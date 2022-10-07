//
//  DstFreqGraphView.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/10.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "DstFreqGraphView.h"
#import "Common.h"
#import "DrawView.h"
#import "Spline.h"

@implementation DstFreqGraphView
{
    BOOL _bInitialized;
    int _nWidth;
    int _nHeight;
    int _nScaleLeft;
    int _nScaleTop;
    int _nScaleRight;
    int _nScaleBottom;
    int _nScaleWidth;
    int _nScaleHeight;
    UIColor *_colorBlack;
    UIColor *_colorGray;
    UIColor *_colorLightGray;
    UIColor *_colorLeft;
    UIColor *_colorRight;
    NSDictionary *_fontAttrs;
    DstDataView *_viewData;
}

-(void)layoutSubviews
{
	[self setSizes];

	_viewData.frame = CGRectMake(_nScaleLeft, _nScaleTop, _nScaleWidth, _nScaleHeight);
}

- (void)drawRect:(CGRect)rect
{
	if (_bInitialized) {
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGContextSetLineWidth(context, 1.0);

		[self.delegate drawGraphScale:context];
	}
}

- (void)drawDataView:(CGContextRef)context
{
	if (_bInitialized) {
		CGContextSetLineWidth(context, 2.0);

		[self.delegate drawGraphData:context];
	}
}

- (void)updateGraph
{
	[self setNeedsDisplay];
	[_viewData setNeedsDisplay];
}

- (void)updateData
{
	[_viewData setNeedsDisplay];
}

- (void)initialize
{
	_colorBlack = [[UIColor alloc] COLOR_BLACK];
	_colorGray = [[UIColor alloc] COLOR_GRAY];
	_colorLightGray = [[UIColor alloc] COLOR_LIGHTGRAY];
	_colorLeft = [[UIColor alloc] COLOR_LEFT];
	_colorRight = [[UIColor alloc] COLOR_RIGHT];

	_fontAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
				  [UIFont systemFontOfSize:AdjustFontSize(17.0)], NSFontAttributeName,
				  _colorBlack, NSForegroundColorAttributeName,
				  nil];

	[self setSizes];

	_viewData = [[DstDataView alloc] initWithFrame:CGRectMake(_nScaleLeft, _nScaleTop, _nScaleWidth, _nScaleHeight)];
	_viewData.delegate = self;
	[self addSubview:_viewData];

	_bInitialized = YES;
}

- (void)setSizes
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

- (void)drawScale:(CGContextRef)context :(int)nFreqStart :(int)nFreqEnd
{
	int x, y;
	int i;
	CGSize size;
	NSString *sText;
	float fStep;
	float fTHD;
	int nTHD;
	NSString *sUnit;
	UIColor *color;

	DrawFillRect(context, _nScaleLeft, _nScaleTop, _nScaleWidth, _nScaleHeight, [UIColor whiteColor]);

	int nFreqMin = MIN(nFreqStart, nFreqEnd);
	int nFreqMax = MAX(nFreqStart, nFreqEnd);
	float fLogFreqMin = log((float)nFreqMin);
	float fLogFreqMax = log((float)nFreqMax);

	float fDist = fLogFreqMax - fLogFreqMin;
	if (fDist != 0) {
		int step = GetLogScaleStep(nFreqMin);
		for (int nFreq = GetScaleStartValue(nFreqMin, step); nFreq <= nFreqMax; nFreq += GetLogScaleStep(nFreq)) {
			x =  (int)((log((float)nFreq) - fLogFreqMin) * _nScaleWidth / fDist + _nScaleLeft + 0.5);

			if (nFreq < 1000)
				sText = [NSString stringWithFormat:@"%d", nFreq];
			else
				sText = [NSString stringWithFormat:@"%gk", (float)nFreq / 1000];
			if ([sText characterAtIndex:0] == '1' || [sText characterAtIndex:0] == '2' || [sText characterAtIndex:0] == '5') {
				size = [sText sizeWithAttributes:_fontAttrs];
				DrawString(sText, x - size.width / 2, _nScaleBottom + 3, _fontAttrs);
			}

			if (x > _nScaleLeft && x < _nScaleRight) {
				DrawLine(context, x, _nScaleTop, x, _nScaleBottom, [sText characterAtIndex:0] == '1' ? _colorGray : _colorLightGray);
			}
		}
	}

	sText = NSLocalizedString(@"IDS_FREQUENCY", nil);
	sText = [sText stringByAppendingString:@" [Hz]"];
	size = [sText sizeWithAttributes:_fontAttrs];
	DrawString(sText, _nScaleLeft + (_nScaleWidth - size.width) / 2, _nHeight - size.height - 2, _fontAttrs);

	if (g_oSetData.Dst.nScaleMode == 0) {
		float fMinTHD = pow(10.0, g_oSetData.Dst.nScaleMin / 20);
		float fMaxTHD = pow(10.0, g_oSetData.Dst.nScaleMax / 20);
		int nDist = g_oSetData.Dst.nScaleMax - g_oSetData.Dst.nScaleMin;
		if (nDist != 0) {
			for (fTHD = fMinTHD, i = 0; fTHD <= fMaxTHD * 1.0001; fTHD += fStep, i++) {
				y = _nScaleBottom - (int)((dB20((float)fTHD) - g_oSetData.Dst.nScaleMin) * _nScaleHeight / nDist);

				if (i % 9 == 0) {
					color = _colorGray;
					sText = [NSString stringWithFormat:@"%1g", fTHD * 100];
					size = [sText sizeWithAttributes:_fontAttrs];
					DrawString(sText, _nScaleLeft - size.width - 2, y - size.height / 2, _fontAttrs);
				} else
					color = _colorLightGray;

				if (y > _nScaleTop && y < _nScaleBottom) {
					DrawLine(context, _nScaleLeft, y, _nScaleRight, y, color);
				}

				fStep = pow(10.0, (int)(log10(fTHD) + 0.0001) - 1);
			}
		}
		sUnit = @"[%]";
	} else {
		int nDist = g_oSetData.Dst.nScaleMax - g_oSetData.Dst.nScaleMin;
		if (nDist != 0) {
			int nStep = GetLinearScaleStep(g_oSetData.Dst.nScaleMax, g_oSetData.Dst.nScaleMin, _nScaleHeight);
			for (nTHD = g_oSetData.Dst.nScaleMin, i = 0; nTHD <= g_oSetData.Dst.nScaleMax; nTHD += nStep, i++) {
				y = _nScaleBottom - (int)((nTHD - g_oSetData.Dst.nScaleMin) * _nScaleHeight / nDist);

				if (i % 2 == 0) {
					color = _colorGray;
					sText = [NSString stringWithFormat:@"%d", nTHD];
					size = [sText sizeWithAttributes:_fontAttrs];
					DrawString(sText, _nScaleLeft - size.width - 2, y - size.height / 2, _fontAttrs);
				} else
					color = _colorLightGray;

				if (y > _nScaleTop && y < _nScaleBottom) {
					DrawLine(context, _nScaleLeft, y, _nScaleRight, y, color);
				}
			}
		}
		sUnit = @"[dB]";
	}

	DrawRectangle(context, _nScaleLeft, _nScaleTop, _nScaleRight + 1, _nScaleBottom + 1, _colorBlack);

	sText = NSLocalizedString(@"IDS_DISTORTION", nil);
	sText = [sText stringByAppendingString:@" "];
	sText = [sText stringByAppendingString:sUnit];
	size = [sText sizeWithAttributes:_fontAttrs];
	DrawRotateString(context, sText, 4, (_nScaleHeight - size.width) / 2 - _nScaleBottom, _fontAttrs);
}

- (void)drawData:(CGContextRef)context :(const float *)pLeftDst :(const float *)pRightDst :(const float *)pFreq :(int)nFreqCount :(int)nFreqStart :(int)nFreqEnd :(int)nFreqPoint
{
	if (pLeftDst != NULL) {
		[self drawLine:context :pLeftDst :pFreq :nFreqCount :nFreqStart :nFreqEnd :nFreqPoint :_colorLeft];
	}

	if (pRightDst != NULL) {
		[self drawLine:context :pRightDst :pFreq :nFreqCount :nFreqStart :nFreqEnd :nFreqPoint :_colorRight];
	}
}

- (void)drawLine:(CGContextRef)context :(const float *)pData :(const float *)pFreq :(int)nFreqCount :(int)nFreqStart :(int)nFreqEnd :(int)nFreqPoint :(UIColor *)color
{
	int i;
	int x, y;
	int nDotSize;
	int nFreqMin = MIN(nFreqStart, nFreqEnd);
	int nFreqMax = MAX(nFreqStart, nFreqEnd);
	float fLogFreqMin = log((float)nFreqMin);
	float fLogFreqMax = log((float)nFreqMax);
	float yStep = (float)_nScaleHeight / (g_oSetData.Dst.nScaleMin - g_oSetData.Dst.nScaleMax);
	CGPoint *pPoint = new CGPoint[nFreqCount];

	nDotSize = (_nScaleWidth / nFreqPoint < 10) ? 3 : 4;

	for (i = nFreqCount - 1; i >= 0; i--) {
		if (pData[i] != 0)
			break;
		nFreqCount--;
	}

	int nPointCnt = 0;
	for (i = 0; i < nFreqCount; i++) {
		if (pFreq[i] + 0.5 >= nFreqMin && pFreq[i] - 0.5 <= nFreqMax) {
			x = (int)((log((float)pFreq[i]) - fLogFreqMin) * _nScaleWidth / (fLogFreqMax - fLogFreqMin) + 0.5);
			y = (int)((dB10(pData[i]) - g_oSetData.Dst.nScaleMax) * yStep + 0.5);

			if (g_oSetData.Dst.bFreqMarker)
				DrawFillEllipse(context, x - nDotSize, y - nDotSize, x + nDotSize, y + nDotSize, color);

			pPoint[nPointCnt].x = x;
			pPoint[nPointCnt].y = y;
			nPointCnt++;
		}
	}

	if (g_oSetData.Dst.bFreqSpline && nPointCnt >= 3) {
		CSpline spl;
		float *xp = new float[nPointCnt];
		float *yp = new float[nPointCnt];

		if (pPoint[0].x <= pPoint[1].x) {
			for (i = 0; i < nPointCnt; i++) {
				xp[i] = pPoint[i].x;
				yp[i] = pPoint[i].y;
			}
		} else {
			for (i = 0; i < nPointCnt; i++) {
				xp[i] = pPoint[nPointCnt - i - 1].x;
				yp[i] = pPoint[nPointCnt - i - 1].y;
			}
		}

		spl.MakeTable(xp, yp, nPointCnt);

		delete [] yp;
		delete [] xp;

		int x1 = MIN(pPoint[0].x, pPoint[nPointCnt - 1].x);
		int x2 = MAX(pPoint[0].x, pPoint[nPointCnt - 1].x);
		int nSpline = x2 - x1;

		CGPoint *pSpline = new CGPoint[nSpline];
		for (i = 0; i < nSpline; i++) {
			pSpline[i].x = x1 + i;
			pSpline[i].y = spl.Spline(pSpline[i].x);
		}

		DrawPolyline(context, pSpline, nSpline, color);

		delete [] pSpline;
	} else
		DrawPolyline(context, pPoint, nPointCnt, color);

	delete [] pPoint;
}

@end
