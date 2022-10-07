//
//  CtTextField.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/04/04.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "CtTextField.h"

@implementation CtTextField

- (void)awakeFromNib
{
	[super awakeFromNib];

	self.delegate = self;
	self.backgroundColor = [UIColor clearColor];
}

- (int)getIntValue
{
    return self.text.intValue;
}

- (void)setIntValue:(int)intValue
{
    self.text = [NSString stringWithFormat:@"%d", intValue];
}

- (float)getFloatValue
{
    return self.text.floatValue;
}

- (void)setFloatValue:(float)floatValue
{
    self.text = [NSString stringWithFormat:@"%g", floatValue];
}

- (void)setFloatValue:(float)floatValue decimalPosition:(int)decimalPosition
{
	self.text = [NSString stringWithFormat:[NSString stringWithFormat:@"%%.%df", decimalPosition], floatValue];
}

- (void)blank
{
    self.text = @"";
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    self.textColor = enabled ? [UIColor blackColor] : [UIColor lightGrayColor];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}
@end
