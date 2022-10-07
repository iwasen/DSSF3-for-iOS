#pragma once

#import "PCSCL.h"

// マイク較正ファイル名
#define FN_MICCAL_DBF	"MICCAL.DBF"
#define FN_MICCAL1_EDX	"MICCAL1.EDX"

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

// マイク周波数特性データ
struct MicFreq {
	float	freq;
	float	level;
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

#pragma pack()

extern char g_szDefaultDir[];
extern class CMyPcserve g_oPcserve;

// PCSERVE クラス
class CMyPcserve : public CPcserve
{
public:
	void Initialize();
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

