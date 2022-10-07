//
//  DstManualGraphView.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/11.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "DstManualGraphView.h"
#import "Common.h"
#import "DrawView.h"

@implementation DstManualGraphView
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
    UIImage *_imageLeft;
    UIImage *_imageRight;
    UIImage *_imageLeftTotal;
    UIImage *_imageRightTotal;
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
		CGContextSetLineWidth(context, 1.0);

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

	_imageLeft = [UIImage imageNamed:@"OctLeft.png"];
	_imageRight = [UIImage imageNamed:@"OctRight.png"];
	_imageLeftTotal = [UIImage imageNamed:@"OctPeakLeft.png"];
	_imageRightTotal = [UIImage imageNamed:@"OctPeakRight.png"];

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

- (void)drawScale:(CGContextRef)context :(int)nMaxHarmonics
{
	int y;
	int i;
	CGSize size;
	NSString *sText;
	float fStep;
	float fPos;
	float fTHD;
	int nTHD;
	NSString *sUnit;
	UIColor *color;

	DrawFillRect(context, _nScaleLeft, _nScaleTop, _nScaleWidth, _nScaleHeight, [UIColor whiteColor]);

	int nData = nMaxHarmonics;
	fStep = (float)_nScaleWidth / nData;
	fPos = _nScaleLeft + fStep / 2;
	for (i = 0; i < nData; i++) {
		if (i == 0)
			sText = @"THD";
		else
			sText = [NSString stringWithFormat:@"%d", i + 1];

		size = [sText sizeWithAttributes:_fontAttrs];
		DrawString(sText, fPos - size.width / 2, _nScaleBottom + 3, _fontAttrs);

		fPos += fStep;
	}

	sText = NSLocalizedString(@"IDS_HARMONICS", nil);
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

- (void)drawData:(CGContextRef)context :(const float *)pLeftDst :(const float *)pRightDst :(int)nChannel :(int)nMaxHarmonics
{
	int i;
	float xPos;
	int xWidth;
	float xStep = (float)_nScaleWidth / nMaxHarmonics;
	float yStep = (float)_nScaleHeight / (g_oSetData.Dst.nScaleMin - g_oSetData.Dst.nScaleMax);
	CGFloat top, left, right, bottom;
	UIImage *image;

	if (nChannel != 0)
		xWidth = (int)(xStep / 2.5);
	else
		xWidth = (int)(xStep / 1.4);

	xPos = xStep / 2;

	if (nChannel == 0)
		xPos -= xWidth / 2;
	else
		xPos -= xWidth;

	if (pLeftDst != NULL) {
		for (i = 0; i < nMaxHarmonics; i++) {
			if (pLeftDst[i] != 0) {
				left = (int)xPos;
				top = (int)((dB10(pLeftDst[i]) - g_oSetData.Dst.nScaleMax) * yStep + 0.5);
				right = left + xWidth;
				bottom = _nScaleHeight;

				if (top < 0)
					top = 0;

				if (i == 0) {
					image = _imageLeftTotal;
				} else {
					image = _imageLeft;
				}

				if (top < bottom) {
					[image drawInRect:CGRectMake(left, top, right - left, bottom - top)];
					DrawLine(context, left, top, right, top, _colorLeft);
				}
			}

			xPos += xStep;
		}
	}

	if (pRightDst != NULL) {
		xPos = xStep / 2;

		for (i = 0; i < nMaxHarmonics; i++) {
			if (pRightDst[i] != 0) {
				left = (int)xPos;
				top = (int)((dB10(pRightDst[i]) - g_oSetData.Dst.nScaleMax) * yStep + 0.5);
				right = left + xWidth;
				bottom = _nScaleHeight;

				if (top < 0)
					top = 0;

				if (i == 0) {
					image = _imageRightTotal;
				} else {
					image = _imageRight;
				}

				if (top < bottom) {
					[image drawInRect:CGRectMake(left, top, right - left, bottom - top)];
					DrawLine(context, left, top, right, top, _colorRight);
				}
			}

			xPos += xStep;
		}
	}
}

@end
