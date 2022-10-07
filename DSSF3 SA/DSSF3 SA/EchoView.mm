//
//  EchoView.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/05.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "EchoView.h"
#import "DrawView.h"
#import "Common.h"
#import "RemarkView.h"

@implementation EchoView
{
    int _nScaleZero;
    UIColor *_colorData, *_colorData2;
    UIColor *_colorTsub;
    UIColor *_colorDot;
    UIColor *_colorBlack, *_colorGray, *_colorLightGray;
    UIColor *_colorT20, *_colorT30, *_colorEDT;
    NSDictionary *_fontAttrs;
    NSString *_title;
    REMARK_INFO _remark;
    RemarkView *_remarkView;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();

	if (self.enabled) {
		[self.delegate drawGraphData:context: self];
	}
}

- (void)initialize:(NSString *)title
{
	//	_pCallBackFunc = pCallBackFunc;
	//	_dwCallBackData = (DWORD)nCallBackData;

	_colorData = [[UIColor alloc] RGB(255, 0, 0)];
	_colorData2 = [[UIColor alloc] RGB(255, 0, 255)];
	_colorTsub = [[UIColor alloc] RGB(0, 0, 255)];
	_colorDot = [[UIColor alloc] RGB(0, 0, 255)];
	_colorBlack = [[UIColor alloc] RGB(0, 0, 0)];
	_colorGray = [[UIColor alloc] RGB(128, 128, 128)];
	_colorLightGray = [[UIColor alloc] RGB(192, 192, 192)];
	_colorT20 = [[UIColor alloc] RGB(224, 224, 0)];
	_colorT30 = [[UIColor alloc] RGB(128, 224, 0)];
	_colorEDT = [[UIColor alloc] RGB(0, 224, 224)];

	_fontAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
				  [UIFont systemFontOfSize:AdjustFontSize(17.0)], NSFontAttributeName,
				  _colorBlack, NSForegroundColorAttributeName,
				  nil];

	_title = title;

	_remarkView = [[RemarkView alloc] init];
}

- (void)layoutSubviews
{
	_nWidth = self.bounds.size.width;
	_nHeight = self.bounds.size.height;

	_nScaleLeft = AdjustFontSize(60);
	_nScaleTop = AdjustFontSize(10);
	_nScaleRight = _nWidth - AdjustFontSize(15);
	_nScaleBottom = _nHeight - AdjustFontSize(50);
	_nScaleWidth = _nScaleRight - _nScaleLeft;
	_nScaleHeight = _nScaleBottom - _nScaleTop;
}

- (void)drawScale:(CGContextRef)context :(float)startTime :(float)dispTime :(int)nMaxLevel :(int)nMinLevel
{
	NSString *sText;
	CGSize size;
	int i;
	int x, y;
	float step, t, t1, t2;
	int ns;
	int nLevelRange = nMaxLevel - nMinLevel;
	UIColor *color;

	_nScaleZero = _nScaleTop + _nScaleHeight * nMaxLevel / nLevelRange;

	DrawFillRect(context, _nScaleLeft, _nScaleTop, _nScaleWidth, _nScaleHeight, [UIColor whiteColor]);
	DrawLine(context, _nScaleLeft - 1, _nScaleTop, _nScaleLeft - 1, _nScaleBottom, _colorBlack);

	int yStep = _nScaleHeight >= 100 ? 10 : 20;

	for (i = nMaxLevel; i >= nMinLevel; i -= yStep) {
		y = _nScaleZero - (i * _nScaleHeight / nLevelRange);
		if (i == 0)
			color = _colorBlack;
		else if (i == nMinLevel)
			color = _colorGray;
		else
			color = _colorLightGray;

		DrawLine(context, _nScaleLeft, y, _nScaleRight, y, color);

		sText = [NSString stringWithFormat:@"%d", i];
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

	sText = NSLocalizedString(@"IDS_TIME", nil);
	sText = [sText stringByAppendingString:@" [ms]"];
	size = [sText sizeWithAttributes:_fontAttrs];
	DrawString(sText, _nScaleLeft + (_nScaleWidth - size.width) / 2, _nHeight - size.height - 4, _fontAttrs);

	sText = NSLocalizedString(@"IDS_REVLEVEL", nil);
	sText = [sText stringByAppendingString:@" [dB]"];
	size = [sText sizeWithAttributes:_fontAttrs];
	DrawRotateString(context, sText, 4, (_nScaleHeight - size.width) / 2 - _nScaleBottom, _fontAttrs);
}

- (void)dispGraph:(CGContextRef)context :(float)totalTime :(float)startTime :(float)dispTime :(const float *)pData :(const float *)pData2 :(int)nData :(float)fRate :(float)t0 :(float)t1 :(float)dev :(float)fEndTime :(int)nMaxLevel :(int)nMinLevel :(float)fT20Reg0 :(float)fT20Reg1 :(float)fT30Reg0 :(float)fT30Reg1 :(float)fEDTReg0 :(float)fEDTReg1
{
	int i, i2;
	int x, x2;
	int y, y2;
	int n;
	int nLevelRange = nMaxLevel - nMinLevel;
	float fOffset;

	[self drawScale:context :startTime :dispTime :nMaxLevel :nMinLevel];

	CGContextClipToRect (context, CGRectMake(_nScaleLeft, _nScaleTop, _nScaleWidth, _nScaleHeight));

	CGFloat len[] = {5, 5};
	CGContextSetLineDash(context, 0, len, 2);

	y = _nScaleZero - (-60 * _nScaleHeight / nLevelRange);
	DrawLine(context, _nScaleLeft, y, _nScaleRight, y, _colorDot);

	if (dev != 0) {
		float t1s = t1 / 1000;
		x = _nScaleLeft + (int)((t1s - startTime) / dispTime * _nScaleWidth);
		y = _nScaleZero;
		x2 = _nScaleLeft + (int)((t1s + (nMinLevel / dev - startTime)) / dispTime * _nScaleWidth);
		y2 = _nScaleBottom;
		DrawLine(context, x, y, x2, y2, _colorTsub);

		x = _nScaleLeft + (int)((t1s - startTime) / dispTime * _nScaleWidth);
		DrawLine(context, x, _nScaleTop, x, _nScaleBottom, _colorDot);

		x = _nScaleLeft + (int)((fEndTime - startTime) / dispTime * _nScaleWidth);
		DrawLine(context, x, _nScaleTop, x, _nScaleBottom, _colorDot);
	}

	CGContextSetLineDash(context, 0, nil, 0);

	int nT0Pos = (int)(t0 / 1000 * fRate);
	int nT1Pos = (int)(t1 / 1000 * fRate);
	if (fT20Reg1 != 0) {
		fOffset = -(fT20Reg0 + pData[nT0Pos] - pData[nT1Pos]) / fT20Reg1;
		x = _nScaleLeft + (int)((fOffset - startTime) / dispTime * _nScaleWidth);
		y = _nScaleZero;
		x2 = _nScaleLeft + (int)((fOffset + (nMinLevel / fT20Reg1 - startTime)) / dispTime * _nScaleWidth);
		y2 = _nScaleBottom;
		DrawLine(context, x, y, x2, y2, _colorT20);
	}

	if (fT30Reg1 != 0) {
		fOffset = -(fT30Reg0 + pData[nT0Pos] - pData[nT1Pos]) / fT30Reg1;
		x = _nScaleLeft + (int)((fOffset - startTime) / dispTime * _nScaleWidth);
		y = _nScaleZero;
		x2 = _nScaleLeft + (int)((fOffset + (nMinLevel / fT30Reg1 - startTime)) / dispTime * _nScaleWidth);
		y2 = _nScaleBottom;
		DrawLine(context, x, y, x2, y2, _colorT30);
	}

	if (fEDTReg1 != 0) {
		fOffset = -(fEDTReg0 + pData[nT0Pos] - pData[nT1Pos]) / fEDTReg1;
		x = _nScaleLeft + (int)((fOffset - startTime) / dispTime * _nScaleWidth);
		y = _nScaleZero;
		x2 = _nScaleLeft + (int)((fOffset + (nMinLevel / fEDTReg1 - startTime)) / dispTime * _nScaleWidth);
		y2 = _nScaleBottom;
		DrawLine(context, x, y, x2, y2, _colorEDT);
	}

	fOffset = startTime / totalTime * nData;
	i2 = int(fOffset);
	CGPoint *points = new CGPoint[_nScaleWidth * 2 + 2];

	if (pData != NULL) {
		x2 = y2 = 0;
		n = 0;
		for (i = i2; i < nData - 1; i++) {
			x = _nScaleLeft + int((i - fOffset) * totalTime / dispTime * _nScaleWidth / nData);
			y = _nScaleZero - (int)((float)pData[i] * _nScaleHeight / nLevelRange + 0.5);
			if (x >= _nScaleRight)
				break;

			if (i == i2)
				points[n++] = CGPointMake(x, y);
			else {
				if (x != x2 || y != y2)
					points[n++] = CGPointMake(x, y);
			}
			x2 = x;
			y2 = y;
		}

		DrawPolyline(context, points, n, _colorData);
	}

	if (pData2 != NULL) {
		x2 = y2 = 0;
		n = 0;
		for (i = i2; i < nData - 1; i++) {
			x = _nScaleLeft + int((i - i2) * totalTime / dispTime * _nScaleWidth / nData + 0.5);
			y = _nScaleZero - (int)((float)pData2[i] * _nScaleHeight / nLevelRange + 0.5);
			if (x >= _nScaleRight)
				break;

			if (i == i2)
				points[n++] = CGPointMake(x, y);
			else {
				if (x != x2 || y != y2)
					points[n++] = CGPointMake(x, y);
			}
			x2 = x;
			y2 = y;
		}

		DrawPolyline(context, points, n, _colorData2);
	}

	delete [] points;

	if (_title != nil) {
		int n = 0;
		_remark.remarks[n].color = nil;
		_remark.remarks[n++].text = _title;
		if (pData2 != NULL) {
			_remark.remarks[n].color = _colorData2;
			_remark.remarks[n++].text = NSLocalizedString(@"IDS_WITHOUTNOISE", nil);
		}
		if (pData != NULL) {
			_remark.remarks[n].color = _colorData;
			_remark.remarks[n++].text = NSLocalizedString(@"IDS_WITHNOISE", nil);
		}
		if (dev != 0) {
			_remark.remarks[n].color = _colorTsub;
			_remark.remarks[n++].text = [@"Tsub " stringByAppendingString:NSLocalizedString(@"IDS_REGRESSIONLINE", nil)];
		}
		if (fT20Reg1 != 0) {
			_remark.remarks[n].color = _colorT20;
			_remark.remarks[n++].text = [@"T20 " stringByAppendingString:NSLocalizedString(@"IDS_REGRESSIONLINE", nil)];
		}
		if (fT30Reg1 != 0) {
			_remark.remarks[n].color = _colorT30;
			_remark.remarks[n++].text = [@"T30 " stringByAppendingString:NSLocalizedString(@"IDS_REGRESSIONLINE", nil)];
		}
		if (fEDTReg1 != 0) {
			_remark.remarks[n].color = _colorEDT;
			_remark.remarks[n++].text = [@"EDT " stringByAppendingString:NSLocalizedString(@"IDS_REGRESSIONLINE", nil)];
		}
		_remark.nRemark = n;
		[_remarkView dispRemarks:&_remark :14 :self];
	}
}

- (void)dispEnergy:(CGContextRef)context :(float)totalTime :(float)startTime :(float)dispTime :(const float *)pData :(int)nData :(int)nMaxLevel :(int)nMinLevel
{
	int i, i2;
	int x, x2 = 0;
	int y;
	int nLevelRange = nMaxLevel - nMinLevel;
	float data;
	int nCount;
	BOOL bFirst = YES;
	int n;

	[self drawScale:context :startTime :dispTime :nMaxLevel :nMinLevel];

	CGPoint *points = new CGPoint[_nScaleWidth * 2 + 2];

	n = 0;
	data= 0;
	nCount = 0;
	i2 = int(startTime / totalTime * nData);
	for (i = i2; i < nData - 1; i++) {
		x = _nScaleLeft + int((i - i2) * totalTime / dispTime * _nScaleWidth / nData + 0.5);
		if (x >= _nScaleRight)
			break;

		if (i == i2)
			x2 = x;

		if (x != x2) {
			if (data != 0)
				data = log10(data / nCount) * 10;
			else
				data = -1000;
			y = _nScaleZero - (int)(data * _nScaleHeight / nLevelRange + 0.5);
			if (bFirst) {
				points[n++] = CGPointMake(x2, y);
				bFirst = NO;
			}
			points[n++] = CGPointMake(x2, y);
			x2 = x;
			data = 0;
			nCount = 0;
		}

		data += pData[i];
		nCount++;
	}

	DrawPolyline(context, points, n, _colorData);
	delete [] points;

	if (_title != nil) {
		_remark.nRemark = 1;
		_remark.remarks[0].color = nil;
		_remark.remarks[0].text = _title;
		[_remarkView dispRemarks:&_remark :14 :self];
	}
}
/*
void CEchoWnd::OnLButtonDown(UINT nFlags, CPoint point)
{
	if (point.y > _nScaleTop && point.y < _nScaleBottom) {
		if (_nMouseMode == MOUSE_SELECT_NONE) {
			_nScrollPos = point.x;
			_nMouseMode = MOUSE_SCROLL;
			SetCapture();
		}

		SetMouseCursor(point);
	}

	CWnd::OnLButtonDown(nFlags, point);
}

void CEchoWnd::OnLButtonUp(UINT nFlags, CPoint point)
{
	if (_nMouseMode != MOUSE_SELECT_NONE) {
		_nMouseMode = MOUSE_SELECT_NONE;
		ReleaseCapture();

		SetMouseCursor(point);
	}

	CWnd::OnLButtonUp(nFlags, point);
}

void CEchoWnd::OnMouseMove(UINT nFlags, CPoint point)
{
	switch (_nMouseMode) {
		case MOUSE_SCROLL:
			_pCallBackFunc(CC_SCROLL, _dwCallBackData, (float)(point.x - _nScrollPos) / _nScaleWidth, 0);
			_nScrollPos = point.x;
			break;
	}

	SetMouseCursor(point);

	CWnd::OnMouseMove(nFlags, point);
}
*/
@end
