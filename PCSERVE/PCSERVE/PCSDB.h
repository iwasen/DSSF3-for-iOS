/************************************************************************
 *
 *			ＰＣ−ＳＥＲＶＥ
 *
 *		名称		: ＩＳＡＭ関連定義
 *		ファイル名	: pcsdb.h
 *		作成者		: s.aizawa
 *
 ************************************************************************/

#define	BLOCK_SIZE	512				// インデックスファイルのブロックサイズ
#define	MAX_IDX		40				// 同時にオープンできるインデックスファイル数
#define	EXT_FIELD	0x1521			// 拡張フィールド
#define	FLAG_FREEBLOCK	0x0414		// インデックスフリーブロック有効フラグ
#define	BIN_BLOCK_SIZE	1024		// バイナリファイルブロックサイズ
#define	BIN_DATA_SIZE	(BIN_BLOCK_SIZE - 4)	// バイナリデータサイズ

#pragma pach(1)

// インデックス（ＮＤＸ）ファイルのヘッダ
typedef	struct	_IDX_H	{
	LONG	root;				// ルートのブロックＮｏ．
	ULONG	nBlock;				// ブロック数
	SHORT	lBlock;				// ブロック長
	SHORT	reserved1;			// 予約１
	SHORT	lKey;				// キーの長さ
	SHORT	order;				// 次数
	SHORT	type;				// データ種別
	SHORT	lRec;				// １レコードの長さ
	SHORT	reserved2;			// 予約２
	CHAR	reserved3;			// 予約３
	CHAR	uniq;				// ユニークフラグ
	CHAR	index[100];			// インデックス表現式
	CHAR	work[382];			// ワークエリア
	SHORT	fFreeBlock;			// フリーブロック有効フラグ
	ULONG	nFreeBlock;			// フリーブロック数
} IDX_H, *PIDX_H;

// インデックスブロック情報
typedef	struct	_IDX_B	{
	LONG	bno;				// ブロックＮｏ．
	SHORT	cp;					// カレントポインタ
	struct	_IDX_B	*fwp;		// チェインポインタ
	struct	_IDX_B	*bwp;		// チェインポインタ
	CHAR	block[0];			// ブロック情報
} IDX_B, *PIDX_B;

// インデックスファイル管理情報
typedef	struct	_IDX_F	{
	CHAR	fileName[256];		// ファイル名
	FILE	*fh;				// ファイルハンドル
	PIDX_H	ihp;				// ヘッダ情報ポインタ
	SHORT	updateFlag;			// 更新フラグ
	SHORT	exFlag;				// 拡張インデックスフラグ
	SHORT	lBlock;				// ブロック長
	struct	_IDX	*ip;		// IDXポインタ
	struct	_IDX_F	*chain;		// IDX_Fチェイン
} IDX_F, *PIDX_F;

// インデックス管理情報
typedef	struct	_IDX	{
	PIDX_B	bp;					// カレントブロック情報ポインタ
	PIDX_B	top;				// ブロック情報ポインタ
	PIDX_B	bottom;				// ブロック情報ポインタ
	CHAR	*keyp;				// キーポインタ
	struct	_IDX_F	*ifp;		// IDX_Fポインタ
	struct	_IDX	*chain;		// IDXチェイン
#ifdef	MULTI_OPEN
	int		fh;					// NDX ファイルハンドル
#endif
} IDX, *PIDX;

// バイナリファイルのヘッダ
typedef	struct	_BIN_H	{
	LONG	nUsedBlock;			// 使用ブロック数
	LONG	freeBlock;			// 空きブロック番号
	CHAR	reserved[BIN_BLOCK_SIZE - 8];
} BIN_H, *PBIN_H;

// バイナリファイル管理情報
typedef	struct	_BIN	{
	CHAR	fileName[256];		// ファイル名
	FILE	*fh;				// ファイルハンドル
	PBIN_H	bhp;				// ヘッダ情報へのポインタ
	LONG	dataSize;			// データサイズ
	LONG	dataSize2;			// 上書き前のデータサイズ
	LONG	bno;				// カレントブロック番号
	LONG	remain;				// ブロックバッファ内残りデータサイズ
	LONG	offset;				// ブロックバッファ内オフセット
	LONG	bnoTop;				// 先頭のブロック番号
	LONG	bnoNext;			// 次のブロック番号
	CHAR	buf[BIN_BLOCK_SIZE];	// ブロックバッファ
	PSBOOL	updateBlockFlag;	// ブロック更新フラグ
	PSBOOL	updateSizeFlag;		// サイズ更新フラグ
	PSBOOL	updateHeaderFlag;	// ヘッダ更新フラグ
} BIN, *PBIN;

// バイナリデータ読み込み管理情報
typedef	struct	_BIN_R	{
	LONG	dataSize;			// 残りデータサイズ
	LONG	bno;				// カレントブロック番号
	LONG	remain;				// ブロックバッファ内残りデータサイズ
	LONG	offset;				// ブロックバッファ内オフセット
	CHAR	buf[BIN_BLOCK_SIZE];	// ブロックバッファ
} BIN_R, *PBIN_R;

// データ（ＤＢＦ）ファイルのヘッダ
typedef	struct	_DBF_H	{
	CHAR	flag;				// データベーステキストファイル保有フラグ
	CHAR	date[3];			// 最終更新日
	LONG	nRec;				// レコード数
	SHORT	lHeader;			// ヘッダ部の長さ
	SHORT	lRec;				// １レコードの長さ
	SHORT	extField;			// 拡張フィールド
	USHORT	scramble;			// 暗号化キー
	CHAR	password[8];		// パスワード
	CHAR	reserve[8];			// システム予約領域
} DBF_H, *PDBF_H;

// フィールド情報
typedef	struct	_FIELD	{
	CHAR	name[11];			// フィールド名
	CHAR	type;				// フィールド形式
	SHORT	offset;				// フィールドオフセット
	SHORT	lField2;			// 拡張フィールド長
	CHAR	lField;				// フィールド長
	CHAR	lDec;				// 小数位桁数
	CHAR	reserve1[5];		// システム予約領域
	CHAR	flag;				// SET FIELDS ON/OFF の設定フラグ
	CHAR	reserve2[8];		// システム予約領域
} FIELD, *PFIELD;

#pragma pack()

// レコードロック情報
typedef	struct	_DBLOCK	{
	struct	_DB	*dbp;			// レコードロック dbp
	LONG	rno;				// ロックレコード番号
	struct	_DBLOCK	*chain;		// チェイン
} DBLOCK, *PDBLOCK;

// データファイル管理情報
typedef	struct	_DBF	{
	CHAR	fileName[256];		// ファイル名
	FILE	*fh;				// ファイルハンドル
	PDBF_H	dhp;				// ヘッダ情報へのポインタ
	PFIELD	flp;				// フィールド情報へのポインタ
	SHORT	nField;				// フィールド数
	SHORT	updateFlag;			// 更新フラグ
	LONG	updateCount;		// 更新カウンタ
	SHORT	adjustFlag;			// レコード数調整フラグ
	int		readLockCount;		// ファイル読み込みロックカウント
	int		writeLockCount;		// ファイル書き込みロックカウント
	PDBLOCK	rdlp;				// レコード読み込みロック情報
	PDBLOCK	wdlp;				// レコード書き込みロック情報
	PBIN	bfp;				// バイナリファイル情報
	SHORT	lRec;				// レコード長（バイナリフィールドを除く）
	CRITICALSECTION	csDBF;		// DBF クリチカルセクション
	struct	_DB	*dbp;			// DBポインタ
	struct	_DBF	*chain;		// DBFチェイン
} DBF, *PDBF;

// データベース管理情報
typedef	struct	_DB	{
	PDBF	dp;					// データファイル情報
	PBIN_R	brp;				// バイナリデータ読み込み情報
	PIDX	ip[MAX_IDX+1];		// インデックスファイル情報
	int		master;				// マスターインデックス
	int		nIdx;				// インデックスファイル数
	LONG	rno;				// カレントレコードＮｏ．
	SHORT	bof;				// ＢＯＦフラグ
	SHORT	eof;				// ＥＯＦフラグ
	SHORT	setDeleted;			// 削除レコード無効フラグ
	CHAR	*filter;			// フィルタ条件式
	HPSTR	select;				// 選択レコードフラグ
	LONG	selectRec;			// 選択時のレコード数
	SHORT	*readField;			// 読み込みフィールド
	SHORT	readSize;			// 読み込みサイズ
	CHAR	*rbp;				// レコードバッファ
	CHAR	*rbp2;				// レコードバッファ２
	LONG	updateCount;		// 更新カウンタ
	int		readLockCount;		// ファイル読み込みロックカウント
	int		writeLockCount;		// ファイル書き込みロックカウント
	SHORT	permission;			// アクセス許可モード
	struct	_DB	*chain;			// チェインポインタ
#ifdef	MULTI_OPEN
	int		fh;					// DBF ファイルハンドル
#endif
} DB, *PDB;

// 関数定義
extern	SHORT	DBOpen(CHAR *, PDB *, SHORT);
extern	SHORT	DBCreate(CHAR *, PDBF_I, SHORT, PDB *, SHORT);
extern	SHORT	DBClose(PDB);
extern	SHORT	DBFlush(PDB);
extern	SHORT	DBIndex(PDB, CHAR *, SHORT *);
extern	SHORT	DBIdxCreate(PDB, CHAR *, CHAR *, SHORT, SHORT *);
extern	SHORT	DBChgIdx(PDB, SHORT);
extern	SHORT	DBSearch(PDB, CHAR *, SHORT);
extern	SHORT	DBSearch2(PDB, CHAR *, SHORT, SHORT *);
extern	SHORT	DBSearchLock(PDB, CHAR *, SHORT, LONG *);
extern	SHORT	DBCount(PDB, CHAR *, SHORT, LONG *);
extern	SHORT	DBStore(PDB, CHAR *);
extern	SHORT	DBStoreUniq(PDB, CHAR *);
extern	SHORT	DBUpdate(PDB, CHAR *);
extern	SHORT	DBUpdateKey(PDB, CHAR *, SHORT, CHAR *);
extern	SHORT	DBDelete(PDB);
extern	SHORT	DBDelete2(PDB);
extern	SHORT	DBDelete3(PDB);
extern	SHORT	DBDeleteKey(PDB, CHAR *, SHORT, SHORT);
extern	SHORT	DBRecall(PDB);
extern	SHORT	DBTop(PDB);
extern	SHORT	DBBottom(PDB);
extern	SHORT	DBSet(PDB, LONG);
extern	SHORT	DBSkip(PDB, LONG);
extern	SHORT	DBReindex(PDB);
extern	SHORT	DBPack(PDB);
extern	SHORT	DBRead(PDB, CHAR *);
extern	SHORT	DBReadNext(PDB, SHORT, CHAR *, SHORT *);
extern	SHORT	DBReadBack(PDB, SHORT, CHAR *, SHORT *);
extern	SHORT	DBReadKey(PDB, CHAR *, SHORT, CHAR *, SHORT, SHORT *);
extern	SHORT	DBReadBinary(PDB, CHAR *, HPSTR, LONG, LONG *);
extern	SHORT	DBWriteBinary(PDB, CHAR *, HPSTR, LONG);
extern	SHORT	DBGetBinarySize(PDB, CHAR *, LONG *);
extern	SHORT	DBClrRecord(PDB);
extern	SHORT	DBGetRecord(PDB);
extern	SHORT	DBGetField(PDB, CHAR *, VOID *, SHORT *, SHORT *);
extern	SHORT	DBSetField(PDB, CHAR *, VOID *);
extern	SHORT	DBAddRecord(PDB);
extern	SHORT	DBUpdRecord(PDB);
extern	SHORT	DBCopy(PDB, PDB);
extern	SHORT	DBCheckDeleted(PDB, SHORT *);
extern	SHORT	DBSetFilter(PDB, CHAR *);
extern	SHORT	DBSelect(PDB, CHAR *, LONG *);
extern	SHORT	DBSetDeleted(PDB, SHORT);
extern	SHORT	DBLRecNo(PDB, LONG *);
extern	SHORT	DBLRecCount(PDB, LONG *);
extern	SHORT	DBLSet(PDB, LONG);
extern	SHORT	DBZip(PDB);
extern	SHORT	DBCheckUpdate(PDB, SHORT *);
extern	SHORT	DBLock(PDB, SHORT);
extern	SHORT	DBUnlock(PDB, SHORT);
extern	SHORT	DBRecCount(PDB, LONG *);
extern	SHORT	DBBof(PDB, SHORT *);
extern	SHORT	DBDbf(PDB, CHAR *);
extern	SHORT	DBEof(PDB, SHORT *);
extern	SHORT	DBNField(PDB, SHORT *);
extern	SHORT	DBField(PDB, SHORT, PDBF_I);
extern	SHORT	DBNdx(PDB, SHORT, CHAR *);
extern	SHORT	DBRecNo(PDB, LONG *);
extern	SHORT	DBRecSize(PDB, SHORT *);
extern	SHORT	DBSetReadField(PDB, CHAR *, SHORT *);
extern	SHORT	DBSetScramble(PDB);
extern	SHORT	DBSetPassword(PDB, CHAR *);
extern	SHORT	DBUpdateEx(PDB, LONG, CHAR *);
extern	SHORT	DBDeleteEx(PDB, LONG);
extern	SHORT	DBRecallEx(PDB, LONG);
extern	SHORT	DBDelete2Ex(PDB, LONG);
extern	SHORT	DBLockEx(PDB, LONG, SHORT);
extern	SHORT	DBPackIndex(CHAR *);

// インデックスのキー種別
#define	KEY_TYPE_C	0	// 文字型
#define	KEY_TYPE_N	1	// 実数型
#define	KEY_TYPE_I	2	// 整数型
