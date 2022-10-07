//
//  FftGraph3dd.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/23.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "FftViewController.h"

@implementation FftViewController (tdd)

- (void)init3dd
{
    int i, j;
    int dx, dy;
    
    _nFrameLeft = 75 * _sizeGraphView.width / 768;
    _nFrameTop = 10;
    _nFrameRight = _sizeGraphView.width - (55 * _sizeGraphView.width / 768);
    _nFrameBottom = _sizeGraphView.height - 50;
    _nFrameWidth = _nFrameRight - _nFrameLeft;
    _nFrameHeight = _nFrameBottom - _nFrameTop;
    
    if (_nViewMode != VM_SPLIT) {
        _dx = _nFrameWidth / 5 / g_oSetData.Fft.nTimeDataNum;
        _dy = _dx * 5 / 3;
    } else {
        _dx = _nFrameWidth / 8 / g_oSetData.Fft.nTimeDataNum;
        _dy = _dx;
    }
    dx = _dx * g_oSetData.Fft.nTimeDataNum;
    dy = _dy * g_oSetData.Fft.nTimeDataNum;
    
    if (_nViewMode != VM_SPLIT) {
        _nScaleWidth = _nFrameWidth;
        _nScaleHeight = _nFrameHeight;
        _nScaleWidth2 = _nScaleWidth - dx;
        _nScaleHeight2 = _nScaleHeight - dy;
    } else {
        _nScaleWidth = _nFrameWidth;
        _nScaleHeight = _nFrameHeight / 2 - _sizeGraphView.height / 50;
        _nScaleWidth2 = _nScaleWidth - dx;
        _nScaleHeight2 = _nScaleHeight - dy;
    }
    
    for (i = 0; i < 2; i++) {
        FFTDATA &oFftData = _aFftData[i];
        
        for (j = 0; j < g_oSetData.Fft.nTimeDataNum; j++) {
            if (oFftData._p3ddPoint[j] == NULL)
                oFftData._p3ddPoint[j] = new CGPoint[_nScaleWidth2 + 2];
            
            oFftData._n3ddPointCount[j] = 0;
        }
        
        oFftData._n3ddCurrentPtr = 0;
    }
    
    if (_p3ddWork == NULL)
        _p3ddWork = new CGPoint[_nScaleWidth2 * 2 + 2];
    
    if (_p3ddCheckTbl == NULL)
        _p3ddCheckTbl = new int[_nScaleWidth];
}

- (void)drawScale3dd:(CGRect)frame
{
    if (_nViewMode != VM_SPLIT) {
        [self drawScale3ddSub:_nFrameLeft :_nFrameTop :_nFrameRight :_nFrameBottom :YES :_nChannel == CH_STEREO ? @"Lch / Rch" : NULL];
    } else {
        [self drawScale3ddSub:_nFrameLeft :_nFrameTop :_nFrameRight :_nFrameTop + _nScaleHeight :NO :@"Lch"];
        [self drawScale3ddSub:_nFrameLeft :_nFrameBottom - _nScaleHeight :_nFrameRight :_nFrameBottom :YES :@"Rch"];
    }
}

- (void)drawScale3ddSub:(int)nLeft :(int)nTop :(int)nRight :(int)nBottom :(bool)bAxisX :(NSString *)pText
{
    int	nFreq, nLevel;
    float t;
    int i;
    CGFloat x, y;
    NSString *sText;
    CGSize size;
    int nLeft1 = nLeft, nTop1 = nTop, nRight1 = nLeft + _nScaleWidth2, nBottom1 = nTop + _nScaleHeight2;
    int nLeft2 = nRight - _nScaleWidth2, nTop2 = nBottom - _nScaleHeight2, nRight2 = nRight, nBottom2 = nBottom;
    int nHeight = nBottom1 - nTop1;
    
    CGPoint point[7];
    point[0] = CGPointMake(nLeft2, nBottom2);
    point[1] = CGPointMake(nLeft1, nBottom1);
    point[2] = CGPointMake(nLeft1, nTop1);
    point[3] = CGPointMake(nRight1, nTop1);
    point[4] = CGPointMake(nRight2, nTop2);
    point[5] = CGPointMake(nRight2, nBottom2);
    point[6] = CGPointMake(nLeft2, nBottom2);

    CGContextRef context = UIGraphicsGetCurrentContext();
    
    DrawFillPath(context, point, 7, _colorWhite);
    
    DrawLine(context, nRight1, nBottom1, nLeft1, nBottom1, _colorGray);
    DrawLine(context, nRight1, nBottom1, nRight1, nTop1, _colorGray);
    DrawLine(context, nRight1, nBottom1, nRight2, nBottom2, _colorGray);
    
    if (g_oSetData.Fft.nFftScale == 0) {
        int step = GetLogScaleStep(_nMinFreq);
        float fSpanFreq = _fLogMaxFreq - _fLogMinFreq;
        for (nFreq = GetScaleStartValue(_nMinFreq, step); nFreq <= _nMaxFreq; nFreq += GetLogScaleStep(nFreq)) {
            x =  nLeft2 + ((log((float)nFreq) - _fLogMinFreq) * _nScaleWidth2 / fSpanFreq);
            
            if (x > nLeft2 && x < nRight2) {
                DrawLine(context, x, nBottom2 - 4, x, nBottom2, _colorGray);
            }
            
            if (bAxisX) {
                if (nFreq < 1000)
                    sText = [NSString stringWithFormat:@"%d", nFreq];
                else
                    sText = [NSString stringWithFormat:@"%dk", nFreq / 1000];
                if ([sText characterAtIndex:0] == '1' || [sText characterAtIndex:0] == '2' || [sText characterAtIndex:0] == '5') {
                    size = [sText sizeWithAttributes:_fontAttrs];
                    DrawString(sText, x - size.width / 2, nBottom2 + 3, _fontAttrs);
                }
            }
        }
    } else {
        int step = GetLinearScaleStep(_nMaxFreq, _nMinFreq, (int)(_nScaleWidth2 * 0.75));
        float fSpanFreq = _nMaxFreq - _nMinFreq;
        for (nFreq = GetScaleStartValue(_nMinFreq, step); nFreq <= _nMaxFreq; nFreq += step) {
            x = nLeft2 + ((nFreq - _nMinFreq) * _nScaleWidth2 / fSpanFreq);
            
            if (x > nLeft2 && x < nRight2) {
                DrawLine(context, x, nBottom2 - 4, x, nBottom2, _colorGray);
            }
            
            if (bAxisX) {
                if (nFreq < 1000)
                    sText = [NSString stringWithFormat:@"%d", nFreq];
                else
                    sText = [NSString stringWithFormat:@"%gk", (float)nFreq / 1000];
                size = [sText sizeWithAttributes:_fontAttrs];
                DrawString(sText, x - size.width / 2, nBottom2 + 3, _fontAttrs);
            }
        }
    }
    
    int step = GetLinearScaleStep(_nMaxLevel, _nMinLevel, _nScaleHeight);
    float fSpanLevel = _nMaxLevel - _nMinLevel;
    for (nLevel = GetScaleStartValue(_nMinLevel, step); nLevel <= _nMaxLevel; nLevel += step) {
        sText = [NSString stringWithFormat:@"%d", nLevel];
        size = [sText sizeWithAttributes:_fontAttrs];
        
        y = nTop + ((_nMaxLevel - nLevel) * _nScaleHeight2 / fSpanLevel);
        DrawLine(context, nLeft, y, nLeft + 4, y, _colorGray);
        DrawString(sText, nLeft - size.width - 5, y - size.height / 2, _fontAttrs);
        
        y = nTop2 + ((_nMaxLevel - nLevel) * _nScaleHeight2 / fSpanLevel);
        DrawLine(context, nRight2, y, nRight2 - 4, y, _colorGray);
        DrawString(sText, nRight2 + 4, y - size.height / 2, _fontAttrs);
    }
    
    for (i = 0; i < g_oSetData.Fft.nTimeDataNum; i++) {
        x = nLeft2 - _dx * i;
        y = nBottom2 - _dy * i;
        DrawLine(context, x, y, x + 4, y, _colorGray);
    }
    
    DrawPolyline(context, point, 7, _colorBlack);

    t = _fTimeStep * g_oSetData.Fft.nTimeDataNum / g_oSetData.Fft.nTimeRes;
    if (t < 1.0)
        sText = [NSString stringWithFormat:@"t=%.1fms", t * 1000];
    else
        sText = [NSString stringWithFormat:@"t=%.3fs", t];
    size = [sText sizeWithAttributes:_fontAttrs];
    DrawString(sText, nLeft2 - size.width - 30, nBottom2 - size.height - 10, _fontAttrs);
    
    if (bAxisX) {
        sText = NSLocalizedString(@"IDS_FREQUENCY", nil);
        sText = [sText stringByAppendingString:@" [Hz]"];
        size = [sText sizeWithAttributes:_fontAttrs];
        DrawString(sText, nLeft2 + (_nScaleWidth2 - size.width) / 2, _sizeGraphView.height - size.height - 4, _fontAttrs);
    }
    
    sText = NSLocalizedString(@"IDS_SPL", nil);
    sText = [sText stringByAppendingString:@" [dB]"];
    size = [sText sizeWithAttributes:_fontAttrs];
    DrawRotateString(context, sText, 4, (nHeight - size.width) / 2 - nBottom1, _fontAttrs);
    
    [self drawNote:pText :nTop :nRight1];
}

- (void)setDispData3dd
{
    if (_bLch) {
        [self calc3dd:&_aFftData[0]];
        [self disp3ddInfo:&_aFftData[0] :self.outletPeakFreqLeft :self.outletPeakLevelLeft];
    }
    
    if (_bRch) {
        [self calc3dd:&_aFftData[1]];
        [self disp3ddInfo:&_aFftData[1] :self.outletPeakFreqRight :self.outletPeakLevelRight];
    }
}

- (void)calc3dd:(FFTDATA *)pFftData
{
    int i, j;
    int nPtr = pFftData->_n3ddCurrentPtr;
    CGPoint *pPoint = pFftData->_p3ddPoint[nPtr];
    float *pFftPBuf = pFftData->_oPowerSpecBuf.GetBuf();
    int x;
    CGFloat y;
    int x2 = 0;
    float fStepY = float(_nScaleHeight2) / (_nMinLevel - _nMaxLevel);
    float fTmp1 = float(_nScaleWidth2) / (_fLogMaxFreq - _fLogMinFreq);
    float fTmp2 = float(_nScaleWidth2) / (_nMaxFreq - _nMinFreq);
    int nFftSize2 = _nFftSize / 2;
    float fLevel = 0;
    float fLevel2 = pFftPBuf[0];
    int nLevelCounter = 0;
    int nPointCount = 0;
    int dx, xj;
    float dl;
    float t;
    
    pPoint[nPointCount].x = 0;
    pPoint[nPointCount].y = _nScaleHeight2;
    nPointCount++;
    
    for (i = 0; i < nFftSize2; i++) {
        if (g_oSetData.Fft.nFftScale == 0)
            x = int((_pLogFreqTbl[i] - _fLogMinFreq) * fTmp1 + 0.5);
        else
            x = int((i * _fFreqStep - _nMinFreq) * fTmp2 + 0.5);
        
        fLevel += pFftPBuf[i];
        nLevelCounter++;
        
        if (x != x2) {
            fLevel /= nLevelCounter;
            
            if (fLevel2 == 0)
                fLevel2 = fLevel;
            
            dx = x - x2;
            dl = fLevel - fLevel2;
            for (j = 0; j < dx; j++) {
                xj = x2 + j;
                if (xj >= 0 && xj < _nScaleWidth2) {
                    t = fLevel2 + dl * j / dx;
                    if (t > 0) {
                        y = (dB10(t) - _nMaxLevel) * fStepY;
                        if (y > _nScaleHeight2)
                            y = _nScaleHeight2;
                    } else
                        y = _nScaleHeight2;
                    pPoint[nPointCount] = CGPointMake(xj, y);
                    nPointCount++;
                }
            }
            
            x2 = x;
            fLevel2 = fLevel;
            fLevel = 0;
            nLevelCounter = 0;
        }
    }
    
    pPoint[nPointCount].x = _nScaleWidth2 - 1;
    pPoint[nPointCount].y = _nScaleHeight2;
    nPointCount++;
    
    pFftData->_n3ddPointCount[nPtr] = nPointCount;
    
    if (++(pFftData->_n3ddCurrentPtr) >= g_oSetData.Fft.nTimeDataNum)
        pFftData->_n3ddCurrentPtr = 0;
}

- (void)drawData3dd:(CGContextRef)context :(int)nChannel
{
    if (nChannel == 0)
        [self drawData3ddSub:context :&_aFftData[0] :_colorLeft];
    else
        [self drawData3ddSub:context :&_aFftData[1] :_colorRight];
}

- (void)drawData3ddSub:(CGContextRef)context :(FFTDATA *)pFftData :(UIColor *)colorData
{
    int i, j, nPtr, nPointCount, nPointCount2, n;
    int x, x2;
    int y, y2;
    CGPoint *pPoint;
    BOOL flag = NO;
    
    for (i = 0; i < _nScaleWidth; i++)
        _p3ddCheckTbl[i] = _nScaleHeight;

    nPtr = pFftData->_n3ddCurrentPtr;
    for (i = 0; i < g_oSetData.Fft.nTimeDataNum; i++) {
        n = g_oSetData.Fft.nTimeDataNum - i;
        if (g_oSetData.Fft.nTimeDir != 0) {
            if (--nPtr < 0)
                nPtr = g_oSetData.Fft.nTimeDataNum - 1;
        }
        
        x2 = y2 = -1;
        nPointCount = pFftData->_n3ddPointCount[nPtr];
        nPointCount2 = 0;
        pPoint = pFftData->_p3ddPoint[nPtr] + nPointCount - 1;
        for (j = 0; j < nPointCount; j++) {
            x = pPoint->x + _dx * n;
            y = pPoint->y + _dy * n;

            if (_p3ddCheckTbl[x] > y)
                _p3ddCheckTbl[x] = y;

            if (_p3ddCheckTbl[x] == y || flag) {
                if (x2 != -1) {
                    _p3ddWork[nPointCount2] = CGPointMake(x2, y2);
                    nPointCount2++;

                    _p3ddWork[nPointCount2] = CGPointMake(x, _p3ddCheckTbl[x]);
                    nPointCount2++;
                }
                
                flag = (_p3ddCheckTbl[x] == y);
            }
            
            x2 = x;
            y2 = _p3ddCheckTbl[x];
            
            pPoint--;
        }
        
        if (nPointCount2 != 0)
            DrawLineSegments(context, _p3ddWork, nPointCount2, colorData);
        
        if (g_oSetData.Fft.nTimeDir == 0) {
            if (++nPtr >= g_oSetData.Fft.nTimeDataNum)
                nPtr = 0;
        }
    }
}

- (void)disp3ddInfo:(const FFTDATA *)pFftData :(CtTextField *)freqTextField :(CtTextField *)levelTextField
{
    if (pFftData->_fFftAllPower != 0)
        levelTextField.text = [NSString stringWithFormat:@"%.2lf", dB10(pFftData->_fFftAllPower)];
    freqTextField.text = @"ALL";
}

@end
