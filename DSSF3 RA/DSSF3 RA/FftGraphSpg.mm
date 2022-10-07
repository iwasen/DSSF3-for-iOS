//
//  FftGraphSpg.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/24.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "FftViewController.h"

@implementation FftViewController (Spg)

- (void)initSpg
{
    _nFrameLeft = 75 * _sizeGraphView.width / 768;
    _nFrameTop = 10;
    _nFrameRight = _sizeGraphView.width - 62;
    _nFrameBottom = _sizeGraphView.height - (55 * _sizeGraphView.width / 768);
    _nFrameWidth = _nFrameRight - _nFrameLeft;
    _nFrameHeight = _nFrameBottom - _nFrameTop;
    
    if (_nViewMode != VM_SPLIT) {
        _nScaleWidth = _nFrameWidth;
        _nScaleHeight = _nFrameHeight;
    } else {
        _nScaleWidth = _nFrameWidth;
        _nScaleHeight = _nFrameHeight / 2 - _sizeGraphView.height / 50;
    }
    
	if (_pSpgLevel == NULL)
        _pSpgLevel = new float[_nScaleHeight];

    for (int i = 0; i < 2; i++) {
        _aFftData[i]._pSpgImage = nil;
    }
}

- (void)drawScaleSpg:(CGRect)frame
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    DrawFillRect(context, 0, 0, _sizeGraphView.width, _sizeGraphView.height, _colorScaleBg);

    if (_nViewMode != VM_SPLIT) {
        [self drawScaleSpgSub:_nFrameLeft :_nFrameTop :_nFrameRight :_nFrameBottom :YES :_nChannel == CH_STEREO ? @"Lch / Rch" : NULL];
    } else {
        [self drawScaleSpgSub:_nFrameLeft :_nFrameTop :_nFrameRight :_nFrameTop + _nScaleHeight :NO :@"Lch"];
        [self drawScaleSpgSub:_nFrameLeft :_nFrameBottom - _nScaleHeight :_nFrameRight :_nFrameBottom :YES :@"Rch"];
    }
    
    [self drawLevelScale:_nFrameLeft :_nFrameTop :_nFrameRight :_nFrameBottom];
}

- (void)drawScaleSpgSub:(int)nLeft :(int)nTop :(int)nRight :(int)nBottom :(BOOL)bAxisX :(NSString *)pText
{
    int	nFreq;
    int time;
    CGFloat x, y;
    int nWidth = nRight - nLeft;
    int nHeight = nBottom - nTop;
    NSString *sText;
    CGSize size;
    
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSaveGState( context );
    CGContextSetBlendMode(context, kCGBlendModeClear);
    DrawFillRect(context, nLeft, nTop, nWidth, nHeight, [UIColor clearColor]);
    CGContextRestoreGState( context );
    
    DrawRectangle(context, nLeft - 1, nTop - 1, nRight + 1, nBottom + 1, _colorBlack);
    
    for (time = 0; time <= g_oSetData.Fft.nTimeRange; time++) {
        x = nLeft + time * nWidth / (CGFloat)g_oSetData.Fft.nTimeRange;
        
        if (x > nLeft && x < nRight) {
            DrawLine(context, x, nTop, x, nBottom, _colorGray);
        }
        
        if (bAxisX) {
            sText = [NSString stringWithFormat:@"%d", time];
            size = [sText sizeWithAttributes:_fontAttrs];
            DrawString(sText, x - size.width / 2, nBottom + 3, _fontAttrs);
        }
    }
    
    if (g_oSetData.Fft.nFftScale == 0) {
        int step = GetLogScaleStep(_nMinFreq);
        float fSpanFreq = _fLogMaxFreq - _fLogMinFreq;
        for (nFreq = GetScaleStartValue(_nMinFreq, step); nFreq <= _nMaxFreq; nFreq += GetLogScaleStep(nFreq)) {
            y = nTop + ((_fLogMaxFreq - log((float)nFreq)) * nHeight / fSpanFreq);
            
            if (nFreq < 1000)
                sText = [NSString stringWithFormat:@"%d", nFreq];
            else
                sText = [NSString stringWithFormat:@"%gk", (float)nFreq / 1000];
            
            if ([sText characterAtIndex:0] == '1' || [sText characterAtIndex:0] == '2' || [sText characterAtIndex:0] == '5') {
                size = [sText sizeWithAttributes:_fontAttrs];
                DrawString(sText, nLeft - size.width - 5, y - size.height / 2, _fontAttrs);
            }
        }
    } else {
        int step = GetLinearScaleStep(_nMaxFreq, _nMinFreq, nHeight);
        float fSpanFreq = _nMaxFreq - _nMinFreq;
        for (nFreq = GetScaleStartValue(_nMinFreq, step); nFreq <= _nMaxFreq; nFreq += step) {
            y = nTop + ((_nMaxFreq - nFreq) * nHeight / fSpanFreq);
            if (nFreq < 1000)
                sText = [NSString stringWithFormat:@"%d", nFreq];
            else
                sText = [NSString stringWithFormat:@"%gk", (float)nFreq / 1000];
            size = [sText sizeWithAttributes:_fontAttrs];
            DrawString(sText, nLeft - size.width - 5, y - size.height / 2, _fontAttrs);
        }
    }
    
    if (bAxisX) {
        sText = NSLocalizedString(@"IDS_TIME", nil);
        sText = [sText stringByAppendingString:@" [s]"];
        size = [sText sizeWithAttributes:_fontAttrs];
        DrawString(sText, nLeft + (nWidth - size.width) / 2, _sizeGraphView.height - size.height - 4, _fontAttrs);
    }
    
    sText = NSLocalizedString(@"IDS_FREQUENCY", nil);
    sText = [sText stringByAppendingString:@" [Hz]"];
    size = [sText sizeWithAttributes:_fontAttrs];
    DrawRotateString(context, sText, 4, (nHeight - size.width) / 2 - nBottom, _fontAttrs);

    [self drawNote:pText :nTop :nRight];
}

- (void)drawLevelScale:(int)nLeft :(int)nTop :(int)nRight :(int)nBottom
{
    int y;
    int nLevel;
    int nHeight = nBottom - nTop;
    int nLevelRange = _nMaxLevel - _nMinLevel;
    NSString *sText;
    CGSize size;
    CGFloat rgb[3];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    DrawRectangle(context, nRight + 9, nTop - 1, nRight + 21, nBottom + 1, _colorBlack);
    
    int step = GetLinearScaleStep(_nMaxLevel, _nMinLevel, nHeight * 3 / 5);
    for (nLevel = GetScaleStartValue(_nMinLevel, step); nLevel <= _nMaxLevel; nLevel += step) {
        y = nTop - (nLevel - _nMaxLevel) * nHeight / nLevelRange;
        
        sText = [NSString stringWithFormat:@"%d", nLevel];
        size = [sText sizeWithAttributes:_fontAttrs];
        DrawString(sText, nRight + 24, y - size.height / 2, _fontAttrs);
    }
    
    for (y = nTop; y <= nBottom; y++) {
        [self getLevelColor:_nMaxLevel - (y - nTop) * nLevelRange / (float)nHeight :rgb];
        DrawFillRectRGB(context, nRight + 10, y, 10, 1, rgb[0], rgb[1], rgb[2], 1.0);
    }
    
    sText = NSLocalizedString(@"IDS_LEVEL", nil);
    sText = [sText stringByAppendingString:@" [dB]"];
    size = [sText sizeWithAttributes:_fontAttrs];
    DrawString(sText, _sizeGraphView.width - size.width, _sizeGraphView.height - size.height - 4, _fontAttrs);
}

- (void)getLevelColor:(float)fLevel :(CGFloat *)rgb
{
    CGFloat r, g, b;
    
    fLevel = (fLevel - _nMinLevel) / (_nMaxLevel - _nMinLevel);
    
    if (g_oSetData.Fft.nColorScale == 0) {
        if (fLevel >= 0.8) {
            r = 1;
            g = 1 - ((fLevel - 0.8) * 5);
            b = 0;
        } else if (fLevel >= 0.6) {
            r = (fLevel - 0.6) * 5;
            g = 1;
            b = 0;
        } else if (fLevel >= 0.4) {
            r = 0;
            g = 1;
            b = 1 - (fLevel - 0.4) * 5;
        } else if (fLevel >= 0.2) {
            r = 0;
            g = (fLevel - 0.2) * 5;
            b = 1;
        } else {
            r = 0;
            g = 0;
            b = fLevel * 5;
        }
    } else
        r = g = b = fLevel;
    
    if (r > 1)
        r = 1;
    else if (r < 0)
        r = 0;
    
    if (g > 1)
        g = 1;
    else if (g < 0)
        g = 0;
    
    if (b > 1)
        b = 1;
    else if (b < 0)
        b = 0;
    
    rgb[0] = r;
    rgb[1] = g;
    rgb[2] = b;
}

- (void)setDispDataSpg
{
    float fTimeStep = _nScaleWidth * _fTimeStep2 / g_oSetData.Fft.nTimeRange;
    _fSpgTimeStep += fTimeStep;
    int nTimeStep = (int)_fSpgTimeStep;
    _fSpgTimeStep -= nTimeStep;
    
    if (_nViewMode == VM_OVERLAY) {
        [self calcSpg:&_aFftData[0] :nTimeStep];
        [self dispSpgInfo:&_aFftData[0] :self.outletPeakFreqLeft :self.outletPeakLevelLeft];
    } else {
        if (_bLch) {
            [self calcSpg:&_aFftData[0] :nTimeStep];
            [self dispSpgInfo:&_aFftData[0] :self.outletPeakFreqLeft :self.outletPeakLevelLeft];
        }
        
        if (_bRch) {
            [self calcSpg:&_aFftData[1] :nTimeStep];
            [self dispSpgInfo:&_aFftData[0] :self.outletPeakFreqLeft :self.outletPeakLevelLeft];
        }
    }
}

- (void)calcSpg:(FFTDATA *)pFftData :(int)nTimeStep
{
    int i;
    int x, y;
    int y2 = 0;
    float fTmp1 = (float)_nScaleHeight / (_fLogMaxFreq - _fLogMinFreq);
    float fTmp2 = (float)_nScaleHeight / (_nMaxFreq - _nMinFreq);
    float fTmp3 = exp(0.5 / fTmp1);
    float nLevel = 0;
    int nFftSize2 = _nFftSize / 2;
    int nCount = 0;
    int t1, t2, t3;
    CGFloat rgb[3];

    MEMCLEAR(_pSpgLevel, _nScaleHeight);
    
    for (i = 1; i < nFftSize2; i++) {
        if (g_oSetData.Fft.nFftScale == 0)
            y = (int)((_fLogMaxFreq - _pLogFreqTbl[i]) * fTmp1 + 0.5);
        else
            y = (int)((_nMaxFreq - _fFreqStep * i) * fTmp2 + 0.5);
        
        if (i == 1)
            y2 = y;
        
        if (y != y2) {
            if (y >= 0 && y < _nScaleHeight) {
                if (nLevel == 0)
                    _pSpgLevel[y] = (float)_nMinLevel;
                else {
                    float tmp4, tmp5;
                    
                    if (g_oSetData.Fft.nFftScale == 0) {
                        tmp4 = _nMaxFreq / exp(y / fTmp1);
                        tmp5 = tmp4 * fTmp3 - tmp4 / fTmp3;
                    } else
                        tmp5 = 1 / fTmp2;
                    
                    _pSpgLevel[y] = dB10(nLevel / nCount * tmp5 / _fFreqStep);
                }
            }
            
            y2 = y;
            nLevel = 0;
            nCount = 0;
        }
        
        nLevel += pFftData->_pPowerSpecBuf[i];
        nCount++;
    }
    
    for (i = 0; i < _nScaleHeight; i++) {
        if (_pSpgLevel[i] == 0) {
            for (t1 = i; t1 >= 0 && _pSpgLevel[t1] == 0; t1--)
                ;
            for (t2 = i; t2 < _nScaleHeight && _pSpgLevel[t2] == 0; t2++)
                ;
            if (t1 < 0)
                _pSpgLevel[i] = _pSpgLevel[t2];
            else if (t2 >= _nScaleHeight)
                _pSpgLevel[i] = _pSpgLevel[t1];
            else {
                t3 = t2 - t1;
                _pSpgLevel[i] = (_pSpgLevel[t1] * (t2 - i) + _pSpgLevel[t2] * (i - t1)) / t3;
            }
        }
    }
    
    UIGraphicsBeginImageContext(CGSizeMake(_nScaleWidth, _nScaleHeight));
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    int nScroll;
    
    if (g_oSetData.Fft.nTimeDir == 0) {
        x = _nScaleWidth - nTimeStep;
        nScroll = -nTimeStep;
    } else {
        x = 0;
        nScroll = nTimeStep;
    }

	if (pFftData->_pSpgImage != nil)
		[pFftData->_pSpgImage drawAtPoint:CGPointMake(nScroll, 0)];
	else
		DrawFillRect(context, 0, 0, _nScaleWidth, _nScaleHeight, _colorBlack);
    
    for (y = 0; y < _nScaleHeight; y++) {
        [self getLevelColor:_pSpgLevel[y] :rgb];
        DrawFillRectRGB(context, x, y, nTimeStep, 1, rgb[0], rgb[1], rgb[2], 1.0);
    }

    pFftData->_pSpgImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

- (void)drawDataSpg:(CGContextRef)context :(int)nChannel
{
    if (nChannel == 1 && _nViewMode == VM_OVERLAY)
        return;

    if (nChannel == 0)
        [_aFftData[0]._pSpgImage drawAtPoint:CGPointMake(0, 0)];
    else
        [_aFftData[1]._pSpgImage drawAtPoint:CGPointMake(0, 0)];
}

- (void)dispSpgInfo:(FFTDATA *)pFftData :(CtTextField *)freqTextField :(CtTextField *)levelTextField
{
    levelTextField.text = [NSString stringWithFormat:@"%.2lf", dB10(pFftData->_fFftAllPower)];
    freqTextField.text = @"ALL";
}

@end
