//
//  ImpView.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/15.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "ImpView.h"
#import "Common.h"
#import "DrawView.h"

@implementation ImpView
{
    BOOL _bInitialized;
    int _nWidth, _nHeight;
    int _nScaleLeft, _nScaleTop, _nScaleRight, _nScaleBottom;
    int _nScaleWidth, _nScaleHeight, _nScaleCenter;
    UIColor *_colorLeft;
    UIColor *_colorRight;
    UIColor *_colorBlack, *_colorGray, *_colorLightGray;
    UIColor *_colorT0, *_colorT1;
    UIColor *_brushSelectArea;
    float _fStartTime;
    float _fDispTime;
    int _nData;
    int _nScrollPos;
    BOOL _bHScroll;
    CGPoint *_pPoint;
    NSDictionary *_fontAttrs;
    int _nChannel;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	[self.delegate drawGraphData:context: _nChannel];
}

- (void)initialize:(NSString *)pTitle :(int)nChannel
{
	if (_bInitialized)
		return;

	_nChannel = nChannel;

	_bInitialized = YES;

	_colorBlack = [[UIColor alloc] COLOR_BLACK];
	_colorGray = [[UIColor alloc] COLOR_GRAY];
	_colorLightGray = [[UIColor alloc] COLOR_LIGHTGRAY];
	_colorLeft = [[UIColor alloc] COLOR_LEFT];
	_colorRight = [[UIColor alloc] COLOR_RIGHT];

	_fontAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
				  [UIFont systemFontOfSize:AdjustFontSize(17.0)], NSFontAttributeName,
				  _colorBlack, NSForegroundColorAttributeName,
				  nil];
}

-(void)layoutSubviews
{
	_nWidth = self.bounds.size.width;
	_nHeight = self.bounds.size.height;

	_nScaleLeft = AdjustFontSize(60);
	_nScaleTop = AdjustFontSize(10);
	_nScaleRight = _nWidth - AdjustFontSize(15);
	_nScaleBottom = _nHeight - AdjustFontSize(50);
	_nScaleWidth = _nScaleRight - _nScaleLeft;
	_nScaleHeight = _nScaleBottom - _nScaleTop;
	_nScaleCenter = _nScaleTop + _nScaleHeight / 2;

	_pPoint = new CGPoint[_nScaleWidth * 2 + 4];
}

- (void)dealloc
{
	if (_pPoint != NULL) {
		delete [] _pPoint;
		_pPoint = NULL;
	}
}

- (void)drawScale:(CGContextRef)context :(float)startTime :(float)dispTime
{
	NSString *sText;
	CGSize size;
	int i;
	int x, y;
	float step, t, t1, t2;
	int ns;
	UIColor *color;

	DrawFillRect(context, _nScaleLeft, _nScaleTop, _nScaleWidth, _nScaleHeight, [UIColor whiteColor]);

	for (i = 100; i >= -100; i -= 20) {
		y = _nScaleCenter - (i * (_nScaleHeight / 2) / 100);
		if (i == 0 || i == 100 || i == -100)
			color = _colorBlack;
		else
			color = _colorLightGray;

		DrawLine(context, _nScaleLeft, y, _nScaleRight, y, color);

		sText = [NSString stringWithFormat:@"%g", (float)i / 100];
		size = [sText sizeWithAttributes:_fontAttrs];
		DrawString(sText, _nScaleLeft - size.width - 3, y - size.height / 2, _fontAttrs);
	}

	t1 = dispTime / _nScaleWidth * 100;
	step = pow(10.0, floor(log10(t1)));
	t2 = t1 / step;
	if (t2 < 2) {
		step *= 0.5;
		ns = 2;
	} else if (t2 < 5)
		ns = 2;
	else
		ns = 5;

	for (t = floor(startTime / step) * step; t < startTime + dispTime; t += step) {
		x = _nScaleLeft + int((t - startTime) * _nScaleWidth / dispTime);
		if (x >= _nScaleLeft) {
			if (int(t / step + 0.5) % ns == 0) {
				if (x > _nScaleLeft) {
					DrawLine(context, x, _nScaleTop + 1, x, _nScaleBottom - 1, _colorGray);
				}
				sText = [NSString stringWithFormat:@"%g", t * 1000];
				size = [sText sizeWithAttributes:_fontAttrs];
				DrawString(sText, x - size.width / 2, _nScaleBottom + 3, _fontAttrs);
			} else {
				if (x > _nScaleLeft) {
					DrawLine(context, x, _nScaleTop + 1, x, _nScaleBottom - 1, _colorLightGray);
				}
			}
		}
	}

	DrawLine(context, _nScaleLeft - 1, _nScaleTop, _nScaleLeft - 1, _nScaleBottom, _colorBlack);
	DrawLine(context, _nScaleLeft, _nScaleCenter, _nScaleRight, _nScaleCenter, _colorBlack);

	sText = NSLocalizedString(@"IDS_TIME", nil);
	sText = [sText stringByAppendingString:@" [ms]"];
	size = [sText sizeWithAttributes:_fontAttrs];
	DrawString(sText, _nScaleLeft + (_nScaleWidth - size.width) / 2, _nHeight - size.height - 2, _fontAttrs);

	sText = NSLocalizedString(@"IDS_AMPLITUDE", nil);
	size = [sText sizeWithAttributes:_fontAttrs];
	DrawRotateString(context, sText, 4, (_nScaleHeight - size.width) / 2 - _nScaleBottom, _fontAttrs);

	if (_nChannel == 1) {
		sText = @"Lch";
		color = _colorLeft;
	} else {
		sText = @"Rch";
		color = _colorRight;
	}
	size = [sText sizeWithAttributes:_fontAttrs];
	NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								  [UIFont systemFontOfSize:FONT_SIZE_SCALE], NSFontAttributeName,
								  color, NSForegroundColorAttributeName,
								  nil];
	DrawString(sText, _nScaleRight - size.width - 10, _nScaleTop + 5, attrs);
}

- (void)drawData:(CGContextRef)context :(float)totalTime :(float)startTime :(float)dispTime :(const float *)pData :(int)nData
{
	int i, i2;
	int x, x2;
	int y;
	int ymin, ymax;
	int nPoint = 0;

	if (!_enabled)
		return;

	_fStartTime = startTime;
	_fDispTime = dispTime;
	_nData = nData;

	[self drawScale:context :startTime :dispTime];

	if (pData == NULL)
		return;

	x2 = 0;
	ymin = ymax = _nScaleCenter;
	i2 = int(startTime / totalTime * nData + 0.99);
	for (i = i2; i < nData - 1; i++) {
		x = (int)((i * totalTime / nData - startTime) / dispTime * _nScaleWidth + 0.5) + _nScaleLeft;

		if (x2 == 0)
			x2 = x;

		if (x != x2) {
			if (ymin == _nScaleCenter && ymax == _nScaleCenter) {
				_pPoint[nPoint].x = x2;
				_pPoint[nPoint].y = _nScaleCenter;
				nPoint++;
			} else {
				if (ymin != _nScaleCenter) {
					_pPoint[nPoint].x = x2;
					_pPoint[nPoint].y = ymin;
					nPoint++;
				}

				if (ymax != _nScaleCenter) {
					_pPoint[nPoint].x = x2;
					_pPoint[nPoint].y = ymax;
					nPoint++;
				}
			}

			if (x2 > _nScaleRight)
				break;

			ymin = ymax = _nScaleCenter;
			x2 = x;
		}

		y = (int)(_nScaleCenter - pData[i] * _nScaleHeight / 2 + 0.5);
		if (y < ymin)
			ymin = y;
		if (y > ymax)
			ymax = y;
	}

	if (nPoint != 0)
		DrawPolyline(context, _pPoint, nPoint, _nChannel == 1 ? _colorLeft : _colorRight);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (event.allTouches.count == 1) {
		UITouch *touch = [touches anyObject];
		CGPoint previous = [touch previousLocationInView:self];
		CGPoint now = [touch locationInView:self];
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

		[self.delegate zoomGraph:self :previousDistance / distance];
	}
}

@end
