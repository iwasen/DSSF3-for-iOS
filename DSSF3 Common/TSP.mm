//
//  TSP.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/15.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "TSP.h"

CTSP::CTSP()
{
	m_nStage = 0;
	m_pSignal = NULL;
}

CTSP::~CTSP()
{
	FreeBuffers();
}

void CTSP::InitMethod(int nStage)
{
	static const int tMParam[] = {10, 12, 13, 14, 15, 15, 15, 15, 15, 15};

	if (nStage == m_nStage)
		return;

	m_nStage = nStage;
	m_nN = 1 << m_nStage;
	m_nM = tMParam[m_nStage - 10] * m_nN / 32;

	FreeBuffers();
}

void CTSP::GenerateSequence(float *pData, int nAtt)
{
	int i, j;
	float e;
	int nLevel = 1 / nAtt;

	if (m_pSignal == NULL) {
		float *f1 = new float[m_nN];

		f1[0] = 1.0;
		f1[1] = 1.0;
		for (i = 1; i < m_nN / 2; i++) {
			e = 4 * M_PI * m_nM * i * i / ((float)m_nN * m_nN);
			j = i * 2;
			f1[j] = cos(e);
			f1[j + 1] = -sin(e);
		}

		m_oRFFT.ifft(m_nN, f1);

		float fMax = 0;
		float fAbs;
		for (i = 0; i < m_nN; i++) {
			fAbs = fabs(f1[i]);
			if (fAbs > fMax)
				fMax = fAbs;
		}

		for (i = 0; i < m_nN; i++)
			f1[i] /= fMax;

		m_pSignal = new float[m_nN];

		int nShift = m_nN / 2 - m_nM;
		for (i = 0; i < m_nN - nShift; i++)
			m_pSignal[i] = f1[i + nShift] * nLevel;
		for ( ; i < m_nN; i++)
			m_pSignal[i] = f1[i - (m_nN - nShift)] * nLevel;

		delete [] f1;
	}

	memcpy(pData, m_pSignal, sizeof(float) * m_nN);
}

void CTSP::CalcImpulse(float *pData)
{
	if (m_nStage == 0)
		return;

	int i, j;
	float e;
	float *f1 = new float[m_nN];
	float t1, t2;

	f1[0] = 1.0;
	f1[1] = 1.0;
	for (i = 1; i < m_nN / 2; i++) {
		e = 4 * M_PI * m_nM * i * i / ((float)m_nN * m_nN);
		j = i * 2;
		f1[j] = cos(e);
		f1[j + 1] = sin(e);
	}

	m_oRFFT.fft(m_nN, pData);

	f1[0] = 0;
	f1[1] = 0;
	for (i = 1; i < m_nN / 2; i++) {
		j = i * 2;
		t1 = (f1[j] * pData[j] - f1[j + 1] * pData[j + 1]) * 0.005794; // 0.005794ÇÕMånóÒÇ∆êÆçá
		t2 = (f1[j] * pData[j + 1] + f1[j + 1] * pData[j]) * 0.005794;
		f1[j] = t1;
		f1[j + 1] = t2;
	}

	m_oRFFT.ifft(m_nN, f1);

	int nShift = m_nN / 2 - m_nM;
	memcpy(pData, f1 + (m_nN - nShift), sizeof(float) * nShift);
	memcpy(pData + nShift, f1, sizeof(float) * (m_nN - nShift));

	delete [] f1;

	PolarityCheck(m_nN, pData);
}

void CTSP::FreeBuffers()
{
	if (m_pSignal != NULL) {
		delete [] m_pSignal;
		m_pSignal = NULL;
	}
}
