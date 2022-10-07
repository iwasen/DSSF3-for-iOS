//
//  FftGraphView.m
//  SoundTest
//
//  Created by 相沢伸一 on 2015/03/07.
//  Copyright (c) 2015年 aizawa. All rights reserved.
//

#import "FftScaleView.h"

@implementation FftScaleView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
		self.userInteractionEnabled = YES;
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    [self.delegate drawScaleView:context];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self notifyTouches:touches];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self notifyTouches:touches];
}

- (void)notifyTouches:(NSSet *)touches
{
	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView:self];

	[self.delegate touchesScaleView:point];
}

@end
