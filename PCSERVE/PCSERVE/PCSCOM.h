/************************************************************************
 *
 *			ＰＣ−ＳＥＲＶＥ
 *
 *		名称		: 共通サブルーチンヘッダ
 *		ファイル名	: pcscom.h
 *		作成者		: s.aizawa
 *
 ************************************************************************/

extern	PSBOOL	active;

extern	double	natof(CHAR *, SHORT);
extern	SHORT	natoi(CHAR *, SHORT);
extern	LONG	natol(CHAR *, SHORT);
extern	VOID	StringToUpper(CHAR *);
extern	VOID	SetExtention(CHAR *, CHAR *);
extern	VOID	Scramble1(CHAR *, SHORT, USHORT);
extern	VOID	Scramble2(CHAR *, SHORT, USHORT);
