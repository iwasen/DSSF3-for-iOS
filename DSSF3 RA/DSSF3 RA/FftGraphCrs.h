//
//  FftGraphCrs.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/26.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

@interface FftViewController (Crs)

- (void)initCrs;
- (void)drawScaleCrs:(CGRect)frame;
- (void)setDispDataCrs;
- (void)drawDataCrs:(CGContextRef)context :(int)nChannel;
- (void)setDispFreqCrs:(CGPoint)point;
- (void)resetDispFreqCrs;

@end
