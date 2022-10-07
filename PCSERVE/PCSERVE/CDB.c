/************************************************************************
 *
 *			ＰＣ−ＳＥＲＶＥ
 *
 *		名称		: クライアント側ＤＢ関数処理
 *		ファイル名	: cdb.c
 *		作成者		: s.aizawa
 *
 ************************************************************************/

#include "PCSOS.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "PCSCLNT.h"

#ifdef	OS_VMS
#define min(a,b)	(((a) < (b)) ? (a) : (b))
#endif

/*=======================================================================
 |
 |		データベースオープン
 |
 |	PFCB	PSDBOpen(pCCB, fileName)
 |
 |		PCCB	pCCB;		クライアント制御ブロックポインタ
 |		CHAR	*fileName;	データファイル名
 |
 |		PFCB	返値		ファイル制御ブロックポインタ
 |
 =======================================================================*/
PFCB	PSENTRY PSDBOpen(PCCB pCCB, CHAR *fileName)
{
	PFCB	pFCB;

	if ((pFCB = malloc(sizeof(FCB))) == NULL) {
		pCCB->errorCode = ERROR_CLIENT_MEMORY;
		return NULL;
	}

	memset(pFCB, 0, sizeof(FCB));
	pFCB->fileType = FILETYPE_DB;
	pFCB->pCCB = pCCB;

	{
		if ((pCCB->errorCode = DBOpen(fileName, &pFCB->pDB, PERMISSION_ALL)) != 0) {
			free(pFCB);
			return NULL;
		}
		pFCB->DBInf.recSize = pFCB->pDB->dp->lRec;
	}

	pFCB->readSize = pFCB->DBInf.recSize;

	pFCB->chain = pCCB->pFCB;
	pCCB->pFCB = pFCB;

	return pFCB;
}

/*=======================================================================
 |
 |		データベース作成
 |
 |	PFCB	PSDBCreate(pCCB, fileName, dip, nField)
 |
 |		PCCB	pCCB;		クライアント制御ブロックポインタ
 |		CHAR	*fileName;	データファイル名
 |		PDBF_I	dip;		フィールド情報
 |		SHORT	nField;		フィールド数
 |
 |		PFCB	返値		ファイル制御ブロックポインタ
 |
 =======================================================================*/
PFCB	PSENTRY PSDBCreate(PCCB pCCB, CHAR *fileName, PDBF_I dip,
								SHORT nField)
{
	PFCB	pFCB;

	if ((pFCB = malloc(sizeof(FCB))) == NULL) {
		pCCB->errorCode = ERROR_CLIENT_MEMORY;
		return NULL;
	}

	memset(pFCB, 0, sizeof(FCB));
	pFCB->fileType = FILETYPE_DB;
	pFCB->pCCB = pCCB;

	{
		if ((pCCB->errorCode = DBCreate(fileName, dip, nField, &pFCB->pDB, PERMISSION_ALL)) != 0) {
			free(pFCB);
			return NULL;
		}
		pFCB->DBInf.recSize = pFCB->pDB->dp->lRec;
	}

	pFCB->readSize = pFCB->DBInf.recSize;

	pFCB->chain = pCCB->pFCB;
	pCCB->pFCB = pFCB;

	return pFCB;
}

/*=======================================================================
 |
 |		データベースクローズ
 |
 |	VOID	PSDBClose(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 =======================================================================*/
VOID	PSENTRY PSDBClose(PFCB pFCB)
{
	PCCB	pCCB;
	PFCB	*pPFCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBClose(pFCB->pDB);
	}

	for (pPFCB = &pCCB->pFCB; *pPFCB != 0; pPFCB = &(*pPFCB)->chain) {
		if ((*pPFCB) == pFCB) {
			*pPFCB = (*pPFCB)->chain;
			break;
		}
	}

	if (err != 0) {
		pCCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	if (pFCB->pReadBuffer != NULL)
		free(pFCB->pReadBuffer);

	free(pFCB);
}

/*=======================================================================
 |
 |		全データベースクローズ
 |
 |	VOID	PSDBCloseAll(pCCB)
 |
 |		PFCB	pCCB;		クライアント制御ブロックポインタ
 |
 =======================================================================*/
VOID	PSENTRY PSDBCloseAll(PCCB pCCB)
{
	PFCB	pFCB;

loop:
	for (pFCB = pCCB->pFCB; pFCB != NULL; pFCB = pFCB->chain) {
		if (pFCB->fileType == FILETYPE_DB) {
			PSDBClose(pFCB);
			goto loop;
		}
	}
}

/*=======================================================================
 |
 |		ファイル強制掃き出し
 |
 |	VOID	PSDBFlush(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 =======================================================================*/
VOID	PSENTRY PSDBFlush(PFCB pFCB)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBFlush(pFCB->pDB);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		全ファイル強制掃き出し
 |
 |	VOID	PSDBFlushAll(pCCB)
 |
 |		PFCB	pCCB;		クライアント制御ブロックポインタ
 |
 =======================================================================*/
VOID	PSENTRY PSDBFlushAll(PCCB pCCB)
{
	PFCB	pFCB;

	for (pFCB = pCCB->pFCB; pFCB != NULL; pFCB = pFCB->chain) {
		if (pFCB->fileType == FILETYPE_DB)
			PSDBFlush(pFCB);
	}
}

/*=======================================================================
 |
 |		インデックスファイルオープン
 |
 |	SHORT	PSDBIndex(pFCB, fileName)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*fileName;	インデックスファイル名
 |
 |		SHORT	返値		インデックスファイル番号
 |
 =======================================================================*/
SHORT	PSENTRY PSDBIndex(PFCB pFCB, CHAR *fileName)
{
	PCCB	pCCB;
	SHORT	indexNo = 0;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBIndex(pFCB->pDB, fileName, &indexNo);
	}
ret:
	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return indexNo;
}

/*=======================================================================
 |
 |		インデックスファイル作成
 |
 |	SHORT	PSDBIdxCreate(pFCB, fileName, key, uniq)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*fileName;	インデックスファイル名
 |		CHAR	*key;		キー
 |		SHORT	uniq;		０：キーの重複を許す　１：許さない
 |
 |		SHORT	返値		インデックスファイル番号
 |
 =======================================================================*/
SHORT	PSENTRY PSDBIdxCreate(PFCB pFCB, CHAR *fileName, CHAR *key, SHORT uniq)
{
	PCCB	pCCB;
	SHORT	indexNo = 0;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBIdxCreate(pFCB->pDB, fileName, key, uniq, &indexNo);
	}
ret:
	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return indexNo;
}

/*=======================================================================
 |
 |		マスターインデックス切り替え
 |
 |	VOID	PSDBChgIdx(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 =======================================================================*/
VOID	PSENTRY PSDBChgIdx(PFCB pFCB, SHORT n)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBChgIdx(pFCB->pDB, n);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		インデックスファイルによる検索（完全一致，前方一致）
 |
 |	VOID	PSDBSearch(pFCB, key, len)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*key;		検索する文字列
 |		SHORT	len;		検索する文字列の長さ
 |
 =======================================================================*/
VOID	PSENTRY PSDBSearch(PFCB pFCB, CHAR *key, SHORT len)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBSearch(pFCB->pDB, key, len);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		インデックスファイルによる検索（範囲指定対応）
 |
 |	SHORT	PSDBSearch2(pFCB, key, len)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*key;		検索する文字列
 |		SHORT	len;		検索する文字列の長さ
 |
 |		SHORT	返値		検索結果
 |					０：該当レコード無し
 |					１：一致するレコードが見つかった
 |					２：一致するレコードは見つからなかった
 |
 =======================================================================*/
SHORT	PSENTRY PSDBSearch2(PFCB pFCB, CHAR *key, SHORT len)
{
	PCCB	pCCB;
	SHORT	find;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBSearch2(pFCB->pDB, key, len, &find);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return find;
}

/*=======================================================================
 |
 |		インデックスファイルによる検索（ロック付き）
 |
 |	LONG	PSDBSearchLock(pFCB, key, len)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*key;		検索する文字列
 |		SHORT	len;		検索する文字列の長さ
 |
 |		LONG	返値		検索されたレコード数
 |
 =======================================================================*/
LONG	PSENTRY PSDBSearchLock(PFCB pFCB, CHAR *key, SHORT len)
{
	PCCB	pCCB;
	LONG	count;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBSearchLock(pFCB->pDB, key, len, &count);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return count;
}

/*=======================================================================
 |
 |		キーに一致するレコード数の取得
 |
 |	LONG	PSDBCount(pFCB, key, len)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*key;		検索する文字列
 |		SHORT	len;		検索する文字列の長さ
 |
 |		LONG	返値		キーに一致したレコード数
 |
 =======================================================================*/
LONG	PSENTRY PSDBCount(PFCB pFCB, CHAR *key, SHORT len)
{
	PCCB	pCCB;
	LONG	nRec;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBCount(pFCB->pDB, key, len, &nRec);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return nRec;
}

/*=======================================================================
 |
 |		レコード追加
 |
 |	VOID	PSDBStore(pFCB, rec)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*rec;		追加するレコードデータへのポインタ
 |
 =======================================================================*/
VOID	PSENTRY PSDBStore(PFCB pFCB, CHAR *rec)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBStore(pFCB->pDB, rec);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		レコード追加（重複無し）
 |
 |	VOID	PSDBStoreUniq(pFCB, rec)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*rec;		追加するレコードデータへのポインタ
 |
 =======================================================================*/
VOID	PSENTRY PSDBStoreUniq(PFCB pFCB, CHAR *rec)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBStoreUniq(pFCB->pDB, rec);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		レコード更新
 |
 |	VOID	PSDBUpdate(pFCB, rec)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*rec;		更新するレコードデータへのポインタ
 |
 =======================================================================*/
VOID	PSENTRY PSDBUpdate(PFCB pFCB, CHAR *rec)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBUpdate(pFCB->pDB, rec);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		キー指定によるレコード更新
 |
 |	VOID	PSDBUpdateKey(pFCB, key, len, buf)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*key;		キー
 |		SHORT	len;		キー長
 |		CHAR	*buf;		レコードバッファ
 |
 =======================================================================*/
VOID	PSENTRY PSDBUpdateKey(PFCB pFCB, CHAR *key, SHORT len,
							CHAR *buf)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBUpdateKey(pFCB->pDB, key, len, buf);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		レコード削除
 |
 |	VOID	PSDBDelete(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 =======================================================================*/
VOID	PSENTRY PSDBDelete(PFCB pFCB)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBDelete(pFCB->pDB);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		レコード復元
 |
 |	VOID	PSDBRecall(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 =======================================================================*/
VOID	PSENTRY PSDBRecall(PFCB pFCB)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBRecall(pFCB->pDB);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		レコードの物理的削除
 |
 |	VOID	PSDBDelete2(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 =======================================================================*/
VOID	PSENTRY PSDBDelete2(PFCB pFCB)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBDelete2(pFCB->pDB);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		レコードの物理的削除（カレントレコードポインタ保存あり）
 |
 |	VOID	PSDBDelete3(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 =======================================================================*/
VOID	PSENTRY PSDBDelete3(PFCB pFCB)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBDelete3(pFCB->pDB);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		キー指定によるレコードの物理的削除
 |
 |	VOID	PSDBDeleteKey(pFCB, key, len, flag)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*key;		削除するキー
 |		SHORT	len;		キーの長さ
 |		SHORT	flag;		０：重複キーはエラー
 |					１：重複キーも削除
 |
 =======================================================================*/
VOID	PSENTRY PSDBDeleteKey(PFCB pFCB, CHAR *key, SHORT len, SHORT flag)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBDeleteKey(pFCB->pDB, key, len, flag);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		レコードポインタを先頭レコードにセット
 |
 |	VOID	PSDBTop(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 =======================================================================*/
VOID	PSENTRY PSDBTop(PFCB pFCB)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBTop(pFCB->pDB);
	}

	pFCB->readBufRecord = 0;

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		レコードポインタを最終レコードにセット
 |
 |	VOID	PSDBBottom(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 =======================================================================*/
VOID	PSENTRY PSDBBottom(PFCB pFCB)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBBottom(pFCB->pDB);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		レコードポインタを指定されたレコードにセット
 |
 |	VOID	PSDBSet(pFCB, recNo)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		LONG	recNo;		レコード番号
 |
 =======================================================================*/
VOID	PSENTRY PSDBSet(PFCB pFCB, LONG recNo)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBSet(pFCB->pDB, recNo);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		レコードポインタの前後移動
 |
 |	VOID	PSDBSkip(pFCB, n)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		LONG	n;		移動レコード数
 |
 =======================================================================*/
VOID	PSENTRY PSDBSkip(PFCB pFCB, LONG n)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBSkip(pFCB->pDB, n);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		インデックスファイル再構築
 |
 |	VOID	PSDBReindex(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 =======================================================================*/
VOID	PSENTRY PSDBReindex(PFCB pFCB)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBReindex(pFCB->pDB);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		削除レコードをファイル上から削除
 |
 |	VOID	PSDBPack(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 =======================================================================*/
VOID	PSENTRY PSDBPack(PFCB pFCB)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBPack(pFCB->pDB);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		カレントレコード読み込み
 |
 |	VOID	PSDBRead(pFCB, pBuf)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*pBuf;		レコード読み込みバッファポインタ
 |
 =======================================================================*/
VOID	PSENTRY PSDBRead(PFCB pFCB, CHAR *pBuf)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBRead(pFCB->pDB, pBuf);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		複数次レコードレコード読み込み
 |
 |	SHORT	PSDBReadNext(pFCB, nRec, pBuf)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		SHORT	nRec;		レコード数
 |		CHAR	*pBuf;		レコード読み込みバッファポインタ
 |
 |		SHORT	返値		実際に読んだレコード数
 |
 =======================================================================*/
SHORT	PSENTRY PSDBReadNext(PFCB pFCB, SHORT nRec, CHAR *pBuf)
{
	PCCB	pCCB;
	SHORT	readRec;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBReadNext(pFCB->pDB, nRec, pBuf, &readRec);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return readRec;
}

/*=======================================================================
 |
 |		複数前レコードレコード読み込み
 |
 |	SHORT	PSDBReadBack(pFCB, nRec, pBuf)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		SHORT	nRec;		レコード数
 |		CHAR	*pBuf;		レコード読み込みバッファポインタ
 |
 |		SHORT	返値		実際に読んだレコード数
 |
 =======================================================================*/
SHORT	PSENTRY PSDBReadBack(PFCB pFCB, SHORT nRec, CHAR *pBuf)
{
	PCCB	pCCB;
	SHORT	readRec;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBReadBack(pFCB->pDB, nRec, pBuf, &readRec);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return readRec;
}

/*=======================================================================
 |
 |		キー指定によるレコード読み込み
 |
 |	SHORT	PSDBReadKey(pFCB, key, len, buf, lock)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*key;		キー
 |		SHORT	len;		キー長
 |		CHAR	*buf;		レコードバッファ
 |		SHORT	lock;		０：レコードロックなし　１：あり
 |
 |		SHORT	返値		０：該当レコードなし　１：あり
 |
 =======================================================================*/
SHORT	PSENTRY PSDBReadKey(PFCB pFCB, CHAR *key, SHORT len, CHAR *buf,
								SHORT lock)
{
	PCCB	pCCB;
	SHORT	flag;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBReadKey(pFCB->pDB, key, len, buf, lock, &flag);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return flag;
}

/*=======================================================================
 |
 |		レコードバッファクリア
 |
 |	VOID	PSDBClrRecord(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 =======================================================================*/
VOID	PSENTRY PSDBClrRecord(PFCB pFCB)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBClrRecord(pFCB->pDB);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		レコードバッファ読み込み
 |
 |	VOID	PSDBGetRecord(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 =======================================================================*/
VOID	PSENTRY PSDBGetRecord(PFCB pFCB)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBGetRecord(pFCB->pDB);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		フィールドデータ読み込み
 |
 |	SHORT	PSDBGetField(pFCB, field, pBuf)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*field;		フィールド名
 |		VOID	*pBuf;		フィールドバッファ
 |
 |		SHORT	返値		フィールドの型
 |
 =======================================================================*/
SHORT	PSENTRY PSDBGetField(PFCB pFCB, CHAR *field, VOID *pBuf)
{
	PCCB	pCCB;
	SHORT	fieldType = 0;
	SHORT	dataSize;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBGetField(pFCB->pDB, field, pBuf, &fieldType,
								&dataSize);
	}
ret:
	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return fieldType;
}

/*=======================================================================
 |
 |		フィールドデータ書き込み
 |
 |	VOID	PSDBSetField(pFCB, field, pBuf)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*field;		フィールド名
 |		VOID	*pBuf;		フィールドバッファ
 |
 =======================================================================*/
VOID	PSENTRY PSDBSetField(PFCB pFCB, CHAR *field, VOID *pBuf)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBSetField(pFCB->pDB, field, pBuf);
	}
ret:
	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		レコード追加
 |
 |	VOID	PSDBAddRecord(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 =======================================================================*/
VOID	PSENTRY PSDBAddRecord(PFCB pFCB)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBAddRecord(pFCB->pDB);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		レコード更新
 |
 |	VOID	PSDBUpdRecord(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 =======================================================================*/
VOID	PSENTRY PSDBUpdRecord(PFCB pFCB)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBUpdRecord(pFCB->pDB);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		データファイルのコピー
 |
 |	VOID	PSDBCopy(pFCB1, pFCB2)
 |
 |		PFCB	pFCB1;		コピー元ファイル制御ブロックポインタ
 |		PFCB	pFCB2;		コピー先ファイル制御ブロックポインタ
 |
 =======================================================================*/
VOID	PSENTRY PSDBCopy(PFCB pFCB1, PFCB pFCB2)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB1->pCCB;

	{
		err = DBCopy(pFCB1->pDB, pFCB2->pDB);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB1->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB1, err);
	}
}

/*=======================================================================
 |
 |		削除レコードチェック
 |
 |	SHORT	PSDBCheckDeleted(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 |		SHORT	返値		０：通常レコード　１：削除レコード
 |
 =======================================================================*/
SHORT	PSENTRY PSDBCheckDeleted(PFCB pFCB)
{
	PCCB	pCCB;
	SHORT	flag;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBCheckDeleted(pFCB->pDB, &flag);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return flag;
}

/*=======================================================================
 |
 |		フィルタ設定
 |
 |	VOID	PSDBSetFilter(pFCB, filter)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*filter;	フィルタ条件式
 |
 =======================================================================*/
VOID	PSENTRY PSDBSetFilter(PFCB pFCB, CHAR *filter)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBSetFilter(pFCB->pDB, filter);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		選択条件設定
 |
 |	LONG	PSDBSelect(pFCB, select)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*select;	選択条件式
 |
 |		LONG	返値		選択レコード数
 |
 =======================================================================*/
LONG	PSENTRY PSDBSelect(PFCB pFCB, CHAR *select)
{
	PCCB	pCCB;
	LONG	nRec = 0;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBSelect(pFCB->pDB, select, &nRec);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return nRec;
}

/*=======================================================================
 |
 |		削除レコード有効／無効の設定
 |
 |	VOID	PSDBSetDeleted(pFCB, flag)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		SHORT	flag;		０：削除レコード有効
 |					１：削除レコード無効
 |
 =======================================================================*/
VOID	PSENTRY PSDBSetDeleted(PFCB pFCB, SHORT flag)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBSetDeleted(pFCB->pDB, flag);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		カレントレコードの論理レコード番号取り出し
 |
 |	LONG	PSDBLRecNo(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 |		LONG	返値		論理レコード番号
 |
 =======================================================================*/
LONG	PSENTRY PSDBLRecNo(PFCB pFCB)
{
	PCCB	pCCB;
	LONG	recNo;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBLRecNo(pFCB->pDB, &recNo);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return recNo;
}

/*=======================================================================
 |
 |		論理レコード数取り出し
 |
 |	LONG	PSDBLRecCount(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 |		LONG	返値		論理レコード数
 |
 =======================================================================*/
LONG	PSENTRY PSDBLRecCount(PFCB pFCB)
{
	PCCB	pCCB;
	LONG	nRec;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBLRecCount(pFCB->pDB, &nRec);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return nRec;
}

/*=======================================================================
 |
 |		論理レコード番号によるカレントレコードの設定
 |
 |	VOID	PSDBLSet(pFCB, lRecNo)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		LONG	lRecNo;		論理レコード番号
 |
 =======================================================================*/
VOID	PSENTRY PSDBLSet(PFCB pFCB, LONG lRecNo)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBLSet(pFCB->pDB, lRecNo);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		全レコード削除
 |
 |	VOID	PSDBZip(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 =======================================================================*/
VOID	PSENTRY PSDBZip(PFCB pFCB)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBZip(pFCB->pDB);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		更新チェック
 |
 |	SHORT	PSDBCheckUpdate(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 |		SHORT	返値		０：更新なし　１：更新あり
 |
 =======================================================================*/
SHORT	PSENTRY PSDBCheckUpdate(PFCB pFCB)
{
	PCCB	pCCB;
	SHORT	updateFlag;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBCheckUpdate(pFCB->pDB, &updateFlag);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return updateFlag;
}

/*=======================================================================
 |
 |		ファイル／レコードロック
 |
 |	VOID	PSDBLock(pFCB, lock)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		SHORT	lock;		０：ファイルロック　１：レコードロック
 |
 =======================================================================*/
VOID	PSENTRY PSDBLock(PFCB pFCB, SHORT lock)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBLock(pFCB->pDB, lock);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		ファイル／レコードロック解除
 |
 |	VOID	PSDBUnlock(pFCB, lock)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		SHORT	lock;		０：ファイルロック　１：レコードロック
 |
 =======================================================================*/
VOID	PSENTRY PSDBUnlock(PFCB pFCB, SHORT lock)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBUnlock(pFCB->pDB, lock);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		レコード数取り出し
 |
 |	LONG	PSDBRecCount(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 |		LONG	返値		レコード数
 |
 =======================================================================*/
LONG	PSENTRY PSDBRecCount(PFCB pFCB)
{
	PCCB	pCCB;
	LONG	nRec;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBRecCount(pFCB->pDB, &nRec);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return nRec;
}

/*=======================================================================
 |
 |		ＢＯＦチェック
 |
 |	SHORT	PSDBBof(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 |		SHORT	返値		０：ＢＯＦでない　１：ＢＯＦ
 |
 =======================================================================*/
SHORT	PSENTRY PSDBBof(PFCB pFCB)
{
	PCCB	pCCB;
	SHORT	bof;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBBof(pFCB->pDB, &bof);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return bof;
}

/*=======================================================================
 |
 |		データファイル名取り出し
 |
 |	VOID	PSDBDbf(pFCB, fileName)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*fileName;	データファイル名
 |
 =======================================================================*/
VOID	PSENTRY PSDBDbf(PFCB pFCB, CHAR *fileName)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBDbf(pFCB->pDB, fileName);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		ＥＯＦチェック
 |
 |	SHORT	PSDBEof(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 |		SHORT	返値		０：ＥＯＦでない　１：ＥＯＦ
 |
 =======================================================================*/
SHORT	PSENTRY PSDBEof(PFCB pFCB)
{
	PCCB	pCCB;
	SHORT	eof;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBEof(pFCB->pDB, &eof);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return eof;
}

/*=======================================================================
 |
 |		フィールド数取得
 |
 |	SHORT	PSDBNField(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 |		SHORT	返値		フィールド数
 |
 =======================================================================*/
SHORT	PSENTRY PSDBNField(PFCB pFCB)
{
	PCCB	pCCB;
	SHORT	nField;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBNField(pFCB->pDB, &nField);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return nField;
}

/*=======================================================================
 |
 |		フィールド情報取り出し
 |
 |	VOID	PSDBField(pFCB, n, dip)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		SHORT	n;		フィールド番号
 |		PDBF_I	dip;		フィールド情報
 |
 =======================================================================*/
VOID	PSENTRY PSDBField(PFCB pFCB, SHORT n, PDBF_I dip)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBField(pFCB->pDB, n, dip);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		インデックスファイル名取り出し
 |
 |	VOID	PSDBNdx(pFCB, n, fileName)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		SHORT	n;		インデックスファイル番号
 |		CHAR	*fileName;	インデックスファイル名へ
 |
 =======================================================================*/
VOID	PSENTRY PSDBNdx(PFCB pFCB, SHORT n, CHAR *fileName)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBNdx(pFCB->pDB, n, fileName);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		カレントレコード番号取り出し
 |
 |	LONG	PSDBRecNo(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 |		LONG	返値		カレントレコード番号
 |
 =======================================================================*/
LONG	PSENTRY PSDBRecNo(PFCB pFCB)
{
	PCCB	pCCB;
	LONG	recNo;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBRecNo(pFCB->pDB, &recNo);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return recNo;
}

/*=======================================================================
 |
 |		レコード長取り出し
 |
 |	SHORT	PSDBRecSize(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 |		SHORT	返値		レコード長
 |
 =======================================================================*/
SHORT	PSENTRY PSDBRecSize(PFCB pFCB)
{
	PCCB	pCCB;
	SHORT	recSize;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBRecSize(pFCB->pDB, &recSize);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return recSize;
}

/*=======================================================================
 |
 |		最新エラーコード取得
 |
 |	SHORT	PSDBGetErrCode(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 |		SHORT	返値		エラーコード
 |
 =======================================================================*/
SHORT	PSENTRY PSDBGetErrCode(PFCB pFCB)
{
	SHORT	err;

	err = pFCB->errorCode;
	pFCB->errorCode = 0;

	return err;
}

/*=======================================================================
 |
 |		エラーハンドラ設定
 |
 |	VOID	PSDBSetErrHandler(pFCB, func)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		VOID (*func)(PFCB, SHORT) エラーハンドラ関数
 |
 =======================================================================*/
VOID	PSENTRY PSDBSetErrHandler(PCCB pCCB, VOID (*func)(PFCB, SHORT))
{
	pCCB->pErrHandler = func;
}

VOID	PSENTRY	PSDBAsync(PCCB pCCB)
{
	pCCB->async = TRUE;
}

/*=======================================================================
 |
 |		Visual Basic 用レコード読み込み
 |
 |	SHORT	PSDBReadVB(pFCB, topIndex, nRec, hAD)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		SHORT	topIndex;	先頭添字
 |		SHORT	nRec;		読み込みレコード数
 |		VOID	*hAD;		配列のハンドル
 |
 |		SHORT	返値		実際に読み込みだレコード数
 |
 =======================================================================*/
SHORT	PSENTRY PSDBReadVB(PFCB pFCB, SHORT topIndex, SHORT nRec, VOID *hAD)
{
#if defined OS_WINDOWS
#define	BUFSIZE	(1024*32U)
extern	LPVOID FAR PASCAL VBArrayElement(VOID *, SHORT, SHORT *);
	PCCB	pCCB;
	struct	PRM_DB_READNEXT	*pParam;
	CHAR	*buf;
	SHORT	nRead, n, readRec;
	LPVOID	lpData;
	SHORT	indexes[1];
	int	i;
	SHORT	err = 0;

	pCCB = pFCB->pCCB;

	readRec = 0;

	if ((buf = malloc(BUFSIZE)) == NULL) {
		err = ERROR_CLIENT_MEMORY;
		goto err;
	}

	indexes[0] = topIndex;
	for (;;) {
		nRead = min((USHORT)(nRec - readRec),
				(USHORT)BUFSIZE / pFCB->readSize);

		{
			err = DBReadNext(pFCB->pDB, nRead, buf, &n);
		} else {
			pParam = (struct PRM_DB_READNEXT *)pCCB->command.param;
			pParam->handle = pFCB->fileHandle;
			pParam->nRec = nRead;
			pCCB->pOutData = buf;
			err = SendCommand(pCCB, FC_DB_READNEXT,
					sizeof(struct PRM_DB_READNEXT), 0);

			n = pCCB->response.ret.sValue;
		}

		if (err != 0)
			break;

		for (i = 0; i < n; i++) {
			lpData = VBArrayElement(hAD, 1, indexes);
			if (HIWORD(lpData) == 0) {
				err = ERROR_DB_PARAMETER;
				break;
			}
			_fmemcpy(lpData, &buf[i * (USHORT)pFCB->readSize],
							pFCB->readSize);
			indexes[0]++;
		}

		readRec += n;

		if (err != 0 || n != nRead || readRec == nRec)
			break;
	}

	free(buf);
err:
	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return readRec;
#elif defined OS_WNT
/*
#define	BUFSIZE	(1024*32U)
	PCCB	pCCB;
	struct	PRM_DB_READNEXT	*pParam;
	SAFEARRAY *psa;
	CHAR	*buf;
	USHORT	*wbuf;
	SHORT	nRead, n, readRec;
	int	i;
	int	elementSize;
	int	indexes[1];
	SHORT	err;

	pCCB = pFCB->pCCB;
	psa = *(SAFEARRAY **)hAD;

	readRec = 0;

	if ((buf = malloc(BUFSIZE)) == NULL) {
		err = ERROR_CLIENT_MEMORY;
		goto err;
	}

	elementSize = SafeArrayGetElemsize(psa);
	if ((wbuf = malloc(elementSize)) == NULL) {
		free(buf);
		err = ERROR_CLIENT_MEMORY;
		goto err;
	}

	indexes[0] = topIndex;
	for (;;) {
		nRead = min((USHORT)(nRec - readRec),
				(USHORT)BUFSIZE / pFCB->readSize);

		{
			err = DBReadNext(pFCB->pDB, nRead, buf, &n);
		} else {
			pParam = (struct PRM_DB_READNEXT *)pCCB->command.param;
			pParam->handle = pFCB->fileHandle;
			pParam->nRec = nRead;
			pCCB->pOutData = buf;
			err = SendCommand(pCCB, FC_DB_READNEXT,
					sizeof(struct PRM_DB_READNEXT), 0);

			n = pCCB->response.ret.sValue;
		}

		if (err != 0)
			break;

		for (i = 0; i < n; i++) {
			MultiByteToWideChar(CP_ACP, 0,
				(LPCSTR)&buf[i * (USHORT)pFCB->readSize],
					pFCB->readSize, (LPWSTR)wbuf,
					elementSize);
			SafeArrayPutElement(psa, indexes, wbuf);
			indexes[0]++;
		}

		readRec += n;

		if (err != 0 || n != nRead || readRec == nRec)
			break;
	}

	free(wbuf);
	free(buf);
err:
	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return readRec;
*/
#define	BUFSIZE	(1024*32U)
	PCCB	pCCB;
	struct	PRM_DB_READNEXT	*pParam;
	SAFEARRAY *psa;
	CHAR	*buf;
	SHORT	nRead, n, readRec;
	int	i;
	int	indexes[1];
	SHORT	err;

	pCCB = pFCB->pCCB;
	psa = *(SAFEARRAY **)hAD;

	readRec = 0;

	if ((buf = malloc(BUFSIZE)) == NULL) {
		err = ERROR_CLIENT_MEMORY;
		goto err;
	}

	indexes[0] = topIndex;
	for (;;) {
		nRead = min((USHORT)(nRec - readRec),
				(USHORT)BUFSIZE / pFCB->readSize);

		{
			err = DBReadNext(pFCB->pDB, nRead, buf, &n);
		} else {
			pParam = (struct PRM_DB_READNEXT *)pCCB->command.param;
			pParam->handle = pFCB->fileHandle;
			pParam->nRec = nRead;
			pCCB->pOutData = buf;
			err = SendCommand(pCCB, FC_DB_READNEXT,
					sizeof(struct PRM_DB_READNEXT), 0);

			n = pCCB->response.ret.sValue;
		}

		if (err != 0)
			break;

		for (i = 0; i < n; i++) {
			SafeArrayPutElement(psa, indexes,
					&buf[i * (USHORT)pFCB->readSize]);
			indexes[0]++;
		}

		readRec += n;

		if (err != 0 || n != nRead || readRec == nRec)
			break;
	}

	free(buf);
err:
	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return readRec;
#else
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;
	err = ERROR_DB_NOSUPPORT;
	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return 0;
#endif
}

/*=======================================================================
 |
 |		読み込みフィールド設定
 |
 |	SHORT	PSDBSetReadField(pFCB, readField)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*readField;	読み込みフィールド名
 |
 |		SHORT	返値		データ長
 |
 =======================================================================*/
SHORT	PSENTRY PSDBSetReadField(PFCB pFCB, CHAR *readField)
{
	PCCB	pCCB;
	SHORT	length;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBSetReadField(pFCB->pDB, readField, &length);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	pFCB->readSize = length;

	return length;
}

/*=======================================================================
 |
 |		暗号化キー設定
 |
 |	VOID	PSDBSetScramble(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |
 =======================================================================*/
VOID	PSENTRY PSDBSetScramble(PFCB pFCB)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBSetScramble(pFCB->pDB);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		パスワード設定
 |
 |	VOID	PSDBSetPassword(pFCB)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*password;	パスワード
 |
 =======================================================================*/
VOID	PSENTRY PSDBSetPassword(PFCB pFCB, CHAR *password)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBSetPassword(pFCB->pDB, password);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		ORACLE 用フィールド更新
 |
 |	VOID	PSDBUpdateOracle(pFCB, key, buf)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*key;		キー
 |		CHAR	*buf;		フィールドデータ
 |
 =======================================================================*/
VOID	PSENTRY PSDBUpdateOracle(PFCB pFCB, CHAR *key, CHAR *buf)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = ERROR_CLIENT_NOSUPPORT;
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		ORACLE 用レコード削除
 |
 |	VOID	PSDBDeleteOracle(pFCB, key)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*key;		キー
 |
 =======================================================================*/
VOID	PSENTRY PSDBDeleteOracle(PFCB pFCB, CHAR *key)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = ERROR_CLIENT_NOSUPPORT;
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		全レコードレコード読み込み
 |
 |	SHORT	PSDBReadAll(pFCB, pBuf)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*pBuf;		レコード読み込みバッファポインタ
 |
 |		SHORT	返値		1:読み込んだ　0:EOFまたはエラー
 |
 =======================================================================*/
SHORT	PSENTRY PSDBReadAll(PFCB pFCB, CHAR *pBuf)
{
	PCCB	pCCB;
	SHORT	rc = 0;
	SHORT	err = 0;

	pCCB = pFCB->pCCB;

	if (pFCB->pReadBuffer == NULL) {
		if ((pFCB->pReadBuffer = malloc(READ_BUFFER_SIZE)) == NULL) {
			err = ERROR_CLIENT_MEMORY;
			goto ret;
		}
		pFCB->readBufRecord = 0;
		pFCB->readBufCounter = 0;
	}

	if (pFCB->readBufRecord == pFCB->readBufCounter) {
		pFCB->readBufRecord = (USHORT)PSDBReadNext(pFCB,
				(SHORT)(READ_BUFFER_SIZE / pFCB->readSize),
				pFCB->pReadBuffer);
		pFCB->readBufCounter = 0;
	}

	if (pFCB->readBufRecord == 0)
		rc = 0;
	else {
#if defined (OS_WINDOWS)
		hmemcpy(pBuf, pFCB->pReadBuffer +
				(pFCB->readBufCounter++ * pFCB->readSize),
				pFCB->readSize);
#else
		memcpy(pBuf, pFCB->pReadBuffer +
				(pFCB->readBufCounter++ * pFCB->readSize),
				pFCB->readSize);
#endif
		rc = 1;
	}

ret:
	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return rc;
}

/*=======================================================================
 |
 |		インデックスパック
 |
 |	VOID	PSDBPackIndex(pCCB, fileName)
 |
 |		PCCB	pCCB;		クライアント制御ブロックポインタ
 |		CHAR	*fileName;	インデックスファイル名
 |
 |		SHORT	返値		エラーコード
 |
 =======================================================================*/
VOID	PSENTRY PSDBPackIndex(PCCB pCCB, CHAR *fileName)
{
	SHORT	err;

	{
		err = DBPackIndex(fileName);
	}

	if (err != 0) {
		pCCB->errorCode = err;
	}
}

/*=======================================================================
 |
 |		バイナリデータ読み込み
 |
 |	LONG	PSDBReadBinary(pFCB, fieldName, pBuf, bufSize)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*fieldName;	フィールド名
 |		CHAR	*pBuf;		読み込みバッファ
 |		LONG	bufSize;	読み込みバッファサイズ
 |
 |		LONG	返値		読み込んだバイト数
 |
 =======================================================================*/
LONG	PSENTRY	PSDBReadBinary(PFCB pFCB, CHAR *fieldName, CHAR *pBuf,
								LONG bufSize)
{
	PCCB	pCCB;
	LONG	readSize;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBReadBinary(pFCB->pDB, fieldName, pBuf, bufSize,
								&readSize);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return readSize;
}

/*=======================================================================
 |
 |		バイナリデータ書き込み
 |
 |	VOID	PSDBWriteBinary(pFCB, fieldName, pBuf, bufSize)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*fieldName;	フィールド名
 |		CHAR	*pBuf;		書き込みデータ
 |		LONG	bufSize;	書き込みデータサイズ
 |
 =======================================================================*/
VOID	PSENTRY	PSDBWriteBinary(PFCB pFCB, CHAR *fieldName, CHAR *pBuf,
								LONG dataSize)
{
	PCCB	pCCB;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBWriteBinary(pFCB->pDB, fieldName, pBuf, dataSize);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}
}

/*=======================================================================
 |
 |		バイナリデータサイズ取得
 |
 |	LONG	PSDBGetBinarySize(pFCB, fieldName)
 |
 |		PFCB	pFCB;		ファイル制御ブロックポインタ
 |		CHAR	*fieldName;	フィールド名
 |
 |		LONG	返値		バイナリデータサイズ
 |
 =======================================================================*/
LONG	PSENTRY	PSDBGetBinarySize(PFCB pFCB, CHAR *fieldName)
{
	PCCB	pCCB;
	LONG	dataSize;
	SHORT	err;

	pCCB = pFCB->pCCB;

	{
		err = DBGetBinarySize(pFCB->pDB, fieldName, &dataSize);
	}

	if (err != 0) {
		pCCB->errorCode = err;
		pFCB->errorCode = err;
		if (pCCB->pErrHandler != NULL)
			(*pCCB->pErrHandler)(pFCB, err);
	}

	return dataSize;
}
