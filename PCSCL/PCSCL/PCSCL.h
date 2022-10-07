#import "CString.h"

extern "C" {
//#ifndef OS_WNT
//#define	OS_WNT
//#endif
#import "PCSAPI.h"
}

#ifndef NULL
#define NULL	0
#endif

typedef const char *LPCTSTR;
typedef int *LPINT;
typedef int *LPLONG;
typedef void *LPVOID;
typedef const void *LPCVOID;
typedef PSBOOL *LPBOOL;
typedef char *LPSTR;

class CPcserve {
public:
	CPcserve();
	~CPcserve();

	PCCB GetCCB();
	int Connect(int nChType, LPCTSTR lpszServerName, LPCTSTR lpszClientID);
	int Disconnect();
	int PackIndex(LPCTSTR lpFileName);
	//static LPCTSTR GetErrorText(int err);

protected:
	PCCB m_pCCB;

	friend class CPSDB;
};

class CPSDB {
public:
	CPSDB();
	~CPSDB();

	struct RECFORMAT {
		int nFieldType;
		int nFieldLength;
	};

	PFCB GetFCB();
	int DBOpen(CPcserve &pcserve, LPCTSTR lpFileName);
	int DBCreate(CPcserve &pcserve, LPCTSTR lpFileName, PDBF_I lpDBFI, int nField);
	int DBClose();
	int DBFlush();
	int DBIndex(LPCTSTR lpFileName, LPINT lpIdxNo);
	int DBIdxCreate(LPCTSTR lpFileName, LPCTSTR lpKey, PSBOOL bUniq, LPINT lpIdxNo);
	int DBChgIdx(int nIdxNo);
	int DBSearch(LPCTSTR lpKey, int nKeyLength);
	int DBSearch2(LPCTSTR lpKey, int nKeyLength, LPINT lpFind);
	int DBSearchLock(LPCTSTR lpKey, int nKeyLength, LPLONG lpRecNum);
	int DBCount(LPCTSTR lpKey, int nKeyLength, LPLONG lpRecNum);
	int DBStore(LPVOID lpRec);
	int DBStoreUniq(LPVOID lpRec);
	int DBUpdate(LPVOID lpRec);
	int DBUpdateKey(LPCTSTR lpKey, int nKeyLength, LPVOID lpBuf);
	int DBDelete();
	int DBRecall();
	int DBDelete2();
	int DBDelete3();
	int DBDeleteKey(LPCTSTR lpKey, int nKeyLength, int nFlag);
	int DBTop();
	int DBBottom();
	int DBSet(int nRecNo);
	int DBSkip(int nRecNum);
	int DBReindex();
	int DBPack();
	int DBRead(LPVOID lpBuf);
	int DBReadNext(int nRec, LPVOID lpBuf, LPINT lpReadRec);
	int DBReadBack(int nRec, LPVOID lpBuf, LPINT lpReadRec);
	int DBReadKey(LPCTSTR lpKey, int nKeyLength, LPVOID lpBuf, int nLock, LPINT lpFind);
	int DBClrRecord();
	int DBGetRecord();
	int DBGetField(LPCTSTR lpFieldName, LPVOID lpBuf, LPINT lpFieldType);
	int DBSetField(LPCTSTR lpFieldName, LPVOID lpBuf);
	int DBAddRecord();
	int DBUpdRecord();
	int DBCheckDeleted(LPINT lpDeleted);
	int DBSetFilter(LPCTSTR lpFilter);
	int DBSelect(LPCTSTR lpSelect, LPLONG lpRecNum);
	int DBSetDeleted(int nFlag);
	int DBLRecNo(LPLONG lpRecNo);
	int DBLRecCount(LPLONG lpRecNum);
	int DBLSet(int nRecNo);
	int DBZip();
	int DBCheckUpdate(LPBOOL lpUpdateFlag);
	int DBLock(int nLock);
	int DBUnlock(int nLock);
	int DBRecCount(LPLONG lpRecNum);
	int DBBof(LPBOOL lpBofFlag);
	int DBDbf(LPSTR lpFileName);
	int DBEof(LPBOOL lpEofFlag);
	int DBNField(LPINT lpFieldNum);
	int DBField(int nFieldNo, PDBF_I lpDBFI);
	int DBNdx(int nIdxNo, LPSTR lpFileName);
	int DBRecNo(LPLONG lpRecNo);
	int DBRecSize(LPINT lpRecSize);
	int DBSetReadField(LPCTSTR lpReadField, LPINT lpDataSize);
	int DBSetScramble();
	int DBSetPassword(LPCTSTR lpPassword);
	int DBReadAll(LPVOID lpBuf, LPBOOL lpReadFlag);
	int DBReadBinary(LPCTSTR lpFieldName, LPVOID lpBuf, int nBufSize, LPLONG lpReadNum);
	int DBWriteBinary(LPCTSTR lpFieldName, LPCVOID lpBuf, int nDataSize);
	int DBGetBinarySize(LPCTSTR lpFieldName, LPLONG lpDataSize);
	int DBGetFieldBuf(LPVOID lpRecBuf, LPVOID lpFieldBuf);
	int DBSetFieldBuf(LPVOID lpRecBuf, LPVOID lpFieldBuf);
	int DBCopy(CPSDB &dbSrc);

protected:
	PFCB m_pFCB;
	PCCB m_pCCB;

private:
	int GetFieldInf();

	PDBF_I m_lpFieldInf;
	int m_nField;
	CString m_ReadField;
};
