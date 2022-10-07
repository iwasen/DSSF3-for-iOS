//
//  DstViewController.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/09.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Common.h"
#import "SubViewController.h"
#import "AudioEx.h"

@protocol DstMode

- (void)initialize;
- (void)updateGraph;
- (BOOL)waveOutData:(int *)nFreq :(float *)fLevel;
- (BOOL)notifyTHD:(const float *)pLeftDst :(const float *)pRightDst;

@end

@interface DstViewController : SubViewController <AudioInputData, AudioOutputData>

@end
