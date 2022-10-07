//
//  FftGraphCrf.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/23.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "FftViewController.h"

@implementation FftViewController (Crf)

- (void)initCrf
{
    _nFrameLeft = 75 * _sizeGraphView.width / 768;
    _nFrameTop = 10;
    _nFrameRight = _sizeGraphView.width - 15;
    _nFrameBottom = _sizeGraphView.height - (55 * _sizeGraphView.width / 768);
    _nFrameWidth = _nFrameRight - _nFrameLeft;
    _nFrameHeight = _nFrameBottom - _nFrameTop;
    
    _nCrfRange = g_oSetData.Fft.nCrfZoom * CRF_RANGE;
    
    if (_nViewMode != VM_SPLIT) {
        _nScaleWidth = _nFrameWidth;
        _nScaleHeight = _nFrameHeight;
    } else {
        _nScaleWidth = _nFrameWidth;
        _nScaleHeight = _nFrameHeight / 2 - _sizeGraphView.height / 50;
    }
    
    for (int i = 0; i < 2; i++) {
        FFTDATA &oFftData = _aFftData[i];
        
        if (oFftData._pCrfPoint == NULL)
            oFftData._pCrfPoint = new CGPoint[(_nFftSize / _nCrfRange + 1) * 2];
        
        oFftData._nCrfPointCount = 0;
    }
}

- (void)drawScaleCrf:(CGRect)frame
{
    if (_nViewMode != VM_SPLIT) {
        [self drawScaleCrfSub:_nFrameLeft :_nFrameTop :_nFrameRight :_nFrameBottom :YES :_nChannel == CH_STEREO ? @"Lch / Rch" : NULL];
    } else {
        [self drawScaleCrfSub:_nFrameLeft :_nFrameTop :_nFrameRight :_nFrameTop + _nScaleHeight :NO :@"Lch"];
        [self drawScaleCrfSub:_nFrameLeft :_nFrameBottom - _nScaleHeight :_nFrameRight :_nFrameBottom :YES :@"Rch"];
    }
}

- (void)drawScaleCrfSub:(int)nLeft :(int)nTop :(int)nRight :(int)nBottom :(bool)bAxisX :(NSString *)pText
{
    NSString *sText;
    CGSize size;
    int ns;
    float step, t1, t2;
    CGFloat y;
    int i;
    int nWidth = nRight - nLeft;
    int nHeight = nBottom - nTop;
    int nCenter = nTop + _nScaleHeight / 2;
    UIColor *color;
    
    CGContextRef context = UIGraphicsGetCurrentContext();

    DrawFillRect(context, nLeft, nTop, nWidth, nHeight, _colorWhite);
    DrawRectangle(context, nLeft - 1, nTop - 1, nRight + 1, nBottom + 1, _colorBlack);
    
    for (i = 100; i >= -100; i -= 20) {
        y = nCenter - (i * ((float)_nScaleHeight / 2) / 100);
        if (i != 100 && i != -100) {
            if (i == 0)
                color = _colorBlack;
            else
                color = _colorLightGray;
            
            DrawLine(context, nLeft, y, nRight, y, color);
        }
        
        sText = [NSString stringWithFormat:@"%g", (float)i / 100];
        size = [sText sizeWithAttributes:_fontAttrs];
        DrawString(sText, nLeft - size.width - 5, y - size.height / 2, _fontAttrs);
    }
    
    if (g_oSetData.Fft.nCorrelation == 0)
        t1 = _fTimeStep / (10 * _nCrfRange);
    else
        t1 = _fTimeStep / (5 * _nCrfRange);
    t1 *= 1000.0 / _nScaleWidth;
    
    step = pow(10.0, floor(log10(t1)));
    t2 = t1 / step;
    if (t2 < 3) {
        step *= 0.5;
        ns = 2;
    } else if (t2 < 5)
        ns = 2;
    else
        ns = 5;
    
    if (g_oSetData.Fft.nCorrelation == 0)
        [self drawScaleCrfSub2:context :nLeft :nTop :nRight :nBottom :bAxisX :step :nLeft :_nScaleWidth :1 :ns];
    else {
        [self drawScaleCrfSub2:context :nLeft :nTop :nRight :nBottom :bAxisX :step :nLeft + _nScaleWidth / 2 :_nScaleWidth / 2 :1 :ns];
        [self drawScaleCrfSub2:context :nLeft :nTop :nRight :nBottom :bAxisX :step :nLeft + _nScaleWidth / 2 :_nScaleWidth / 2 :-1 :ns];
    }
    
    if (bAxisX) {
        sText = NSLocalizedString(@"IDS_TAU", nil);
        sText = [sText stringByAppendingString:@" [ms]"];
        size = [sText sizeWithAttributes:_fontAttrs];
        DrawString(sText, nLeft + (_nScaleWidth - size.width) / 2, _sizeGraphView.height - size.height - 4, _fontAttrs);
    }
    
    sText = NSLocalizedString(@"IDS_CORRELATION", nil);
    size = [sText sizeWithAttributes:_fontAttrs];
    DrawRotateString(context, sText, 4, (nHeight - size.width) / 2 - nBottom, _fontAttrs);
    
    if (g_oSetData.Fft.nCorrelation == 0)
        [self drawNote:pText :nTop :nRight];
}

- (void)drawScaleCrfSub2:(CGContextRef) context :(int)nLeft :(int)nTop :(int)nRight :(int)nBottom :(BOOL)bAxisX :(float)step :(int)zero :(int)width :(int)dir :(int)ns
{
    float t;
    CGFloat x;
    NSString *sText;
    CGSize size;
    float fTime = _fTimeStep / _nCrfRange;
    UIColor *color;
    int i;
    
    for (t = 0, i = 0; t < fTime; i++, t = i * step) {
        x = zero + (t * width / fTime) * dir;
        if (x >= nLeft && x <= nRight) {
            if (int(t / step + 0.5) % ns == 0) {
                if (x > nLeft) {
                    if (t == 0)
                        color = _colorBlack;
                    else
                        color = _colorGray;
                    DrawLine(context, x, nTop, x, nBottom, color);
                }
                
                if (bAxisX) {
                    sText = [NSString stringWithFormat:@"%g", (t == 0) ? 0 : t * 1000 * dir];
                    size = [sText sizeWithAttributes:_fontAttrs];
                    //_dcMem.TextOut(x - size.cx / 2, nBottom + 2, sText);
                    DrawString(sText, x - size.width / 2, nBottom + 3, _fontAttrs);
                }
            } else {
                if (x > nLeft) {
                    DrawLine(context, x, nTop, x, nBottom, _colorLightGray);
                }
            }
        }
    }
}

- (void)setDispDataCrf
{
    if (g_oSetData.Fft.nCorrelation != 0) {
        // 相互相関
        [self calcLateralCorrelation:_pCrossBufRe :_pCrossBufIm];
        [self calcCrf:&_aFftData[0] :_nFftSize - _nFftSize / _nCrfRange :_nFftSize * 2 / _nCrfRange];
        _aFftData[1]._nCrfPointCount = 0;
    } else {
        // 自己相関
        if (_bLch) {
            [self calcAutoCorrelation:_aFftData[0]._pPowerSpecBuf :_aFftData[0]._pCrfBuf];
            [self calcCrf:&_aFftData[0] :0 :_nFftSize / _nCrfRange];
        }
        
        if (_bRch) {
            [self calcAutoCorrelation:_aFftData[1]._pPowerSpecBuf :_aFftData[1]._pCrfBuf];
            [self calcCrf:&_aFftData[1] :0 :_nFftSize / _nCrfRange];
        }
    }
    
    [self dispCrfInfo];
}

- (void)calcAutoCorrelation:(const float *)pFftBuf :(float *)pCrfBuf
{
    int i, j;
    int nFftSize2 = _nFftSize / 2;
    
    pCrfBuf[0] = pCrfBuf[1] = 0;
    
    for (i = 1; i < nFftSize2; i++) {
        j = i * 2;
        
        pCrfBuf[j] = pFftBuf[i];
        pCrfBuf[j + 1] = 0;
    }
    
    _oFFT.ifft(_nFftSize, pCrfBuf);
    
    float f0 = 1 / pCrfBuf[0];
    for (i = 0; i < nFftSize2; i++)
        pCrfBuf[i] *= f0;
}

- (void)calcLateralCorrelation:(float *)pFftBufRe :(float *)pFftBufIm
{
    int i, j;
    int nFftSize2 = _nFftSize / 2;
    float *pCrfBuf = _aFftData[0]._pCrfBuf;
    
    pCrfBuf[0] = pCrfBuf[1] = 0;
    
    for (i = 1; i < nFftSize2; i++) {
        j = i * 2;
        
        pCrfBuf[j] = pFftBufRe[i];
        pCrfBuf[j + 1] = pFftBufIm[i];
    }
    
    _oFFT.ifft(_nFftSize, pCrfBuf);
    
    float f0 = 0;
    for (i = 0; i < nFftSize2; i++) {
        f0 += _aFftData[0]._pPowerSpecBuf[i];
        f0 += _aFftData[1]._pPowerSpecBuf[i];
    }
    f0 = 2 / f0;
    
    for (i = 0; i < _nFftSize; i++)
        pCrfBuf[i] *= f0;
}

- (void)calcCrf:(FFTDATA *)pFftData :(int)nOffset :(int)nDataSize
{
    int i;
    CGPoint *pPoint = pFftData->_pCrfPoint;
    int x, y;
    int x2 = -1, y2 = 0;
    int nPointCount = 0;
    int nIndex;
    int nCenter = _nScaleHeight / 2;
    float *pCrfBuf = pFftData->_pCrfBuf;
    
    for (i = 0; ; i++) {
        x = (i * _nScaleWidth + nDataSize / 2) / nDataSize;
        
        nIndex = nOffset + i;
        if (nIndex >= _nFftSize)
            nIndex -= _nFftSize;
        y = (int)(nCenter - pCrfBuf[nIndex] * _nScaleHeight / 2 + 0.5);
        
        if (x != x2 || y != y2) {
            pPoint[nPointCount].x = x;
            pPoint[nPointCount].y = y;
            nPointCount++;
            
            if (x >= _nScaleWidth)
                break;
            
            x2 = x;
            y2 = y;
        }
    }
    
    pFftData->_nCrfPointCount = nPointCount;
}

- (void)drawDataCrf:(CGContextRef)context :(int)nChannel
{
    if (nChannel == 0) {
        if (_aFftData[0]._nCrfPointCount != 0) {
            if (g_oSetData.Fft.nCorrelation == 0)
                [self drawDataCrfSub:context :&_aFftData[0] :0 :_colorLeft :_colorLeftLine :_colorLeftPeak];
            else
                [self drawDataCrfSub:context :&_aFftData[0] :0 :_colorGreen :_colorLightGreen :_colorGreen];
        }
    } else {
        if (_aFftData[1]._nCrfPointCount != 0)
            [self drawDataCrfSub:context :&_aFftData[1] :_nViewMode == VM_OVERLAY ? 1 : 0 :_colorRight :_colorRightLine :_colorRightPeak];
    }
}

- (void)drawDataCrfSub:(CGContextRef)context :(FFTDATA *)pFftData :(int)nOffest :(UIColor *)colorData :(UIColor *)colorLine :(UIColor *)colorPeak
{
    int nCenter = _nScaleHeight / 2;
    int i, j, y;
    int dx, dy;
    
    DrawPolyline(context, pFftData->_pCrfPoint, pFftData->_nCrfPointCount, colorData);

    CGPoint *points = new CGPoint[_nScaleWidth];
    for (i = nOffest, j = 0; i < _nScaleWidth; i += 2) {
        while (pFftData->_pCrfPoint[j].x < i)
            j++;
        if (pFftData->_pCrfPoint[j].x == i)
            y = pFftData->_pCrfPoint[j].y;
        else {
            dx = pFftData->_pCrfPoint[j].x - pFftData->_pCrfPoint[j - 1].x;
            dy = pFftData->_pCrfPoint[j].y - pFftData->_pCrfPoint[j - 1].y;
            y = pFftData->_pCrfPoint[j].y - dy * (pFftData->_pCrfPoint[j].x - i) / dx;
        }
        points[i] = CGPointMake(i, nCenter);
        points[i + 1] = CGPointMake(i, y);
    }
    DrawLineSegments(context, points, _nScaleWidth, colorLine);
    delete [] points;
    
    if (pFftData->_nCrfDispTime != 0) {
        DrawLine(context, pFftData->_nCrfTimePos, 0, pFftData->_nCrfTimePos, _nScaleHeight, colorPeak);
        DrawLine(context, 0, pFftData->_nCrfLevelPos, _nScaleWidth, pFftData->_nCrfLevelPos, colorPeak);
    }
}

- (void)dispCrfInfo
{
    if (_bLch)
        [self dispCrfInfoSub:&_aFftData[0] :self.outletPeakFreqLeft :self.outletPeakLevelLeft];
    
    if (_bRch)
        [self dispCrfInfoSub:&_aFftData[1] :self.outletPeakFreqRight :self.outletPeakLevelRight];
}

- (void)dispCrfInfoSub:(FFTDATA *)pFftData :(CtTextField *)freqTextField :(CtTextField *)levelTextField
{
    float *pCrfBuf = pFftData->_pCrfBuf;
    int nDataSize = (g_oSetData.Fft.nCorrelation == 0) ? _nFftSize / _nCrfRange : _nFftSize * 2 / _nCrfRange;
    int nCrfDispTime = (g_oSetData.Fft.nCorrelation == 0) ? pFftData->_nCrfDispTime : pFftData->_nCrfDispTime - nDataSize / 2;
    int nIndex = (nCrfDispTime + _nFftSize) % _nFftSize;
    
    pFftData->_nCrfTimePos = (pFftData->_nCrfDispTime * _nScaleWidth) / nDataSize;
    pFftData->_nCrfLevelPos = (int)((_nScaleHeight / 2) - pCrfBuf[nIndex] * _nScaleHeight / 2 + 0.5);
    
    if (pFftData->_nCrfDispTime == 0) {
        levelTextField.text = @"";
        freqTextField.text = @"";
    } else {
        levelTextField.text = [NSString stringWithFormat:@"%.2lf", pCrfBuf[nIndex]];
        freqTextField.text = [NSString stringWithFormat:@"%.1lf",  1000.0 * nCrfDispTime / _nSamplingRate];
    }
}

- (void)setDispFreqCrf:(CGPoint)point
{
    if (!g_oSetData.Fft.bPeakDisp) {
        int n;
        int nDataSize = (g_oSetData.Fft.nCorrelation == 0) ? _nFftSize / _nCrfRange : _nFftSize * 2 / _nCrfRange;
        
        n = (point.x - _nFrameLeft) * nDataSize / _nScaleWidth;
        _aFftData[0]._nCrfDispTime = _aFftData[1]._nCrfDispTime = (n > 1 && n < nDataSize) ? n : 0;
        [self dispCrfInfo];
        [_viewFftScale setNeedsDisplay];
    }
}

- (void)resetDispFreqCrf
{
    if (!g_oSetData.Fft.bPeakDisp) {
        _aFftData[0]._nCrfDispTime = _aFftData[1]._nCrfDispTime = 0;
        [self dispCrfInfo];
        [_viewFftScale setNeedsDisplay];
    }
}

@end
