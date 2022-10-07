/************************************************************************
 *
 *			ＰＣ−ＳＥＲＶＥ
 *
 *		名称		: システム情報ヘッダ
 *		ファイル名	: pcssys.h
 *		作成者		: s.aizawa
 *
 ************************************************************************/

#define	FILETYPE_NULL		0
#define	FILETYPE_DB			1
#define	FILETYPE_RF			2
#define	FILETYPE_FORWARD	4

#pragma pack(1)

typedef	struct	{
	CHAR	id;
	CHAR	endMark;
	SHORT	dataLength;
	CHAR	data[1020];
} BINDATA;

#pragma pack()

typedef	struct	{
	SHORT	recSize;
} DBINF, *PDBINF;
