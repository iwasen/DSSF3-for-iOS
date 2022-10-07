#import "Noise.h"
#import "Mrnd.h"

CNoise::CNoise()
{
	memset(m_aPinkBuf, 0, sizeof(m_aPinkBuf));
	m_fBrownBuf = 0;
}

void CNoise::GenerateWhiteNoise(float *pData, int nSize, float fLevel)
{
	int i;

	for (i = 0; i < nSize; i++)
		*pData++ = nrnd1() / 6 * fLevel;
}

void CNoise::GeneratePinkNoise(float *pData, int nSize, float fLevel)
{
	int i;

	for (i = 0; i < nSize; i++)
		*pData++ = GeneratePinkNoiseSub() * fLevel / 19;
}

float CNoise::GeneratePinkNoiseSub()
{
	float white = nrnd1(), pink;

	m_aPinkBuf[0] = 0.99886 * m_aPinkBuf[0] + white * 0.0555179;
	m_aPinkBuf[1] = 0.99332 * m_aPinkBuf[1] + white * 0.0750759;
	m_aPinkBuf[2] = 0.96900 * m_aPinkBuf[2] + white * 0.1538520;
	m_aPinkBuf[3] = 0.86650 * m_aPinkBuf[3] + white * 0.3104856;
	m_aPinkBuf[4] = 0.55000 * m_aPinkBuf[4] + white * 0.5329522;
	m_aPinkBuf[5] = -0.7616 * m_aPinkBuf[5] - white * 0.0168980;
	pink = m_aPinkBuf[0] + m_aPinkBuf[1] + m_aPinkBuf[2] + m_aPinkBuf[3] + m_aPinkBuf[4] + m_aPinkBuf[5] + m_aPinkBuf[6] + white * 0.5362;
	m_aPinkBuf[6] = white * 0.115926;

	return pink;
}

void CNoise::GenerateBrownNoise(float *pData, int nSize, float fLevel)
{
	int i;

	for (i = 0; i < nSize; i++) {
		m_fBrownBuf = m_fBrownBuf * (1023.0 / 1024.0) + nrnd1() * (1.0 / 1024.0);
		*pData++ = m_fBrownBuf * fLevel * 9;
	}
}
