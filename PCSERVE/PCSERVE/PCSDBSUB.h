/************************************************************************
 *
 *			ＰＣ−ＳＥＲＶＥ
 *
 *		名称		: ＩＳＡＭ関連内部関数定義
 *		ファイル名	: pcsdbsub.h
 *		作成者		: s.aizawa
 *
 ************************************************************************/

#include "PCSIO.h"

extern	SHORT	DBFOpen(CHAR *, PDBF *);
extern	SHORT	DBFCreate(CHAR *, DBF_I *, SHORT, PDBF *);
extern	SHORT	DBFRead(PDBF, LONG, CHAR *);
extern	SHORT	DBFRead2(PDBF, LONG, CHAR *);
extern	SHORT	DBFWrite(PDBF, LONG, CHAR *);
extern	SHORT	DBFWrite2(PDBF, LONG, CHAR *);
extern	SHORT	DBFClose(PDBF);
extern	SHORT	DBFFlush(PDBF, PSBOOL);
extern	SHORT	DBFDelete(PDBF, LONG);
extern	SHORT	DBFRecall(PDBF, LONG);
extern	SHORT	DBFPack(PDBF);
extern	SHORT	DBFCheckDeleted(PDBF, LONG, SHORT *);
extern	SHORT	DBFCopy(PDBF, PDBF);
extern	SHORT	DBFZip(PDBF);
extern	SHORT	DBFSetScramble(PDBF, USHORT);
extern	SHORT	DBFSetPassword(PDBF, CHAR *);

extern	SHORT	IDXOpen(CHAR *, PIDX *);
extern	SHORT	IDXCreate(CHAR *, CHAR *, SHORT, PIDX *);
extern	SHORT	IDXSetInfo(PIDX, SHORT, SHORT);
extern	SHORT	IDXRead(PIDX, LONG, PIDX_B *);
extern	SHORT	IDXGetBlk(PIDX, LONG, PIDX_B *);
extern	SHORT	IDXWrite(PIDX, IDX_B *);
extern	SHORT	IDXClose(PIDX);
extern	SHORT	IDXFlush(PIDX, PSBOOL);
extern	SHORT	IDXSearch(PIDX, VOID *, SHORT, LONG *);
extern	SHORT	IDXSearch2(PIDX, VOID *, SHORT, LONG *);
extern	SHORT	IDXSearch3(PIDX, VOID *, SHORT, LONG, LONG *);
extern	SHORT	IDXSearchEx(PIDX, VOID *, SHORT, LONG, LONG *);
extern	SHORT	IDXCompare(PIDX, VOID *, SHORT);
extern	SHORT	IDXCompareEx(PIDX, VOID *, SHORT, LONG);
extern	SHORT	IDXStore(PIDX, CHAR *, LONG);
extern	SHORT	IDXDelete(PIDX, LONG);
extern	SHORT	IDXNext(PIDX, LONG *);
extern	SHORT	IDXBack(PIDX, LONG *);
extern	SHORT	IDXTop(PIDX, LONG *);
extern	SHORT	IDXBottom(PIDX, LONG *);
extern	SHORT	IDXCount(PIDX, VOID *, SHORT, LONG *);
extern	SHORT	IDXSet(PIDX, LONG);
extern	VOID	IDXFlushBlock(PIDX, PSBOOL);
extern	SHORT	IDXPack(PIDX);

extern	SHORT	BINOpen(CHAR *, PBIN *);
extern	SHORT	BINCreate(CHAR *, PBIN *);
extern	SHORT	BINClose(PBIN);
extern	SHORT	BINFlush(PBIN, PSBOOL);
extern	SHORT	BINRead(PBIN, PBIN_R, HPSTR, LONG, LONG, LONG *);
extern	SHORT	BINReadNext(PBIN, PBIN_R, HPSTR, LONG, LONG *);
extern	SHORT	BINWrite(PBIN, HPSTR, LONG, LONG *);
extern	SHORT	BINWriteNext(PBIN, HPSTR, LONG);
extern	SHORT	BINGetDataSize(PBIN, LONG, LONG *);
extern	SHORT	BINDelete(PBIN, LONG);
extern	SHORT	BINZip(PBIN);
extern	SHORT	BINCopy(PBIN, PBIN, LONG, LONG *);

/*extern	SHORT	DBFSort(PDBF, CHAR *, CHAR *);*/
extern	SHORT	IDXMake(PDBF, PIDX);

extern	SHORT	GetKey(PDBF, CHAR *, IDX_H *, VOID *);
extern	FIELD	*GetField(PDBF, CHAR *);
extern	SHORT	GetFieldNo(PDBF, CHAR *);

extern	SHORT	SetFilter(PDB, CHAR *);
extern	SHORT	CheckFilter(PDB);
extern	SHORT	SetSelect(PDB, CHAR *, LONG *);
