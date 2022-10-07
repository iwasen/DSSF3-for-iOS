//
//  MMDB.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/21.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "PCSCL.h"

typedef	struct {
	int nChannels;
	int nBitsPerSample;
	int nSamplesPerSec;
	int dataSize;
	void *waveData[0];
} WAVEDATA, *PWAVEDATA;

typedef char *HWAVEDATA;
typedef HWAVEDATA *PHWAVEDATA;
typedef const char *LPCTSTR;

extern HWAVEDATA MMWaveReadDB(CPSDB &db, LPCTSTR fieldName);
extern void MMWaveWriteDB(CPSDB &db, LPCTSTR fieldName, const char *data, int dataSize);
