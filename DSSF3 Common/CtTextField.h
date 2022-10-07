//
//  CtTextField.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/04/04.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CtTextField : UITextField <UITextFieldDelegate>

@property (nonatomic, getter=getIntValue, setter=setIntValue:) int intValue;
@property (nonatomic, getter=getFloatValue, setter=setFloatValue:) float floatValue;

- (void)blank;
- (void)setFloatValue:(float)floatValue decimalPosition:(int)decimalPosition;

@end
