//
//  FftDataView.m
//  SoundTest
//
//  Created by 相沢伸一 on 2015/03/07.
//  Copyright (c) 2015年 aizawa. All rights reserved.
//

#import "FftDataView.h"
#import "FftViewController.h"

@implementation FftDataView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
		self.userInteractionEnabled = NO;
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetLineWidth(context, 1.0);
    CGContextSetShouldAntialias(context, NO);
    CGContextSetAllowsAntialiasing(context, NO);

    if (_leftChannel)
        [self.delegate drawDataView:context :0];
    
    if (_rightChannel)
        [self.delegate drawDataView:context :1];
}

- (void)display
{
	CALayer *layer = self.layer;
	[layer setNeedsDisplay];
	[layer displayIfNeeded];
}

@end
