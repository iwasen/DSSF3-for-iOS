/************************************************************************
 *
 *			ＰＣ−ＳＥＲＶＥ
 *
 *		名称		: ＤＢ共通サブルーチン
 *		ファイル名	: dbsub.c
 *		作成者		: s.aizawa
 *
 ************************************************************************/

#include "PCSOS.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#define	iskanji(c)	((c) & 0x80)
#include "pcsdef.h"
#include "PCSDB.h"
#include "PCSDBSUB.h"
#include "PCSCOM.h"

/*=======================================================================
 |
 |		キー取り出し
 |
 |	SHORT	GetKey(dp, rbp, ihp, kp)
 |
 |		DBF	*dp;		ＤＢＦポインタ
 |		CHAR	*rbp;		レコードバッファポインタ
 |		IDX_H	*ihp;		ＩＤＸ＿Ｈポインタ
 |		VOID	*kp;		キーバッファ
 |
 |		返値			０：キーなし　１：キーあり
 |
 =======================================================================*/
SHORT	GetKey(DBF *dp, CHAR *rbp, IDX_H *ihp, VOID *kp)
{
	FIELD	*flp;
	CHAR	buf[100], *p;
	SHORT	flag;

	strcpy(buf, ihp->index);
	p = strtok(buf, "+ ");
	switch (ihp->type) {
	case KEY_TYPE_C:
		*(CHAR *)kp = '\0';
		break;
	case KEY_TYPE_N:
		*(double *)kp = 0;
		break;
	case KEY_TYPE_I:
		*(LONG *)kp = 0L;
		break;
	default:
		return 0;
	}

	flag = 0;
	while (p) {
		if ((flp = GetField(dp, p)) != NULL) {
			switch (ihp->type) {
			case KEY_TYPE_C:
				memcpy(kp, &rbp[flp->offset], flp->lField2);
				*(CHAR **)&kp += flp->lField2;
				break;
			case KEY_TYPE_N:
				*(double *)kp += natof(&rbp[flp->offset],
								flp->lField2);
				break;
			case KEY_TYPE_I:
				*(LONG *)kp += natol(&rbp[flp->offset],
								flp->lField2);
				break;
			}
			flag = 1;
		} else
			return 0;

		p = strtok(NULL, "+ ");
	}

	return flag;
}

/*=======================================================================
 |
 |		フィールド情報ポインタ取り出し
 |
 |	FIELD	*GetField(dp, field)
 |
 |		DBF	*dp;		ＤＢＦポインタ
 |		CHAR	*field;		フィールド名
 |
 |		返値			フィールド情報へのポインタ
 |
 =======================================================================*/
FIELD	*GetField(DBF *dp, CHAR *field)
{
	SHORT	i;
	FIELD	*flp;
	CHAR	buf[11], *p;

	strcpy(buf, field);
	for (p = buf; *p; p++) {
		if (iskanji(*p)) {
			if (*(++p) == '\0')
				break;
		} else if (islower(*p))
			*p -= 0x20;
	}

	for (i = 0, flp = dp->flp; i < dp->nField; i++, flp++) {
		if (strcmp(buf, flp->name) == 0)
			return flp;
	}
	return NULL;
}

/*=======================================================================
 |
 |		フィールド情報番号取り出し
 |
 |	SHORT	GetField(dp, field)
 |
 |		DBF	*dp;		ＤＢＦポインタ
 |		CHAR	*field;		フィールド名
 |
 |		返値			フィールド情報番号
 |
 =======================================================================*/
SHORT	GetFieldNo(DBF *dp, CHAR *field)
{
	SHORT	i;
	FIELD	*flp;
	CHAR	buf[11], *p;

	strcpy(buf, field);
	for (p = buf; *p; p++) {
		if (iskanji(*p))
			p++;
		else if (islower(*p))
			*p -= 0x20;
	}

	for (i = 0, flp = dp->flp; i < dp->nField; i++, flp++) {
		if (strcmp(buf, flp->name) == 0)
			return i;
	}
	return -1;
}

PSBOOL CopyFile(CHAR *pSrcFileName, CHAR *pDstFileName)
{
	FILE *fps, *fpd;
	int n;
	char buf[4096];

	if ((fps = fopen(pSrcFileName, "r")) == NULL)
		return FALSE;

	if ((fpd = fopen(pDstFileName, "w")) == NULL) {
		fclose(fps);
		return FALSE;
	}

	for (;;) {
		n = (int)fread(buf, 1, sizeof(buf), fps);
		if (n == 0)
			break;

		fwrite(buf, 1, n, fpd);
	}

	fclose(fps);
	fclose(fpd);

	return TRUE;
}
