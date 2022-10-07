//
//  FftGraphCep.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/26.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "FftViewController.h"

@implementation FftViewController (cep)

- (void)initCep
{
    _nFrameLeft = 75 * _sizeGraphView.width / 768;
    _nFrameTop = 10;
    _nFrameRight = _sizeGraphView.width - 15;
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
    
    for (int i = 0; i < 2; i++) {
        FFTDATA &oFftData = _aFftData[i];
        
        if (oFftData._pCepPoint == NULL)
            oFftData._pCepPoint = new CGPoint[_nScaleWidth * 3];
        oFftData._nCepPointCount = 0;
        
        if (oFftData._pCepPeakPoint == NULL)
            oFftData._pCepPeakPoint = new CGPoint[_nScaleWidth * 3];
        oFftData._nCepPeakCount = 0;
    }    
}

- (void)drawScaleCep:(CGRect)frame
{
    if (_nViewMode != VM_SPLIT) {
        [self drawScaleCepSub:_nFrameLeft :_nFrameTop :_nFrameRight :_nFrameBottom :YES :_nChannel == CH_STEREO ? @"Lch / Rch" : NULL];
    } else {
        [self drawScaleCepSub:_nFrameLeft :_nFrameTop :_nFrameRight :_nFrameTop + _nScaleHeight :NO :@"Lch"];
        [self drawScaleCepSub:_nFrameLeft :_nFrameBottom - _nScaleHeight :_nFrameRight :_nFrameBottom :YES :@"Rch"];
    }
}

- (void)drawScaleCepSub:(int)nLeft :(int)nTop :(int)nRight :(int)nBottom :(BOOL)bAxisX :(NSString *)pText
{
    float t;
    int	nLevel;
    CGFloat x, y;
    int nWidth = nRight - nLeft;
    int nHeight = nBottom - nTop;
    NSString *sText;
    CGSize size;
    int ns;
    float fTime = _fTimeStep / (g_oSetData.Fft.nCrfZoom * 2);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    DrawFillRect(context, nLeft, nTop, nWidth, nHeight, _colorWhite);
    DrawRectangle(context, nLeft - 1, nTop - 1, nRight + 1, nBottom + 1, _colorBlack);
    
    float t1 = _fTimeStep / (10 * g_oSetData.Fft.nCrfZoom);
    t1 *= 500.0 / _nScaleWidth;
    float fStep = pow(10.0, floor(log10(t1)));
    float t2 = t1 / fStep;
    if (t2 < 3) {
        fStep *= 0.5;
        ns = 2;
    } else if (t2 < 5)
        ns = 2;
    else
        ns = 5;
    
    for (t = 0; t < fTime; t += fStep) {
        x = _nFrameLeft + (t * _nScaleWidth / fTime);
        if (x >= nLeft && x <= nRight) {
            if (int(t / fStep + 0.5) % ns == 0) {
                if (x > nLeft) {
                    DrawLine(context, x, nTop, x, nBottom, t == 0 ? _colorBlack : _colorGray);
                }
                
                if (bAxisX) {
                    sText = [NSString stringWithFormat:@"%g", t * 1000];
                    size = [sText sizeWithAttributes:_fontAttrs];
                    DrawString(sText, x - size.width / 2, nBottom + 3, _fontAttrs);
                }
            } else {
                if (x > nLeft) {
                    DrawLine(context, x, nTop, x, nBottom, _colorLightGray);
                }
            }
        }
    }
    
    int nStep = GetLinearScaleStep(_nMaxLevel, _nMinLevel, nHeight);
    float fSpanLevel = _nMaxLevel - _nMinLevel;
    for (nLevel = GetScaleStartValue(_nMinLevel, nStep); nLevel <= _nMaxLevel; nLevel += nStep) {
        y = nBottom - ((nLevel - _nMinLevel) * nHeight / fSpanLevel);
        
        if (y > nTop && y < nBottom) {
            DrawLine(context, nLeft, y, nRight, y, _colorGray);
        }
        
        sText = [NSString stringWithFormat:@"%d", nLevel];
        size = [sText sizeWithAttributes:_fontAttrs];
        DrawString(sText, nLeft - size.width - 5, y - size.height / 2, _fontAttrs);
    }
    
    if (bAxisX) {
        sText = NSLocalizedString(@"IDS_TIME", nil);
        sText = [sText stringByAppendingString:@" [ms]"];
        size = [sText sizeWithAttributes:_fontAttrs];
        DrawString(sText, nLeft + (_nScaleWidth - size.width) / 2, _sizeGraphView.height - size.height - 4, _fontAttrs);
    }
    
    sText = NSLocalizedString(@"IDS_LEVEL", nil);
    sText = [sText stringByAppendingString:@" [dB]"];
    size = [sText sizeWithAttributes:_fontAttrs];
    DrawRotateString(context, sText, 4, (nHeight - size.width) / 2 - nBottom, _fontAttrs);

    [self drawNote:pText :nTop :nRight];
}

- (void)setDispDataCep
{
    if (_bLch)
        [self calcCep:&_aFftData[0]];
    
    if (_bRch)
        [self calcCep:&_aFftData[1]];
    
    [self dispCepInfo];
}

- (void)calcCep:(FFTDATA *)pFftData
{
    int i, j, k;
    float fLevel = 0;
    float *pPowerSpecBuf = pFftData->_oPowerSpecBuf.GetBuf();
    float *pCepBuf = pFftData->_pCepBuf;
    int nFftSize2 = _nFftSize / 2;
    int nDataSize = nFftSize2 / g_oSetData.Fft.nCrfZoom;
    
    for (i = 0; i < nFftSize2; i++) {
        j = i * 2;
        for (k = i; k < nFftSize2; k++) {
            fLevel = pPowerSpecBuf[k];
            if (fLevel > 0)
                break;
        }
        if (k == nFftSize2)
            fLevel = 0;
        
        pCepBuf[j] = (fLevel != 0) ? dB10(fLevel) : 0;
        pCepBuf[j + 1] = 1;
    }
    
    _oFFT.ifft(_nFftSize, pCepBuf);
    
    pCepBuf[0] = 0;
    
    float fMul = (float)50 / _nFftSize;
    for (i = 0; i < nFftSize2; i++)
        pCepBuf[i] *= fMul;
    
    pFftData->_nCepPointCount = [self calcCepSub:pCepBuf :pFftData->_pCepPoint];
    
    if (g_oSetData.Fft.bPeakHold) {
        float *pPeakLevel = pFftData->_pCepPeakLevel;
        for (i = 0; i < nDataSize; i++) {
            fLevel = pCepBuf[i];
            if (fLevel > *pPeakLevel || _nPeakHoldTimer == 0)
                *pPeakLevel = fLevel;
            
            pPeakLevel++;
        }
        
        pFftData->_nCepPeakCount = [self calcCepSub:pFftData->_pCepPeakLevel :pFftData->_pCepPeakPoint];
    }
}

- (int)calcCepSub:(float *)pCepBuf :(CGPoint *)pPoint
{
    int i;
    int x, y;
    int x2 = -1;
    int x3 = x2;
    float fStepY = (float)_nScaleHeight / (_nMinLevel - _nMaxLevel);
    int nDataSize = _nFftSize / (2 * g_oSetData.Fft.nCrfZoom);
    int nPointCount = 0;
    int ymin = INT_MAX;
    int ymax = INT_MIN;
    int ymin2 = ymin;
    int ymax2 = ymax;
    
    for (i = 0; i < nDataSize; i++) {
        x = (i * _nScaleWidth) / nDataSize;
        
        if (x != x2) {
            if (x2 >= 0) {
                if (ymax2 != INT_MIN && (x > x2 + 1 || ymin2 > ymax || ymax2 < ymin || ymin == ymax)) {
                    pPoint[nPointCount] = CGPointMake(x3, ymax2);
                    nPointCount++;
                    
                    pPoint[nPointCount] = CGPointMake(x2, ymax);
                    nPointCount++;
                }
                
                if (ymin != ymax) {
                    pPoint[nPointCount] = CGPointMake(x2, ymin);
                    nPointCount++;
                    
                    pPoint[nPointCount] = CGPointMake(x2, ymax);
                    nPointCount++;
                }
                
                if (x2 >= _nScaleWidth)
                    break;
            }
            
            ymin2 = ymin;
            ymax2 = ymax;
            x3 = x2;
            
            x2 = x;
            ymin = INT_MAX;
            ymax = INT_MIN;
        }
        
        y = (int)((pCepBuf[i] - _nMaxLevel) * fStepY + 0.5);

        if (y < ymin)
            ymin = y;
        if (y > ymax)
            ymax = y;
    }
    
    return nPointCount;
}

- (void)drawDataCep:(CGContextRef)context :(int)nChannel
{
    if (nChannel == 0)
        [self drawDataCepSub:context :&_aFftData[0] :_colorLeft :_colorLeftPeak];
    else
        [self drawDataCepSub:context :&_aFftData[1] :_colorRight :_colorRightPeak];
}

- (void)drawDataCepSub:(CGContextRef)context :(FFTDATA *)pFftData :(UIColor *)colorData :(UIColor *)colorPeak
{
    if (pFftData->_nCepPointCount != 0) {
        DrawLineSegments(context, pFftData->_pCepPoint, pFftData->_nCepPointCount, colorData);
        
        if (g_oSetData.Fft.bPeakHold) {
            DrawLineSegments(context, pFftData->_pCepPeakPoint, pFftData->_nCepPeakCount, colorPeak);
        }
        
        if (pFftData->_nCepDispTime != 0) {
            DrawLine(context, pFftData->_nCepTimePos, 0, pFftData->_nCepTimePos, _nScaleHeight, colorPeak);
            DrawLine(context, 0, pFftData->_nCepLevelPos, _nScaleWidth, pFftData->_nCepLevelPos, colorPeak);
        }
    }
}

- (void)dispCepInfo
{
    if (_bLch)
        [self dispCepInfoSub:&_aFftData[0] :self.outletPeakFreqLeft :self.outletPeakLevelLeft];
    
    if (_bRch)
        [self dispCepInfoSub:&_aFftData[1] :self.outletPeakFreqRight :self.outletPeakLevelRight];
}

- (void)dispCepInfoSub:(FFTDATA *)pFftData :(CtTextField *)freqTextField :(CtTextField *)levelTextField
{
    float *pCepBuf = pFftData->_pCepBuf;
    int nDataSize = _nFftSize / (2 * g_oSetData.Fft.nCrfZoom);
    
    if (g_oSetData.Fft.bPeakDisp) {
        float fPeakLevel = pCepBuf[1];
        pFftData->_nCepDispTime = 1;
        for (int i = 2; i < nDataSize; i++) {
            if (pCepBuf[i] > fPeakLevel) {
                fPeakLevel = pCepBuf[i];
                pFftData->_nCepDispTime = i;
            }
        }
    }
    
    pFftData->_nCepTimePos = (pFftData->_nCepDispTime * _nScaleWidth) / nDataSize;
    pFftData->_nCepLevelPos = (int)((pCepBuf[pFftData->_nCepDispTime] - _nMaxLevel) * ((float)_nScaleHeight / (_nMinLevel - _nMaxLevel)));
    
    if (pFftData->_nCepDispTime == 0) {
        levelTextField.text = @"";
        freqTextField.text = @"";
    } else {
        levelTextField.text = [NSString stringWithFormat:@"%.2lf", pCepBuf[pFftData->_nCepDispTime]];
        freqTextField.text = [NSString stringWithFormat:@"%.1lf", 1000.0 * pFftData->_nCepDispTime / _nSamplingRate];
    }
}

- (void)setDispFreqCep:(CGPoint)point
{
    if (!g_oSetData.Fft.bPeakDisp) {
        int n;
        int nDataSize = _nFftSize / (2 * g_oSetData.Fft.nCrfZoom);
        
        n = (point.x - _nFrameLeft) * nDataSize / _nScaleWidth;
        _aFftData[0]._nCepDispTime = _aFftData[1]._nCepDispTime = (n > 1 && n < nDataSize) ? n : 0;
        [self dispCepInfo];
        [_viewFftScale setNeedsDisplay];
    }
}

- (void)resetDispFreqCep
{
    if (!g_oSetData.Fft.bPeakDisp) {
        _aFftData[0]._nCepDispTime = _aFftData[1]._nCepDispTime = 0;
        [self dispCepInfo];
        [_viewFftScale setNeedsDisplay];
    }
}

@end
