//
//  FreqView.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/07.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GraphView.h"

@interface FreqView : GraphView

- (void)initialize:(NSString *)title :(int)nRemark :(UIColor *)freqColor :(CGFloat)fontSize;
- (void)dispGraph:(CGContextRef)context :(const float *)pFreqData :(int)nData :(float)fRate :(int)nMinFreq :(int)nMaxFreq :(int)nMinLevel :(int)nMaxLevel :(BOOL)bMean;

@end
