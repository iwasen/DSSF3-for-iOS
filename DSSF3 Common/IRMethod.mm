//
//  IRMethod.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/15.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "IRMethod.h"

CIRMethod::CIRMethod()
{

}

CIRMethod::~CIRMethod()
{
	
}

void CIRMethod::PolarityCheck(int nData, float *pData)
{
	int i;
	float fMin = 0, fMax = 0;

	for (i = 0; i < nData; i++) {
		if (pData[i] < fMin)
			fMin = pData[i];
		if (pData[i] > fMax)
			fMax = pData[i];
	}

	if (-fMin > fMax) {
		for (i = 0; i < nData; i++)
			pData[i] = -pData[i];
	}
}
