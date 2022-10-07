//
//  TSP.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/15.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFT.h"
#import "IRMethod.h"

class CTSP : public CIRMethod
{
public:
	CTSP();
	virtual ~CTSP();

	void InitMethod(int nStage);
	void GenerateSequence(float *pData, int nAtt);
	void CalcImpulse(float *pData);

protected:
	void FreeBuffers();

	int m_nStage;
	int m_nN;
	int m_nM;
	float *m_pSignal;
	CRFFT m_oRFFT;
};
