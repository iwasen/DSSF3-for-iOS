/************************************************************************
 *
 *			ＰＣ−ＳＥＲＶＥ
 *
 *		名称		: データファイル操作
 *		ファイル名	: dbf.c
 *		作成者		: s.aizawa
 *
 ************************************************************************/

#include "PCSOS.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "pcsdef.h"
#include "PCSDB.h"
#include "PCSDBSUB.h"
#include "PCSCOM.h"

static	SHORT	_DBFOpen(CHAR *, PDBF *);
static	SHORT	_DBFCreate(CHAR *, PDBF_I, SHORT, PDBF *);
static	SHORT	_DBFClose(PDBF);

static	PDBF	pTopDBF;
CRITICALSECTION	csDBF;		/* DBF クリチカルセクション */

/*=======================================================================
 |
 |		データファイルオープン
 |
 |	SHORT	DBFOpen(fileName, &dpp)
 |
 |		CHAR	*fileName;	データファイル名
 |		PDBF	*dpp;		ＤＢＦポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBFOpen(CHAR *fileName, PDBF *dpp)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&csDBF);
	err = _DBFOpen(fileName, dpp);
	LEAVE_CRITICAL_SECTION(&csDBF);

	return err;
}

static	SHORT	_DBFOpen(CHAR *fileName, PDBF *dpp)
{
	PDBF	dp;
	PDBF_H	dhp;
	PFIELD	flp;
	SHORT	i;
	SHORT	offset;
	LONG	nRec;
	CHAR	buf[2];
#if defined (OS_WNT)
	DWORD	numBytes;
#endif
	PSBOOL	fBinaryField;
	CHAR	binFileName[256];
	CHAR	*p;
	SHORT	err;

	/* フルパス名取得 */
/*
	_fullpath(pathName, fileName, sizeof(pathName));
	StringToUpper(pathName);
*/
	for (dp = pTopDBF; dp != NULL; dp = dp->chain) {
		if (strcmp(fileName, dp->fileName) == 0) {
#if defined (MULTI_OPEN)
			if ((dp->fh = __OPEN(pathName)) == -1)
				return ERROR_DB_FOPEN;
#endif
			*dpp = dp;
			return 0;
		}
	}

	/* データファイル管理情報エリア確保 */
	if ((dp = malloc(sizeof(DBF))) == 0)
		return ERROR_DB_MEMORY;

	memset(dp, 0, sizeof(DBF));
	INIT_CRITICAL_SECTION(&dp->csDBF);

	/* データファイルオープン */
	if ((dp->fh = __OPEN(fileName)) == NULL) {
		_DBFClose(dp);
		return ERROR_DB_NOFILE;
	}

	strcpy(dp->fileName, fileName);	/* ファイル名セーブ */

	/* ヘッダ情報エリア確保 */
	if ((dhp = malloc(sizeof(DBF_H))) == 0) {
		_DBFClose(dp);
		return ERROR_DB_MEMORY;
	}
	dp->dhp = dhp;

	/* ヘッダ情報読み込み */
	if (__READ(dp->fh, (CHAR *)dhp, sizeof(DBF_H)) != sizeof(DBF_H)) {
		_DBFClose(dp);
		return ERROR_DB_READ;
	}

	/* フィールド情報エリア確保 */
	dp->nField = (dhp->lHeader - 33) / 32;
	if ((dp->flp = malloc(sizeof(FIELD) * dp->nField)) == 0) {
		_DBFClose(dp);
		return ERROR_DB_MEMORY;
	}

	/* フィールド情報読み込み */
	if (__READ(dp->fh, (CHAR *)dp->flp, sizeof(FIELD) * dp->nField) !=
					(int)(sizeof(FIELD) * dp->nField)) {
		_DBFClose(dp);
		return ERROR_DB_READ;
	}

	/* フィールドポインタセット */
	flp = dp->flp;
	offset = 0;
	fBinaryField = FALSE;
	for (i = 0; i < dp->nField; i++) {
		if (dhp->extField != EXT_FIELD)
			flp->lField2 = flp->lField;
		flp->offset = offset;
		offset += flp->lField2;

		if (flp->type == 'B')
			fBinaryField = TRUE;
		else
			dp->lRec += flp->lField2;

		flp++;
	}

	/* バイナリファイルオープン */
	if (fBinaryField) {
		strcpy(binFileName, fileName);
		if ((p = strrchr(binFileName, '.')) == NULL)
			p = binFileName + strlen(binFileName);
		strcpy(p, ".BIN");
		if ((err = BINOpen(binFileName, &dp->bfp)) != 0) {
			if (err == ERROR_DB_NOFILE && (err = BINCreate(binFileName, &dp->bfp)) != 0) {
				_DBFClose(dp);
				return err;
			}
		}
	}

	/* レコード数調整 */
	nRec = (int)(__LSEEK(dp->fh, 0L, SEEK_END) - dhp->lHeader) / dhp->lRec;
	if (nRec < 0)
		nRec = 0;
	if (nRec > dhp->nRec) {
		__LSEEK(dp->fh, dhp->lHeader + dhp->nRec * dhp->lRec, SEEK_SET);
		if (__READ(dp->fh, buf, 1) == 1) {
			if (buf[0] == 0x1a)
				nRec = dhp->nRec;
		}
	}
	if (nRec != dhp->nRec) {
		dhp->nRec = nRec;
		dp->updateFlag = TRUE;	/* ファイル更新フラグセット */
		dp->adjustFlag = TRUE;
	}

	/* チェイン処理 */
	dp->chain = pTopDBF;
	pTopDBF = dp;

	*dpp = dp;

	return 0;
}

/*=======================================================================
 |
 |		データファイル作成
 |
 |	SHORT	DBFCreate(fileName, dip, nField, dpp)
 |
 |		CHAR	*fileName;	データファイル名
 |		PDBF_I	dip;		データファイル情報
 |		SHORT	nField;		フィールド数
 |		PDBF	*dpp;		ＤＢＦポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBFCreate(CHAR *fileName, PDBF_I dip, SHORT nField, PDBF *dpp)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&csDBF);
	err = _DBFCreate(fileName, dip, nField, dpp);
	LEAVE_CRITICAL_SECTION(&csDBF);

	return err;
}

static	SHORT	_DBFCreate(CHAR *fileName, PDBF_I dip, SHORT nField, PDBF *dpp)
{
	PDBF	dp;
	PDBF_H	dhp;
	PFIELD	flp;
	SHORT	i;
	SHORT	offset;
	PSBOOL	fExtField;
	static	CHAR	cr_eof[2] = {0x0d, 0x1a};
#if defined (OS_WNT) && !defined (_SERVER)
	DWORD	numBytes;
#endif
	PSBOOL	fBinaryField;
	CHAR	binFileName[256];
	CHAR	*p;
	SHORT	err;

	/* フルパス名取得 */
/*
	_fullpath(pathName, fileName, sizeof(pathName));
	StringToUpper(pathName);
*/
	for (dp = pTopDBF; dp != NULL; dp = dp->chain) {
		if (strcmp(fileName, dp->fileName) == 0) {
			return ERROR_DB_ARDYOPEN;
		}
	}

	/* データファイル管理情報エリア確保 */
	if ((dp = malloc(sizeof(DBF))) == 0)
		return ERROR_DB_MEMORY;

	memset(dp, 0, sizeof(DBF));
	INIT_CRITICAL_SECTION(&dp->csDBF);

	/* データファイルオープン */
	if ((dp->fh = __CREAT(fileName)) == NULL) {
		_DBFClose(dp);
		return ERROR_DB_FOPEN;
	}

	strcpy(dp->fileName, fileName);	/* ファイル名セーブ */

	/* ヘッダ情報エリア確保 */
	if ((dhp = malloc(sizeof(DBF_H))) == 0) {
		_DBFClose(dp);
		return ERROR_DB_MEMORY;
	}
	memset(dhp, 0, sizeof(DBF_H));
	dp->dhp = dhp;

	/* ヘッダ情報設定 */
	dhp->flag = 0x03;
	dhp->lHeader = (nField + 1) * 32 + 1;

	/* フィールド情報エリア確保 */
	dp->nField = nField;
	if ((dp->flp = malloc(sizeof(FIELD) * nField)) == 0) {
		_DBFClose(dp);
		return ERROR_DB_MEMORY;
	}
	memset(dp->flp, 0, sizeof(FIELD) * nField);

	fExtField = FALSE;
	for (i = 0; i < nField; i++) {
		if (dip[i].lField > 255) {
			fExtField = TRUE;
			dhp->extField = EXT_FIELD;
			dhp->flag = 0x04;
			break;
		}
	}

	/* フィールド情報設定 */
	fBinaryField = FALSE;
	for (i = 0, flp = dp->flp, dhp->lRec = 1; i < nField; i++, flp++) {
		strcpy(flp->name, dip->name);
		StringToUpper(flp->name);
		flp->type = (dip->type >= 'a' && dip->type <= 'z') ? dip->type - 0x20 : dip->type;

		/* フィールド種別チェック */
		switch (flp->type) {
		case 'B':
			fBinaryField = TRUE;
			flp->lField2 = 4;
			break;
		case 'C':
		case 'D':
		case 'I':
		case 'L':
		case 'N':
			if (fBinaryField != 0) {
				_DBFClose(dp);
				return ERROR_DB_FIELD;
			}

			flp->lField2 = dip->lField;
			dp->lRec += flp->lField2;
			break;
		default:
			_DBFClose(dp);
			return ERROR_DB_FIELD;
		}

		if (flp->type == 'N')
			flp->lDec = (CHAR)dip->lDec;
		else
			flp->lDec = (CHAR)0;

		flp->lField = (CHAR)flp->lField2;
		dhp->lRec += flp->lField2;
		dip++;
	}

	/* バイナリファイル作成 */
	if (fBinaryField) {
		strcpy(binFileName, fileName);
		if ((p = strrchr(binFileName, '.')) == NULL)
			p = binFileName + strlen(binFileName);
		strcpy(p, ".BIN");
		if ((err = BINCreate(binFileName, &dp->bfp)) != 0) {
			_DBFClose(dp);
			return err;
		}
	}

	/* ヘッダ情報書き込み */
	if (__WRITE(pathName, dp->fh, (CHAR *)dp->dhp, sizeof(DBF_H)) !=
							sizeof(DBF_H)) {
		_DBFClose(dp);
		return ERROR_DB_WRITE;
	}

	/* フィールド情報書き込み */
	if (__WRITE(pathName, dp->fh, (CHAR *)dp->flp,
				sizeof(FIELD) * dp->nField) !=
				(int)(sizeof(FIELD) * dp->nField)) {
		_DBFClose(dp);
		return ERROR_DB_WRITE;
	}

	/* 区切り文字＆ＥＯＦ書き込み */
	if (__WRITE(pathName, dp->fh, cr_eof, 2) != 2) {
		_DBFClose(dp);
		return ERROR_DB_WRITE;
	}

	/* フィールドポインタセット */
	flp = dp->flp;
	offset = 0;
	for (i = 0; i < nField; i++) {
		flp->offset = offset;
		offset += flp->lField2;
		flp++;
	}

	dp->updateFlag = 1;
	dp->updateCount++;

	/* チェイン処理 */
	dp->chain = pTopDBF;
	pTopDBF = dp;

	*dpp = dp;

	return 0;
}

/*=======================================================================
 |
 |		レコード読み込み（レコード全体）
 |
 |	SHORT	DBFRead(dp, rno, bufp)
 |
 |		PDBF	dp;		ＤＢＦポインタ
 |		LONG	rno;		レコード番号
 |		CHAR	*bufp;		バッファポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBFRead(PDBF dp, LONG rno, CHAR *bufp)
{
	PDBF_H	dhp;
#if defined (OS_WNT)
	DWORD	numBytes;
#endif

	dhp = dp->dhp;

	/* レコード番号が範囲外ならエラー */
	if (rno <= 0 || rno > dhp->nRec)
		return ERROR_DB_RECNO;

	/* 読み込み */
	__LSEEK(dp->fh, dhp->lHeader + dhp->lRec*(rno-1), SEEK_SET);
	if (__READ(dp->fh, bufp, dhp->lRec) != (int)dhp->lRec)
		return ERROR_DB_READ;

	if (dhp->scramble != 0)
		Scramble2(bufp + 1, dp->lRec, dhp->scramble);

	return 0;
}

/*=======================================================================
 |
 |		レコード読み込み（削除マーク，バイナリフィールドを除く）
 |
 |	SHORT	DBFRead2(dp, rno, bufp)
 |
 |		PDBF	dp;		ＤＢＦポインタ
 |		LONG	rno;		レコード番号
 |		CHAR	*bufp;		バッファポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBFRead2(PDBF dp, LONG rno, CHAR *bufp)
{
	PDBF_H	dhp;
#if defined (OS_WNT)
	DWORD	numBytes;
#endif

	dhp = dp->dhp;

	/* レコード番号が範囲外ならエラー */
	if (rno <= 0 || rno > dhp->nRec)
		return ERROR_DB_RECNO;

	/* 読み込み */
	__LSEEK(dp->fh, dhp->lHeader + dhp->lRec*(rno-1) + 1, SEEK_SET);
	if (__READ(dp->fh, bufp, dp->lRec) != (int)dp->lRec)
		return ERROR_DB_READ;

	if (dhp->scramble != 0)
		Scramble2(bufp, dp->lRec, dhp->scramble);

	return 0;
}

/*=======================================================================
 |
 |		レコード書き込み（レコード全体）
 |
 |	SHORT	DBFWrite(dp, rno, bufp)
 |
 |		PDBF	dp;		ＤＢＦポインタ
 |		LONG	rno;		レコード番号
 |		CHAR	*bufp;		バッファポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBFWrite(PDBF dp, LONG rno, CHAR *bufp)
{
	PDBF_H	dhp;
	int	rc;
#if defined (OS_WNT) && !defined (_SERVER)
	DWORD	numBytes;
#endif

	dhp = dp->dhp;

	/* レコード番号が範囲外ならエラー */
	if (rno <= 0 || rno > dhp->nRec)
		return ERROR_DB_RECNO;

	if (dhp->scramble != 0)
		Scramble1(bufp + 1, dp->lRec, dhp->scramble);

	/* 書き込み */
	rc = (int)__WRITE2(dp->fileName, dp->fh, bufp, dhp->lRec,
				dhp->lHeader + dhp->lRec*(rno-1));

	if (dhp->scramble != 0)
		Scramble2(bufp + 1, dp->lRec, dhp->scramble);

	if (rc != (int)dhp->lRec)
		return ERROR_DB_WRITE;

	dp->updateFlag = 1;		/* ファイル更新フラグセット */
	dp->updateCount++;

	return 0;
}

/*=======================================================================
 |
 |		レコード書き込み（削除マーク，バイナリフィールドを除く）
 |
 |	SHORT	DBFWrite2(dp, rno, bufp)
 |
 |		PDBF	dp;		ＤＢＦポインタ
 |		LONG	rno;		レコード番号
 |		CHAR	*bufp;		バッファポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBFWrite2(PDBF dp, LONG rno, CHAR *bufp)
{
	PDBF_H	dhp;
	int	rc;
#if defined (OS_WNT) && !defined (_SERVER)
	DWORD	numBytes;
#endif

	dhp = dp->dhp;

	/* レコード番号が範囲外ならエラー */
	if (rno <= 0 || rno > dhp->nRec)
		return ERROR_DB_RECNO;

	if (dhp->scramble != 0)
		Scramble1(bufp, dp->lRec, dhp->scramble);

	/* 書き込み */
	rc = (int)__WRITE2(dp->fileName, dp->fh, bufp, dp->lRec,
					dhp->lHeader + dhp->lRec*(rno-1) + 1);

	if (dhp->scramble != 0)
		Scramble2(bufp, dp->lRec, dhp->scramble);

	if (rc != (int)dp->lRec)
		return ERROR_DB_WRITE;

	dp->updateFlag = 1;		/* ファイル更新フラグセット */
	dp->updateCount++;

	return 0;
}

/*=======================================================================
 |
 |		データファイルクローズ
 |
 |	SHORT	DBFClose(dp)
 |
 |		PDBF	dp;		ＤＢＦポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBFClose(PDBF dp)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&csDBF);
	err = _DBFClose(dp);
	LEAVE_CRITICAL_SECTION(&csDBF);

	return err;
}

static	SHORT	_DBFClose(PDBF dp)
{
	PDBF	*ppDBF;

	if (dp->fh != NULL) {
		DBFFlush(dp, FALSE);	/* ファイル書き込み */
		__CLOSE(dp->fh);	/* ファイルクローズ */
	}

	if (dp->bfp != NULL)
		BINClose(dp->bfp);	/* バイナリファイルクローズ */

	if (dp->dhp != NULL)
		free(dp->dhp);		/* ヘッダ情報エリア解放 */

	if (dp->flp != NULL)
		free(dp->flp);		/* フィールド情報エリア解放 */

	/* チェイン切り離し */
	for (ppDBF = &pTopDBF; *ppDBF != 0; ppDBF = &(*ppDBF)->chain) {
		if ((*ppDBF) == dp) {
			*ppDBF = (*ppDBF)->chain;
			break;
		}
	}

	DELETE_CRITICAL_SECTION(&dp->csDBF);

	free(dp);		/* データファイル管理情報エリア解放 */

	return 0;
}

/*=======================================================================
 |
 |		データファイル強制掃き出し
 |
 |	SHORT	DBFFlush(dp, bReopen)
 |
 |		PDBF	dp;		ＤＢＦポインタ
 |		PSBOOL	bReopen;	再オープンフラグ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBFFlush(PDBF dp, PSBOOL bReopen)
{
	static	CHAR	eof[1] = {0x1a};
	PDBF_H	dhp;
	long	ltime;
	struct	tm	*tmp;
#if defined (OS_WNT) && !defined (_SERVER)
	DWORD	numBytes;
#endif

	if (dp->updateFlag != 0) {
		dhp = dp->dhp;

		/* 最終更新日書き込み */
		time(&ltime);
		tmp = localtime(&ltime);
		dhp->date[0] = (CHAR)tmp->tm_year;
		dhp->date[1] = (CHAR)(tmp->tm_mon + 1);
		dhp->date[2] = (CHAR)tmp->tm_mday;

		/* ヘッダ書き込み */
		if (__WRITE2(dp->fileName, dp->fh, (CHAR *)dp->dhp,
					sizeof(DBF_H), 0) != sizeof(DBF_H))
			return ERROR_DB_WRITE;

		/* ＥＯＦ書き込み */
		if (__WRITE2(dp->fileName, dp->fh, eof, 1,
				dhp->lHeader + dhp->lRec * dhp->nRec) != 1)
			return ERROR_DB_WRITE;

		dp->updateFlag = 0;
	}

	if (bReopen) {
		__CLOSE(dp->fh);
		dp->fh = __OPEN(dp->fileName);
	} else
		__FLUSH(dp->fh);

	if (dp->bfp != NULL)
		BINFlush(dp->bfp, bReopen);

	return 0;
}

/*=======================================================================
 |
 |		削除マークセット
 |
 |	SHORT	DBFDelete(dp, rno)
 |
 |		PDBF	dp;		ＤＢＦポインタ
 |		LONG	rno;		レコード番号
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBFDelete(PDBF dp, LONG rno)
{
	PDBF_H	dhp;
	CHAR	mark[1];
#if defined (OS_WNT) && !defined (_SERVER)
	DWORD	numBytes;
#endif

	dhp = dp->dhp;

	/* レコード番号が範囲外ならエラー */
	if (rno <= 0 || rno > dhp->nRec)
		return ERROR_DB_RECNO;

	/* 削除フラグセット */
	mark[0] = '*';
	if (__WRITE2(dp->fileName, dp->fh, mark, 1,
				dhp->lHeader + dhp->lRec*(rno-1)) != 1)
		return ERROR_DB_WRITE;

	dp->updateFlag = 1;		/* ファイル更新フラグセット */
	dp->updateCount++;

	return 0;
}

/*=======================================================================
 |
 |		削除マーク取り消し
 |
 |	SHORT	DBFRecall(dp, rno)
 |
 |		PDBF	dp;		ＤＢＦポインタ
 |		LONG	rno;		レコード番号
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBFRecall(PDBF dp, LONG rno)
{
	PDBF_H	dhp;
	CHAR	mark[1];
#if defined (OS_WNT) && !defined (_SERVER)
	DWORD	numBytes;
#endif

	dhp = dp->dhp;

	/* レコード番号が範囲外ならエラー */
	if (rno <= 0 || rno > dhp->nRec)
		return ERROR_DB_RECNO;

	/* 削除フラグリセット */
	mark[0] = ' ';
	if (__WRITE2(dp->fileName, dp->fh, mark, 1,
				dhp->lHeader + dhp->lRec*(rno-1)) != 1)
		return ERROR_DB_WRITE;

	dp->updateFlag = 1;		/* ファイル更新フラグセット */
	dp->updateCount++;

	return 0;
}

/*=======================================================================
 |
 |		削除マークがついているレコードをファイルから削除
 |
 |	SHORT	DBFPack(dp)
 |
 |		PDBF	dp;		ＤＢＦポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBFPack(PDBF dp)
{
	PDBF_H	dhp;
	PBIN	bfp;
	PDB	dbp2;
	PDBLOCK	dlp;
	PFIELD	flp;
	LONG	r_rno, w_rno;
	CHAR	*rbp;
	CHAR	*fdp;
	int	i;
	SHORT	err = 0;
	CHAR	binFileName[256];
	CHAR	binTempFileName[256];
	CHAR	dbfBackupFileName[256];
	PBIN	bfpTemp;
	CHAR	*p;
	LONG	bno;
	PSBOOL	bWriteBinary;
	PSBOOL	bRc;

	dhp = dp->dhp;
	bfp = dp->bfp;

	if ((rbp = malloc(dhp->lRec)) == NULL)
		return ERROR_DB_MEMORY;

	/* 削除マークが付いているレコードを削除する */
	for (r_rno = w_rno = 0; r_rno < dhp->nRec; ) {
		if ((err = DBFRead(dp, ++r_rno, rbp)) != 0)
			break;

		if (rbp[0] != '*') {
			if (r_rno != ++w_rno) {
				if ((err = DBFWrite(dp, w_rno, rbp)) != 0)
					break;

				/* カレントレコード番号補正 */
				ENTER_CRITICAL_SECTION(&csDBF);
				for (dbp2 = dp->dbp; dbp2 != NULL;
							dbp2 = dbp2->chain) {
					if (dbp2->rno == r_rno)
						dbp2->rno = w_rno;
				}
				LEAVE_CRITICAL_SECTION(&csDBF);

				/* ロックレコード番号補正 */
				for (dlp = dp->rdlp; dlp != NULL;
							dlp = dlp->chain) {
					if (dlp->rno == r_rno)
						dlp->rno = w_rno;
				}
				for (dlp = dp->wdlp; dlp != NULL;
							dlp = dlp->chain) {
					if (dlp->rno == r_rno)
						dlp->rno = w_rno;
				}
			}
		} else {
			/* バイナリデータの削除 */
			if (bfp != NULL) {
				for (i = 0, flp = dp->flp; i < dp->nField; i++, flp++) {
					if (flp->type == 'B') {
						fdp = &rbp[flp->offset + 1];
						BINDelete(bfp, *(LONG *)fdp);
					}
				}
			}
		}
	}

	if (err != 0) {
		free(rbp);
		return err;
	}

	/* ファイルサイズを調整する */
	__CHSIZE(dp->fileName, dp->fh, dhp->lHeader + dhp->lRec * w_rno);

	/* レコード数セット */
	dhp->nRec = w_rno;

	/* バイナリデータのパック */
	if (bfp != NULL && bfp->bhp->freeBlock != 0) {
		// DBF バックアップファイル名作成
		strcpy(dbfBackupFileName, dp->fileName);
		if ((p = strrchr(dbfBackupFileName, '.')) == NULL)
			p = dbfBackupFileName + strlen(dbfBackupFileName);
		strcpy(p, ".BAK");

		// DBF バックアップコピー
		__CLOSE(dp->fh);
		bRc = __COPYFILE(dp->fileName, dbfBackupFileName, FALSE);
		dp->fh = __OPEN(dp->fileName);
		if (!bRc) {
			free(rbp);
			return ERROR_DB_TMPFILE;
		}

		// BIN テンポラリファイル名作成
		strcpy(binTempFileName, dp->fileName);
		if ((p = strrchr(binTempFileName, '.')) == NULL)
			p = binTempFileName + strlen(binTempFileName);
		strcpy(p, ".BI$");

		// BIN テンポラリファイル作成
		if (BINCreate(binTempFileName, &bfpTemp) != 0) {
			__DELETEFILE(dbfBackupFileName);
			free(rbp);
			return ERROR_DB_TMPFILE;		
		}

		// BIN ファイルコピー
		for (r_rno = 0; r_rno < dhp->nRec; ) {
			if ((err = DBFRead(dp, ++r_rno, rbp)) != 0)
				break;

			bWriteBinary = FALSE;
			for (i = 0, flp = dp->flp; i < dp->nField; i++, flp++) {
				if (flp->type == 'B') {
					fdp = &rbp[flp->offset + 1];
					if (*(LONG *)fdp != 0) {
						if ((err = BINCopy(bfp, bfpTemp, *(LONG *)fdp, &bno)) != 0)
							goto end_binpack;
						*(LONG *)fdp = bno;
						bWriteBinary = TRUE;
					}
				}
			}

			if (bWriteBinary) {
				if ((err = DBFWrite(dp, r_rno, rbp)) != 0)
					break;
			}
		}
end_binpack:
		if (err == 0) {
			BINClose(bfpTemp);
			strcpy(binFileName, bfp->fileName);
			BINClose(bfp);
			__DELETEFILE(binFileName);
			__MOVEFILE(binTempFileName, binFileName);
			BINOpen(binFileName, &dp->bfp);
			__DELETEFILE(dbfBackupFileName);
		} else {
			BINClose(bfpTemp);
			__DELETEFILE(binTempFileName);

			__CLOSE(dp->fh);
			__DELETEFILE(dp->fileName);
			__MOVEFILE(dbfBackupFileName, dp->fileName);
			dp->fh = __OPEN(dp->fileName);
		}
	}	

	free(rbp);

	return 0;
}

/*=======================================================================
 |
 |		削除レコードチェック
 |
 |	SHORT	DBFCheckDeleted(dp, rno, flag)
 |
 |		PDBF	dp;		ＤＢＦポインタ
 |		LONG	rno;		レコード番号
 |		SHORT	*flag;		０：通常レコード　１：削除レコード
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBFCheckDeleted(PDBF dp, LONG rno, SHORT *flag)
{
	PDBF_H	dhp;
	CHAR	buf[1];
#if defined (OS_WNT)
	DWORD	numBytes;
#endif

	dhp = dp->dhp;

	/* レコード番号が範囲外ならエラー */
	if (rno <= 0 || rno > dhp->nRec)
		return ERROR_DB_RECNO;

	/* 削除フラグリセット */
	__LSEEK(dp->fh, dhp->lHeader + dhp->lRec*(rno-1), SEEK_SET);
	if (__READ(dp->fh, buf, 1) != 1)
		return ERROR_DB_READ;

	*flag = (buf[0] == '*') ? 1 : 0;

	return 0;
}

/*=======================================================================
 |
 |		データファイルをコピーする
 |
 |	SHORT	DBFCopy(dp1, dp2)
 |
 |		PDBF	dp1;		コピー元ＤＢＦポインタ
 |		PDBF	dp2;		コピー先ＤＢＦポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBFCopy(PDBF dp1, PDBF dp2)
{
	LONG	rno;
	SHORT	i, j, len;
	PFIELD	flp1 = NULL, flp2;
	CHAR	*rbp1, *rbp2;
	PBIN	bfp1, bfp2;
	LONG	bno;
	SHORT	err;

	if ((rbp1 = malloc(dp1->dhp->lRec)) == NULL)
		return ERROR_DB_MEMORY;

	if ((rbp2 = malloc(dp2->dhp->lRec)) == NULL) {
		free(rbp1);
		return ERROR_DB_MEMORY;
	}

	/* レコード数セット */
	dp2->dhp->nRec = dp1->dhp->nRec;

	bfp1 = dp1->bfp;
	bfp2 = dp2->bfp;

	err = 0;

	for (rno = 1; rno <= dp1->dhp->nRec; rno++) {
		if ((err = DBFRead(dp1, rno, rbp1)) != 0)
			break;

		memset(rbp2, ' ', dp2->dhp->lRec);
		for (i = 0; i < dp2->nField; i++) {
			flp2 = &dp2->flp[i];
			for (j = 0; j < dp1->nField; j++) {
				flp1 = &dp1->flp[j];
				if (strcmp(flp1->name, flp2->name) == 0)
					break;
			}
			if (j < dp1->nField) {
				len = min(flp1->lField2, flp2->lField2);
				switch (flp2->type) {
				case 'N':
				case 'I':
					memcpy(&rbp2[flp2->offset + (flp2->lField2-len) + 1],
							&rbp1[flp1->offset + (flp1->lField2-len) + 1], len);
					break;
				case 'B':
					if (bfp1 != NULL && bfp2 != NULL) {
						BINCopy(bfp1, bfp2, *(LONG *)&rbp1[flp1->offset + 1], &bno);
						*(LONG *)&rbp2[flp2->offset + 1] = bno;
					}
					break;
				default:
					memcpy(&rbp2[flp2->offset + 1], &rbp1[flp1->offset + 1], len);
					break;
				}
			}
		}
		if ((err = DBFWrite(dp2, rno, rbp2)) != 0)
			break;
	}

	free(rbp1);
	free(rbp2);

	if (err != 0)
		return err;

	/* ファイルサイズを調整する */
	__CHSIZE(dp2->fileName, dp2->fh,
			dp2->dhp->lHeader + dp2->dhp->lRec * (rno - 1));

	return 0;
}

/*=======================================================================
 |
 |		全てのレコードを削除する
 |
 |	SHORT	DBFZip(dp)
 |
 |		PDBF	dp;		ＤＢＦポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBFZip(PDBF dp)
{
	PDBF_H	dhp;

	dhp = dp->dhp;

	dhp->nRec = 0;		/* レコード数を０にする */

	/* ファイルサイズを調整する */
	__CHSIZE(dp->fileName, dp->fh, (LONG)dhp->lHeader);

	/* バイナリデータの全削除 */
	if (dp->bfp != NULL)
		BINZip(dp->bfp);

	dp->updateFlag = 1;		/* 更新フラグセット */
	dp->updateCount++;

	return 0;
}

/*=======================================================================
 |
 |		暗号化キー設定
 |
 |	SHORT	DBFSetScramble(dp, scrambleKey)
 |
 |		PDBF	dp;		ＤＢＦポインタ
 |		USHORT	scramble;	暗号化キー
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBFSetScramble(PDBF dp, USHORT scramble)
{
	PDBF_H	dhp;
	USHORT	currentScramble;
	LONG	recNo;
	CHAR	*rbp;
	SHORT	err;

	dhp = dp->dhp;

	if ((rbp = malloc(dhp->lRec)) == NULL)
		return ERROR_DB_MEMORY;

	currentScramble = dhp->scramble;
	for (recNo = 1; recNo <= dhp->nRec; recNo++) {
		dhp->scramble = currentScramble;
		if ((err = DBFRead(dp, recNo, rbp)) != 0) {
			free(rbp);
			return err;
		}
		dhp->scramble = scramble;
		if ((err = DBFWrite(dp, recNo, rbp)) != 0) {
			free(rbp);
			return err;
		}
	}
	dhp->scramble = scramble;

	free(rbp);

	return 0;
}

/*=======================================================================
 |
 |		パスワード設定
 |
 |	SHORT	DBFSetPassword(dp, password)
 |
 |		PDBF	dp;		ＤＢＦポインタ
 |		CHAR	*password;	パスワード
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBFSetPassword(PDBF dp, CHAR *password)
{
	PDBF_H	dhp;

	dhp = dp->dhp;

	if (password == NULL || password[0] == '\0') {
		memset(dhp->password, 0, 8);
	} else {
		memset(dhp->password, ' ', 8);
		memcpy(dhp->password, password, min(strlen(password), 8));
		Scramble1(dhp->password + 1, 7, dhp->password[0]);
	}

	dp->updateFlag = 1;

	return 0;
}
