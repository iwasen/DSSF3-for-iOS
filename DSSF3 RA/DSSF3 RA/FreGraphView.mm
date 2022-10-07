//
//  FreGraphView.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/01.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "FreGraphView.h"
#import "Common.h"
#import "DrawView.h"

@implementation FreGraphView
{
    BOOL _bInitialized;
    int _nMode;
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
    FreDataView *_viewData;
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

- (void)initialize:(int)nMode :(int)nFreqStart :(int)nFreqEnd
{
	_nMode = nMode;

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

	_viewData = [[FreDataView alloc] initWithFrame:CGRectMake(_nScaleLeft, _nScaleTop, _nScaleWidth, _nScaleHeight)];
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

- (void)updateGraph
{
	[self setNeedsDisplay];
	[_viewData setNeedsDisplay];
}

- (void)updateData
{
	[_viewData setNeedsDisplay];
}

- (void)drawScale:(CGContextRef)context :(int)nFreqStart :(int)nFreqEnd
{
	int x, y;
	CGSize size;
	NSString *sText;
	int nLevel;
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

	int nDist = g_oSetData.Fre.nMaxLevel - g_oSetData.Fre.nMinLevel;
	if (nDist > 0) {
		int nStep = GetLinearScaleStep(g_oSetData.Fre.nMaxLevel, g_oSetData.Fre.nMinLevel, _nScaleHeight);
		for (nLevel = GetScaleStartValue(g_oSetData.Fre.nMinLevel, nStep); nLevel <= g_oSetData.Fre.nMaxLevel; nLevel += nStep) {
			y = _nScaleBottom - (int)((nLevel - g_oSetData.Fre.nMinLevel) * _nScaleHeight / nDist);

			if (nLevel / 10 * 10 == nLevel) {
				color = _colorGray;
				sText = [NSString stringWithFormat:@"%d", nLevel];
				size = [sText sizeWithAttributes:_fontAttrs];
				DrawString(sText, _nScaleLeft - size.width - 2, y - size.height / 2, _fontAttrs);
			} else
				color = _colorLightGray;

			if (y > _nScaleTop && y < _nScaleBottom) {
				DrawLine(context, _nScaleLeft, y, _nScaleRight, y, color);
			}
		}
	}

	DrawRectangle(context, _nScaleLeft, _nScaleTop, _nScaleRight + 1, _nScaleBottom + 1, _colorBlack);

	sText = NSLocalizedString(@"IDS_LEVEL", nil);
	sText = [sText stringByAppendingString:@" [dB]"];
	size = [sText sizeWithAttributes:_fontAttrs];
	DrawRotateString(context, sText, 4, (_nScaleHeight - size.width) / 2 - _nScaleBottom, _fontAttrs);
}

- (void)drawData:(CGContextRef)context :(const float *)pLeftFre :(const float *)pRightFre :(const float *)pFreq :(int)nFreqCount :(int)nFreqStart :(int) nFreqEnd :(int)nFreqPoint
{
	if (pLeftFre != NULL) {
		if (_nMode != 2)
			[self drawLine1:context :pLeftFre :pFreq :nFreqCount :nFreqStart :nFreqEnd :nFreqPoint :_colorLeft];
		else
			[self drawLine2:context :pLeftFre :pFreq :nFreqCount :nFreqStart :nFreqEnd :_colorLeft];
	}

	if (pRightFre != NULL) {
		if (_nMode != 2)
			[self drawLine1:context :pRightFre :pFreq :nFreqCount :nFreqStart :nFreqEnd :nFreqPoint :_colorRight];
		else
			[self drawLine2:context :pRightFre :pFreq :nFreqCount :nFreqStart :nFreqEnd :_colorRight];
	}
}

-(void)drawLine1:(CGContextRef)context :(const float *)pData :(const float *)pFreq :(int)nFreqCount :(int)nFreqStart :(int)nFreqEnd :(int)nFreqPoint :(UIColor *)color
{
	int i;
	int x, y;
	int nDotSize;
	int nFreqMin = MIN(nFreqStart, nFreqEnd);
	int nFreqMax = MAX(nFreqStart, nFreqEnd);
	float fLogFreqMin = log((float)nFreqMin);
	float fLogFreqMax = log((float)nFreqMax);
	float yStep = (float)_nScaleHeight / (g_oSetData.Fre.nMinLevel - g_oSetData.Fre.nMaxLevel);
	CGPoint *pPoint = new CGPoint[nFreqCount];

	if (nFreqPoint != 0)
		nDotSize = (_nScaleWidth / nFreqPoint < 10) ? 3 : 4;
	else
		nDotSize = 0;

	int nPointCnt = 0;
	int x2 = 0;
	int y2 = 0;
	for (i = 0; i < nFreqCount; i++) {
		if (pFreq[i] + 0.5 >= nFreqMin && pFreq[i] - 0.5 <= nFreqMax) {
			x =  (int)((log((float)pFreq[i]) - fLogFreqMin) * _nScaleWidth / (fLogFreqMax - fLogFreqMin) + 0.5);
			y = (int)((dB10(pData[i]) - g_oSetData.Fre.nMaxLevel) * yStep + 0.5);

			if (nDotSize > 0)
				DrawFillEllipse(context, x - nDotSize, y - nDotSize, x + nDotSize, y + nDotSize, color);

			if (x != x2 || y != y2) {
				pPoint[nPointCnt].x = x;
				pPoint[nPointCnt].y = y;
				x2 = x;
				y2 = y;
				nPointCnt++;
			}
		}
	}

	DrawPolyline(context, pPoint, nPointCnt, color);

	delete [] pPoint;
}

- (void)drawLine2:(CGContextRef)context :(const float *)pData :(const float *)pFreq :(int)nFreqCount :(int)nFreqStart :(int)nFreqEnd :(UIColor *)color
{
	int i;
	int x, y;
	int nFreqMin = MIN(nFreqStart, nFreqEnd);
	int nFreqMax = MAX(nFreqStart, nFreqEnd);
	float fLogFreqMin = log((float)nFreqMin);
	float fLogFreqMax = log((float)nFreqMax);
	float yStep = (float)_nScaleHeight / (g_oSetData.Fre.nMinLevel - g_oSetData.Fre.nMaxLevel);
	CGPoint *pPoint = new CGPoint[nFreqCount];

	int nPointCnt = 0;
	int x2 = 0;
	float fData = 0;
	int nAddCount = 0;
	for (i = 0; i < nFreqCount; i++) {
		x =  (int)((log((float)pFreq[i]) - fLogFreqMin) * _nScaleWidth / (fLogFreqMax - fLogFreqMin) + 0.5);
		if (i == 0)
			x2 = x;
		else if (i == nFreqCount - 1) {
			x2 = x;
			x = 0;
		}

		fData += *pData++;
		nAddCount++;

		if (x != x2) {
			y = (int)((dB10(fData / nAddCount) - g_oSetData.Fre.nMaxLevel) * yStep + 0.5);
			pPoint[nPointCnt].x = x2;
			pPoint[nPointCnt].y = y;
			nPointCnt++;
			x2 = x;
			fData = 0;
			nAddCount = 0;
		}
	}

	DrawPolyline(context, pPoint, nPointCnt, color);
	
	delete [] pPoint;
}

@end
