/************************************************************************
 *
 *			ＰＣ−ＳＥＲＶＥ
 *
 *		名称		: インデックスファイル操作
 *		ファイル名	: idx.c
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

static	SHORT	_IDXOpen(CHAR *, PIDX *);
static	SHORT	_IDXCreate(CHAR *, CHAR *, SHORT, PIDX *);
static	SHORT	_IDXClose(PIDX);
static	SHORT	_IDXPack(CHAR *, PIDX, FILE *, int, LONG *, CHAR *, PSBOOL *,
							LONG *, LONG *);
static	ULONG	_CountFreeBlock(PIDX_F);

static	PIDX_F	pTopIDX_F;
CRITICALSECTION	csIDX;		/* IDX クリチカルセクション */

/*=======================================================================
 |
 |		インデックスファイルオープン
 |
 |	SHORT	IDXOpen(fileName, ipp)
 |
 |		CHAR	*fileName;	インデックスファイル名
 |		PIDX	*ipp;		ＩＤＸポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	IDXOpen(CHAR *fileName, PIDX *ipp)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&csIDX);
	err = _IDXOpen(fileName, ipp);
	LEAVE_CRITICAL_SECTION(&csIDX);

	return err;
}

static	SHORT	_IDXOpen(CHAR *fileName, PIDX *ipp)
{
	PIDX	ip;
	PIDX_F	ifp;
	PIDX_H	ihp;
	CHAR	*p;
#if defined (OS_WNT)
	DWORD	numBytes;
#endif

	/* フルパス名取得 */
/*
	_fullpath(pathName, fileName, sizeof(pathName));
	StringToUpper(pathName);
*/
	for (ifp = pTopIDX_F; ifp != NULL; ifp = ifp->chain) {
		if (strcmp(fileName, ifp->fileName) == 0)
			break;
	}

	/* インデックス管理情報エリア確保 */
	if ((ip = malloc(sizeof(IDX))) == 0)
		return ERROR_DB_MEMORY;
	memset(ip, 0, sizeof(IDX));

	if (ifp == NULL) {
		/* インデックス管理情報エリア確保 */
		if ((ifp = malloc(sizeof(IDX_F))) == 0) {
			_IDXClose(ip);
			return ERROR_DB_MEMORY;
		}

		memset(ifp, 0, sizeof(IDX_F));

		ip->ifp = ifp;

		/* インデックスファイルオープン */
		if ((ifp->fh = __OPEN(fileName)) == NULL) {
			_IDXClose(ip);
			return ERROR_DB_NOFILE;
		}

		strcpy(ifp->fileName, fileName);	/* ファイル名セーブ */

		/* 拡張インデックスチェック */
		if ((p = strrchr(fileName, '.')) != NULL) {
			if (strncmp(p, ".EDX", 4) == 0)
				ifp->exFlag = 1;
		}

		/* ヘッダ情報エリア確保 */
		if ((ifp->ihp = malloc(sizeof(IDX_H))) == 0) {
			_IDXClose(ip);
			return ERROR_DB_MEMORY;
		}
		ihp = ifp->ihp;

		/* ヘッダ情報読み込み */
		if (__READ(ifp->fh, (CHAR *)ihp, sizeof(IDX_H)) !=
							sizeof(IDX_H)) {
			_IDXClose(ip);
			return ERROR_DB_READ;
		}

		/* ヘッダ情報チェック */
		if (ihp->root == 0 || ihp->nBlock == 0 || ihp->lKey == 0 ||
				ihp->order == 0 || ihp->lRec == 0 ||
				ihp->index[0] == '\0') {
			_IDXClose(ip);
			return ERROR_DB_INDEXFILE;
		}

		/* ブロック長セット */
		if (ifp->exFlag)
			ifp->lBlock = (ihp->lBlock + 1) * BLOCK_SIZE;
		else
			ifp->lBlock = BLOCK_SIZE;

		/* IDX_F チェイン処理 */
		ifp->chain = pTopIDX_F;
		pTopIDX_F = ifp;
	} else {
#if defined (OS_WINDOWS)
		if ((ifp->fh = __OPEN(fileName)) == -1) {
			_IDXClose(ip);
			return ERROR_DB_FOPEN;
		}
#endif
		ip->ifp = ifp;
	}

#if defined (OS_WINDOWS)
	ip->fh = ifp->fh;
#endif

	/* IDX チェイン処理 */
	ip->chain = ifp->ip;
	ifp->ip = ip;

	*ipp = ip;

	return 0;
}

/*=======================================================================
 |
 |		インデックスファイル作成
 |
 |	SHORT	IDXCreate(fileName, key, uniq, ipp)
 |
 |		CHAR	*fileName;	インデックスファイル名
 |		CHAR	*key;		キー
 |		SHORT	uniq;		０：キーの重複を許す　１：許さない
 |		PIDX	*ipp;		ＩＤＸポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	IDXCreate(CHAR *fileName, CHAR *key, SHORT uniq, PIDX *ipp)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&csIDX);
	err = _IDXCreate(fileName, key, uniq, ipp);
	LEAVE_CRITICAL_SECTION(&csIDX);

	return err;
}

static	SHORT	_IDXCreate(CHAR *fileName, CHAR *key, SHORT uniq, PIDX *ipp)
{
	PIDX	ip;
	PIDX_F	ifp;
	CHAR	*p;

	/* フルパス名取得 */
/*
	_fullpath(pathName, fileName, sizeof(pathName));
	StringToUpper(pathName);
*/
	for (ifp = pTopIDX_F; ifp != NULL; ifp = ifp->chain) {
		if (strcmp(fileName, ifp->fileName) == 0) {
			return ERROR_DB_ARDYOPEN;
		}
	}

	/* インデックス管理情報エリア確保 */
	if ((ip = malloc(sizeof(IDX))) == 0)
		return ERROR_DB_MEMORY;
	memset(ip, 0, sizeof(IDX));

	/* インデックス管理情報エリア確保 */
	if ((ifp = malloc(sizeof(IDX_F))) == 0) {
		_IDXClose(ip);
		return ERROR_DB_MEMORY;
	}

	memset(ifp, 0, sizeof(IDX_F));

	ip->ifp = ifp;

	/* インデックスファイルオープン */
	if ((ifp->fh = __CREAT(fileName)) == NULL) {
		_IDXClose(ip);
		return ERROR_DB_NOFILE;
	}

#if defined (OS_WINDOWS)
	ip->fh = ifp->fh;
#endif

	strcpy(ifp->fileName, fileName);	/* ファイル名セーブ */

	/* 拡張インデックスチェック */
	if ((p = strrchr(fileName, '.')) != NULL) {
		if (strncmp(p, ".EDX", 4) == 0)
			ifp->exFlag = 1;
	}

	/* ヘッダ情報エリア確保 */
	if ((ifp->ihp = malloc(sizeof(IDX_H))) == 0) {
		_IDXClose(ip);
		return ERROR_DB_MEMORY;
	}

	/* ヘッダ情報設定 */
	memset(ifp->ihp, 0, sizeof(IDX_H));
	sprintf(ifp->ihp->index, "%s ", key);
	ifp->ihp->uniq = uniq ? (CHAR)1 : (CHAR)0;
	ifp->ihp->fFreeBlock = FLAG_FREEBLOCK;
	ifp->updateFlag = 1;

	/* IDX_F チェイン処理 */
	ifp->chain = pTopIDX_F;
	pTopIDX_F = ifp;

	/* IDX チェイン処理 */
	ip->chain = ifp->ip;
	ifp->ip = ip;

	*ipp = ip;

	return 0;
}

/*=======================================================================
 |
 |		インデックスファイル情報設定
 |
 |	SHORT	IDXSetInfo(ip, type, len)
 |
 |		PIDX	ip;		ＩＤＸポインタ
 |		SHORT	type;		０：文字型　１：数値型　２：整数型
 |		SHORT	len;		キーの長さ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	IDXSetInfo(PIDX ip, SHORT type, SHORT len)
{
	PIDX_F	ifp;
	PIDX_H	ihp;

	ifp = ip->ifp;
	ihp = ifp->ihp;

	if (ifp->exFlag) {
		ihp->lBlock = (len - 1) / 100;
		ifp->lBlock = (ihp->lBlock + 1) * BLOCK_SIZE;
	} else
		ifp->lBlock = BLOCK_SIZE;

	ihp->type = type;		/* データタイプ設定 */
	ihp->lKey = len;		/* キー長設定 */
	ihp->lRec = ((ihp->lKey - 1) & ~3) + 12;	/* レコード長設定 */
	ihp->order = (ifp->lBlock - 4) / ihp->lRec;	/* 次数設定 */

	return 0;
}

/*=======================================================================
 |
 |		インデックスファイル読み込み
 |
 |	SHORT	IDXRead(ip, bno, blkpp)
 |
 |		PIDX	ip;		ＩＤＸポインタ
 |		LONG	bno;		ブロック番号
 |		PIDX_B	*blkpp;		ブロック情報へのポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	IDXRead(PIDX ip, LONG bno, PIDX_B *blkpp)
{
	PIDX_B	*bpp, bp;
	int	i;
	int	size;
#if defined (OS_WNT)
	DWORD	numBytes;
#endif

	/* ブロックバッファポインタチェック */
	if (ip->bp == NULL)
		bpp = &ip->top;
	else
		bpp = &ip->bp->fwp;

	if (*bpp == NULL) {
		for (bp = ip->top, i = 0; bp != NULL; bp = bp->fwp, i++) {
			if (i > 100)
				return ERROR_DB_INDEXFILE;
		}

		/* ブロック情報エリア確保 */
		size = sizeof(IDX_B) + ip->ifp->lBlock * 2;
		if ((bp = malloc(size)) == 0)
			return ERROR_DB_MEMORY;
		memset(bp, 0, size);

		/* チェイン処理 */
		*bpp = bp;
		bp->bwp = ip->bottom;
		ip->bottom = bp;
	} else
		bp = *bpp;

	if (bp->bno != bno) {
		if (bno != 0) {
			/* ファイル読み込み */
			PIDX_F	ifp = ip->ifp;
			bp->bno = bno;
			__LSEEK(ifp->fh, bno * ifp->lBlock, SEEK_SET);
			if (__READ(ifp->fh, bp->block, ifp->lBlock) !=
								ifp->lBlock)
				return ERROR_DB_READ;
		}
	}

	ip->bp = bp;

	*blkpp = bp;

	return 0;
}

/*=======================================================================
 |
 |		ブロック情報エリア確保
 |
 |	SHORT	IDXGetBlk(ip, bno, blkpp)
 |
 |		PIDX	ip;		ＩＤＸポインタ
 |		LONG	bno;		ブロック番号
 |		PIDX_B	*blkpp;		ブロック情報へのポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	IDXGetBlk(PIDX ip, LONG bno, PIDX_B *blkpp)
{
	SHORT	err;

	/* エリア確保 */
	if ((err = IDXRead(ip, 0L, blkpp)) != 0)
		return err;

	(*blkpp)->bno = bno;		/* ブロック番号セット */

	return 0;
}

/*=======================================================================
 |
 |		インデックスファイル書き込み
 |
 |	SHORT	IDXWrite(ip, bp)
 |
 |		PIDX	ip;		ＩＤＸポインタ
 |		PIDX_B	bp;		ブロック情報ポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	IDXWrite(PIDX ip, PIDX_B bp)
{
	PIDX_F	ifp;
#if defined (OS_WNT) && !defined (_SERVER)
	DWORD	numBytes;
#endif

	ifp = ip->ifp;

	if (__WRITE2(ifp->fileName, ifp->fh, bp->block, ifp->lBlock,
					bp->bno * ifp->lBlock) != ifp->lBlock)
		return ERROR_DB_WRITE;

	ifp->updateFlag = 1;

	return 0;
}

/*=======================================================================
 |
 |		インデックスファイルクローズ
 |
 |	SHORT	IDXClose(ip)
 |
 |		PIDX	ip;		ＩＤＸポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	IDXClose(PIDX ip)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&csIDX);
	err = _IDXClose(ip);
	LEAVE_CRITICAL_SECTION(&csIDX);

	return err;
}

static	SHORT	_IDXClose(PIDX ip)
{
	PIDX	*ipp;
	PIDX_B	bp, fwp;
	PIDX_F	ifp, *ifpp;
	PIDX_H	ihp;
	PSBOOL	bNormal = FALSE;

	ifp = ip->ifp;

	/* IDX チェイン切り離し */
	if (ifp != NULL) {
		for (ipp = &ifp->ip; *ipp != 0; ipp = &(*ipp)->chain) {
			if ((*ipp) == ip) {
				*ipp = (*ipp)->chain;
				bNormal = TRUE;
				break;
			}
		}
	}

	if (ifp != NULL && ifp->ip == NULL) {
		ihp = ifp->ihp;

		if (bNormal && ihp != NULL && ifp->fh != NULL) {
			/* フリーブロックをカウントする */
			if (ihp->fFreeBlock != FLAG_FREEBLOCK) {
				ihp->nFreeBlock = _CountFreeBlock(ifp);
				ihp->fFreeBlock = FLAG_FREEBLOCK;
				ifp->updateFlag = 1;
			}

			/* フリーブロックが半数を越えたらパックする */
			if (ihp->nBlock > 2 &&
					ihp->nFreeBlock >= ihp->nBlock / 2)
				IDXPack(ip);
		}

		if (ifp->fh != NULL) {
			IDXFlush(ip, FALSE);	/* ファイル書き込み */
			__CLOSE(ifp->fh);	/* ファイルクローズ */
		}

		if (ihp != NULL)
			free(ihp);		/* ヘッダ情報エリア解放 */

		/* IDX_F チェイン切り離し */
		for (ifpp = &pTopIDX_F; *ifpp != 0; ifpp = &(*ifpp)->chain) {
			if ((*ifpp) == ifp) {
				*ifpp = (*ifpp)->chain;
				break;
			}
		}
		free(ifp);
	}
#if defined (OS_WINDOWS)
	else
		__CLOSE(ip->fh);
#endif

	/* ブロック情報エリア解放 */
	for (bp = ip->top; bp != NULL; bp = fwp) {
		fwp = bp->fwp;
		free(bp);
	}

	free(ip);		/* インデックス管理情報エリア解放 */

	return 0;
}

/*=======================================================================
 |
 |		インデックスファイル強制掃き出し
 |
 |	SHORT	IDXFlush(ip, bReopen)
 |
 |		PIDX	ip;		ＩＤＸポインタ
 |		PSBOOL	bReopen;	再オープンフラグ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	IDXFlush(PIDX ip, PSBOOL bReopen)
{
	PIDX_F	ifp;
#if defined (OS_WNT) && !defined (_SERVER)
	DWORD	numBytes;
#endif

	ifp = ip->ifp;

	if (ifp->updateFlag != 0) {
		/* ヘッダ情報書き込み */
		if (__WRITE2(ifp->fileName, ifp->fh, (CHAR *)ifp->ihp,
					sizeof(IDX_H), 0) != sizeof(IDX_H))
			return ERROR_DB_WRITE;
		ifp->updateFlag = 0;
	}

	if (bReopen) {
		__CLOSE(ifp->fh);
		ifp->fh = __OPEN(ifp->fileName);
	} else
		__FLUSH(ifp->fh);

	return 0;
}

/*=======================================================================
 |
 |		検索（完全一致，前方一致）
 |
 |	SHORT	IDXSearch(ip, key, len, recNo)
 |
 |		PIDX	ip;		ＩＤＸポインタ
 |		CHAR	*key;		検索する文字列
 |		SHORT	len;		検索する文字列の長さ
 |		LONG	*recNo;		レコード番号
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	IDXSearch(PIDX ip, VOID *key, SHORT len, LONG *recNo)
{
	PIDX_B	bp;
	PIDX_H	ihp;
	CHAR	*bufp;
	SHORT	m;
	LONG	bno;
	SHORT	left, right, mid;
	SHORT	err;

	ip->bp = NULL;		/* ブロックポインタ初期化 */

	*recNo = 0L;
	ihp = ip->ifp->ihp;	/* インデックスヘッダポインタセット */
	bno = ihp->root;	/* ルートブロックＮｏ．セット */
	for (;;) {
		/* ブロックデータ読み込み */
		if ((err = IDXRead(ip, bno, &bp)) != 0)
			return err;

		bufp = bp->block;
		m = *(SHORT *)bufp;	/* ブロック内データ個数取り出し */
		bufp += 4;

		if (m != 0) {
			/* バイナリサーチ */
			left = 0;
			right = m;
			while (left < right) {
				mid = (left + right) / 2;
				ip->keyp = &bufp[8 + ihp->lRec * mid];
				if (IDXCompare(ip, key, len) > 0)
					left = mid + 1;
				else
					right = mid;
			}

			bufp += ihp->lRec * left;
			bp->cp = left;

			ip->keyp = bufp + 8;
			if (m != left && IDXCompare(ip, key, len) == 0) {
				if (*(LONG *)bufp == 0) {
					*recNo = *(LONG *)(bufp + 4);
					break;
				}
			}
		} else
			bp->cp = 0;

		if ((bno = *(LONG *)bufp) == 0)
			break;
	}

	return 0;
}

/*=======================================================================
 |
 |		検索（範囲指定対応）
 |
 |	SHORT	IDXSearch2(ip, key, len, recNo)
 |
 |		PIDX	ip;		ＩＤＸポインタ
 |		CHAR	*key;		検索する文字列
 |		SHORT	len;		検索する文字列の長さ
 |		LONG	*recNo;		レコード番号
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	IDXSearch2(PIDX ip, VOID *key, SHORT len, LONG *recNo)
{
	PIDX_B	bp;
	PIDX_H	ihp;
	CHAR	*bufp;
	SHORT	m;
	LONG	bno;
	SHORT	left, right, mid;
	SHORT	err;

	ip->bp = NULL;		/* ブロックポインタ初期化 */

	*recNo = 0L;
	ihp = ip->ifp->ihp;	/* インデックスヘッダポインタセット */
	bno = ihp->root;	/* ルートブロックＮｏ．セット */
	for (;;) {
		/* ブロックデータ読み込み */
		if ((err = IDXRead(ip, bno, &bp)) != 0)
			return err;

		bufp = bp->block;
		m = *(SHORT *)bufp;	/* ブロック内データ個数取り出し */
		bufp += 4;

		if (m != 0) {
			/* バイナリサーチ */
			left = 0;
			right = m;
			while (left < right) {
				mid = (left + right) / 2;
				ip->keyp = &bufp[8 + ihp->lRec * mid];
				if (IDXCompare(ip, key, len) > 0)
					left = mid + 1;
				else
					right = mid;
			}

			bufp += ihp->lRec * left;
			bp->cp = left;
			ip->keyp = bufp + 8;

			if (m == left && *(LONG *)bufp == 0)
				break;

			if (*(LONG *)bufp == 0) {
				*recNo = *(LONG *)(bufp + 4);
				break;
			}
		} else
			bp->cp = 0;

		if ((bno = *(LONG *)bufp) == 0)
			break;
	}

	return 0;
}

/*=======================================================================
 |
 |		検索（レコード番号指定）
 |
 |	SHORT	IDXSearch3(ip, key, len, recNo, findRecNo)
 |
 |		PIDX	ip;		ＩＤＸポインタ
 |		CHAR	*key;		検索する文字列
 |		SHORT	len;		検索する文字列の長さ
 |		LONG	recNo;		検索レコード番号
 |		LONG	*findRecNo;	検索結果
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	IDXSearch3(PIDX ip, VOID *key, SHORT len, LONG recNo, LONG *findRecNo)
{
	PIDX_H	ihp;
	PIDX_B	bp;
	CHAR	*bufp;
	SHORT	m;
	LONG	bno;
	LONG	rno;
	SHORT	err;

	if (ip->ifp->exFlag)
		return IDXSearchEx(ip, key, len, recNo, findRecNo);

	if ((err = IDXSearch(ip, key, len, findRecNo)) != 0)
		return err;

	if (*findRecNo == recNo)
		return 0;

	*findRecNo = 0;
	ihp = ip->ifp->ihp;
	for (;;) {
		if ((bp = ip->bp) == NULL)
			break;
		bp->cp++;		/* カレントポインタ更新 */
		bufp = bp->block;
		m = *(SHORT *)bufp;	/* ブロック内データ個数取り出し */

		bufp += 4 + bp->cp * ihp->lRec;
		for (; bp->cp < m; bp->cp++) {
			if ((rno = *(LONG *)(bufp+4)) != 0) {
				if (rno == recNo) {
					ip->keyp = bufp + 8;
					if (IDXCompare(ip, key, len) == 0)
						*findRecNo = rno;
					goto break2;
				}
			}
			if (*(LONG *)bufp != 0)
				break;
			bufp += ihp->lRec;
		}

		if (bp->cp <= m && (bno = *(LONG *)bufp) != 0) {
			/* 下位ブロック読み込み */
			if ((err = IDXRead(ip, bno, &bp)) != 0)
				return err;
			bp->cp = -1;
		} else {
			/* 上位ブロックポインタセット */
			ip->bp = bp->bwp;
		}
	}
break2:
	return 0;
}

/*=======================================================================
 |
 |		拡張インデックスレコード番号検索
 |
 |	SHORT	IDXSearchEx(ip, key, len, recNo)
 |
 |		PIDX	ip;		ＩＤＸポインタ
 |		CHAR	*key;		検索する文字列
 |		SHORT	len;		検索する文字列の長さ
 |		LONG	recNo;		検索レコード番号
 |		LONG	*findRecNo;	検索結果
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	IDXSearchEx(PIDX ip, VOID *key, SHORT len, LONG recNo, LONG *findRecNo)
{
	PIDX_B	bp;
	PIDX_H	ihp;
	CHAR	*bufp;
	SHORT	m;
	LONG	bno;
	SHORT	left, right, mid;
	SHORT	err;

	ip->bp = NULL;		/* ブロックポインタ初期化 */

	*findRecNo = 0L;
	ihp = ip->ifp->ihp;	/* インデックスヘッダポインタセット */
	bno = ihp->root;	/* ルートブロックＮｏ．セット */
	for (;;) {
		/* ブロックデータ読み込み */
		if ((err = IDXRead(ip, bno, &bp)) != 0)
			return err;

		bufp = bp->block;
		m = *(SHORT *)bufp;	/* ブロック内データ個数取り出し */
		bufp += 4;

		if (m != 0) {
			/* バイナリサーチ */
			left = 0;
			right = m;
			while (left < right) {
				mid = (left + right) / 2;
				ip->keyp = &bufp[8 + ihp->lRec * mid];
				if (IDXCompareEx(ip, key, len, recNo) > 0)
					left = mid + 1;
				else
					right = mid;
			}

			bufp += ihp->lRec * left;
			bp->cp = left;

			ip->keyp = bufp + 8;
			if (m != left && IDXCompareEx(ip, key, len,
							recNo) == 0) {
				if (*(LONG *)bufp == 0) {
					*findRecNo = *(LONG *)(bufp + 4);
					break;
				}
			}
		} else
			bp->cp = 0;

		if ((bno = *(LONG *)bufp) == 0)
			break;
	}

	return 0;
}

/*=======================================================================
 |
 |		キーの比較
 |
 |	SHORT	IDXCompare(ip, key, len)
 |
 |		PIDX	ip;		ＩＤＸポインタ
 |		CHAR	*key;		比較する文字列
 |		SHORT	len;		比較する文字列の長さ
 |
 |		返値			比較結果
 |
 =======================================================================*/
SHORT	IDXCompare(PIDX ip, VOID *key, SHORT len)
{
	double	dTmp;
	LONG	lTmp;

	switch (ip->ifp->ihp->type) {
	case KEY_TYPE_C:	/* 文字型の場合 */
		return memcmp(key, ip->keyp, len);
	case KEY_TYPE_N:	/* 数値型の場合 */
		dTmp = *(double *)key - *(double *)ip->keyp;
		if (dTmp > 0.0)
			return 1;
		else if (dTmp < 0.0)
			return -1;
		else
			return 0;
	case KEY_TYPE_I:	/* 整数型の場合 */
		lTmp = *(LONG *)key - *(LONG *)ip->keyp;
		if (lTmp > 0L)
			return 1;
		else if (lTmp < 0L)
			return -1;
		else
			return 0;
	}
	return 0;
}

/*=======================================================================
 |
 |		キーの比較（拡張インデックス）
 |
 |	SHORT	IDXCompareEx(ip, key, len, recNo)
 |
 |		PIDX	ip;		ＩＤＸポインタ
 |		CHAR	*key;		比較する文字列
 |		SHORT	len;		比較する文字列の長さ
 |		LONG	recNo;		レコード番号
 |
 |		返値			比較結果
 |
 =======================================================================*/
SHORT	IDXCompareEx(PIDX ip, VOID *key, SHORT len, LONG recNo)
{
	int	iTmp;
	double	dTmp;
	LONG	lTmp;

	switch (ip->ifp->ihp->type) {
	case KEY_TYPE_C:	/* 文字型の場合 */
		iTmp = memcmp(key, ip->keyp, len);
		if (iTmp != 0)
			return iTmp;
		break;
	case KEY_TYPE_N:	/* 数値型の場合 */
		dTmp = *(double *)key - *(double *)ip->keyp;
		if (dTmp > 0.0)
			return 1;
		else if (dTmp < 0.0)
			return -1;
		break;
	case KEY_TYPE_I:	/* 整数型の場合 */
		lTmp = *(LONG *)key - *(LONG *)ip->keyp;
		if (lTmp > 0L)
			return 1;
		else if (lTmp < 0L)
			return -1;
		break;
	}

	lTmp = recNo - *(LONG *)(ip->keyp - 4);
	if (lTmp > 0L)
		return 1;
	else if (lTmp < 0L)
		return -1;
	else
		return 0;
}

/*=======================================================================
 |
 |		キーの挿入
 |
 |	SHORT	IDXStore(ip, key, rno)
 |
 |		PIDX	ip;		ＩＤＸポインタ
 |		CHAR	*key;		挿入するキー
 |		LONG	rno;		レコード番号
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	IDXStore(PIDX ip, CHAR *key, LONG rno)
{
	PIDX_B	bp;
	PIDX_H	ihp;
	LONG	bno;
	SHORT	m, m1, m2;
	LONG	nRec;
	LONG	recNo;
	CHAR	*bufp;
	SHORT	exFlag;
	SHORT	err;
	CHAR	key_buf[256];

	ihp = ip->ifp->ihp;

	if ((exFlag = ip->ifp->exFlag)) {
		/* 重複キーチェック */
		if (ihp->uniq) {
			if ((err = IDXSearch(ip, key, ihp->lKey, &recNo)) != 0)
				return err;
			if (recNo != 0)
				return ERROR_DB_DBLKEY;
		}

		/* 挿入位置検索 */
		if ((err = IDXSearchEx(ip, key, ihp->lKey, rno, &recNo)) != 0)
			return err;
	} else {
		/* 挿入位置検索 */
		if ((err = IDXCount(ip, key, ihp->lKey, &nRec)) != 0)
			return err;

		/* 重複キーチェック */
		if (nRec != 0) {
			if (ihp->uniq)
				return ERROR_DB_DBLKEY;
		}
	}

	bno = 0;
	bp = ip->bp;
	for (;;) {
		if (bp == NULL) {
			/* ルートブロック再構築 */
			if ((err = IDXGetBlk(ip, ihp->nBlock++, &bp)) != 0)
				return err;
			*(SHORT *)bp->block = 0;
			*(LONG *)(bp->block + 4) = ihp->root;
			ihp->root = bp->bno;
			bp->cp = 0;
		}
		bufp = bp->block;
		m = *(SHORT *)bufp;	/* ブロック内データ個数取り出し */
		bufp += 8 + bp->cp * ihp->lRec;

		/* ブロック内に挿入 */
		memmove(bufp + ihp->lRec, bufp, ihp->lRec * (m - bp->cp));
		*(LONG *)bufp = rno;
		memmove(bufp + 4, key, ihp->lKey);
		*((LONG *)(bufp + ihp->lRec - 4)) = bno;

		if (++m > ihp->order) {
			/* ブロックの分割 */
			m1 = (m + 1) / 2;
			m2 = m - m1;
			bufp = bp->block + 4 + m1 * ihp->lRec;
			if (bno != 0)
				m1--;
			*(SHORT *)bp->block = m1;
			key = key_buf;
			memcpy(key, bufp - ihp->lRec + 8, ihp->lKey);
			if (exFlag)
				rno = *(LONG *)(bufp - ihp->lRec + 4);
			else
				rno = 0;

			if ((err = IDXWrite(ip, bp)) != 0)
				return err;

			bno = bp->bno = ihp->nBlock++;
			*(SHORT *)bp->block = m2;
			memcpy(bp->block + 4, bufp, m2 * ihp->lRec + 4);

			if ((err = IDXWrite(ip, bp)) != 0)
				return err;

			bp = bp->bwp;
		} else {
			*(SHORT *)bp->block = m;

			if ((err = IDXWrite(ip, bp)) != 0)
				return err;
			break;
		}
	}

	IDXFlushBlock(ip, FALSE);

	return 0;
}

/*=======================================================================
 |
 |		キーの削除
 |
 |	SHORT	IDXDelete(ip, LONG recNo)
 |
 |		PIDX	ip;		ＩＤＸポインタ
 |		LONG	recNo;		削除レコード番号
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	IDXDelete(PIDX ip, LONG recNo)
{
	PIDX_H	ihp;
	PIDX_B	bp;
	CHAR	*bufp, *key;
	SHORT	loopSW, m;
	SHORT	err;

	if ((err = IDXSet(ip, recNo)) != 0)
		return err;

	ihp = ip->ifp->ihp;
	key = NULL;
	recNo = 0;
	bp = ip->bp;
	loopSW = 1;
	while (loopSW) {
		if (bp == NULL)
			break;

		bufp = bp->block;
		m = *(SHORT *)bufp;	/* ブロック内データ個数取り出し */
		bufp += 4 + bp->cp * ihp->lRec;
		if (key == NULL) {
			if (m == 0) {
				*(LONG *)bufp = 0L;
			} else {
				if (*(LONG *)bufp == 0L && bp->cp == m-1) {
					if (m > 1) {
						key = bufp - ihp->lRec + 8;
						recNo = *(LONG *)
							(bufp - ihp->lRec + 4);
					}
				} else if (bp->cp == m) {
					/* ブロック内最終キー */
					key = bufp - ihp->lRec + 8;
					recNo = *(LONG *)
							(bufp - ihp->lRec + 4);
				} else {
					/* キー削除 */
					memcpy(bufp, bufp + ihp->lRec
					, ihp->lRec * (m - bp->cp - 1) + 4);
					loopSW = 0;
				}
				(*(SHORT *)bp->block)--;
			}
				
			if (*(SHORT *)bp->block == 0)
				ihp->nFreeBlock++;

			if ((err = IDXWrite(ip, bp)) != 0)
				return err;
		} else {
			if (bp->cp != m) {
				/* 上位ブロックのキー入れ替え */
				memcpy(bufp + 8, key, ihp->lKey);
				if (ip->ifp->exFlag)
					*(LONG *)(bufp + 4) = recNo;
				if ((err = IDXWrite(ip, bp)) != 0)
					return err;
				loopSW = 0;
			}
		}
		bp = bp->bwp;
	}

	IDXFlushBlock(ip, FALSE);

	return 0;
}

/*=======================================================================
 |
 |		次レコード番号取り出し
 |
 |	SHORT	IDXNext(ip, recNo)
 |
 |		PIDX	ip;		ＩＤＸポインタ
 |		LONG	*recNo;		レコード番号
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	IDXNext(PIDX ip, LONG *recNo)
{
	PIDX_H	ihp;
	PIDX_B	bp;
	CHAR	*bufp;
	SHORT	m;
	LONG	bno;
	SHORT	err;

	if ((err = IDXSet(ip, *recNo)) != 0)
		return err;

	*recNo = 0L;

	ihp = ip->ifp->ihp;
	for (;;) {
		if ((bp = ip->bp) == NULL)
			break;
		bp->cp++;		/* カレントポインタ更新 */
		bufp = bp->block;
		m = *(SHORT *)bufp;	/* ブロック内データ個数取り出し */

		bufp += 4 + bp->cp * ihp->lRec;
		if (bp->cp < m) {
			if (*(LONG *)bufp == 0) {
				ip->keyp = bufp + 8;
				*recNo = *(LONG *)(bufp + 4);
				goto break2;
			}
		}

		if (bp->cp <= m && (bno = *(LONG *)bufp) != 0) {
			/* 下位ブロック読み込み */
			if ((err = IDXRead(ip, bno, &bp)) != 0)
				return err;
			bp->cp = -1;
		} else {
			/* 上位ブロックポインタセット */
			ip->bp = bp->bwp;
		}
	}
break2:
	return 0;
}

/*=======================================================================
 |
 |		前レコード番号取り出し
 |
 |	SHORT	IDXBack(ip, recNo)
 |
 |		PIDX	ip;		ＩＤＸポインタ
 |		LONG	*recNo;		レコード番号
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	IDXBack(PIDX ip, LONG *recNo)
{
	PIDX_H	ihp;
	PIDX_B	bp;
	CHAR	*bufp;
	SHORT	m;
	LONG	bno;
	SHORT	err;

	if ((err = IDXSet(ip, *recNo)) != 0)
		return err;

	*recNo = 0L;

	ihp = ip->ifp->ihp;
	for (;;) {
		if ((bp = ip->bp) == NULL)
			break;
		bp->cp--;		/* カレントポインタ更新 */
		bufp = bp->block;
		m = *(SHORT *)bufp;	/* ブロック内データ個数取り出し */

		bufp += 4 + bp->cp * ihp->lRec;
		for (; bp->cp >= 0; bp->cp--) {
			if (bp->cp < m) {
				if (*(LONG *)bufp == 0) {
					ip->keyp = bufp + 8;
					*recNo = *(LONG *)(bufp + 4);
					goto break2;
				}
			}
			if (*(LONG *)bufp != 0)
				break;
			bufp -= ihp->lRec;
		}

		if (bp->cp >= 0 && (bno = *(LONG *)bufp) != 0) {
			/* 下位ブロック読み込み */
			if ((err = IDXRead(ip, bno, &bp)) != 0)
				return err;
			bp->cp = *(SHORT *)bp->block + 1;
		} else {
			/* 上位ブロックポインタセット */
			ip->bp = bp->bwp;
		}
	}
break2:
	return 0;
}

/*=======================================================================
 |
 |		先頭レコード番号取り出し
 |
 |	SHORT	IDXTop(ip, recNo)
 |
 |		PIDX	ip;		ＩＤＸポインタ
 |		LONG	*recNo;		レコード番号
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	IDXTop(PIDX ip, LONG *recNo)
{
	PIDX_B	bp;
	CHAR	*bufp;
	LONG	bno;
	SHORT	err;

	*recNo = 0L;

	ip->bp = NULL;		/* ブロックポインタ初期化 */

	bno = ip->ifp->ihp->root;	/* ルートブロック番号セット */
	for (;;) {
		/* ブロックデータ読み込み */
		if ((err = IDXRead(ip, bno, &bp)) != 0)
			return err;

		bufp = bp->block;

		bp->cp = 0;	/* カレントポインタクリア */

		bufp += 4;
		if ((bno = *(LONG *)bufp) == 0)
			break;
	}

	if (*(int *)bp->block != 0) {
		ip->keyp = bufp + 8;
		*recNo = *(LONG *)(bufp + 4);
	} else
		*recNo = 0L;

	return 0;
}

/*=======================================================================
 |
 |		最終レコード番号取り出し
 |
 |	SHORT	IDXBottom(ip, recNo)
 |
 |		PIDX	ip;		ＩＤＸポインタ
 |		LONG	*recNo;		レコード番号
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	IDXBottom(PIDX ip, LONG *recNo)
{
	PIDX_B	bp;
	CHAR	*bufp;
	LONG	bno;
	SHORT	err;

	*recNo = 0L;

	ip->bp = NULL;		/* ブロックポインタ初期化 */

	bno = ip->ifp->ihp->root;	/* ルートブロック番号セット */
	for (;;) {
		/* ブロックデータ読み込み */
		if ((err = IDXRead(ip, bno, &bp)) != 0)
			return err;

		bufp = bp->block;

		bp->cp = *(SHORT *)bufp;	/* カレントポインタセット */

		bufp += 4 + bp->cp * ip->ifp->ihp->lRec;
		if ((bno = *(LONG *)bufp) == 0)
			break;
	}

	if (*(int *)bp->block != 0) {
		bp->cp--;
		bufp -= ip->ifp->ihp->lRec;
	
		ip->keyp = bufp + 8;
		*recNo = *(LONG *)(bufp + 4);
	} else
		*recNo = 0L;

	return 0;
}

/*=======================================================================
 |
 |		一致するキーの個数を求める
 |
 |	SHORT	IDXCount(ip, key, len, count)
 |
 |		PIDX	ip;		ＩＤＸポインタ
 |		CHAR	*key;		検索する文字列
 |		SHORT	len;		検索する文字列の長さ
 |		LONG	*count;		一致するキーの個数
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	IDXCount(PIDX ip, VOID *key, SHORT len, LONG *count)
{
	LONG	rno;
	SHORT	err;

	*count = 0;

	if ((err = IDXSearch(ip, key, len, &rno)) != 0)
		return err;

	if (rno != 0) {
		for (;;) {
			if (IDXCompare(ip, key, len) != 0)
				break;
			(*count)++;
			if ((err = IDXNext(ip, &rno)) != 0)
				return err;
			if (rno == 0) {
				if ((err = IDXBottom(ip, &rno)) != 0)
					return err;
				ip->bp->cp++;
				break;
			}
		}
	}

	return 0;
}

/*=======================================================================
 |
 |		カレントポインタセット
 |
 |	SHORT	IDXSet(ip, recNo)
 |
 |		PIDX	ip;		ＩＤＸポインタ
 |		LONG	recNo;		カレントレコード番号
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	IDXSet(PIDX ip, LONG recNo)
{
	PIDX_H	ihp;
	PIDX_B	bp;
	CHAR	*bufp;
	SHORT	m;
	LONG	bno;
	LONG	rno;
	SHORT	err;

	if (ip->keyp != NULL && *(LONG *)(ip->keyp - 4) == recNo)
		return 0;

	if ((err = IDXTop(ip, &rno)) != 0)
		return err;

	ihp = ip->ifp->ihp;
	for (;;) {
		if ((bp = ip->bp) == NULL)
			break;
		bp->cp++;		/* カレントポインタ更新 */
		bufp = bp->block;
		m = *(SHORT *)bufp;	/* ブロック内データ個数取り出し */

		bufp += 4 + bp->cp * ihp->lRec;
		for (; bp->cp < m; bp->cp++) {
			if ((rno = *(LONG *)(bufp+4)) != 0) {
				if (rno == recNo) {
					ip->keyp = bufp + 8;
					goto break2;
				}
			}
			if (*(LONG *)bufp != 0)
				break;
			bufp += ihp->lRec;
		}

		if (bp->cp <= m && (bno = *(LONG *)bufp) != 0) {
			/* 下位ブロック読み込み */
			if ((err = IDXRead(ip, bno, &bp)) != 0)
				return err;
			bp->cp = -1;
		} else {
			/* 上位ブロックポインタセット */
			ip->bp = bp->bwp;
		}
	}
break2:
	return 0;
}

/*=======================================================================
 |
 |		バッファフラッシュ
 |
 |	SHORT	IDXFlushBlock(ip, bSelf)
 |
 |		PIDX	ip;		ＩＤＸポインタ
 |		PSBOOL	bSelf;		自ｉｐ処理フラグ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
VOID	IDXFlushBlock(PIDX ip, PSBOOL bSelf)
{
	PIDX	ipTmp;
	PIDX_B	bp;

	ENTER_CRITICAL_SECTION(&csIDX);
	for (ipTmp = ip->ifp->ip; ipTmp != NULL; ipTmp = ipTmp->chain) {
		if (bSelf || ipTmp != ip) {
			for (bp = ipTmp->top; bp != NULL; bp = bp->fwp)
				bp->bno = 0L;
			ipTmp->keyp = NULL;
		}
	}
	LEAVE_CRITICAL_SECTION(&csIDX);
}

/*=======================================================================
 |
 |		インデックスファイルパック処理
 |
 |	SHORT	IDXPack(ip)
 |
 |		PIDX	ip;		インデックスファイルポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	IDXPack(PIDX ip)
{
	PIDX_F	ifp;
	PIDX_H	ihp;
	FILE	*fh;
	LONG	bno = 0;
	LONG	rno;
	LONG	nBlock;
	int	level;
	SHORT	err;
	CHAR	key[256];
	PSBOOL	keyFlag;
	CHAR	tmpFile[256];

	ifp = ip->ifp;
	ihp = ifp->ihp;

	strcpy(tmpFile, ifp->fileName);
	SetExtention(tmpFile, "$$1");
	if ((fh = __CREAT(tmpFile)) == NULL)
		return ERROR_DB_TMPFILE;

	memset(key, 0, ihp->lKey);
	nBlock = 1;
	level = 0;
	keyFlag = FALSE;

	if ((err = IDXTop(ip, &rno)) == 0) {
		do {
			if ((err = _IDXPack(tmpFile, ip, fh, level++, &nBlock,
					key, &keyFlag, &bno, &rno)) != 0)
				break;
		} while (rno != 0);
	}


	__CLOSE(fh);

	if (err == 0) {
		__CLOSE(ifp->fh);
		__DELETE(ifp->fileName);

		__RENAME(tmpFile, ifp->fileName);
		ifp->fh = __OPEN(ifp->fileName);

		ihp->root = bno;
		ihp->nBlock = nBlock;
		ihp->nFreeBlock = 0;

		ifp->updateFlag = 1;

		IDXFlushBlock(ip, TRUE);
	} else {
		__DELETE(tmpFile);
	}

	return err;
}

/*=======================================================================
 |
 |		インデックスファイルパック処理
 |
 |	SHORT	_IDXPack(fileName, ip, fh, level, nBlock, key, keyFlag,
 |								bno, rno)
 |
 |		CHAR	*fileName;	ファイル名
 |		PIDX	ip;		インデックスファイルポインタ
 |		int	fh;		ファイルハンドル
 |		int	level;		階層数
 |		LONG	nBlock;		書き込みブロック数
 |		CHAR	*key;		キー
 |		PSBOOL	*keyFlag;	初回キー書き込みフラグ
 |		LONG	*bno;		ブロック番号
 |		LONG	*rno;		レコード番号
 |
 |		返値			エラーコード
 |
 =======================================================================*/
static	SHORT	_IDXPack(CHAR *fileName, PIDX ip, FILE *fh, int level,
					LONG *nBlock, CHAR *key, PSBOOL *keyFlag,
					LONG *bno, LONG *rno)
{
	PIDX_F	ifp;
	PIDX_H	ihp;
	CHAR	*blockp;
	CHAR	*bufp;
	int	i;
	SHORT	err;
#if defined (OS_WNT) && !defined (_SERVER)
	DWORD	numBytes;
#endif

	ifp = ip->ifp;
	ihp = ifp->ihp;

	if ((blockp = malloc(ifp->lBlock)) == 0)
		return ERROR_DB_MEMORY;
	memset(blockp, 0, ifp->lBlock);

	bufp = blockp + 4;

	if (level == 0) {
		for (i = 0; i < ihp->order && *rno != 0; ) {
			*(LONG *)(bufp + 4) = *rno;
			memcpy(bufp + 8, ip->keyp, ihp->lKey);

			if (ihp->uniq && *keyFlag) {
				if (memcmp(bufp + 8, key, ihp->lKey) == 0)
					continue;
			}

			*(LONG *)bufp = 0;
			memcpy(key, bufp + 8, ihp->lKey);
			*keyFlag = TRUE;
			bufp += ihp->lRec;
			i++;

			if ((err = IDXNext(ip, rno)) != 0) {
				free(blockp);
				return err;
			}
		}
		*(LONG *)bufp = 0;
	} else {
		if (*bno == 0) {
			if ((err = _IDXPack(fileName, ip, fh, level - 1,
							nBlock, key, keyFlag,
							bno, rno)) != 0) {
				free(blockp);
				return err;
			}
		}

		for (i = 0; i < ihp->order && *rno != 0; i++) {
			*(LONG *)bufp = *bno;
			if (ifp->exFlag)
				*(LONG *)(bufp + 4) = *rno;
			else
				*(LONG *)(bufp + 4) = 0;
			memcpy(bufp+8, key, ihp->lKey);
			*bno = 0;
			if ((err = _IDXPack(fileName, ip, fh, level - 1,
							nBlock, key, keyFlag,
							bno, rno)) != 0) {
				free(blockp);
				return err;
			}
			bufp += ihp->lRec;
		}
		*(LONG *)bufp = *bno;
	}

	*(SHORT *)blockp = i;

	if (__WRITE2(fileName, fh, blockp, ifp->lBlock,
				*nBlock * ifp->lBlock) != ifp->lBlock) {
		free(blockp);
		return ERROR_DB_WRITE;
	}

	*bno = (*nBlock)++;

	free(blockp);

	return 0;
}

/*=======================================================================
 |
 |		フリーブロックカウント処理
 |
 |	SHORT	_CountFreeBlock(ifp)
 |
 |		PIDX_F	ifp;		インデックスファイルポインタ
 |
 |		返値			フリーブロック数
 |
 =======================================================================*/
static	ULONG	_CountFreeBlock(PIDX_F ifp)
{
	ULONG	count;
	CHAR	*bufp;
#if defined (OS_WNT)
	DWORD	numBytes;
#endif

	if ((bufp = malloc(ifp->lBlock)) == NULL)
		return 0;

	__LSEEK(ifp->fh, ifp->lBlock, SEEK_SET);

	count = 0;
	for (;;) {
		if (__READ(ifp->fh, bufp, ifp->lBlock) != ifp->lBlock)
			break;

		if (*(SHORT *)bufp == 0)
			count++;
	}

	free(bufp);

	return count;
}
