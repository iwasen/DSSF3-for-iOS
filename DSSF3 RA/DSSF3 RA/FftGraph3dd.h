//
//  FftGraph3dd.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/23.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

@interface FftViewController (tdd)

- (void)init3dd;
- (void)drawScale3dd:(CGRect)frame;
- (void)setDispData3dd;
- (void)drawData3dd:(CGContextRef)context :(int)nChannel;

@end
