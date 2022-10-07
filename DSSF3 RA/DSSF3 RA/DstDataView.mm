//
//  DstDataView.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/10.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "DstDataView.h"

@implementation DstDataView

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		self.backgroundColor = [UIColor clearColor];
		self.userInteractionEnabled = NO;
	}
	return self;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	[self.delegate drawDataView:context];
}

@end
