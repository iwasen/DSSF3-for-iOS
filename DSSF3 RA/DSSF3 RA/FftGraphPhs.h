//
//  FftGraphPhs.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/24.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

@interface FftViewController (Phs)

- (void)initPhs;
- (void)drawScalePhs:(CGRect)frame;
- (void)setDispDataPhs;
- (void)drawDataPhs:(CGContextRef)context :(int)nChannel;
- (void)setDispFreqPhs:(CGPoint)point;
- (void)resetDispFreqPhs;

@end
