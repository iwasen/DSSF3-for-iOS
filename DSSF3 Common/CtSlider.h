//
//  CtSlider.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/04/07.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE

@interface CtSlider : UIControl

@property (nonatomic) IBInspectable BOOL vertical;
@property (nonatomic, setter=setMinValue:) IBInspectable int minValue;
@property (nonatomic, setter=setMaxValue:) IBInspectable int maxValue;
@property (nonatomic) IBInspectable int ticPosition;
@property (nonatomic) IBInspectable int ticFreq;
@property (nonatomic) IBInspectable int ticLength;
@property (nonatomic, setter=setSliderValue:) int value;

- (void)clearTics;
- (void)addTic:(CGFloat)position :(NSString *)text;

@end
