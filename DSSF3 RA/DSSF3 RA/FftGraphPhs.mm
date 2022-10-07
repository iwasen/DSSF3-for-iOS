//
//  FftGraphPhs.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/24.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "FftViewController.h"

@implementation FftViewController (Phs)

- (void)initPhs
{
    _nFrameLeft = 75 * _sizeGraphView.width / 768;
    _nFrameTop = 10;
    _nFrameRight = _sizeGraphView.width - 15;
    _nFrameBottom = _sizeGraphView.height - (55 * _sizeGraphView.width / 768);
    _nFrameWidth = _nFrameRight - _nFrameLeft;
    _nFrameHeight = _nFrameBottom - _nFrameTop;

    _nScaleWidth = _nFrameWidth;
    _nScaleHeight = _nFrameHeight;
    
    if (_pPhsPoint == NULL)
        _pPhsPoint = new CGPoint[_nScaleWidth * 2 + 4];
    _nPhsPointCount = 0;
}

- (void)drawScalePhs:(CGRect)frame
{
    [self drawScaleSub:_nFrameLeft :_nFrameTop :_nFrameRight :_nFrameBottom :YES];
}

- (void)drawScaleSub:(int)nLeft :(int)nTop :(int)nRight :(int)nBottom :(BOOL)bAxisX
{
    int	fFreq, fPhase;
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
        for (fFreq = GetScaleStartValue(_nMinFreq, step); fFreq <= _nMaxFreq; fFreq += GetLogScaleStep(fFreq)) {
            x = nLeft + ((log((float)fFreq) - _fLogMinFreq) * nWidth / fSpanFreq);
            
            if (fFreq < 1000)
                sText = [NSString stringWithFormat:@"%d", fFreq];
            else
                sText = [NSString stringWithFormat:@"%gk", (float)fFreq / 1000];
            
            if (bAxisX && ([sText characterAtIndex:0] == '1' || [sText characterAtIndex:0] == '2' || [sText characterAtIndex:0] == '5')) {
                size = [sText sizeWithAttributes:_fontAttrs];
                DrawString(sText, x - size.width / 2, nBottom + 3, _fontAttrs);
            }
            
            if (x > nLeft && x < nRight) {
                DrawLine(context, x, nTop, x, nBottom, [sText characterAtIndex:0] == '1' ? _colorGray : _colorLightGray);
            }
        }
    } else {
        int step = GetLinearScaleStep(_nMaxFreq, _nMinFreq, nWidth);
        float fSpanFreq = _nMaxFreq - _nMinFreq;
        for (fFreq = GetScaleStartValue(_nMinFreq, step); fFreq <= _nMaxFreq; fFreq += step) {
            x = nLeft + ((fFreq - _nMinFreq) * nWidth / fSpanFreq);
            
            if (x > nLeft && x < nRight) {
                DrawLine(context, x, nTop, x, nBottom, _colorGray);
            }
            
            if (bAxisX) {
                if (fFreq < 1000)
                    sText = [NSString stringWithFormat:@"%d", fFreq];
                else
                    sText = [NSString stringWithFormat:@"%gk", (float)fFreq / 1000];
                size = [sText sizeWithAttributes:_fontAttrs];
                DrawString(sText, x - size.width / 2, nBottom + 3, _fontAttrs);
            }
        }
    }
    
    int nCenter = (nTop + nBottom) / 2;
    for (fPhase = 180; fPhase >= -180; fPhase -= 45) {
        y = nCenter - fPhase * nHeight / 2 / 180;
        if (fPhase != 180 && fPhase != -180) {
            DrawLine(context, nLeft, y, nRight, y, fPhase == 0 ? _colorBlack : _colorGray);
        }
        
        sText = [NSString stringWithFormat:@"%+d", fPhase];
        size = [sText sizeWithAttributes:_fontAttrs];
        DrawString(sText, nLeft - size.width - 5, y - size.height / 2, _fontAttrs);
    }
    
    if (bAxisX) {
        sText = NSLocalizedString(@"IDS_FREQUENCY", nil);
        sText = [sText stringByAppendingString:@" [Hz]"];
        size = [sText sizeWithAttributes:_fontAttrs];
        DrawString(sText, nLeft + (nWidth - size.width) / 2, _sizeGraphView.height - size.height - 4, _fontAttrs);
    }
    
    sText = NSLocalizedString(@"IDS_PHASE2", nil);
    sText = [sText stringByAppendingString:@" [degree]"];
    size = [sText sizeWithAttributes:_fontAttrs];
    DrawRotateString(context, sText, 4, (nHeight - size.width) / 2 - nBottom, _fontAttrs);
}

- (void)setDispDataPhs
{
    int i, j;
    float xt1, yt1, xt2, yt2;
    int nFftSize2 = _nFftSize / 2;
    
    _pPhaseBuf[0] = 0;
    for (i = 1; i < nFftSize2; i++) {
        j = i * 2;
        
        xt1 = _pFftBufL[j];
        yt1 = _pFftBufL[j + 1];
        
        xt2 = _pFftBufR[j];
        yt2 = _pFftBufR[j + 1];
        
        float fPhase = atan2(xt2 * yt1 - xt1 * yt2, xt1 * xt2 + yt1 * yt2);
        
        if (fPhase - _pPhaseBuf[i] < -M_PI * 1.1)
            fPhase += 2 * M_PI;
        else if (fPhase - _pPhaseBuf[i] > M_PI * 1.1)
            fPhase -= 2 * M_PI;
        
        fPhase = fPhase * _fSmoothing1 + _pPhaseBuf[i] * _fSmoothing2;
        
        if (fPhase < -M_PI)
            fPhase += 2 * M_PI;
        else if (fPhase > M_PI)
            fPhase -= 2 * M_PI;
        
        _pPhaseBuf[i] = fPhase;
    }
    
    _nPhsPointCount = [self calcPhs:_pPhaseBuf :_pPhsPoint];
    
    [self dispPhsInfo];
}

- (int)calcPhs:(float *)pPhaseBuf :(CGPoint *)pPoint
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
    int nCenter = _nScaleHeight / 2;

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
        
        y = (int)(nCenter - (pPhaseBuf[i] / M_PI * nCenter) + 0.5);
        
        if (y < ymin)
            ymin = y;
        if (y > ymax)
            ymax = y;
    }
    
    return nPointCount;
}

- (void)drawDataPhs:(CGContextRef)context :(int)nChannel
{
    if (nChannel == 0) {
        if (_nPhsPointCount != 0) {
            DrawPolyline(context, _pPhsPoint, _nPhsPointCount, _colorPhase);
        }
        
        if (_nPhsDispFreq != 0) {
            DrawLine(context, _nPhsFreqPos, 0, _nPhsFreqPos, _nScaleHeight, _colorGreen);
            DrawLine(context, 0, _nPhsLevelPos, _nScaleWidth, _nPhsLevelPos, _colorGreen);
        }
    }
}

- (void)dispPhsInfo
{
    float *pBuf = _pPhaseBuf;
    
    if (g_oSetData.Fft.nFftScale == 0)
        _nPhsFreqPos = (int)((_pLogFreqTbl[_nPhsDispFreq] - _fLogMinFreq) * ((float)_nFrameWidth / (_fLogMaxFreq - _fLogMinFreq)));
    else
        _nPhsFreqPos = (int)((_fFreqStep * _nPhsDispFreq - _nMinFreq) * ((float)_nFrameWidth / (_nMaxFreq - _nMinFreq)));
    _nPhsLevelPos = (_nScaleHeight / 2) - (int)(pBuf[_nPhsDispFreq] / M_PI * _nScaleHeight / 2);
    
    if (_nPhsDispFreq == 0) {
        self.outletPeakLevelLeft.text = @"";
        self.outletPeakFreqLeft.text = @"";
    } else {
        self.outletPeakLevelLeft.text = [NSString stringWithFormat:@"%.2lf", pBuf[_nPhsDispFreq] / M_PI * 180];
        self.outletPeakFreqLeft.text = [NSString stringWithFormat:@"%.1lf",  _fFreqStep * _nPhsDispFreq];
    }
}

- (void)setDispFreqPhs:(CGPoint)point
{
    int n;
    
    if (g_oSetData.Fft.nFftScale == 0)
        n = (int)(exp((point.x - _nFrameLeft) * (_fLogMaxFreq - _fLogMinFreq) / _nScaleWidth + _fLogMinFreq) / _fFreqStep);
    else
        n = (int)(((point.x - _nFrameLeft) * (_nMaxFreq - _nMinFreq) / _nScaleWidth + _nMinFreq) / _fFreqStep);
    
    if (n > 1 && n < _nFftSize / 2)
        _nPhsDispFreq = n;
    else
        _nPhsDispFreq = 0;
    
    [self dispPhsInfo];
    [_viewFftScale setNeedsDisplay];
}

- (void)resetDispFreqPhs
{
    _nPhsDispFreq = 0;
    [self dispPhsInfo];
    [_viewFftScale setNeedsDisplay];
}

@end
