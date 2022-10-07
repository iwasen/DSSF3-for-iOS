//
//  FftGraphPws.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/10.
//  Copyright (c) 2015年 aizawa. All rights reserved.
//

#import "FftViewController.h"

@implementation FftViewController (Pws)

- (void)initPws
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
        
        if (oFftData._pPwsPoint == NULL)
            oFftData._pPwsPoint = new CGPoint[_nScaleWidth * 3];
        oFftData._nPwsPointCount = 0;
        
        if (oFftData._pPwsPeakPoint == NULL)
            oFftData._pPwsPeakPoint = new CGPoint[_nScaleWidth * 3];
        oFftData._nPwsPeakCount = 0;
    }
}

- (void)drawScalePws:(CGRect)frame
{
    if (_nViewMode != VM_SPLIT) {
        [self drawScalePwsSub:_nFrameLeft :_nFrameTop :_nFrameRight :_nFrameBottom :YES :_nChannel == CH_STEREO ? @"Lch / Rch" : NULL];
    } else {
        [self drawScalePwsSub:_nFrameLeft :_nFrameTop :_nFrameRight :_nFrameTop + _nScaleHeight :NO :@"Lch"];
        [self drawScalePwsSub:_nFrameLeft :_nFrameBottom - _nScaleHeight :_nFrameRight :_nFrameBottom :YES :@"Rch"];
    }
}

- (void)drawScalePwsSub:(int)nLeft :(int)nTop :(int)nRight :(int)nBottom :(bool)bAxisX :(NSString *)pText
{
    int	nFreq, nLevel;
    CGFloat x, y;
    int nWidth = nRight - nLeft;
    int nHeight = nBottom - nTop;
    NSString *sText;
    CGSize size;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    DrawFillRect(context, nLeft, nTop, nWidth, nHeight, _colorWhite);
    DrawRectangle(context, nLeft - 1, nTop - 1, nRight + 1, nBottom + 1, _colorBlack);
    
    if (g_oSetData.Fft.nFftScale == 0) {
        int step = GetLogScaleStep(_nMinFreq);
        float fSpanFreq = _fLogMaxFreq - _fLogMinFreq;
        for (nFreq = GetScaleStartValue(_nMinFreq, step); nFreq <= _nMaxFreq; nFreq += GetLogScaleStep(nFreq)) {
            x =  nLeft + ((log(nFreq) - _fLogMinFreq) * nWidth / fSpanFreq);
            
            if (nFreq < 1000)
                sText = [NSString stringWithFormat:@"%d", nFreq];
            else
                sText = [NSString stringWithFormat:@"%gk", (float)nFreq / 1000];
            
            if (bAxisX && ([sText characterAtIndex:0] == '1' || [sText characterAtIndex:0] == '2' || [sText characterAtIndex:0] == '5')) {
                size = [sText sizeWithAttributes:_fontAttrs];
                DrawString(sText, x - size.width / 2, nBottom + 3, _fontAttrs);
            }
            
            if (x > nLeft && x < nRight) {
                DrawLine(context, x, nTop, x, nBottom, [sText hasPrefix:@"1"] ? _colorGray : _colorLightGray);
            }
        }
    } else {
        int step = GetLinearScaleStep(_nMaxFreq, _nMinFreq, (int)(nWidth * 0.75));
        float fSpanFreq = _nMaxFreq - _nMinFreq;
        for (nFreq = GetScaleStartValue(_nMinFreq, step); nFreq <= _nMaxFreq; nFreq += step) {
            x = nLeft + ((nFreq - _nMinFreq) * nWidth / fSpanFreq);
            
            if (x > nLeft && x < nRight) {
               DrawLine(context, x, nTop, x, nBottom, _colorGray);
            }
            
            if (bAxisX) {
                if (nFreq < 1000)
                    sText = [NSString stringWithFormat:@"%d", nFreq];
                else
                    sText = [NSString stringWithFormat:@"%gk", (float)nFreq / 1000];
                size = [sText sizeWithAttributes:_fontAttrs];
                DrawString(sText, x - size.width / 2, nBottom + 3, _fontAttrs);
            }
        }
    }
    
    int step = GetLinearScaleStep(_nMaxLevel, _nMinLevel, nHeight);
    float fSpanLevel = _nMaxLevel - _nMinLevel;
    for (nLevel = GetScaleStartValue(_nMinLevel, step); nLevel <= _nMaxLevel; nLevel += step) {
        y = nBottom - ((nLevel - _nMinLevel) * nHeight / fSpanLevel);
        
        if (y > nTop && y < nBottom) {
           DrawLine(context, nLeft, y, nRight, y, _colorGray);
        }
        
        sText = [NSString stringWithFormat:@"%d", nLevel];
        size = [sText sizeWithAttributes:_fontAttrs];
        DrawString(sText, nLeft - size.width - 5, y - size.height / 2, _fontAttrs);
    }
    
    if (bAxisX) {
        sText = NSLocalizedString(@"IDS_FREQUENCY", nil);
        sText = [sText stringByAppendingString:@" [Hz]"];
        size = [sText sizeWithAttributes:_fontAttrs];
        DrawString(sText, nLeft + (nWidth - size.width) / 2, _sizeGraphView.height - size.height - 4, _fontAttrs);
    }
    
    sText = NSLocalizedString(@"IDS_SPL", nil);
    sText = [sText stringByAppendingString:@" [dB]"];
    size = [sText sizeWithAttributes:_fontAttrs];
    DrawRotateString(context, sText, 4, (nHeight - size.width) / 2 - nBottom, _fontAttrs);
    
    [self drawNote:pText :nTop :nRight];
}

- (void)setDispDataPws
{
    if (_bLch)
        [self calcPws:&_aFftData[0]];
    
    if (_bRch)
        [self calcPws:&_aFftData[1]];
    
    [self dispPwsInfo];
}

- (void)calcPws:(FFTDATA *)pFftData
{
    int i;
    float fLevel;
    float *pPowerSpecBuf = pFftData->_oPowerSpecBuf.GetBuf();
    int nFftSize2 = _nFftSize / 2;
    
    pFftData->_nPwsPointCount = [self calcPwsSub:pPowerSpecBuf :pFftData->_pPwsPoint];
    
    if (g_oSetData.Fft.bPeakHold) {
        float *pPeakLevel = pFftData->_pPwsPeakLevel;
        for (i = 0; i < nFftSize2; i++) {
            fLevel = pPowerSpecBuf[i];
            if (fLevel > *pPeakLevel || _nPeakHoldTimer == 0)
                *pPeakLevel = fLevel;
            
            pPeakLevel++;
        }
        
        pFftData->_nPwsPeakCount = [self calcPwsSub:pFftData->_pPwsPeakLevel :pFftData->_pPwsPeakPoint];
    }
}

- (int)calcPwsSub:(const float *)pBuf :(CGPoint *)pPoint
{
    int i;
    int x, y;
    int x2 = -1;
    int x3 = x2;
    float fStepY = (float)_nScaleHeight / (_nMinLevel - _nMaxLevel);
    float fTmp1 = (float)_nScaleWidth / (_fLogMaxFreq - _fLogMinFreq);
    float fTmp2 = (float)_nScaleWidth / (_nMaxFreq - _nMinFreq);
    int nFftSize2 = _nFftSize / 2;
    int nPointCount = 0;
    int ymin = INT_MAX;
    int ymax = INT_MIN;
    int ymin2 = ymin;
    int ymax2 = ymax;
    
    for (i = 1; i < nFftSize2; i++) {
        if (g_oSetData.Fft.nFftScale == 0)
            x = (int)((_pLogFreqTbl[i] - _fLogMinFreq) * fTmp1 + 0.5);
        else
            x = (int)((_fFreqStep * i - _nMinFreq) * fTmp2 + 0.5);
        
        if (x != x2) {
            if (x2 >= 0 && ymin >= 0) {
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
        
        y = (int)((dB10(pBuf[i]) - _nMaxLevel) * fStepY + 0.5);
        
        if (y < ymin)
            ymin = y;
        if (y > ymax)
            ymax = y;
    }
    
    return nPointCount;
}

- (void)drawDataPws:(CGContextRef)context :(int)nChannel
{
    if (nChannel == 0)
        [self drawDataPwsSub:context :&_aFftData[0] :_colorLeft :_colorLeftPeak];
    else
        [self drawDataPwsSub:context :&_aFftData[1] :_colorRight :_colorRightPeak];
}

- (void)drawDataPwsSub:(CGContextRef)context :(FFTDATA *)pFftData :(UIColor *)colorData :(UIColor *)colorPeak
{
    if (pFftData->_nPwsPointCount != 0) {
        DrawLineSegments(context, pFftData->_pPwsPoint, pFftData->_nPwsPointCount, colorData);

        if (g_oSetData.Fft.bPeakHold) {
            DrawLineSegments(context, pFftData->_pPwsPeakPoint, pFftData->_nPwsPeakCount, colorPeak);
        }
         
        if (pFftData->_nPwsDispFreq != 0) {
            DrawLine(context, pFftData->_nPwsFreqPos, 0, pFftData->_nPwsFreqPos, _sizeGraphView.height, colorPeak);
            DrawLine(context, 0, pFftData->_nPwsLevelPos, _sizeGraphView.width, pFftData->_nPwsLevelPos, colorPeak);
        }
    }
    
}

- (void)dispPwsInfo
{
    if (_bLch)
        [self dispPwsInfoSub:&_aFftData[0] :self.outletPeakFreqLeft :self.outletPeakLevelLeft];
    
    if (_bRch)
        [self dispPwsInfoSub:&_aFftData[1] :self.outletPeakFreqRight :self.outletPeakLevelRight];
}

- (void)dispPwsInfoSub:(FFTDATA *)pFftData :(CtTextField *)freqTextField :(CtTextField *)levelTextField
{
    float *pBuf = pFftData->_oPowerSpecBuf.GetBuf();
    
    if (g_oSetData.Fft.bPeakDisp) {
        int nFftSize2 = _nFftSize / 2;
        float fPeakLevel = 0;
        for (int i = 1; i < nFftSize2; i++) {
            float fFreq = _fFreqStep * i;
            if (fFreq >= _nMinFreq && fFreq <= _nMaxFreq && pBuf[i] > fPeakLevel) {
                fPeakLevel = pBuf[i];
                pFftData->_nPwsDispFreq = i;
            }
        }
    }
    
    if (g_oSetData.Fft.nFftScale == 0)
        pFftData->_nPwsFreqPos = (int)((_pLogFreqTbl[pFftData->_nPwsDispFreq] - _fLogMinFreq) * ((float)_nFrameWidth / (_fLogMaxFreq - _fLogMinFreq)));
    else
        pFftData->_nPwsFreqPos = (int)((_fFreqStep * pFftData->_nPwsDispFreq - _nMinFreq) * ((float)_nFrameWidth / (_nMaxFreq - _nMinFreq)));
    pFftData->_nPwsLevelPos = (int)((dB10(pBuf[pFftData->_nPwsDispFreq]) - _nMaxLevel) * ((float)_nScaleHeight / (_nMinLevel - _nMaxLevel)));
    
    if (pFftData->_nPwsDispFreq == 0) {
        if (pFftData->_fFftAllPower != 0)
            levelTextField.text = [NSString stringWithFormat:@"%.2lf", dB10(pFftData->_fFftAllPower)];
        freqTextField.text = @"ALL";
    } else {
        if (pBuf[pFftData->_nPwsDispFreq] != 0)
            levelTextField.text = [NSString stringWithFormat:@"%.2lf", dB10(pBuf[pFftData->_nPwsDispFreq])];
        freqTextField.text = [NSString stringWithFormat:@"%.1lf",  _fFreqStep * pFftData->_nPwsDispFreq];
    }
}

- (void)setDispFreqPws:(CGPoint)point
{
    if (!g_oSetData.Fft.bPeakDisp) {
        int n;
        
        if (g_oSetData.Fft.nFftScale == 0)
            n = (int)(exp((point.x - _nFrameLeft) * (_fLogMaxFreq - _fLogMinFreq) / _nScaleWidth + _fLogMinFreq) / _fFreqStep);
        else
            n = (int)(((point.x - _nFrameLeft) * (_nMaxFreq - _nMinFreq) / _nScaleWidth + _nMinFreq) / _fFreqStep);
        
        _aFftData[0]._nPwsDispFreq = _aFftData[1]._nPwsDispFreq = (n > 1 && n < _nFftSize / 2) ? n : 0;
        [self dispPwsInfo];
        [_viewFftScale setNeedsDisplay];
    }
}

- (void)resetDispFreqPws
{
    if (!g_oSetData.Fft.bPeakDisp) {
        _aFftData[0]._nPwsDispFreq = _aFftData[1]._nPwsDispFreq = 0;
        [self dispPwsInfo];
        [_viewFftScale setNeedsDisplay];
    }
}

@end
