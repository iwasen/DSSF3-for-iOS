//
//  MtfView.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/12.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "MtfView.h"
#import "Common.h"
#import "RemarkView.h"
#import "DrawView.h"
#import "Calc.h"

#define MIN_FREQ	0.5
#define MAX_FREQ	15

@implementation MtfView
{
    int _nScaleCenter;
    UIColor *_colorMtf;
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

- (void)initialize:(NSString *)title :(int)nRemark :(UIColor *)color
{
	_colorMtf = color;
	_colorBlack = [[UIColor alloc] RGB(0, 0, 0)];
	_colorGray = [[UIColor alloc] RGB(128, 128, 128)];

	_fontAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
				  [UIFont systemFontOfSize:AdjustFontSize(17.0)], NSFontAttributeName,
				  _colorBlack, NSForegroundColorAttributeName,
				  nil];

	if (title != NULL) {
		_remark.nRemark = nRemark;
		_remark.remarks[0].color = NULL;
		_remark.remarks[0].text = title;
		_remark.remarks[1].color = _colorMtf;

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

	[_remarkView dispRemarks:&_remark :14: self];
}

- (void)drawScale:(CGContextRef)context
{
	int	nFreq, nLevel;
	int x, y;
	NSString *text;
	CGSize size;

	DrawFillRect(context, _nScaleLeft, _nScaleTop, _nScaleWidth, _nScaleHeight, [UIColor whiteColor]);

	int minFreq = (int)(MIN_FREQ * 10);
	int maxFreq = (int)(MAX_FREQ * 10);
	float fMaxFreqLog = log((float)maxFreq);
	float fMinFreqLog = log((float)minFreq);
	for (nFreq = minFreq; nFreq <= maxFreq; ) {
		x =  (int)((log((float)nFreq) - fMinFreqLog) *
				   _nScaleWidth / (fMaxFreqLog - fMinFreqLog) + _nScaleLeft + 0.5);

		if (x > _nScaleLeft && x < _nScaleRight) {
			DrawLine(context, x, _nScaleTop, x, _nScaleBottom, _colorGray);
		}

		if (nFreq != minFreq) {
			text = [NSString stringWithFormat:@"%g", (float)nFreq / 10];
			if ([text characterAtIndex:0] == '0')
				text = [text substringFromIndex:1];
			size = [text sizeWithAttributes:_fontAttrs];
			DrawString(text, x - size.width / 2, _nScaleBottom + 1, _fontAttrs);
		}

		if (nFreq < 10)
			nFreq += 1;
		else if (nFreq < 100)
			nFreq += 10;
		else
			nFreq += 100;
	}

	for (nLevel = 0; nLevel <= 10; nLevel++) {
		y = _nScaleBottom - nLevel * _nScaleHeight / 10;

		if (y > _nScaleTop && y < _nScaleBottom) {
			DrawLine(context, _nScaleLeft, y, _nScaleRight, y, _colorGray);
		}

		text = [NSString stringWithFormat:@"%g", (float)nLevel / 10];
		size = [text sizeWithAttributes:_fontAttrs];
		DrawString(text, _nScaleLeft - size.width - 3, y - size.height / 2, _fontAttrs);
	}

	DrawRectangle(context, _nScaleLeft, _nScaleTop, _nScaleRight, _nScaleBottom, _colorBlack);

	text = NSLocalizedString(@"IDS_FREQUENCY", nil);
	text = [text stringByAppendingString:@" [Hz]"];
	size = [text sizeWithAttributes:_fontAttrs];
	DrawString(text, _nScaleLeft + (_nScaleWidth - size.width) / 2, _nHeight - size.height - 4, _fontAttrs);

	text = @"MTF";
	size = [text sizeWithAttributes:_fontAttrs];
	DrawRotateString(context, text, 4, (_nScaleHeight - size.width) / 2 - _nScaleBottom, _fontAttrs);
}

- (void)dispGraph:(CGContextRef)context :(const float *)pMtfData :(const float *)pMtfFreq
{
	float fMaxFreqLog = log((float)MAX_FREQ);
	float fMinFreqLog = log((float)MIN_FREQ);
	int i;
	int x, y;

	[self drawScale:context];

	float fTmp1 = (float)_nScaleWidth / (fMaxFreqLog - fMinFreqLog);

	CGPoint *points = new CGPoint[N_MTF_FREQ];

	for (i = 0; i < N_MTF_FREQ; i++) {
		x = _nScaleLeft + (int)((log(pMtfFreq[i]) - fMinFreqLog) * fTmp1 + 0.5);
		y = _nScaleBottom - (int)(pMtfData[i] * _nScaleHeight + 0.5);

		points[i] = CGPointMake(x, y);

		DrawFillEllipse(context, x - 2, y - 2, x + 3, y + 3, _colorMtf);
	}

	DrawPolyline(context, points, i, _colorMtf);

	delete [] points;
}

@end
