//
//  RemarkView.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/31.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "RemarkView.h"
#import "Common.h"
#import "DrawView.h"

#define XMARGIN		6
#define YMARGIN		3
#define XPOS		20
#define YPOS		11
#define LINELENGTH	30

@implementation RemarkView
{
    const REMARK_INFO *_pRemark;
    int _nX;
    int _nY;
    NSDictionary *_fontAttrs;
    CGPoint _pointTouch;
    CGRect _rectTouch;
}

- (void)drawRect:(CGRect)rect
{
	CGSize size;
	int i, y;

	CGContextRef context = UIGraphicsGetCurrentContext();

	DrawRectangle(context, 0, 0, self.bounds.size.width, self.bounds.size.height, [UIColor grayColor]);

	y = YMARGIN;

	CGFloat dash[2] = {5, 5};
	for (i = 0; i < _pRemark->nRemark; i++) {
		size = [_pRemark->remarks[i].text sizeWithAttributes:_fontAttrs];

		if (_pRemark->remarks[i].color != nil) {
			if (_pRemark->remarks[i].dash)
				CGContextSetLineDash(context, 0, dash, 2);
			else
				CGContextSetLineDash(context, 0, nil, 0);
			DrawLine(context, XMARGIN, y + size.height / 2, XMARGIN + LINELENGTH - 5, y + size.height / 2, _pRemark->remarks[i].color);
			DrawString(_pRemark->remarks[i].text, XMARGIN + LINELENGTH, y, _fontAttrs);
		} else
			DrawString(_pRemark->remarks[i].text, XMARGIN, y, _fontAttrs);

		y += size.height;
	}
}

- (void)dispRemarks:(const REMARK_INFO *)pRemark :(int)nFontPoint :(UIView *)viewParent
{
	CGFloat cx, cy;
	CGSize size;
	int i;
	int nx, ny;
	CGFloat width, height;

	_pRemark = pRemark;
	_fontAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
				  [UIFont systemFontOfSize:AdjustFontSize(nFontPoint)], NSFontAttributeName,
				  [UIColor blackColor], NSForegroundColorAttributeName,
				  nil];

	cx = 0;
	cy = 0;
	for (i = 0; i < _pRemark->nRemark; i++) {
		size = [_pRemark->remarks[i].text sizeWithAttributes:_fontAttrs];
		if (_pRemark->remarks[i].color != nil)
			size.width += LINELENGTH;
		if (size.width > cx)
			cx = size.width;
		cy += size.height;
	}

	width = cx + XMARGIN * 2;
	height = cy + YMARGIN * 2;

	nx = viewParent.bounds.size.width - width - XPOS;
	ny = YPOS;
	self.frame = CGRectMake(nx, ny, width, height);

	self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:0.9 alpha:0.7];
	self.clearsContextBeforeDrawing = YES;

	[viewParent addSubview:self];
	[self setNeedsDisplay];
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	UITouch *touch = [touches anyObject];
	_pointTouch = [touch locationInView:self.superview];
	_rectTouch = self.frame;
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
	CGPoint point = [((UITouch*)[touches anyObject])locationInView:self.superview];

	// ドラッグ中の座標を使って移動
	CGRect rect = _rectTouch;
	rect.origin.x += point.x - _pointTouch.x;
	rect.origin.y += point.y - _pointTouch.y;
	self.frame = rect;
//	self.transform = CGAffineTransformMakeTranslation(point.x - _pointTouch.x, point.y - _pointTouch.y);
}

@end
