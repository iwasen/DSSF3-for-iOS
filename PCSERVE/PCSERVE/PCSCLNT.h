/************************************************************************
 *
 *			ＰＣ−ＳＥＲＶＥ
 *
 *		名称		: クライアント側共通ヘッダ
 *		ファイル名	: pcsclnt.h
 *		作成者		: s.aizawa
 *
 ************************************************************************/

#include "pcsdef.h"
#include "PCSSYS.h"
#include "PCSDB.h"
#include "PCSCOM.h"

#define	ID_CCB	0x7e01
#define	READ_BUFFER_SIZE	64000U

typedef	struct	_FCB {
	USHORT	fileType;
	int	fileHandle;
	PDB	pDB;
	struct	_CCB	*pCCB;
	DBINF	DBInf;
	SHORT	readSize;
	CHAR	*pReadBuffer;
	USHORT	readBufRecord;
	USHORT	readBufCounter;
	SHORT	errorCode;
	struct	_FCB	*chain;
} FCB, *PFCB;

typedef	struct	_CCB {
	USHORT	id;
	USHORT	chType;
	int	handle;
	SHORT	async;
	VOID	*pInData;
	VOID	*pOutData;
	SHORT	errorCode;
	LONG	extSendDataLength;
	LONG	extReceiveDataLength;
	VOID	(*pErrHandler)(PFCB, SHORT);
#if defined OS_MSDOS || defined OS_WINDOWS
	struct	find_t	find;
#elif defined OS_WNT
	HANDLE	hdir;
#endif
	PFCB	pFCB;
	char	serverName[128];
} CCB, *PCCB;

#include "pcsfunc.h"
