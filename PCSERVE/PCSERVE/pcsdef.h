/************************************************************************
 *
 *			ＰＣ−ＳＥＲＶＥ
 *
 *		名称		: 共通定義
 *		ファイル名	: pcsdef.h
 *		作成者		: s.aizawa
 *
 ************************************************************************/

typedef	unsigned int	ULONG;
typedef	short			SHORT;
typedef	unsigned short	USHORT;
typedef	char		CHAR;
typedef	unsigned char	UCHAR;
typedef	char	*FPCHAR;
typedef	short	*FPSHORT;
typedef	unsigned short *FPUSHORT;
#define	VOID	void
typedef	void	*FPVOID;
typedef int PSBOOL;
typedef int LONG;
typedef long long LONG64;
typedef int HANDLE;
typedef unsigned int DWORD;
typedef unsigned int UINT;

#define	TRUE	1
#define	FALSE	0

#define max(a,b) ((a) > (b) ? (a) : (b))
#define min(a,b) ((a) < (b) ? (a) : (b))

//	チャネル種別
#define	CHT_LOCAL	0
#define	CHT_TCPIP	1
#define	CHT_NETBIOS	2
#define	CHT_RS232C	3

//	ファイルロック種別
#define	LOCK_FILE		0
#define	LOCK_RECORD		1
#define	LOCK_FILE_WRITE		0
#define	LOCK_RECORD_WRITE	1
#define	LOCK_FILE_READ		2
#define	LOCK_RECORD_READ	3

// アクセス許可モード
#define PERMISSION_NONE		0x00
#define PERMISSION_READ		0x01
#define PERMISSION_WRITE	0x02
#define PERMISSION_ALL		0xff

//	エラーコード
#define	NORMAL		0
#define	ERROR_PCS_START			1000
#define	ERROR_PCS_END			4999
#define	ERROR_SERVER			1000	/* サーバ上のエラー */
#define	ERROR_SERVER_MEMORY		1001	/* サーバでメモリ確保失敗 */
#define	ERROR_SERVER_MAXFILES	1002	/* 最大オープン数オーバ */
#define	ERROR_SERVER_SEND		1003	/* サーバで送信エラー */
#define	ERROR_SERVER_RECEIVE	1004	/* サーバで受信エラー */
#define	ERROR_SERVER_NOSUPPORT	1005	/* 未サポート */
#define	ERROR_SERVER_MAXCONNECT	1006	/* コネクト数オーバ */
#define	ERROR_SERVER_CONNECT	1007	/* 二重化の相手のサーバに接続できない*/
#define	ERROR_SERVER_DUPLEX		1008	/* 二重化スレーブサーバ */
#define	ERROR_SERVER_MULTI		1009	/* 分散サーバエラー */
#define	ERROR_SERVER_LICENSE	1010	/* ライセンスが有効でない */

#define	ERROR_CLIENT_MEMORY		2001	/* クライアントでメモリ確保失敗 */
#define	ERROR_CLIENT_SEND		2002	/* クライアントで送信エラー */
#define	ERROR_CLIENT_RECEIVE	2003	/* クライアントで受信エラー */
#define	ERROR_CLIENT_NOHOST		2004	/* ホストが存在しない */
#define	ERROR_CLIENT_SOCKET		2005	/* socket() エラー */
#define	ERROR_CLIENT_CONNECT	2006	/* connect() エラー */
#define	ERROR_CLIENT_NOSUPPORT	2007	/* 未サポート */
#define	ERROR_CLIENT_PARAMETER	2008	/* パラメータエラー */
#define	ERROR_CLIENT_BUSY		2009	/* 話し中 */
#define	ERROR_CLIENT_NOCARRIER	2010	/* キャリア断 */
#define	ERROR_CLIENT_MODEM		2011	/* モデムの応答が無い */
#define	ERROR_CLIENT_CCB		2012	/* CCB が正しくない */
#define	ERROR_CLIENT_MAXCONNECT	2013	/* コネクト数オーバ */
#define	ERROR_CLIENT_WINSOCK	2014	/* winsock.dll がロードできない */
#define	ERROR_CLIENT_NOTCONNECT	2015	/* サーバに接続していません */
#define	ERROR_CLIENT_NOTOPEN	2016	/* ファイルをオープンしていません */

#define	ERROR_DB_MEMORY			3001	/* メモリ不足 */
#define	ERROR_DB_FOPEN			3002	/* ファイルオープンエラー */
#define	ERROR_DB_NOFILE			3003	/* オープンするファイルがない */
#define	ERROR_DB_IDXOVER		3004	/* インデックスファイルが多すぎる */
#define	ERROR_DB_TMPFILE		3005	/* テンポラリファイルが作れない */
#define	ERROR_DB_NOKEY			3006	/* 指定されたキーが存在しない */
#define	ERROR_DB_DBLKEY			3007	/* キーが重複している*/
#define	ERROR_DB_RECNO			3008	/* レコード番号が不正 */
#define	ERROR_DB_EOF			3009	/* ＢＯＦまたはＥＯＦ */
#define	ERROR_DB_STRFILE		3010	/* 構造ファイルが正しくない */
#define	ERROR_DB_READ			3011	/* ファイルｒｅａｄエラー */
#define	ERROR_DB_WRITE			3012	/* ファイルｗｒｉｔｅエラー */
#define	ERROR_DB_IDXKEY			3013	/* インデックスのキー表現式が不正 */
#define	ERROR_DB_NOINDEX		3014	/* インデックスされていない */
#define	ERROR_DB_ARDYOPEN		3015	/* 他でオープン中 */
#define	ERROR_DB_LOCK			3016	/* ファイルロック中 */
#define	ERROR_DB_NOSUPPORT		3017	/* 未サポート */
#define	ERROR_DB_PARAMETER		3018	/* パラメータエラー */
#define	ERROR_DB_TIMEOUT		3019	/* タイムアウト */
#define	ERROR_DB_SIZEOVER		3020	/* サイズオーバ */
#define	ERROR_DB_NOOPEN			3021	/* オープンされていない */
#define	ERROR_DB_PASSWORD		3022	/* パスワードが違う */
#define	ERROR_DB_INDEXFILE		3023	/* インデックスファイルが壊れている */
#define	ERROR_DB_FIELD			3024	/* フィールド情報が不正 */
#define	ERROR_DB_BUFSIZE		3025	/* バッファサイズが不足 */

#define	ERROR_SN_PARAMETER		3301	/* パラメータエラー */
#define	ERROR_SN_EXIST			3302	/* 既にキーが存在する */
#define	ERROR_SN_NOTFOUND		3303	/* キーがない */

#define	ERROR_CL_PARAMETER		3401	/* パラメータエラー */
#define	ERROR_CL_NOTFOUND		3402	/* キーがない */

#define	ERROR_MS_PARAMETER		3501	/* パラメータエラー */
#define	ERROR_MS_GRPFILE		3502	/* メッセージグループファイルエラー */
#define	ERROR_MS_BUFSIZE		3503	/* バッファサイズ不足 */

#define	ERROR_EXEC_COMMAND		4001	/* コマンド起動失敗 */
#define	ERROR_DIRNAME			4002	/* ディレクトリ名が登録されていない */
#define	ERROR_FILE_TYPE			4003	/* ファイル種別が違う */
#define	ERROR_FILE_HANDLE		4004	/* ファイルハンドルが不正 */
#define ERROR_FILE_PERMISSION	4005	// アクセスが許可されていない
#define ERROR_USER_PASSWORD		4006	// ユーザ名またはパスワードが不正
#define ERROR_NOLOGIN			4007	// ログインしていない

/*	データファイルフィールド情報	*/
#pragma pack(1)
typedef	struct	_DBF_I	{
	CHAR	name[11];	/* フィールド名 */
	CHAR	type;		/* フィールド形式 */
	SHORT	lField;		/* フィールド長 */
	SHORT	lDec;		/* 小数位桁数 */
} DBF_I;
#pragma pack()

typedef	DBF_I	*PDBF_I;
