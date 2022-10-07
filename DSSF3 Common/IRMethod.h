//
//  IRMethod.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/15.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import <UIKit/UIKit.h>

class CIRMethod
{
public:
	CIRMethod();
	virtual ~CIRMethod();

	virtual void InitMethod(int nStage) = 0;
	virtual void GenerateSequence(float *pData, int nAtt) = 0;
	virtual void CalcImpulse(float *pData) = 0;

protected:
	void PolarityCheck(int nData, float *pData);
};
