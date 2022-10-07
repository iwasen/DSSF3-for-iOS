#pragma once

#import "FileIO.h"
#import "fft.h"
#import "MSeq.h"
#import "TSP.h"

#define dB10(x)	(x == 0 ? -1000 : log10((float)(x)) * 10)
#define dB20(x)	(x == 0 ? -1000 : log10((float)(x)) * 20)

#define MeanSPL(left, right)	LogMean(left, right)
#define MeanDT1(left, right)	(((left) + (right)) / 2)
#define MeanTsub(left, right)	(((left) + (right)) / 2)
#define MeanA(left, right)		(((left) + (right)) / 2)
#define MeanG(left, right)		LogMean(left, right)
#define MeanT(left, right)		(((left) + (right)) / 2)
#define MeanC(left, right)		LogMean(left, right)
#define MeanD(left, right)		(((left) + (right)) / 2)
#define MeanTs(left, right)		(((left) + (right)) / 2)

#define INVALID_PREF	-1000

#define N_MTF_FREQ	14
#define N_MTF_BAND	7
#define N_MTF_500	4
#define	N_MTF_2000	5

#define SPL_MAXREF		-1
#define SPL_ABSOLUTE	-2

#define FREQ_ALL		0
#define FREQ_AFILTER	-1

#define METHOD_MSEQ			0
#define METHOD_TSP			1

struct FREQBAND {
	int nData;
	float fBandWidth;
	float fRealFreq[33];
	float fDispFreq[33];
};

typedef char *HWAVEDATA;

extern const struct FREQBAND g_tFilterTbl[2];
extern const float g_tMtfFreq[];

extern void CalcEchoData(const float *pIRLeft, const float *pIRRight, float *pEchoData, int nData, float fRate,  float t1, float noise);
extern void CalcIACCData(const float *pIRLeft, const float *pIRRight, int nData, float *pOutData, int nOutData);
extern BOOL MakeFilterTbl1(float *pFilterTbl, int nData, float fRate, float fFreqLow, float fFreqHigh);
extern void CalcFilter(float *pWaveLeft, float *pWaveRight, int nData, const float *pFilterTbl);
extern BOOL CalcFilterAuto(float *pWaveLeft, float *pWaveRight, int nData, float fRate, int nFreq, int band);
extern NSString *GetDispFreq(int nFreq, int band, BOOL bKiro);
extern float CalcParamSpl(const float *pData, int nData, int nMultiplier);
extern void CalcParamDeltaT1(const float *pData, int nData, float fRate, float minTime, Float64 *pT0, Float64 *pT1, int *pT0Pos);
extern float CalcParamTSub(const float *pData1, const float *pData2, int nData, float fRate, float t1, float endLevel, BOOL bAuto, float noise, Float64 *pDev, Float64 *pAVal, Float64 *pEndTime = NULL);
extern void CalcParamIACC(const float *pIACCData, int nIACCData, float fRate, Float64 *pIACC, Float64 *pTIACC, Float64 *pWIACC, float wLevel, Float64 *pWIACC1 = NULL, Float64 *pWIACC2 = NULL);
extern void CalcParamTx2(const float *pData1, const float *pData2, int nData, float fRate, int nT0Pos, float *pT20Reg0, float *pT20Reg1, float *pT30Reg0, float *pT30Reg1, float *pEDTReg0, float *pEDTReg1);
extern BOOL CalcAcParam(DbImpulseRec *pDbImpulseRec, HWAVEDATA hWaveData, DbAcParamRec *pDbAcParamRec, float fRate, id obj, SEL sel);
extern void CalcTsub(const DbImpulseRec *pDbImpulseRec, HWAVEDATA hWaveData, DbAcParamRec *pDbAcParamRec, float fRate);
extern void CalcIACC(const DbImpulseRec *pDbImpulseRec, HWAVEDATA hWaveData, DbAcParamRec *pDbAcParamRec, float fRate);
extern void CalcPowerSpectrum(const float *pWaveLeft, const float *pWaveRight, float *pFreqLeft, float *pFreqRight, int nData, BOOL bAdjust = YES);
extern BOOL CalcPreference(float SPL, float dT1, float Tsub, float IACC, float A, float te, float bestSPL, float *s);
extern BOOL CalcS0(DbAcParamRec *pDbAcParamRec, int nFreq, float fAdjustSPL, float *pPref);
extern float LogMean(float d1, float d2);
extern float GetAdjustSPL(int folderID, int nSplRefData, float fSplRefLevel);
extern void CalcMTF(const float *pIR, int nData, float fRate, const float *pMtfFreq, int nMtfFreq, float *pMTF, BOOL bSN, float fSN);
