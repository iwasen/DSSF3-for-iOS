// Calc.cpp : インプリメンテーション ファイル
//

#import "Calc.h"
#import "Common.h"
#import "Regress.h"
#import "Filter.h"
#import "SetData.h"

#define _sqrt(_param1) (float)sqrt(_param1)
#define _pow(_param1,_param2) (float)pow(_param1,_param2)

const struct FREQBAND g_tFilterTbl[2] = {
	{12, _sqrt(2.0),
		{0, 15.625, 31.25, 62.5, 125, 250, 500, 1000, 2000, 4000, 8000, 16000},
		{0, 16, 31.5, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000}},
	{33, _pow(2.0, 1.0 / 6),
		{0, _pow(10.0, 1.2), _pow(10.0, 1.3), _pow(10.0, 1.4),
		_pow(10.0, 1.5), _pow(10.0, 1.6), _pow(10.0, 1.7), _pow(10.0, 1.8), _pow(10.0, 1.9),
		_pow(10.0, 2.0), _pow(10.0, 2.1), _pow(10.0, 2.2), _pow(10.0, 2.3), _pow(10.0, 2.4),
		_pow(10.0, 2.5), _pow(10.0, 2.6), _pow(10.0, 2.7), _pow(10.0, 2.8), _pow(10.0, 2.9),
		_pow(10.0, 3.0), _pow(10.0, 3.1), _pow(10.0, 3.2), _pow(10.0, 3.3), _pow(10.0, 3.4),
		_pow(10.0, 3.5), _pow(10.0, 3.6), _pow(10.0, 3.7), _pow(10.0, 3.8), _pow(10.0, 3.9),
		_pow(10.0, 4.0), _pow(10.0, 4.1), _pow(10.0, 4.2), _pow(10.0, 4.3)},
		{0, 16, 20, 25, 31.5, 40, 50, 63, 80, 100, 125,
		160, 200, 250, 315, 400, 500, 630, 800, 1000, 1250,
		1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000, 12500,
		16000, 20000}}
};

// STI 変調周波数
const float g_tMtfFreq[N_MTF_FREQ] = {
	0.63, 0.8, 1.0, 1.25, 1.6, 2.0, 2.5,
	3.15, 4.0, 5.0, 6.3, 8.0, 10.0, 12.5
};

static CRFFT g_oRFFT;
static CMSeq g_oMSeq;
static CTSP g_oTSP;

// STI 周波数バンド
static const float tMtfBand[N_MTF_BAND] = {
	125, 250, 500, 1000, 2000, 4000, 8000
};

// RASTI 500Hzバンド変調周波数
static const float tMtf500[N_MTF_500] = {
	1.0, 2.0, 4.0, 8.0
};

// RASTI 2kHzバンド変調周波数
static const float tMtf2000[N_MTF_2000] = {
	0.7, 1.4, 2.8, 5.6, 11.2
};

static float CalcNoisePower(const float *pIRData1, const float *pIRData2, int nData, float fNoise);
static void CalcParamTx(const float *pData1, const float *pData2, int nData, float fRate, int nT0Pos, float fTCustom1, float fTCustom2, Float64 *pT20, Float64 *pT30, Float64 *pTCustom, Float64 *pEDT);
static float CalcRT(const float *pEcho, int nData, float fRate, float fStartLevel, float fEndLevel, float *pReg0 = NULL, float *pReg1 = NULL);
static float CalcEDT(const float *pEcho, int nData, float fRate, int nT0Pos, float *pReg0 = NULL, float *pReg1 = NULL);
static void CalcParamCx(const float *pData, int nData, float fRate, int nT0Pos, float fCCustom, Float64 *pC50, Float64 *pC80, Float64 *pCCustom, Float64 *pD50, Float64 *pTs);
static float CalcC(const float *pData, int nData, float fRate, int nT0Pos, float t, float fNoisePower);
static float CalcD(const float *pData, int nData, float fRate, int nT0Pos, float t, float fNoisePower);
static float CalcTs(const float *pData, int nData, float fRate, int nT0Pos, float fNoisePower);
static void CalcParamIACCx(const float *pDataL, const float *pDataR, int nData, float fRate, int nT0PosL, int nT0PosR, Float64 *pIACCE, Float64 *pIACCL);
static float CalcIACCSub(const float *pDataL, const float *pDataR, int nData, float fRate, int nT0Pos, float t1, float t2);
static float CalcMTI(const float *pIR, int nData, float fRate, const float *pMtfFreq, int nMtfFreq, BOOL bSN, float fSN);
static void CalcParamSTI(const float *pMTI, float fMTI500, float fMTI2000, Float64 *pSTI, Float64 *pSTI_m, Float64 *pSTI_f, Float64 *pRASTI);
static float CalcParamSTISub(const float *pMTI, const float *pTbl1, const float *pTbl2);

void CalcEchoData(const float *pIRData1, const float *pIRData2, float *pEchoData, int nData, float fRate,  float t1, float noise)
{
	float l2, r2, sum, noisePower, power;
	int i, start, end;
	float zero;

	noisePower = CalcNoisePower(pIRData1, pIRData2, nData, noise);

	start = (int)(t1 / 1000 * fRate);
	end = (int)(nData * (1 - noise));

	sum = 0;
	for (i = nData - 1; i >= 0; i--) {
		if (i < end) {
			l2 = (float)pIRData1[i] * (float)pIRData1[i];
			if (pIRData2 != NULL) {
				r2 = (float)pIRData2[i] * (float)pIRData2[i];
				power = (l2 + r2) / 2;
			} else
				power = l2;

			power -= noisePower;
			if (power < 0)
				power = 0;

			sum += power;
		}
		pEchoData[i] = sum;
	}

	zero = pEchoData[start];
	for (i = 0; i < nData; i++) {
		if (pEchoData[i] > 0)
			pEchoData[i] = dB10(pEchoData[i] / zero);
		else
			pEchoData[i] = -1000;
	}
}

float CalcNoisePower(const float *pIRData1, const float *pIRData2, int nData, float fNoise)
{
	float fL2, fR2, fNoisePower;
	int i, nEnd;

	nEnd = (int)(nData * (1 - fNoise));

	fNoisePower = 0;
	for (i = nEnd; i < nData; i++) {
		fL2 = (float)pIRData1[i] * (float)pIRData1[i];
		if (pIRData2 != NULL) {
			fR2 = (float)pIRData2[i] * (float)pIRData2[i];
			fNoisePower += (fL2 + fR2) / 2;
		} else
			fNoisePower += fL2;
	}
	if (nData - nEnd != 0)
		fNoisePower /= nData - nEnd;

	return fNoisePower;
}

void CalcIACCData(const float *pIRLeft, const float *pIRRight, int nData, float *pOutData, int nOutData)
{
	float leftPower, rightPower, totalPower;
	int i, j;
	int offset;
	int nFftSize, nTemp;
	float xt1, yt1, xt2, yt2;

	for (nFftSize = 1, nTemp = nData - 1; nTemp != 0; nFftSize <<= 1, nTemp >>= 1)
		;

	leftPower = 0;
	for (i = 0; i < nData; i++)
		leftPower += (float)pIRLeft[i] * (float)pIRLeft[i];

	rightPower = 0;
	for (i = 0; i < nData; i++)
		rightPower += (float)pIRRight[i] * (float)pIRRight[i];

	totalPower = 2 / (sqrt(leftPower * rightPower) * nFftSize);

	float *pTemp1 = new float[nFftSize];
	float *pTemp2 = new float[nFftSize];

	memcpy(pTemp1, pIRLeft, nData * sizeof(float));
	memcpy(pTemp2, pIRRight, nData * sizeof(float));

	nTemp = nFftSize - nData;
	if (nTemp > 0) {
		memset(pTemp1 + nData, 0, nTemp * sizeof(float));
		memset(pTemp2 + nData, 0, nTemp * sizeof(float));
	}

	g_oRFFT.fft(nFftSize, pTemp1);
	g_oRFFT.fft(nFftSize, pTemp2);

	pTemp1[0] = 0;
	pTemp1[1] = 0;

	for (i = 1; i < nFftSize / 2; i++) {
		j = i * 2;

		xt1 = pTemp1[j];
		yt1 = pTemp1[j + 1];

		xt2 = pTemp2[j];
		yt2 = pTemp2[j + 1];

		pTemp1[j] = xt1 * xt2 + yt1 * yt2;
		pTemp1[j + 1] = xt2 * yt1 - xt1 * yt2;
	}

	g_oRFFT.ifft(nFftSize, pTemp1);

	for (i = 0; i < nOutData; i++) {
		offset = i - nOutData / 2 + nFftSize;
		pOutData[i] = pTemp1[offset % nFftSize] * totalPower;
	}

	delete [] pTemp1;
	delete [] pTemp2;
}

BOOL MakeFilterTbl1(float *pFilterTbl, int nData, float fRate, float fFreqLow, float fFreqHigh)
{
	int i;
	float fFreqStep, f;
	BOOL rc = FALSE;

	fFreqStep = fRate / nData;

	pFilterTbl[0] = 0;
	for (i = 1; i <= nData / 2; i++) {
		f = fFreqStep * i;
		pFilterTbl[i] = pFilterTbl[nData - i] = 1 / ((1 + pow(fFreqLow / f, 16)) * (1 + pow(f / fFreqHigh, 16)));
		rc = TRUE;
	}

	return rc;
}

void CalcFilter(float *pWaveLeft, float *pWaveRight, int nData, const float *pFilterTbl)
{
	int i, j;

	g_oRFFT.fft(nData, pWaveLeft);
	if (pWaveRight != NULL)
		g_oRFFT.fft(nData, pWaveRight);

	int nData2 = nData / 2;
	for (i = 0; i < nData2; i++) {
		j = i * 2;

		pWaveLeft[j] *= pFilterTbl[i] / nData2;
		pWaveLeft[j + 1] *= (i == 0 ? pFilterTbl[nData2] : pFilterTbl[i]) / nData2;

		if (pWaveRight != NULL) {
			pWaveRight[j] *= pFilterTbl[i] / nData2;
			pWaveRight[j + 1] *= (i == 0 ? pFilterTbl[nData2] : pFilterTbl[i]) / nData2;
		}
	}

	g_oRFFT.ifft(nData, pWaveLeft);
	if (pWaveRight != NULL)
		g_oRFFT.ifft(nData, pWaveRight);
}

BOOL CalcFilterAuto(float *pWaveLeft, float *pWaveRight, int nData, float fRate, int nFreq, int band)
{
	if (nFreq == FREQ_ALL)
		return TRUE;

	int nData2 = nData * 2;
	FREQBAND const *pFreqBand = &g_tFilterTbl[band];
	float *pFilterTbl = new float[nData2];
	float *pTmpLeft = NULL;
	float *pTmpRight = NULL;
	BOOL rc;

	pTmpLeft = new float[nData2];
	memcpy(pTmpLeft, pWaveLeft, nData * sizeof(float));
	memset(pTmpLeft + nData, 0, nData * sizeof(float));
	if (pWaveRight != NULL) {
		pTmpRight = new float[nData2];
		memcpy(pTmpRight, pWaveRight, nData * sizeof(float));
		memset(pTmpRight + nData, 0, nData * sizeof(float));
	}

	if (nFreq == FREQ_AFILTER) {
		rc = MakeFilterTbl2(pFilterTbl, nData2, fRate, FILTER_A, 20);
	} else {
		rc = MakeFilterTbl1(pFilterTbl, nData2, fRate, pFreqBand->fRealFreq[nFreq] / pFreqBand->fBandWidth, pFreqBand->fRealFreq[nFreq] * pFreqBand->fBandWidth);
	}

	if (rc)
		CalcFilter(pTmpLeft, pTmpRight, nData2, pFilterTbl);

	delete [] pFilterTbl;

	memcpy(pWaveLeft, pTmpLeft, nData * sizeof(float));
	delete [] pTmpLeft;
	if (pWaveRight != NULL) {
		memcpy(pWaveRight, pTmpRight, nData * sizeof(float));
		delete [] pTmpRight;
	}

	return rc;
}

NSString *GetDispFreq(int nFreq, int band, BOOL bKiro)
{
	NSString *str;

	if (nFreq == FREQ_ALL)
		str = @"All(F)";
	else if (nFreq == FREQ_AFILTER)
		str = @"All(A)";
	else {
		if (bKiro && g_tFilterTbl[band].fDispFreq[nFreq] >= 1000)
			str = [NSString stringWithFormat:@"%gk", g_tFilterTbl[band].fDispFreq[nFreq] / 1000];
		else
			str = [NSString stringWithFormat:@"%g", g_tFilterTbl[band].fDispFreq[nFreq]];
	}

	return str;
}

float CalcParamSpl(const float *pData, int nData, int nMultiplier)
{
	float fLevel;
	float power;
	float tmp;
	int i;

	if (nMultiplier == 0)
		nMultiplier = 1;

	fLevel = 0;
	for (i = 0; i < nData; i++)
		fLevel += (float)pData[i];
	fLevel /= nData;

	power = 0;
	for (i = 0; i < nData; i++) {
		tmp = (float)(pData[i] - fLevel) * nMultiplier;
		power += tmp * tmp;
	}

	return dB10(power / nData);
}
/*
// 自己相関からΔT1を求める方法（べき乗になっていない場合の対処が必要）
void CalcParamDeltaT1(float *pData, int nData, float fRate, float minTime, float *pT0, float *pT1)
{
	float T0Level, T1Level;
	int T0Pos, T1Pos;
	float maxLevel;
	int i;
	float data;
	int startPos;
	BOOL bUpFlag;

	if (pData == NULL) {
		*pT0 = 0;
		*pT1 = 0;
		return;
	}

	float *pWork1 = new float[nData];
	float *pWork2 = new float[nData];
	memcpy(pWork1, pData, nData * sizeof(float));
	memset(pWork2, 0, nData * sizeof(float));
	g_FFT.fft(nData, pWork1, pWork2);
	for (i = 0; i < nData; i++) {
		pWork1[i] = pWork1[i] * pWork1[i] + pWork2[i] * pWork2[i];
		pWork2[i] = 0;
	}
	g_FFT.ifft(nData, pWork1, pWork2);

	maxLevel = 0;
	for (i = 1; i < nData / 2; i++) {
		data = (float)fabs(pData[i]);
		if (data > maxLevel)
			maxLevel = data;
	}

	T0Level = 0;
	T0Pos = 0;
	for (i = 1; i < nData / 2; i++) {
		data = (float)fabs(pData[i]);
		if (data > (float)fabs(pData[i - 1]) && data > (float)fabs(pData[i + 1])) {
			if (data > T0Level) {
				T0Level = data;
				T0Pos = i;
			} else if (T0Level > maxLevel / 5)
				break;
		}
	}

	startPos = (int)(minTime / 1000 * fRate) + 1;
	if (startPos >= nData)
		startPos = nData - 1;

	maxLevel = 0;
	for (i = startPos; i < nData / 2; i++) {
		data = pWork1[i];
		if (data > maxLevel)
			maxLevel = data;
	}

	T1Level = 0;
	T1Pos = 0;
	bUpFlag = FALSE;
	for (i = startPos; i < nData / 2; i++) {
		data = pWork1[i];
		if (data > pWork1[i - 1] && data > pWork1[i + 1]) {
			if (bUpFlag) {
				if (data > T1Level) {
					T1Level = data;
					T1Pos = i;
				} else if (T1Level > maxLevel / 2)
					break;
			} else {
				if (T1Level != 0 && data > T1Level && data > maxLevel / 10)
					bUpFlag = TRUE;
				else {
					T1Level = data;
					T1Pos = i;
				}
			}
		}
	}

	delete [] pWork1;
	delete [] pWork2;

	*pT0 = (float)T0Pos / fRate * 1000;
	*pT1 = (float)(T0Pos + T1Pos) / fRate * 1000;
}
*/
void CalcParamDeltaT1(const float *pData, int nData, float fRate, float minTime, Float64 *pT0, Float64 *pT1, int *pT0Pos)
{
	float T1Level;
	int T0Pos = 0, T1Pos;
	float maxLevel;
	int i;
	float data;
	int startPos;
	BOOL bUpFlag;

	if (pData == NULL) {
		*pT0 = 0;
		*pT1 = 0;
		*pT0Pos = 0;
		return;
	}

	maxLevel = 0;
	for (i = 1; i < nData / 2; i++) {
		data = fabs(pData[i]);
		if (data > maxLevel)
			maxLevel = data;
	}

	for (i = 1; i < nData / 2; i++) {
		data = fabs(pData[i]);
		if (data > fabs(pData[i - 1]) && data > fabs(pData[i + 1])) {
			if (data > maxLevel / 5) {
				T0Pos = i;
				break;
			}
		}
	}

	startPos = (int)(T0Pos + minTime / 1000 * fRate) + 1;
	if (startPos >= nData)
		startPos = nData - 1;

	maxLevel = 0;
	for (i = startPos; i < nData / 2; i++) {
		data = fabs(pData[i]);
		if (data > maxLevel)
			maxLevel = data;
	}

	T1Level = 0;
	T1Pos = 0;
	bUpFlag = FALSE;
	for (i = startPos; i < nData / 2; i++) {
		data = fabs(pData[i]);
		if (data > fabs(pData[i - 1]) && data > fabs(pData[i + 1])) {
			if (bUpFlag) {
				if (data > T1Level) {
					T1Level = data;
					T1Pos = i;
				} else if (T1Level > maxLevel / 2)
					break;
			} else {
				if (T1Level != 0 && data > T1Level && data > maxLevel / 10)
					bUpFlag = TRUE;
				else {
					T1Level = data;
					T1Pos = i;
				}
			}
		}
	}

	*pT0 = (float)T0Pos / fRate * 1000;
	*pT1 = (float)T1Pos / fRate * 1000;
	*pT0Pos = T0Pos;
}

#define NAVR	64
#define MAX_A	20
float CalcParamTSub(const float *pData1, const float *pData2, int nData, float fRate, float t1, float endLevel, BOOL bAuto, float noise, Float64 *pDev, Float64 *pAVal, Float64 *pEndTime)
{
	float *pEchoData;
	float noiseLevel, l2, r2;
	float fLevel;
	int noisePos;
	int i, j, k;
	int startPos, endPos;
	float a;

	pEchoData = new float[nData];
	CalcEchoData(pData1, pData2, pEchoData, nData, fRate, t1, noise);

	if (pAVal != NULL) {
		if (pEchoData[0] != 0) {
			*pAVal = sqrt(1 / (pow(10.0, pEchoData[0] / 10.0) - 1));
			if (*pAVal > MAX_A)
				*pAVal = MAX_A;
		} else
			*pAVal = MAX_A;
	}

	startPos = (int)(t1 / 1000 * fRate);
	noisePos = (int)(nData * (1 - noise));

	if (bAuto) {
		if (noise == 0)
			noise = 0.5;
		noiseLevel = 0;
		for (i = noisePos; i < nData; i++) {
			l2 = (float)pData1[i] * (float)pData1[i];
			if (pData2 != NULL) {
				r2 = (float)pData2[i] * (float)pData2[i];
				noiseLevel += (l2 + r2) / 2;
			} else
				noiseLevel += l2;
		}
		noiseLevel /= (nData - noisePos);

		endPos = 0;
		for (i = startPos; i < noisePos; i++) {
			fLevel = 0;
			for (j = 0; j < NAVR; j++) {
				k = i + j;
				if (k < nData) {
					l2 = (float)pData1[k] * (float)pData1[k];
					if (pData2 != NULL) {
						r2 = (float)pData2[k] * (float)pData2[k];
						fLevel += (l2 + r2) / 2;
					} else
						fLevel += l2;
				}
			}
			fLevel /= NAVR;

			if (fLevel < noiseLevel * 3) {
				endPos = i;
				break;
			}
		}
	} else {
		endPos = nData - 1;
		for (i = startPos; i < nData; i++) {
			if (pEchoData[i] < pEchoData[startPos] + endLevel) {
				endPos = i;
				break;
			}
		}
	}

	if (startPos >= nData)
		startPos = 0;

	if (endPos >= nData)
		endPos = nData - 1;

	if (startPos >= endPos)
		endPos = (startPos < noisePos) ? noisePos : nData - 1;

	a = Regress1(pEchoData + startPos, endPos - startPos, 0, (float)1 / fRate);

	delete [] pEchoData;

	if (pDev != NULL)
		*pDev = a;

	if (pEndTime != NULL)
		*pEndTime = endPos / fRate;

	return -60.0 / a;
}

#define MAX_WIACC	50
void CalcParamIACC(const float *pIACCData, int nIACCData, float fRate, Float64 *pIACC, Float64 *pTIACC, Float64 *pWIACC, float wLevel, Float64 *pWIACC1, Float64 *pWIACC2)
{
	float IACC;
	int nT1, nT2;
	int i, nIACCPos = 0;
	int wPos1, wPos2;
	float wt1, wt2;

/*
	float maxIACC = pIACCData[0];
	for (i = 1; i < nIACCData; i++) {
		if (pIACCData[i] > maxIACC)
			maxIACC = pIACCData[i];
	}

	maxIACC *= (float)0.8;
	IACC = -1;
	nIACCPos = 0;
	for (i = 1; i < nIACCData - 1; i++) {
		if (pIACCData[i] > maxIACC && abs(i - nIACCData / 2) < abs(nIACCPos - nIACCData / 2) &&
					pIACCData[i] >= pIACCData[i - 1] && pIACCData[i] >= pIACCData[i + 1]) {
			IACC = pIACCData[i];
			nIACCPos = i;
		}
	}
*/
	nT1 = nIACCData / 2 - (int)(fRate / 1000);
	if (nT1 < 0)
		nT1 = 0;
	nT2 = nIACCData / 2 + (int)(fRate / 1000);
	if (nT2 > nIACCData)
		nT2 = nIACCData;

	IACC = -1;
	for (i = nT1; i < nT2; i++) {
		if (pIACCData[i] > IACC) {
			IACC = pIACCData[i];
			nIACCPos = i;
		}
	}

	if (pIACC != NULL)
		*pIACC = (float)IACC;

	if (pTIACC != NULL)
		*pTIACC = (float)(nIACCPos - nIACCData / 2) / fRate * 1000;

	if (wLevel > 0) {
		wLevel = (1 - wLevel) * IACC;
		wPos1 = 0;
		for (i = nIACCPos; i >= 0; i--) {
			if (pIACCData[i] < wLevel) {
				wPos1 = i;
				break;
			}
		}
		wt1 = (nIACCPos - wPos1 - (wLevel - pIACCData[wPos1]) / (pIACCData[wPos1 + 1] - pIACCData[wPos1])) / fRate * 1000;

		wPos2 = nIACCData;
		for (i = nIACCPos; i < nIACCData; i++) {
			if (pIACCData[i] < wLevel) {
				wPos2 = i;
				break;
			}
		}
		wt2 = (wPos2 - nIACCPos - (wLevel - pIACCData[wPos2]) / (pIACCData[wPos2 - 1] - pIACCData[wPos2])) / fRate * 1000;
	} else {
		wt1 = 0;
		wt2 = 0;
	}

	if (pWIACC1 != NULL)
		*pWIACC1 = wt1;

	if (pWIACC2 != NULL)
		*pWIACC2 = wt2;

	if (pWIACC != NULL) {
		*pWIACC = wt1 + wt2;
		if (*pWIACC > MAX_WIACC)
			*pWIACC = MAX_WIACC;
	}
}

void CalcParamTx(const float *pData1, const float *pData2, int nData, float fRate, int nT0Pos, float fTCustom1, float fTCustom2, Float64 *pT20, Float64 *pT30, Float64 *pTCustom, Float64 *pEDT)
{
	float *pEcho = new float[nData];
	CalcEchoData(pData1, pData2, pEcho, nData, fRate, 0, 0.5);

	float fOffset = pEcho[0] - pEcho[nT0Pos];
	for (int i = 0; i < nData; i++)
		pEcho[i] += fOffset;

	*pT20 = CalcRT(pEcho, nData, fRate, -5, -25);
	*pT30 = CalcRT(pEcho, nData, fRate, -5, -35);
	*pTCustom = CalcRT(pEcho, nData, fRate, fTCustom1, fTCustom2);
	*pEDT = CalcEDT(pEcho, nData, fRate, nT0Pos);

	delete [] pEcho;
}

void CalcParamTx2(const float *pData1, const float *pData2, int nData, float fRate, int nT0Pos, float *pT20Reg0, float *pT20Reg1, float *pT30Reg0, float *pT30Reg1, float *pEDTReg0, float *pEDTReg1)
{
	float *pEcho = new float[nData];
	CalcEchoData(pData1, pData2, pEcho, nData, fRate, 0, 0.5);

	float fOffset = pEcho[0] - pEcho[nT0Pos];
	for (int i = 0; i < nData; i++)
		pEcho[i] += fOffset;

	CalcRT(pEcho, nData, fRate, -5, -25, pT20Reg0, pT20Reg1);
	CalcRT(pEcho, nData, fRate, -5, -35, pT30Reg0, pT30Reg1);
	CalcEDT(pEcho, nData, fRate, nT0Pos, pEDTReg0, pEDTReg1);

	delete [] pEcho;
}

float CalcRT(const float *pEcho, int nData, float fRate, float fStartLevel, float fEndLevel, float *pReg0, float *pReg1)
{
	int i;
	int nStartPos = 0;
	int nEndPos = nData - 1;

	for (i = 0; i < nData; i++) {
		if (pEcho[i] <= fStartLevel) {
			nStartPos = i;
			break;
		}
	}

	for (; i < nData; i++) {
		if (pEcho[i] <= fEndLevel) {
			nEndPos = i;
			break;
		}
	}

	float fReg0, fReg1;
	Regress2(pEcho + nStartPos, nEndPos - nStartPos, 0, (float)1 / fRate, &fReg0, &fReg1);

	if (pReg0 != NULL)
		*pReg0 = fReg0 - fReg1 * nStartPos / fRate;

	if (pReg1 != NULL)
		*pReg1 = fReg1;

	return -60.0 / fReg1;
}

float CalcEDT(const float *pEcho, int nData, float fRate, int nT0Pos, float *pReg0, float *pReg1)
{
	int i;
	int nEndPos = nData - 1;

	float fEndLevel = pEcho[nT0Pos] - 10;
	for (i = nT0Pos; i < nData; i++) {
		if (pEcho[i] <= fEndLevel) {
			nEndPos = i;
			break;
		}
	}

	float fReg0, fReg1;
	Regress2(pEcho + nT0Pos, nEndPos - nT0Pos, 0, (float)1 / fRate, &fReg0, &fReg1);

	if (pReg0 != NULL)
		*pReg0 = fReg0;

	if (pReg1 != NULL)
		*pReg1 = fReg1;

	return -60.0 / fReg1;
}

void CalcParamCx(const float *pData, int nData, float fRate, int nT0Pos, float fCCustom, Float64 *pC50, Float64 *pC80, Float64 *pCCustom, Float64 *pD50, Float64 *pTs)
{
	float fNoisePower = CalcNoisePower(pData, NULL, nData, 0.5);

	*pC50 = CalcC(pData, nData, fRate, nT0Pos, 0.05, fNoisePower);
	*pC80 = CalcC(pData, nData, fRate, nT0Pos, 0.08, fNoisePower);
	*pCCustom = CalcC(pData, nData, fRate, nT0Pos, fCCustom / 1000, fNoisePower);
	*pD50 = CalcD(pData, nData, fRate, nT0Pos, 0.05, fNoisePower);
	*pTs = CalcTs(pData, nData, fRate, nT0Pos, fNoisePower);
}

float CalcC(const float *pData, int nData, float fRate, int nT0Pos, float t, float fNoisePower)
{
	float p1 = 0;
	float p2 = 0;
	float pw;
	int nPos;
	int i;

	// 直接音の位置を原点に補正
	pData += nT0Pos;
	nData -= nT0Pos;

	nPos = (int)(t * fRate);
	if (nPos > nData)
		nPos = nData;

	for (i = 0; i < nPos; i++) {
		pw = (float)pData[i] * pData[i] - fNoisePower;
		if (pw < 0)
			pw = 0;
		p1 += pw;
	}

	for (; i < nData; i++) {
		pw = (float)pData[i] * pData[i] - fNoisePower;
		if (pw < 0)
			pw = 0;
		p2 += pw;
	}

	return dB10(p1 / p2);
}

float CalcD(const float *pData, int nData, float fRate, int nT0Pos, float t, float fNoisePower)
{
	float p1 = 0;
	float p2 = 0;
	float pw;
	int nPos;
	int i;

	// 直接音の位置を原点に補正
	pData += nT0Pos;
	nData -= nT0Pos;

	nPos = (int)(t * fRate);
	if (nPos > nData)
		nPos = nData;

	for (i = 0; i < nPos; i++) {
		pw = (float)pData[i] * pData[i] - fNoisePower;
		if (pw < 0)
			pw = 0;
		p1 += pw;
	}

	p2 = p1;
	for (; i < nData; i++) {
		pw = (float)pData[i] * pData[i] - fNoisePower;
		if (pw < 0)
			pw = 0;
		p2 += pw;
	}

	return p1 / p2 * 100;
}

float CalcTs(const float *pData, int nData, float fRate, int nT0Pos, float fNoisePower)
{
	float s1 = 0;
	float s2 = 0;
	float pw;
	int i;

	// 直接音の位置を原点に補正
	pData += nT0Pos;
	nData -= nT0Pos;

	for (i = 0; i < nData; i++) {
		pw = (float)pData[i] * pData[i] - fNoisePower;
		if (pw < 0)
			pw = 0;

		s1 += pw * i / fRate;
		s2 += pw;
	}

	return s1 / s2;
}

void CalcParamIACCx(const float *pDataL, const float *pDataR, int nData, float fRate, int nT0PosL, int nT0PosR, Float64 *pIACCE, Float64 *pIACCL)
{
	int nT0Pos = min(nT0PosL, nT0PosR);

	*pIACCE = CalcIACCSub(pDataL, pDataR, nData, fRate, nT0Pos, 0, 0.08);
	*pIACCL = CalcIACCSub(pDataL, pDataR, nData, fRate, nT0Pos, 0.08, 0.750);
}

float CalcIACCSub(const float *pDataL, const float *pDataR, int nData, float fRate, int nT0Pos, float t1, float t2)
{
	int nIACCSize = (int)(fRate / 1000);
	nIACCSize += nIACCSize - 1;
	float *pIACCData = new float[nIACCSize];
	int nT1Pos = nT0Pos + (int)(t1 * fRate);
	int nT2Pos = nT0Pos + (int)(t2 * fRate);
	Float64 fIACC;

	if (nT1Pos > nData)
		return 0;

	if (nT2Pos > nData)
		nT2Pos = nData;

	nData = nT2Pos - nT1Pos;
	if (nData <= nIACCSize)
		return 0;

	pDataL += nT1Pos;
	pDataR += nT1Pos;

	CalcIACCData(pDataL, pDataR, nData, pIACCData, nIACCSize);
	CalcParamIACC(pIACCData, nIACCSize, fRate, &fIACC, NULL, NULL, 0, NULL, NULL);

	delete [] pIACCData;

	return fIACC;
}

BOOL CalcAcParam(DbImpulseRec *pDbImpulseRec, HWAVEDATA hWaveData, DbAcParamRec *pDbAcParamRec, float fRate, id obj, SEL sel)
{
	const FREQBAND *pFreqBand;
	int nFreq;
	float *pIRLeft = NULL, *pIRRight = NULL;
	float *pIRLeft2 = NULL, *pIRRight2 = NULL;
	int i, j, n;
	int nData, nData2;
	float *pIACCData = NULL;
	int nIACCData = 0;
	NSString *str, *str2;
	BOOL bAbort = FALSE;
	int nFreqIndex;
	int nT0PosL = 0, nT0PosR = 0;
	float fMTIL[N_MTF_BAND], fMTIR[N_MTF_BAND];
	float fMTI500L, fMTI500R;
	float fMTI2000L, fMTI2000R;

	nData = 1 << pDbImpulseRec->nMeasTime;

	pIRLeft = new float[nData];
	pIRLeft2 = new float[nData];
	if (pDbImpulseRec->nChannel == 2) {
		nIACCData = (int)(fRate / 500);
		nIACCData += nIACCData - 1;
		pIRRight = new float[nData];
		pIRRight2 = new float[nData];
		pIACCData = new float[nIACCData];
	}

	nData2 = ReadWaveData(hWaveData, pIRLeft, pIRRight, nData);

	int nMethod = pDbImpulseRec->nBit & 0x03;
	CIRMethod *pMethod;
	if (nMethod == METHOD_MSEQ)
		pMethod = &g_oMSeq;
	else
		pMethod = &g_oTSP;

	pMethod->InitMethod(pDbImpulseRec->bImpulseData ? 0 : pDbImpulseRec->nMeasTime);
	pMethod->CalcImpulse(pIRLeft);
	if (pIRRight != NULL)
		pMethod->CalcImpulse(pIRRight);

	pFreqBand = &g_tFilterTbl[setData.Imp.nFreqBand];

	pDbAcParamRec->nImpulseID = pDbAcParamRec->nImpulseID;
	pDbAcParamRec->dbAcParamCond.nFreqBand = setData.Imp.nFreqBand;
	pDbAcParamRec->dbAcParamCond.bAFilter = setData.Imp.bAFilter;
	pDbAcParamRec->dbAcParamCond.nSplRefData = setData.Imp.nSplRefData;
	pDbAcParamRec->dbAcParamCond.fSplRefLevel = setData.Imp.fSplRefLevel;
	pDbAcParamRec->dbAcParamCond.fDT1MinTime = setData.Imp.fDT1MinTime;
	pDbAcParamRec->dbAcParamCond.fTsubEnd = setData.Imp.fTsubEnd;
	pDbAcParamRec->dbAcParamCond.bTsubAuto = setData.Imp.bTsubAuto;
	pDbAcParamRec->dbAcParamCond.fTsubNoise = setData.Imp.fTsubNoise;
	pDbAcParamRec->dbAcParamCond.fWIACCLevel = setData.Imp.fWIACCLevel;
	pDbAcParamRec->dbAcParamCond.fPrefSPL = setData.Imp.fPrefSPL;
	pDbAcParamRec->dbAcParamCond.fPrefTauE = setData.Imp.fPrefTauE;
	pDbAcParamRec->dbAcParamCond.fGRefData = setData.Imp.fGRefData;
	pDbAcParamRec->dbAcParamCond.fTCustom1 = setData.Imp.fTCustom1;
	pDbAcParamRec->dbAcParamCond.fTCustom2 = setData.Imp.fTCustom2;
	pDbAcParamRec->dbAcParamCond.fCCustom = setData.Imp.fCCustom;

	memset(fMTIL, 0, sizeof(fMTIL));
	fMTI500L = 0;
	fMTI2000L = 0;

	memset(fMTIR, 0, sizeof(fMTIR));
	fMTI500R = 0;
	fMTI2000R = 0;

	n = 0;
	nFreqIndex = 0;
	for (i = 0; nFreqIndex < pFreqBand->nData; i++) {
		if (i == 0)
			nFreq = FREQ_ALL;
		else if (pDbAcParamRec->dbAcParamCond.bAFilter && i == 1)
			nFreq = FREQ_AFILTER;
		else {
			nFreq = ++nFreqIndex;
			if (setData.Imp.nStartFreq == 0 || nFreq < setData.Imp.nStartFreq || nFreq > setData.Imp.nEndFreq + 1)
				continue;

			if (pFreqBand->fRealFreq[nFreq] > fRate / 2)
				break;
		}

		str = GetDispFreq(nFreq, setData.Imp.nFreqBand, YES);
		if (nFreq == FREQ_ALL || nFreq == FREQ_AFILTER)
			str2 = [NSString stringWithFormat:@"%@ [%@]", (NSString *)pDbImpulseRec->sTitle, str];
		else
			str2 = [NSString stringWithFormat:@"%@ [%@Hz]", (NSString *)pDbImpulseRec->sTitle, str];
		[obj performSelectorOnMainThread:sel withObject:str2 waitUntilDone:YES];
//		pProgressDlg->SetProgressBarSub(100 * nFreqIndex / pFreqBand->nData);

		memcpy(pIRLeft2, pIRLeft, nData * sizeof(float));
		if (pIRRight != NULL)
			memcpy(pIRRight2, pIRRight, nData * sizeof(float));

		if (!CalcFilterAuto(pIRLeft2, pIRRight2, nData, fRate, nFreq, setData.Imp.nFreqBand))
			continue;

		pDbAcParamRec->dbAcParamData[n].nFreq = nFreq;

		// SPL
		pDbAcParamRec->dbAcParamData[n].fSplL = CalcParamSpl(pIRLeft2, nData2, pDbImpulseRec->nMultiplier);
		if (pIRRight2 != NULL)
			pDbAcParamRec->dbAcParamData[n].fSplR = CalcParamSpl(pIRRight2, nData2, pDbImpulseRec->nMultiplier);

		// ΔT1
		if (i == 0) {
			CalcParamDeltaT1(pIRLeft2, nData2, fRate, setData.Imp.fDT1MinTime, &pDbAcParamRec->dbAcParamResult.fDeltaT0L, &pDbAcParamRec->dbAcParamResult.fDeltaT1L, &nT0PosL);
			if (pIRRight2 != NULL)
				CalcParamDeltaT1(pIRRight2, nData2, fRate, setData.Imp.fDT1MinTime, &pDbAcParamRec->dbAcParamResult.fDeltaT0R, &pDbAcParamRec->dbAcParamResult.fDeltaT1R, &nT0PosR);
		}

		// Tsub
		pDbAcParamRec->dbAcParamData[n].tSubL = CalcParamTSub(pIRLeft2, NULL, nData2, fRate, pDbAcParamRec->dbAcParamResult.fDeltaT1L, setData.Imp.fTsubEnd, setData.Imp.bTsubAuto, setData.Imp.fTsubNoise, NULL, &pDbAcParamRec->dbAcParamData[n].fAL);
		if (pIRRight2 != NULL)
			pDbAcParamRec->dbAcParamData[n].tSubR = CalcParamTSub(pIRRight2, NULL, nData2, fRate, pDbAcParamRec->dbAcParamResult.fDeltaT1R, setData.Imp.fTsubEnd, setData.Imp.bTsubAuto, setData.Imp.fTsubNoise, NULL, &pDbAcParamRec->dbAcParamData[n].fAR);

		// IACC
		if (pIRRight2 != NULL) {
			CalcIACCData(pIRLeft2, pIRRight2, nData2, pIACCData, nIACCData);
			CalcParamIACC(pIACCData, nIACCData, fRate, &pDbAcParamRec->dbAcParamData[n].fIACC, &pDbAcParamRec->dbAcParamData[n].tIACC, &pDbAcParamRec->dbAcParamData[n].wIACC, setData.Imp.fWIACCLevel);
		}

		// G
		pDbAcParamRec->dbAcParamData[n].fG_L = CalcParamSpl(pIRLeft2, nData2, pDbImpulseRec->nMultiplier) - setData.Imp.fGRefData;
		if (pIRRight2 != NULL)
			pDbAcParamRec->dbAcParamData[n].fG_R = CalcParamSpl(pIRRight2, nData2, pDbImpulseRec->nMultiplier) - setData.Imp.fGRefData;

		// T20, T30, T_custom, EDT
		CalcParamTx(pIRLeft2, NULL, nData2, fRate, nT0PosL,
				setData.Imp.fTCustom1, setData.Imp.fTCustom2,
				&pDbAcParamRec->dbAcParamData[n].fT20_L,
				&pDbAcParamRec->dbAcParamData[n].fT30_L,
				&pDbAcParamRec->dbAcParamData[n].fTCustom_L,
				&pDbAcParamRec->dbAcParamData[n].fEDT_L);
		if (pIRRight2 != NULL) {
			CalcParamTx(pIRRight2, NULL, nData2, fRate, nT0PosR,
					setData.Imp.fTCustom1, setData.Imp.fTCustom2,
					&pDbAcParamRec->dbAcParamData[n].fT20_R,
					&pDbAcParamRec->dbAcParamData[n].fT30_R,
					&pDbAcParamRec->dbAcParamData[n].fTCustom_R,
					&pDbAcParamRec->dbAcParamData[n].fEDT_R);
		}

		// C50, C80, C_custom, D50, Ts
		CalcParamCx(pIRLeft2, nData2, fRate, nT0PosL, setData.Imp.fCCustom,
				&pDbAcParamRec->dbAcParamData[n].fC50_L,
				&pDbAcParamRec->dbAcParamData[n].fC80_L,
				&pDbAcParamRec->dbAcParamData[n].fCCustom_L,
				&pDbAcParamRec->dbAcParamData[n].fD50_L,
				&pDbAcParamRec->dbAcParamData[n].fTs_L);
		if (pIRRight2 != NULL) {
			CalcParamCx(pIRRight2, nData2, fRate, nT0PosR, setData.Imp.fCCustom,
					&pDbAcParamRec->dbAcParamData[n].fC50_R,
					&pDbAcParamRec->dbAcParamData[n].fC80_R,
					&pDbAcParamRec->dbAcParamData[n].fCCustom_R,
					&pDbAcParamRec->dbAcParamData[n].fD50_R,
					&pDbAcParamRec->dbAcParamData[n].fTs_R);
		}

		// IACCE, IACCL
		if (pIRRight2 != NULL) {
			CalcParamIACCx(pIRLeft2, pIRRight2, nData2, fRate, nT0PosL, nT0PosR,
					&pDbAcParamRec->dbAcParamData[n].fIACCE,
					&pDbAcParamRec->dbAcParamData[n].fIACCL);
		}

		// MTI
		if (setData.Imp.nFreqBand == 0) {
			for (j = 0; j < N_MTF_BAND; j++) {
				if (g_tFilterTbl[0].fRealFreq[nFreq] == tMtfBand[j]) {
					fMTIL[j] = CalcMTI(pIRLeft2, nData2, fRate, g_tMtfFreq, N_MTF_FREQ, FALSE, 0);
					if (pIRRight2 != NULL)
						fMTIR[j] = CalcMTI(pIRRight2, nData2, fRate, g_tMtfFreq, N_MTF_FREQ, FALSE, 0);
				}
			}

			if (g_tFilterTbl[0].fRealFreq[nFreq] == 500) {
				fMTI500L = CalcMTI(pIRLeft2, nData2, fRate, tMtf500, N_MTF_500, FALSE, 0);
				if (pIRRight2 != NULL)
					fMTI500R = CalcMTI(pIRRight2, nData2, fRate, tMtf500, N_MTF_500, FALSE, 0);
			}

			if (g_tFilterTbl[0].fRealFreq[nFreq] == 2000) {
				fMTI2000L = CalcMTI(pIRLeft2, nData2, fRate, tMtf2000, N_MTF_2000, FALSE, 0);
				if (pIRRight2 != NULL)
					fMTI2000R = CalcMTI(pIRRight2, nData2, fRate, tMtf2000, N_MTF_2000, FALSE, 0);
			}
		}

		n++;
	}
	pDbAcParamRec->nDataNum = n;

	if (!bAbort) {
		// STI
		for (i = 0; i < N_MTF_BAND; i++) {
			if (fMTIL[i] == 0) {
				memcpy(pIRLeft2, pIRLeft, nData * sizeof(float));
				if (pIRRight != NULL)
					memcpy(pIRRight2, pIRRight, nData * sizeof(float));

				if (!CalcFilterAuto(pIRLeft2, pIRRight2, nData, fRate, i + 4, 0))
					continue;

				fMTIL[i] = CalcMTI(pIRLeft2, nData2, fRate, g_tMtfFreq, N_MTF_FREQ, FALSE, 0);
				if (pIRRight2 != NULL)
					fMTIR[i] = CalcMTI(pIRRight2, nData2, fRate, g_tMtfFreq, N_MTF_FREQ, FALSE, 0);
			}
		}
		if (fMTI500L == 0) {
			memcpy(pIRLeft2, pIRLeft, nData * sizeof(float));
			if (pIRRight != NULL)
				memcpy(pIRRight2, pIRRight, nData * sizeof(float));

			if (CalcFilterAuto(pIRLeft2, pIRRight2, nData, fRate, 6, 0)) {
				fMTI500L = CalcMTI(pIRLeft2, nData2, fRate, tMtf500, N_MTF_500, FALSE, 0);
				if (pIRRight2 != NULL)
					fMTI500R = CalcMTI(pIRRight2, nData2, fRate, tMtf500, N_MTF_500, FALSE, 0);
			}
		}
		if (fMTI2000L == 0) {
			memcpy(pIRLeft2, pIRLeft, nData * sizeof(float));
			if (pIRRight != NULL)
				memcpy(pIRRight2, pIRRight, nData * sizeof(float));

			if (CalcFilterAuto(pIRLeft2, pIRRight2, nData, fRate, 8, 0)) {
				fMTI2000L = CalcMTI(pIRLeft2, nData2, fRate, tMtf2000, N_MTF_2000, FALSE, 0);
				if (pIRRight2 != NULL)
					fMTI2000R = CalcMTI(pIRRight2, nData2, fRate, tMtf2000, N_MTF_2000, FALSE, 0);
			}
		}
		CalcParamSTI(fMTIL, fMTI500L, fMTI2000L, &pDbAcParamRec->dbAcParamResult.fSTI_L, &pDbAcParamRec->dbAcParamResult.fSTIM_L, &pDbAcParamRec->dbAcParamResult.fSTIF_L, &pDbAcParamRec->dbAcParamResult.fRASTI_L);
		if (pIRRight2 != NULL)
			CalcParamSTI(fMTIR, fMTI500R, fMTI2000R, &pDbAcParamRec->dbAcParamResult.fSTI_R, &pDbAcParamRec->dbAcParamResult.fSTIM_R, &pDbAcParamRec->dbAcParamResult.fSTIF_R, &pDbAcParamRec->dbAcParamResult.fRASTI_R);
	}

	if (pIRLeft != NULL)
		delete [] pIRLeft;

	if (pIRRight != NULL)
		delete [] pIRRight;

	if (pIRLeft2 != NULL)
		delete [] pIRLeft2;

	if (pIRRight2 != NULL)
		delete [] pIRRight2;

	if (pIACCData != NULL)
		delete [] pIACCData;

	return bAbort;
}

void CalcTsub(const DbImpulseRec *pDbImpulseRec, HWAVEDATA hWaveData, DbAcParamRec *pDbAcParamRec, float fRate)
{
	const FREQBAND *pFreqBand;
	float *pIRLeft = NULL, *pIRRight = NULL;
	float *pIRLeft2 = NULL, *pIRRight2 = NULL;
	int i;
	int nData, nData2;

	nData = 1 << pDbImpulseRec->nMeasTime;

	pIRLeft = new float[nData];
	pIRLeft2 = new float[nData];
	if (pDbImpulseRec->nChannel == 2) {
		pIRRight = new float[nData];
		pIRRight2 = new float[nData];
	}

	nData2 = ReadWaveData(hWaveData, pIRLeft, pIRRight, nData);

	int nMethod = pDbImpulseRec->nBit & 0x03;
	CIRMethod *pMethod;
	if (nMethod == METHOD_MSEQ)
		pMethod = &g_oMSeq;
	else
		pMethod = &g_oTSP;

	pMethod->InitMethod(pDbImpulseRec->bImpulseData ? 0 : pDbImpulseRec->nMeasTime);
	pMethod->CalcImpulse(pIRLeft);
	if (pIRRight != NULL)
		pMethod->CalcImpulse(pIRRight);

	pFreqBand = &g_tFilterTbl[pDbAcParamRec->dbAcParamCond.nFreqBand];

	for (i = 0; i < pDbAcParamRec->nDataNum; i++) {
		memcpy(pIRLeft2, pIRLeft, nData * sizeof(float));
		if (pIRRight != NULL)
			memcpy(pIRRight2, pIRRight, nData * sizeof(float));

		CalcFilterAuto(pIRLeft2, pIRRight2, nData, fRate, pDbAcParamRec->dbAcParamData[i].nFreq, pDbAcParamRec->dbAcParamCond.nFreqBand);

		pDbAcParamRec->dbAcParamData[i].tSubL = CalcParamTSub(pIRLeft2, NULL, nData2, fRate, pDbAcParamRec->dbAcParamResult.fDeltaT1L, pDbAcParamRec->dbAcParamCond.fTsubEnd, pDbAcParamRec->dbAcParamCond.bTsubAuto, pDbAcParamRec->dbAcParamCond.fTsubNoise, NULL, &pDbAcParamRec->dbAcParamData[i].fAL);
		if (pIRRight2 != NULL)
			pDbAcParamRec->dbAcParamData[i].tSubR = CalcParamTSub(pIRRight2, NULL, nData2, fRate, pDbAcParamRec->dbAcParamResult.fDeltaT1R, pDbAcParamRec->dbAcParamCond.fTsubEnd, pDbAcParamRec->dbAcParamCond.bTsubAuto, pDbAcParamRec->dbAcParamCond.fTsubNoise, NULL, &pDbAcParamRec->dbAcParamData[i].fAR);
	}

	if (pIRLeft != NULL)
		delete [] pIRLeft;

	if (pIRRight != NULL)
		delete [] pIRRight;

	if (pIRLeft2 != NULL)
		delete [] pIRLeft2;

	if (pIRRight2 != NULL)
		delete [] pIRRight2;
}

void CalcIACC(const DbImpulseRec *pDbImpulseRec, HWAVEDATA hWaveData, DbAcParamRec *pDbAcParamRec, float fRate)
{
	const FREQBAND *pFreqBand;
	float *pIRLeft = NULL, *pIRRight = NULL;
	float *pIRLeft2 = NULL, *pIRRight2 = NULL;
	float *pIACCData = NULL;
	int nIACCData;
	int i;
	int nData, nData2;

	nData = 1 << pDbImpulseRec->nMeasTime;
	nIACCData = (int)(fRate / 500);
	nIACCData += nIACCData - 1;

	pIRLeft = new float[nData];
	pIRLeft2 = new float[nData];
	if (pDbImpulseRec->nChannel == 2) {
		pIRRight = new float[nData];
		pIRRight2 = new float[nData];
		pIACCData = new float[nIACCData];
	}

	nData2 = ReadWaveData(hWaveData, pIRLeft, pIRRight, nData);

	int nMethod = pDbImpulseRec->nBit & 0x03;
	CIRMethod *pMethod;
	if (nMethod == METHOD_MSEQ)
		pMethod = &g_oMSeq;
	else
		pMethod = &g_oTSP;

	pMethod->InitMethod(pDbImpulseRec->bImpulseData ? 0 : pDbImpulseRec->nMeasTime);
	pMethod->CalcImpulse(pIRLeft);
	if (pIRRight != NULL)
		pMethod->CalcImpulse(pIRRight);

	pFreqBand = &g_tFilterTbl[pDbAcParamRec->dbAcParamCond.nFreqBand];

	for (i = 0; i < pDbAcParamRec->nDataNum; i++) {
		memcpy(pIRLeft2, pIRLeft, nData * sizeof(float));
		if (pIRRight != NULL)
			memcpy(pIRRight2, pIRRight, nData * sizeof(float));

		CalcFilterAuto(pIRLeft2, pIRRight2, nData, fRate, pDbAcParamRec->dbAcParamData[i].nFreq, pDbAcParamRec->dbAcParamCond.nFreqBand);

		if (pIRRight2 != NULL) {
			CalcIACCData(pIRLeft2, pIRRight2, nData2, pIACCData, nIACCData);
			CalcParamIACC(pIACCData, nIACCData, fRate, &pDbAcParamRec->dbAcParamData[i].fIACC, &pDbAcParamRec->dbAcParamData[i].tIACC, &pDbAcParamRec->dbAcParamData[i].wIACC, pDbAcParamRec->dbAcParamCond.fWIACCLevel);
		}
	}

	if (pIRLeft != NULL)
		delete [] pIRLeft;

	if (pIRRight != NULL)
		delete [] pIRRight;

	if (pIRLeft2 != NULL)
		delete [] pIRLeft2;

	if (pIRRight2 != NULL)
		delete [] pIRRight2;

	if (pIACCData != NULL)
		delete [] pIACCData;
}

void CalcPowerSpectrum(const float *pWaveLeft, const float *pWaveRight, float *pFreqLeft, float *pFreqRight, int nData, BOOL bAdjust)
{
	int i, j;
	float xt1, yt1, xt2, yt2;
	float m = bAdjust ? 1.0 / nData : 1.0;
	int nData2 = nData / 2;

	for (i = 0; i < nData; i++)
		pFreqLeft[i] = (pWaveLeft != NULL) ? pWaveLeft[i] * m : 0;

	for (i = 0; i < nData; i++)
		pFreqRight[i] = (pWaveRight != NULL) ? pWaveRight[i] * m : 0;

	g_oRFFT.fft(nData, pFreqLeft);
	g_oRFFT.fft(nData, pFreqRight);

	pFreqLeft[0] *= pFreqLeft[0];
	pFreqRight[0] *= pFreqRight[0];

	pFreqLeft[nData2] = pFreqLeft[1] * pFreqLeft[1] * 4;
	pFreqRight[nData2] = pFreqRight[1] * pFreqRight[1] * 4;

	for (i = 1; i < nData2; i++) {
		j = i * 2;

		xt1 = pFreqLeft[j];
		yt1 = pFreqLeft[j + 1];
		xt2 = pFreqRight[j];
		yt2 = pFreqRight[j + 1];

		pFreqLeft[i] = (xt1 * xt1 + yt1 * yt1) * 4;
		pFreqRight[i] = (xt2 * xt2 + yt2 * yt2) * 4;
	}

	for (i = 1; i < nData2; i++) {
		pFreqLeft[nData - i] = pFreqLeft[i];
		pFreqRight[nData - i] = pFreqRight[i];
	}
}

BOOL CalcPreference(float SPL, float dT1, float Tsub, float IACC, float A, float te, float bestSPL, float *s)
{
	float a, x, tp;
	BOOL rc = TRUE;

	x = SPL - bestSPL;
	a = (x >= 0) ? 0.07 : 0.04;
	s[1] = -a * pow(fabs(x), 1.5);

	tp = (1 - log10(A)) * te;
	if (tp > 0) {
		x = log10(dT1 / tp);
		a = (x >= 0) ? 1.42 : 1.11;
		s[2] = -a * pow(fabs(x), 1.5);
	} else {
		s[2] = INVALID_PREF;
		rc = FALSE;
	}

	if (A < 5) {
		tp = 23 * te / 1000;
		x = log10(Tsub / tp);
		a = (x >= 0) ? 0.45 + 0.74 * A : 2.36 - 0.42 * A;
		s[3] = -a * pow(fabs(x), 1.5);
	} else {
		s[3] = INVALID_PREF;
		rc = FALSE;
	}

	x = IACC;
	a = 1.45;
	s[4] = -a * pow(fabs(x), 1.5);

	if (rc)
		s[0] = s[1] + s[2] + s[3] + s[4];
	else
		s[0] = INVALID_PREF;

	return rc;
}

BOOL CalcS0(DbAcParamRec *pDbAcParamRec, int nFreq, float fAdjustSPL, float *pPref)
{
	float s[5];

	if (CalcPreference(MeanSPL(pDbAcParamRec->dbAcParamData[nFreq].fSplL, pDbAcParamRec->dbAcParamData[nFreq].fSplR) + fAdjustSPL,
			MeanDT1(pDbAcParamRec->dbAcParamResult.fDeltaT1L - pDbAcParamRec->dbAcParamResult.fDeltaT0L, pDbAcParamRec->dbAcParamResult.fDeltaT1R - pDbAcParamRec->dbAcParamResult.fDeltaT0R),
			MeanTsub(pDbAcParamRec->dbAcParamData[nFreq].tSubL, pDbAcParamRec->dbAcParamData[nFreq].tSubR),
			pDbAcParamRec->dbAcParamData[nFreq].fIACC,
			MeanA(pDbAcParamRec->dbAcParamData[nFreq].fAL, pDbAcParamRec->dbAcParamData[nFreq].fAR),
			pDbAcParamRec->dbAcParamCond.fPrefTauE, pDbAcParamRec->dbAcParamCond.fPrefSPL, s)) {
		*pPref = s[0];
		return TRUE;
	} else {
		*pPref = INVALID_PREF;
		return FALSE;
	}
}

float LogMean(float pw1, float pw2)
{
	return dB10((pow(10.0, (pw1 / 10)) + pow(10.0, (pw2 / 10))) / 2);
}

float GetAdjustSPL(int folderID, int nSplRefData, float fSplRefLevel)
{
	if (nSplRefData == SPL_ABSOLUTE)
		return 0;

	if (nSplRefData == SPL_MAXREF) {
		CDbImpulse dbImpulse;
		DbImpulseRec dbImpulseRec;
		CDbAcParam dbAcParam;
		DbAcParamRec dbAcParamRec;
		CString str;
		int nRec;
		float fMaxSPL = 0;
		int i;

		if (!dbImpulse.Open())
			return 0;

		if (!dbAcParam.Open())
			return 0;

		str.Format("#%d=%ld", dbImpulse.m_nIdxFolderID, folderID);
		dbImpulse.DBSelect(str, &nRec);
		for (i = 0; ; i++) {
			if (!dbImpulse.ReadRecNext(&dbImpulseRec))
				break;

			if (dbAcParam.ReadRecID(dbImpulseRec.nImpulseID, &dbAcParamRec)) {
				if (dbAcParamRec.dbAcParamData[0].fSplL > fMaxSPL)
					fMaxSPL = dbAcParamRec.dbAcParamData[0].fSplL;

				if (dbImpulseRec.nChannel == 2) {
					if (dbAcParamRec.dbAcParamData[0].fSplR > fMaxSPL)
						fMaxSPL = dbAcParamRec.dbAcParamData[0].fSplR;
				}
			}
		}
		return fSplRefLevel - fMaxSPL;
	} else {
		CDbAcParam dbAcParam;
		DbAcParamRec dbAcParamRec;

		if (!dbAcParam.Open())
			return 0;

		if (!dbAcParam.ReadRecID(nSplRefData, &dbAcParamRec))
			return 0;

		if (dbAcParamRec.dbAcParamData[0].fSplR == 0)
			return fSplRefLevel - dbAcParamRec.dbAcParamData[0].fSplL;
		else
			return fSplRefLevel - MeanSPL(dbAcParamRec.dbAcParamData[0].fSplL, dbAcParamRec.dbAcParamData[0].fSplR);
	}
}

void CalcMTF(const float *pIR, int nData, float fRate, const float *pMtfFreq, int nMtfFreq, float *pMTF, BOOL bSN, float fSN)
{
	int i, j;
	float fSum1, fSum2R, fSum2I, fSum2;
	float fTmp1, fTmp2, fTmp3;
	float t;

	fSum1 = 0;
	for (i = 0; i < nData; i++)
		fSum1 += pIR[i] * pIR[i];

	for (i = 0; i < nMtfFreq; i++) {
		fSum2R = 0;
		fSum2I = 0;
		for (j = 0; j < nData; j++) {
			t = j / fRate;
			fTmp1 = cos(2 * M_PI * pMtfFreq[i] * t);
			fTmp2 = sin(2 * M_PI * pMtfFreq[i] * t);
			fTmp3 = pIR[j] * pIR[j];
			fSum2R += fTmp1 * fTmp3;
			fSum2I += fTmp2 * fTmp3;
		}
		fSum2 = sqrt(fSum2R * fSum2R + fSum2I * fSum2I);

		pMTF[i] = fSum2 / fSum1;

		if (bSN)
			pMTF[i] /= 1 + pow(10.0, -fSN / 10);
	}
}

float CalcMTI(const float *pIR, int nData, float fRate, const float *pMtfFreq, int nMtfFreq, BOOL bSN, float fSN)
{
	int i;
	float fSNR;
	float fTI;
	float fMTI;
	float tMTI[N_MTF_FREQ];

	CalcMTF(pIR, nData, fRate, pMtfFreq, nMtfFreq, tMTI, bSN, fSN);

	fMTI = 0;
	for (i = 0; i < nMtfFreq; i++) {
		fSNR = 10 * log10(tMTI[i] / (1 - tMTI[i]));
		fTI = (fSNR + 15) / 30;
		if (fTI > 1)
			fTI = 1;
		else if (fTI < 0)
			fTI = 0;

		fMTI += fTI;
	}

	return fMTI / nMtfFreq;
}

void CalcParamSTI(const float *pMTI, float fMTI500, float fMTI2000, Float64 *pSTI, Float64 *pSTI_m, Float64 *pSTI_f, Float64 *pRASTI)
{
	static const float tSTI[N_MTF_BAND] = {
		0.129, 0.143, 0.114, 0.114, 0.186, 0.171, 0.143
	};
	static const float tSTI_m1[N_MTF_BAND] = {
		0.085, 0.127, 0.230, 0.233, 0.309, 0.224, 0.173
	};
	static const float tSTI_m2[N_MTF_BAND - 1] = {
		0.085, 0.078, 0.065, 0.011, 0.047, 0.095
	};
	static const float tSTI_f1[N_MTF_BAND] = {
		0, 0.117, 0.223, 0.216, 0.328, 0.250, 0.194
	};
	static const float tSTI_f2[N_MTF_BAND - 1] = {
		0, 0.099, 0.066, 0.062, 0.025, 0.076
	};
	int i;

	// STI
	*pSTI = 0;
	for (i = 0; i < N_MTF_BAND; i++)
		*pSTI += tSTI[i] * pMTI[i];

	// STI_m
	*pSTI_m = CalcParamSTISub(pMTI, tSTI_m1, tSTI_m2);

	// STI_f
	*pSTI_f = CalcParamSTISub(pMTI, tSTI_f1, tSTI_f2);

	// RASTI
	*pRASTI = (fMTI500 + fMTI2000) / 2;
}

float CalcParamSTISub(const float *pMTI, const float *pTbl1, const float *pTbl2)
{
	float fSTI1 = 0;
	float fSTI2 = 0;
	int i;

	for (i = 0; i < N_MTF_BAND; i++)
		fSTI1 += pTbl1[i] * pMTI[i];

	for (i = 0; i < N_MTF_BAND - 1; i++)
		fSTI2 += pTbl2[i] * sqrt(pMTI[i] * pMTI[i + 1]);

	return fSTI1 - fSTI2;
}
