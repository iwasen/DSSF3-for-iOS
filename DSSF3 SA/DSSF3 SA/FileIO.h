#pragma once

#import "PCSCL.h"

// フォルダファイル名
#define FN_FOLDER_DBF	"FOLDER.DBF"
#define FN_FOLDER1_EDX	"FOLDER1.EDX"

// インパルス応答測定データファイル名
#define FN_IMPULSE_DBF	"IMPULSE.DBF"
#define FN_IMPULSE_BIN	"IMPULSE.BIN"
#define FN_IMPULSE1_EDX	"IMPULSE1.EDX"
#define FN_IMPULSE2_EDX	"IMPULSE2.EDX"

// Running ACF 測定データファイル
#define FN_ACF_DBF		"ACF.DBF"
#define FN_ACF_BIN		"ACF.BIN"
#define FN_ACF1_EDX		"ACF1.EDX"
#define FN_ACF2_EDX		"ACF2.EDX"

// 音響パラメータ計算結果ファイル名
#define FN_ACPARAM_DBF	"ACPARAM.DBF"
#define FN_ACPARAM1_EDX	"ACPARAM1.EDX"

// Running ACF 計算結果ファイル名
#define FN_ACFFACT_DBF	"ACFFACT.DBF"
#define FN_ACFFACT1_EDX	"ACFFACT1.EDX"

// 逆フィルタファイル名
#define FN_IFILTER_DBF	"IFILTER.DBF"
#define FN_IFILTER1_EDX	"IFILTER1.EDX"

// マイク較正ファイル名
#define FN_MICCAL_DBF	"MICCAL.DBF"
#define FN_MICCAL1_EDX	"MICCAL1.EDX"

// プリセットファイル名
#define FN_PRESET_DBF	"PRESET5.DBF"
#define FN_PRESET_BIN	"PRESET5.BIN"
#define FN_PRESET1_EDX	"PRESET5.EDX"

// 波形データファイル名
#define FN_WAVEFORM_DBF	"WAVEFORM.DBF"
#define FN_WAVEFORM_BIN	"WAVEFORM.BIN"
#define FN_WAVEFORM1_EDX	"WAVEFORM1.EDX"

// テンポラリファイル名
#define FN_TEMP_DBF		"TEMP.DBF"
#define FN_TEMP_BIN		"TEMP.BIN"

// フォルダタイプ
#define FOLDER_TYPE_IR	'I'		// インパルス応答
#define FOLDER_TYPE_ACF	'A'		// Running ACF

#define ACPARAM_NFREQ	34		// 音響パラメータ周波数帯域別データ数
#define MICCAL_NFREQ	20		// マイク較正周波数データ数

// データベースフィールド長
#define LEN_ID			8		// ＩＤ
#define LEN_TYPE		1		// フォルダタイプ
#define LEN_TITLE		30		// タイトル
#define LEN_NAME		20		// 測定者氏名
#define LEN_PLACE		20		// 測定場所
#define LEN_DATE		8		// 作成日付
#define LEN_COMMENT		100		// コメント
#define LEN_SAMPLING	6		// サンプリングレート
#define LEN_MESTIME		2		// インパルス応答測定時間
#define LEN_MESNUM		3		// インパルス応答同期加算回数
#define LEN_CHANNEL		1		// サンプリングチャネル数
#define LEN_BIT			2		// サンプリングビット数
#define LEN_TIME		14		// 測定日時
#define LEN_MULTIPLIER	5		// インパルス応答出力レベル倍率
#define LEN_NDATA		2		// 音響パラメータデータ数
#define LEN_FREQBAND	1		// 周波数帯域（1Oct,1/3Oct)
#define LEN_FLOAT		8		// 浮動小数データ
#define LEN_BOOL		1		// BOOL データ
#define LEN_SHORT		6		// short データ
#define LEN_RESERVE		8		// リザーブ
#define LEN_MICINFO		30		// マイク情報（マイク較正）
#define LEN_MICAMPINFO	30		// マイクアンプ情報（マイク較正）
#define LEN_MAXLEVEL	3		// 逆フィルタ最大補償レベル
#define LEN_SIZE		5		// データサイズ
#define LEN_NACFFACT	4		// Running ACF 計算結果データ数
#define LEN_SAMPLENUM	10		// Running ACF サンプリングデータ数
#define	LEN_WAVEFORMNUM	4		// 波形データ個数

#pragma pack(4)

// フォルダファイルバッファ
struct DbFolderBuf {
	char	aFolderID[LEN_ID];
	char	aType[LEN_TYPE];
	char	aName[LEN_NAME];
	char	aPlace[LEN_PLACE];
	char	aDate[LEN_DATE];
	char	aTitle[LEN_TITLE];
	char	aComment[LEN_COMMENT];
	char	aScale[LEN_FLOAT];
};

// フォルダファイルレコード
struct DbFolderRec {
	int	nFolderID;
	CString	sType;
	CString	sName;
	CString	sPlace;
	CString	sDate;
	CString	sTitle;
	CString	sComment;
	float fScale;
};

// インパルス応答測定データファイルバッファ
struct DbImpulseBuf {
	char	aFolderID[LEN_ID];
	char	aImpulseID[LEN_ID];
	char	aSampling[LEN_SAMPLING];
	char	aMeasTime[LEN_MESTIME];
	char	aMeasNum[LEN_MESNUM];
	char	aChannel[LEN_CHANNEL];
	char	aBit[LEN_BIT];
	char	aTime[LEN_TIME];
	char	aTitle[LEN_TITLE];
	char	aComment[LEN_COMMENT];
	char	aUseFilter[LEN_BOOL];
	char	aIFilterID[LEN_ID];
	char	aTemperature[LEN_FLOAT];
	char	aHumidity[LEN_FLOAT];
	char	aMultiplier[LEN_MULTIPLIER];
};

// インパルス応答測定データファイルレコード
struct DbImpulseRec {
	int	nFolderID;
	int	nImpulseID;
	int	nSampling;
	int	nMeasTime;
	int	nMeasNum;
	int	nChannel;
	int	nBit;
	CString	sTime;
	CString sTitle;
	CString	sComment;
	int	nUseFilter;
	int	nIFilterID;
	float	fTemperature;
	float	fHumidity;
	int	nMultiplier;
	int	bImpulseData;
};

// Running ACF 測定データファイルバッファ
struct DbAcfBuf {
	char	aFolderID[LEN_ID];
	char	aAcfID[LEN_ID];
	char	aSampling[LEN_SAMPLING];
	char	aChannel[LEN_CHANNEL];
	char	aSampleNum[LEN_SAMPLENUM];
	char	aDataTime[LEN_FLOAT];
	char	aTime[LEN_TIME];
	char	aTitle[LEN_TITLE];
	char	aComment[LEN_COMMENT];
};

// Running ACF 測定データファイルレコード
struct DbAcfRec {
	int	nFolderID;
	int	nAcfID;
	int	nSampling;
	int	nChannel;
	int	nSampleNum;
	float	fDataTime;
	CString	sTime;
	CString sTitle;
	CString	sComment;
};

// 音響パラメータ計算条件
struct DbAcParamCond {
	int	nFreqBand;
	int	bAFilter;
	int	nSplRefData;
	Float64	fSplRefLevel;
	Float64	fDT1MinTime;
	Float64	fTsubEnd;
	int	bTsubAuto;
	Float64	fTsubNoise;
	Float64	fWIACCLevel;
	Float64	fPrefSPL;
	Float64	fPrefTauE;
	Float64	fGRefData;
	Float64	fTCustom1;
	Float64	fTCustom2;
	Float64	fCCustom;
};

// 音響パラメータ計算結果データ
struct DbAcParamResult {
	Float64	fDeltaT0L;
	Float64	fDeltaT0R;
	Float64	fDeltaT1L;
	Float64	fDeltaT1R;
	Float64	fSTI_L;
	Float64	fSTI_R;
	Float64	fSTIM_L;
	Float64	fSTIM_R;
	Float64	fSTIF_L;
	Float64	fSTIF_R;
	Float64	fRASTI_L;
	Float64	fRASTI_R;
};

// 音響パラメータ帯域別計算結果データ
struct DbAcParamData {
	int	nFreq;
	Float64	fSplL;
	Float64	fSplR;
	Float64	fAL;
	Float64	fAR;
	Float64	tSubL;
	Float64	tSubR;
	Float64	fIACC;
	Float64	tIACC;
	Float64	wIACC;
	Float64	fG_L;
	Float64	fG_R;
	Float64	fT20_L;
	Float64	fT20_R;
	Float64	fT30_L;
	Float64	fT30_R;
	Float64	fTCustom_L;
	Float64	fTCustom_R;
	Float64	fEDT_L;
	Float64	fEDT_R;
	Float64	fC50_L;
	Float64	fC50_R;
	Float64	fC80_L;
	Float64	fC80_R;
	Float64	fCCustom_L;
	Float64	fCCustom_R;
	Float64	fD50_L;
	Float64	fD50_R;
	Float64	fTs_L;
	Float64	fTs_R;
	Float64	fIACCE;
	Float64	fIACCL;
};

// 音響パラメータ計算結果ファイルバッファ
struct DbAcParamBuf {
	char	aImpulseID[LEN_ID];
	char	aConditionSize[LEN_SIZE];
	char	aDataSize[LEN_SIZE];
	char	aDataNum[LEN_NDATA];
};

// 音響パラメータ計算結果ファイルレコード
struct DbAcParamRec {
	int	nImpulseID;
	int	nConditionSize;
	int	nDataSize;
	int	nDataNum;
	DbAcParamCond dbAcParamCond;
	DbAcParamResult dbAcParamResult;
	DbAcParamData dbAcParamData[ACPARAM_NFREQ];
};
/*
// Running ACF 計算結果ファイルバッファ
struct DbAcfFactorBuf {
	char	aAcfID[LEN_ID];
	char	aConditionSize[LEN_SIZE];
	char	aFactorSize[LEN_SIZE];
	char	aAcfFactor[LEN_NACFFACT];
};

// Running ACF 計算結果ファイルレコード
struct DbAcfFactorRec {
	int	nAcfID;
	int	nConditionSize;
	int	nFactorSize;
	int	nAcfFactor;
};

// Running ACF 計算条件データ（共通部）
struct AcfCondition {
	float fIntegrationTime;
	float fRunningStep;
	int nFreqWeighting;
	float fMaxDelayTime;
	int nPhi0RefData;
	float fPhi0RefLevel;
	float fTaueInterval;
	float fTaueEndLevel;
	float fTaueEndTime;
	short bTaueOrigin;
	short nTau1Peak;
};

// Running IACF 計算条件データ（共通部）
struct IAcfCondition {
	float fIACCWLevel;
};

// Running ACF 計算条件データ
struct AcfConditionData {
	int	nStartPos;
	int	nDataNum;
	AcfCondition AcfCondition;
	IAcfCondition IAcfCondition;
};

// Running ACF 計算結果データ
struct AcfFactor {
	float	fPhi0;
	float	fTauE;
	float	fTau1;
	float	fPhi1;
	float	fTauE0;
};

// Running IACF 計算結果データ
struct IAcfFactor {
	float	fSPL;
	float	fIACC;
	float	fTauIACC;
	float	fWIACC;
	float	fWIACC1;
};

// ACF,IACF計算結果データ
struct AllFactorData {
	AcfFactor	Acf;
	IAcfFactor	IAcf;
};
typedef struct AllFactorData AcfFactorData;
typedef struct AllFactorData NmsFactorData;

// τn, φn 計算結果データ
struct TaunPhinData {
	float	fTaun[10];
	float	fPhin[10];
};

// マイク周波数特性データ
struct MicFreq {
	float	freq;
	float	level;
};

// 逆フィルタファイルバッファ
struct DbIFilterBuf {
	char	aIFilterID[LEN_ID];
	char	aTitle[LEN_TITLE];
	char	aComment[LEN_COMMENT];
	char	aSampling[LEN_SAMPLING];
	char	aStartPos[LEN_FLOAT];
	char	aEndPos[LEN_FLOAT];
	char	aMaxLevel[LEN_MAXLEVEL];
	char	aPhaseAdj[LEN_BOOL];
};

// 逆フィルタファイルレコード
struct DbIFilterRec {
	int	nIFilterID;
	CString	sTitle;
	CString	sComment;
	int	nSampling;
	float	fStartPos;
	float	fEndPos;
	int	nMaxLevel;
	int	nPhaseAdj;
};

// マイク較正ファイルバッファ
struct DbMicCalBuf {
	char	aMicCalID[LEN_ID];
	char	aMicInfo[LEN_MICINFO];
	char	aMicAmpInfo[LEN_MICAMPINFO];
	char	aComment[LEN_COMMENT];
	char	aInputSens[LEN_FLOAT];
	char	aInputSel[LEN_SHORT];
	char	aInputVol[LEN_SHORT];
	char	aFreqData[LEN_SHORT];
	struct	{
		char	aFreq[LEN_FLOAT];
		char	aFevel[LEN_FLOAT];
	} aFreq[MICCAL_NFREQ];
};

// マイク較正ファイルレコード
struct DbMicCalRec {
	int	nMicCalID;
	CString	sMicInfo;
	CString	sMicAmpInfo;
	CString	sComment;
	float fInputSens;
	int nInputSel;
	int nInputVol;
	int nFreqData;
	MicFreq aFreq[MICCAL_NFREQ];
};

// 波形データファイルバッファ
struct DbWaveFormBuf {
	char	aWaveFormID[LEN_ID];
	char	aSmoothFlag[LEN_BOOL];
	char	aDataNum[LEN_WAVEFORMNUM];
};

// 波形データファイルレコード
struct DbWaveFormRec {
	int	nWaveFormID;
	int	nSmoothFlag;
	int	nDataNum;
};

// 波形データ
struct WaveFormData {
	float	x;
	float	y;
};
*/
#pragma pack()

extern char g_szDefaultDir[];
extern class CMyPcserve g_oPcserve;

// PCSERVE クラス
class CMyPcserve : public CPcserve
{
public:
	void Initialize();
};

// フォルダファイルクラス
class CDbFolder : public CPSDB
{
public:
	BOOL Open(LPCTSTR dir = g_szDefaultDir);
	BOOL GetNewID(int *pID);
	BOOL ReadRecID(int id, DbFolderRec *pDbRec);
	BOOL ReadRecNext(DbFolderRec *pDbRec);
	BOOL StoreRec(DbFolderRec *pDbRec);
	BOOL UpdateRec(DbFolderRec *pDbRec);
};

// インパルス応答測定データファイルクラス
class CDbImpulse : public CPSDB
{
public:
	BOOL Open(LPCTSTR dir = g_szDefaultDir);
	BOOL GetNewID(int *pImpulseID);
	BOOL ReadRecID(int id, DbImpulseRec *pDbRec);
	BOOL ReadRecNext(DbImpulseRec *pDbRec);
	BOOL StoreRec(DbImpulseRec *pDbRec);
	BOOL UpdateRec(DbImpulseRec *pDbRec);

	int m_nIdxFolderID;
	int m_nIdxImpulseID;
};
/*
// Runnning ACF 測定データファイルクラス
class CDbAcf : public CPSDB
{
public:
	BOOL Open(LPCTSTR dir = g_szDefaultDir);
	BOOL GetNewID(int *pAcfID);
	BOOL ReadRecID(int id, DbAcfRec *pDbRec);
	BOOL ReadRecNext(DbAcfRec *pDbRec);
	BOOL StoreRec(DbAcfRec *pDbRec);
	BOOL UpdateRec(DbAcfRec *pDbRec);

	int m_nIdxFolderID;
	int m_nIdxAcfID;
};
*/
// 音響パラメータ計算結果ファイルクラス
class CDbAcParam : public CPSDB
{
public:
	BOOL Open(LPCTSTR dir = g_szDefaultDir);
	BOOL ReadRecID(int id, DbAcParamRec *pDbRec);
	BOOL SearchID(int id, BOOL bDispErr = YES);
	BOOL StoreRec(DbAcParamRec *pDbRec);
	BOOL UpdateRec(DbAcParamRec *pDbRec);
};
/*
// Running ACF 計算結果ファイルクラス
class CDbAcfFactor : public CPSDB
{
public:
	BOOL Open(LPCTSTR dir = g_szDefaultDir);
	BOOL ReadRecID(int id, DbAcfFactorRec *pDbRec,
			AcfConditionData *pAcfConditionData = NULL, AcfFactorData **pAcfFactorData = NULL, TaunPhinData **pTaunPhinData = NULL);
	BOOL SearchID(int id);
	BOOL StoreRec(DbAcfFactorRec *pDbRec);
	BOOL UpdateRec(DbAcfFactorRec *pDbRec);
};

// 逆フィルタファイルクラス
class CDbIFilter : public CPSDB
{
public:
	BOOL Open(LPCTSTR dir = g_szDefaultDir);
	BOOL GetNewID(int *pID);
	BOOL ReadRecID(int id, DbIFilterRec *pDbRec);
	BOOL ReadRecNext(DbIFilterRec *pDbRec);
	BOOL StoreRec(DbIFilterRec *pDbRec);
	BOOL UpdateRec(DbIFilterRec *pDbRec);
	BOOL DeleteID(int id);
};

// マイク較正ファイルクラス
class CDbMicCal : public CPSDB
{
public:
	BOOL Open(LPCTSTR dir = g_szDefaultDir);
	BOOL GetNewID(int *pID);
	BOOL ReadRecID(int id, DbMicCalRec *pDbRec);
	BOOL ReadRecNext(DbMicCalRec *pDbRec);
	BOOL StoreRec(DbMicCalRec *pDbRec);
	BOOL UpdateRec(DbMicCalRec *pDbRec);
	BOOL DeleteID(int id);
	BOOL SearchRecID(int id);
};

// 波形データファイルクラス
class CDbWaveForm : public CPSDB
{
public:
	BOOL Open(LPCTSTR dir = g_szDefaultDir);
	BOOL ReadRecID(int id, DbWaveFormRec *pDbRec, WaveFormData *pWaveFormData);
	BOOL WriteRec(DbWaveFormRec *pDbRec, WaveFormData *pWaveFormData);
};
*/
extern void DeleteFolder(int nFolderID);
extern void DeleteImpulse(int nImpulseID);
//extern void DeleteAcf(int nAcfID);
extern CString FormatTime(const CString &src);
extern CString UnformatTime(const CString &src);
/*
extern void ReadNsWeightData(NsWeightData *pNsWeightData);
extern void WriteNsWeightData(const NsWeightData *pNsWeightData);
extern void ImportIR(LPCTSTR pDir);
extern void ImportACF(LPCTSTR pDir);
*/
