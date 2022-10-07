//
//  FreqView.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/07.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "FreqView.h"
#import "DrawView.h"
#import "Common.h"
#import "RemarkView.h"

@implementation FreqView
{
    int _nScaleCenter;
    UIColor *_colorFreq;
    UIColor *_colorPhase;
    UIColor *_colorBlack, *_colorGray;
    NSDictionary *_fontAttrs;
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

- (void)initialize:(NSString *)title :(int)nRemark :(UIColor *)freqColor :(CGFloat)fontSize
{
	_colorFreq = freqColor;
	_colorBlack = [[UIColor alloc] RGB(0, 0, 0)];
	_colorGray = [[UIColor alloc] RGB(128, 128, 128)];

	_fontAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
				  [UIFont systemFontOfSize:AdjustFontSize(fontSize)], NSFontAttributeName,
				  _colorBlack, NSForegroundColorAttributeName,
				  nil];

	if (title != nil) {
		_remark.nRemark = nRemark;
		_remark.remarks[0].color = NULL;
		_remark.remarks[0].text = title;
		_remark.remarks[1].color = _colorFreq;
		_remark.remarks[1].text = NSLocalizedString(@"IDS_FREQRESP", nil);
		_remark.remarks[2].color = _colorPhase;
		_remark.remarks[3].text = NSLocalizedString(@"IDS_PHASE", nil);

		_remarkView = [[RemarkView alloc] init];
	}
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
	_nScaleCenter = _nScaleTop + _nScaleHeight / 2;
}

- (void)drawScale:(CGContextRef)context :(int)nScale :(int)nMinFreq :(int)nMaxFreq :(int)nMinLevel :(int)nMaxLevel
{
	int	nFreq, nLevel;
	int x, y;
	NSString *sText;
	CGSize size;

	DrawFillRect(context, _nScaleLeft, _nScaleTop, _nScaleWidth, _nScaleHeight, [UIColor whiteColor]);

	DrawRectangle(context, _nScaleLeft, _nScaleTop, _nScaleRight, _nScaleBottom, _colorBlack);

	if (nScale == 0) {
		float fMaxFreqLog = log((float)nMaxFreq);
		float fMinFreqLog = log((float)nMinFreq);
		float fSpanFreq = fMaxFreqLog - fMinFreqLog;
		for (nFreq = nMinFreq; nFreq <= nMaxFreq; ) {
			x =  _nScaleLeft + (int)((log((float)nFreq) - fMinFreqLog) * _nScaleWidth / fSpanFreq + 0.5);

			if (x > _nScaleLeft && x < _nScaleRight) {
				DrawLine(context, x, _nScaleTop, x, _nScaleBottom, _colorGray);
			}

			if (nFreq < 1000)
				sText = [NSString stringWithFormat:@"%d", nFreq];
			else
				sText = [NSString stringWithFormat:@"%dk", nFreq / 1000];
			if ([sText characterAtIndex:0] == '1' || [sText characterAtIndex:0] == '2' || [sText characterAtIndex:0] == '5') {
				size = [sText sizeWithAttributes:_fontAttrs];
				DrawString(sText, x - size.width / 2, _nScaleBottom + 1, _fontAttrs);
			}

			if (nFreq < 10)
				nFreq += 1;
			else if (nFreq < 100)
				nFreq += 10;
			else if (nFreq < 1000)
				nFreq += 100;
			else if (nFreq < 10000)
				nFreq += 1000;
			else
				nFreq += 10000;
		}
	} else {
		int step = (nMaxFreq - nMinFreq) / 5;
		if (step < 9)
			step = 1;
		else if (step < 99)
			step = 10;
		else if (step < 999)
			step = 100;
		else if (step < 9999)
			step = 1000;
		else
			step = 10000;

		int start = (nMinFreq + step - 1) / step * step;
		float fSpanFreq = nMaxFreq - nMinFreq;
		for (nFreq = start; nFreq <= nMaxFreq; nFreq += step) {
			x = _nScaleLeft + (int)((nFreq - nMinFreq) * _nScaleWidth / fSpanFreq);

			if (x > _nScaleLeft && x < _nScaleRight) {
				DrawLine(context, x, _nScaleTop + 1, x, _nScaleBottom - 1, _colorGray);
			}

			if (nFreq < 1000)
				sText = [NSString stringWithFormat:@"%d", nFreq];
			else
				sText = [NSString stringWithFormat:@"%dk", nFreq / 1000];
			size = [sText sizeWithAttributes:_fontAttrs];
			DrawString(sText, x - size.width / 2, _nScaleBottom + 1, _fontAttrs);
		}
	}

	int step = ((nMaxLevel - nMinLevel) / 120 + 1) * 10;
	float fSpanLevel = nMaxLevel - nMinLevel;
	for (nLevel = nMaxLevel; nLevel >= nMinLevel; nLevel -= step) {
		y = _nScaleBottom - (int)((nLevel - nMinLevel) * _nScaleHeight / fSpanLevel);

		if (y > _nScaleTop && y < _nScaleBottom) {
			DrawLine(context, _nScaleLeft, y, _nScaleRight, y, _colorGray);
		}

		sText = [NSString stringWithFormat:@"%d", nLevel];
		size = [sText sizeWithAttributes:_fontAttrs];
		DrawString(sText, _nScaleLeft - size.width - 3, y - size.height / 2, _fontAttrs);
	}

	sText = NSLocalizedString(@"IDS_FREQUENCY", nil);
	sText = [sText stringByAppendingString:@" [Hz]"];
	size = [sText sizeWithAttributes:_fontAttrs];
	DrawString(sText, _nScaleLeft + (_nScaleWidth - size.width) / 2, _nHeight - size.height - 4, _fontAttrs);

	sText = NSLocalizedString(@"IDS_LEVEL", nil);
	sText = [sText stringByAppendingString:@" [dB]"];
	size = [sText sizeWithAttributes:_fontAttrs];
	DrawRotateString(context, sText, 4, (_nScaleHeight - size.width) / 2 - _nScaleBottom, _fontAttrs);
}

- (void)dispGraph:(CGContextRef)context :(const float *)pFreqData :(int)nData :(float)fRate :(int)nMinFreq :(int)nMaxFreq :(int)nMinLevel :(int)nMaxLevel :(BOOL)bMean;
{
	int nScale = 0;
	float fMaxFreqLog = log((float)nMaxFreq);
	float fMinFreqLog = log((float)nMinFreq);
	int i;
	int x, x2 = 0;
	int y, y2 = 0;
	int n = 0;

	[self drawScale:context :nScale :nMinFreq :nMaxFreq :nMinLevel :nMaxLevel];

	CGContextClipToRect(context, CGRectMake(_nScaleLeft, _nScaleTop, _nScaleWidth, _nScaleHeight));

	float fFreqStep = (float)fRate / nData;
	float fStepY = (float)_nScaleHeight / (nMinLevel - nMaxLevel);
	float fTmp1 = (float)_nScaleWidth / (fMaxFreqLog - fMinFreqLog);
	float fTmp2 = (float)_nScaleWidth / (nMaxFreq - nMinFreq);

	CGPoint *points = new CGPoint[nData];

	if (bMean) {
		float fLevel= 0;
		int nCount = 0;
		BOOL bFirst = YES;
		for (i = 1; i < nData / 2; i++) {
			if (nScale == 0)
				x = _nScaleLeft + (int)((log(i * fFreqStep) - fMinFreqLog) * fTmp1 + 0.5);
			else
				x = _nScaleLeft + (int)((i * fFreqStep - nMinFreq) * fTmp2 + 0.5);

			if (i == 1)
				x2 = x;

			if (x != x2) {
				fLevel /= nCount;
				if (fLevel != 0)
					y = _nScaleTop + (int)((log10(fLevel) * 10 - nMaxLevel) * fStepY + 0.5);
				else
					y = _nScaleBottom;
				if (bFirst) {
					points[n++] = CGPointMake(x2, y);
					bFirst = NO;
				}
				points[n++] = CGPointMake(x2, y);
				x2 = x;
				fLevel = 0;
				nCount = 0;
			}

			fLevel += pFreqData[i];
			nCount++;
		}
	} else {
		for (i = 1; i < nData / 2; i++) {
			if (nScale == 0)
				x = _nScaleLeft + (int)((log(i * fFreqStep) - fMinFreqLog) * fTmp1 + 0.5);
			else
				x = _nScaleLeft + (int)((i * fFreqStep - nMinFreq) * fTmp2 + 0.5);

			if (pFreqData[i] != 0)
				y = _nScaleTop + (int)((log10(pFreqData[i]) * 10 - nMaxLevel) * fStepY + 0.5);
			else
				y = _nScaleBottom;

			if (i == 1)
				points[n++] = CGPointMake(x, y);
			else {
				if (x != x2 || y != y2)
					points[n++] = CGPointMake(x, y);
			}
			x2 = x;
			y2 = y;
		}
	}

	DrawPolyline(context, points, n, _colorFreq);

	delete [] points;
}

@end
