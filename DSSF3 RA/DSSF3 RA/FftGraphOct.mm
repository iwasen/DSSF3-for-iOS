//
//  FftGraphOct.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/16.
//  Copyright (c) 2015年 aizawa. All rights reserved.
//

#import "FftViewController.h"

#define MIN_VALUE		-1000

@implementation FftViewController (Oct)

- (void)initOct
{
    int i, j;
    float fFreqLow, fFreqCenter, fFreqHigh;
    
    [_aFreqScale removeAllObjects];
    if (g_oSetData.Fft.nOctaveBand == 0) {
        // 1/1オクターブ
        //_aFreqScale[0] = g_pFreqScale1[0];
        [_aFreqScale insertObject:g_pFreqScale1[0] atIndex:0];
        _bOctScaleFlag[0] = 1;
        
        for (i = 0, j = 0; i < MAX_OCT1; i++) {
            fFreqLow = pow(2.0, i - 6.5) * 1000;
            if (fFreqLow >= _fFreqStep) {
                _fOctTbl[j] = fFreqLow;
                //_aFreqScale[++j] = g_pFreqScale1[i + 1];
                [_aFreqScale insertObject:g_pFreqScale1[i + 1] atIndex:++j];
                _bOctScaleFlag[j] = 1;
            }
        }
        _nOctBand = j;
        _fOctTbl[j] = 1000000.0;		// ストッパ
    } else {
        // 1/3オクターブ
        int nOct3 = g_nOctBandTbl[g_oSetData.Fft.nOctaveBand] / 3;
        int nBandPerDecade = 10 * nOct3;
        
        BOOL bFirstBand = NO;
        //_aFreqScale[0] = g_pFreqScale3[0];
        [_aFreqScale insertObject:g_pFreqScale3[0] atIndex:0];
        _bOctScaleFlag[0] = 0x03;
        
        for (i = 0, j = 0; i < MAX_OCT; i++) {
            fFreqLow = pow(10.0, (i - 0.5) / nBandPerDecade + 1.2);
            
            // 最初のデータの存在するバンドを取得
            if (!bFirstBand) {
                fFreqHigh = pow(10.0, (i + 0.5) / nBandPerDecade + 1.2);
                for (float fFreqMin = _fFreqStep; fFreqMin < fFreqHigh; fFreqMin += _fFreqStep) {
                    if (fFreqMin >= fFreqLow) {
                        bFirstBand = YES;
                        break;
                    }
                }
            }
            
            if (bFirstBand) {
                _fOctTbl[j] = fFreqLow;
                if (i % nOct3 == 0) {
                    int n = i / nOct3 + 1;
                    //_aFreqScale[++j] = g_pFreqScale3[n];
                    [_aFreqScale insertObject:g_pFreqScale3[n] atIndex:++j];
                    _bOctScaleFlag[j] = 0x01;
                    if (n == 9 || n == 19 || n == 29)
                        _bOctScaleFlag[j] |= 0x02;
                } else {
                    fFreqCenter = pow(10.0, (float)i / nBandPerDecade + 1.2);
                    if (fFreqCenter < 1000) {
                        //_aFreqScale[++j].Format("%g", (float)(int)(fFreqCenter * 2 + 0.5) / 2);
                        [_aFreqScale insertObject:[NSString stringWithFormat:@"%g", (float)(int)(fFreqCenter * 2 + 0.5) / 2] atIndex:++j];
                    } else {
                        //_aFreqScale[++j].Format("%.2fk", fFreqCenter / 1000);
                        [_aFreqScale insertObject:[NSString stringWithFormat:@"%.2fk", fFreqCenter / 1000] atIndex:++j];
                    }
                    _bOctScaleFlag[j] = 0;
                }
            }
            
            if (fFreqLow > _nMaxFreq)
                break;
        }
        _nOctBand = j;
        _fOctTbl[j] = 1000000.0;		// ストッパ
    }
    
    _nFrameLeft = 75 * _sizeGraphView.width / 768;
    _nFrameTop = 10;
    _nFrameRight = _sizeGraphView.width - 15;
    _nFrameBottom = _sizeGraphView.height - (75 * _sizeGraphView.width / 768);
    _nFrameWidth = _nFrameRight - _nFrameLeft;
    _nFrameHeight = _nFrameBottom - _nFrameTop;
    
    _nScaleWidth = _nFrameWidth;
    _fOctBarStep = (float)_nScaleWidth / _nOctBand;
    if (_fOctBarStep - (int)_fOctBarStep < 0.2)
        _fOctBarStep = (int)_fOctBarStep;
    
    if (_nViewMode == VM_OVERLAY)
        _nBarWidth = (int)(_fOctBarStep / 2.5);
    else
        _nBarWidth = (int)(_fOctBarStep / 1.5);
    
    if (_nBarWidth == 0)
        _nBarWidth = 1;
    
    if (_nViewMode != VM_SPLIT) {
        _nScaleHeight = _nFrameHeight;
    } else {
        _nScaleHeight = _nFrameHeight / 2 - _sizeGraphView.height / 50;
    }
    
    _aFftData[0]._bOctData = NO;
    _aFftData[1]._bOctData = NO;
    _aFftData[0]._nOctDispBand = 0;
    _aFftData[1]._nOctDispBand = 0;
    
    _bPeakReset = YES;
}

- (void)drawScaleOct:(CGRect)frame
{
    if (_nViewMode != VM_SPLIT) {
        [self drawScaleOctSub:_nFrameLeft :_nFrameTop :_nFrameRight :_nFrameBottom :YES :_nChannel == CH_STEREO ? @"Lch / Rch" : NULL];
    } else {
        [self drawScaleOctSub:_nFrameLeft :_nFrameTop :_nFrameRight :_nFrameTop + _nScaleHeight :NO :@"Lch"];
        [self drawScaleOctSub:_nFrameLeft :_nFrameBottom - _nScaleHeight :_nFrameRight :_nFrameBottom :YES :@"Rch"];
    }
}

- (void)drawScaleOctSub:(int)nLeft :(int)nTop :(int)nRight :(int)nBottom :(bool)bAxisX :(NSString *)pText
{
    int	nLevel;
    CGFloat y;
    int i, j;
    int nWidth = nRight - nLeft;
    int nHeight = nBottom - nTop;
    CGSize size;
    NSString *sText;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    DrawFillRect(context, nLeft, nTop, nWidth, nHeight, _colorWhite);
    DrawRectangle(context, nLeft - 1, nTop - 1, nRight + 1, nBottom + 1, _colorBlack);
    
    float xPos = nLeft + _fOctBarStep / 2;
    if (bAxisX && g_oSetData.Fft.nOctaveBand == 0) {
        for (i = 0; i < _nOctBand; i++) {
            size = [_aFreqScale[i] sizeWithAttributes:_fontAttrs];
            DrawString(_aFreqScale[i], xPos - size.width / 2, nBottom + 2 + (size.height + 2) / 2, _fontAttrs);
            xPos += _fOctBarStep;
        }
    } else {
        int nBarWidth = _nBarWidth;
        if (_nViewMode == VM_OVERLAY)
            nBarWidth *= 2;
        
        for (i = 0, j = 0; i < _nOctBand; i++) {
            if (_bOctScaleFlag[i]) {
                if (_bOctScaleFlag[i] & 2)
                    DrawFillRect(context, xPos - nBarWidth / 2, nTop, nBarWidth, nHeight, _colorOctBar);
                
                if (bAxisX) {
                    size = [_aFreqScale[i] sizeWithAttributes:_fontAttrs];
                    DrawString(_aFreqScale[i], xPos - size.width / 2, nBottom + 3 + (j + 1) % 2 * size.height, _fontAttrs);
                }
                j++;
            }
            xPos += _fOctBarStep;
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

- (void)setDispDataOct
{
    if (_bLch)
        [self calcOct:&_aFftData[0]];
    
    if (_bRch)
        [self calcOct:&_aFftData[1]];
    
    [self dispOctInfo];
}

- (void)calcOct:(FFTDATA *)pFftData
{
    int i;
    float *pFftPBuf = pFftData->_oPowerSpecBuf.GetBuf();
    float *pOctData = pFftData->_fOctData;
    float *pOctTbl = _fOctTbl;
    int nOctData[MAX_OCT];
    int t1, t2, t3;
    
    if (_nOctBand > 0) {
        memset(pOctData, 0, _nOctBand * sizeof(float));
        memset(nOctData, 0, _nOctBand * sizeof(int));
    }
    
    pOctData[0] = pFftData->_fFftAllPower ? dB10(pFftData->_fFftAllPower) : _nMinLevel;
    
    int tblp = 0;
    for (i = 1; i < _nFftSize / 2; i++) {
        while (i * _fFreqStep >= pOctTbl[tblp])
            tblp++;
        
        if (tblp >= 1 && tblp < _nOctBand) {
            pOctData[tblp] += pFftPBuf[i];
            nOctData[tblp]++;
        }
    }
    
    for (i = 1; i < _nOctBand; i++) {
        if (nOctData[i] != 0)
            pOctData[i] = pOctData[i] ? dB10(pOctData[i] / nOctData[i] * ((pOctTbl[i] - pOctTbl[i - 1]) / _fFreqStep)) : _nMinLevel;
    }
    
    for (i = 1; i < _nOctBand; i++) {
        if (nOctData[i] == 0) {
            for (t1 = i; t1 > 0 && nOctData[t1] == 0; t1--)
                ;
            for (t2 = i; t2 < _nOctBand && nOctData[t2] == 0; t2++)
                ;
            if (t1 > 0 && t2 < _nOctBand) {
                t3 = t2 - t1;
                pOctData[i] = (pOctData[t1] * (t2 - i) + pOctData[t2] * (i - t1)) / t3;
            } else
                pOctData[i] = MIN_VALUE;
        }
    }
    
    float *pPeakLevel = pFftData->_fOctPeakLevel;
    for (i = 0; i < _nOctBand; i++) {
        if (pOctData[i] > *pPeakLevel || _nPeakHoldTimer == 0)
            *pPeakLevel = pOctData[i];
        
        pPeakLevel++;
    }
    
    pFftData->_bOctData = YES;
}

- (void)drawDataOct:(CGContextRef)context :(int)nChannel
{
    if (nChannel == 0)
        [self drawDataOctSub:context :&_aFftData[0] :_colorLeft :_colorLeftPeak :_imageOctLeft :_imageOctPeakLeft :_nViewMode != VM_OVERLAY ? _nBarWidth / 2 : _nBarWidth];
    else
        [self drawDataOctSub:context :&_aFftData[1] :_colorRight :_colorRightPeak :_imageOctRight :_imageOctPeakRight :_nViewMode != VM_OVERLAY ? _nBarWidth / 2 : 0];
}

- (void)drawDataOctSub:(CGContextRef)context :(FFTDATA *)pFftData :(UIColor *)colorData :(UIColor *)colorPeak :(UIImage *)imageData :(UIImage *)imagePeak :(int)xOffset
{
    int i;
    float *pOctData;
    float *pPeakLevel;
    float xStep = _fOctBarStep;
    float yStep = (float)_nScaleHeight / (_nMinLevel - _nMaxLevel);
    float xPos;
    CGFloat top, left, right, bottom;
    UIColor *color;
    UIImage *image;
    float prevtop = 0;
    
    xPos = xStep / 2 - xOffset;
    
    if (pFftData->_bOctData) {
        pOctData = pFftData->_fOctData;
        pPeakLevel = pFftData->_fOctPeakLevel;
        for (i = 0; i < _nOctBand; i++) {
            left = xPos;
            top = (*pOctData++ - _nMaxLevel) * yStep;
            right = left + _nBarWidth;
            bottom = _nScaleHeight;
            
            if (i == pFftData->_nOctDispBand) {
                color = colorPeak;
                image = imagePeak;
            } else {
                color = colorData;
                image = imageData;
            }
            
            if (imageData != nil) {
                if (_nBarWidth == 1) {
                    DrawLine(context, left, top, left, bottom, color);
                } else if (_nBarWidth == 2) {
                    DrawRectangle(context, left, top, right, bottom, color);
                } else {
                    [image drawInRect:CGRectMake(left, top, right - left, bottom - top)];
                    DrawLine(context, left, top, right, top, color);
                }
            } else {
                float x = i * xStep;
                CGContextSetLineWidth(context, 2.0);
                if (i != 0) {
                    DrawLine(context, x, prevtop, x, top, color);
                }
                DrawLine(context, x, top, x + xStep, top, color);
                CGContextSetLineWidth(context, 1.0);
            }
            
            if (g_oSetData.Fft.bPeakHold) {
                top = (*pPeakLevel++ - _nMaxLevel) * yStep;
                bottom = top + 2;
                DrawFillRect(context, left, top, right - left, bottom - top, color);
            }
            
            prevtop = top;
            xPos += xStep;
        }
    }
}

- (void)dispOctInfo
{
    if (_bLch)
        [self dispOctInfoSub:&_aFftData[0] :self.outletPeakFreqLeft :self.outletPeakLevelLeft];
    
    if (_bRch)
        [self dispOctInfoSub:&_aFftData[1] :self.outletPeakFreqRight :self.outletPeakLevelRight];
}

- (void)dispOctInfoSub:(FFTDATA *)pFftData :(CtTextField *)freqTextField :(CtTextField *)levelTextField
{
    if (g_oSetData.Fft.bPeakDisp) {
        float *pOctData = pFftData->_fOctData;
        float maxLevel = MIN_VALUE;
        for (int i = 1; i < _nOctBand; i++) {
            if (pOctData[i] > maxLevel) {
                maxLevel = pOctData[i];
                pFftData->_nOctDispBand = i;
            }
        }
    }
    
    levelTextField.text = [NSString stringWithFormat:@"%.2lf", pFftData->_fOctData[pFftData->_nOctDispBand]];
    freqTextField.text = _aFreqScale[pFftData->_nOctDispBand];
}

- (void)setDispFreqOct:(CGPoint)point
{
    if (!g_oSetData.Fft.bPeakDisp) {
        int nBand = (int)((point.x - _nFrameLeft) / _fOctBarStep);
        if (nBand >= 0 && nBand < _nOctBand) {
            _aFftData[0]._nOctDispBand = nBand;
            _aFftData[1]._nOctDispBand = nBand;
            [self dispOctInfo];
            [_viewFftScale setNeedsDisplay];
        }
    }
}

- (void)resetDispFreqOct
{
    if (!g_oSetData.Fft.bPeakDisp) {
        _aFftData[0]._nOctDispBand = 0;
        _aFftData[1]._nOctDispBand = 0;
        [self dispOctInfo];
        [_viewFftScale setNeedsDisplay];
    }
}

@end
