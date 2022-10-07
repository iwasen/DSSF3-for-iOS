#import "PCSCL.h"

CPcserve::CPcserve()
{
	m_pCCB = NULL;
}

CPcserve::~CPcserve()
{
	Disconnect();
}

PCCB CPcserve::GetCCB()
{
	return m_pCCB;
}

int CPcserve::Connect(int nChType, LPCTSTR lpServerName, LPCTSTR lpClientID)
{
	short err;

	m_pCCB = PSConnect(nChType, (LPSTR)lpServerName, (LPSTR)lpClientID, &err);
	return err;
}

int CPcserve::Disconnect()
{
	if (m_pCCB != NULL) {
		PSDisconnect(m_pCCB);
		m_pCCB = NULL;
	}

	return 0;
}

int CPcserve::PackIndex(LPCTSTR lpFileName)
{
	if (m_pCCB == NULL)
		return ERROR_CLIENT_NOTCONNECT;

	PSDBPackIndex(m_pCCB, (LPSTR)lpFileName);
	return PSGetErrCode(m_pCCB);
}
/*
LPCTSTR CPcserve::GetErrorText(int err)
{
	return PSGetErrorText(err);
}
*/
