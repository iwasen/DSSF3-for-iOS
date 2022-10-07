// FileIO.cpp : インプリメンテーション ファイル
//

#import <UIKit/UIKit.h>
#import "FileIO.h"
#import "Global.h"

char g_szDefaultDir[256];
CMyPcserve g_oPcserve;

static void ErrorMessage(NSString *msgID, int err = 0);
static void MakeStrID(int id, CString &strID);

void CMyPcserve::Initialize()
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *path = [paths objectAtIndex:0];
	strcpy(g_szDefaultDir, [path UTF8String]);

	Connect(0, NULL, "");
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
