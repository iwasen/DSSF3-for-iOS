//
//  FftGraphPws.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/10.
//  Copyright (c) 2015年 aizawa. All rights reserved.
//

@interface FftViewController (Pws)

- (void)initPws;
- (void)drawScalePws:(CGRect)frame;
- (void)setDispDataPws;
- (void)drawDataPws:(CGContextRef)context :(int)nChannel;
- (void)setDispFreqPws:(CGPoint)point;
- (void)resetDispFreqPws;

@end
