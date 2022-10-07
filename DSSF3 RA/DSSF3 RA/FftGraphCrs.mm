//
//  FftGraphCrs.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/26.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "FftViewController.h"

@implementation FftViewController (Crs)

- (void)initCrs
{
    _nFrameLeft = 75 * _sizeGraphView.width / 768;
    _nFrameTop = 10;
    _nFrameRight = _sizeGraphView.width - 15;
    _nFrameBottom = _sizeGraphView.height - (55 * _sizeGraphView.width / 768);
    _nFrameWidth = _nFrameRight - _nFrameLeft;
    _nFrameHeight = _nFrameBottom - _nFrameTop;
    
    _nScaleWidth = _nFrameWidth;
    _nScaleHeight = _nFrameHeight;
    
    if (_pCrsPoint == NULL)
        _pCrsPoint = new CGPoint[_nScaleWidth * 2 + 4];
    _nCrsPointCount = 0;
    
    if (_pCrsPeakPoint == NULL)
        _pCrsPeakPoint = new CGPoint[_nScaleWidth * 2 + 4];
    _nCrsPeakCount = 0;
}

- (void)drawScaleCrs:(CGRect)frame
{
    [self drawScaleCrsSub:_nFrameLeft :_nFrameTop :_nFrameRight :_nFrameBottom :YES];
}

- (void)drawScaleCrsSub:(int)nLeft :(int)nTop :(int)nRight :(int)nBottom :(BOOL)bAxisX
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
        for (nFreq = GetScaleStartValue(_nMinFreq, step); nFreq <= _nMaxFreq; nFreq += GetLogScaleStep(nFreq)) {
            x =  ((log((float)nFreq) - _fLogMinFreq) * nWidth / (_fLogMaxFreq - _fLogMinFreq)) + nLeft;
            
            if (nFreq < 1000)
                sText = [NSString stringWithFormat:@"%d", nFreq];
            else
                sText = [NSString stringWithFormat:@"%gk", (float)nFreq / 1000];
            
            if (bAxisX && ([sText characterAtIndex:0] == '1' || [sText characterAtIndex:0] == '2' || [sText characterAtIndex:0] == '5')) {
                size = [sText sizeWithAttributes:_fontAttrs];
                DrawString(sText, x - size.width / 2, nBottom + 3, _fontAttrs);
            }
            
            if (x > nLeft && x < nRight) {
                DrawLine(context, x, nTop, x, nBottom, [sText characterAtIndex:0] == '1' ? _colorGray : _colorLightGray);
            }
        }
    } else {
        int step = GetLinearScaleStep(_nMaxFreq, _nMinFreq, (int)(nWidth * 0.75));
        for (nFreq = GetScaleStartValue(_nMinFreq, step); nFreq <= _nMaxFreq; nFreq += step) {
            x =  ((nFreq - _nMinFreq) * nWidth / (float)(_nMaxFreq - _nMinFreq)) + nLeft;
            
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
    for (nLevel = GetScaleStartValue(_nMinLevel, step); nLevel <= _nMaxLevel; nLevel += step) {
        y = nTop - (nLevel - _nMaxLevel) * nHeight / (float)(_nMaxLevel - _nMinLevel);
        
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
    
    sText = NSLocalizedString(@"IDS_LEVEL", nil);
    sText = [sText stringByAppendingString:@" [dB]"];
    size = [sText sizeWithAttributes:_fontAttrs];
    DrawRotateString(context, sText, 4, (nHeight - size.width) / 2 - nBottom, _fontAttrs);
}

- (void)setDispDataCrs
{
    [self calcCrs];
    
    [self dispCrsInfo];
}

- (void)calcCrs
{
    int i;
    float fLevel;
    float *pCrossBufRe = _oCrossBufRe.GetBuf();
    float *pCrossBufIm = _oCrossBufIm.GetBuf();
    int nFftSize2 = _nFftSize / 2;
    
    _fCrossAllPower = 0;
    for (i = 1; i < nFftSize2; i++) {
        _pCrsBuf[i] = sqrt(pCrossBufRe[i] * pCrossBufRe[i] + pCrossBufIm[i] * pCrossBufIm[i]);
        _fCrossAllPower += _pCrsBuf[i];
    }
    
    _nCrsPointCount = [self calcCrsSub:_pCrsBuf :_pCrsPoint];
    
    if (g_oSetData.Fft.bPeakHold) {
        float *pPeakLevel = _pCrsPeakLevel;
        for (i = 0; i < nFftSize2; i++) {
            fLevel = _pCrsBuf[i];
            if (fLevel > *pPeakLevel || _nPeakHoldTimer == 0)
                *pPeakLevel = fLevel;
            
            pPeakLevel++;
        }
        
        _nCrsPeakCount = [self calcCrsSub:_pCrsPeakLevel :_pCrsPeakPoint];
    }
}

- (int)calcCrsSub:(const float *)pFftPBuf :(CGPoint *)pPoint
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
        
        y = (int)((dB10(pFftPBuf[i]) - _nMaxLevel) * fStepY + 0.5);
        
        if (y < ymin)
            ymin = y;
        if (y > ymax)
            ymax = y;
    }
    
    return nPointCount;
}

- (void)drawDataCrs:(CGContextRef)context :(int)nChannel
{
    if (nChannel == 0) {
        if (_nCrsPointCount != 0) {
            DrawPolyline(context, _pCrsPoint, _nCrsPointCount, _colorCross);
            
            if (g_oSetData.Fft.bPeakHold) {
                DrawPolyline(context, _pCrsPeakPoint, _nCrsPeakCount, _colorCrossPeak);
            }
            
            if (_nCrsDispFreq != 0) {
                DrawLine(context, _nCrsFreqPos, 0, _nCrsFreqPos, _nScaleHeight, _colorGreen);
                DrawLine(context, 0, _nCrsLevelPos, _nScaleWidth, _nCrsLevelPos, _colorGreen);
            }
        }
    }
}

- (void)dispCrsInfo
{
    float *pBuf = _pCrsBuf;
    
    if (g_oSetData.Fft.bPeakDisp) {
        int nFftSize2 = _nFftSize / 2;
        float fPeakLevel = 0;
        for (int i = 1; i < nFftSize2; i++) {
            float fFreq = _fFreqStep * i;
            if (fFreq >= _nMinFreq && fFreq <= _nMaxFreq && pBuf[i] > fPeakLevel) {
                fPeakLevel = pBuf[i];
                _nCrsDispFreq = i;
            }
        }
    }
    
    if (g_oSetData.Fft.nFftScale == 0)
        _nCrsFreqPos = (int)((_pLogFreqTbl[_nCrsDispFreq] - _fLogMinFreq) * ((float)_nFrameWidth / (_fLogMaxFreq - _fLogMinFreq)));
    else
        _nCrsFreqPos = (int)((_fFreqStep * _nCrsDispFreq - _nMinFreq) * ((float)_nFrameWidth / (_nMaxFreq - _nMinFreq)));
    _nCrsLevelPos = (int)((dB10(pBuf[_nCrsDispFreq]) - _nMaxLevel) * ((float)_nScaleHeight / (_nMinLevel - _nMaxLevel)));
    
    if (_nCrsDispFreq == 0) {
        if (_fCrossAllPower != 0)
            self.outletPeakLevelLeft.text = [NSString stringWithFormat:@"%.2lf", dB10(_fCrossAllPower)];
        self.outletPeakFreqLeft.text = @"ALL";
    } else {
        if (pBuf[_nCrsDispFreq] != 0)
            self.outletPeakLevelLeft.text = [NSString stringWithFormat:@"%.2lf", dB10(pBuf[_nCrsDispFreq])];
        self.outletPeakFreqLeft.text = [NSString stringWithFormat:@"%.1lf",  _fFreqStep * _nCrsDispFreq];
    }
}

- (void)setDispFreqCrs:(CGPoint)point
{
    if (!g_oSetData.Fft.bPeakDisp) {
        int n;
        
        if (g_oSetData.Fft.nFftScale == 0)
            n = (int)(exp((point.x - _nFrameLeft) * (_fLogMaxFreq - _fLogMinFreq) / _nScaleWidth + _fLogMinFreq) / _fFreqStep);
        else
            n = (int)(((point.x - _nFrameLeft) * (_nMaxFreq - _nMinFreq) / _nScaleWidth + _nMinFreq) / _fFreqStep);
        
        _nCrsDispFreq = (n > 1 && n < _nFftSize / 2) ? n : 0;
        [self dispCrsInfo];
        [_viewFftScale setNeedsDisplay];
    }
}

- (void)resetDispFreqCrs
{
    if (!g_oSetData.Fft.bPeakDisp) {
        _nCrsDispFreq = 0;
        [self dispCrsInfo];
        [_viewFftScale setNeedsDisplay];
    }
}

@end
