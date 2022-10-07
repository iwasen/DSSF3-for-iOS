//
//  ParamView.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/11.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GraphView.h"

@interface ParamView : GraphView

- (void)initialize;
- (void)dispGraph:(CGContextRef)context :(const int *)pDataFreq :(int)nFreqBand :(const float *)pDataAll :(const float *)pDataLeft :(const float *)pDataRight :(int)nData :(float)scaleMin :(float)scaleMax :(float)scaleStep :(NSString *)vAxis;
- (void)dispRemark:(NSString *)title :(int)nRemark;

@end
