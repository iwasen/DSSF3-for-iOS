//
//  Common.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/06.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "Global.h"
#import "MMDB.h"

#define RGB(r,g,b)          initWithRed:(float)r / 255 green:(float)g / 255 blue:(float)b / 255 alpha:1.0

#define METHOD_MSEQ			0
#define METHOD_TSP			1

#define SPL_MAXREF		-1
#define SPL_ABSOLUTE	-2

#define FREQ_ALL		0
#define FREQ_AFILTER	-1

typedef unsigned char BYTE;

extern int ReadWaveData(HWAVEDATA hWaveData, float *pLeftData, float *pRightData, int nData, int nOffset = 0);
