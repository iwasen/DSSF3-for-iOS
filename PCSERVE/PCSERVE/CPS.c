/************************************************************************
 *
 *			ＰＣ−ＳＥＲＶＥ
 *
 *		名称		: クライアント側接続／切断処理
 *		ファイル名	: cps.c
 *		作成者		: s.aizawa
 *
 ************************************************************************/

#include "PCSOS.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "PCSCLNT.h"

/*=======================================================================
 |
 |		接続コマンド処理
 |
 |	PCCB	PSConnect(chType, hostName, clientID, err)
 |
 |		SHORT	chType;		チャネル種別
 |		CHAR	*hostName;	ホスト名
 |		CHAR	*clientID;	クライアントＩＤ
 |		SHORT	*err;		エラーコード
 |
 |		PCCB	返値		クライアント制御ブロックポインタ
 |
 =======================================================================*/
PCCB	PSENTRY PSConnect(SHORT chType, CHAR *hostName,
						CHAR *clientID, SHORT *err)
{
	PCCB	pCCB;

	if ((pCCB = malloc(sizeof(CCB))) == NULL) {
		*err = ERROR_CLIENT_MEMORY;
		return NULL;
	}
	memset(pCCB, 0, sizeof(CCB));
	pCCB->handle = -1;
	if (hostName != NULL)
		strcpy(pCCB->serverName, hostName);

#ifdef	OS_WNT
	pCCB->hdir = INVALID_HANDLE_VALUE;
#endif

	pCCB->chType = chType;

	*err = 0;
	return pCCB;
}

/*=======================================================================
 |
 |		切断コマンド処理
 |
 |	SHORT	PSDisconnect(pCCB)
 |
 |		PCCB	pCCB;		クライアント制御ブロックポインタ
 |
 |		SHORT	返値		エラーコード
 |
 =======================================================================*/
SHORT	PSENTRY PSDisconnect(PCCB pCCB)
{
	PFCB	pFCB;
	SHORT	async;
	SHORT	err;

	if (pCCB == NULL)
		return 0;

	async = pCCB->async;

	while ((pFCB = pCCB->pFCB) != NULL) {
		PSDBClose(pFCB);
		pCCB->async = async;
	}

#ifdef	OS_WNT
	if (pCCB->hdir != INVALID_HANDLE_VALUE)
		FindClose(pCCB->hdir);
#endif
	err = 0;

	pCCB->id = 0;

	free(pCCB);

	return err;
}

/*=======================================================================
 |
 |		エラーコード取り出しコマンド処理
 |
 |	SHORT	PSGetErrCode(pCCB)
 |
 |		PCCB	pCCB;		クライアント制御ブロックポインタ
 |
 |		SHORT	返値		エラーコード
 |
 =======================================================================*/
SHORT	PSENTRY PSGetErrCode(PCCB pCCB)
{
	SHORT	err;

	err = pCCB->errorCode;
	pCCB->errorCode = 0;

	return err;
}
