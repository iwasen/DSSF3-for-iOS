//
//  FftGraphCep.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/26.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "FftViewController.h"

@implementation FftViewController (coh)

- (void)initCoh
{
    _nFrameLeft = 75 * _sizeGraphView.width / 768;
    _nFrameTop = 10;
    _nFrameRight = _sizeGraphView.width - 15;
    _nFrameBottom = _sizeGraphView.height - (55 * _sizeGraphView.width / 768);
    _nFrameWidth = _nFrameRight - _nFrameLeft;
    _nFrameHeight = _nFrameBottom - _nFrameTop;
    
    _nScaleWidth = _nFrameWidth;
    _nScaleHeight = _nFrameHeight;
    
    if (_pCohPoint == NULL)
        _pCohPoint = new CGPoint[_nScaleWidth * 2 + 4];
    _nCohPointCount = 0;
}

- (void)drawScaleCoh:(CGRect)frame
{
    [self drawScaleCohSub:_nFrameLeft :_nFrameTop :_nFrameRight :_nFrameBottom :YES];
}

- (void)drawScaleCohSub:(int)nLeft :(int)nTop :(int)nRight :(int)nBottom :(BOOL)bAxisX
{
    int	nFreq;
    CGFloat x, y;
    int nWidth = nRight - nLeft;
    int nHeight = nBottom - nTop;
    NSString *sText;
    CGSize size;
    int i;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    DrawFillRect(context, nLeft, nTop, nWidth, nHeight, _colorWhite);
    DrawRectangle(context, nLeft - 1, nTop - 1, nRight + 1, nBottom + 1, _colorBlack);
    
    if (g_oSetData.Fft.nFftScale == 0) {
        int step = GetLogScaleStep(_nMinFreq);
        for (nFreq = GetScaleStartValue(_nMinFreq, step); nFreq <= _nMaxFreq; nFreq += GetLogScaleStep(nFreq)) {
            x =  (log((float)nFreq) - _fLogMinFreq) * nWidth / (_fLogMaxFreq - _fLogMinFreq) + nLeft;
            
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
            x = (nFreq - _nMinFreq) * nWidth / (_nMaxFreq - _nMinFreq) + nLeft;
            
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
    
    for (i = 0; i <= 100; i += 10) {
        y = nBottom - (i * ((float)_nScaleHeight) / 100);
        if (i != 100 && i != 0) {
            DrawLine(context, nLeft, y, nRight, y, _colorGray);
        }
        
        sText = [NSString stringWithFormat:@"%g", (float)i / 100];
        size = [sText sizeWithAttributes:_fontAttrs];
        DrawString(sText, nLeft - size.width - 5, y - size.height / 2, _fontAttrs);
    }
    
    if (bAxisX) {
        sText = NSLocalizedString(@"IDS_FREQUENCY", nil);
        sText = [sText stringByAppendingString:@" [Hz]"];
        size = [sText sizeWithAttributes:_fontAttrs];
        DrawString(sText, nLeft + (nWidth - size.width) / 2, _sizeGraphView.height - size.height - 4, _fontAttrs);
    }
    
    sText = NSLocalizedString(@"IDS_COHERENCE2", nil);
    size = [sText sizeWithAttributes:_fontAttrs];
    DrawRotateString(context, sText, 4, (nHeight - size.width) / 2 - nBottom, _fontAttrs);
}

- (void)setDispDataCoh
{
    int i;
    float w, cr, ci;
    float fCoherence;
    int nFftSize2 = _nFftSize / 2;
    
    float *pPowerSpecBufL = _aFftData[0]._oPowerSpecBuf.GetBuf();
    float *pPowerSpecBufR = _aFftData[1]._oPowerSpecBuf.GetBuf();
    float *pCrossBufRe = _oCrossBufRe.GetBuf();
    float *pCrossBufIm = _oCrossBufIm.GetBuf();
    _pCoherenceBuf[0] = 0;
    for (i = 1; i < nFftSize2; i++) {
        cr = pCrossBufRe[i];
        ci = pCrossBufIm[i];
        
        w = pPowerSpecBufL[i] * pPowerSpecBufR[i];
        fCoherence = (w == 0) ? 0 : (cr * cr + ci * ci) / w;
        
        _pCoherenceBuf[i] = fCoherence * _fSmoothing1 + _pCoherenceBuf[i] * _fSmoothing2;
    }
    
    _nCohPointCount = [self calcCoh:_pCoherenceBuf :_pCohPoint];
    
    [self dispCohInfo];
}

- (int)calcCoh:(const float *)pBuf :(CGPoint *)pPoint
{
    int i;
    int x, y;
    int x2 = -1;
    int x3 = x2;
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
        
        y = (int)(_nScaleHeight - (pBuf[i] * _nScaleHeight) + 0.5);
        
        if (y < ymin)
            ymin = y;
        if (y > ymax)
            ymax = y;
    }
    
    return nPointCount;
}

- (void)drawDataCoh:(CGContextRef)context :(int)nChannel
{
    if (nChannel == 0) {
        if (_nCohPointCount != 0) {
            DrawPolyline(context, _pCohPoint, _nCohPointCount, _colorCoherence);
        }
        
        if (_nCohDispFreq != 0) {
            DrawLine(context, _nCohFreqPos, 0, _nCohFreqPos, _nScaleHeight, _colorGreen);
            DrawLine(context, 0, _nCohLevelPos, _nScaleWidth, _nCohLevelPos, _colorGreen);
        }
    }
}

- (void)dispCohInfo
{
    float *pBuf = _pCoherenceBuf;
    
    if (g_oSetData.Fft.nFftScale == 0)
        _nCohFreqPos = (int)((_pLogFreqTbl[_nCohDispFreq] - _fLogMinFreq) * ((float)_nFrameWidth / (_fLogMaxFreq - _fLogMinFreq)));
    else
        _nCohFreqPos = (int)((_fFreqStep * _nCohDispFreq - _nMinFreq) * ((float)_nFrameWidth / (_nMaxFreq - _nMinFreq)));
    _nCohLevelPos = _nScaleHeight - (int)(pBuf[_nCohDispFreq] * _nScaleHeight);
    
    if (_nCohDispFreq == 0) {
        self.outletPeakLevelLeft.text = @"";
        self.outletPeakFreqLeft.text= @"";
    } else {
        self.outletPeakLevelLeft.text = [NSString stringWithFormat:@"%.2lf", pBuf[_nCohDispFreq]];
        self.outletPeakFreqLeft.text = [NSString stringWithFormat:@"%.1lf",  _fFreqStep * _nCohDispFreq];
    }
}

- (void)setDispFreqCoh:(CGPoint)point
{
    int n;
    
    if (g_oSetData.Fft.nFftScale == 0)
        n = (int)(exp((point.x - _nFrameLeft) * (_fLogMaxFreq - _fLogMinFreq) / _nScaleWidth + _fLogMinFreq) / _fFreqStep);
    else
        n = (int)(((point.x - _nFrameLeft) * (_nMaxFreq - _nMinFreq) / _nScaleWidth + _nMinFreq) / _fFreqStep);
    
    _nCohDispFreq = (n > 1 && n < _nFftSize / 2) ? n : 0;
    [self dispCohInfo];
    [_viewFftScale setNeedsDisplay];
}

- (void)resetDispFreqCoh
{
    _nCohDispFreq = 0;
    [self dispCohInfo];
    [_viewFftScale setNeedsDisplay];
}

@end
