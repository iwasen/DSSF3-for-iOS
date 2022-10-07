/************************************************************************
 *
 *			ＰＣ−ＳＥＲＶＥ
 *
 *		名称		: 共通サブルーチン
 *		ファイル名	: pcscom.c
 *		作成者		: s.aizawa
 *
 ************************************************************************/

#include "PCSOS.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#define	iskanji(c)	((c) & 0x80)
#include "pcsdef.h"
#include "PCSDB.h"
#include "PCSCOM.h"

int	allocCount;
PSBOOL	active = TRUE;

/*=======================================================================
 |
 |		文字列からdoubleへの変換
 |
 |	double	natof(str, len)
 |
 |		CHAR	*str;		文字列
 |		SHORT	len;		長さ
 |
 |		返値			実数値
 |
 =======================================================================*/
double	natof(CHAR *str, SHORT len)
{
	CHAR	buf[64];

	memcpy(buf, str, len);
	buf[len] = '\0';
	return atof(buf);
}

/*=======================================================================
 |
 |		文字列からSHORTへの変換
 |
 |	SHORT	natoi(str, len)
 |
 |		CHAR	*str;		文字列
 |		SHORT	len;		長さ
 |
 |		返値			実数値
 |
 =======================================================================*/
SHORT	natoi(CHAR *str, SHORT len)
{
	CHAR	buf[64];

	memcpy(buf, str, len);
	buf[len] = '\0';
	return atoi(buf);
}

/*=======================================================================
 |
 |		文字列からLONGへの変換
 |
 |	LONG	natol(str, len)
 |
 |		CHAR	*str;		文字列
 |		SHORT	len;		長さ
 |
 |		返値			整数値
 |
 =======================================================================*/
LONG	natol(CHAR *str, SHORT len)
{
	CHAR	buf[64];

	memcpy(buf, str, len);
	buf[len] = '\0';
	return atoi(buf);
}

/*=======================================================================
 |
 |		大文字変換処理
 |
 |	VOID	StringToUpper(name, ext)
 |
 |		CHAR	*str;		文字列
 |
 =======================================================================*/
VOID	StringToUpper(CHAR *str)
{
	while (*str != '\0') {
		if (iskanji(*str)) {
			str++;
			if (*str == '\0')
				break;
		} else
			*str = (CHAR)toupper(*str);
		str++;
	}
}

/*=======================================================================
 |
 |		拡張子付加処理
 |
 |	VOID	SetExtention(name, ext)
 |
 |		CHAR	*name;		ファイル名
 |		CHAR	*ext;		拡張子
 |
 =======================================================================*/
VOID	SetExtention(CHAR *name, CHAR *ext)
{
	CHAR	 *p;

	if ((p = strrchr(name, '\\')) == NULL)
		p = name;

	if ((p = strchr(p, '.')) != NULL)
		strcpy(p+1, ext);
	else {
		strcat(name, ".");
		strcat(name, ext);
	}
}

/*=======================================================================
 |
 |		暗号化処理
 |
 |	VOID	Scramble1(bufp, length, scramble)
 |
 |		CHAR	*bufp;		データバッファ
 |		SHORT	length;		データ長
 |		USHORT	scramble;	暗号化キー
 |
 =======================================================================*/
VOID	Scramble1(CHAR *bufp, SHORT length, USHORT scramble)
{
	static	CHAR	scrambleTbl1[256] = {
		0x35, 0x85, 0x49, 0xe2, 0xa7, 0x42, 0xdf, 0x0b,
		0x2d, 0x23, 0xdd, 0xde, 0x1f, 0x17, 0xbb, 0xcf,
		0x4e, 0xa3, 0x19, 0x04, 0x71, 0x12, 0xb5, 0x50,
		0x43, 0x64, 0xa0, 0x15, 0xdb, 0x22, 0xb0, 0x83,
		0x39, 0xea, 0xaf, 0xc3, 0xd0, 0xce, 0x77, 0x14,
		0xad, 0x56, 0x80, 0x5f, 0x6e, 0xd2, 0xd9, 0xc0,
		0xe6, 0xf6, 0x70, 0xf9, 0x05, 0x5a, 0x33, 0xc5,
		0x8c, 0x73, 0xcb, 0xfa, 0x81, 0x3e, 0xd8, 0x9e,
		0x26, 0xd6, 0x0c, 0xba, 0xaa, 0xcd, 0x7e, 0x9d,
		0xff, 0x1d, 0x06, 0xc4, 0xed, 0xf2, 0xf4, 0x5b,
		0x94, 0x9b, 0xa1, 0x5e, 0xb8, 0x37, 0xc1, 0xf1,
		0x57, 0x7b, 0xd7, 0xfb, 0x25, 0xcc, 0x91, 0xf0,
		0x62, 0x7f, 0xfc, 0x1a, 0x96, 0x72, 0x2f, 0xda,
		0x38, 0xa2, 0x3a, 0xbf, 0xb4, 0xb1, 0xe8, 0xbd,
		0x0f, 0xf7, 0xae, 0xa6, 0x88, 0x74, 0x2c, 0x7d,
		0x01, 0xec, 0x07, 0x24, 0x40, 0x34, 0x5d, 0x59,
		0x9c, 0x7a, 0x9a, 0xee, 0xe7, 0x46, 0x9f, 0x61,
		0x63, 0x30, 0xb2, 0x97, 0xef, 0xac, 0x76, 0x8e,
		0x75, 0xe4, 0xd3, 0xa9, 0x2a, 0x41, 0x00, 0xa5,
		0xbc, 0x66, 0x51, 0xca, 0x1b, 0xb7, 0x7c, 0x0e,
		0x18, 0x6b, 0xc7, 0x78, 0x84, 0x6a, 0x6c, 0x82,
		0x60, 0xd5, 0x1c, 0x13, 0x55, 0x52, 0xb9, 0x53,
		0x32, 0x1e, 0xb6, 0x28, 0x4b, 0x8f, 0x11, 0x8d,
		0x8b, 0xfd, 0x10, 0x67, 0x3f, 0xd1, 0x36, 0x45,
		0x86, 0xc9, 0x4a, 0x54, 0x4f, 0xf8, 0x79, 0x29,
		0x69, 0x08, 0xe9, 0x89, 0x20, 0xab, 0x6d, 0xe3,
		0xc6, 0x98, 0x99, 0xe5, 0x93, 0x48, 0x09, 0xe1,
		0xf3, 0x47, 0x4c, 0xfe, 0x8a, 0x95, 0x3c, 0xeb,
		0x2b, 0x03, 0xf5, 0xa8, 0x58, 0x3d, 0xc2, 0x31,
		0x65, 0xdc, 0x27, 0xbe, 0x21, 0x68, 0xe0, 0xb3,
		0xc8, 0xa4, 0x02, 0x2e, 0xd4, 0x3b, 0x6f, 0x5c,
		0x87, 0x0a, 0x92, 0x0d, 0x4d, 0x16, 0x44, 0x90
	};
	USHORT	hs, ls;

	hs = scramble >> 8;
	ls = scramble & 0xff;
	while (length) {
		*bufp = (CHAR)(scrambleTbl1[(*bufp + ls) & 0xff] ^ hs);
		ls++;
		bufp++;
		length--;
	}
}

/*=======================================================================
 |
 |		暗号解除処理
 |
 |	VOID	Scramble2(bufp, length, scramble)
 |
 |		CHAR	*bufp;		データバッファ
 |		SHORT	length;		データ長
 |		USHORT	scramble;	暗号化キー
 |
 =======================================================================*/
VOID	Scramble2(CHAR *bufp, SHORT length, USHORT scramble)
{
	static	CHAR	scrambleTbl2[256] = {
		0x96, 0x78, 0xf2, 0xe1, 0x13, 0x34, 0x4a, 0x7a,
		0xc9, 0xd6, 0xf9, 0x07, 0x42, 0xfb, 0x9f, 0x70,
		0xba, 0xb6, 0x15, 0xab, 0x27, 0x1b, 0xfd, 0x0d,
		0xa0, 0x12, 0x63, 0x9c, 0xaa, 0x49, 0xb1, 0x0c,
		0xcc, 0xec, 0x1d, 0x09, 0x7b, 0x5c, 0x40, 0xea,
		0xb3, 0xc7, 0x94, 0xe0, 0x76, 0x08, 0xf3, 0x66,
		0x89, 0xe7, 0xb0, 0x36, 0x7d, 0x00, 0xbe, 0x55,
		0x68, 0x20, 0x6a, 0xf5, 0xde, 0xe5, 0x3d, 0xbc,
		0x7c, 0x95, 0x05, 0x18, 0xfe, 0xbf, 0x85, 0xd9,
		0xd5, 0x02, 0xc2, 0xb4, 0xda, 0xfc, 0x10, 0xc4,
		0x17, 0x9a, 0xad, 0xaf, 0xc3, 0xac, 0x29, 0x58,
		0xe4, 0x7f, 0x35, 0x4f, 0xf7, 0x7e, 0x53, 0x2b,
		0xa8, 0x87, 0x60, 0x88, 0x19, 0xe8, 0x99, 0xbb,
		0xed, 0xc8, 0xa5, 0xa1, 0xa6, 0xce, 0x2c, 0xf6,
		0x32, 0x14, 0x65, 0x39, 0x75, 0x90, 0x8e, 0x26,
		0xa3, 0xc6, 0x81, 0x59, 0x9e, 0x77, 0x46, 0x61,
		0x2a, 0x3c, 0xa7, 0x1f, 0xa4, 0x01, 0xc0, 0xf8,
		0x74, 0xcb, 0xdc, 0xb8, 0x38, 0xb7, 0x8f, 0xb5,
		0xff, 0x5e, 0xfa, 0xd4, 0x50, 0xdd, 0x64, 0x8b,
		0xd1, 0xd2, 0x82, 0x51, 0x80, 0x47, 0x3f, 0x86,
		0x1a, 0x52, 0x69, 0x11, 0xf1, 0x97, 0x73, 0x04,
		0xe3, 0x93, 0x44, 0xcd, 0x8d, 0x28, 0x72, 0x22,
		0x1e, 0x6d, 0x8a, 0xef, 0x6c, 0x16, 0xb2, 0x9d,
		0x54, 0xae, 0x43, 0x0e, 0x98, 0x6f, 0xeb, 0x6b,
		0x2f, 0x56, 0xe6, 0x23, 0x4b, 0x37, 0xd0, 0xa2,
		0xf0, 0xc1, 0x9b, 0x3a, 0x5d, 0x45, 0x25, 0x0f,
		0x24, 0xbd, 0x2d, 0x92, 0xf4, 0xa9, 0x41, 0x5a,
		0x3e, 0x2e, 0x67, 0x1c, 0xe9, 0x0a, 0x0b, 0x06,
		0xee, 0xd7, 0x03, 0xcf, 0x91, 0xd3, 0x30, 0x84,
		0x6e, 0xca, 0x21, 0xdf, 0x79, 0x4c, 0x83, 0x8c,
		0x5f, 0x57, 0x4d, 0xd8, 0x4e, 0xe2, 0x31, 0x71,
		0xc5, 0x33, 0x3b, 0x5b, 0x62, 0xb9, 0xdb, 0x48,
	};
	USHORT	hs, ls;

	hs = scramble >> 8;
	ls = scramble & 0xff;
	while (length) {
		*bufp = (CHAR)((scrambleTbl2[*bufp ^ hs] - ls) & 0xff);
		ls++;
		bufp++;
		length--;
	}
}

#undef	malloc
VOID	*_malloc(size_t size)
{
#if defined (OS_WNT) && !defined (_SERVER)
	HANDLE	hMap;
	VOID	*p;

	hMap = CreateFileMapping((HANDLE)0xFFFFFFFF, NULL, PAGE_READWRITE, 0,
						size + sizeof(HANDLE), NULL);
	if (hMap == NULL) 
		return NULL;
 
	p = MapViewOfFile(hMap, FILE_MAP_WRITE, 0, 0, 0);
	if (p == NULL) {
		CloseHandle(hMap);
		return NULL;
	}

	*(HANDLE *)p = hMap;
	((HANDLE *)p)++;

	allocCount++;
	return p;
#else
	extern	VOID	*malloc(size_t);

	allocCount++;
	return malloc(size);
#endif
}

#undef	calloc
VOID	*_calloc(size_t num, size_t size)
{
#if defined (OS_WNT) && !defined (_SERVER)
	return _malloc(num * size);
#else
	extern	VOID	*calloc(size_t, size_t);

	allocCount++;
	return calloc(num, size);
#endif
}

#undef	free
VOID	_free(VOID *p)
{
#if defined (OS_WNT) && !defined (_SERVER)
	HANDLE	hMap;

	allocCount--;
	hMap = *(HANDLE *)p;
	((HANDLE *)p)--;
	UnmapViewOfFile(p);
	CloseHandle(hMap);
#else
	extern	VOID	free(VOID *);

	allocCount--;
	free(p);
#endif
}
