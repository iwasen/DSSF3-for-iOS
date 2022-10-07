//
//  CtButton.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/04/04.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "CtButton.h"

@implementation CtButton

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
    self.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.layer.borderWidth = 1.5f;
    self.layer.cornerRadius = 8.0f;
}

- (void)setSelected:(BOOL)selected
{
	// Do original Selected
	[super setSelected:selected];

	// Select with new colour OR replace with orignial
	self.backgroundColor = selected ? self.tintColor : [UIColor whiteColor];
}

@end
