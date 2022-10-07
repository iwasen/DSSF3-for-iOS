//
//  PrefView.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/10.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "PrefView.h"
#import "Common.h"
#import "RemarkView.h"
#import "DrawView.h"

@implementation PrefView
{
    UIColor *_colorData, *_colorTauE, *_colorS;
    UIColor *_colorBlack, *_colorGray, *_colorLightGray;
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

- (void)initialize
{
	_colorData = [[UIColor alloc] RGB(255, 0, 0)];
	_colorTauE = [[UIColor alloc] RGB(0, 0, 255)];
	_colorS = [[UIColor alloc] RGB(255, 0, 255)];
	_colorBlack = [[UIColor alloc] RGB(0, 0, 0)];
	_colorGray = [[UIColor alloc] RGB(128, 128, 128)];
	_colorLightGray = [[UIColor alloc] RGB(192, 192, 192)];

	_fontAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
				  [UIFont systemFontOfSize:AdjustFontSize(17.0)], NSFontAttributeName,
				  _colorBlack, NSForegroundColorAttributeName,
				  nil];

	_remark.nRemark = 3;
	_remark.remarks[0].color = _colorData;
	_remark.remarks[0].text = NSLocalizedString(@"IDS_TAUEPREF", nil);
	_remark.remarks[1].color = _colorTauE;
	_remark.remarks[1].dash = YES;
	_remark.remarks[1].text = NSLocalizedString(@"IDS_OPTIMUMTAUE", nil);
	_remark.remarks[2].color = _colorS;
	_remark.remarks[2].dash = YES;
	_remark.remarks[2].text = NSLocalizedString(@"IDS_MAXPREF", nil);

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

	[_remarkView dispRemarks:&_remark :14: self];
}

- (void)drawScale:(CGContextRef)context :(int)minS :(int)maxTe
{
	int	t, s;
	int x, y;
	NSString *text;
	CGSize size;
	UIColor *color;

	DrawFillRect(context, _nScaleLeft, _nScaleTop, _nScaleWidth, _nScaleHeight, [UIColor whiteColor]);

	for (t = 0; t <= maxTe; t += 10) {
		if (t % 20 == 0)
			color = _colorGray;
		else
			color = _colorLightGray;

		x = _nScaleLeft + t * _nScaleWidth / maxTe;
		DrawLine(context, x, _nScaleTop, x, _nScaleBottom, color);

		if (t % 20 == 0) {
			text = [NSString stringWithFormat:@"%d", t];
			size = [text sizeWithAttributes:_fontAttrs];
			DrawString(text, x - size.width / 2, _nScaleBottom + 1, _fontAttrs);
		}
	}

	for (s = 0; s >= minS * 2; s--) {
		if (s % 2 == 0)
			color = _colorGray;
		else
			color = _colorLightGray;

		y = _nScaleTop + s * _nScaleHeight / minS / 2;
		DrawLine(context, _nScaleLeft, y, _nScaleRight, y, color);

		if (s % 2 == 0) {
			text = [NSString stringWithFormat:@"%d", s / 2];
			size = [text sizeWithAttributes:_fontAttrs];
			DrawString(text, _nScaleLeft - size.width - 3, y - size.height / 2, _fontAttrs);
		}
	}

	DrawRectangle(context, _nScaleLeft, _nScaleTop, _nScaleRight, _nScaleBottom, _colorBlack);

	text = NSLocalizedString(@"IDS_TAUE", nil);
	text = [text stringByAppendingString:@" [ms]"];
	size = [text sizeWithAttributes:_fontAttrs];
	DrawString(text, _nScaleLeft + (_nScaleWidth - size.width) / 2, _nHeight - size.height - 4, _fontAttrs);

	text = NSLocalizedString(@"IDS_PREFVALUE", nil);
	size = [text sizeWithAttributes:_fontAttrs];
	DrawRotateString(context, text, 4, (_nScaleHeight - size.width) / 2 - _nScaleBottom, _fontAttrs);
}

#define MIN_S	-10
- (void)dispGraph:(CGContextRef)context :(const float *)pData :(int)nData :(float)maxTauE :(float)maxS
{
	int i;
	int x, y;

	[self drawScale:context :MIN_S :nData];

	CGContextClipToRect(context, CGRectMake(_nScaleLeft, _nScaleTop, _nScaleWidth, _nScaleHeight));

	CGFloat len[] = {5, 5};
	CGContextSetLineDash(context, 0, len, 2);

	x = _nScaleLeft + (int)(maxTauE * _nScaleWidth / nData + 0.5);
	DrawLine(context, x, _nScaleTop, x, _nScaleBottom, _colorTauE);

	y = _nScaleTop + (int)(maxS * _nScaleHeight / MIN_S + 0.5);
	DrawLine(context, _nScaleLeft, y, _nScaleRight, y, _colorS);

	CGContextSetLineDash(context, 0, nil, 0);

	CGPoint *points = new CGPoint[nData];

	for (i = 0; i < nData; i++) {
		x = _nScaleLeft + (i + 1) * _nScaleWidth / nData;
		y = _nScaleTop + (int)(pData[i] * _nScaleHeight / MIN_S + 0.5);

		points[i] = CGPointMake(x, y);
	}

	DrawPolyline(context, points, i, _colorData);
}

@end
