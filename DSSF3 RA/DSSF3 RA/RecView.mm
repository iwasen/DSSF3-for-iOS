//
//  RecView.m
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2017/01/06.
//  Copyright © 2017年 TRC. All rights reserved.
//

#import "RecView.h"
#import "DrawView.h"
#import "Common.h"

#define SELECT_MODE_NONE	0
#define SELECT_MODE_START	1
#define SELECT_MODE_END		2

#define SELECT_MARK_WIDTH	20
#define SELECT_MARK_HEIGHT	15

@implementation RecView
{
    BOOL _bInitialized;
    int _nScaleCenter;
    UIColor *_colorLeft, *_colorRight;
    UIColor *_colorBlack, *_colorGray, *_colorLightGray;
    UIColor *_colorSelectBar;
    UIColor *_colorReplayBar;
    UIColor *_colorWhite;
    UIColor *_colorSelectArea;
    NSDictionary *_fontAttrs;
    float _fStartTime;
    float _fDispTime;
    int _nData;
    CGPoint *_pPointBuf;
    int _nPoint;
    //    float _fReplayTime;
    int _selectMode;
    bool _selectAreaOnly;
    CGFloat _selectOffsetX;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();

	if (self.enabled) {
		[self.delegate drawGraphData:context: self];
	}
}

-(void)dealloc
{
	if (_pPointBuf != NULL) {
		delete [] _pPointBuf;
		_pPointBuf = NULL;
	}
}

- (void)initialize
{
	if (_bInitialized)
		return;

	_bInitialized = FALSE;
	_selectMode = SELECT_MODE_NONE;
	_pPointBuf = NULL;
//	_fReplayTime = -1;

	_bInitialized = TRUE;

	_colorLeft = [[UIColor alloc] COLOR_LEFT];
	_colorRight = [[UIColor alloc] COLOR_RIGHT];
	_colorBlack = [[UIColor alloc] RGB(0, 0, 0)];
	_colorGray = [[UIColor alloc] RGB(128, 128, 128)];
	_colorLightGray = [[UIColor alloc] RGB(192, 192, 192)];
	_colorSelectBar = [[UIColor alloc] RGB(0, 0, 0)];
	_colorReplayBar = [[UIColor alloc] RGB(0, 128, 0)];
	_colorWhite = [[UIColor alloc] RGB(255, 255, 255)];
	_colorSelectArea = [[UIColor alloc] RGB(192, 255, 255)];

	_fontAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
				  [UIFont systemFontOfSize:AdjustFontSize(17.0)], NSFontAttributeName,
				  _colorBlack, NSForegroundColorAttributeName,
				  nil];
}

- (void)layoutSubviews
{
	_nWidth = self.bounds.size.width;
	_nHeight = self.bounds.size.height;

	_nScaleLeft = AdjustFontSize(60);
	_nScaleTop = AdjustFontSize(30);
	_nScaleRight = _nWidth - AdjustFontSize(15);
	_nScaleBottom = _nHeight - AdjustFontSize(50);
	_nScaleWidth = _nScaleRight - _nScaleLeft;
	_nScaleHeight = _nScaleBottom - _nScaleTop;
	_nScaleCenter = _nScaleTop + _nScaleHeight / 2;

	_pPointBuf = new CGPoint[_nScaleWidth * 2 + 2];
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
	DrawLine(context, _nScaleLeft - 1, _nScaleTop, _nScaleLeft - 1, _nScaleBottom, _colorBlack);

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

	t1 = dispTime / 7;
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
				if (t >= 0.1 || t == 0)
					sText = [NSString stringWithFormat:@"%g", t];
				else
					sText = [NSString stringWithFormat:@"%gm", t * 1000];
				size = [sText sizeWithAttributes:_fontAttrs];
				DrawString(sText, x - size.width / 2, _nScaleBottom + 1, _fontAttrs);
			} else {
				if (x > _nScaleLeft) {
					DrawLine(context, x, _nScaleTop + 1, x, _nScaleBottom - 1, _colorLightGray);
				}
			}
		}
	}

	sText = NSLocalizedString(@"IDS_TIME", nil);
	sText = [sText stringByAppendingString:@" [sec]"];
	size = [sText sizeWithAttributes:_fontAttrs];
	DrawString(sText, _nScaleLeft + (_nScaleWidth - size.width) / 2, _nHeight - size.height - 4, _fontAttrs);

	sText = NSLocalizedString(@"IDS_AMPLITUDE", nil);
	size = [sText sizeWithAttributes:_fontAttrs];
	DrawRotateString(context, sText, 4, (_nScaleHeight - size.width) / 2 - _nScaleBottom, _fontAttrs);
}

- (void)dispGraph:(CGContextRef)context :(float)totalTime :(float)startTime :(float)dispTime :(const float *)pData :(int)nData :(int)nLR :(float)fMaxData :(float)selectStart :(float)selectEnd
{
	int i, i2;
	int x, x2;
	int y, ymin, ymax;

	_fStartTime = startTime;
	_fDispTime = dispTime;
	_nData = nData;

	[self drawScale:context :startTime :dispTime];

	if (pData == NULL)
		return;

	UIColor *color = (nLR == 0) ? _colorLeft : _colorRight;

	if (!_selectAreaOnly) {
		_nPoint = 0;
		x2 = 0;
		ymin = _nScaleBottom;
		ymax = _nScaleTop;
		i2 = int(startTime / totalTime * nData + 0.99);
		for (i = i2; i < nData; i++) {
			x = (int)((i * totalTime / nData - startTime) / dispTime * _nScaleWidth + 0.5) + _nScaleLeft;

			if (x2 == 0)
				x2 = x;

			if (x != x2) {
				_pPointBuf[_nPoint].x = x2;
				_pPointBuf[_nPoint].y = ymin;
				_nPoint++;
				if (ymax != ymin) {
					_pPointBuf[_nPoint].x = x2;
					_pPointBuf[_nPoint].y = ymax;
					_nPoint++;
				}
				ymin = _nScaleBottom;
				ymax = _nScaleTop;
				x2 = x;

				if (x > _nScaleRight)
					break;
			}

			y = (int)(_nScaleCenter - pData[i] * _nScaleHeight / 2 / fMaxData);
			if (y < ymin)
				ymin = y;
			if (y > ymax)
				ymax = y;
		}
	} else {
		_selectAreaOnly = NO;
	}

	if (_nPoint >= 2)
		DrawPolyline(context, _pPointBuf, _nPoint, color);

	[self drawSelectArea:context :selectStart :selectEnd];
}

- (void)drawSelectArea:(CGContextRef)context :(float)selectStart :(float)selectEnd
{
	CGFloat x1, x2;

	if (selectStart != selectEnd) {
		CGContextSetBlendMode(context, kCGBlendModeDarken);
		CGRect clipRects[2];
		clipRects[0] = CGRectMake(0, 0, _nWidth, _nScaleTop);
		clipRects[1] = CGRectMake(_nScaleLeft, _nScaleTop, _nScaleWidth + 1, _nScaleHeight);
		CGContextClipToRects(context, clipRects, 2);

		x1 = ((selectStart - _fStartTime) / _fDispTime * _nScaleWidth) + _nScaleLeft;
		x2 = ((selectEnd - _fStartTime) / _fDispTime * _nScaleWidth) + _nScaleLeft;

		DrawFillRect(context, x1, _nScaleTop, x2 - x1, _nScaleHeight, _colorSelectArea);
		DrawLine(context, x1, _nScaleTop, x1, _nScaleBottom, _colorSelectBar);
		DrawLine(context, x2, _nScaleTop, x2, _nScaleBottom, _colorSelectBar);

		[self drawSelectMark:context :x1];
		[self drawSelectMark:context :x2];
	}
}

- (void)drawSelectMark:(CGContextRef)context :(float)x
{
	if (x >= _nScaleLeft && x <= _nScaleRight + 1) {
		CGPoint points[4];
		points[0] = CGPointMake(x, _nScaleTop);
		points[1] = CGPointMake(x - SELECT_MARK_WIDTH / 2, _nScaleTop - SELECT_MARK_HEIGHT);
		points[2] = CGPointMake(x + SELECT_MARK_WIDTH / 2, _nScaleTop - SELECT_MARK_HEIGHT);
		points[3] = CGPointMake(x, _nScaleTop);
		DrawPolygon(context, points, 4, _colorBlack, _colorSelectArea);
	}
}

/*
- (void)setReplayPosition:(float)fReplayTime
{
	int ropModeOrg = _dcMem.SetROP2(R2_NOTXORPEN);
	CBitmap *pBitmapOrg = _dcMem.SelectObject(&_bitmapMem);
	CPen *pPenOrg = (CPen *)_dcMem.SelectObject(&_colorReplayBar);
	int x;

	_dcMem.SelectClipRgn(&_Rgn);

	if (_fReplayTime != -1) {
		x = (int)((_fReplayTime - _fStartTime) / _fDispTime * _nScaleWidth + 0.5) + _nScaleLeft;
		_dcMem.MoveTo(x, _nScaleTop);
		_dcMem.LineTo(x, _nScaleBottom);
	}

	if (fReplayTime != -1) {
		x = (int)((fReplayTime - _fStartTime) / _fDispTime * _nScaleWidth + 0.5) + _nScaleLeft;
		_dcMem.MoveTo(x, _nScaleTop);
		_dcMem.LineTo(x, _nScaleBottom);
	}

	_fReplayTime = fReplayTime;

	_dcMem.SelectObject(pBitmapOrg);
	_dcMem.SelectObject(pPenOrg);
	_dcMem.SetROP2(ropModeOrg);

	_dcMem.SelectClipRgn(NULL);

	Invalidate(FALSE);
	UpdateWindow();
}
*/

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	if (event.allTouches.count == 1) {
		UITouch *touch = [touches anyObject];
		CGPoint location = [touch locationInView:self];

		float selectStart, selectEnd;
		CGFloat x;
		CGRect rect;
		[self.delegate2 getSelectArea:&selectStart :&selectEnd];

		x = ((selectStart - _fStartTime) / _fDispTime * _nScaleWidth) + _nScaleLeft;
		rect = CGRectMake(x - SELECT_MARK_WIDTH / 2, _nScaleTop - SELECT_MARK_HEIGHT, SELECT_MARK_WIDTH, SELECT_MARK_HEIGHT);
		if (CGRectContainsPoint(rect, location)) {
			_selectMode = SELECT_MODE_START;
			_selectOffsetX = location.x - x;
		}


		x = ((selectEnd - _fStartTime) / _fDispTime * _nScaleWidth) + _nScaleLeft;
		rect = CGRectMake(x - SELECT_MARK_WIDTH / 2, _nScaleTop - SELECT_MARK_HEIGHT, SELECT_MARK_WIDTH, SELECT_MARK_HEIGHT);
		if (CGRectContainsPoint(rect, location)) {
			_selectMode = SELECT_MODE_END;
			_selectOffsetX = location.x - x;
		}
	}

	[super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	_selectMode = SELECT_MODE_NONE;

	[super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	_selectMode = SELECT_MODE_NONE;

	[super touchesCancelled:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGFloat previous = [touch previousLocationInView:self].x - _selectOffsetX;
	CGFloat now = [touch locationInView:self].x - _selectOffsetX;
	CGRect rectUpdate = CGRectMake(MIN(previous, now) - SELECT_MARK_WIDTH / 2 - 1, _nScaleTop - SELECT_MARK_HEIGHT - 1, ABS(previous - now) + SELECT_MARK_WIDTH + 2, _nScaleHeight + SELECT_MARK_HEIGHT + 2);

	switch (_selectMode) {
		case SELECT_MODE_START:
			[self.delegate2 changeSelectStart:(now - _nScaleLeft) / _nScaleWidth * _fDispTime + _fStartTime];
			_selectAreaOnly = YES;
			[self setNeedsDisplayInRect:rectUpdate];
			break;
		case SELECT_MODE_END:
			[self.delegate2 changeSelectEnd:(now - _nScaleLeft) / _nScaleWidth * _fDispTime + _fStartTime];
			_selectAreaOnly = YES;
			[self setNeedsDisplayInRect:rectUpdate];
			break;
		default:
			[super touchesMoved:touches withEvent:event];
			break;
	}
}

@end
