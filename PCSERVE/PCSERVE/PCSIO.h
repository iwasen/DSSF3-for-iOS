/************************************************************************
 *
 *			ＰＣ−ＳＥＲＶＥ
 *
 *		名称		: ファイルＩＯマクロ
 *		ファイル名	: pcsio.h
 *		作成者		: s.aizawa
 *
 ************************************************************************/

#define	__CREAT(_fname)	fopen(_fname,"w+")
#define	__CREAT_LOCAL(_fname) fopen(_fname,"w+")
#define	__OPEN(_fname)	fopen(_fname,"r+")
#define	__READ(_handle,_buf,_size)	fread(_buf,1,_size,_handle)
#define	__WRITE(_fname,_handle,_buf,_size)	fwrite(_buf,1,_size,_handle)
#define	__WRITE_LOCAL(_handle,_buf,_size)	fwrite(_buf,1,_size,_handle)
#define	__WRITE2(_fname,_handle,_buf,_size,_offset) (fseek(_handle,_offset,0),fwrite(_buf,1,_size,_handle))
#define	__LSEEK(_handle,_offset,_origin) (fseek(_handle,_offset,_origin),ftell(_handle))
#define	__CLOSE(_handle)	fclose(_handle)
#define	__CHSIZE(_fname,_handle,_size)
#define	__CHSIZE_LOCAL(_handle,_size)
#define	__DELETE(_fname) remove(_fname)
#define	__RENAME(_fname1,_fname2) rename(_fname1,_fname2)
#define	__FLUSH(_handle) fflush(_handle)
#define __DELETEFILE(_fname) remove(_fname)
#define __COPYFILE(_src,_dst,_flag) CopyFile(_src,_dst)
#define __MOVEFILE(_src,_dst) rename(_src,_dst)
#define	__LSEEK_64(_handle,_offset,_origin) (fseeko(_handle,_offset,_origin),ftello(_handle))
#define	__WRITE2_64(_fname,_handle,_buf,_size,_offset) (fseeko(_handle,_offset,0),fwrite(_buf,1,_size,_handle))
#define	__CHSIZE_64(_fname,_handle,_size)

extern PSBOOL CopyFile(CHAR *pSrcFileName, CHAR *pDstFileName);