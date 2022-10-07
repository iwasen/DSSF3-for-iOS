//
//  FftGraphCrf.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/23.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

@interface FftViewController (Crf)

- (void)initCrf;
- (void)drawScaleCrf:(CGRect)frame;
- (void)setDispDataCrf;
- (void)drawDataCrf:(CGContextRef)context :(int)nChannel;
- (void)setDispFreqCrf:(CGPoint)point;
- (void)resetDispFreqCrf;

@end
