#include "PCSCL.h"

CPSDB::CPSDB()
{
	m_pFCB = NULL;
	m_lpFieldInf = NULL;
	m_nField = 0;
}

CPSDB::~CPSDB()
{
	DBClose();
}

PFCB CPSDB::GetFCB()
{
	return m_pFCB;
}

int CPSDB::DBOpen(CPcserve &pcserve, LPCTSTR lpFileName)
{
	if (pcserve.m_pCCB == NULL)
		return ERROR_CLIENT_NOTCONNECT;

	m_pCCB = pcserve.m_pCCB;

	m_pFCB = PSDBOpen(pcserve.m_pCCB, (LPSTR)lpFileName);
	return PSGetErrCode(pcserve.m_pCCB);
}

int CPSDB::DBCreate(CPcserve &pcserve, LPCTSTR lpFileName, PDBF_I lpDBFI, int nField)
{
	if (pcserve.m_pCCB == NULL)
		return ERROR_CLIENT_NOTCONNECT;

	m_pCCB = pcserve.m_pCCB;

	m_pFCB = PSDBCreate(pcserve.m_pCCB, (LPSTR)lpFileName, lpDBFI, (SHORT)nField);
	return PSGetErrCode(pcserve.m_pCCB);
}

int CPSDB::DBClose()
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	if (m_lpFieldInf != NULL) {
		delete m_lpFieldInf;
		m_lpFieldInf = NULL;
	}

	PSDBClose(m_pFCB);
	m_pFCB = NULL;

	return 0;
}

int CPSDB::DBFlush()
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBFlush(m_pFCB);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBIndex(LPCTSTR lpFileName, LPINT lpIdxNo)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	*lpIdxNo = PSDBIndex(m_pFCB, (LPSTR)lpFileName);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBIdxCreate(LPCTSTR lpFileName, LPCTSTR lpKey, PSBOOL bUniq, LPINT lpIdxNo)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	*lpIdxNo = PSDBIdxCreate(m_pFCB, (LPSTR)lpFileName, (LPSTR)lpKey, (SHORT)bUniq);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBChgIdx(int nIdxNo)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBChgIdx(m_pFCB, (SHORT)nIdxNo);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBSearch(LPCTSTR lpKey, int nKeyLength)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBSearch(m_pFCB, (LPSTR)lpKey, (SHORT)nKeyLength);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBSearch2(LPCTSTR lpKey, int nKeyLength, LPINT lpFind)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	*lpFind = PSDBSearch2(m_pFCB, (LPSTR)lpKey, nKeyLength);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBSearchLock(LPCTSTR lpKey, int nKeyLength, LPLONG lpRecNum)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	*lpRecNum = PSDBSearchLock(m_pFCB, (LPSTR)lpKey, (SHORT)nKeyLength);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBCount(LPCTSTR lpKey, int nKeyLength, LPLONG lpRecNum)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	*lpRecNum = PSDBCount(m_pFCB, (LPSTR)lpKey, (SHORT)nKeyLength);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBStore(LPVOID lpRec)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBStore(m_pFCB, (LPSTR)lpRec);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBStoreUniq(LPVOID lpRec)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBStoreUniq(m_pFCB, (LPSTR)lpRec);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBUpdate(LPVOID lpRec)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBUpdate(m_pFCB, (LPSTR)lpRec);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBUpdateKey(LPCTSTR lpKey, int nKeyLength, LPVOID lpBuf)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBUpdateKey(m_pFCB, (LPSTR)lpKey, (SHORT)nKeyLength, (LPSTR)lpBuf);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBDelete()
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBDelete(m_pFCB);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBRecall()
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBRecall(m_pFCB);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBDelete2()
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBDelete2(m_pFCB);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBDelete3()
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBDelete3(m_pFCB);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBDeleteKey(LPCTSTR lpKey, int nKeyLength, int nFlag)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBDeleteKey(m_pFCB, (LPSTR)lpKey, (SHORT)nKeyLength, (SHORT)nFlag);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBTop()
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBTop(m_pFCB);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBBottom()
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBBottom(m_pFCB);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBSet(int nRecNo)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBSet(m_pFCB, nRecNo);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBSkip(int nRecNum)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBSkip(m_pFCB, nRecNum);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBReindex()
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBReindex(m_pFCB);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBPack()
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBPack(m_pFCB);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBRead(LPVOID lpBuf)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBRead(m_pFCB, (LPSTR)lpBuf);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBReadNext(int nRec, LPVOID lpBuf, LPINT lpReadRec)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	*lpReadRec = PSDBReadNext(m_pFCB, (SHORT)nRec, (LPSTR)lpBuf);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBReadBack(int nRec, LPVOID lpBuf, LPINT lpReadRec)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	*lpReadRec = PSDBReadBack(m_pFCB, (SHORT)nRec, (LPSTR)lpBuf);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBReadKey(LPCTSTR lpKey, int nKeyLength, LPVOID lpBuf, int nLock, LPINT lpFind)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	*lpFind = PSDBReadKey(m_pFCB, (LPSTR)lpKey, nKeyLength, (LPSTR)lpBuf, (SHORT)nLock);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBClrRecord()
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBClrRecord(m_pFCB);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBGetRecord()
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBGetRecord(m_pFCB);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBGetField(LPCTSTR lpFieldName, LPVOID lpBuf, LPINT lpFieldType)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	*lpFieldType = PSDBGetField(m_pFCB, (LPSTR)lpFieldName, lpBuf);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBSetField(LPCTSTR lpFieldName, LPVOID lpBuf)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBSetField(m_pFCB, (LPSTR)lpFieldName, lpBuf);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBAddRecord()
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBAddRecord(m_pFCB);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBUpdRecord()
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBUpdRecord(m_pFCB);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBCheckDeleted(LPINT lpDeleted)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	*lpDeleted = PSDBCheckDeleted(m_pFCB);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBSetFilter(LPCTSTR lpFilter)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBSetFilter(m_pFCB, (LPSTR)lpFilter);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBSelect(LPCTSTR lpSelect, LPLONG lpRecNum)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	*lpRecNum = PSDBSelect(m_pFCB, (LPSTR)lpSelect);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBSetDeleted(int nFlag)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBSetDeleted(m_pFCB, (SHORT)nFlag);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBLRecNo(LPLONG lpRecNo)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	*lpRecNo = PSDBLRecNo(m_pFCB);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBLRecCount(LPLONG lpRecNum)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	*lpRecNum = PSDBLRecCount(m_pFCB);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBLSet(int nRecNo)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBLSet(m_pFCB, nRecNo);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBZip()
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBZip(m_pFCB);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBCheckUpdate(LPBOOL lpUpdateFlag)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	*lpUpdateFlag = PSDBCheckUpdate(m_pFCB);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBLock(int nLock)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBLock(m_pFCB, (SHORT)nLock);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBUnlock(int nLock)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBUnlock(m_pFCB, (SHORT)nLock);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBRecCount(LPLONG lpRecNum)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	*lpRecNum = PSDBRecCount(m_pFCB);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBBof(LPBOOL lpBofFlag)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	*lpBofFlag = PSDBBof(m_pFCB);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBDbf(LPSTR lpFileName)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBDbf(m_pFCB, lpFileName);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBEof(LPBOOL lpEofFlag)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	*lpEofFlag = PSDBEof(m_pFCB);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBNField(LPINT lpFieldNum)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	*lpFieldNum = PSDBNField(m_pFCB);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBField(int nFieldNo, PDBF_I lpDBFI)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBField(m_pFCB, (SHORT)nFieldNo, lpDBFI);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBNdx(int nIdxNo, LPSTR lpFileName)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBNdx(m_pFCB, (SHORT)nIdxNo, lpFileName);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBRecNo(LPLONG lpRecNo)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	*lpRecNo = PSDBRecNo(m_pFCB);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBRecSize(LPINT lpRecSize)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	*lpRecSize = PSDBRecSize(m_pFCB);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBSetReadField(LPCTSTR lpReadField, LPINT lpDataSize)
{
	int err;

	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	*lpDataSize = PSDBSetReadField(m_pFCB, (LPSTR)lpReadField);
	err = PSGetErrCode(m_pCCB);
	if (err == 0 && lpReadField != NULL)
		m_ReadField = lpReadField;
	else
		m_ReadField.Empty();

	return err;
}

int CPSDB::DBSetScramble()
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBSetScramble(m_pFCB);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBSetPassword(LPCTSTR lpPassword)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBSetPassword(m_pFCB, (LPSTR)lpPassword);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBReadAll(LPVOID lpBuf, LPBOOL lpReadFlag)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	*lpReadFlag = PSDBReadAll(m_pFCB, (LPSTR)lpBuf);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBReadBinary(LPCTSTR lpFieldName, LPVOID lpBuf, int nBufSize, LPLONG lpReadNum)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	*lpReadNum = PSDBReadBinary(m_pFCB, (LPSTR)lpFieldName, (LPSTR)lpBuf, nBufSize);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBWriteBinary(LPCTSTR lpFieldName, LPCVOID lpBuf, int nDataSize)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBWriteBinary(m_pFCB, (LPSTR)lpFieldName, (LPSTR)lpBuf, nDataSize);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBGetBinarySize(LPCTSTR lpFieldName, LPLONG lpDataSize)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	*lpDataSize = PSDBGetBinarySize(m_pFCB, (LPSTR)lpFieldName);
	return PSGetErrCode(m_pCCB);
}

int CPSDB::DBGetFieldBuf(LPVOID lpRecBuf, LPVOID lpFieldBuf)
{
	int i, j, err;
	PDBF_I lpFieldInf;
	LPSTR p;

	if (m_lpFieldInf == NULL) {
		if ((err = GetFieldInf()) != 0)
			return err;
	}

	for (i = 0; ; i++) {
		if (m_ReadField.IsEmpty()) {
			if (i == m_nField)
				break;
			lpFieldInf = &m_lpFieldInf[i];
		} else {
			if ((p = strtok((i == 0) ? (LPSTR)(LPCTSTR)m_ReadField : NULL, "+ ")) == NULL)
				break;
			for (j = 0, lpFieldInf = m_lpFieldInf; j < m_nField; j++, lpFieldInf++) {
				if (strcmp(p, lpFieldInf->name) == 0)
					break;
			}
			if (j == m_nField)
				return ERROR_DB_PARAMETER;
		}
		CString tmp((LPCTSTR)lpRecBuf, lpFieldInf->lField);
		tmp.TrimRight();
		switch (lpFieldInf->type) {
		case 'C':
		case 'D':
		case 'L':
			*(CString *)lpFieldBuf = tmp;
			lpFieldBuf = (LPVOID)((char *)lpFieldBuf + sizeof(CString));
			break;
		case 'N':
			*(float *)lpFieldBuf = atof((LPCTSTR)tmp);
			lpFieldBuf = (LPVOID)((float *)lpFieldBuf + 1);
			break;
		case 'I':
			*(int *)lpFieldBuf = atoi((LPCTSTR)tmp);
			lpFieldBuf = (LPVOID)((int *)lpFieldBuf + 1);
			break;
		case 'B':
			break;
		default:
			return ERROR_DB_PARAMETER;
		}
		lpRecBuf = (LPVOID)((LPSTR)lpRecBuf + lpFieldInf->lField);
	}

	return 0;
}

int CPSDB::DBSetFieldBuf(LPVOID lpRecBuf, LPVOID lpFieldBuf)
{
	int i, len, err;
	PDBF_I lpFieldInf;
	CString fmt, strBuf;

	if (m_lpFieldInf == NULL) {
		if ((err = GetFieldInf()) != 0)
			return err;
	}

	lpFieldInf = m_lpFieldInf;
	for (i = 0; i < m_nField; i++) {
		switch (lpFieldInf->type) {
		case 'C':
		case 'D':
		case 'L':
			len = min((int)strlen((LPCTSTR)(*(CString *)lpFieldBuf)), (int)lpFieldInf->lField);
			memcpy(lpRecBuf, (LPCTSTR)(*(CString *)lpFieldBuf), len);
			if (len < lpFieldInf->lField)
				memset((LPSTR)lpRecBuf + len, ' ', lpFieldInf->lField - len);
			lpFieldBuf = (LPVOID)((char *)lpFieldBuf + sizeof(CString));
			break;
		case 'N':
			fmt.Format("%%%d.%dlf", lpFieldInf->lField, lpFieldInf->lDec);
			strBuf.Format(fmt, *(float *)lpFieldBuf);
			memcpy(lpRecBuf, (LPCTSTR)strBuf, lpFieldInf->lField);
			lpFieldBuf = (LPVOID)((float *)lpFieldBuf + 1);
			break;
		case 'I':
			fmt.Format("%%%dld", lpFieldInf->lField);
			strBuf.Format(fmt, *(int *)lpFieldBuf);
			memcpy(lpRecBuf, (LPCTSTR)strBuf, lpFieldInf->lField);
			lpFieldBuf = (LPVOID)((int *)lpFieldBuf + 1);
			break;
		case 'B':
			break;
		default:
			return ERROR_DB_PARAMETER;
		}
		lpRecBuf = (LPVOID)((LPSTR)lpRecBuf + lpFieldInf->lField);
		lpFieldInf++;
	}

	return 0;
}

int CPSDB::GetFieldInf()
{
	int i, err;

	if ((err = DBNField(&m_nField)) != 0)
		return err;

	if ((m_lpFieldInf = new DBF_I[m_nField]) == NULL)
		return ERROR_DB_MEMORY;

	for (i = 0; i < m_nField; i++) {
		if ((err = DBField(i + 1, &m_lpFieldInf[i])) != 0) {
			delete m_lpFieldInf;
			m_lpFieldInf = NULL;
			return err;
		}
	}

	return 0;
}

int CPSDB::DBCopy(CPSDB &dbSrc)
{
	if (m_pFCB == NULL)
		return ERROR_CLIENT_NOTOPEN;

	PSDBCopy(dbSrc.m_pFCB, m_pFCB);
	return PSGetErrCode(m_pCCB);
}
