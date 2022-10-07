/************************************************************************
 *
 *			ＰＣ−ＳＥＲＶＥ
 *
 *		名称		: データベース操作
 *		ファイル名	: db.c
 *		作成者		: s.aizawa
 *
 ************************************************************************/

#include "PCSOS.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "pcsdef.h"
#include "PCSDB.h"
#include "PCSDBSUB.h"
#include "PCSCOM.h"

#ifdef	OS_WINDOWS
#define	DBFRead(p1,p2,p3)	(p1->fh=dbp->fh,DBFRead(p1,p2,p3))
#define	DBFRead2(p1,p2,p3)	(p1->fh=dbp->fh,DBFRead2(p1,p2,p3))
#define	DBFWrite(p1,p2,p3)	(p1->fh=dbp->fh,DBFWrite(p1,p2,p3))
#define	DBFWrite2(p1,p2,p3)	(p1->fh=dbp->fh,DBFWrite2(p1,p2,p3))
#define	DBFFlush(p1,p2)		(p1->fh=dbp->fh,DBFFlush(p1,p2))
#define	DBFDelete(p1,p2)	(p1->fh=dbp->fh,DBFDelete(p1,p2))
#define	DBFRecall(p1,p2)	(p1->fh=dbp->fh,DBFRecall(p1,p2))
#define	DBFPack(p1)		(p1->fh=dbp->fh,DBFPack(p1))
#define	DBFCheckDeleted(p1,p2,p3) (p1->fh=dbp->fh,DBFCheckDeleted(p1,p2,p3))
#define	DBFCopy(p1,p2)	(p1->fh=dbp1->fh,p2->fh=dbp2->fh,DBFCopy(p1,p2))
#define	DBFZip(p1)		(p1->fh=dbp->fh,DBFZip(p1))

#define	IDXClose(p1)		(p1->ifp->fh=p1->fh,IDXClose(p1))
#define	IDXFlush(p1,p2)		(p1->ifp->fh=p1->fh,IDXFlush(p1,p2))
#define	IDXSearch(p1,p2,p3,p4)	(p1->ifp->fh=p1->fh,IDXSearch(p1,p2,p3,p4))
#define	IDXSearch2(p1,p2,p3,p4)	(p1->ifp->fh=p1->fh,IDXSearch2(p1,p2,p3,p4))
#define	IDXSearch3(p1,p2,p3,p4,p5) (p1->ifp->fh=p1->fh,IDXSearch3(p1,p2,p3,p4,p5))
#define	IDXCompare(p1,p2,p3)	(p1->ifp->fh=p1->fh,IDXCompare(p1,p2,p3))
#define	IDXStore(p1,p2,p3)	(p1->ifp->fh=p1->fh,IDXStore(p1,p2,p3))
#define	IDXDelete(p1,p2)	(p1->ifp->fh=p1->fh,IDXDelete(p1,p2))
#define	IDXNext(p1,p2)		(p1->ifp->fh=p1->fh,IDXNext(p1,p2))
#define	IDXBack(p1,p2)		(p1->ifp->fh=p1->fh,IDXBack(p1,p2))
#define	IDXTop(p1,p2)		(p1->ifp->fh=p1->fh,IDXTop(p1,p2))
#define	IDXBottom(p1,p2)	(p1->ifp->fh=p1->fh,IDXBottom(p1,p2))
#define	IDXCount(p1,p2,p3,p4)	(p1->ifp->fh=p1->fh,IDXCount(p1,p2,p3,p4))
#define	IDXMake(p1,p2) (p1->fh=dbp->fh,p2->ifp->fh=p2->fh,IDXMake(p1,p2))
#endif

/*	ローカル関数定義	*/
static	SHORT	_DBOpen(CHAR *, PDB *, SHORT);
static	SHORT	_DBCreate(CHAR *, PDBF_I, SHORT, PDB *, SHORT);
static	SHORT	_DBClose(PDB);
static	SHORT	_DBFlush(PDB);
static	SHORT	_DBIndex(PDB, CHAR *, SHORT *);
static	SHORT	_DBIdxCreate(PDB, CHAR *, CHAR *, SHORT, SHORT *);
static	SHORT	_DBChgIdx(PDB, SHORT);
static	SHORT	_DBSearch(PDB, CHAR *, SHORT);
static	SHORT	_DBSearch2(PDB, CHAR *, SHORT, SHORT *);
static	SHORT	_DBSearchLock(PDB, CHAR *, SHORT, LONG *);
static	SHORT	_DBCount(PDB, CHAR *, SHORT, LONG *);
static	SHORT	_DBStore(PDB, CHAR *);
static	SHORT	_DBStoreUniq(PDB, CHAR *);
static	SHORT	_DBUpdate(PDB, CHAR *);
static	SHORT	_DBUpdateKey(PDB, CHAR *, SHORT, CHAR *);
static	SHORT	_DBDelete(PDB);
static	SHORT	_DBRecall(PDB);
static	SHORT	_DBDelete2(PDB);
static	SHORT	_DBDelete3(PDB);
static	SHORT	_DBDeleteKey(PDB, CHAR *, SHORT, SHORT);
static	SHORT	_DBTop(PDB);
static	SHORT	_DBBottom(PDB);
static	SHORT	_DBSet(PDB, LONG);
static	SHORT	_DBSkip(PDB, LONG);
static	SHORT	_DBReindex(PDB);
static	SHORT	_DBPack(PDB);
static	SHORT	_DBRead(PDB, CHAR *);
static	SHORT	_DBReadNext(PDB, SHORT, CHAR *, SHORT *);
static	SHORT	_DBReadBack(PDB, SHORT, CHAR *, SHORT *);
static	SHORT	_DBReadKey(PDB, CHAR *, SHORT, CHAR *, SHORT, SHORT *);
static	SHORT	_DBReadBinary(PDB, CHAR *, HPSTR, LONG, LONG *);
static	SHORT	_DBWriteBinary(PDB, CHAR *, HPSTR, LONG);
static	SHORT	_DBGetBinarySize(PDB, CHAR *, LONG *);
static	SHORT	_DBClrRecord(PDB);
static	SHORT	_DBGetRecord(PDB);
static	SHORT	_DBGetField(PDB, CHAR *, VOID *, SHORT *, SHORT *);
static	SHORT	_DBSetField(PDB, CHAR *, VOID *);
static	SHORT	_DBAddRecord(PDB);
static	SHORT	_DBUpdRecord(PDB);
static	SHORT	_DBCheckDeleted(PDB, SHORT *);
static	SHORT	_DBSetFilter(PDB, CHAR *);
static	SHORT	_DBSelect(PDB, CHAR *, LONG *);
static	SHORT	_DBSetDeleted(PDB, SHORT);
static	SHORT	_DBLRecNo(PDB, LONG *);
static	SHORT	_DBLRecCount(PDB, LONG *);
static	SHORT	_DBLSet(PDB, LONG);
static	SHORT	_DBZip(PDB);
static	SHORT	_DBCheckUpdate(PDB, SHORT *);
static	SHORT	_DBLock(PDB, SHORT);
static	SHORT	_DBUnlock(PDB, SHORT);
static	SHORT	_DBRecCount(PDB, LONG *);
static	SHORT	_DBBof(PDB, SHORT *);
static	SHORT	_DBDbf(PDB, CHAR *);
static	SHORT	_DBEof(PDB, SHORT *);
static	SHORT	_DBNField(PDB, SHORT *);
static	SHORT	_DBField(PDB, SHORT, PDBF_I);
static	SHORT	_DBNdx(PDB, SHORT, CHAR *);
static	SHORT	_DBRecNo(PDB, LONG *);
static	SHORT	_DBRecSize(PDB, SHORT *);
static	SHORT	_DBSetReadField(PDB, CHAR *, SHORT *);
static	SHORT	_DBSetScramble(PDB);
static	SHORT	_DBUpdateEx(PDB, LONG, CHAR *);
static	SHORT	_DBDeleteEx(PDB, LONG);
static	SHORT	_DBRecallEx(PDB, LONG);
static	SHORT	_DBDelete2Ex(PDB, LONG);
static	SHORT	_DBLockEx(PDB, LONG, SHORT);
static	SHORT	_FileLockCheck(PDB);
static	SHORT	_RecordLockCheck(PDB);
static	SHORT	_SkipDeleted(PDB, int);
static	SHORT	_Skip(PDB, LONG);
static	VOID	_CheckBof(PDB, LONG);
static	VOID	_CheckEof(PDB, LONG);

CRITICALSECTION	csDB;		/* DB クリチカルセクション */
CRITICALSECTION	csDBL;		/* DBLOCK クリチカルセクション */

CHAR	bitTable1[8] = {0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80};
CHAR	bitTable2[8] = {0xfe, 0xfd, 0xfb, 0xf7, 0xef, 0xdf, 0xbf, 0x7f};

/*=======================================================================
 |
 |		データベースオープン
 |
 |	SHORT	DBOpen(fileName, dbpp, permission)
 |
 |		CHAR	*fileName;	データファイル名
 |		PDB		*dbpp;		ＤＢポインタ
 |		SHORT	permission;	アクセス許可モード
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBOpen(CHAR *fileName, PDB *dbpp, SHORT permission)
{
	SHORT	err;
	CHAR	fileNameTmp[256];
	CHAR	password[8];
	CHAR	*p;
	int len;

	ENTER_CRITICAL_SECTION(&csDB);

	if ((p = strchr(fileName, ',')) != NULL) {
		len = (int)(p - fileName);
		memcpy(fileNameTmp, fileName, len);
		fileNameTmp[len] = '\0';
	} else
		strcpy(fileNameTmp, fileName);

	err = _DBOpen(fileNameTmp, dbpp, permission);

	if (err == 0) {
		if (p == NULL) {
			if ((*dbpp)->dp->dhp->password[0] != 0) {
				_DBClose(*dbpp);
				*dbpp = NULL;
				err = ERROR_DB_PASSWORD;
			}
		} else {
			p++;
			memset(password, ' ', sizeof(password));
			memcpy(password, p, min(strlen(p), 8));
			Scramble1(password + 1, 7, password[0]);
			if (memcmp((*dbpp)->dp->dhp->password, password, 8) != 0) {
				_DBClose(*dbpp);
				*dbpp = NULL;
				err = ERROR_DB_PASSWORD;
			}
		}
	}
	LEAVE_CRITICAL_SECTION(&csDB);

	return err;
}

static	SHORT	_DBOpen(CHAR *fileName, PDB *dbpp, SHORT permission)
{
	PDB	dbp;
	SHORT	err;

	*dbpp = NULL;

	// アクセス許可モードチェック
	if (!(permission & PERMISSION_READ))
		return ERROR_FILE_PERMISSION;

	/* データベース管理情報エリア確保 */
	if ((dbp = malloc(sizeof(DB))) == NULL)
		return ERROR_DB_MEMORY;

	memset(dbp, 0, sizeof(DB));

	/* データファイル（ＤＢＦ）オープン */
	if ((err = DBFOpen(fileName, &dbp->dp)) != 0) {
		_DBClose(dbp);
		return err;
	}

#ifdef	MULTI_OPEN
	dbp->fh = dbp->dp->fh;
#endif

	/* レコードバッファ確保 */
	if ((dbp->rbp = malloc(dbp->dp->dhp->lRec + 1)) == NULL) {
		_DBClose(dbp);
		return ERROR_DB_MEMORY;
	}

	/* レコードバッファ確保２ */
	if ((dbp->rbp2 = malloc(dbp->dp->lRec)) == NULL) {
		_DBClose(dbp);
		return ERROR_DB_MEMORY;
	}

	dbp->readSize = dbp->dp->lRec;

	dbp->permission = permission;

	/* チェイン処理 */
	dbp->chain = dbp->dp->dbp;
	dbp->dp->dbp = dbp;

	dbp->updateCount = dbp->dp->updateCount;

	_CheckBof(dbp, 1L);	/* ＢＯＦチェック*/

	*dbpp = dbp;

	return 0;
}

/*=======================================================================
 |
 |		データベース作成
 |
 |	SHORT	DBCreate(fileName, dip, nField, dbpp, permission)
 |
 |		CHAR	*fileName;	データファイル名
 |		PDBF_I	dip;		データファイル情報
 |		SHORT	nField;		フィールド数
 |		PDB	*dbpp;		ＤＢポインタ
 |		SHORT	permission;	アクセス許可モード
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBCreate(CHAR *fileName, PDBF_I dip, SHORT nField, PDB *dbpp, SHORT permission)
{
	CHAR	*p;
	SHORT	err;

	ENTER_CRITICAL_SECTION(&csDB);

	if ((p = strchr(fileName, ',')) != NULL)
		*p = '\0';

	err = _DBCreate(fileName, dip, nField, dbpp, permission);

	if (p != NULL) {
		*p = ',';
		if (err == 0)
			DBSetPassword(*dbpp, p + 1);
	}

	LEAVE_CRITICAL_SECTION(&csDB);

	return err;
}

static	SHORT	_DBCreate(CHAR *fileName, PDBF_I dip, SHORT nField, PDB *dbpp, SHORT permission)
{
	PDBF	dp;
	SHORT	err;

	*dbpp = NULL;

	// アクセス許可モードチェック
	if ((permission & (PERMISSION_READ | PERMISSION_WRITE)) != (PERMISSION_READ | PERMISSION_WRITE))
		return ERROR_FILE_PERMISSION;

	/* データファイル作成 */
	if ((err = DBFCreate(fileName, dip, nField, &dp)) != 0)
		return err;

	/* データファイルクローズ */
	if ((err = DBFClose(dp)) != 0)
		return err;

	return _DBOpen(fileName, dbpp, permission);
}

/*=======================================================================
 |
 |		データベースクローズ
 |
 |	SHORT	DBClose(dbp)
 |
 |		PDB	dbp;		ＤＢポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBClose(PDB dbp)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&csDB);
	err = _DBClose(dbp);
	LEAVE_CRITICAL_SECTION(&csDB);

	return err;
}

static	SHORT	_DBClose(PDB dbp)
{
	PDB	*dbpp;
	int	i;

	if (dbp->dp != NULL) {
		/* 全ロック解除 */
		if (dbp->readLockCount != 0)
			dbp->readLockCount = 1;
		if (dbp->writeLockCount != 0)
			dbp->writeLockCount = 1;
		_DBUnlock(dbp, LOCK_FILE_WRITE);
		_DBUnlock(dbp, LOCK_RECORD_WRITE);
		_DBUnlock(dbp, LOCK_FILE_READ);
		_DBUnlock(dbp, LOCK_RECORD_READ);

		/* チェイン切り離し */
		for (dbpp = &dbp->dp->dbp; *dbpp != 0; dbpp = &(*dbpp)->chain){
			if ((*dbpp) == dbp) {
				*dbpp = (*dbpp)->chain;
				break;
			}
		}

		/* データファイルクローズ */
#ifdef	MULTI_OPEN
		if (dbp->dp->dbp == NULL) {
			dbp->dp->fh = dbp->fh;
			DBFClose(dbp->dp);
		} else
			__CLOSE(dbp->fh);
#else
		if (dbp->dp->dbp == NULL)
			DBFClose(dbp->dp);
		else
			DBFFlush(dbp->dp, FALSE);
#endif
	}

	/* インデックスファイルクローズ */
	for (i = 1; i <= dbp->nIdx; i++) {
		if (dbp->ip[i] != NULL)
			IDXClose(dbp->ip[i]);
	}

	/* バイナリデータ読み込み情報解放 */
	if (dbp->brp != NULL)
		free(dbp->brp);

	/* レコードバッファ解放 */
	if (dbp->rbp != NULL)
		free(dbp->rbp);

	/* レコードバッファ２解放 */
	if (dbp->rbp2 != NULL)
		free(dbp->rbp2);

	/* フィルタ情報解放 */
	if (dbp->filter != NULL)
		free(dbp->filter);

	/* 選択情報解放 */
	if (dbp->select != NULL)
		HFREE(dbp->select);

	/* 読み込みフィールド情報解放 */
	if (dbp->readField != NULL)
		free(dbp->readField);

	free(dbp);	/* 管理情報エリア解放 */

	return 0;
}

/*=======================================================================
 |
 |		ファイル強制掃き出し
 |
 |	SHORT	DBFlush(dbp)
 |
 |		PDB	dbp;		ＤＢポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBFlush(PDB dbp)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBFlush(dbp);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBFlush(PDB dbp)
{
	int	i;

	/* データファイルフラッシュ */
	DBFFlush(dbp->dp, TRUE);

	/* インデックスファイルフラッシュ */
	for (i = 1; i <= dbp->nIdx; i++) {
		if (dbp->ip[i] != NULL)
			IDXFlush(dbp->ip[i], TRUE);
	}

	return 0;
}

/*=======================================================================
 |
 |		インデックスファイルオープン
 |
 |	SHORT	DBIndex(dbp, fileName, idxNo)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*fileName;	インデックスファイル名
 |		SHORT	*idxNo;		インデックスファイル番号
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBIndex(PDB dbp, CHAR *fileName, SHORT *idxNo)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBIndex(dbp, fileName, idxNo);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBIndex(PDB dbp, CHAR *fileName, SHORT *idxNo)
{
	PIDX	ip;
	SHORT	err;

	*idxNo = 0;

	/* インデックスファイルオープン数チェック */
	if (dbp->nIdx >= MAX_IDX)
		return ERROR_DB_IDXOVER;

	/* インデックスファイルオープン */
	if ((err = IDXOpen(fileName, &ip)) != 0)
		return err;

	if (dbp->dp->adjustFlag && ip->chain == NULL) {
		if ((err = IDXMake(dbp->dp, ip)) != 0) {
			IDXClose(ip);
			return err;
		}
	}

	dbp->ip[dbp->nIdx+1] = ip;
	dbp->nIdx++;		/* インデックスファイル数更新 */

	/* マスターインデックスファイル番号セット */
	if (dbp->master == 0) {
		dbp->master = dbp->nIdx;
		_DBTop(dbp);
	}

	*idxNo = dbp->nIdx;

	return 0;
}

/*=======================================================================
 |
 |		インデックスファイル作成
 |
 |	SHORT	DBIdxCreate(dbp, fileName, key, uniq, idxNo)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*fileName;	インデックスファイル名
 |		CHAR	*key;		キー
 |		SHORT	uniq;		０：キーの重複を許す　１：許さない
 |		SHORT	*idxNo;		インデックスファイル番号
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBIdxCreate(PDB dbp, CHAR *fileName, CHAR *key, SHORT uniq,
								SHORT *idxNo)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBIdxCreate(dbp, fileName, key, uniq, idxNo);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBIdxCreate(PDB dbp, CHAR *fileName, CHAR *key, SHORT uniq,
								SHORT *idxNo)
{
	PDBF	dp;
	PIDX	ip;
	SHORT	err;

	dp = dbp->dp;
	*idxNo = 0;

	// アクセス許可モードチェック
	if (!(dbp->permission & PERMISSION_WRITE))
		return ERROR_FILE_PERMISSION;

	/* インデックスファイルオープン数チェック */
	if (dbp->nIdx >= MAX_IDX)
		return ERROR_DB_IDXOVER;

	/* インデックスファイル作成 */
	if ((err = IDXCreate(fileName, key, uniq, &ip)) != 0)
		return err;

	/* インデックス構築 */
	if ((err = IDXMake(dp, ip)) != 0) {
		IDXClose(ip);
		return err;
	}

	dbp->ip[dbp->nIdx+1] = ip;	/* インデックスポインタセーブ */

	dbp->nIdx++;		/* インデックスファイル数更新 */

	/* マスターインデックスファイル番号セット */
	if (dbp->master == 0) {
		dbp->master = dbp->nIdx;
		_DBTop(dbp);
	}

	*idxNo = dbp->nIdx;

	return 0;
}

/*=======================================================================
 |
 |		マスターインデックス切り替え
 |
 |	SHORT	DBChgIdx(dbp, n)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		SHORT	n;		インデックスファイル番号
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBChgIdx(PDB dbp, SHORT n)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBChgIdx(dbp, n);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBChgIdx(PDB dbp, SHORT n)
{
	if (n < 0 || n > dbp->nIdx)
		return ERROR_DB_PARAMETER;

	dbp->master = n;	/* マスターインデックス番号セット */
	return _DBTop(dbp);	/* 先頭レコード */
}

/*=======================================================================
 |
 |		インデックスファイルによる検索（完全一致，前方一致）
 |
 |	SHORT	DBSearch(dbp, key, len)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*key;		検索する文字列
 |		SHORT	len;		検索する文字列の長さ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBSearch(PDB dbp, CHAR *key, SHORT len)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBSearch(dbp, key, len);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBSearch(PDB dbp, CHAR *key, SHORT len)
{
	PIDX	ip;
	double	dTmp;
	LONG	lTmp;
	LONG	rno;
	SHORT	err;

	/* ポインタセット */
	ip = dbp->ip[dbp->master];

	/* インデックスファイルが無ければエラー */
	if (ip == NULL)
		return ERROR_DB_NOINDEX;

	switch (ip->ifp->ihp->type) {
	case KEY_TYPE_N:
		/* 文字列を実数に変換 */
		dTmp = natof(key, len);
		key = (CHAR *)&dTmp;
		len = 8;
		break;
	case KEY_TYPE_I:
		/* 文字列を整数に変換 */
		lTmp = natol(key, len);
		key = (CHAR *)&lTmp;
		len = 4;
		break;
	}

	/* インデックス検索 */
	if ((err = IDXSearch(ip, key, len, &rno)) != 0)
		return err;

	_CheckEof(dbp, rno);	/* ＥＯＦチェック */

	if (dbp->filter != NULL || dbp->select != NULL ||
						dbp->setDeleted != 0) {
		/* 削除レコードスキップ */
		if ((err = _SkipDeleted(dbp, 1)) != 0)
			return err;
		if (dbp->eof == 0) {
			if (IDXCompare(ip, key, len) != 0)
				_CheckEof(dbp, 0L);
		}
	}

	return 0;
}

/*=======================================================================
 |
 |		インデックスファイルによる検索（範囲指定対応）
 |
 |	SHORT	DBSearch2(dbp, key, len, find)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*key;		検索する文字列
 |		SHORT	len;		検索する文字列の長さ
 |		SHORT	*find;		検索結果
 |					０：該当レコード無し
 |					１：一致するレコードが見つかった
 |					２：一致するレコードは見つからなかった
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBSearch2(PDB dbp, CHAR *key, SHORT len, SHORT *find)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBSearch2(dbp, key, len, find);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBSearch2(PDB dbp, CHAR *key, SHORT len, SHORT *find)
{
	PIDX	ip;
	double	dTmp;
	LONG	lTmp;
	LONG	rno;
	SHORT	err;

	/* ポインタセット */
	ip = dbp->ip[dbp->master];

	/* インデックスファイルがなければ何もしない */
	if (ip == NULL)
		return ERROR_DB_NOINDEX;

	switch (ip->ifp->ihp->type) {
	case KEY_TYPE_N:
		/* 文字列を実数に変換 */
		dTmp = natof(key, len);
		key = (CHAR *)&dTmp;
		len = 8;
		break;
	case KEY_TYPE_I:
		/* 文字列を整数に変換 */
		lTmp = natol(key, len);
		key = (CHAR *)&lTmp;
		len = 4;
		break;
	}

	/* 検索 */
	if ((err = IDXSearch2(ip, key, len, &rno)) != 0)
		return err;

	_CheckEof(dbp, rno);	/* ＥＯＦチェック */

	if (dbp->filter != NULL || dbp->select != NULL ||
						dbp->setDeleted != 0) {
		/* 削除レコードスキップ */
		if ((err = _SkipDeleted(dbp, 1)) != 0)
			return err;
	}

	if (dbp->eof)
		*find = 0;
	else if (IDXCompare(ip, key, len) == 0)
		*find = 1;
	else
		*find = 2;

	return 0;
}

/*=======================================================================
 |
 |		インデックスファイルによる検索（ロック付き）
 |
 |	SHORT	DBSearchLock(dbp, key, len, count)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*key;		検索する文字列
 |		SHORT	len;		検索する文字列の長さ
 |		LONG	count;		検索されたレコード数
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBSearchLock(PDB dbp, CHAR *key, SHORT len, LONG *count)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBSearchLock(dbp, key, len, count);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBSearchLock(PDB dbp, CHAR *key, SHORT len, LONG *count)
{
	LONG	l;
	SHORT	err;

	/* 対象レコード数取り出し */
	if ((err = _DBCount(dbp, key, len, count)) != 0)
		return err;

	if (*count == 0)
		return 0;

	if ((err = _DBSearch(dbp, key, len)) != 0)
		return err;

	for (l = 0; l < *count; l++) {
		if ((err = _DBLock(dbp, LOCK_RECORD_WRITE)) != 0) {
			_DBUnlock(dbp, LOCK_RECORD_WRITE);
			return err;
		}
		if ((err = _DBSkip(dbp, 1L)) != 0) {
			_DBUnlock(dbp, LOCK_RECORD_WRITE);
			return err;
		}
	}

	if ((err = _DBSearch(dbp, key, len)) != 0) {
		_DBUnlock(dbp, LOCK_RECORD_WRITE);
		return err;
	}

	return 0;
}

/*=======================================================================
 |
 |		キーに一致するレコード数の取得
 |
 |	SHORT	DBCount(dbp, key, len, nRec)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*key;		検索する文字列
 |		SHORT	len;		検索する文字列の長さ
 |		LONG	*nRec;		キーに一致したレコード数
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBCount(PDB dbp, CHAR *key, SHORT len, LONG *nRec)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBCount(dbp, key, len, nRec);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBCount(PDB dbp, CHAR *key, SHORT len, LONG *nRec)
{
	PIDX	ip;
	double	dTmp;
	LONG	lTmp;
	LONG	count, rno;
	SHORT	err;

	/* ポインタセット */
	ip = dbp->ip[dbp->master];

	/* インデックスファイルがなければ何もしない */
	if (ip == NULL)
		return ERROR_DB_NOINDEX;

	switch (ip->ifp->ihp->type) {
	case KEY_TYPE_N:
		/* 文字列を実数に変換 */
		dTmp = natof(key, len);
		key = (CHAR *)&dTmp;
		len = 8;
		break;
	case KEY_TYPE_I:
		/* 文字列を整数に変換 */
		lTmp = natol(key, len);
		key = (CHAR *)&lTmp;
		len = 4;
		break;
	}

	/* 検索 */
	if ((err = IDXSearch(ip, key, len, &rno)) != 0)
		return err;

	_CheckEof(dbp, rno);	/* ＥＯＦチェック */

	/* 削除レコードスキップ */
	if ((err = _SkipDeleted(dbp, 1)) != 0)
		return err;

	count = 0;
	while (dbp->eof == 0) {
		if (IDXCompare(ip, key, len) != 0)
			break;
		count++;
		if ((err = _DBSkip(dbp, 1L)) != 0)
			return err;
	}

	*nRec = count;		/* 結果セット */

	return 0;
}

/*=======================================================================
 |
 |		レコード追加
 |
 |	SHORT	DBStore(dbp, rec)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*rec;		追加するレコードデータへのポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBStore(PDB dbp, CHAR *rec)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBStore(dbp, rec);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBStore(PDB dbp, CHAR *rec)
{
	PDBF	dp;
	PIDX	ip;
	int	i;
	PDBF_H	dhp;
	SHORT	err;
	CHAR	kbuf[256];

	// アクセス許可モードチェック
	if (!(dbp->permission & PERMISSION_WRITE))
		return ERROR_FILE_PERMISSION;

	/* ポインタセット */
	dp = dbp->dp;
	dhp = dp->dhp;

	/* ファイルロックチェック */
	if (dp->readLockCount != 0 ||
			(dp->writeLockCount != 0 && dbp->writeLockCount == 0))
		return ERROR_DB_LOCK;

	dbp->rbp[0] = ' ';	/* 削除レコードフラグクリア */

	memcpy(dbp->rbp + 1, rec, dp->lRec);	/* データコピー */

	/* バイナリフィールドクリア */
	if (dhp->lRec - 1 > dp->lRec)
		memset(dbp->rbp + 1 + dp->lRec, 0, dhp->lRec - 1 - dp->lRec);

	/* データファイルに追加 */
	dbp->rno = ++dhp->nRec;
	if ((err = DBFWrite(dp, dbp->rno, dbp->rbp)) != 0)
		return err;

	/* インデックスファイル更新 */
	for (i = 1; i <= dbp->nIdx; i++) {
		ip = dbp->ip[i];

		if (GetKey(dp, dbp->rbp + 1, ip->ifp->ihp, kbuf) != 0)
			IDXStore(ip, kbuf, dhp->nRec);
	}

	/* インデックスファイル内のポインタをセット */
	_DBSet(dbp, dbp->rno);

	return 0;
}

/*=======================================================================
 |
 |		レコード追加（重複無し）
 |
 |	SHORT	DBStoreUniq(dbp, rec)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*rec;		追加するレコードデータへのポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBStoreUniq(PDB dbp, CHAR *rec)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBStoreUniq(dbp, rec);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBStoreUniq(PDB dbp, CHAR *rec)
{
	PIDX	ip;
	PIDX_H	ihp;
	int	i;
	SHORT	err;
	LONG	rno;
	CHAR	kbuf[256];

	// アクセス許可モードチェック
	if (!(dbp->permission & PERMISSION_WRITE))
		return ERROR_FILE_PERMISSION;

	/* 重複チェック */
	for (i = 1; i <= dbp->nIdx; i++) {
		ip = dbp->ip[i];
		ihp = ip->ifp->ihp;

		if (ihp->uniq && GetKey(dbp->dp, rec, ihp, kbuf) != 0) {
			if ((err = IDXSearch(ip, kbuf, ihp->lKey, &rno)) != 0)
				return err;
			if (rno != 0)
				return ERROR_DB_DBLKEY;
		}
	}

	return _DBStore(dbp, rec);
}

/*=======================================================================
 |
 |		レコード更新
 |
 |	SHORT	DBUpdate(dbp, rec)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*rec;		更新するレコードデータへのポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBUpdate(PDB dbp, CHAR *rec)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBUpdate(dbp, rec);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBUpdate(PDB dbp, CHAR *rec)
{
	PDBF	dp;
	PIDX	ip;
	int	i;
	PDBF_H	dhp;
	PIDX_H	ihp;
	LONG	rno;
	SHORT	err;
	CHAR	kbuf1[256], kbuf2[256];

	// アクセス許可モードチェック
	if (!(dbp->permission & PERMISSION_WRITE))
		return ERROR_FILE_PERMISSION;

	/* ＢＯＦまたはＥＯＦならエラー */
	if (dbp->bof || dbp->eof)
		return ERROR_DB_EOF;

	/* ファイルロックチェック */
	if ((err = _RecordLockCheck(dbp)) != 0)
		return err;

	/* ポインタセット */
	dp = dbp->dp;
	dhp = dp->dhp;

	/* レコード読み込み */
	if ((err = DBFRead2(dp, dbp->rno, dbp->rbp)) != 0)
		return err;

	/* インデックスファイル更新 */
	for (i = 1; i <= dbp->nIdx; i++) {
		ip = dbp->ip[i];
		ihp = ip->ifp->ihp;

		if (GetKey(dp, dbp->rbp, ihp, kbuf1) != 0) {
			IDXSearch3(ip, kbuf1, ihp->lKey, dbp->rno, &rno);

			GetKey(dp, rec, ihp, kbuf2);
			if (rno != 0) {
				if (memcmp(kbuf1, kbuf2, ihp->lKey) != 0) {
					IDXDelete(ip, rno);
					IDXStore(ip, kbuf2, rno);
				}
			} else
				IDXStore(ip, kbuf2, dbp->rno);
		}
	}

	/* データファイル更新 */
	if ((err = DBFWrite2(dp, dbp->rno, rec)) != 0)
		return err;

	/* インデックスファイル内のポインタをセット */
	_DBSet(dbp, dbp->rno);

	return 0;
}

/*=======================================================================
 |
 |		キー指定によるレコード更新
 |
 |	SHORT	DBUpdateKey(dbp, key, len, buf)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*key;		キー
 |		SHORT	len;		キー長
 |		CHAR	*buf;		レコードバッファ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBUpdateKey(PDB dbp, CHAR *key, SHORT len, CHAR *buf)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBUpdateKey(dbp, key, len, buf);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBUpdateKey(PDB dbp, CHAR *key, SHORT len, CHAR *buf)
{
	LONG	count;
	SHORT	err;

	// アクセス許可モードチェック
	if (!(dbp->permission & PERMISSION_WRITE))
		return ERROR_FILE_PERMISSION;

	/* レコード検索 */
	if ((err = _DBCount(dbp, key, len, &count)) != 0)
		return err;

	if (count == 0)
		return ERROR_DB_NOKEY;
	if (count > 1)
		return ERROR_DB_DBLKEY;

	if ((err = _DBSearch(dbp, key, len)) != 0)
		return err;

	if ((err = _DBUpdate(dbp, buf)) != 0)
		return err;

	return 0;
}

/*=======================================================================
 |
 |		レコード削除
 |
 |	SHORT	DBDelete(dbp)
 |
 |		PDB	dbp;		ＤＢポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBDelete(PDB dbp)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBDelete(dbp);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBDelete(PDB dbp)
{
	SHORT	err;

	// アクセス許可モードチェック
	if (!(dbp->permission & PERMISSION_WRITE))
		return ERROR_FILE_PERMISSION;

	/* ＢＯＦまたはＥＯＦならエラー */
	if (dbp->bof || dbp->eof)
		return ERROR_DB_EOF;

	/* ファイルロックチェック */
	if ((err = _RecordLockCheck(dbp)) != 0)
		return err;

	/* 削除マークセット */
	if ((err = DBFDelete(dbp->dp, dbp->rno)) != 0)
		return err;

	/* 削除レコードスキップ */
	if ((err = _SkipDeleted(dbp, 1)) != 0)
		return err;

	return 0;
}

/*=======================================================================
 |
 |		レコード復元
 |
 |	SHORT	DBRecall(dbp)
 |
 |		PDB	dbp;		ＤＢポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBRecall(PDB dbp)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBRecall(dbp);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBRecall(PDB dbp)
{
	SHORT	err;

	// アクセス許可モードチェック
	if (!(dbp->permission & PERMISSION_WRITE))
		return ERROR_FILE_PERMISSION;

	/* ＢＯＦまたはＥＯＦならエラー */
	if (dbp->bof || dbp->eof)
		return ERROR_DB_EOF;

	/* ファイルロックチェック */
	if ((err = _RecordLockCheck(dbp)) != 0)
		return err;

	/* 削除マーク取り消し */
	if ((err = DBFRecall(dbp->dp, dbp->rno)) != 0)
		return err;

	return 0;
}

/*=======================================================================
 |
 |		レコードの物理的削除
 |
 |	SHORT	DBDelete2(dbp)
 |
 |		PDB	dbp;		ＤＢポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBDelete2(PDB dbp)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBDelete2(dbp);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBDelete2(PDB dbp)
{
	PDB	dbp2;
	PDBF	dp;
	PDBF_H	dhp;
	PIDX	ip;
	PIDX_H	ihp;
	PFIELD	flp;
	CHAR	*fdp;
	int	i;
	CHAR	*rbufp;
	LONG	rno;
	SHORT	err;
	CHAR	kbuf[256];
	CHAR	kbuf2[256];
	PDBLOCK	dlp, *dlpp, chain;

	// アクセス許可モードチェック
	if (!(dbp->permission & PERMISSION_WRITE))
		return ERROR_FILE_PERMISSION;

	/* ＢＯＦまたはＥＯＦならエラー */
	if (dbp->bof || dbp->eof)
		return ERROR_DB_EOF;

	/* ファイルロックチェック */
	if ((err = _RecordLockCheck(dbp)) != 0)
		return err;

	dp = dbp->dp;
	dhp = dp->dhp;

	/* カレントレコード読み込み */
	if ((err = DBFRead(dp, dbp->rno, dbp->rbp)) != 0)
		return err;

	/* バイナリデータの削除 */
	if (dp->bfp != NULL) {
		for (i = 0, flp = dp->flp; i < dp->nField; i++, flp++) {
			if (flp->type == 'B') {
				fdp = &dbp->rbp[flp->offset + 1];
				BINDelete(dp->bfp, *(LONG *)fdp);
			}
		}
	}

	/* ワークエリア確保 */
	if ((rbufp = malloc(dp->dhp->lRec)) == 0)
		return ERROR_DB_MEMORY;

	/* 最終レコード読み込み */
	if ((err = DBFRead(dp, dhp->nRec, rbufp)) != 0) {
		free(rbufp);
		return err;
	}

	/* 物理的最終レコードをインデックスファイルより削除 */
	for (i = 1; i <= dbp->nIdx; i++) {
		ip = dbp->ip[i];
		ihp = ip->ifp->ihp;

		if (GetKey(dp, rbufp + 1, ihp, kbuf) != 0) {
			IDXSearch3(ip, kbuf, ihp->lKey, dhp->nRec, &rno);
			if (rno != 0)
				IDXDelete(ip, rno);	/* キーの削除 */
		}
	}

	rno = dbp->rno;		/* カレントレコード番号保存 */

	/* 最終レコード以外の場合、削除するレコードに最終レコードを上書き */
	if (rno != dhp->nRec) {
		/* インデックスファイル更新 */
		for (i = 1; i <= dbp->nIdx; i++) {
			ip = dbp->ip[i];
			ihp = ip->ifp->ihp;

			if (GetKey(dp, dbp->rbp + 1, ihp, kbuf) != 0) {
				IDXSearch3(ip, kbuf, ihp->lKey, dbp->rno,
									&rno);

				GetKey(dp, rbufp + 1, ihp, kbuf2);
				if (rno != 0) {
					if (memcmp(kbuf, kbuf2, ihp->lKey)
									!= 0) {
						IDXDelete(ip, rno);
						IDXStore(ip, kbuf2, rno);
					}
				} else
					IDXStore(ip, kbuf2, dbp->rno);
			}
		}

		/* データファイル更新 */
		if ((err = DBFWrite(dp, dbp->rno, rbufp)) != 0)
			return err;
	}

	free(rbufp);

	ENTER_CRITICAL_SECTION(&csDB);

	/* カレントレコードが削除された場合はＥＯＦとする */
	for (dbp2 = dp->dbp; dbp2 != NULL; dbp2 = dbp2->chain) {
		if (dbp2->rno == rno)
			_CheckEof(dbp2, 0L);
	}

	/* カレントレコード番号補正 */
	for (dbp2 = dp->dbp; dbp2 != NULL; dbp2 = dbp2->chain) {
		if (dbp2->rno == dhp->nRec)
			dbp2->rno = rno;
	}

	LEAVE_CRITICAL_SECTION(&csDB);

	ENTER_CRITICAL_SECTION(&csDBL);

	/* カレントレコードのロック解除 */
	for (dlpp = &dp->rdlp; *dlpp != 0; ) {
		if ((*dlpp)->rno == rno) {
			chain = (*dlpp)->chain;
			free(*dlpp);
			*dlpp = chain;
		} else
			dlpp = &(*dlpp)->chain;
	}

	for (dlpp = &dp->wdlp; *dlpp != 0; dlpp = &(*dlpp)->chain) {
		if ((*dlpp)->rno == rno) {
			chain = (*dlpp)->chain;
			free(*dlpp);
			*dlpp = chain;
			break;
		} 
	}

	/* 読み込みロックレコード番号補正 */
	for (dlp = dp->rdlp; dlp != NULL; dlp = dlp->chain) {
		if (dlp->rno == dhp->nRec)
			dlp->rno = rno;
	}

	/* 書き込みロックレコード番号補正 */
	for (dlp = dp->wdlp; dlp != NULL; dlp = dlp->chain) {
		if (dlp->rno == dhp->nRec)
			dlp->rno = rno;
	}

	LEAVE_CRITICAL_SECTION(&csDBL);

	dhp->nRec--;		/* レコード数−１ */
	dp->updateFlag = 1;	/* ファイル更新フラグセット */
	dp->updateCount++;

	if (dhp->nRec == 0)	/* ０件になった場合はＢＯＦ、ＥＯＦをセット */
		dbp->eof = dbp->bof = 1;

	/* ファイルサイズを調整する */
	__CHSIZE(dp->fileName, dp->fh, dhp->lHeader + dhp->lRec * dhp->nRec);

	return 0;
}

SHORT	DBDelete3(PDB dbp)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBDelete3(dbp);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBDelete3(PDB dbp)
{
	LONG	currentRecNo, nextRecNo;
	SHORT	eof;
	SHORT	err;

	// アクセス許可モードチェック
	if (!(dbp->permission & PERMISSION_WRITE))
		return ERROR_FILE_PERMISSION;

	/* ＢＯＦまたはＥＯＦならエラー */
	if (dbp->bof || dbp->eof)
		return ERROR_DB_EOF;

	/* ファイルロックチェック */
	if ((err = _RecordLockCheck(dbp)) != 0)
		return err;

	/* カレントレコード番号保存 */
	currentRecNo = dbp->rno;

	/* 次レコード番号保存 */
	if ((err = _DBSkip(dbp, 1L)) != 0)
		return err;
	nextRecNo = dbp->rno;
	if (nextRecNo == dbp->dp->dhp->nRec)
		nextRecNo = currentRecNo;

	eof = dbp->eof;

	/* カレントレコード再セット */
	if ((err = _DBSet(dbp, currentRecNo)) != 0)
		return err;

	/* レコードの物理的削除 */
	if ((err = _DBDelete2(dbp)) != 0)
		return err;

	/* 次レコードにレコードポインタをセット */
	if (eof == 0) {
		if ((err = _DBSet(dbp, nextRecNo)) != 0)
			return err;
	} else
		_CheckEof(dbp, 0L);

	return 0;
}

/*=======================================================================
 |
 |		キー指定によるレコードの物理的削除
 |
 |	SHORT	DBDeleteKey(dbp, key, len, flag)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*key;		削除するキー
 |		SHORT	len;		キーの長さ
 |		SHORT	flag;		０：重複キーはエラー
 |					１：重複キーも削除
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBDeleteKey(PDB dbp, CHAR *key, SHORT len, SHORT flag)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBDeleteKey(dbp, key, len, flag);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBDeleteKey(PDB dbp, CHAR *key, SHORT len, SHORT flag)
{
	LONG	count;
	SHORT	err;

	// アクセス許可モードチェック
	if (!(dbp->permission & PERMISSION_WRITE))
		return ERROR_FILE_PERMISSION;

	/* 対象レコード数取り出し */
	if ((err = _DBCount(dbp, key, len, &count)) != 0)
		return err;

	/* 重複チェック */
	if (count == 0) {
		return 0;
	} else if (count > 1) {
		if (flag == 0)
			return ERROR_DB_DBLKEY;
	}

	/* ファイルロックチェック */
	if ((err = _RecordLockCheck(dbp)) != 0)
		return err;


	for (;;) {
		/* 削除レコード検索 */
		if ((err = _DBSearch(dbp, key, len)) != 0)
			return err;

		if (dbp->eof)
			break;

		/* レコード削除 */
		if ((err = _DBDelete2(dbp)) != 0)
			return err;
	}

	return 0;
}

/*=======================================================================
 |
 |		レコードポインタを先頭レコードにセット
 |
 |	SHORT	DBTop(dbp)
 |
 |		PDB	dbp;		ＤＢポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBTop(PDB dbp)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBTop(dbp);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBTop(PDB dbp)
{
	PIDX	ip;
	LONG	rno;
	SHORT	err;

	ip = dbp->ip[dbp->master];

	if (ip == NULL)
		_CheckBof(dbp, 1L);
	else {
		if ((err = IDXTop(ip, &rno)) != 0)
			return err;
		_CheckBof(dbp, rno);
	}

	/* 削除レコードスキップ */
	return _SkipDeleted(dbp, 1);
}

/*=======================================================================
 |
 |		レコードポインタを最終レコードにセット
 |
 |	SHORT	DBBottom(dbp)
 |
 |		PDB	dbp;		ＤＢポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBBottom(PDB dbp)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBBottom(dbp);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBBottom(PDB dbp)
{
	PIDX	ip;
	LONG	rno;
	SHORT	err;

	ip = dbp->ip[dbp->master];

	if (ip == NULL)
		_CheckEof(dbp, dbp->dp->dhp->nRec);
	else {
		if ((err = IDXBottom(ip, &rno)) != 0)
			return err;
		_CheckEof(dbp, rno);
	}

	/* 削除レコードスキップ */
	return _SkipDeleted(dbp, -1);
}

/*=======================================================================
 |
 |		レコードポインタを指定されたレコードにセット
 |
 |	SHORT	DBSet(dbp, recno)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		LONG	recNo;		レコード番号
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBSet(PDB dbp, LONG recNo)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBSet(dbp, recNo);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBSet(PDB dbp, LONG recNo)
{
	PDBF	dp;
	PIDX	ip;
	LONG	rno;
	SHORT	err;
	CHAR	kbuf[256];
	
	/* ポインタセット */
	dp = dbp->dp;
	ip = dbp->ip[dbp->master];

	if (ip != NULL) {
		/* インデックスファイルがある場合 */
		/* レコード読み込み */
		if ((err = DBFRead2(dp, recNo, dbp->rbp)) != 0)
			return err;

		/* インデックスファイルの指定されたレコード番号を探す */
		if (GetKey(dp, dbp->rbp, ip->ifp->ihp, kbuf) != 0) {
			if ((err = IDXSearch3(ip, kbuf, ip->ifp->ihp->lKey,
							recNo, &rno)) != 0)
				return err;
		}
	}

	_CheckEof(dbp, recNo);	/* ＥＯＦチェック */

	return 0;
}

/*=======================================================================
 |
 |		レコードポインタの前後移動
 |
 |	SHORT	DBSkip(dbp, n)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		LONG	n;		移動レコード数
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBSkip(PDB dbp, LONG n)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBSkip(dbp, n);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBSkip(PDB dbp, LONG n)
{
	SHORT	err;

	if (dbp->filter == NULL && dbp->select == NULL &&
						dbp->setDeleted == 0) {
		/* レコードポインタ移動 */
		if ((err = _Skip(dbp, n)) != 0)
			return err;
	} else {
		if (n < 0) {
			for ( ; n != 0; n++) {
				if ((err = _Skip(dbp, -1L)) != 0)
					return err;
				if ((err = _SkipDeleted(dbp, -1)) != 0)
					return err;
			}
		} else if (n > 0) {
			for ( ; n != 0; n--) {
				if ((err = _Skip(dbp, 1L)) != 0)
					return err;
				if ((err = _SkipDeleted(dbp, 1)) != 0)
					return err;
			}
		}
	}

	return 0;
}

/*=======================================================================
 |
 |		インデックスファイル再構築
 |
 |	SHORT	DBReindex(dbp)
 |
 |		PDB	dbp;		ＤＢポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBReindex(PDB dbp)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBReindex(dbp);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBReindex(PDB dbp)
{
	PDBF	dp;
	int	i;
	SHORT	err;

	// アクセス許可モードチェック
	if (!(dbp->permission & PERMISSION_WRITE))
		return ERROR_FILE_PERMISSION;

	/* ファイルロックチェック */
	if ((err = _FileLockCheck(dbp)) != 0)
		return err;

	dp = dbp->dp;

	for (i = 1; i <= dbp->nIdx; i++) {
		/* インデックス構築 */
		if ((err = IDXMake(dp, dbp->ip[i])) != 0)
			return err;
	}

	_DBTop(dbp);

	return 0;
}

/*=======================================================================
 |
 |		削除レコードをファイル上から削除
 |
 |	SHORT	DBPack(dbp)
 |
 |		PDB	dbp;		ＤＢポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBPack(PDB dbp)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBPack(dbp);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBPack(PDB dbp)
{
	SHORT	err;

	// アクセス許可モードチェック
	if (!(dbp->permission & PERMISSION_WRITE))
		return ERROR_FILE_PERMISSION;

	/* ファイルロックチェック */
	if ((err = _FileLockCheck(dbp)) != 0)
		return err;

	/* 削除レコードの削除 */
	if ((err = DBFPack(dbp->dp)) != 0)
		return err;

	/* インデックスファイル再構築 */
	if ((err = _DBReindex(dbp)) != 0)
		return err;

	return 0;
}

/*=======================================================================
 |
 |		カレントレコード読み込み
 |
 |	SHORT	DBRead(dbp, p)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*p;		レコード読み込みバッファポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBRead(PDB dbp, CHAR *p)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBRead(dbp, p);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBRead(PDB dbp, CHAR *p)
{
	PDBF	dp;
	PFIELD	flp;
	SHORT	*rfp;
	SHORT	err;

	/* ＢＯＦまたはＥＯＦならエラー */
	if (dbp->bof || dbp->eof)
		return ERROR_DB_EOF;

	dp = dbp->dp;

	/* カレントレコード読み込み */
	if (dbp->readField == NULL) {
		if ((err = DBFRead2(dp, dbp->rno, p)) != 0)
			return err;
	} else {
		if ((err = DBFRead2(dp, dbp->rno, dbp->rbp)) != 0)
			return err;
		for (rfp = dbp->readField; *rfp != -1; rfp++) {
			flp = &dp->flp[*rfp];
			memcpy(p, &dbp->rbp[flp->offset], flp->lField2);
			p += flp->lField2;
		}
	}

	return 0;
}

/*=======================================================================
 |
 |		複数次レコードレコード読み込み
 |
 |	SHORT	DBReadNext(dbp, nRec, p, readRec)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		SHORT	nRec;		レコード数
 |		CHAR	*p;		レコード読み込みバッファポインタ
 |		SHORT	*readRec;	実際に読んだレコード数
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBReadNext(PDB dbp, SHORT nRec, CHAR *p, SHORT *readRec)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBReadNext(dbp, nRec, p, readRec);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBReadNext(PDB dbp, SHORT nRec, CHAR *p, SHORT *readRec)
{
	PDBF	dp;
	PFIELD	flp;
	SHORT	*rfp;
	SHORT	err;

	*readRec = 0;
	dp = dbp->dp;

	if ((LONG)dbp->readSize * (LONG)nRec >= 0x10000L)
		return ERROR_DB_PARAMETER;

	while (dbp->eof == 0 && nRec != 0) {
		/* カレントレコード読み込み */
		if (dbp->readField == NULL) {
			if ((err = DBFRead2(dp, dbp->rno, p)) != 0)
				return err;
			p += dp->lRec;
		} else {
			if ((err = DBFRead2(dp, dbp->rno, dbp->rbp)) != 0)
				return err;
			for (rfp = dbp->readField; *rfp != -1; rfp++) {
				flp = &dp->flp[*rfp];
				memcpy(p, &dbp->rbp[flp->offset],
							flp->lField2);
				p += flp->lField2;
			}
		}

		if ((err = _DBSkip(dbp, 1L)) != 0)
			return err;

		(*readRec)++;
		--nRec;
	}

	return 0;
}

/*=======================================================================
 |
 |		複数前レコードレコード読み込み
 |
 |	SHORT	DBReadBack(dbp, nRec, p, readRec)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		SHORT	nRec;		レコード数
 |		CHAR	*p;		レコード読み込みバッファポインタ
 |		SHORT	*readRec;	実際に読んだレコード数
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBReadBack(PDB dbp, SHORT nRec, CHAR *p, SHORT *readRec)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBReadBack(dbp, nRec, p, readRec);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBReadBack(PDB dbp, SHORT nRec, CHAR *p, SHORT *readRec)
{
	PDBF	dp;
	PFIELD	flp;
	SHORT	*rfp;
	SHORT	err;

	*readRec = 0;
	dp = dbp->dp;

	if ((LONG)dbp->readSize * (LONG)nRec >= 0x10000L)
		return ERROR_DB_PARAMETER;

	while (dbp->bof == 0 && nRec != 0) {
		/* カレントレコード読み込み */
		if (dbp->readField == NULL) {
			if ((err = DBFRead2(dp, dbp->rno, p)) != 0)
				return err;
			p += dp->lRec;
		} else {
			if ((err = DBFRead2(dp, dbp->rno, dbp->rbp)) != 0)
				return err;
			for (rfp = dbp->readField; *rfp != -1; rfp++) {
				flp = &dp->flp[*rfp];
				memcpy(p, &dbp->rbp[flp->offset],
							flp->lField2);
				p += flp->lField2;
			}
		}

		if ((err = _DBSkip(dbp, -1L)) != 0)
			return err;

		(*readRec)++;
		--nRec;
	}

	return 0;
}

/*=======================================================================
 |
 |		キー指定によるレコード読み込み
 |
 |	SHORT	DBReadKey(dbp, key, len, buf, lock, flag)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*key;		キー
 |		SHORT	len;		キー長
 |		CHAR	*buf;		レコードバッファ
 |		SHORT	lock;		０：レコードロックなし　１：あり
 |		SHORT	*flag;		０：該当レコードなし　１：あり
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBReadKey(PDB dbp, CHAR *key, SHORT len, CHAR *buf,
						SHORT lock, SHORT *flag)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBReadKey(dbp, key, len, buf, lock, flag);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBReadKey(PDB dbp, CHAR *key, SHORT len, CHAR *buf,
						SHORT lock, SHORT *flag)
{
	SHORT	err;

	*flag = 0;

	/* レコード検索 */
	if ((err = _DBSearch(dbp, key, len)) != 0)
		return err;

	if (dbp->eof)
		return ERROR_DB_NOKEY;

	/* レコードロック */
	if (lock) {
		if ((err = _DBLock(dbp, LOCK_RECORD_WRITE)) != 0)
			return err;
	}

	if ((err = _DBRead(dbp, buf)) != 0) {
		_DBUnlock(dbp, LOCK_RECORD_WRITE);
		return err;
	}

	*flag = 1;

	return 0;
}

/*=======================================================================
 |
 |		バイナリデータ読み込み
 |
 |	SHORT	DBReadBinary(dbp, field, bufSize, buf, readSize)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*field;		フィールド名
 |		HPSTR	buf;		データバッファ
 |		LONG	bufSize;	バッファサイズ
 |		LONG	*readSize;	読み込みデータサイズ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBReadBinary(PDB dbp, CHAR *field, HPSTR buf, LONG bufSize,
							LONG *readSize)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBReadBinary(dbp, field, buf, bufSize, readSize);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBReadBinary(PDB dbp, CHAR *field, HPSTR buf, LONG bufSize,
								LONG *readSize)
{
	PFIELD	flp;
	CHAR	*fdp;
	LONG	bno;
	SHORT	err;

	*readSize = 0;

	if (field == NULL || field[0] == '\0') {
		if (dbp->brp == NULL)
			return ERROR_DB_NOKEY;

		return BINReadNext(dbp->dp->bfp, dbp->brp, buf, bufSize, readSize);
	}

	/* ＢＯＦまたはＥＯＦならエラー */
	if (dbp->bof || dbp->eof)
		return ERROR_DB_EOF;

	/* カレントレコード読み込み */
	if ((err = DBFRead(dbp->dp, dbp->rno, dbp->rbp)) != 0)
		return err;

	/* フィールド情報取り出し */
	if ((flp = GetField(dbp->dp, field)) == NULL)
		return ERROR_DB_NOKEY;

	/* フィールドタイプチェック */
	if (flp->type != 'B')
		return ERROR_DB_NOKEY;

	fdp = &dbp->rbp[flp->offset + 1];
	bno = *(LONG *)fdp;

	if (bno != 0) {
		if (dbp->brp == NULL) {
			if ((dbp->brp = malloc(sizeof(BIN_R))) == NULL)
				return ERROR_DB_MEMORY;
		}

		if ((err = BINRead(dbp->dp->bfp, dbp->brp, buf, bufSize, bno, readSize)) != 0)
			return err;
	}

	return 0;
}

/*=======================================================================
 |
 |		バイナリデータ書き込み
 |
 |	SHORT	DBWriteBinary(dbp, field, buf, bufSize)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*field;		フィールド名
 |		HPSTR	buf;		データバッファ
 |		LONG	bufSize;	バッファサイズ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBWriteBinary(PDB dbp, CHAR *field, HPSTR buf, LONG bufSize)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBWriteBinary(dbp, field, buf, bufSize);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBWriteBinary(PDB dbp, CHAR *field, HPSTR buf, LONG bufSize)
{
	PBIN	bfp;
	PFIELD	flp;
	CHAR	*fdp;
	LONG	bno;
	PSBOOL	bClear;
	SHORT	err;

	// アクセス許可モードチェック
	if (!(dbp->permission & PERMISSION_WRITE))
		return ERROR_FILE_PERMISSION;

	if (field == NULL || field[0] == '\0')
		return BINWriteNext(dbp->dp->bfp, buf, bufSize);

	/* ＢＯＦまたはＥＯＦならエラー */
	if (dbp->bof || dbp->eof)
		return ERROR_DB_EOF;

	/* カレントレコード読み込み */
	if ((err = DBFRead(dbp->dp, dbp->rno, dbp->rbp)) != 0)
		return err;

	/* データクリアチェック */
	if (field[0] == '*') {
		bClear = FALSE;
		field++;
	} else
		bClear = TRUE;

	/* フィールド情報取り出し */
	if ((flp = GetField(dbp->dp, field)) == NULL)
		return ERROR_DB_NOKEY;

	/* フィールドタイプチェック */
	if (flp->type != 'B')
		return ERROR_DB_NOKEY;

	fdp = &dbp->rbp[flp->offset + 1];
	bno = *(LONG *)fdp;

	bfp = dbp->dp->bfp;

	if (bno != 0 && bClear) {
		if ((err = BINDelete(bfp, bno)) != 0)
			return err;
		bno = 0;
	}

	if ((err = BINWrite(bfp, buf, bufSize, &bno)) != 0)
		return err;

	*(LONG *)fdp = bno;

	/* カレントレコード書き込み */
	if ((err = DBFWrite(dbp->dp, dbp->rno, dbp->rbp)) != 0)
		return err;

	return 0;
}

/*=======================================================================
 |
 |		バイナリデータサイズ取得
 |
 |	SHORT	DBGetBinarySize(dbp, field, dataSize)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*field;		フィールド名
 |		LONG	*dataSize;	読み込みデータサイズ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBGetBinarySize(PDB dbp, CHAR *field, LONG *dataSize)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBGetBinarySize(dbp, field, dataSize);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBGetBinarySize(PDB dbp, CHAR *field, LONG *dataSize)
{
	PFIELD	flp;
	CHAR	*fdp;
	LONG	bno;
	SHORT	err;

	*dataSize = 0;

	/* ＢＯＦまたはＥＯＦならエラー */
	if (dbp->bof || dbp->eof)
		return ERROR_DB_EOF;

	/* カレントレコード読み込み */
	if ((err = DBFRead(dbp->dp, dbp->rno, dbp->rbp)) != 0)
		return err;

	/* フィールド情報取り出し */
	if ((flp = GetField(dbp->dp, field)) == NULL)
		return ERROR_DB_NOKEY;

	/* フィールドタイプチェック */
	if (flp->type != 'B')
		return ERROR_DB_NOKEY;

	fdp = &dbp->rbp[flp->offset + 1];
	bno = *(LONG *)fdp;

	if (bno == 0)	
		*dataSize = 0;
	else {
		if ((err = BINGetDataSize(dbp->dp->bfp, bno, dataSize)) != 0)
			return err;
	}

	return 0;
}

/*=======================================================================
 |
 |		レコードバッファクリア
 |
 |	SHORT	DBClrRecord(dbp)
 |
 |		PDB	dbp;		ＤＢポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBClrRecord(PDB dbp)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBClrRecord(dbp);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBClrRecord(PDB dbp)
{
	memset(dbp->rbp2, ' ', dbp->dp->lRec);	/* バッファクリア */

	return 0;
}

/*=======================================================================
 |
 |		レコードバッファ読み込み
 |
 |	SHORT	DBGetRecord(dbp)
 |
 |		PDB	dbp;		ＤＢポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBGetRecord(PDB dbp)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBGetRecord(dbp);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBGetRecord(PDB dbp)
{
	SHORT	err;

	/* ＢＯＦまたはＥＯＦならエラー */
	if (dbp->bof || dbp->eof)
		return ERROR_DB_EOF;

	/* カレントレコード読み込み */
	if ((err = DBFRead2(dbp->dp, dbp->rno, dbp->rbp2)) != 0)
		return err;

	return 0;
}

/*=======================================================================
 |
 |		フィールドデータ読み込み
 |
 |	SHORT	DBGetField(dbp, field, bufp, fieldType, dataSize)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*field;		フィールド名
 |		VOID	*bufp;		フィールドバッファ
 |		SHORT	*fieldType;	フィールドの型
 |		SHORT	*dataSize;	フィールドデータ長
 |
 |		返値			エラーコード
 |	
 =======================================================================*/
SHORT	DBGetField(PDB dbp, CHAR *field, VOID *bufp, SHORT *fieldType,
							SHORT *dataSize)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBGetField(dbp, field, bufp, fieldType, dataSize);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBGetField(PDB dbp, CHAR *field, VOID *bufp, SHORT *fieldType,
							SHORT *dataSize)
{
	PFIELD	flp;
	SHORT	len;
	CHAR	*fdp;

	*dataSize = 0;

	/* フィールド情報取り出し */
	if ((flp = GetField(dbp->dp, field)) == NULL)
		return ERROR_DB_NOKEY;

	fdp = &dbp->rbp2[flp->offset];

	/* フィールドデータをそれぞれの型に変換 */
	switch (flp->type) {
	case 'C':
	case 'D':
	case 'L':
		for (len = flp->lField2; len != 0; len--) {
			if (fdp[len - 1] != ' ')
				break;
		}
		memcpy(bufp, fdp, len);
		((CHAR *)bufp)[len] = '\0';
		*dataSize = len + 1;
		break;
	case 'N':
		*(double *)bufp = natof(fdp, flp->lField2);
		*dataSize = sizeof(double);
		break;
	case 'I':
		*(LONG *)bufp = natol(fdp, flp->lField2);
		*dataSize = sizeof(LONG);
		break;
	default:
		return ERROR_DB_NOKEY;
		break;
	}

	*fieldType = flp->type;

	return 0;
}

/*=======================================================================
 |
 |		フィールドデータ書き込み
 |
 |	SHORT	DBSetField(dbp, field, bufp)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*field;		フィールド名
 |		VOID	*bufp;		フィールドバッファ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBSetField(PDB dbp, CHAR *field, VOID *bufp)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBSetField(dbp, field, bufp);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBSetField(PDB dbp, CHAR *field, VOID *bufp)
{
	PFIELD	flp;
	SHORT	len;
	CHAR	*fdp;
	CHAR	fmt[20];
	CHAR	buf[128];

	/* フィールド情報取り出し */
	if ((flp = GetField(dbp->dp, field)) == NULL)
		return ERROR_DB_NOKEY;

	fdp = &dbp->rbp2[flp->offset];

	/* 各型のデータを文字に変換 */
	switch (flp->type) {
	case 'C':
	case 'D':
	case 'L':
		len = strlen(bufp);
		if (len > flp->lField2)
			len = flp->lField2;
		memcpy(fdp, bufp, len);
		if (len < flp->lField2)
			memset(fdp + len, ' ', flp->lField2 - len);
		break;
	case 'N':
		sprintf(fmt, "%%%d.%dlf", flp->lField2, flp->lDec);
		sprintf(buf, fmt, *(double *)bufp);
		memcpy(fdp, buf, flp->lField2);
		break;
	case 'I':
		sprintf(fmt, "%%%dld", flp->lField2);
		sprintf(buf, fmt, *(LONG *)bufp);
		memcpy(fdp, buf, flp->lField2);
		break;
	default:
		return ERROR_DB_NOKEY;
		break;
	}

	return 0;
}

/*=======================================================================
 |
 |		レコード追加
 |
 |	SHORT	DBAddRecord(dbp)
 |
 |		PDB	dbp;		ＤＢポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBAddRecord(PDB dbp)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBAddRecord(dbp);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBAddRecord(PDB dbp)
{
	return _DBStore(dbp, dbp->rbp2);	/* レコード追加 */
}

/*=======================================================================
 |
 |		レコード更新
 |
 |	SHORT	DBUpdRecord(dbp)
 |
 |		PDB	dbp;		ＤＢポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBUpdRecord(PDB dbp)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBUpdRecord(dbp);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBUpdRecord(PDB dbp)
{
	return _DBUpdate(dbp, dbp->rbp2);	/* レコード更新 */
}

/*=======================================================================
 |
 |		データファイルのコピー
 |
 |	SHORT	DBCopy(dbp1, dbp2)
 |
 |		PDB	dbp1;		コピー元ＤＢポインタ
 |		PDB	dbp2;		コピー先ＤＢポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBCopy(PDB dbp1, PDB dbp2)
{
	SHORT	err;

	// アクセス許可モードチェック
	if (!(dbp2->permission & PERMISSION_WRITE))
		return ERROR_FILE_PERMISSION;

	/* データファイルコピー */
	if ((err = DBFCopy(dbp1->dp, dbp2->dp)) != 0)
		return err;

	/* インデックスファイル再構築 */
	return _DBReindex(dbp2);
}

/*=======================================================================
 |
 |		削除レコードチェック
 |
 |	SHORT	DBCheckDeleted(dbp, flag)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		SHORT	*flag;		０：通常レコード　１：削除レコード
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBCheckDeleted(PDB dbp, SHORT *flag)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBCheckDeleted(dbp, flag);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBCheckDeleted(PDB dbp, SHORT *flag)
{
	/* ＢＯＦまたはＥＯＦならエラー */
	if (dbp->bof || dbp->eof)
		return ERROR_DB_EOF;

	return DBFCheckDeleted(dbp->dp, dbp->rno, flag);
}

/*=======================================================================
 |
 |		フィルタ設定
 |
 |	SHORT	DBSetFilter(dbp, filter)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*filter;	フィルタ条件式
 |					（NULL の場合はフィルタ解除）
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBSetFilter(PDB dbp, CHAR *filter)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBSetFilter(dbp, filter);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBSetFilter(PDB dbp, CHAR *filter)
{
	int	len;
	SHORT	err;

	if (dbp->filter != NULL) {
		free(dbp->filter);
		dbp->filter = NULL;
	}

	if (filter != NULL) {
		len = (int)strlen(filter);
		if (strlen(filter) != 0) {
			if ((err = SetFilter(dbp, filter)) != 0)
				return err;
		}
	}

	return _DBTop(dbp);		/* 先頭レコード */
}

/*=======================================================================
 |
 |		選択条件設定
 |
 |	SHORT	DBSelect(dbp, select, nRec)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*select;	選択条件式
 |		LONG	*nRec;		選択レコード数
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBSelect(PDB dbp, CHAR *select, LONG *nRec)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBSelect(dbp, select, nRec);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBSelect(PDB dbp, CHAR *select, LONG *nRec)
{
	int	len;
	SHORT	err;

	*nRec = 0;

	if (dbp->select != NULL) {
		HFREE(dbp->select);
		dbp->select = NULL;
	}

	if (select != NULL) {
		len = (int)strlen(select);
		if (strlen(select) != 0) {
			if ((err = SetSelect(dbp, select, nRec)) != 0)
				return err;
		}
	}

	return _DBTop(dbp);		/* 先頭レコード */
}

/*=======================================================================
 |
 |		削除レコード有効／無効の設定
 |
 |	SHORT	DBSetDeleted(dbp, flag)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		SHORT	flag;		０：削除レコード有効
 |					１：削除レコード無効
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBSetDeleted(PDB dbp, SHORT flag)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBSetDeleted(dbp, flag);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBSetDeleted(PDB dbp, SHORT flag)
{
	dbp->setDeleted = flag;
	return _DBTop(dbp);		/* 先頭レコード */
}

/*=======================================================================
 |
 |		カレントレコードの論理レコード番号取り出し
 |
 |	SHORT	DBLRecNo(dbp, recNo)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		LONG	*recNo;		論理レコード番号
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBLRecNo(PDB dbp, LONG *recNo)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBLRecNo(dbp, recNo);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBLRecNo(PDB dbp, LONG *recNo)
{
	LONG	pRecNo, lRecNo;
	SHORT	err;

	if (dbp->bof || dbp->eof)
		return ERROR_DB_EOF;

	_DBRecNo(dbp, &pRecNo);
	_DBTop(dbp);
	for (lRecNo = 1; pRecNo != dbp->rno; lRecNo++) {
		if (dbp->eof)
			return 0L;
		if ((err = _DBSkip(dbp, 1L)) != 0)
			return err;
	}

	*recNo = lRecNo;

	return 0;
}

/*=======================================================================
 |
 |		論理レコード数取り出し
 |
 |	LONG	DBLRecCount(dbp, nRec)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		LONG	*nRec;		論理レコード数
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBLRecCount(PDB dbp, LONG *nRec)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBLRecCount(dbp, nRec);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBLRecCount(PDB dbp, LONG *nRec)
{
	LONG	count;
	SHORT	bof;
	SHORT	eof;
	LONG	rno;
	SHORT	master;
	SHORT	err;

	if (dbp->filter == NULL && dbp->select == NULL && dbp->setDeleted == 0)
		*nRec = dbp->dp->dhp->nRec;
	else {
		bof = dbp->bof;
		eof = dbp->eof;
		rno = dbp->rno;
		master = dbp->master;
		dbp->master = 0;

		_DBTop(dbp);
		for (count = 0; dbp->eof == 0; count++) {
			if ((err = _DBSkip(dbp, 1L)) != 0)
				return err;
		}

		dbp->bof = bof;
		dbp->eof = eof;
		dbp->rno = rno;
		dbp->master = master;

		*nRec = count;
	}

	return 0;
}

/*=======================================================================
 |
 |		論理レコード番号によるカレントレコードの設定
 |
 |	SHORT	DBLSet(dbp, lRecNo)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		LONG	lRecNo;		論理レコード番号
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBLSet(PDB dbp, LONG lRecNo)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBLSet(dbp, lRecNo);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBLSet(PDB dbp, LONG lRecNo)
{
	SHORT	err;

	if ((err = _DBTop(dbp)) != 0)
		return err;

	return _DBSkip(dbp, lRecNo - 1);
}

/*=======================================================================
 |
 |		全レコード削除
 |
 |	SHORT	DBZip(dbp)
 |
 |		PDB	dbp;		ＤＢポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBZip(PDB dbp)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBZip(dbp);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBZip(PDB dbp)
{
	SHORT	err;

	// アクセス許可モードチェック
	if (!(dbp->permission & PERMISSION_WRITE))
		return ERROR_FILE_PERMISSION;

	/* ファイルロックチェック */
	if ((err = _FileLockCheck(dbp)) != 0)
		return err;

	/* データファイル全レコード削除 */
	if ((err = DBFZip(dbp->dp)) != 0)
		return err;

	/* インデックス再構築 */
	return _DBReindex(dbp);
}

/*=======================================================================
 |
 |		更新チェック
 |
 |	SHORT	DBCheckUpdate(dbp, updateFlag)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		SHORT	*updateFlag;	０：更新なし　１：更新あり
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBCheckUpdate(PDB dbp, SHORT *updateFlag)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBCheckUpdate(dbp, updateFlag);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBCheckUpdate(PDB dbp, SHORT *updateFlag)
{
	*updateFlag = (dbp->updateCount != dbp->dp->updateCount) ? 1 : 0;
	dbp->updateCount = dbp->dp->updateCount;

	return 0;
}

/*=======================================================================
 |
 |		ファイル／レコードロック
 |
 |	SHORT	DBLock(dbp, lock)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		SHORT	lock;		０：ファイルロック　１：レコードロック
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBLock(PDB dbp, SHORT lock)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBLock(dbp, lock);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBLock(PDB dbp, SHORT lock)
{
	PDBF	dp;
	PDBLOCK	dlp;

	dp = dbp->dp;
	switch (lock) {
	case LOCK_FILE_WRITE:
		if (dbp->writeLockCount != 0) {
			dbp->writeLockCount++;
			break;
		}

		/* ファイルロックチェック */
		if (dp->readLockCount != 0 || dp->writeLockCount != 0)
			return ERROR_DB_LOCK;

		ENTER_CRITICAL_SECTION(&csDBL);

		/* 読み込みレコードロックチェック */
		for (dlp = dp->rdlp; dlp != NULL; dlp = dlp->chain) {
			if (dlp->dbp != dbp) {
				LEAVE_CRITICAL_SECTION(&csDBL);
				return ERROR_DB_LOCK;
			}
		}

		/* 書き込みレコードロックチェック */
		for (dlp = dp->wdlp; dlp != NULL; dlp = dlp->chain) {
			if (dlp->dbp != dbp) {
				LEAVE_CRITICAL_SECTION(&csDBL);
				return ERROR_DB_LOCK;
			}
		}

		LEAVE_CRITICAL_SECTION(&csDBL);

		dbp->writeLockCount++;
		dp->writeLockCount++;
		break;
	case LOCK_RECORD_WRITE:
		/* ＢＯＦまたはＥＯＦならエラー */
		if (dbp->bof || dbp->eof)
			return ERROR_DB_EOF;

		/* ファイルロックチェック */
		if (dp->readLockCount != 0 ||
					(dp->writeLockCount != 0 &&
					dbp->writeLockCount == 0))
			return ERROR_DB_LOCK;

		ENTER_CRITICAL_SECTION(&csDBL);

		/* 読み込みレコードロックチェック */
		for (dlp = dp->rdlp; dlp != NULL; dlp = dlp->chain) {
			if (dlp->rno == dbp->rno) {
				LEAVE_CRITICAL_SECTION(&csDBL);
				return ERROR_DB_LOCK;
			}
		}

		/* 書き込みレコードロックチェック */
		for (dlp = dp->wdlp; dlp != NULL; dlp = dlp->chain) {
			if (dlp->rno == dbp->rno) {
				if (dlp->dbp != dbp) {
					LEAVE_CRITICAL_SECTION(&csDBL);
					return ERROR_DB_LOCK;
				}
				break;
			}
		}

		if (dlp == NULL) {
			if ((dlp = malloc(sizeof(DBLOCK))) == NULL) {
				LEAVE_CRITICAL_SECTION(&csDBL);
				return ERROR_DB_MEMORY;
			}
			memset(dlp, 0, sizeof(DBLOCK));

			dlp->dbp = dbp;
			dlp->rno = dbp->rno;

			dlp->chain = dp->wdlp;
			dp->wdlp = dlp;
		}

		LEAVE_CRITICAL_SECTION(&csDBL);
		break;
	case LOCK_FILE_READ:
		if (dbp->readLockCount != 0) {
			dbp->readLockCount++;
			break;
		}

		/* ファイルロックチェック */
		if (dp->writeLockCount != 0)
			return ERROR_DB_LOCK;

		ENTER_CRITICAL_SECTION(&csDBL);

		/* 書き込みレコードロックチェック */
		if (dp->wdlp != NULL) {
			LEAVE_CRITICAL_SECTION(&csDBL);
			return ERROR_DB_LOCK;
		}

		LEAVE_CRITICAL_SECTION(&csDBL);

		dbp->readLockCount++;
		dp->readLockCount++;
		break;
	case LOCK_RECORD_READ:
		/* ＢＯＦまたはＥＯＦならエラー */
		if (dbp->bof || dbp->eof)
			return ERROR_DB_EOF;

		/* ファイルロックチェック */
		if (dp->writeLockCount != 0)
			return ERROR_DB_LOCK;

		ENTER_CRITICAL_SECTION(&csDBL);

		/* 書き込みレコードロックチェック */
		for (dlp = dp->wdlp; dlp != NULL; dlp = dlp->chain) {
			if (dlp->rno == dbp->rno) {
				LEAVE_CRITICAL_SECTION(&csDBL);
				return ERROR_DB_LOCK;
			}
		}

		for (dlp = dp->rdlp; dlp != NULL; dlp = dlp->chain) {
			if (dlp->rno == dbp->rno)
				break;
		}

		if (dlp == NULL) {
			if ((dlp = malloc(sizeof(DBLOCK))) == NULL) {
				LEAVE_CRITICAL_SECTION(&csDBL);
				return ERROR_DB_MEMORY;
			}
			memset(dlp, 0, sizeof(DBLOCK));

			dlp->dbp = dbp;
			dlp->rno = dbp->rno;

			dlp->chain = dp->rdlp;
			dp->rdlp = dlp;
		}

		LEAVE_CRITICAL_SECTION(&csDBL);
		break;
	default:
		return ERROR_DB_PARAMETER;
	}

	return 0;
}

/*=======================================================================
 |
 |		ファイル／レコードロック解除
 |
 |	SHORT	DBUnlock(dbp, lock)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		SHORT	lock;		０：ファイルロック　１：レコードロック
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBUnlock(PDB dbp, SHORT lock)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBUnlock(dbp, lock);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBUnlock(PDB dbp, SHORT lock)
{
	PDBF	dp;
	PDBLOCK	chain, *dlpp;

	dp = dbp->dp;

	switch (lock) {
	case LOCK_FILE_WRITE:
		if (dbp->writeLockCount != 0) {
			if (--dbp->writeLockCount == 0) {
				if (dp->writeLockCount > 0)
					dp->writeLockCount--;
			}
		}
		break;
	case LOCK_RECORD_WRITE:
		ENTER_CRITICAL_SECTION(&csDBL);
		for (dlpp = &dp->wdlp; *dlpp != 0; ) {
			if ((*dlpp)->dbp == dbp) {
				chain = (*dlpp)->chain;
				free(*dlpp);
				*dlpp = chain;
			} else
				dlpp = &(*dlpp)->chain;
		}
		LEAVE_CRITICAL_SECTION(&csDBL);
		break;
	case LOCK_FILE_READ:
		if (dbp->readLockCount != 0) {
			if (--dbp->readLockCount == 0) {
				if (dp->readLockCount > 0)
					dp->readLockCount--;
			}
		}
		break;
	case LOCK_RECORD_READ:
		ENTER_CRITICAL_SECTION(&csDBL);
		for (dlpp = &dp->rdlp; *dlpp != 0; ) {
			if ((*dlpp)->dbp == dbp) {
				chain = (*dlpp)->chain;
				free(*dlpp);
				*dlpp = chain;
			} else
				dlpp = &(*dlpp)->chain;
		}
		LEAVE_CRITICAL_SECTION(&csDBL);
		break;
	default:
		return ERROR_DB_PARAMETER;
	}

	return 0;
}

/*=======================================================================
 |
 |		レコード数取り出し
 |
 |	SHORT	DBRecCount(dbp, nRec)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		LONG	*nRec;		レコード数
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBRecCount(PDB dbp, LONG *nRec)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBRecCount(dbp, nRec);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBRecCount(PDB dbp, LONG *nRec)
{
	*nRec = dbp->dp->dhp->nRec;

	return 0;
}

/*=======================================================================
 |
 |		ＢＯＦチェック
 |
 |	SHORT	DBBof(dbp, bof)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		SHORT	*bof;		０：ＢＯＦでない　１：ＢＯＦ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBBof(PDB dbp, SHORT *bof)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBBof(dbp, bof);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBBof(PDB dbp, SHORT *bof)
{
	*bof = dbp->bof;

	return 0;
}

/*=======================================================================
 |
 |		データファイル名取り出し
 |
 |	SHORT	DBDbf(dbp, fileName)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*fileName;	データファイル名
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBDbf(PDB dbp, CHAR *fileName)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBDbf(dbp, fileName);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBDbf(PDB dbp, CHAR *fileName)
{
	strcpy(fileName, dbp->dp->fileName);

	return 0;
}

/*=======================================================================
 |
 |		ＥＯＦチェック
 |
 |	SHORT	DBEof(dbp, eof)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		SHORT	*eof;		０：ＥＯＦでない　１：ＥＯＦ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBEof(PDB dbp, SHORT *eof)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBEof(dbp, eof);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBEof(PDB dbp, SHORT *eof)
{
	*eof = dbp->eof;

	return 0;
}

/*=======================================================================
 |
 |		フィールド数取得
 |
 |	SHORT	DBNField(dbp, nField)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		SHORT	*nField;	フィールド数
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBNField(PDB dbp, SHORT *nField)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBNField(dbp, nField);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBNField(PDB dbp, SHORT *nField)
{
	*nField = dbp->dp->nField;

	return 0;
}

/*=======================================================================
 |
 |		フィールド情報取り出し
 |
 |	SHORT	DBField(dbp, n, dip)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		SHORT	n;		フィールド番号
 |		PDBF_I	dip;		フィールド情報
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBField(PDB dbp, SHORT n, PDBF_I dip)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBField(dbp, n, dip);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBField(PDB dbp, SHORT n, PDBF_I dip)
{
	PDBF	dp;
	PFIELD	flp;

	dp = dbp->dp;
	if (n < 1 || n > dp->nField)
		return ERROR_DB_PARAMETER;

	flp = &dp->flp[n - 1];
	strcpy(dip->name, flp->name);
	dip->type = flp->type;
	dip->lField = (flp->type == 'B') ? 0 : flp->lField2;
	dip->lDec = flp->lDec;

	return 0;
}

/*=======================================================================
 |
 |		インデックスファイル名取り出し
 |
 |	SHORT	DBNdx(dbp, n, fileName)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		SHORT	n;		インデックスファイル番号
 |		CHAR	*fileName;	インデックスファイル名へ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBNdx(PDB dbp, SHORT n, CHAR *fileName)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBNdx(dbp, n, fileName);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBNdx(PDB dbp, SHORT n, CHAR *fileName)
{
	fileName[0] = '\0';

	if (n < 1 || n > dbp->nIdx)
		return ERROR_DB_PARAMETER;

	strcpy(fileName, dbp->ip[n]->ifp->fileName);

	return 0;
}

/*=======================================================================
 |
 |		カレントレコード番号取り出し
 |
 |	SHORT	DBRecNo(dbp, recNo)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		LONG	*renNo;		カレントレコード番号
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBRecNo(PDB dbp, LONG *recNo)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBRecNo(dbp, recNo);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBRecNo(PDB dbp, LONG *recNo)
{
	*recNo = dbp->rno;

	return 0;
}

/*=======================================================================
 |
 |		レコード長取り出し
 |
 |	SHORT	DBRecSize(dbp, lRec)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		SHORT	*lRec;		レコード長
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBRecSize(PDB dbp, SHORT *lrec)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBRecSize(dbp, lrec);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBRecSize(PDB dbp, SHORT *lrec)
{
	*lrec = dbp->dp->lRec + 1;

	return 0;
}

/*=======================================================================
 |
 |		読み込みフィールド設定
 |
 |	SHORT	DBSetReadField(dbp, readField, length)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*readField;	読み込みフィールド名
 |		SHORT	*length;	データ長
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBSetReadField(PDB dbp, CHAR *readField, SHORT *length)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBSetReadField(dbp, readField, length);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBSetReadField(PDB dbp, CHAR *readField, SHORT *length)
{
	PDBF	dp;
	CHAR	*p;
	int	count;
	SHORT	fieldNo;
	SHORT	*sp;
	CHAR	*wp;

	dp = dbp->dp;

	if (dbp->readField != NULL) {
		free(dbp->readField);
		dbp->readField = NULL;
		dbp->readSize = dp->lRec;
	}

	if (readField != NULL && readField[0] != '\0') {
		if ((sp = (SHORT *)malloc(1000 * sizeof(SHORT))) == NULL)
			return ERROR_DB_MEMORY;
		if ((wp = malloc(strlen(readField) + 1)) == NULL) {
			free(sp);
			return ERROR_DB_MEMORY;
		}
		dbp->readSize = 0;
		count = 0;
		strcpy(wp, readField);
		p = strtok(wp, "+ ");
		while (p) {
			if ((fieldNo = GetFieldNo(dp, p)) == -1) {
				free(sp);
				free(wp);
				return ERROR_DB_PARAMETER;
			}

			sp[count++] = fieldNo;
			dbp->readSize += dp->flp[fieldNo].lField2;
			p = strtok(NULL, "+ ");
		}
		free(wp);
		sp[count++] = -1;
		if ((dbp->readField = (SHORT *)realloc(sp,
					count * sizeof(SHORT))) == NULL) {
			free(sp);
			return ERROR_DB_MEMORY;
		}
	} else
		dbp->readSize = dbp->dp->lRec;

	*length = dbp->readSize;

	return 0;
}

/*=======================================================================
 |
 |		暗号化キー設定
 |
 |	SHORT	DBSetScramble(dbp)
 |
 |		PDB	dbp;		ＤＢポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBSetScramble(PDB dbp)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBSetScramble(dbp);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBSetScramble(PDB dbp)
{
	long	ltime;
	USHORT	scramble;

	// アクセス許可モードチェック
	if (!(dbp->permission & PERMISSION_WRITE))
		return ERROR_FILE_PERMISSION;

	time(&ltime);
	scramble = (USHORT)ltime;
	if (scramble == 0)
		scramble = 1;

	return DBFSetScramble(dbp->dp, scramble);
}

/*=======================================================================
 |
 |		パスワード設定
 |
 |	SHORT	DBSetPassword(dbp, password)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		CHAR	*password;	パスワード
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBSetPassword(PDB dbp, CHAR *password)
{
	// アクセス許可モードチェック
	if (!(dbp->permission & PERMISSION_WRITE))
		return ERROR_FILE_PERMISSION;

	return DBFSetPassword(dbp->dp, password);
}

/*=======================================================================
 |
 |		レコード番号指定によるレコード更新
 |
 |	SHORT	DBUpdateEx(dbp, recNo, rec)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		LONG	recNo;		レコード番号
 |		CHAR	*rec;		更新するレコードデータへのポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBUpdateEx(PDB dbp, LONG recNo, CHAR *rec)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBUpdateEx(dbp, recNo, rec);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBUpdateEx(PDB dbp, LONG recNo, CHAR *rec)
{
	SHORT	err;

	// アクセス許可モードチェック
	if (!(dbp->permission & PERMISSION_WRITE))
		return ERROR_FILE_PERMISSION;

	/* カレントレコードセット */
	if ((err = _DBSet(dbp, recNo)) != 0)
		return err;

	return _DBUpdate(dbp, rec);
}

/*=======================================================================
 |
 |		レコード番号指定によるレコード削除
 |
 |	SHORT	DBDeleteEx(dbp, recNo)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		LONG	recNo;		レコード番号
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBDeleteEx(PDB dbp, LONG recNo)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBDeleteEx(dbp, recNo);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBDeleteEx(PDB dbp, LONG recNo)
{
	SHORT	err;

	// アクセス許可モードチェック
	if (!(dbp->permission & PERMISSION_WRITE))
		return ERROR_FILE_PERMISSION;

	/* カレントレコードセット */
	if ((err = _DBSet(dbp, recNo)) != 0)
		return err;

	return _DBDelete(dbp);
}

/*=======================================================================
 |
 |		レコード番号指定によるレコード復元
 |
 |	SHORT	DBRecallEx(dbp, recNo)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		LONG	recNo;		レコード番号
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBRecallEx(PDB dbp, LONG recNo)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBRecallEx(dbp, recNo);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBRecallEx(PDB dbp, LONG recNo)
{
	SHORT	err;

	// アクセス許可モードチェック
	if (!(dbp->permission & PERMISSION_WRITE))
		return ERROR_FILE_PERMISSION;

	/* カレントレコードセット */
	if ((err = _DBSet(dbp, recNo)) != 0)
		return err;

	return _DBRecall(dbp);
}

/*=======================================================================
 |
 |		レコード番号指定による物理レコード削除
 |
 |	SHORT	DBDelete2Ex(dbp, recNo)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		LONG	recNo;		レコード番号
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBDelete2Ex(PDB dbp, LONG recNo)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBDelete2Ex(dbp, recNo);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBDelete2Ex(PDB dbp, LONG recNo)
{
	SHORT	err;

	// アクセス許可モードチェック
	if (!(dbp->permission & PERMISSION_WRITE))
		return ERROR_FILE_PERMISSION;

	/* カレントレコードセット */
	if ((err = _DBSet(dbp, recNo)) != 0)
		return err;

	return _DBDelete2(dbp);
}

/*=======================================================================
 |
 |		レコード番号指定によるレコード／ファイルロック
 |
 |	SHORT	DBLockEx(dbp, recNo, lock)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		LONG	recNo;		レコード番号
 |		SHORT	lock;		０：ファイルロック　１：レコードロック
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBLockEx(PDB dbp, LONG recNo, SHORT lock)
{
	SHORT	err;

	ENTER_CRITICAL_SECTION(&dbp->dp->csDBF);
	err = _DBLockEx(dbp, recNo, lock);
	LEAVE_CRITICAL_SECTION(&dbp->dp->csDBF);

	return err;
}

static	SHORT	_DBLockEx(PDB dbp, LONG recNo, SHORT lock)
{
	SHORT	err;

	/* カレントレコードセット */

	if (lock == LOCK_RECORD_WRITE || lock == LOCK_RECORD_READ) {
		if ((err = _DBSet(dbp, recNo)) != 0)
			return err;
	}

	return _DBLock(dbp, lock);
}

/*=======================================================================
 |
 |		インデックスファイルのパック
 |
 |	SHORT	DBPackIndex(fileName)
 |
 |		CHAR	*fileName;	インデックスファイル名
 |
 |		返値			エラーコード
 |
 =======================================================================*/
SHORT	DBPackIndex(CHAR *fileName)
{
	PIDX	ip;
	SHORT	err;

	/* インデックスファイルオープン */
	if ((err = IDXOpen(fileName, &ip)) != 0)
		return err;

	err = IDXPack(ip);

	IDXClose(ip);

	return err;
}

/*=======================================================================
 |
 |		ファイルロックチェック
 |
 |	SHORT	_FileLockCheck(dbp)
 |
 |		PDB	dbp;		ＤＢポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
static	SHORT	_FileLockCheck(PDB dbp)
{
	PDBF	dp;
	PDBLOCK	dlp;

	dp = dbp->dp;

	/* ファイルロックチェック */
	if (dp->readLockCount != 0 ||
			(dp->writeLockCount != 0 && dbp->writeLockCount == 0))
		return ERROR_DB_LOCK;

	ENTER_CRITICAL_SECTION(&csDBL);

	/* 読み込みレコードロックチェック */
	if (dp->rdlp != NULL) {
		LEAVE_CRITICAL_SECTION(&csDBL);
		return ERROR_DB_LOCK;
	}

	/* 書き込みレコードロックチェック */
	for (dlp = dp->wdlp; dlp != NULL; dlp = dlp->chain) {
		if (dlp->dbp != dbp) {
			LEAVE_CRITICAL_SECTION(&csDBL);
			return ERROR_DB_LOCK;
		}
	}

	LEAVE_CRITICAL_SECTION(&csDBL);

	return 0;
}

/*=======================================================================
 |
 |		レコードロックチェック
 |
 |	SHORT	_RecordLockCheck(dbp)
 |
 |		PDB	dbp;		ＤＢポインタ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
static	SHORT	_RecordLockCheck(PDB dbp)
{
	PDBF	dp;
	PDBLOCK	dlp;

	dp = dbp->dp;

	/* ファイルロックチェック */
	if (dp->readLockCount != 0 ||
			(dp->writeLockCount != 0 && dbp->writeLockCount == 0))
		return ERROR_DB_LOCK;

	ENTER_CRITICAL_SECTION(&csDBL);

	/* 読み込みレコードロックチェック */
	for (dlp = dp->rdlp; dlp != NULL; dlp = dlp->chain) {
		if (dlp->rno == dbp->rno) {
			LEAVE_CRITICAL_SECTION(&csDBL);
			return ERROR_DB_LOCK;
		}
	}

	/* 書き込みレコードロックチェック */
	for (dlp = dp->wdlp; dlp != NULL; dlp = dlp->chain) {
		if (dlp->rno == dbp->rno) {
			if (dlp->dbp != dbp) {
				LEAVE_CRITICAL_SECTION(&csDBL);
				return ERROR_DB_LOCK;
			}
			break;
		}
	}

	LEAVE_CRITICAL_SECTION(&csDBL);

	return 0;
}

/*=======================================================================
 |
 |		削除レコードのスキップ
 |
 |	SHORT	_SkipDeleted(dbp, n)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		int	n;		１：後ろへスキップ　−１：前へスキップ
 |
 |		返値			エラーコード
 |
 =======================================================================*/
static	SHORT	_SkipDeleted(PDB dbp, int n)
{
	SHORT	flag;
	SHORT	err;

	for (;;) {
		if (dbp->bof || dbp->eof)
			break;

		if (dbp->select != NULL) {
			if (dbp->rno <= dbp->selectRec &&
					(dbp->select[dbp->rno / 8] &
					bitTable1[dbp->rno % 8]) == 0) {
				if ((err = _Skip(dbp, (LONG)n)) != 0)
					return err;
				continue;
			}
		}

		if (dbp->setDeleted != 0) {
			if ((err = DBFCheckDeleted(dbp->dp, dbp->rno, &flag))
								!= 0)
				return err;
			if (flag) {
				if ((err = _Skip(dbp, (LONG)n)) != 0)
					return err;
				continue;
			}
		}

		if (dbp->filter != NULL) {
			if ((err = DBFRead(dbp->dp, dbp->rno, dbp->rbp)) != 0)
				return err;

			if (CheckFilter(dbp) == 0) {
				if ((err = _Skip(dbp, (LONG)n)) != 0)
					return err;
				continue;
			}
		}
		break;
	}

	return 0;
}

/*=======================================================================
 |
 |		レコードの前後移動
 |
 |	SHORT	_Skip(dbp, n)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		LONG	n;		移動レコード数
 |
 |		返値			エラーコード
 |
 =======================================================================*/
static	SHORT	_Skip(PDB dbp, LONG n)
{
	PDBF	dp;
	PIDX	ip;
	LONG	rno;
	SHORT	err;

	dp = dbp->dp;
	ip = dbp->ip[dbp->master];

	rno = dbp->rno;
	if (ip == NULL) {
		/* インデックスファイルがない場合 */
		if (n > 0 && dbp->bof)
			rno = n;
		else if (n < 0 && dbp->eof)
			rno = dp->dhp->nRec + n + 1;
		else
			rno = dbp->rno + n;

		if (rno <= 0)
			_CheckBof(dbp, 0L);
		else if (rno > dp->dhp->nRec)
			_CheckEof(dbp, 0L);
		else
			_CheckEof(dbp, rno);
	} else {
		/* インデックスファイルがある場合 */
		if (n > 0) {
			if (dbp->bof) {
				if ((err = IDXTop(ip, &rno)) != 0)
					return err;
				n--;
			}
			while (n-- != 0) {
				if ((err = IDXNext(ip, &rno)) != 0)
					return err;
				if (rno == 0)
					break;
			}
			_CheckEof(dbp, rno);
		} else if (n < 0) {
			if (dbp->eof) {
				if ((err = IDXBottom(ip, &rno)) != 0)
					return err;
				n++;
			}
			while (n++ != 0) {
				if ((err = IDXBack(ip, &rno)) != 0)
					return err;
				if (rno == 0)
					break;
			}
			_CheckBof(dbp, rno);
		}
	}

	return 0;
}

/*=======================================================================
 |
 |		ＢＯＦチェック
 |
 |	VOID	_CheckBof(dbp, rno)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		LONG	rno;		レコード番号
 |
 =======================================================================*/
static	VOID	_CheckBof(PDB dbp, LONG rno)
{
	if (dbp->dp->dhp->nRec == 0) {
		/* レコードが１件もない場合 */
		dbp->rno = 1;
		dbp->bof = 1;
		dbp->eof = 1;
	} else {
		if (rno == 0) {
			dbp->rno = 1;
			dbp->bof = 1;
			dbp->eof = 0;
		} else {
			dbp->rno = rno;
			dbp->bof = 0;
			dbp->eof = 0;
		}
	}
}

/*=======================================================================
 |
 |		ＥＯＦチェック
 |
 |	VOID	_CheckEof(dbp, rno)
 |
 |		PDB	dbp;		ＤＢポインタ
 |		LONG	rno;		レコード番号
 |
 =======================================================================*/
static	VOID	_CheckEof(PDB dbp, LONG rno)
{
	if (dbp->dp->dhp->nRec == 0) {
		/* レコードが１件もない場合 */
		dbp->rno = 1;
		dbp->bof = 1;
		dbp->eof = 1;
	} else {
		if (rno == 0) {
			dbp->rno = dbp->dp->dhp->nRec + 1;
			dbp->bof = 0;
			dbp->eof = 1;
		} else {
			dbp->rno = rno;
			dbp->bof = 0;
			dbp->eof = 0;
		}
	}
}
