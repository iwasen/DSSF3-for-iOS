//
//  Common.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/06.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Common.h"

static void CopyWaveToFloat(const void *pWaveData, float *pLeftData, float *pRightData, int nDataNum, int nBits)
{
	BYTE *bp;
	short *sp;
	float *fp;
	int i;
	union {
		int i;
		BYTE b[4];
	} ib;

	switch (nBits) {
		case 8:
			bp = (BYTE *)pWaveData;
			for (i = 0; i < nDataNum; i++) {
				*pLeftData++ = (char)(*bp++ - 128) / PowFloat(8);
				if (pRightData != NULL)
					*pRightData++ = (char)(*bp++ - 128) / PowFloat(8);
			}
			break;
		case 16:
			sp = (short *)pWaveData;
			for (i = 0; i < nDataNum; i++) {
				*pLeftData++ = *sp++ / PowFloat(16);
				if (pRightData != NULL)
					*pRightData++ = *sp++ / PowFloat(16);
			}
			break;
		case 24:
			bp = (BYTE *)pWaveData;
			ib.b[0] = 0;
			for (i = 0; i < nDataNum; i++) {
				ib.b[1] = *bp++;
				ib.b[2] = *bp++;
				ib.b[3] = *bp++;
				*pLeftData++ = ib.i / PowFloat(32);

				if (pRightData != NULL) {
					ib.b[1] = *bp++;
					ib.b[2] = *bp++;
					ib.b[3] = *bp++;
					*pRightData++ = ib.i / PowFloat(32);
				}
			}
			break;
		case 32:
			fp = (float *)pWaveData;

			float fAdj = 1;
			for (i = 0; i < nDataNum; i++) {
				if (fp[i] > 1.0) {
					fAdj = 1.0 / PowFloat(16);
					break;
				}
			}

			for (i = 0; i < nDataNum; i++) {
				*pLeftData++ = *fp++ * fAdj;
				if (pRightData != NULL)
					*pRightData++ = *fp++ * fAdj;
			}
			break;
	}
}

int ReadWaveData(HWAVEDATA hWaveData, float *pLeftData, float *pRightData, int nData, int nOffset)
{
	PWAVEDATA pWaveData;
	int nBytesPerSample;
	int nWaveSize;
	int nReadSize;

	if (pLeftData == NULL)
		return 0;

	pWaveData = (PWAVEDATA)hWaveData;
	nBytesPerSample = pWaveData->nChannels * (pWaveData->nBitsPerSample / 8);
	nWaveSize = pWaveData->dataSize / nBytesPerSample;
	nReadSize = MIN(nWaveSize - nOffset, nData);

	CopyWaveToFloat((BYTE *)pWaveData->waveData + nOffset * nBytesPerSample, pLeftData, pWaveData->nChannels == 2 ? pRightData : NULL, nReadSize, pWaveData->nBitsPerSample);

	if (nReadSize < nData) {
		int nClear = nData - nReadSize;

		memset(pLeftData + nReadSize, 0, sizeof(float) * nClear);
		if (pRightData != NULL)
			memset(pRightData + nReadSize, 0, sizeof(float) * nClear);
	}

	return nReadSize;
}
