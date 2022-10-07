//
//  AudioEx.h
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2017/01/23.
//  Copyright © 2017年 TRC. All rights reserved.
//

#import "AudioInput.h"
#import "AudioOutput.h"

#define REC_MODE_OFF	0
#define REC_MODE_RECORD	1
#define REC_MODE_PLAY	2

@protocol AudioRecorder <NSObject>

- (void)audioRecordStart:(AudioInfo *)audioInfo;
- (void)audioRecordStop;
- (void)audioRecordData:(AudioData *)audioData;
- (void)audioPlayStart:(AudioInfo *)audioInfo;
- (void)audioPlayStop;
- (void)audioPlayData:(AudioData *)audioData;
- (int)getSampleRate;

@end

@interface AudioEx : NSObject

+ (void)setRecMode:(int)recMode :(id <AudioRecorder>)target;
+ (int)getPlaybackSampleRate;

@end

@interface AudioInputEx : AudioInput

@end

@interface AudioOutputEx : AudioOutput

@end
