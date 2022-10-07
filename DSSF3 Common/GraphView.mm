//
//  GraphView.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/06.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "GraphView.h"

@implementation GraphView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (event.allTouches.count == 1) {
		UITouch *touch = [touches anyObject];
		CGPoint previous = [touch previousLocationInView:self];
		CGPoint now = [touch locationInView:self];
		if ([self.delegate respondsToSelector:@selector(moveGraph::)])
			[self.delegate moveGraph:self :(previous.x - now.x) / _nScaleWidth];
	} else if (event.allTouches.count == 2) {
		//2本指でタッチしている場合は、２点間の距離を計算
		NSArray *twoFingers = [event.allTouches allObjects];
		UITouch *touch1 = [twoFingers objectAtIndex:0];
		UITouch *touch2 = [twoFingers objectAtIndex:1];
		CGPoint previous1 = [touch1 previousLocationInView:self];
		CGPoint previous2 = [touch2 previousLocationInView:self];
		CGPoint now1 = [touch1 locationInView:self];
		CGPoint now2 = [touch2 locationInView:self];

		//現状の距離と、前回の距離を比較して距離が縮まったか離れたかを判別
		CGFloat previousDistance = ABS(previous1.x - previous2.x);
		CGFloat distance = ABS(now1.x - now2.x);

		if ([self.delegate respondsToSelector:@selector(zoomGraph::)])
			[self.delegate zoomGraph:self :previousDistance / distance];
	}
}

@end
