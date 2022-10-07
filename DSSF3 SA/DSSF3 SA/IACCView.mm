//
//  IACCView.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/06.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "IACCView.h"
#import "DrawView.h"
#import "Common.h"
#import "RemarkView.h"

@implementation IACCView
{
    int _nScaleVCenter, _nScaleHCenter;
    UIColor *_colorData;
    UIColor *_colorBlack, *_colorGray, *_colorLightGray;
    UIColor *_colorIACC, *_colorTIACC, *_colorWIACC;
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

- (void)initialize:(NSString *)title :(int)nRemark
{
	_colorBlack = [[UIColor alloc] RGB(0, 0, 0)];
	_colorGray = [[UIColor alloc] RGB(128, 128, 128)];
	_colorLightGray = [[UIColor alloc] RGB(192, 192, 192)];
	_colorData = [[UIColor alloc] RGB(255, 0, 0)];
	_colorIACC = [[UIColor alloc] RGB(255, 0, 255)];
	_colorTIACC = [[UIColor alloc] RGB(0, 0, 255)];
	_colorWIACC = [[UIColor alloc] RGB(0, 255, 0)];

	_fontAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
				  [UIFont systemFontOfSize:AdjustFontSize(17.0)], NSFontAttributeName,
				  _colorBlack, NSForegroundColorAttributeName,
				  nil];

	if (title != nil) {
		_remark.nRemark = nRemark;
		_remark.remarks[0].color = _colorData;
		_remark.remarks[0].text = title;
		_remark.remarks[1].color = _colorIACC;
		_remark.remarks[1].dash = YES;
		_remark.remarks[1].text = @"IACC";
		_remark.remarks[2].color = _colorTIACC;
		_remark.remarks[2].dash = YES;
		_remark.remarks[2].text = NSLocalizedString(@"IDS_TIACC", nil);
		_remark.remarks[3].color = _colorWIACC;
		_remark.remarks[3].dash = YES;
		_remark.remarks[3].text = @"W_IACC";

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
	_nScaleVCenter = _nScaleTop + _nScaleHeight / 2;
	_nScaleHCenter = _nScaleLeft + _nScaleWidth / 2;
}

- (void)drawScale:(CGContextRef)context
{
	int i;
	int x, y;
	NSString *text;
	CGSize size;
	UIColor *color;

	DrawFillRect(context, _nScaleLeft, _nScaleTop, _nScaleWidth, _nScaleHeight, [UIColor whiteColor]);

	for (i = -10; i <= 10; i++) {
		y = _nScaleVCenter - i * _nScaleHeight / 20;
		if (i == -10 || i == 0 || i == 10)
			color = _colorBlack;
		else if (i == -5 || i == 5)
			color = _colorGray;
		else
			color = _colorLightGray;

		DrawLine(context, _nScaleLeft, y, _nScaleRight, y, color);

		if (i % 2 == 0) {
			text = [NSString stringWithFormat:@"%g", (float)i / 10];
			size = [text sizeWithAttributes:_fontAttrs];
			DrawString(text, _nScaleLeft - size.width - 3, y - size.height / 2, _fontAttrs);
		}
	}

	for (i = -10; i <= 10; i++) {
		x = _nScaleHCenter + i * _nScaleWidth / 20;
		if (i == -10 || i == 0 || i == 10)
			color = _colorBlack;
		else if (i == -5 || i == 5)
			color = _colorGray;
		else
			color = _colorLightGray;

		DrawLine(context, x, _nScaleTop + 1, x, _nScaleBottom, color);

		if (i % 5 == 0) {
			text = [NSString stringWithFormat:@"%g", (float)i / 10];
			size = [text sizeWithAttributes:_fontAttrs];
			DrawString(text, x - size.width / 2, _nScaleBottom + 1, _fontAttrs);
		}
	}

	text = NSLocalizedString(@"IDS_TAU", nil);
	text = [text stringByAppendingString:@" [ms]"];
	size = [text sizeWithAttributes:_fontAttrs];
	DrawString(text, _nScaleLeft + (_nScaleWidth - size.width) / 2, _nHeight - size.height - 4, _fontAttrs);

	text = @"CCF";
	size = [text sizeWithAttributes:_fontAttrs];
	DrawRotateString(context, text, 4, (_nScaleHeight - size.width) / 2 - _nScaleBottom, _fontAttrs);
}

- (void)dispGraph:(CGContextRef)context :(const float *)pData :(int)nData :(float)fRate :(float)IACC :(float)TIACC :(float)WIACC1 :(float)WIACC2
{
	int i;
	CGFloat x, y;

	[self drawScale:context];

	if (pData == NULL)
		return;

	CGContextClipToRect (context, CGRectMake(_nScaleLeft, _nScaleTop, _nScaleWidth, _nScaleHeight));

	CGFloat len[] = {5, 5};
	CGContextSetLineDash(context, 0, len, 2);

	y = (int)(_nScaleVCenter - IACC * (_nScaleHeight / 2) + 0.5);
	DrawLine(context, _nScaleLeft, y, _nScaleRight, y, _colorIACC);

	x = (int)(_nScaleHCenter + TIACC * (_nScaleWidth / 2) + 0.5);
	DrawLine(context, x, _nScaleTop, x, _nScaleBottom, _colorTIACC);

	x = (int)(_nScaleHCenter + (TIACC - WIACC1) * (_nScaleWidth / 2) + 0.5);
	DrawLine(context, x, _nScaleTop, x, _nScaleBottom, _colorWIACC);
	x = (int)(_nScaleHCenter + (TIACC + WIACC2) * (_nScaleWidth / 2) + 0.5);
	DrawLine(context, x, _nScaleTop, x, _nScaleBottom, _colorWIACC);

	CGContextSetLineDash(context, 0, nil, 0);

	CGPoint *points = new CGPoint[nData];
	for (i = 0; i < nData; i++) {
		x = (int)(_nScaleHCenter + (i - nData / 2) * 1000 * (_nScaleWidth / 2) / fRate);
		y = (int)(_nScaleVCenter - pData[i] * _nScaleHeight / 2 + 0.5);

		points[i] = CGPointMake(x, y);
	}

	DrawPolyline(context, points, nData, _colorData);

	delete [] points;
}

@end
