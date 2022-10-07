//
//  ImpulseView.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/15.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "ImpulseView.h"
#import "DrawView.h"
#import "Common.h"
#import "RemarkView.h"

@implementation ImpulseView
{
    int _nScaleCenter;
    UIColor *_colorWave;
    UIColor *_colorBlack, *_colorGray, *_colorLightGray;
    UIColor *_colorT0, *_colorT1;
    NSDictionary *_fontAttrs;
    float _fStartTime;
    float _fDispTime;
    int _nData;
    float _fT0;
    float _fT1;
    float _fStartSelectTime;
    float _fEndSelectTime;
    //    int _nMouseMode;
    //    int _nMouseOffset;
    //    PFNGRAPH _pCallBackFunc;
    //    DWORD _dwCallBackData;
    CGPoint *_pPoint;
    REMARK_INFO _remark;
    RemarkView *_remarkView;
}

- (void)awakeFromNib
{
	[super awakeFromNib];

	_fT0 = -1;
	_fT1 = -1;
}

-(void)dealloc
{
	[self freeBuffer];
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();

	if (self.enabled) {
		int x;

		[self.delegate drawGraphData:context: self];

		CGFloat len[] = {5, 5};
		CGContextSetLineDash(context, 0, len, 2);

		if (_fT0 >= 0) {
			x = (int)((_fT0 - _fStartTime) / _fDispTime * _nScaleWidth + 0.5) + _nScaleLeft;
			if (x >= _nScaleLeft && x < _nScaleRight) {
				DrawLine(context, x, _nScaleTop, x, _nScaleBottom, _colorT0);
			}
		}
		if (_fT1 >= 0) {
			x = (int)((_fT1 - _fStartTime) / _fDispTime * _nScaleWidth + 0.5) + _nScaleLeft;
			if (x >= _nScaleLeft && x < _nScaleRight) {
				DrawLine(context, x, _nScaleTop, x, _nScaleBottom, _colorT1);
			}
		}
	}
}

- (void)initialize:(NSString *)pTitle :(int)nRemark :(UIColor *)colorWave
{
//	_pCallBackFunc = pCallBackFunc;
//	_dwCallBackData = (DWORD)nCallBackData;

	_colorWave = colorWave;
	_colorBlack = [[UIColor alloc] RGB(0, 0, 0)];
	_colorGray = [[UIColor alloc] RGB(128, 128, 128)];
	_colorLightGray = [[UIColor alloc] RGB(192, 192, 192)];
	_colorT0 = [[UIColor alloc] RGB(0, 255, 0)];
	_colorT1 = [[UIColor alloc] RGB(255, 0, 0)];

	_fontAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
				  [UIFont systemFontOfSize:AdjustFontSize(17.0)], NSFontAttributeName,
				  _colorBlack, NSForegroundColorAttributeName,
				  nil];

	if (pTitle != NULL) {
		_remark.nRemark = nRemark;
		_remark.remarks[0].color = (nRemark > 1) ? _colorWave : NULL;
		_remark.remarks[0].text = pTitle;
		_remark.remarks[0].dash = NO;
		_remark.remarks[1].color = _colorT0;
		_remark.remarks[1].text = NSLocalizedString(@"IDS_DIRECTSOUND", nil);
		_remark.remarks[1].dash = YES;
		_remark.remarks[2].color = _colorT1;
		_remark.remarks[2].text = NSLocalizedString(@"IDS_FIRSTREFLECTION", nil);
		_remark.remarks[2].dash = YES;

		_remarkView = [[RemarkView alloc] init];
	}
}

- (void)layoutSubviews
{
	[_remarkView dispRemarks:&_remark :14: self];

	_nWidth = self.bounds.size.width;
	_nHeight = self.bounds.size.height;

	_nScaleLeft = AdjustFontSize(60);
	_nScaleTop = AdjustFontSize(10);
	_nScaleRight = _nWidth - AdjustFontSize(15);
	_nScaleBottom = _nHeight - AdjustFontSize(50);
	_nScaleWidth = _nScaleRight - _nScaleLeft;
	_nScaleHeight = _nScaleBottom - _nScaleTop;
	_nScaleCenter = _nScaleTop + _nScaleHeight / 2;

	[self allocBuffer];
}

- (void)allocBuffer
{
	[self freeBuffer];
	_pPoint = new CGPoint[_nScaleWidth * 2 + 4];
}

- (void)freeBuffer
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

	int yStep = _nScaleHeight >= 100 ? 20 : 50;

	for (i = 100; i >= -100; i -= yStep) {
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

	t1 = dispTime / _nScaleWidth * 75;
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
				DrawString(sText, x - size.width / 2, _nScaleBottom + 1, _fontAttrs);
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
	DrawString(sText, _nScaleLeft + (_nScaleWidth - size.width) / 2, _nHeight - size.height - 4, _fontAttrs);

	sText = NSLocalizedString(@"IDS_AMPLITUDE", nil);
	size = [sText sizeWithAttributes:_fontAttrs];
	DrawRotateString(context, sText, 4, (_nScaleHeight - size.width) / 2 - _nScaleBottom, _fontAttrs);
}

- (void)dispImpulse:(CGContextRef)context :(float)totalTime :(float)startTime :(float)dispTime :(const float *)pData :(int)nData
{
	float fMaxVal;
	int i, i2;
	int x, x2;
	int y;
	int ymin, ymax;
	int nPoint = 0;

	if (!self.enabled)
		return;

	_fStartTime = startTime;
	_fDispTime = dispTime;
	_nData = nData;

	[self drawScale:context :startTime :dispTime];

	if (pData == NULL)
		return;

	fMaxVal = GetMaxData(pData, nData);

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

		y = (int)(_nScaleCenter - pData[i] * _nScaleHeight / 2 / fMaxVal + 0.5);
		if (y < ymin)
			ymin = y;
		if (y > ymax)
			ymax = y;
	}

	if (nPoint != 0)
		DrawPolyline(context, _pPoint, nPoint, _colorWave);
}

- (void)setDeltaT1:(float)T0 :(float)T1
{
	_fT0 = T0 / 1000;
	_fT1 = T1 / 1000;
}
/*
void CImpWnd::OnLButtonDown(UINT nFlags, CPoint point)
{
	if (point.y > _nScaleTop && point.y < _nScaleBottom) {
		if (_fStartSelectTime >= 0) {
			int x1 = (int)((_fStartSelectTime - _fStartTime) / _fDispTime * _nScaleWidth + 0.5) + _nScaleLeft;
			int x2 = (int)((_fEndSelectTime - _fStartTime) / _fDispTime * _nScaleWidth + 0.5) + _nScaleLeft;

			if (abs(point.x - x2) < 2) {
				_nMouseMode = MOUSE_SELECT_END;
				_nMouseOffset = point.x - x2;
				if (_pCallBackFunc != NULL)
					_pCallBackFunc(CC_SELECT_START, _dwCallBackData, _fStartSelectTime, _fEndSelectTime);
			} else if (abs(point.x - x1) < 2) {
				_nMouseMode = MOUSE_SELECT_START;
				_nMouseOffset = point.x - x1;
				if (_pCallBackFunc != NULL)
					_pCallBackFunc(CC_SELECT_START, _dwCallBackData, _fStartSelectTime, _fEndSelectTime);
			}
		}

		if (_fT0 >= 0) {
			int x1 = (int)((_fT0 - _fStartTime) / _fDispTime * _nScaleWidth + 0.5) + _nScaleLeft;
			int x2 = (int)((_fT1 - _fStartTime) / _fDispTime * _nScaleWidth + 0.5) + _nScaleLeft;

			if (abs(point.x - x2) < 2) {
				_nMouseMode = MOUSE_T1;
				_nMouseOffset = point.x - x2;
				if (_pCallBackFunc != NULL)
					_pCallBackFunc(CC_DT1_START, _dwCallBackData, _fT0, _fT1);
			} else if (abs(point.x - x1) < 2) {
				_nMouseMode = MOUSE_T0;
				_nMouseOffset = point.x - x1;
				if (_pCallBackFunc != NULL)
					_pCallBackFunc(CC_DT1_START, _dwCallBackData, _fT0, _fT1);
			}
		}

		if (_nMouseMode == MOUSE_SELECT_NONE) {
			_nScrollPos = point.x;
			_nMouseMode = MOUSE_SCROLL;
			_nMouseOffset = 0;
		}

		SetCapture();

		SetMouseCursor(point);
	}

	CWnd::OnLButtonDown(nFlags, point);
}

void CImpWnd::OnLButtonUp(UINT nFlags, CPoint point)
{
	if (_nMouseMode != MOUSE_SELECT_NONE) {
		switch (_nMouseMode) {
			case MOUSE_SELECT_START:
			case MOUSE_SELECT_END:
				if (_pCallBackFunc != NULL)
					_pCallBackFunc(CC_SELECT_END, _dwCallBackData, _fStartSelectTime, _fEndSelectTime);
				break;
			case MOUSE_T0:
			case MOUSE_T1:
				if (_pCallBackFunc != NULL)
					_pCallBackFunc(CC_DT1_END, _dwCallBackData, _fT0, _fT1);
				break;
		}

		_nMouseMode = MOUSE_SELECT_NONE;
		ReleaseCapture();

		SetMouseCursor(point);
	}

	CWnd::OnLButtonUp(nFlags, point);
}

void CImpWnd::OnMouseMove(UINT nFlags, CPoint point)
{
	int x = point.x - _nMouseOffset - _nScaleLeft;
	if (x < 0)
		x = 0;
	if (x > _nScaleWidth)
		x = _nScaleWidth;

	float t = x * _fDispTime / _nScaleWidth + _fStartTime;

	switch (_nMouseMode) {
		case MOUSE_SELECT_START:
		case MOUSE_SELECT_END:
			if (_nMouseMode == MOUSE_SELECT_START) {
				if (t < _fEndSelectTime) {
					SetSelectArea(t, _fEndSelectTime);
					if (_pCallBackFunc != NULL)
						_pCallBackFunc(CC_SELECT_MOVE, _dwCallBackData, _fStartSelectTime, _fEndSelectTime);
				}
			} else {
				if (t > _fStartSelectTime) {
					SetSelectArea(_fStartSelectTime, t);
					if (_pCallBackFunc != NULL)
						_pCallBackFunc(CC_SELECT_MOVE, _dwCallBackData, _fStartSelectTime, _fEndSelectTime);
				}
			}
			break;
		case MOUSE_T0:
		case MOUSE_T1:
			if (_nMouseMode == MOUSE_T0) {
				if (t < _fT1) {
					_fT0 = t;
					Invalidate(NO);
					UpdateWindow();
					if (_pCallBackFunc != NULL)
						_pCallBackFunc(CC_DT1_MOVE, _dwCallBackData, _fT0, _fT1);
				}
			} else {
				if (t > _fT0) {
					_fT1 = t;
					Invalidate(NO);
					UpdateWindow();
					if (_pCallBackFunc != NULL)
						_pCallBackFunc(CC_DT1_MOVE, _dwCallBackData, _fT0, _fT1);
				}
			}
			break;
		case MOUSE_SCROLL:
			_pCallBackFunc(CC_SCROLL, _dwCallBackData, (float)(point.x - _nScrollPos) / _nScaleWidth, 0);
			_nScrollPos = point.x;
			break;
	}

	SetMouseCursor(point);

	CWnd::OnMouseMove(nFlags, point);
}

void CImpWnd::SetMouseCursor(CPoint point)
{
	HCURSOR hCursor = _hCursorArrow;

	switch (_nMouseMode) {
		case MOUSE_SELECT_START:
		case MOUSE_SELECT_END:
		case MOUSE_T0:
		case MOUSE_T1:
			hCursor = _hCursorHMove;
			break;
		case MOUSE_SCROLL:
			if (_bHScroll)
				hCursor = _hCursorHScroll;
			break;
		default:
			if (_fStartSelectTime >= 0) {
				int x1 = (int)((_fStartSelectTime - _fStartTime) / _fDispTime * _nScaleWidth + 0.5) + _nScaleLeft;
				int x2 = (int)((_fEndSelectTime - _fStartTime) / _fDispTime * _nScaleWidth + 0.5) + _nScaleLeft;
				if ((abs(point.x - x2) < 2 || abs(point.x - x1) < 2) && point.y > _nScaleTop && point.y < _nScaleBottom)
					hCursor = _hCursorHMove;
			}
			if (_fT0 >= 0) {
				int x1 = (int)((_fT0 - _fStartTime) / _fDispTime * _nScaleWidth + 0.5) + _nScaleLeft;
				int x2 = (int)((_fT1 - _fStartTime) / _fDispTime * _nScaleWidth + 0.5) + _nScaleLeft;
				if ((abs(point.x - x2) < 2 || abs(point.x - x1) < 2) && point.y > _nScaleTop && point.y < _nScaleBottom)
					hCursor = _hCursorHMove;
			}
			break;
	}
	
	::SetCursor(hCursor);
}

BOOL CImpWnd::OnSetCursor(CWnd* pWnd, UINT nHitTest, UINT message)
{
	return YES;
}
*/

@end
