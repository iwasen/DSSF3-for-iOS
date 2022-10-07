//
//  CtGroupBox.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/31.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "CtGroupBox.h"

#define LEFT_MARGIN     10
#define TEXT_MARGIN     6

@implementation CtGroupBox

- (void)awakeFromNib
{
	[super awakeFromNib];
/*
	if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)) {
		self.autoresizingMask = UIViewAutoresizingFlexibleHeight |
			UIViewAutoresizingFlexibleWidth |
			UIViewAutoresizingFlexibleTopMargin |
			UIViewAutoresizingFlexibleLeftMargin |
			UIViewAutoresizingFlexibleBottomMargin |
			UIViewAutoresizingFlexibleRightMargin;

		for (UIView *view in self.subviews) {
			if ([view isKindOfClass:[UITextField class]] || [view isKindOfClass:[UISegmentedControl class]]) {
				view.autoresizingMask =
					UIViewAutoresizingFlexibleWidth |
					UIViewAutoresizingFlexibleTopMargin |
					UIViewAutoresizingFlexibleLeftMargin |
					UIViewAutoresizingFlexibleBottomMargin |
					UIViewAutoresizingFlexibleRightMargin;
			} else {
				view.autoresizingMask =
					UIViewAutoresizingFlexibleHeight |
					UIViewAutoresizingFlexibleWidth |
					UIViewAutoresizingFlexibleTopMargin |
					UIViewAutoresizingFlexibleLeftMargin |
					UIViewAutoresizingFlexibleBottomMargin |
					UIViewAutoresizingFlexibleRightMargin;
			}
		}
	}
*/
	NSString *text = NSLocalizedString(_title, nil);
	if (text != nil && text != _title)
		_title = text;

	self.backgroundColor = [UIColor clearColor];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    NSDictionary *fontAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                               [UIFont systemFontOfSize:_fontSize], NSFontAttributeName,
                               nil];
    
    CGSize size = [_title sizeWithAttributes:fontAttrs];
    CGFloat height2 = size.height / 2;
    
    CGPoint points[6];
    points[0] = CGPointMake(LEFT_MARGIN + TEXT_MARGIN + size.width + TEXT_MARGIN, height2);
    points[1] = CGPointMake(self.bounds.size.width - 1, height2);
    points[2] = CGPointMake(self.bounds.size.width - 1, self.bounds.size.height - 1);
    points[3] = CGPointMake(1, self.bounds.size.height - 1);
    points[4] = CGPointMake(1, height2);
    points[5] = CGPointMake(LEFT_MARGIN, height2);
    CGContextBeginPath(context);
    CGContextAddLines(context, points, 6);
    CGContextSetStrokeColorWithColor(context, [UIColor lightGrayColor].CGColor);
    CGContextStrokePath(context);
    
    [_title drawAtPoint:CGPointMake(LEFT_MARGIN + TEXT_MARGIN, 0) withAttributes:fontAttrs];
}

@end
