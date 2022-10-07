//
//  RtaView.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/19.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "RtaView.h"
#import "Common.h"

@implementation RtaView

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIColor *color = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           [UIFont systemFontOfSize:FONT_SIZE_INDICATIOR], NSFontAttributeName,
                           nil];

    NSString *text;
    CGSize size;
    CGFloat x, y;
    int i;

    CGRect rectIndicatior = self.outletOutputIndicator.frame;
	y = rectIndicatior.origin.y + rectIndicatior.size.height;

    for (i = RTA_MIN_LEVEL; i <= 0; i += 10) {
		x = rectIndicatior.origin.x + rectIndicatior.size.width * (RTA_MIN_LEVEL - i) / RTA_MIN_LEVEL;
		DrawLine(context, x, y, x, y + 4, color);
		text = [NSString stringWithFormat:@"%d", i];
		size = [text sizeWithAttributes:attrs];
		DrawString(text, x - size.width / 2, y + 5, attrs);
    }
    
	text = @"[dB]";
	size = [text sizeWithAttributes:attrs];
	DrawString(text, rectIndicatior.origin.x - size.width - 20, y + 5, attrs);
}

@end
