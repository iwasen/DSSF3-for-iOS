//
//  FreViewController.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/05/28.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SubViewController.h"
#import "AudioEx.h"

@protocol FreMode

- (int)initialize;
- (void)updateGraph;
- (BOOL)waveOutData:(float *)pData;
- (BOOL)waveInData:(const float *)pDataLeft :(const float *)pDataRight;
- (BOOL)checkDataExist;
- (void)changeSampleRate;

@end

@interface FreViewController : SubViewController <AudioInputData, AudioOutputData>

@end
