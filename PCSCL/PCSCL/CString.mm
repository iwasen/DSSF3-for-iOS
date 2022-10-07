//
//  String.cpp
//  PCSCL
//
//  Created by 相沢伸一 on 2015/06/30.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "CString.h"
#import <string.h>

CString::CString()
{
	m_pData = NULL;
	Empty();
}

CString::CString(const char *str)
{
	m_pData = NULL;
	AllocBuf((int)strlen(str) + 1);
	strcpy(m_pData, str);
}

CString::CString(const char *str, int len)
{
	m_pData = NULL;
	AllocBuf(len + 1);
	strncpy(m_pData, str, len);
	m_pData[len] = '\0';
}

CString::~CString()
{
	FreeBuf();
}

void CString::AllocBuf(int nSize)
{
	FreeBuf();
	m_pData = new char[nSize];
}

void CString::FreeBuf()
{
	if (m_pData != NULL) {
		delete [] m_pData;
		m_pData = NULL;
	}
}

CString &CString::operator=(const CString &str)
{
	AllocBuf(str.GetLength() + 1);
	strcpy(m_pData, str.m_pData);
	return *this;
}

CString &CString::operator=(const char *str)
{
	AllocBuf((int)strlen(str) + 1);
	strcpy(m_pData, str);
	return *this;
}

CString &CString::operator=(const NSString *str)
{
	*this = (const char *)[str UTF8String];

	return *this;
}

CString CString::operator+(const char *str2)
{
	char *buf = new char[GetLength() + (int)strlen(str2) + 1];
	strcpy(buf, m_pData);
	strcat(buf, str2);
	CString str(buf);
	delete [] buf;
	return str;
}

char CString::operator[](int index)
{
	return m_pData[index];
}

CString::operator const char *()
{
	return m_pData;
}

CString::operator NSString *()
{
	return [NSString stringWithCString: m_pData encoding:NSUTF8StringEncoding];
}

void CString::Empty()
{
	m_pData = new char[1];
	m_pData[0] = '\0';
}

BOOL CString::IsEmpty() const
{
	return m_pData[0] == '\0';
}

CString &CString::TrimRight()
{
	for (int i = (int)strlen(m_pData) - 1; i >= 0; i--) {
		if (m_pData[i] == ' ' || m_pData[i] == '\n' || m_pData[i] == '\r')
			m_pData[i] = '\0';
		else
			break;
	}
	return *this;
}

void CString::Format(const char *fmt, ...)
{
	char buf[256];

	va_list argList;
	va_start(argList, fmt);
	vsprintf(buf, fmt, argList);
	va_end(argList);

	*this = (const char *)buf;
}

int CString::GetLength() const
{
	return (int)strlen(m_pData);
}

CString CString::Left(int nCount) const
{
	if (nCount < 0)
		nCount = 0;

	int nLength = GetLength();
	if( nCount >= nLength )
	{
		return *this;
	}

	return CString(m_pData, nCount);
}

CString CString::Mid(int iFirst) const
{
	return( Mid( iFirst, GetLength()-iFirst ) );
}

CString CString::Mid(int iFirst, int nCount) const
{
	// nCount is in XCHARs

	// out-of-bounds requests return sensible things
	if (iFirst < 0)
		iFirst = 0;
	if (nCount < 0)
		nCount = 0;

	if (iFirst + nCount > GetLength())
	{
		nCount = GetLength() - iFirst;
	}
	if (iFirst > GetLength())
	{
		nCount = 0;
	}

	if ((iFirst == 0) && ((iFirst+nCount) == GetLength()))
	{
		return *this;
	}

	return CString(m_pData + iFirst, nCount);
}

CString CString::Right(int nCount) const
{
	// nCount is in XCHARs
	if (nCount < 0)
		nCount = 0;

	int nLength = GetLength();
	if (nCount >= nLength)
	{
		return *this;
	}

	return CString(m_pData + nLength - nCount, nCount);
}
