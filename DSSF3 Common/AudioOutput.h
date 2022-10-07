//
//  AudioOutput.h
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2017/01/09.
//  Copyright © 2017年 TRC. All rights reserved.
//

#import "AudioCommon.h"

@protocol AudioOutputData <NSObject>

@optional
- (void)audioOutputStart:(AudioInfo *)audioInfo;
- (void)audioOutputStop;
@required
- (void)audioOutputData:(AudioData *)audioData;

@end

@interface AudioOutput : NSObject

+ (void)prepare:(int)sampleRate :(int)channels :(int)samplePerBuffer :(id <AudioOutputData>)target;
+ (void)start:(int)sampleRate :(int)channels :(int)samplePerBuffer :(id <AudioOutputData>)target;
+ (void)start;
+ (void)stop;
+ (void)reset;
+ (void)setMonitor:(id <AudioOutputData>)monitor;
+ (int)getTime;

@end
