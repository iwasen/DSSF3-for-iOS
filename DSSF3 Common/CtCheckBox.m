//
//  CtCheckBox.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/04/08.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "CtCheckBox.h"

@implementation CtCheckBox

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _setup];
    }
    return self;
}

- (void)_setup
{
    [self addTarget:self action:@selector(touchCheckBox:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)touchCheckBox:(UIButton *)sender
{
    _checked = !_checked;
    self.selected = _checked;
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)setChecked:(BOOL)checked
{
    _checked = checked;
    self.selected = _checked;
}

- (void)setEnabled:(BOOL)enabled
{
    self.selected = enabled ? _checked : NO;
    [super setEnabled:enabled];
}

@end
