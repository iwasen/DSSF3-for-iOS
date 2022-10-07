//
//  ExtView.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/12.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "ExtView.h"

@implementation ExtView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
	if ([super pointInside:point withEvent:event])
		return YES;

	for (UIView *subView in [self subviews]) {
		if ([subView pointInside:[self convertPoint:point toView:subView] withEvent:event])
			return YES;
	}

	return NO;
}

@end
