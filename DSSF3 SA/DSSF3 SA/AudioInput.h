//
//  AudioInput.h
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2017/01/09.
//  Copyright © 2017年 TRC. All rights reserved.
//

#import "AudioCommon.h"

@protocol AudioInputData <NSObject>

@optional
- (void)audioInputStart:(AudioInfo *)audioInfo;
- (void)audioInputStop;
@required
- (void)audioInputData:(AudioData *)audioData;

@end

@interface AudioInput : NSObject

+ (void)prepare:(int)sampleRate :(int)channels :(int)samplePerBuffer :(id <AudioInputData>)target;
+ (void)start:(int)sampleRate :(int)channels :(int)samplePerBuffer :(id <AudioInputData>)target;
+ (void)start;
+ (void)stop;
+ (void)reset;
+ (void)setMonitor:(id <AudioInputData>)monitor;
+ (int)getTime;

@end
