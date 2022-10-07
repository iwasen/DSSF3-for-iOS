//
//  ParamView.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/11.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "ParamView.h"
#import "Common.h"
#import "RemarkView.h"
#import "DrawView.h"
#import "Calc.h"

#define COLOR_ALL	RGB(224, 0, 255)
#define COLOR_LEFT	RGB(0, 0, 255)
#define COLOR_RIGHT	RGB(255, 0, 0)

@implementation ParamView
{
    UIColor *_colorAll, *_colorLeft, *_colorRight;
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

- (void)initialize
{
	_colorAll = [[UIColor alloc] COLOR_ALL];
	_colorLeft = [[UIColor alloc] COLOR_LEFT];
	_colorRight = [[UIColor alloc] COLOR_RIGHT];
	_colorBlack = [[UIColor alloc] RGB(0, 0, 0)];
	_colorGray = [[UIColor alloc] RGB(128, 128, 128)];

	_fontAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
				  [UIFont systemFontOfSize:AdjustFontSize(17.0)], NSFontAttributeName,
				  _colorBlack, NSForegroundColorAttributeName,
				  nil];

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

- (void)drawScale:(CGContextRef)context :(const int *)pDataFreq :(int)nFreqBand :(int)nData :(float)scaleMin :(float)scaleMax :(float)scaleStep :(NSString *)vAxis
{
	int	i;
	int x, y;
	float a;
	NSString *text;
	CGSize size;
	int nLine = (nData > 16) ? 2 : 1;

	//_nScaleBottom = _nHeight - 70;

	DrawFillRect(context, _nScaleLeft, _nScaleTop, _nScaleWidth, _nScaleHeight, [UIColor whiteColor]);

	for (i = 0; i < nData; i++) {
		x = _nScaleLeft + (i + 1) * _nScaleWidth / (nData + 1);
		DrawLine(context, x, _nScaleTop, x, _nScaleBottom, _colorGray);

		text = GetDispFreq(pDataFreq[i], nFreqBand, TRUE);
		size = [text sizeWithAttributes:_fontAttrs];
		DrawString(text, x - size.width / 2, _nScaleBottom + (i % nLine) * size.height + nLine, _fontAttrs);
	}

	for (a = scaleMin; a <= scaleMax; a += scaleStep) {
		y = _nScaleBottom - (int)((a - scaleMin) * _nScaleHeight / (scaleMax - scaleMin) + 0.5);
		DrawLine(context, _nScaleLeft, y, _nScaleRight, y, _colorGray);

		if (scaleStep >= 1.0)
			text = [NSString stringWithFormat:@"%g", a];
		else
			text = [NSString stringWithFormat:@"%.1lf", a];
		size = [text sizeWithAttributes:_fontAttrs];
		DrawString(text, _nScaleLeft - size.width - 3, y - size.height / 2, _fontAttrs);
	}

	DrawRectangle(context, _nScaleLeft, _nScaleTop, _nScaleRight, _nScaleBottom, _colorBlack);

	text = NSLocalizedString(@"IDS_FREQUENCY", nil);
	text = [text stringByAppendingString:@" [Hz]"];
	size = [text sizeWithAttributes:_fontAttrs];
	DrawString(text, _nScaleLeft + (_nScaleWidth - size.width) / 2, _nHeight - size.height - 4, _fontAttrs);

	text = vAxis;
	size = [text sizeWithAttributes:_fontAttrs];
	DrawRotateString(context, text, 4, (_nScaleHeight - size.width) / 2 - _nScaleBottom, _fontAttrs);
}

- (void)dispGraph:(CGContextRef)context :(const int *)pDataFreq :(int)nFreqBand :(const float *)pDataAll :(const float *)pDataLeft :(const float *)pDataRight :(int)nData :(float)scaleMin :(float)scaleMax :(float)scaleStep :(NSString *)vAxis
{
	[self drawScale:context :pDataFreq :nFreqBand :nData :scaleMin :scaleMax :scaleStep :vAxis];

	CGContextClipToRect(context, CGRectMake(_nScaleLeft, _nScaleTop, _nScaleWidth, _nScaleHeight));

	if (pDataLeft != NULL)
		[self dispGraphSub:context :pDataFreq :pDataLeft :nData :scaleMin :scaleMax :1];

	if (pDataRight != NULL)
		[self dispGraphSub:context :pDataFreq : pDataRight :nData :scaleMin :scaleMax :2];

	if (pDataAll != NULL)
		[self dispGraphSub:context :pDataFreq :pDataAll :nData :scaleMin :scaleMax :0];
}

- (void)dispGraphSub:(CGContextRef)context :(const int *)pDataFreq :(const float *)pData :(int)nData :(float)scaleMin :(float)scaleMax :(int)channel
{
	int i;
	int x, y;
	CGPoint triangle[4];
	UIColor *color;

	CGPoint *points = new CGPoint[nData];
	int n = 0;

	for (i = 0; i < nData; i++) {
		x = _nScaleLeft + (i + 1) * _nScaleWidth / (nData + 1);
		y = _nScaleBottom - (int)((pData[i] - scaleMin) * _nScaleHeight / (scaleMax - scaleMin) + 0.5);

		switch (channel) {
			case 0:
				color = _colorAll;
				DrawFillEllipse(context, x - 2, y - 2, x + 3, y + 3, color);
				break;
			case 1:
				color = _colorLeft;
				DrawFillRect(context, x - 2, y - 2, 5, 5, color);
				break;
			case 2:
				color = _colorRight;
				triangle[0].x = x - 2;
				triangle[0].y = y + 2;
				triangle[1].x = x;
				triangle[1].y = y - 2;
				triangle[2].x = x + 2;
				triangle[2].y = y + 2;
				triangle[3].x = x - 2;
				triangle[3].y = y + 2;
				DrawPolygon(context, triangle, 4, color, color);
				break;
		}

		if (pDataFreq[i] > 0) {
			points[n++] = CGPointMake(x, y);
		}
	}

	DrawPolyline(context, points, n, color);

	delete [] points;
}

- (void)dispRemark:(NSString *)title :(int)nRemark
{
	_remark.remarks[0].color = NULL;
	_remark.remarks[0].text = title;

	_remark.nRemark = nRemark;
	_remark.remarks[1].color = _colorAll;
	_remark.remarks[1].text = NSLocalizedString(@"IDS_LRAVERAGE", nil);
	_remark.remarks[2].color = _colorLeft;
	_remark.remarks[2].text = NSLocalizedString(@"IDS_LEFTCHANNEL", nil);
	_remark.remarks[3].color = _colorRight;
	_remark.remarks[3].text = NSLocalizedString(@"IDS_RIGHTCHANNEL", nil);
	
	[_remarkView dispRemarks:&_remark :14 :self];
}

@end
