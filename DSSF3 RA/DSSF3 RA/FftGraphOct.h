//
//  FftGraphOct.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/16.
//  Copyright (c) 2015年 aizawa. All rights reserved.
//

@interface FftViewController (Oct)

- (void)initOct;
- (void)drawScaleOct:(CGRect)frame;
- (void)setDispDataOct;
- (void)drawDataOct:(CGContextRef)context :(int)nChannel;
- (void)setDispFreqOct:(CGPoint)point;
- (void)resetDispFreqOct;

@end
