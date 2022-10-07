//
//  AudioCommon.h
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2017/01/09.
//  Copyright © 2017年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

#define NUM_BITS        (sizeof(AUDIO_SAMPLE) * 8)
#define NUM_CHANNELS_1	1
#define NUM_CHANNELS_2  2
#define NUM_BUFFERS     3

#define AUDIO_SAMPLE    float

struct AudioData {
	float *pLeftData;
	float *pRightData;
	int nDataSize;
	int nChannel;
};

struct AudioInfo {
	int nSampleRate;
	int nChannel;
	int nBufSize;
};
