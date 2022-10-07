//
//  MSeq.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/15.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "MSeq.h"

static const MSeqParam tMSeqParam[] = {
	{10, 2, {3, 10},       {3, 13, 19, 30, 104, 152, 177, 325, 904, 1009}},
	{11, 2, {2, 11},       {11, 13, 22, 59, 85, 108, 138, 231, 465, 1139, 1914}},
	{12, 4, {1, 4, 6, 12}, {1, 4, 17, 19, 38, 70, 267, 361, 446, 3254, 3578, 4066}},
	{13, 4, {1, 3, 4, 13}, {1, 2, 11, 47, 71, 199, 393, 2019, 2163, 2631, 3056, 7479, 8156}},
	{14, 4, {1, 3, 5, 14}, {1, 2, 5, 10, 17, 25, 53, 463, 2946, 3200, 6292, 8283, 15458, 16302}},
	{15, 2, {1, 15},       {1, 14, 20, 40, 102, 144, 147, 398, 424, 1122, 4342, 5696, 20706, 22664, 31892}},
	{16, 4, {2, 3, 5, 16}, {3, 18, 19, 23, 48, 118, 377, 545, 769, 1613, 2345, 5236, 8133, 62746, 62776, 64388}},
	{17, 2, {3, 17},       {3, 17, 23, 82, 122, 187, 805, 1026, 2767, 3491, 4099, 12579, 23243, 30416, 107452, 112608, 114545}},
	{18, 2, {7, 18},       {7, 25, 39, 89, 100, 156, 279, 596, 2725, 2752, 6296, 9364, 14415, 36753, 59445, 78413, 126203, 144715}},
	{19, 4, {1, 2, 5, 19}, {1, 2, 4, 22, 153, 173, 206, 237, 318, 4083, 5248, 7232, 17917, 77973, 151898, 154964, 226311, 288443, 362037}}
};

CMSeq::CMSeq()
{
	m_nStage = 0;
	m_pMSequence = NULL;
	m_pPermut = NULL;
}

CMSeq::~CMSeq()
{
	FreeBuffers();
}

void CMSeq::InitMethod(int nStage)
{
	int ntap;
	const int *taps;
	const int *tob;
	int i, k;
	int p, s;
	int nData;

	if (nStage == m_nStage)
		return;

	m_nStage = nStage;

	if (nStage == 0)
		return;

	for (i = 0; i < sizeof(tMSeqParam) / sizeof(MSeqParam); i++) {
		if (tMSeqParam[i].nBit == nStage)
			break;
	}
	if (i == sizeof(tMSeqParam) / sizeof(MSeqParam))
		i = 0;

	FreeBuffers();
	nData = 1 << nStage;
	m_pMSequence = new char[nData];
	m_pPermut = new int[nData];

	ntap = tMSeqParam[i].ntap;
	taps = tMSeqParam[i].taps;
	tob = tMSeqParam[i].tob;

	p = (1 << nStage) - 1;

	/* generate idempotent shift or ml-sequence */
	s = nStage;
	for (i = 0; i <= p; i++) {
		for (k = 0; k < ntap; k++) {
			if (i - taps[k] < 0)
				break;
			else if (i - taps[k] == 0) {
				s += i;
				break;
			} else {
				s += m_pMSequence[i - taps[k]];
			}
		}
		m_pMSequence[i] = (char)(s % 2);
		s = 0;
	}

	/* generate permutation for fast hadamard transform */
	for (i = 0; i <= p - 1; i++) {
		s = 0;
		for (k = 0; k < nStage; k++) {
			s = s * 2 + m_pMSequence[(tob[k] + i) % p];
		}
		m_pPermut[i + 1] = s;
	}
	m_pPermut[0] = 0;
}

void CMSeq::GenerateSequence(float *pData, int nAtt)
{
	int i;
	int nData = 1 << m_nStage;
	float fWave = 0.5 / nAtt;

	for (i = 0; i < nData; i++)
		*pData++ = m_pMSequence[i] ? -fWave : fWave;
}

void CMSeq::CalcImpulse(float *pData)
{
	int nData = 1 << m_nStage;
	int i, j, k, l;
	int ni, nj;
	float a, b;

	if (m_nStage == 0)
		return;

	float *pTmp = new float[nData];
	for (i = 0; i < nData; i++)
		pTmp[i] = pData[i];

	/* permut data & permutation */
	for (l = 1; l < nData; l++) {
		if (m_pPermut[l] <= 0)
			continue;
		i = 0;
		j = l;
		a = pTmp[j];
		for (;;) {
			k = m_pPermut[j];
			m_pPermut[j] = -i;
			if (k <= 0)
				break;
			b = pTmp[k];
			pTmp[k] = a;
			a = b;
			i = j;
			j = k;
		}
	}

	/* fast hadamard trasform */
	ni = 1;
	for (i = 0; i < m_nStage; i++) {
		nj = ni;
		ni *= 2;
		for (k = 0; k <= nData - 1; k += ni) {
			for (j = 0; j < nj; j++) {
				a = pTmp[k + j];
				b = pTmp[k + j + nj];
				pTmp[k + j] = a + b;
				pTmp[k + j + nj] = a - b;
			}
		}
	}

	/* permut data & permutation */
	for (l = 1; l < nData; l++) {
		if (m_pPermut[l] > 0)
			continue;
		i = 0;
		j = l;
		a = pTmp[j];
		for (;;) {
			k = -m_pPermut[j];
			m_pPermut[j] = i;
			if (k <= 0)
				break;
			b = pTmp[k];
			pTmp[k] = a /*- pTmp[0]*/;
			a = b;
			i = j;
			j = k;
		}
	}

	pTmp[0] = pTmp[1];
	for (l = 1; l < nData / 2; l++) {
		a = pTmp[l];
		pTmp[l] = pTmp[nData - l];
		pTmp[nData - l] = a;
	}
	pTmp[nData - 1] = 0;

	for (i = 0; i < nData; i++)
		pData[i] = pTmp[i];

	delete [] pTmp;

	PolarityCheck(nData, pData);
}

void CMSeq::FreeBuffers()
{
	if (m_pMSequence != NULL) {
		delete [] m_pMSequence;
		m_pMSequence = NULL;
	}

	if (m_pPermut != NULL) {
		delete [] m_pPermut;
		m_pPermut = NULL;
	}
}
