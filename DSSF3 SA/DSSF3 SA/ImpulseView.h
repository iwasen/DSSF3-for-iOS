//
//  ImpulseView.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/15.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GraphView.h"

@interface ImpulseView : GraphView

- (void)initialize:(NSString *)pTitle :(int)nRemark :(UIColor *)colorWave;
- (void)dispImpulse:(CGContextRef)context :(float)totalTime :(float)startTime :(float)dispTime :(const float *)pData :(int)nData;
- (void)setDeltaT1:(float)T0 :(float)T1;

@end
