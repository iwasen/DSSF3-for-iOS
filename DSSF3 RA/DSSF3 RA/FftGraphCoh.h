//
//  FftGraphCoh.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/26.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

@interface FftViewController (Coh)

- (void)initCoh;
- (void)drawScaleCoh:(CGRect)frame;
- (void)setDispDataCoh;
- (void)drawDataCoh:(CGContextRef)context :(int)nChannel;
- (void)setDispFreqCoh:(CGPoint)point;
- (void)resetDispFreqCoh;

@end
