//
//  FftGraphSpg.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/24.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

@interface FftViewController (Spg)

- (void)initSpg;
- (void)drawScaleSpg:(CGRect)frame;
- (void)setDispDataSpg;
- (void)drawDataSpg:(CGContextRef)context :(int)nChannel;

@end
