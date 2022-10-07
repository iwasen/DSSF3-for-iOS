//
//  IndicatorView.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/21.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioCommon.h"

@interface IndicatorView : UIView

- (void)clear;
- (void)inputAudioData:(AudioData *)audioData;

@end
