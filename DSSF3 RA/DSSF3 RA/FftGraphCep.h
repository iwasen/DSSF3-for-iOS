//
//  FftGraphCep.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/26.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

@interface FftViewController (Cep)

- (void)initCep;
- (void)drawScaleCep:(CGRect)frame;
- (void)setDispDataCep;
- (void)drawDataCep:(CGContextRef)context :(int)nChannel;
- (void)setDispFreqCep:(CGPoint)point;
- (void)resetDispFreqCep;

@end
