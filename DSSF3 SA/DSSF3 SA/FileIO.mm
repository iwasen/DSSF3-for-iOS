// FileIO.cpp : インプリメンテーション ファイル
//

#import <UIKit/UIKit.h>
#import "FileIO.h"
#import "Global.h"

#define	OFFSET_MEASTIME	50

char g_szDefaultDir[256];
CMyPcserve g_oPcserve;

static void ErrorMessage(NSString *msgID, int err = 0);
static void MakeStrID(int id, CString &strID);

void CMyPcserve::Initialize()
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *path = [paths objectAtIndex:0];
	strcpy(g_szDefaultDir, [path UTF8String]);

	NSString *folderDBF = [path stringByAppendingPathComponent:@FN_FOLDER_DBF];
	if (![[NSFileManager defaultManager] fileExistsAtPath:folderDBF]) {
		NSBundle *bundle = [NSBundle mainBundle];
		NSString *samplePath = [bundle.bundlePath stringByAppendingPathComponent:@"SampleEng"];
		NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:samplePath error:nil];
		for (NSString *file in files) {
			[[NSFileManager defaultManager] copyItemAtPath:[samplePath stringByAppendingPathComponent:file]
													toPath:[path stringByAppendingPathComponent:file]
													 error:nil];
		}
	}

	Connect(0, NULL, "");
}

BOOL CDbFolder::Open(LPCTSTR dir)
{
	static DBF_I fieldInf[] = {
		{"FOLDERID", 'I', LEN_ID,      0},
		{"TYPE",     'C', LEN_TYPE,    0},
		{"NAME",     'C', LEN_NAME,    0},
		{"PLACE",    'C', LEN_PLACE,   0},
		{"DATE",     'C', LEN_DATE,    0},
		{"TITLE",    'C', LEN_TITLE,   0},
		{"COMMENT",  'C', LEN_COMMENT, 0},
		{"SCALE",    'N', LEN_FLOAT,   2}
	};
	BOOL bCreateIndex = FALSE;
	CString pathName;
	int idx;
	int err;

	pathName.Format("%s/%s", (const char *)dir, FN_FOLDER_DBF);
	if ((err = DBOpen(g_oPcserve, pathName)) != 0) {
		if (err == ERROR_DB_NOFILE) {
			if ((err = DBCreate(g_oPcserve, pathName, fieldInf, sizeof(fieldInf) / sizeof(DBF_I))) != 0) {
				ErrorMessage(@"IDS_ERR_CREATEFOLDER", err);
				return FALSE;
			}
			bCreateIndex = TRUE;
		} else {
			ErrorMessage(@"IDS_ERR_OPENFOLDER", err);
			return FALSE;
		}
	}

	pathName.Format("%s/%s", dir, FN_FOLDER1_EDX);
	if (bCreateIndex || DBIndex(pathName, &idx) != 0) {
		if ((err = DBIdxCreate(pathName, "FOLDERID", 1, &idx)) != 0) {
			ErrorMessage(@"IDS_ERR_CREATEFOLDERINDEX", err);
			return FALSE;
		}
	}

	return TRUE;
}

BOOL CDbFolder::GetNewID(int *pID)
{
	DbFolderBuf dbBuf;
	char szID[LEN_ID + 1];
	int err;

	DBBottom();
	if ((err = DBRead(&dbBuf)) == 0) {
		memcpy(szID, dbBuf.aFolderID, LEN_ID);
		szID[LEN_ID] = '\0';
		*pID = atoi(szID) + 1;
	} else if (err == ERROR_DB_EOF)
		*pID = 0;
	else {
		ErrorMessage(@"IDS_ERR_READFOLDER", err);
		return FALSE;
	}

	return TRUE;
}

BOOL CDbFolder::ReadRecID(int id, DbFolderRec *pDbRec)
{
	DbFolderBuf dbBuf;
	CString strID;
	int find;
	int err;

	MakeStrID(id, strID);
	if ((err = DBReadKey(strID, LEN_ID, &dbBuf, 0, &find)) != 0) {
		ErrorMessage(@"IDS_ERR_READFOLDER", err);
		return FALSE;
	}

	if (find == 0)
		return FALSE;

	DBGetFieldBuf(&dbBuf, pDbRec);

	return TRUE;
}

BOOL CDbFolder::ReadRecNext(DbFolderRec *pDbRec)
{
	DbFolderBuf dbBuf;
	int nRead;
	int err;

	if ((err = DBReadNext(1, &dbBuf, &nRead)) != 0) {
		ErrorMessage(@"IDS_ERR_READFOLDER", err);
		return FALSE;
	}

	if (nRead != 1)
		return FALSE;

	DBGetFieldBuf(&dbBuf, pDbRec);

	return TRUE;
}

BOOL CDbFolder::StoreRec(DbFolderRec *pDbRec)
{
	DbFolderBuf dbBuf;
	int err;

	DBSetFieldBuf(&dbBuf, pDbRec);
	if ((err = DBStore(&dbBuf)) != 0) {
		ErrorMessage(@"IDS_ERR_WRITEFOLDER", err);
		return FALSE;
	}

	return TRUE;
}

BOOL CDbFolder::UpdateRec(DbFolderRec *pDbRec)
{
	DbFolderBuf dbBuf;
	int err;

	DBSetFieldBuf(&dbBuf, pDbRec);
	if ((err = DBUpdateKey(dbBuf.aFolderID, LEN_ID, &dbBuf)) != 0) {
		ErrorMessage(@"IDS_ERR_WRITEFOLDER", err);
		return FALSE;
	}

	return TRUE;
}

BOOL CDbImpulse::Open(LPCTSTR dir)
{
	static DBF_I fieldInf[] = {
		{"FOLDERID",   'I', LEN_ID,         0},
		{"IMPULSEID",  'I', LEN_ID,         0},
		{"SAMPLING",   'I', LEN_SAMPLING,   0},
		{"MESTIME",    'I', LEN_MESTIME,    0},
		{"MESNUM",     'I', LEN_MESNUM,     0},
		{"CHANNEL",    'I', LEN_CHANNEL,    0},
		{"BIT",        'I', LEN_BIT,        0},
		{"TIME",       'C', LEN_TIME,       0},
		{"TITLE",      'C', LEN_TITLE,      0},
		{"COMMENT",    'C', LEN_COMMENT,    0},
		{"USEFILTER",  'I', LEN_BOOL,       0},
		{"IFILTERID",  'I', LEN_ID,         0},
		{"TEMPERATUR", 'N', LEN_FLOAT,      2},
		{"HUMIDITY",   'N', LEN_FLOAT,      2},
		{"MULTIPLIER", 'I', LEN_MULTIPLIER, 0},
		{"WAVEDATA",   'B', 0,              0}
	};
	BOOL bCreateIndex = FALSE;
	CString pathName;
	int err;

	pathName.Format("%s/%s", dir, FN_IMPULSE_DBF);
	if ((err = DBOpen(g_oPcserve, pathName)) != 0) {
		if (err == ERROR_DB_NOFILE) {
			if ((err = DBCreate(g_oPcserve, pathName, fieldInf, sizeof(fieldInf) / sizeof(DBF_I))) != 0) {
				ErrorMessage(@"IDS_ERR_CREATEIRFILE", err);
				return FALSE;
			}
			bCreateIndex = TRUE;
		} else {
			ErrorMessage(@"IDS_ERR_OPENIRFILE", err);
			return FALSE;
		}
	}

	pathName.Format("%s/%s", dir, FN_IMPULSE1_EDX);
	if (bCreateIndex || DBIndex(pathName, &m_nIdxFolderID) != 0) {
		if ((err = DBIdxCreate(pathName, "FOLDERID", 0, &m_nIdxFolderID)) != 0) {
			ErrorMessage(@"IDS_ERR_CREATEIRINDEX1", err);
			return FALSE;
		}
	}

	pathName.Format("%s/%s", dir, FN_IMPULSE2_EDX);
	if (bCreateIndex || DBIndex(pathName, &m_nIdxImpulseID) != 0) {
		if ((err = DBIdxCreate(pathName, "IMPULSEID", 1, &m_nIdxImpulseID)) != 0) {
			ErrorMessage(@"IDS_ERR_CREATEIRINDEX2", err);
			return FALSE;
		}
	}

	return TRUE;
}

BOOL CDbImpulse::GetNewID(int *pID)
{
	DbImpulseBuf dbBuf;
	char szID[LEN_ID + 1];
	int err;

	DBChgIdx(m_nIdxImpulseID);
	DBBottom();
	if ((err = DBRead(&dbBuf)) == 0) {
		memcpy(szID, dbBuf.aImpulseID, LEN_ID);
		szID[LEN_ID] = '\0';
		*pID = atoi(szID) + 1;
	} else if (err == ERROR_DB_EOF)
		*pID = 0;
	else {
		ErrorMessage(@"IDS_ERR_READIRFILE", err);
		return FALSE;
	}

	return TRUE;
}

BOOL CDbImpulse::ReadRecID(int id, DbImpulseRec *pDbRec)
{
	DbImpulseBuf dbBuf;
	CString strID;
	int find;
	int err;

	if (id != -1) {
		MakeStrID(id, strID);
		DBChgIdx(m_nIdxImpulseID);
		if ((err = DBReadKey(strID, LEN_ID, &dbBuf, 0, &find)) != 0) {
			ErrorMessage(@"IDS_ERR_READIRFILE", err);
			return FALSE;
		}

		if (find == 0)
			return FALSE;
	} else {
		if ((err = DBRead(&dbBuf)) != 0) {
			ErrorMessage(@"IDS_ERR_READIRFILE", err);
			return FALSE;
		}
	}

	DBGetFieldBuf(&dbBuf, pDbRec);

	if (pDbRec->nMeasTime >= OFFSET_MEASTIME) {
		pDbRec->nMeasTime -= OFFSET_MEASTIME;
		pDbRec->bImpulseData = TRUE;
	} else
		pDbRec->bImpulseData = FALSE;

	return TRUE;
}

BOOL CDbImpulse::ReadRecNext(DbImpulseRec *pDbRec)
{
	DbImpulseBuf dbBuf;
	CString strID;
	int nRead;
	int err;

	if ((err = DBReadNext(1, &dbBuf, &nRead)) != 0) {
		ErrorMessage(@"IDS_ERR_READIRFILE", err);
		return FALSE;
	}

	if (nRead != 1)
		return FALSE;

	DBGetFieldBuf(&dbBuf, pDbRec);

	if (pDbRec->nMeasTime >= OFFSET_MEASTIME) {
		pDbRec->nMeasTime -= OFFSET_MEASTIME;
		pDbRec->bImpulseData = TRUE;
	} else
		pDbRec->bImpulseData = FALSE;

	return TRUE;
}

BOOL CDbImpulse::StoreRec(DbImpulseRec *pDbRec)
{
	DbImpulseBuf dbBuf;
	int err;

	if (pDbRec->bImpulseData)
		pDbRec->nMeasTime += OFFSET_MEASTIME;

	DBSetFieldBuf(&dbBuf, pDbRec);
	if ((err = DBStore(&dbBuf)) != 0) {
		ErrorMessage(@"IDS_ERR_WRITEIRFILE", err);
		return FALSE;
	}

	return TRUE;
}

BOOL CDbImpulse::UpdateRec(DbImpulseRec *pDbRec)
{
	DbImpulseBuf dbBuf;
	int err;

	DBSetFieldBuf(&dbBuf, pDbRec);
	DBChgIdx(m_nIdxImpulseID);
	if ((err = DBUpdateKey(dbBuf.aImpulseID, LEN_ID, &dbBuf)) != 0) {
		ErrorMessage(@"IDS_ERR_WRITEIRFILE", err);
		return FALSE;
	}

	return TRUE;
}
/*
BOOL CDbAcf::Open(LPCTSTR dir)
{
	static DBF_I fieldInf[] = {
		{"FOLDERID",   'I', LEN_ID,         0},
		{"ACFID",      'I', LEN_ID,         0},
		{"SAMPLING",   'I', LEN_SAMPLING,   0},
		{"CHANNEL",    'I', LEN_CHANNEL,    0},
		{"SAMPLENUM",  'I', LEN_SAMPLENUM,  0},
		{"DATATIME",   'N', LEN_FLOAT,      2},
		{"TIME",       'C', LEN_TIME,       0},
		{"TITLE",      'C', LEN_TITLE,      0},
		{"COMMENT",    'C', LEN_COMMENT,    0},
		{"WAVEDATA",   'B', 0,              0}
	};
	BOOL bCreateIndex = FALSE;
	CString pathName;
	int err;

	pathName.Format("%s/%s", dir, FN_ACF_DBF);
	if ((err = DBOpen(g_oPcserve, pathName)) != 0) {
		if (err == ERROR_DB_NOFILE) {
			if ((err = DBCreate(g_oPcserve, pathName, fieldInf, sizeof(fieldInf) / sizeof(DBF_I))) != 0) {
				ErrorMessage(@"IDS_ERR_CREATEACFFILE", err);
				return FALSE;
			}
			bCreateIndex = TRUE;
		} else {
			ErrorMessage(@"IDS_ERR_OPENACFFILE", err);
			return FALSE;
		}
	}

	pathName.Format("%s/%s", dir, FN_ACF1_EDX);
	if (bCreateIndex || DBIndex(pathName, &m_nIdxFolderID) != 0) {
		if ((err = DBIdxCreate(pathName, "FOLDERID", 0, &m_nIdxFolderID)) != 0) {
			ErrorMessage(@"IDS_ERR_CREATEACFINDEX1", err);
			return FALSE;
		}
	}

	pathName.Format("%s/%s", dir, FN_ACF2_EDX);
	if (bCreateIndex || DBIndex(pathName, &m_nIdxAcfID) != 0) {
		if ((err = DBIdxCreate(pathName, "ACFID", 1, &m_nIdxAcfID)) != 0) {
			ErrorMessage(@"IDS_ERR_CREATEACFINDEX2", err);
			return FALSE;
		}
	}

	return TRUE;
}

BOOL CDbAcf::GetNewID(int *pID)
{
	DbAcfBuf dbBuf;
	char szID[LEN_ID + 1];
	int err;

	DBChgIdx(m_nIdxAcfID);
	DBSetFilter("ACFID>=0");
	DBBottom();
	if ((err = DBRead(&dbBuf)) == 0) {
		memcpy(szID, dbBuf.aAcfID, LEN_ID);
		szID[LEN_ID] = '\0';
		*pID = atoi(szID) + 1;
	} else if (err == ERROR_DB_EOF)
		*pID = 0;
	else {
		DBSetFilter(NULL);
		ErrorMessage(@"IDS_ERR_READACFFILE", err);
		return FALSE;
	}

	DBSetFilter(NULL);

	return TRUE;
}

BOOL CDbAcf::ReadRecID(int id, DbAcfRec *pDbRec)
{
	DbAcfBuf dbBuf;
	CString strID;
	int find;
	int err;

	MakeStrID(id, strID);
	DBChgIdx(m_nIdxAcfID);
	if ((err = DBReadKey(strID, LEN_ID, &dbBuf, 0, &find)) != 0) {
		ErrorMessage(@"IDS_ERR_READACFFILE", err);
		return FALSE;
	}

	if (find == 0)
		return FALSE;

	DBGetFieldBuf(&dbBuf, pDbRec);

	return TRUE;
}

BOOL CDbAcf::ReadRecNext(DbAcfRec *pDbRec)
{
	DbAcfBuf dbBuf;
	CString strID;
	int nRead;
	int err;

	if ((err = DBReadNext(1, &dbBuf, &nRead)) != 0) {
		ErrorMessage(@"IDS_ERR_READACFFILE", err);
		return FALSE;
	}

	if (nRead != 1)
		return FALSE;

	DBGetFieldBuf(&dbBuf, pDbRec);

	return TRUE;
}

BOOL CDbAcf::StoreRec(DbAcfRec *pDbRec)
{
	DbAcfBuf dbBuf;
	int err;

	DBSetFieldBuf(&dbBuf, pDbRec);
	if ((err = DBStore(&dbBuf)) != 0) {
		ErrorMessage(@"IDS_ERR_WRITEACFFILE", err);
		return FALSE;
	}

	return TRUE;
}

BOOL CDbAcf::UpdateRec(DbAcfRec *pDbRec)
{
	DbAcfBuf dbBuf;
	int err;

	DBSetFieldBuf(&dbBuf, pDbRec);
	DBChgIdx(m_nIdxAcfID);
	if ((err = DBUpdateKey(dbBuf.aAcfID, LEN_ID, &dbBuf)) != 0) {
		ErrorMessage(@"IDS_ERR_WRITEACFFILE", err);
		return FALSE;
	}

	return TRUE;
}
*/
BOOL CDbAcParam::Open(LPCTSTR dir)
{
	static DBF_I fieldInf[] = {
		{"IMPULSEID", 'I', LEN_ID,    0},
		{"CONDSIZE",  'I', LEN_SIZE,  0},
		{"DATASIZE",  'I', LEN_SIZE,  0},
		{"DATANUM",   'I', LEN_NDATA, 0},
		{"CONDITION", 'B', 0},
		{"RESULT",    'B', 0},
		{"DATA",      'B', 0}
	};
	BOOL bCreateIndex = FALSE;
	CString pathName;
	int idx;
	int err;

	pathName.Format("%s/%s", dir, FN_ACPARAM_DBF);
	if ((err = DBOpen(g_oPcserve, pathName)) != 0) {
		if (err == ERROR_DB_NOFILE) {
			if ((err = DBCreate(g_oPcserve, pathName, fieldInf, sizeof(fieldInf) / sizeof(DBF_I))) != 0) {
				ErrorMessage(@"IDS_ERR_CREATECALCFILE", err);
				return FALSE;
			}
			bCreateIndex = TRUE;
		} else {
			ErrorMessage(@"IDS_ERR_OPENCALCFILE", err);
			return FALSE;
		}
	}

	pathName.Format("%s/%s", dir, FN_ACPARAM1_EDX);
	if (bCreateIndex || DBIndex(pathName, &idx) != 0) {
		if ((err = DBIdxCreate(pathName, "IMPULSEID", 1, &idx)) != 0) {
			ErrorMessage(@"IDS_ERR_CREATECALCINDEX", err);
			return FALSE;
		}
	}

	return TRUE;
}

BOOL CDbAcParam::ReadRecID(int id, DbAcParamRec *pDbRec)
{
	DbAcParamBuf dbBuf;
	CString strID;
	int find;
	int nRead;
	int err;

	MakeStrID(id, strID);
	if ((err = DBReadKey(strID, LEN_ID, &dbBuf, 0, &find)) != 0) {
		if (err != ERROR_DB_NOKEY)
			ErrorMessage(@"IDS_ERR_READCALCFILE", err);
		return FALSE;
	}

	if (find == 0)
		return FALSE;

	memset(pDbRec, 0, sizeof(DbAcParamRec));

	DBGetFieldBuf(&dbBuf, pDbRec);

	if ((err = DBReadBinary("CONDITION", &pDbRec->dbAcParamCond, sizeof(DbAcParamCond), &nRead)) != 0) {
		ErrorMessage(@"IDS_ERR_READCALCFILE", err);
		return FALSE;
	}

	if ((err = DBReadBinary("RESULT", &pDbRec->dbAcParamResult, sizeof(DbAcParamResult), &nRead)) != 0) {
		ErrorMessage(@"IDS_ERR_READCALCFILE", err);
		return FALSE;
	}

	if ((err = DBReadBinary("DATA", &pDbRec->dbAcParamData, sizeof(DbAcParamData) * pDbRec->nDataNum, &nRead)) != 0) {
		ErrorMessage(@"IDS_ERR_READCALCFILE", err);
		return FALSE;
	}

	return TRUE;
}

BOOL CDbAcParam::SearchID(int id, BOOL bDispErr)
{
	CString strID;
	int find;
	int err;

	MakeStrID(id, strID);
	if ((err = DBSearch2(strID, LEN_ID, &find)) != 0) {
		if (bDispErr)
			ErrorMessage(@"IDS_ERR_FINDCALCFILE", err);
		return FALSE;
	}

	if (find != 1)
		return FALSE;

	return TRUE;
}

BOOL CDbAcParam::StoreRec(DbAcParamRec *pDbRec)
{
	DbAcParamBuf dbBuf;
	int err;

	pDbRec->nConditionSize = sizeof(DbAcParamCond);
	pDbRec->nDataSize = sizeof(DbAcParamData);

	DBSetFieldBuf(&dbBuf, pDbRec);
	if ((err = DBStore(&dbBuf)) != 0) {
		ErrorMessage(@"IDS_ERR_WRITECALCFILE", err);
		return FALSE;
	}

	if ((err = DBWriteBinary("CONDITION", &pDbRec->dbAcParamCond, sizeof(DbAcParamCond))) != 0) {
		ErrorMessage(@"IDS_ERR_WRITECALCFILE", err);
		return FALSE;
	}

	if ((err = DBWriteBinary("RESULT", &pDbRec->dbAcParamResult, sizeof(DbAcParamResult))) != 0) {
		ErrorMessage(@"IDS_ERR_WRITECALCFILE", err);
		return FALSE;
	}

	if ((err = DBWriteBinary("DATA", &pDbRec->dbAcParamData, sizeof(DbAcParamData) * pDbRec->nDataNum)) != 0) {
		ErrorMessage(@"IDS_ERR_WRITECALCFILE", err);
		return FALSE;
	}

	return TRUE;
}

BOOL CDbAcParam::UpdateRec(DbAcParamRec *pDbRec)
{
	DbAcParamBuf dbBuf;
	int err;

	pDbRec->nConditionSize = sizeof(DbAcParamCond);
	pDbRec->nDataSize = sizeof(DbAcParamData);

	DBSetFieldBuf(&dbBuf, pDbRec);
	if ((err = DBUpdateKey(dbBuf.aImpulseID, LEN_ID, &dbBuf)) != 0) {
		ErrorMessage(@"IDS_ERR_WRITECALCFILE", err);
		return FALSE;
	}

	if ((err = DBWriteBinary("CONDITION", &pDbRec->dbAcParamCond, sizeof(DbAcParamCond))) != 0) {
		ErrorMessage(@"IDS_ERR_WRITECALCFILE", err);
		return FALSE;
	}

	if ((err = DBWriteBinary("RESULT", &pDbRec->dbAcParamResult, sizeof(DbAcParamResult))) != 0) {
		ErrorMessage(@"IDS_ERR_WRITECALCFILE", err);
		return FALSE;
	}

	if ((err = DBWriteBinary("DATA", &pDbRec->dbAcParamData, sizeof(DbAcParamData) * pDbRec->nDataNum)) != 0) {
		ErrorMessage(@"IDS_ERR_WRITECALCFILE", err);
		return FALSE;
	}

	return TRUE;
}
/*
BOOL CDbAcfFactor::Open(LPCTSTR dir)
{
	static DBF_I fieldInf[] = {
		{"ACFID",     'I', LEN_ID,       0},
		{"CONDSIZE",  'I', LEN_SIZE,     0},
		{"FACTSIZE",  'I', LEN_SIZE,     0},
		{"NACFFACT",  'I', LEN_NACFFACT, 0},
		{"ACFCOND2",  'B', 0},
		{"ACFFACTOR", 'B', 0}
	};
	BOOL bCreateIndex = FALSE;
	CString pathName;
	int idx;
	int err;

	pathName.Format("%s/%s", dir, FN_ACFFACT_DBF);
	if ((err = DBOpen(g_oPcserve, pathName)) != 0) {
		if (err == ERROR_DB_NOFILE) {
			if ((err = DBCreate(g_oPcserve, pathName, fieldInf, sizeof(fieldInf) / sizeof(DBF_I))) != 0) {
				ErrorMessage(@"IDS_ERR_CREATECALCFILE", err);
				return FALSE;
			}
			bCreateIndex = TRUE;
		} else {
			ErrorMessage(@"IDS_ERR_OPENCALCFILE", err);
			return FALSE;
		}
	}

	pathName.Format("%s/%s", dir, FN_ACFFACT1_EDX);
	if (bCreateIndex || DBIndex(pathName, &idx) != 0) {
		if ((err = DBIdxCreate(pathName, "ACFID", 1, &idx)) != 0) {
			ErrorMessage(@"IDS_ERR_CREATECALCINDEX", err);
			return FALSE;
		}
	}

	return TRUE;
}

BOOL CDbAcfFactor::ReadRecID(int id, DbAcfFactorRec *pDbRec, AcfConditionData *pAcfConditionData, AcfFactorData **pAcfFactorData, TaunPhinData **pTaunPhinData)
{
	DbAcfFactorBuf dbBuf;
	CString strID;
	int find;
	int nRead;
	int err;

	MakeStrID(id, strID);
	if ((err = DBReadKey(strID, LEN_ID, &dbBuf, 0, &find)) != 0) {
		if (err != ERROR_DB_NOKEY)
			ErrorMessage(@"IDS_ERR_READCALCFILE", err);
		return FALSE;
	}

	if (find == 0)
		return FALSE;

	DBGetFieldBuf(&dbBuf, pDbRec);

	if (pAcfConditionData != NULL) {
		memset(pAcfConditionData, 0, sizeof(AcfConditionData));
		if ((err = DBReadBinary("ACFCOND2", pAcfConditionData, sizeof(AcfConditionData), &nRead)) != 0) {
			ErrorMessage(@"IDS_ERR_READCALCFILE", err);
			return FALSE;
		}
	}

	if (pAcfFactorData != NULL) {
		*pAcfFactorData = new AcfFactorData[pDbRec->nAcfFactor];
		memset(*pAcfFactorData, 0, sizeof(AcfFactorData) * pDbRec->nAcfFactor);
		if ((err = DBReadBinary("ACFFACTOR", *pAcfFactorData, sizeof(AcfFactorData) * pDbRec->nAcfFactor, &nRead)) != 0) {
			ErrorMessage(@"IDS_ERR_READCALCFILE", err);
			return FALSE;
		}
		if (pTaunPhinData != NULL) {
			*pTaunPhinData = new TaunPhinData[pDbRec->nAcfFactor];
			memset(*pTaunPhinData, 0, sizeof(TaunPhinData) * pDbRec->nAcfFactor);
			if ((err = DBReadBinary(NULL, *pTaunPhinData, sizeof(TaunPhinData) * pDbRec->nAcfFactor, &nRead)) != 0) {
				ErrorMessage(@"IDS_ERR_READCALCFILE", err);
				return FALSE;
			}
		}
	}

	return TRUE;
}

BOOL CDbAcfFactor::SearchID(int id)
{
	CString strID;
	int find;
	int err;

	MakeStrID(id, strID);
	if ((err = DBSearch2(strID, LEN_ID, &find)) != 0) {
		ErrorMessage(@"IDS_ERR_FINDCALCFILE", err);
		return FALSE;
	}

	if (find != 1)
		return FALSE;

	return TRUE;
}

BOOL CDbAcfFactor::StoreRec(DbAcfFactorRec *pDbRec)
{
	DbAcfFactorBuf dbBuf;
	int err;

	DBSetFieldBuf(&dbBuf, pDbRec);
	if ((err = DBStore(&dbBuf)) != 0) {
		ErrorMessage(@"IDS_ERR_WRITECALCFILE", err);
		return FALSE;
	}

	return TRUE;
}

BOOL CDbAcfFactor::UpdateRec(DbAcfFactorRec *pDbRec)
{
	DbAcfFactorBuf dbBuf;
	int err;

	DBSetFieldBuf(&dbBuf, pDbRec);
	if ((err = DBUpdateKey(dbBuf.aAcfID, LEN_ID, &dbBuf)) != 0) {
		ErrorMessage(@"IDS_ERR_WRITECALCFILE", err);
		return FALSE;
	}

	return TRUE;
}

BOOL CDbIFilter::Open(LPCTSTR dir)
{
	static DBF_I fieldInf[] = {
		{"IFILTERID", 'I', LEN_ID,       0},
		{"TITLE",     'C', LEN_TITLE,    0},
		{"COMMENT",   'C', LEN_COMMENT,  0},
		{"SAMPLING",  'I', LEN_SAMPLING, 0},
		{"STARTPOS",  'N', LEN_FLOAT,    3},
		{"ENDPOS",    'N', LEN_FLOAT,    3},
		{"MAXLEVEL",  'I', LEN_MAXLEVEL, 0},
		{"PHASEADJ",  'I', LEN_BOOL,     0},
		{"IRDATA",    'B', 0,            0},
	};
	BOOL bCreateIndex = FALSE;
	CString pathName;
	int idx;
	int err;

	pathName.Format("%s/%s", dir, FN_IFILTER_DBF);
	if ((err = DBOpen(g_oPcserve, pathName)) != 0) {
		if (err == ERROR_DB_NOFILE) {
			if ((err = DBCreate(g_oPcserve, pathName, fieldInf, sizeof(fieldInf) / sizeof(DBF_I))) != 0) {
				ErrorMessage(@"IDS_ERR_CREATEIFFILE", err);
				return FALSE;
			}
			bCreateIndex = TRUE;
		} else {
			ErrorMessage(@"IDS_ERR_OPENIFFILE", err);
			return FALSE;
		}
	}

	pathName.Format("%s/%s", dir, FN_IFILTER1_EDX);
	if (bCreateIndex || DBIndex(pathName, &idx) != 0) {
		if ((err = DBIdxCreate(pathName, "IFILTERID", 1, &idx)) != 0) {
			ErrorMessage(@"IDS_ERR_CREATEIFINDEX", err);
			return FALSE;
		}
	}

	return TRUE;
}

BOOL CDbIFilter::GetNewID(int *pID)
{
	DbIFilterBuf dbBuf;
	char szID[LEN_ID + 1];
	int err;

	DBBottom();
	if ((err = DBRead(&dbBuf)) == 0) {
		memcpy(szID, dbBuf.aIFilterID, LEN_ID);
		szID[LEN_ID] = '\0';
		*pID = atoi(szID) + 1;
	} else if (err == ERROR_DB_EOF)
		*pID = 0;
	else {
		ErrorMessage(@"IDS_ERR_READIFFILE", err);
		return FALSE;
	}

	return TRUE;
}

BOOL CDbIFilter::ReadRecID(int id, DbIFilterRec *pDbRec)
{
	DbIFilterBuf dbBuf;
	CString strID;
	int find;
	int err;

	MakeStrID(id, strID);
	if ((err = DBReadKey(strID, LEN_ID, &dbBuf, 0, &find)) != 0) {
		ErrorMessage(@"IDS_ERR_READIFFILE", err);
		return FALSE;
	}

	if (find == 0)
		return FALSE;

	DBGetFieldBuf(&dbBuf, pDbRec);

	return TRUE;
}

BOOL CDbIFilter::ReadRecNext(DbIFilterRec *pDbRec)
{
	DbIFilterBuf dbBuf;
	CString strID;
	int nRead;
	int err;

	if ((err = DBReadNext(1, &dbBuf, &nRead)) != 0) {
		ErrorMessage(@"IDS_ERR_READIFFILE", err);
		return FALSE;
	}

	if (nRead != 1)
		return FALSE;

	DBGetFieldBuf(&dbBuf, pDbRec);

	return TRUE;
}

BOOL CDbIFilter::StoreRec(DbIFilterRec *pDbRec)
{
	DbIFilterBuf dbBuf;
	int err;

	DBSetFieldBuf(&dbBuf, pDbRec);
	if ((err = DBStore(&dbBuf)) != 0) {
		ErrorMessage(@"IDS_ERR_WRITEIFFILE", err);
		return FALSE;
	}

	return TRUE;
}

BOOL CDbIFilter::UpdateRec(DbIFilterRec *pDbRec)
{
	DbIFilterBuf dbBuf;
	int err;

	DBSetFieldBuf(&dbBuf, pDbRec);
	if ((err = DBUpdateKey(dbBuf.aIFilterID, LEN_ID, &dbBuf)) != 0) {
		ErrorMessage(@"IDS_ERR_WRITEIFFILE", err);
		return FALSE;
	}

	return TRUE;
}

BOOL CDbIFilter::DeleteID(int id)
{
	CString strID;
	int err;

	MakeStrID(id, strID);
	if ((err = DBDeleteKey(strID, LEN_ID, 1)) != 0) {
		ErrorMessage(@"IDS_ERR_DELETEIFFILE", err);
		return FALSE;
	}

	return TRUE;
}

BOOL CDbMicCal::Open(LPCTSTR dir)
{
	static DBF_I fieldInf[] = {
		{"MICCALID",   'I', LEN_ID,      0},
		{"MICINFO",    'C', LEN_MICINFO, 0},
		{"MICAMPINFO", 'C', LEN_MICAMPINFO, 0},
		{"COMMENT",    'C', LEN_COMMENT, 0},
		{"INPUTSENS",  'N', LEN_FLOAT,   2},
		{"INPUTSEL",   'I', LEN_SHORT,   0},
		{"INPUTVOL",   'I', LEN_SHORT,   0},
		{"NFREQDATA",  'I', LEN_SHORT,   0},
		{"FREQ01",     'N', LEN_FLOAT,   2},
		{"LEVEL01",    'N', LEN_FLOAT,   2},
		{"FREQ02",     'N', LEN_FLOAT,   2},
		{"LEVEL02",    'N', LEN_FLOAT,   2},
		{"FREQ03",     'N', LEN_FLOAT,   2},
		{"LEVEL03",    'N', LEN_FLOAT,   2},
		{"FREQ04",     'N', LEN_FLOAT,   2},
		{"LEVEL04",    'N', LEN_FLOAT,   2},
		{"FREQ05",     'N', LEN_FLOAT,   2},
		{"LEVEL05",    'N', LEN_FLOAT,   2},
		{"FREQ06",     'N', LEN_FLOAT,   2},
		{"LEVEL06",    'N', LEN_FLOAT,   2},
		{"FREQ07",     'N', LEN_FLOAT,   2},
		{"LEVEL07",    'N', LEN_FLOAT,   2},
		{"FREQ08",     'N', LEN_FLOAT,   2},
		{"LEVEL08",    'N', LEN_FLOAT,   2},
		{"FREQ09",     'N', LEN_FLOAT,   2},
		{"LEVEL09",    'N', LEN_FLOAT,   2},
		{"FREQ10",     'N', LEN_FLOAT,   2},
		{"LEVEL10",    'N', LEN_FLOAT,   2},
		{"FREQ11",     'N', LEN_FLOAT,   2},
		{"LEVEL11",    'N', LEN_FLOAT,   2},
		{"FREQ12",     'N', LEN_FLOAT,   2},
		{"LEVEL12",    'N', LEN_FLOAT,   2},
		{"FREQ13",     'N', LEN_FLOAT,   2},
		{"LEVEL13",    'N', LEN_FLOAT,   2},
		{"FREQ14",     'N', LEN_FLOAT,   2},
		{"LEVEL14",    'N', LEN_FLOAT,   2},
		{"FREQ15",     'N', LEN_FLOAT,   2},
		{"LEVEL15",    'N', LEN_FLOAT,   2},
		{"FREQ16",     'N', LEN_FLOAT,   2},
		{"LEVEL16",    'N', LEN_FLOAT,   2},
		{"FREQ17",     'N', LEN_FLOAT,   2},
		{"LEVEL17",    'N', LEN_FLOAT,   2},
		{"FREQ18",     'N', LEN_FLOAT,   2},
		{"LEVEL18",    'N', LEN_FLOAT,   2},
		{"FREQ19",     'N', LEN_FLOAT,   2},
		{"LEVEL19",    'N', LEN_FLOAT,   2},
		{"FREQ20",     'N', LEN_FLOAT,   2},
		{"LEVEL20",    'N', LEN_FLOAT,   2}
	};
	BOOL bCreateIndex = FALSE;
	CString pathName;
	int idx;
	int err;

	pathName.Format("%s/%s", dir, FN_MICCAL_DBF);
	if ((err = DBOpen(g_oPcserve, pathName)) != 0) {
		if (err == ERROR_DB_NOFILE) {
			if ((err = DBCreate(g_oPcserve, pathName, fieldInf, sizeof(fieldInf) / sizeof(DBF_I))) != 0) {
				ErrorMessage(@"IDS_ERR_CREATEMICCAL", err);
				return FALSE;
			}
			bCreateIndex = TRUE;
		} else {
			ErrorMessage(@"IDS_ERR_OPENMICCAL", err);
			return FALSE;
		}
	}

	pathName.Format("%s/%s", dir, FN_MICCAL1_EDX);
	if (bCreateIndex || DBIndex(pathName, &idx) != 0) {
		if ((err = DBIdxCreate(pathName, "MICCALID", 1, &idx)) != 0) {
			ErrorMessage(@"IDS_ERR_CREATEMICCALINDEX", err);
			return FALSE;
		}
	}

	return TRUE;
}

BOOL CDbMicCal::GetNewID(int *pID)
{
	DbMicCalBuf dbBuf;
	char szID[LEN_ID + 1];
	int err;

	DBBottom();
	if ((err = DBRead(&dbBuf)) == 0) {
		memcpy(szID, dbBuf.aMicCalID, LEN_ID);
		szID[LEN_ID] = '\0';
		*pID = atoi(szID) + 1;
	} else if (err == ERROR_DB_EOF)
		*pID = 0;
	else {
		ErrorMessage(@"IDS_ERR_READMICCAL", err);
		return FALSE;
	}

	return TRUE;
}

BOOL CDbMicCal::ReadRecID(int id, DbMicCalRec *pDbRec)
{
	DbMicCalBuf dbBuf;
	CString strID;
	int find;
	int err;

	MakeStrID(id, strID);
	if ((err = DBReadKey(strID, LEN_ID, &dbBuf, 0, &find)) != 0) {
		ErrorMessage(@"IDS_ERR_READMICCAL", err);
		return FALSE;
	}

	if (find == 0)
		return FALSE;

	DBGetFieldBuf(&dbBuf, pDbRec);

	return TRUE;
}

BOOL CDbMicCal::ReadRecNext(DbMicCalRec *pDbRec)
{
	DbMicCalBuf dbBuf;
	CString strID;
	int nRead;
	int err;

	if ((err = DBReadNext(1, &dbBuf, &nRead)) != 0) {
		ErrorMessage(@"IDS_ERR_READMICCAL", err);
		return FALSE;
	}

	if (nRead != 1)
		return FALSE;

	DBGetFieldBuf(&dbBuf, pDbRec);

	return TRUE;
}

BOOL CDbMicCal::StoreRec(DbMicCalRec *pDbRec)
{
	DbMicCalBuf dbBuf;
	int err;

	DBSetFieldBuf(&dbBuf, pDbRec);
	if ((err = DBStore(&dbBuf)) != 0) {
		ErrorMessage(@"IDS_ERR_WRITEMICCAL", err);
		return FALSE;
	}

	return TRUE;
}

BOOL CDbMicCal::UpdateRec(DbMicCalRec *pDbRec)
{
	DbMicCalBuf dbBuf;
	int err;

	DBSetFieldBuf(&dbBuf, pDbRec);
	if ((err = DBUpdateKey(dbBuf.aMicCalID, LEN_ID, &dbBuf)) != 0) {
		if (err != 3006 || (err = DBStore(&dbBuf)) != 0) {
			ErrorMessage(@"IDS_ERR_WRITEMICCAL", err);
			return FALSE;
		}
	}

	return TRUE;
}

BOOL CDbMicCal::DeleteID(int id)
{
	CString strID;
	int err;

	MakeStrID(id, strID);
	if ((err = DBDeleteKey(strID, LEN_ID, 1)) != 0) {
		ErrorMessage(@"IDS_ERR_DELETEMICCAL", err);
		return FALSE;
	}

	return TRUE;
}

BOOL CDbMicCal::SearchRecID(int id)
{
	CString strID;
	int find;
	int err;

	MakeStrID(id, strID);
	if ((err = DBSearch2(strID, LEN_ID, &find)) != 0)
		return FALSE;

	if (find != 1)
		return FALSE;

	return TRUE;
}

BOOL CDbWaveForm::Open(LPCTSTR dir)
{
	static DBF_I fieldInf[] = {
		{"WAVEFORMID", 'I', LEN_ID,    0},
		{"SMOOTHFLAG", 'I', LEN_BOOL,  0},
		{"DATANUM",    'I', LEN_WAVEFORMNUM, 0},
		{"DATA",       'B', 0, 0}
	};
	BOOL bCreateIndex = FALSE;
	CString pathName;
	int idx;
	int err;

	pathName.Format("%s/%s", dir, FN_WAVEFORM_DBF);
	if ((err = DBOpen(g_oPcserve, pathName)) != 0) {
		if (err == ERROR_DB_NOFILE) {
			if ((err = DBCreate(g_oPcserve, pathName, fieldInf, sizeof(fieldInf) / sizeof(DBF_I))) != 0) {
				ErrorMessage(@"IDS_ERR_CREATEWAVEFORM", err);
				return FALSE;
			}
			bCreateIndex = TRUE;
		} else {
			ErrorMessage(@"IDS_ERR_OPENWAVEFORM", err);
			return FALSE;
		}
	}

	pathName.Format("%s/%s", dir, FN_WAVEFORM1_EDX);
	if (bCreateIndex || DBIndex(pathName, &idx) != 0) {
		if ((err = DBIdxCreate(pathName, "WAVEFORMID", 1, &idx)) != 0) {
			ErrorMessage(@"IDS_ERR_CREATEWAVEFORMINDEX", err);
			return FALSE;
		}
	}

	return TRUE;
}

BOOL CDbWaveForm::ReadRecID(int id, DbWaveFormRec *pDbRec, WaveFormData *pWaveFormData)
{
	DbWaveFormBuf dbBuf;
	CString strID;
	int find;
	int nRead;
	int err;

	MakeStrID(id, strID);
	if ((err = DBReadKey(strID, LEN_ID, &dbBuf, 0, &find)) != 0) {
		if (err != 3006)
			ErrorMessage(@"IDS_ERR_READWAVEFORM", err);
		return FALSE;
	}

	if (find == 0)
		return FALSE;

	DBGetFieldBuf(&dbBuf, pDbRec);

	int nDataSize;
	switch (pDbRec->nDataNum) {
	case 1000:	// FM音源
		nDataSize = sizeof(float) * 2;
		break;
	default:
		nDataSize = sizeof(WaveFormData) * pDbRec->nDataNum;
		break;
	}

	if ((err = DBReadBinary("DATA", pWaveFormData, nDataSize, &nRead)) != 0) {
		ErrorMessage(@"IDS_ERR_READWAVEFORM", err);
		return FALSE;
	}

	return TRUE;
}

BOOL CDbWaveForm::WriteRec(DbWaveFormRec *pDbRec, WaveFormData *pWaveFormData)
{
	DbWaveFormBuf dbBuf;
	CString strID;
	int find;
	int err;

	DBSetFieldBuf(&dbBuf, pDbRec);

	DBSearch2(dbBuf.aWaveFormID, LEN_ID, &find);
	if (find != 1) {
		if ((err = DBStore(&dbBuf)) != 0) {
			ErrorMessage(@"IDS_ERR_WRITEWAVEFORM", err);
			return FALSE;
		}
	} else {
		if ((err = DBUpdateKey(dbBuf.aWaveFormID, LEN_ID, &dbBuf)) != 0) {
			ErrorMessage(@"IDS_ERR_WRITEWAVEFORM", err);
			return FALSE;
		}
	}

	int nDataSize;
	switch (pDbRec->nDataNum) {
	case 1000:	// FM音源
		nDataSize = sizeof(float) * 2;
		break;
	default:
		nDataSize = sizeof(WaveFormData) * pDbRec->nDataNum;
		break;
	}

	if ((err = DBWriteBinary("DATA", pWaveFormData, nDataSize)) != 0) {
		ErrorMessage(@"IDS_ERR_WRITEWAVEFORM", err);
		return FALSE;
	}

	return TRUE;
}
*/
void DeleteFolder(int nFolderID)
{
	CDbFolder dbFolder;
	DbFolderBuf dbFolderBuf;
	CDbImpulse dbImpulse;
	DbImpulseRec dbImpulseRec;
	CDbAcParam dbAcParam;
//	CDbAcf dbAcf;
//	DbAcfRec dbAcfRec;
//	CDbAcfFactor dbAcfFactor;
	CString strFolderID;
	CString strDataID;
	CString select;
	int find;
	int i;
	int nRec;

	if (!dbFolder.Open())
		return;

	MakeStrID(nFolderID, strFolderID);
	if (dbFolder.DBReadKey(strFolderID, LEN_ID, &dbFolderBuf, 0, &find) != 0 || find == 0) {
		ErrorMessage(@"IDS_ERR_FINDFOLDER");
		return;
	}

	if (dbFolder.DBDeleteKey(strFolderID, LEN_ID, 0) != 0) {
		ErrorMessage(@"IDS_ERR_DELETEFOLDER");
		return;
	}

	switch (dbFolderBuf.aType[0]) {
	case FOLDER_TYPE_IR:
		if (!dbImpulse.Open())
			return;

		if (!dbAcParam.Open())
			return;

		select.Format("#%d=%ld", dbImpulse.m_nIdxFolderID, nFolderID);
		if (dbImpulse.DBSelect(select, &nRec) == 0) {
			for (i = 0; i < nRec; i++) {
				if (!dbImpulse.ReadRecNext(&dbImpulseRec))
					break;
				MakeStrID(dbImpulseRec.nImpulseID, strDataID);
				dbAcParam.DBDeleteKey(strDataID, LEN_ID, 1);
			}
		}
		dbImpulse.DBSelect(NULL, &nRec);

		if (dbImpulse.DBChgIdx(dbImpulse.m_nIdxFolderID) != 0) {
			ErrorMessage(@"IDS_ERR_DELETEIRDATA");
			return;
		}

		if (dbImpulse.DBDeleteKey(strFolderID, LEN_ID, 1) != 0) {
			ErrorMessage(@"IDS_ERR_DELETEIRDATA");
			return;
		}
		break;
/*
	case FOLDER_TYPE_ACF:
		if (!dbAcf.Open())
			return;

		if (!dbAcfFactor.Open())
			return;

		select.Format("#%d=%ld", dbAcf.m_nIdxFolderID, nFolderID);
		if (dbAcf.DBSelect(select, &nRec) == 0) {
			for (i = 0; i < nRec; i++) {
				if (!dbAcf.ReadRecNext(&dbAcfRec))
					break;
				MakeStrID(dbAcfRec.nAcfID, strDataID);
				dbAcfFactor.DBDeleteKey(strDataID, LEN_ID, 1);
			}
		}
		dbAcf.DBSelect(NULL, &nRec);

		if (dbAcf.DBChgIdx(dbAcf.m_nIdxFolderID) != 0) {
			ErrorMessage(@"IDS_ERR_DELETEIRDATA");
			return;
		}

		if (dbAcf.DBDeleteKey(strFolderID, LEN_ID, 1) != 0) {
			ErrorMessage(@"IDS_ERR_DELETEIRDATA");
			return;
		}
		break;
*/
	default:
		return;
	}
}

void DeleteImpulse(int nImpulseID)
{
	CDbImpulse dbImpulse;
	CDbAcParam dbAcParam;
	CString strImpulseID;

	if (!dbImpulse.Open())
		return;

	MakeStrID(nImpulseID, strImpulseID);
	if (dbImpulse.DBChgIdx(dbImpulse.m_nIdxImpulseID) != 0) {
		ErrorMessage(@"IDS_ERR_DELETEIRDATA");
		return;
	}

	if (dbImpulse.DBDeleteKey(strImpulseID, LEN_ID, 1) != 0) {
		ErrorMessage(@"IDS_ERR_DELETEIRDATA");
		return;
	}

	if (!dbAcParam.Open())
		return;

	dbAcParam.DBDeleteKey(strImpulseID, LEN_ID, 1);
}
/*
void DeleteAcf(int nAcfID)
{
	CDbAcf dbAcf;
	CDbAcfFactor dbAcfFactor;
	CString strAcfID;

	if (!dbAcf.Open())
		return;

	MakeStrID(nAcfID, strAcfID);
	if (dbAcf.DBChgIdx(dbAcf.m_nIdxAcfID) != 0) {
		ErrorMessage(@"IDS_ERR_DELETEIRDATA");
		return;
	}

	if (dbAcf.DBDeleteKey(strAcfID, LEN_ID, 1) != 0) {
		ErrorMessage(@"IDS_ERR_DELETEIRDATA");
		return;
	}

	if (!dbAcfFactor.Open())
		return;

	dbAcfFactor.DBDeleteKey(strAcfID, LEN_ID, 1);
}
*/
CString FormatTime(const CString &src)
{
	CString dst;

	switch (src.GetLength()) {
	case 8:		// 日付のみ
		dst = src.Left(4) + "/" + src.Mid(4, 2) + "/" + src.Mid(6, 2);
		break;
	case 14:	// 日付＋時刻
		dst = src.Left(4) + "/" + src.Mid(4, 2) + "/" + src.Mid(6, 2) + " " +
				src.Mid(8, 2) + ":" + src.Mid(10, 2) + ":" + src.Mid(12, 2);
	}

	return dst;
}

CString UnformatTime(const CString &src)
{
	CString dst;

	switch (src.GetLength()) {
	case 10:		// 日付のみ
		dst = src.Left(4) + src.Mid(5, 2) + src.Mid(8, 2);
		break;
	case 19:		// 日付＋時刻
		dst = src.Left(4) + src.Mid(5, 2) + src.Mid(8, 2) +
				src.Mid(11, 2) + src.Mid(14, 2) + src.Mid(17, 2);
		break;
	}

	return dst;
}

static void ErrorMessage(NSString *msgID, int err)
{
	NSString *msg = NSLocalizedString(msgID, nil);
	if (err != 0)
		msg = [NSString stringWithFormat:@"%@ (Error=%d)", msg, err];

	MessageBox(nil, @"Alert", msg, @"OK", nil, FALSE, nil, nil, FALSE);
}

static void MakeStrID(int id, CString &strID)
{
	strID.Format("%8ld", id);
}
