//
//  String.h
//  PCSCL
//
//  Created by 相沢伸一 on 2015/06/30.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <Foundation/Foundation.h>

class CString
{
public:
	CString();
	CString(const char *str);
	CString(const char *str, int len);
	~CString();
	CString &operator=(const CString &str);
	CString &operator=(const char *str);
	CString &operator=(const NSString *str);
	CString operator+(const char *str);
	char operator[](int index);
	operator const char *();
	operator NSString *();
	void Empty();
	BOOL IsEmpty() const;
	CString &TrimRight();
	void Format(const char *fmt, ...);
	int GetLength() const;
	CString Left(int nCount) const;
	CString Mid(int iFirst) const;
	CString Mid(int iFirst, int nCount) const;
	CString Right(int nCount) const;

protected:
	char *m_pData;

	void AllocBuf(int nSize);
	void FreeBuf();
};
