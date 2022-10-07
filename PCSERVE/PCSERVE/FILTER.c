/************************************************************************
 *
 *			ＰＣ−ＳＥＲＶＥ
 *
 *		名称		: フィルタ条件評価
 *		ファイル名	: filter.c
 *		作成者		: s.aizawa
 *
 ************************************************************************/

#include "PCSOS.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "pcsdef.h"
#include "PCSDB.h"
#include "PCSDBSUB.h"
#include "PCSCOM.h"

#define	L_AND	0
#define	L_OR	1
#define	L_END	2
#define	C_EQ	0
#define	C_NE	1
#define	C_GT	2
#define	C_LT	3
#define	C_GE	4
#define	C_LE	5
#define	P_LEFT	6
#define	P_RIGHT	7

#define OPT_NOCASE			0x01
#define OPT_FULLMATCHING	0x02
#define OPT_WILDCARD		0x04
#define OPT_SUBSTR			0x08
#define OPT_ZENKAKU			0x10

static CHAR *_GetOption(CHAR *p, CHAR *option);
static	CHAR	*_GetFieldName(CHAR *, CHAR *);
static	CHAR	*_GetCompare(CHAR *, CHAR *);
static	CHAR	*_GetValue(CHAR *, CHAR *);
static	CHAR	*_GetAndOr(CHAR *, CHAR *);
static	CHAR	*_GetParenthes(CHAR *, CHAR *);
static	SHORT	_CheckFilterSub(PDB, CHAR *);
static	PSBOOL	_CheckSelect(PDB, CHAR *, CHAR *);
static	CHAR	*_GetIndexNo(CHAR *, int *);
static	SHORT	_ExecSelect(PDB, CHAR *, HPSTR *, LONG);
static	SHORT	_SearchIndex1(PIDX, int, CHAR *, int, HPSTR, LONG);
static	SHORT	_SearchIndex2(PIDX, int, CHAR *, int, HPSTR, LONG);

extern	CHAR	bitTable1[8];
extern	CHAR	bitTable2[8];

static PSBOOL wildmat(char *s, char *p);
static PSBOOL Star(char *s, char *p);
static void StringToHankaku(char *s);

#ifdef _SERVER
extern	VOID	CopyFromDBF(CHAR *, CHAR *, SHORT);
#else
VOID	CopyFromDBF(CHAR *strbuf, CHAR *dbField, SHORT length)
{
	while (length != 0) {
		if (dbField[length-1] != ' ')
			break;
		length--;
	}
	memcpy(strbuf, dbField, length);
	strbuf[length] = '\0';
}
#endif

/*=======================================================================
 |
 |		フィルタ条件式解析
 |
 |	SHORT	SetFilter(dbp, filter)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*filter;	フィルタ条件式
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	SetFilter(PDB dbp, CHAR *filter)
{
	PFIELD	flp;
	CHAR	*p, *cp, *cp2;
	CHAR	fieldName[11];
	SHORT	fieldNo;
	CHAR	value[256];
	CHAR	parenthes;
	int	pCount;
	SHORT	*pTable[30];
	CHAR	option;

	if ((cp = malloc(1024U * 32)) == NULL)
		return ERROR_DB_MEMORY;

	cp2 = cp;
	pCount = 0;

	p = filter;

	for (;;) {
		/* 左括弧取り出し */
		for(;;) {
			p = _GetParenthes(p, &parenthes);
			if (parenthes == P_LEFT) {
				pTable[pCount++] = (SHORT *)cp;
				cp += sizeof(SHORT);
			} else
				break;
		}

		/* オプション取り出し */
		if ((p = _GetOption(p, &option)) == NULL) {
			free(cp2);
			return ERROR_DB_PARAMETER;
		}

		/* フィールド名取り出し */
		if ((p = _GetFieldName(p, fieldName)) == NULL) {
			free(cp2);
			return ERROR_DB_PARAMETER;
		}

		if ((fieldNo = GetFieldNo(dbp->dp, fieldName)) == -1) {
			free(cp2);
			return ERROR_DB_PARAMETER;
		}

		*(*(SHORT **)&cp)++ = fieldNo;
		*cp++ = option;

		flp = &dbp->dp->flp[fieldNo];

		/* 比較演算子取り出し */
		if ((p = _GetCompare(p, cp++)) == NULL) {
			free(cp2);
			return ERROR_DB_PARAMETER;
		}

		/* 比較値取り出し */
		if ((p = _GetValue(p, value)) == NULL) {
			free(cp2);
			return ERROR_DB_PARAMETER;
		}

		/* 比較 */
		switch (flp->type) {
		case 'C':
		case 'D':
		case 'L':
		case 'B':
			if (option & OPT_NOCASE)
				StringToUpper(value);
			if (option & OPT_ZENKAKU)
				StringToHankaku(value);
			strcpy(cp, value);
			cp += strlen(value) + 1;
			break;
		case 'N':
			*(*(double **)&cp)++ = atof(value);
			break;
		case 'I':
			*(*(LONG **)&cp)++ = atoi(value);
			break;
		}

		/* 右括弧取り出し */
		for(;;) {
			p = _GetParenthes(p, &parenthes);
			if (parenthes == P_RIGHT) {
				*cp++ = P_RIGHT;
				pCount--;
				if (pCount < 0)
					goto exit_loop;
				*pTable[pCount] = -(cp - (CHAR *)pTable[pCount]);
			} else
				break;
		}

		/* ＡＮＤ／ＯＲの処理 */
		if ((p = _GetAndOr(p, cp++)) == NULL)
			break;
	}

exit_loop:
	if (cp == cp2 || pCount != 0) {
		free(cp2);
		dbp->filter = NULL;
	} else {
		if ((dbp->filter = realloc(cp2, cp - cp2)) == NULL)
			dbp->filter = cp2;
	}

	return 0;
}

/*=======================================================================
 |
 |		フィルタ条件評価
 |
 |	SHORT	CheckFilter(dbp)
 |
 |		PDB	dbp;		ＤＢポインタ
 |
 |		返値			０：無効　１：有効
 |
 =======================================================================*/
SHORT	CheckFilter(PDB dbp)
{
	return _CheckFilterSub(dbp, dbp->filter);
}

static	SHORT	_CheckFilterSub(PDB dbp, CHAR *cp)
{
	PFIELD	flp;
	CHAR	*fdp;
	int	c = 0;
	double	d_tmp1, d_tmp2;
	LONG	l_tmp1, l_tmp2;
	int	flag = 0;
	int	compare;
	PSBOOL	loopSW;
	CHAR option;
	char buf[1024 + 1], *bufp;
	LONG nReadSize;

	loopSW = TRUE;
	while (loopSW) {
		if (*(SHORT *)cp < 0) {		/* 左括弧 */
			flag = _CheckFilterSub(dbp, cp + sizeof(SHORT));
			cp += -(*(SHORT *)cp);
		} else {
			flp = &dbp->dp->flp[*(*(SHORT **)&cp)++];
			option = *cp++;
			compare = *cp++;
			fdp = &dbp->rbp[flp->offset + 1];
			switch (flp->type) {
			case 'B':
			case 'C':
			case 'D':
			case 'L':
				if (flp->type == 'B') {
					if (dbp->brp == NULL) {
						if ((dbp->brp = malloc(sizeof(BIN_R))) == NULL)
							return 0;
					}
					BINRead(dbp->dp->bfp, dbp->brp, buf, sizeof(buf) - 1, *(LONG *)fdp, &nReadSize);
					buf[nReadSize] = '\0';
					bufp = buf;
				} else {
					if (option == 0)
						bufp = fdp;
					else {
						CopyFromDBF(buf, fdp, flp->lField);
						bufp = buf;
					}
				}

				if (option & OPT_NOCASE)
					StringToUpper(bufp);

				if (option & OPT_ZENKAKU)
					StringToHankaku(bufp);

				if (option & OPT_SUBSTR)
					c = (strstr(bufp, cp) != NULL ? 0 : 1);
				else if (option & OPT_WILDCARD)
					c = (wildmat(bufp, cp) ? 0 : 1);
				else if (option & OPT_FULLMATCHING)
					c = strcmp(bufp, cp);
				else
					c = strncmp(bufp, cp, strlen(cp));
				cp += strlen(cp) + 1;
				break;
			case 'N':
				d_tmp1 = natof(fdp, flp->lField2);
				d_tmp2 = *(*(double **)&cp)++;
				if (d_tmp1 > d_tmp2)
					c = 1;
				else if (d_tmp1 < d_tmp2)
					c = -1;
				else
					c = 0;
				break;
			case 'I':
				l_tmp1 = natol(fdp, flp->lField2);
				l_tmp2 = *(*(LONG **)&cp)++;
				if (l_tmp1 > l_tmp2)
					c = 1;
				else if (l_tmp1 < l_tmp2)
					c = -1;
				else
					c = 0;
				break;
			}

			/* 比較演算子により有効／無効を判断する */
			switch (compare) {
			case C_EQ:		/* ＝ */
				flag = (c == 0);
				break;
			case C_NE:		/* ≠ */
				flag = (c != 0);
				break;
			case C_GT:		/* ＞ */
				flag = (c > 0);
				break;
			case C_LT:		/* ＜ */
				flag = (c < 0);
				break;
			case C_GE:		/* ≧ */
				flag = (c >= 0);
				break;
			case C_LE:		/* ≦ */
				flag = (c <= 0);
				break;
			}
		}

		/* ＡＮＤ／ＯＲの処理 */
		switch (*cp++) {
		case L_AND:		/* AND */
			if (!flag)
				return 0;
			break;
		case L_OR:		/* OR */
			if (flag)
				return 1;
			break;
		default:
			loopSW = FALSE;
			break;
		}
	}

	return flag;
}

static CHAR *_GetOption(CHAR *p, CHAR *option)
{
	while (*p == ' ')
		p++;

	*option = 0;

	while (*p == '*') {
		p++;
		switch (*p++) {
		case 'N':		// No case
			*option |= OPT_NOCASE;
			break;
		case 'F':		// Full matching
			*option |= OPT_FULLMATCHING;
			break;
		case 'W':		// Wildcard
			*option |= OPT_WILDCARD;
			break;
		case 'S':		// Sub String
			*option |= OPT_SUBSTR;
			break;
		case 'Z':		// Zenkaku
			*option |= OPT_ZENKAKU;
			break;
		}
	}

	return p;
}

static	CHAR	*_GetFieldName(CHAR *p, CHAR *field)
{
	int	c, count;

	count = 0;
	for (;;) {
		c = *p;
		if (c == ' ' || c == '=' || c == '<' || c == '>' || c == '\0')
			break;
		if (++count > 10)
			return NULL;
		*field++ = (CHAR)c;
		p++;
	}

	*field = '\0';

	return p;
}

static	CHAR	*_GetCompare(CHAR *p, CHAR *compare)
{
	while (*p == ' ')
		p++;

	switch (*p++) {
	case '=':
		*compare = C_EQ;
		break;
	case '>':
		if (*p == '=') {
			p++;
			*compare = C_GE;
		} else
			*compare = C_GT;
		break;
	case '<':
		if (*p == '=') {
			p++;
			*compare = C_LE;
		} else if (*p == '>') {
			p++;
			*compare = C_NE;
		} else
			*compare = C_LT;
		break;
	default:
		p = NULL;
		break;
	}

	return p;
}

static	CHAR	*_GetValue(CHAR *p, CHAR *value)
{
	int	c, flag;

	while (*p == ' ')
		p++;

	if (*p == '\'') {
		flag = 1;
		p++;
	} else if (*p == '\"') {
		flag = 2;
		p++;
	} else
		flag = 0;

	for (;;) {
		c = *p;
		if (c == '\0')
			break;
		if (flag == 0) {
			if (c == ' ' || c == '&' || c == '|' || c == ')' || c == '\0')
				break;
		} else if (flag == 1) {
			if (c == '\'') {
				p++;
				break;
			}
		} else if (flag == 2) {
			if (c == '\"') {
				p++;
				break;
			}
		}

		*value++ = (CHAR)c;
		p++;
	}

	*value = '\0';

	return p;
}

static	CHAR	*_GetAndOr(CHAR *p, CHAR *and_or)
{
	while (*p == ' ')
		p++;

	switch (*p) {
	case '&':
		*and_or = L_AND;
		p++;
		break;
	case '|':
		*and_or = L_OR;
		p++;
		break;
	default:
		*and_or = L_END;
		p = NULL;
		break;
	}

	return p;
}

static	CHAR	*_GetParenthes(CHAR *p, CHAR *parenthes)
{
	while (*p == ' ')
		p++;

	switch (*p) {
	case '(':
		*parenthes = P_LEFT;
		p++;
		break;
	case ')':
		*parenthes = P_RIGHT;
		p++;
		break;
	default:
		*parenthes = '\0';
		break;
	}

	return p;
}

/*=======================================================================
 |
 |		選択条件式の実行
 |
 |	SHORT	SetSelect(dbp, select, LONG *nSelectRec)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*select;	選択条件式
 |		LONG	*nSelectRec;		選択レコード数
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	SetSelect(PDB dbp, CHAR *select, LONG *nSelectRec)
{
	CHAR	*cp;
	LONG	nRec;
	LONG	i;
	HPSTR	p;
	SHORT	err;

	*nSelectRec = 0;

	if ((cp = malloc(1024U * 32)) == NULL)
		return ERROR_DB_MEMORY;

	if (!_CheckSelect(dbp, select, cp)) {
		free(cp);
		return ERROR_DB_PARAMETER;
	}

	nRec = dbp->dp->dhp->nRec;
	err = _ExecSelect(dbp, cp, &dbp->select, nRec / 8 + 1);

	free(cp);

	if (err == 0) {
		for (i = 1, p = dbp->select; i <= nRec; i++) {
			if (p[i / 8] & bitTable1[i % 8])
				(*nSelectRec)++;
		}
		dbp->selectRec = nRec;
	}

	return err;
}

static	PSBOOL	_CheckSelect(PDB dbp, CHAR *select, CHAR *cp)
{
	CHAR	*p, *cp2;
	int	indexNo;
	CHAR	value[256];
	CHAR	parenthes;
	int	pCount;
	SHORT	*pTable[30];
	int	len, klen;

	cp2 = cp;
	pCount = 0;

	p = select;
	for (;;) {
		/* 左括弧取り出し */
		for(;;) {
			p = _GetParenthes(p, &parenthes);
			if (parenthes == P_LEFT) {
				pTable[pCount++] = (SHORT *)cp;
				cp += sizeof(SHORT);
			} else
				break;
		}

		/* インデックス番号取り出し */
		if ((p = _GetIndexNo(p, &indexNo)) == NULL)
			return FALSE;

		if (indexNo < 1 || indexNo > dbp->nIdx)
			return FALSE;

		*(*(SHORT **)&cp)++ = indexNo;

		/* 比較演算子取り出し */
		if ((p = _GetCompare(p, cp++)) == NULL)
			return FALSE;

		/* 比較値取り出し */
		if ((p = _GetValue(p, value)) == NULL)
			return FALSE;

		/* 比較 */
		switch (dbp->ip[indexNo]->ifp->ihp->type) {
		case KEY_TYPE_C:
			len = (int)strlen(value);
			klen = dbp->ip[indexNo]->ifp->ihp->lKey;
			if (len < klen)
				memset(value + len, ' ', klen - len);
			*cp++ = klen;
			memcpy(cp, value, klen);
			cp += klen;
			break;
		case KEY_TYPE_N:
			*cp++ = 8;
			*(*(double **)&cp)++ = atof(value);
			break;
		case KEY_TYPE_I:
			*cp++ = 4;
			*(*(LONG **)&cp)++ = atoi(value);
			break;
		}

		/* 右括弧取り出し */
		for(;;) {
			p = _GetParenthes(p, &parenthes);
			if (parenthes == P_RIGHT) {
				*cp++ = P_RIGHT;
				pCount--;
				if (pCount < 0)
					goto exit_loop;
				*pTable[pCount] =
					-(cp - (CHAR *)pTable[pCount]);
			} else
				break;
		}

		/* ＡＮＤ／ＯＲの処理 */
		if ((p = _GetAndOr(p, cp++)) == NULL)
			break;
	}

exit_loop:
	if (cp == cp2 || pCount != 0)
		return FALSE;

	return TRUE;
}

static	CHAR	*_GetIndexNo(CHAR *p, int *indexNo)
{
	int	c;

	while (*p == ' ')
		p++;

	if (*p++ != '#')
		return NULL;

	*indexNo = 0;
	for (;;) {
		c = *p;
		if (c < '0' || c > '9')
			break;

		*indexNo *= 10;
		*indexNo += c - '0';

		p++;
	}

	return p;
}

/*=======================================================================
 |
 |		選択条件実行
 |
 |	SHORT	ExecSelect(dbp, cp, select, size)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*cp;		選択条件解析データ
 |		HPSTR	select;		選択レコードフラグ
 |		LONG	size;		選択レコードフラグサイズ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
static	SHORT	_ExecSelect(PDB dbp, CHAR *cp, HPSTR *select, LONG size)
{
	int	compare;
	int	andOr;
	int	indexNo;
	int	len;
	LONG	i;
	PSBOOL	loopSW;
	HPSTR	sp1, sp2;
	HPINT	hip1, hip2;
	LONG	iSize;
	SHORT	err;

	andOr = L_END;
	sp1 = sp2 = NULL;
	*select = NULL;

	loopSW = TRUE;
	while (loopSW) {
		if (*(SHORT *)cp < 0) {		/* 左括弧 */
			if ((err = _ExecSelect(dbp, cp + sizeof(SHORT),
							&sp1, size)) != 0)
				return err;

			cp += -(*(SHORT *)cp);
		} else {
			indexNo = *(*(SHORT **)&cp)++;
			compare = *cp++;
			len = *cp++;

			if ((sp1 = HALLOC(size + sizeof(int))) == NULL)
				return ERROR_DB_MEMORY;

			switch (compare) {
			case C_EQ:		/* ＝ */
			case C_NE:		/* ≠ */
				if ((err = _SearchIndex1(dbp->ip[indexNo],
							compare, cp, len,
							sp1, size)) != 0) {
					HFREE(sp1);
					return err;
				}
				break;
			case C_GT:		/* ＞ */
			case C_LT:		/* ＜ */
			case C_GE:		/* ≧ */
			case C_LE:		/* ≦ */
				if ((err = _SearchIndex2(dbp->ip[indexNo],
							compare, cp, len,
							sp1, size)) != 0) {
					HFREE(sp1);
					return err;
				}
				break;
			}

			cp += len;
		}

		switch (andOr) {
		case L_END:
			sp2 = sp1;
			break;
		case L_AND:
			hip1 = (HPINT)sp1;
			hip2 = (HPINT)sp2;
			iSize = (size + (sizeof(int) - 1)) / sizeof(int);
			for (i = 0; i < iSize; i++)
				*hip2++ &= *hip1++;
			HFREE(sp1);
			break;
		case L_OR:
			hip1 = (HPINT)sp1;
			hip2 = (HPINT)sp2;
			iSize = (size + (sizeof(int) - 1)) / sizeof(int);
			for (i = 0; i < iSize; i++)
				*hip2++ |= *hip1++;
			HFREE(sp1);
			break;
		}

		/* ＡＮＤ／ＯＲの処理 */
		switch (*cp++) {
		case L_AND:		/* AND */
			andOr = L_AND;
			break;
		case L_OR:		/* OR */
			andOr = L_OR;
			break;
		default:
			loopSW = FALSE;
			break;
		}
	}

	*select = sp2;

	return 0;
}

static	SHORT	_SearchIndex1(PIDX ip, int compare, CHAR *value, int len,
						HPSTR select, LONG size)
{
	LONG	recNo;
	SHORT	err;

	if (compare == C_EQ) {
		HMEMSET(select, 0x00, size);
	} else {
		HMEMSET(select, 0xff, size);
	}

	if ((err = IDXSearch(ip, value, (SHORT)len, &recNo)) != 0)
		return err;

	while (recNo != 0) {
		if (IDXCompare(ip, value, (SHORT)len) != 0)
			break;

		if (compare == C_EQ)
			select[recNo / 8] |= bitTable1[recNo % 8];
		else
			select[recNo / 8] &= bitTable2[recNo % 8];

		if ((err = IDXNext(ip, &recNo)) != 0)
			return err;
	}

	return 0;
}

static	SHORT	_SearchIndex2(PIDX ip, int compare, CHAR *value, int len,
						HPSTR select, LONG size)
{
	LONG	recNo;
	SHORT	err;

	if (compare == C_GT || compare == C_GE) {
		HMEMSET(select, 0x00, size);
	} else {
		HMEMSET(select, 0xff, size);
	}

	if ((err = IDXSearch2(ip, value, (SHORT)len, &recNo)) != 0)
		return err;

	if (compare == C_GT || compare == C_LE) {
		while (recNo != 0) {
			if (IDXCompare(ip, value, (SHORT)len) != 0)
				break;

			if ((err = IDXNext(ip, &recNo)) != 0)
				return err;

			if (recNo == 0)
				break;
		}
	}

	while (recNo != 0) {
		if (compare == C_GT || compare == C_GE)
			select[recNo / 8] |= bitTable1[recNo % 8];
		else
			select[recNo / 8] &= bitTable2[recNo % 8];

		if ((err = IDXNext(ip, &recNo)) != 0)
			return err;
	}

	return 0;
}

static PSBOOL wildmat(char *s, char *p)
{
    int last;
    int matched;
    int reverse;

	for ( ; *p; s++, p++) {
		switch (*p) {
		case '\\':
			p++;
		default:
			if (*s != *p)
				return FALSE;
			continue;
		case '?':
			if (*s == '\0')
				return FALSE;
			continue;
		case '*':
			return(*++p ? Star(s, p) : TRUE);
		case '[':
			if ((reverse = p[1]) == '^')
				p++;
			for (last = 0400, matched = FALSE; *++p && *p != ']'; last = *p)
				if (*p == '-' ? *s <= *++p && *s >= last : *s == *p)
					matched = TRUE;
			if (matched == reverse)
				return(FALSE);
			continue;
		}
	}

    /* For "tar" use, matches that end at a slash also work. --hoptoad!gnu */
    return(*s == '\0' || *s == '/');
}

static PSBOOL Star(char *s, char *p)
{
	while (wildmat(s, p) == FALSE)
	if (*++s == '\0')
		return FALSE;
	return TRUE;
}

static void StringToHankaku(char *s)
{
/*
	char	buf[1024];
	int size;

	size = LCMapString(LOCALE_SYSTEM_DEFAULT, LCMAP_HALFWIDTH, s, strlen(s), buf, sizeof(buf));
	if (size > 0) {
		memcpy(s, buf, size);
		s[size] = '\0';
	}
*/
}
