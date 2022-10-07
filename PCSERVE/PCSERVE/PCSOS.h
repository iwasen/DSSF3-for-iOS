/************************************************************************
 *
 *			ＰＣ−ＳＥＲＶＥ
 *
 *		名称		: ＯＳ別ヘッダ
 *		ファイル名	: pcsos.h
 *		作成者		: s.aizawa
 *
 ************************************************************************/

#define	ENTER_CRITICAL_SECTION(p1)
#define	LEAVE_CRITICAL_SECTION(p1)
#define	INIT_CRITICAL_SECTION(p1)
#define	DELETE_CRITICAL_SECTION(p1)
#define	CRITICALSECTION			int
typedef	char *HPSTR;
typedef	int *HPINT;
#define	HALLOC(_size)	malloc(_size)
#define	HFREE(_p)	free(_p);
#define	HMEMSET(_p,_data,_size)	memset(_p,_data,_size)
#define	HMEMCPY(_p1,_p2,_size)	memcpy(_p1,_p2,_size)
