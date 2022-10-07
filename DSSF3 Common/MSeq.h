//
//  MSeq.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/15.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IRMethod.h"

#define TOPMSEQPARAM	10
#define N_MSEQDATA		(sizeof(tMSeqParam) / sizeof(MSeqParam))

struct MSeqParam {
	int nBit;
	int ntap;
	int taps[4];
	int tob[19];
};

class CMSeq : public CIRMethod
{
public:
	CMSeq();
	~CMSeq();

	void InitMethod(int nStage);
	void GenerateSequence(float *pData, int nAtt);
	void CalcImpulse(float *pData);

protected:
	void FreeBuffers();

	int m_nStage;
	int *m_pPermut;
	char *m_pMSequence;
};
