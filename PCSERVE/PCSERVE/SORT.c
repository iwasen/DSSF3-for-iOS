/************************************************************************
 *
 *			ＰＣ−ＳＥＲＶＥ
 *
 *		名称		: ソート関連処理
 *		ファイル名	: sort.c
 *		作成者		: s.aizawa
 *
 ************************************************************************/

#include "PCSOS.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "pcsdef.h"
#include "PCSDB.h"
#include "PCSDBSUB.h"
#include "PCSCOM.h"

#if defined OS_WNT
#define	MAX_BUF_SIZE	(65536U*3)
#else
#define	MAX_BUF_SIZE	(16384U*3)
#endif
#define	MIN_BUF_SIZE	(1024U*3)

typedef	struct	{
	LONG	nRec;
	LONG	offset;
} SORT_BLOCK;

static	int	comp_c(CHAR *, CHAR *);
static	int	comp_n(CHAR *, CHAR *);
static	int	comp_i(CHAR *, CHAR *);
static	SHORT	merge(FILE *, FILE *, SORT_BLOCK *, SORT_BLOCK *, CHAR *, int, int (*)(CHAR *, CHAR *));
static	SHORT	wrt_index(IDX *, FILE *, LONG, int);
static	SHORT	wrt_block(IDX *, FILE *, int, int, CHAR *, LONG *, LONG *);

static	int	comp_offset, comp_len;
static	LONG	w_nRec, w_bno;
static int	bufSize;
static	PSBOOL	keyFlag;

CRITICALSECTION	csSort;

/*=======================================================================
 |
 |		マージソート処理
 |
 |	SHORT	merge(fh1, fh2, sbp1, sbp2, bufp, lRec, comp)
 |
 |		int	fh1;		ファイルハンドル１
 |		int	fh2;		ファイルハンドル２
 |		SORT_BLOCK sbp1;	ソートブロックポインタ１
 |		SORT_BLOCK sbp2;	ソートブロックポインタ２
 |		CHAR	*bufp;		テンポラリバッファポインタ
 |		int	lRec;		レコード長
 |		int	(*comp)(CHAR *, CHAR *)	比較関数ポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
static	SHORT	merge(FILE *fh1, FILE *fh2, SORT_BLOCK *sbp1, SORT_BLOCK *sbp2,
			CHAR *bufp, int lRec, int (*comp)(CHAR *, CHAR *))
{
	int	nRec;
	int	n1, n2, n3;
	LONG	offset1, offset2;
	CHAR	*buf1, *buf2, *buf3;
	CHAR	*p1 = NULL, *p2 = NULL, *p3;
	LONG	nRec1, nRec2;
	LONG	rec;
#ifdef	OS_WNT
	DWORD	numBytes;
#endif

	nRec = (bufSize / 3) / lRec;
	n1 = n2 = n3 = 0;
	nRec1 = sbp1->nRec;
	nRec2 = sbp2->nRec;
	offset1 = sbp1->offset;
	offset2 = sbp2->offset;
	buf1 = bufp;
	buf2 = buf1 + bufSize / 3;
	buf3 = buf2 + bufSize / 3;

	p3 = buf3;
	rec = nRec1 + nRec2;
	while (rec--) {
		if (n1 == 0 && nRec1 != 0) {
			n1 = (int)min((LONG)nRec, nRec1);
			nRec1 -= n1;
			__LSEEK(fh1, offset1, SEEK_SET);
			if (__READ(fh1, buf1, lRec * n1) != (int)(lRec * n1))
				return ERROR_DB_READ;
			offset1 += lRec * n1;
			p1 = buf1;
		}
		if (n2 == 0 && nRec2 != 0) {
			n2 = (int)min((LONG)nRec, nRec2);
			nRec2 -= n2;
			__LSEEK(fh1, offset2, SEEK_SET);
			if (__READ(fh1, buf2, lRec * n2) != (int)(lRec * n2))
				return ERROR_DB_READ;
			offset2 += lRec * n2;
			p2 = buf2;
		}

		if (n1 != 0 && (n2 == 0 || (*comp)(p1, p2) <= 0)) {
			memcpy(p3, p1, lRec);
			p1 += lRec;
			n1--;
		} else {
			memcpy(p3, p2, lRec);
			p2 += lRec;
			n2--;
		}

		p3 += lRec;
		if (++n3 == nRec) {
			if (__WRITE_LOCAL(fh2, buf3, lRec * n3) !=
							(int)(lRec * n3))
				return ERROR_DB_WRITE;
			p3 = buf3;
			n3 = 0;
		}
	}

	if (__WRITE_LOCAL(fh2, buf3, lRec * n3) != (int)(lRec * n3))
		return ERROR_DB_WRITE;

	return 0;
}

/*=======================================================================
 |
 |		インデックスファイル構築
 |
 |	SHORT	IDXMake(dp, ip)
 |
 |		PDBF	dp;		ＤＢＦポインタ
 |		PIDX	ip;		ＩＤＸポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	IDXMake(PDBF dp, PIDX ip)
{
	PFIELD	flp;
	FILE	*fh[2];
	PDBF_H	dhp;
	PIDX_H	ihp;
	SORT_BLOCK	*sbp;
	int	nRec, lRec, nBlock, block, block1, block2, n;
	SHORT	type, klen;
	CHAR	*bufp;
	CHAR	*rbp;
	CHAR	tmpFile[2][256];
	int	tmp, tmp1, tmp2;
	LONG	rec;
	int	i;
	CHAR	*p;
	SHORT	err;
	CHAR	kbuf[100];
	int	(*comp)(CHAR *, CHAR *) = NULL;
#ifdef	OS_WNT
	DWORD	numBytes;
#endif

	fh[0] = fh[1] = NULL;
	bufp = NULL;
	sbp = NULL;
	rbp = NULL;

	ihp = ip->ifp->ihp;

	/* キー情報チェック */
	strcpy(kbuf, ihp->index);
	p = strtok(kbuf, "+ ");
	type = -1;
	klen = 0;
	while (p) {
		if ((flp = GetField(dp, p)) != NULL) {
			switch (flp->type) {
			case 'C':
				if (type != -1 && type != KEY_TYPE_C)
					return ERROR_DB_IDXKEY;
				type = KEY_TYPE_C;
				klen += flp->lField2;
				break;
			case 'D':
				if (type != -1 && type != KEY_TYPE_C)
					return ERROR_DB_IDXKEY;
				type = KEY_TYPE_C;
				klen += 8;
				break;
			case 'N':
				if (type != -1 && type != KEY_TYPE_N)
					return ERROR_DB_IDXKEY;
				type = KEY_TYPE_N;
				klen = 8;
				break;
			case 'I':
				if (type != -1 && type != KEY_TYPE_I)
					return ERROR_DB_IDXKEY;
				type = KEY_TYPE_I;
				klen = 4;
				break;
			default:
				return ERROR_DB_IDXKEY;
			}
		} else
			return ERROR_DB_IDXKEY;

		p = strtok(NULL, "+ ");
	}

	if (type == -1)
		return ERROR_DB_IDXKEY;

	ENTER_CRITICAL_SECTION(&csSort);

	IDXSetInfo(ip, type, klen);	/* インデックス情報セット */

	comp_offset = 4;
	comp_len = klen;

	strcpy(tmpFile[0], ip->ifp->fileName);
	SetExtention(tmpFile[0], "$$1");
	if ((fh[0] = __CREAT_LOCAL(tmpFile[0])) == NULL) {
		err = ERROR_DB_TMPFILE;
		goto ret;
	}

	strcpy(tmpFile[1], ip->ifp->fileName);
	SetExtention(tmpFile[1], "$$2");
	if ((fh[1] = __CREAT_LOCAL(tmpFile[1])) == NULL) {
		err = ERROR_DB_TMPFILE;
		goto ret;
	}

	switch (ihp->type) {
	case KEY_TYPE_C:
		comp = comp_c;
		break;
	case KEY_TYPE_N:
		comp = comp_n;
		break;
	case KEY_TYPE_I:
		comp = comp_i;
		break;
	}

	dhp = dp->dhp;
	lRec = klen + 4;

	/* レコードバッファ確保 */
	if ((rbp = malloc(dhp->lRec)) == NULL) {
		err =  ERROR_DB_MEMORY;
		goto ret;
	}

	/* ワークバッファ確保 */
	for (bufSize = MAX_BUF_SIZE; ; ) {
		nRec = bufSize / lRec;
		nBlock = (int)((dhp->nRec - 1) / nRec + 1);

		if ((sbp = calloc(nBlock, sizeof(SORT_BLOCK))) == NULL) {
			err = ERROR_DB_MEMORY;
			goto ret;
		}

		if ((bufp = malloc(bufSize)) != NULL)
			break;

		free(sbp);

		bufSize /= 2;
		if (bufSize < MIN_BUF_SIZE) {
			err = ERROR_DB_MEMORY;
			goto ret;
		}
	}

	rec = 0;
	__LSEEK(dp->fh, (LONG)dhp->lHeader, SEEK_SET);
	for (block = 0; block < nBlock; block++) {
		n  = (int)min((LONG)nRec, dhp->nRec - rec);
		sbp[block].nRec = n;
		sbp[block].offset = lRec * rec;
		for (i = 0, p = bufp; i < n; i++, p += lRec) {
			if (__READ(dp->fh, rbp, dhp->lRec) != (int)dhp->lRec){
				err = ERROR_DB_READ;
				goto ret;
			}
			if (dhp->scramble != 0)
				Scramble2(rbp + 1, (SHORT)(dhp->lRec - 1),
								dhp->scramble);
			*(LONG *)p = ++rec;
			GetKey(dp, rbp+1, ihp, p+4);
		}
		qsort(bufp, n, lRec, (int (*)(const void *,const void *))comp);
		if (__WRITE_LOCAL(fh[0], bufp, lRec * n) != (lRec * n)) {
			err = ERROR_DB_WRITE;
			goto ret;
		}
	}

	tmp1 = 0;
	tmp2 = 1;
	for ( ; nBlock != 1; nBlock = (nBlock + 1) / 2) {
		__LSEEK(fh[tmp2], 0L, SEEK_SET);

		for (block = 0; block < nBlock/2; block++) {
			block1 = block * 2;
			block2 = block1 + 1;
			if ((err = merge(fh[tmp1], fh[tmp2], &sbp[block1],
					&sbp[block2], bufp, lRec, (int (*)(char *,char *))comp)) != 0)
				goto ret;
			sbp[block].nRec = sbp[block1].nRec
						+ sbp[block2].nRec;
			sbp[block].offset = sbp[block1].offset;
		}
		if (nBlock % 2 != 0) {
			block1 = block * 2;
			__LSEEK(fh[tmp1], sbp[block1].offset, SEEK_SET);
			for (rec = sbp[block1].nRec; rec != 0; ) {
				n = (int)min((LONG)nRec, rec);
				if (__READ(fh[tmp1], bufp, lRec * n) !=
							(int)(lRec * n)) {
					err = ERROR_DB_READ;
					goto ret;
				}
				if (__WRITE_LOCAL(fh[tmp2], bufp, lRec * n) !=
							(int)(lRec * n)) {
					err = ERROR_DB_WRITE;
					goto ret;
				}
				rec -= n;
			}
			sbp[block].nRec = sbp[block1].nRec;
			sbp[block].offset = sbp[block1].offset;
		}
		tmp = tmp1;
		tmp1 = tmp2;
		tmp2 = tmp;
	}

	__LSEEK(fh[tmp1], 0L, SEEK_SET);
	err = wrt_index(ip, fh[tmp1], dhp->nRec, lRec);
ret:
	if (bufp)
		free(bufp);
	if (sbp)
		free(sbp);

	if (rbp)
		free(rbp);

	if (fh[1] != NULL) {
		__CLOSE(fh[1]);
		remove(tmpFile[1]);
	}
	if (fh[0] != NULL) {
		__CLOSE(fh[0]);
		remove(tmpFile[0]);
	}

	IDXFlushBlock(ip, TRUE);

	LEAVE_CRITICAL_SECTION(&csSort);

	return err;
}

/*=======================================================================
 |
 |		文字型データ用比較関数
 |
 |	int	comp_c(p1, p2)
 |
 |		CHAR	*p1;		比較データ１
 |		CHAR	*p2;		比較データ２
 |
 =======================================================================*/
static	int	comp_c(CHAR *p1, CHAR *p2)
{
	int	i;
	LONG	l;

	if ((i = memcmp(p1+4, p2+4, comp_len)) == 0) {
		l = *(LONG *)p1 - *(LONG *)p2;
		i = (l == 0) ? 0 : (l < 0) ? -1 : 1;
	}
	return i;
}

/*=======================================================================
 |
 |		実数型データ用比較関数
 |
 |	int	comp_n(p1, p2)
 |
 |		CHAR	*p1;		比較データ１
 |		CHAR	*p2;		比較データ２
 |
 =======================================================================*/
static	int	comp_n(CHAR *p1, CHAR *p2)
{
	int	i;
	LONG	l;

	if (*(double *)(p1+4) > *(double *)(p2+4))
		i = 1;
	else if (*(double *)(p1+4) < *(double *)(p2+4))
		i = -1;
	else {
		l = *(LONG *)p1 - *(LONG *)p2;
		i = (l == 0) ? 0 : (l < 0) ? -1 : 1;
	}
	return i;
}

/*=======================================================================
 |
 |		整数型データ用比較関数
 |
 |	int	comp_i(p1, p2)
 |
 |		CHAR	*p1;		比較データ１
 |		CHAR	*p2;		比較データ２
 |
 =======================================================================*/
static	int	comp_i(CHAR *p1, CHAR *p2)
{
	int	i;
	LONG	l;

	if (*(LONG *)(p1+4) > *(LONG *)(p2+4))
		i = 1;
	else if (*(LONG *)(p1+4) < *(LONG *)(p2+4))
		i = -1;
	else {
		l = *(LONG *)p1 - *(LONG *)p2;
		i = (l == 0) ? 0 : (l < 0) ? -1 : 1;
	}
	return i;
}

/*=======================================================================
 |
 |		インデックスファイル書き込み処理
 |
 |	SHORT	wrt_index(ip, fh, nRec, lRec)
 |
 |		PIDX	ip;		インデックスファイルポインタ
 |		int	fh;		ファイルハンドル
 |		LONG	nRec;		レコード数
 |		int	lRec;		レコード長
 |
 |		返値			エラーコード
 |
 =======================================================================*/
static	SHORT	wrt_index(PIDX ip, FILE *fh, LONG nRec, int lRec)
{
	PIDX_H	ihp;
	LONG	bno;
	LONG	rno;
	int	level;
	SHORT	err;
	CHAR	key[256];

	__CHSIZE(ip->ifp->fileName, ip->ifp->fh, 0L);

	ihp = ip->ifp->ihp;

	memset(key, 0, ihp->lKey);
	w_nRec = nRec;
	w_bno = 1;
	level = 0;
	rno = 0;
	keyFlag = FALSE;
	do {
		ip->bp = NULL;
		if ((err = wrt_block(ip, fh, level++, lRec, key, &bno, &rno)) != 0)
			return err;
	} while (w_nRec != 0);

	ihp->root = bno;
	ihp->nBlock = w_bno;
	ihp->nFreeBlock = 0;

	return 0;
}

/*=======================================================================
 |
 |		インデックスファイル１ブロック書き込み処理
 |
 |	SHORT	wrt_block(ip, fh, level, lRec, key, bno, rno)
 |
 |		PIDX	ip;		インデックスファイルポインタ
 |		int	fh;		ファイルハンドル
 |		int	level;		階層数
 |		int	lRec;		レコード長
 |		CHAR	*key;		キー
 |		LONG	*bno;		ブロック番号
 |		LONG	*rno;		レコード番号
 |
 |		返値			エラーコード
 |
 =======================================================================*/
static	SHORT	wrt_block(PIDX ip, FILE *fh, int level, int lRec, CHAR *key
		, LONG *bno, LONG *rno)
{
	PIDX_H	ihp;
	PIDX_B	bp;
	CHAR	*bufp;
	int	i;
	SHORT	err;
#ifdef	OS_WNT
	DWORD	numBytes;
#endif

	ihp = ip->ifp->ihp;
	if ((err = IDXRead(ip, 0L, &bp)) != 0)
		return err;

	bufp = bp->block + 4;

	if (level == 0) {
		for (i = 0; i < ihp->order && w_nRec != 0; w_nRec--) {
			if (__READ(fh, bufp + 4, lRec) != (int)lRec)
				return ERROR_DB_READ;
			if (ihp->uniq && keyFlag) {
				if (memcmp(bufp + 8, key, ihp->lKey) == 0)
					continue;
			}
			*(LONG *)bufp = 0;
			memcpy(key, bufp + 8, ihp->lKey);
			*rno = *(LONG *)(bufp + 4);
			keyFlag = TRUE;
			bufp += ihp->lRec;
			i++;
		}
		*(LONG *)bufp = 0;
	} else {
		if (*bno == 0) {
			if ((err = wrt_block(ip, fh, level-1, lRec, key,
							bno, rno)) != 0)
				return err;
		}

		for (i = 0; i < ihp->order && w_nRec != 0; i++) {
			*(LONG *)bufp = *bno;
			if (ip->ifp->exFlag)
				*(LONG *)(bufp + 4) = *rno;
			else
				*(LONG *)(bufp + 4) = 0;
			memcpy(bufp+8, key, ihp->lKey);
			*bno = 0;
			if ((err = wrt_block(ip, fh, level-1, lRec, key,
							bno, rno)) != 0)
				return err;
			bufp += ihp->lRec;
		}
		*(LONG *)bufp = *bno;
	}

	*(SHORT *)bp->block = i;
	bp->bno = w_bno++;

	if ((err = IDXWrite(ip, bp)) != 0)
		return err;

	*bno = bp->bno;
	ip->bp = bp->bwp;

	return 0;
}
