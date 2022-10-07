//
//  OsGraphView.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/18.
//  Copyright (c) 2015年 aizawa. All rights reserved.
//

#import "OsGraphView.h"
#import "Common.h"

#define COLOR_XY	RGB(0, 224, 64)

@implementation OsGraphView
{
    OsDataView *_viewOsData;
    int _nWidth, _nHeight;
    int _nScaleDiv;
    int _nScaleLeft, _nScaleTop, _nScaleRight, _nScaleBottom;
    int _nScaleWidth, _nScaleHeight;
    int _nScaleHCenter, _nScaleVCenter;
    int _nTrigLevel;
    BOOL _bTrigLevel;
    int _nTrigChannel;
    CGPoint *_pPointBufL, *_pPointBufR, *_pPointBufXY;
    int _nPointCntL, _nPointCntR, _nPointCntXY;
    int _nPointBufSize;
    int _nChannel;
    BOOL _bLch;
    BOOL _bRch;
    UIColor *_colorBlack;
    UIColor *_colorGray;
    UIColor *_colorLightGray;
    UIColor *_colorLeft;
    UIColor *_colorRight;
    UIColor *_colorLeftZero;
    UIColor *_colorRightZero;
    UIColor *_colorXY;
    UIColor *_colorTrig;
    NSString *_sScreenText[2];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    int i;
    CGFloat x, y;
    UIColor *color;
    CGSize size;
    
    CGContextRef context = UIGraphicsGetCurrentContext();

	DrawFillRect(context, _nScaleLeft, _nScaleTop, _nScaleWidth, _nScaleHeight, [UIColor whiteColor]);

    for (i = 1; i < _nVDiv * 5; i++) {
        y = _nScaleTop + i * _nScaleDiv / 5;
        if (i == _nVDiv / 2 * 5)
            color = _colorGray;
        else
            color = _colorLightGray;
        
        if (i % 5 == 0) {
            DrawLine(context, _nScaleLeft, y, _nScaleRight, y, color);
        } else {
            DrawLine(context, _nScaleHCenter - 3, y, _nScaleHCenter + 3, y, color);
        }
    }
    
    for (i = 1; i < _nHDiv * 5; i++) {
        x = _nScaleLeft + i * _nScaleDiv / 5;
        if ((i - _nHDiv / 2 * 5) % 25 == 0)
            color = _colorGray;
        else
            color = _colorLightGray;
        
        if (i % 5 == 0) {
            DrawLine(context, x, _nScaleTop, x, _nScaleBottom, color);
        } else {
            DrawLine(context, x, _nScaleVCenter - 3, x, _nScaleVCenter + 3, color);
        }
    }
    
    DrawRectangle(context, _nScaleLeft, _nScaleTop, _nScaleRight, _nScaleBottom, _colorBlack);
    
    if (!g_oSetData.Os.bXY && g_oSetData.Os.bZeroLevel)
        [self dispCenterLine:context];
    
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           [UIFont systemFontOfSize:AdjustFontSize(FONT_SIZE_OS)], NSFontAttributeName,
                           nil];

    for (i = 0; i < 2; i++) {
        NSString *text = _sScreenText[i];
        
        if (text != nil) {
            size = [text sizeWithAttributes:attrs];
            y = (size.height + 2) * i + 10;
            
            DrawString(text, _nScaleLeft, y, attrs);
        }
    }
    
    if (_bTrigLevel) {
        CGPoint point[4];
        y = _nScaleVCenter - _nTrigLevel * _nScaleHeight / 100;

        point[0] = CGPointMake(_nScaleLeft - 9, y - 4);
        point[1] = CGPointMake(_nScaleLeft - 1, y);
        point[2] = CGPointMake(_nScaleLeft - 9, y + 4);
        point[3] = CGPointMake(_nScaleLeft - 9, y - 4);
        DrawPolygon(context, point, 4, _nTrigChannel == 0 ? _colorLeft : _colorRight, _colorTrig);
    }
}

- (void)dispCenterLine:(CGContextRef)context
{
    //CPen *pPenOrg = dc.SelectObject(&_penLeftZero);
    
    if (_bLch) {
        int nLeftPos = _nScaleVCenter - (g_oSetData.Os.nPosL * _nScaleHeight / 100);
        //dc.MoveTo(_nScaleLeft, nLeftPos);
        //dc.LineTo(_nScaleRight, nLeftPos);
       DrawLine(context, _nScaleLeft, nLeftPos, _nScaleRight, nLeftPos, _colorLeftZero);
    }
    
    if (_bRch) {
        int nRightPos = _nScaleVCenter - (g_oSetData.Os.nPosR * _nScaleHeight / 100);
        //dc.SelectObject(&_penRightZero);
        //dc.MoveTo(_nScaleLeft, nRightPos);
        //dc.LineTo(_nScaleRight, nRightPos);
       DrawLine(context, _nScaleLeft, nRightPos, _nScaleRight, nRightPos, _colorRightZero);
    }
    
    //dc.SelectObject(pPenOrg);
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _colorBlack = [[UIColor alloc] COLOR_BLACK];
    _colorGray = [[UIColor alloc] COLOR_GRAY];
    _colorLightGray = [[UIColor alloc] COLOR_LIGHTGRAY];
    _colorLeft = [[UIColor alloc] COLOR_LEFT];
    _colorRight = [[UIColor alloc] COLOR_RIGHT];
    _colorLeftZero = [[UIColor alloc] COLOR_LEFT_ZERO];
    _colorRightZero = [[UIColor alloc] COLOR_RIGHT_ZERO];
    _colorXY = [[UIColor alloc] COLOR_XY];
    _colorTrig = [[UIColor alloc] COLOR_GREEN];

    [self createDataView];
}

- (void)createDataView
{
    
    CGRect rect;
    rect = self.bounds;
    
    _nWidth = rect.size.width;
    _nHeight = rect.size.height;
    
    _nVDiv = 10;
    _nScaleDiv = (_nHeight - 90) / _nVDiv;
    _nHDiv = (_nWidth - 40) / (_nScaleDiv * 2) * 2;
    _nScaleWidth = _nScaleDiv * _nHDiv;
    _nScaleHeight = _nScaleDiv * _nVDiv;
    _nScaleLeft = (_nWidth - _nScaleWidth) / 2;
    _nScaleTop = (_nHeight - _nScaleHeight) * 2 / 3;
    _nScaleRight = _nScaleLeft + _nScaleWidth;
    _nScaleBottom = _nScaleTop + _nScaleHeight;
    _nScaleHCenter = _nScaleLeft + _nScaleWidth / 2;
    _nScaleVCenter = _nScaleTop + _nScaleHeight / 2;

    [_viewOsData removeFromSuperview];
    _viewOsData = [[OsDataView alloc] initWithFrame:CGRectMake(_nScaleLeft, _nScaleTop, _nScaleWidth, _nScaleHeight)];
    _viewOsData.delegate = self;
    [self addSubview:_viewOsData];
}

- (void)dealloc
{
    [self freeOverlayBuf];
}

- (void)allocWave
{
    [self freeOverlayBuf];
    
    int nBufSize = _nScaleWidth * 2 + 2;
    
    if (_bLch)
        _pPointBufL = new CGPoint[nBufSize];
    
    if (_bRch)
        _pPointBufR = new CGPoint[nBufSize];
}

- (void)allocXY:(int)nData
{
    [self freeOverlayBuf];
    
    _nPointBufSize = nData;
    
    _pPointBufXY = new CGPoint[_nPointBufSize];
}

- (void)freeOverlayBuf
{
    if (_pPointBufL != NULL) {
        delete [] _pPointBufL;
        _pPointBufL = NULL;
    }
    
    if (_pPointBufR != NULL) {
        delete [] _pPointBufR;
        _pPointBufR = NULL;
    }
    
    if (_pPointBufXY != NULL) {
        delete [] _pPointBufXY;
        _pPointBufXY = NULL;
    }
}

- (void)resetPointCnt
{
    _nPointCntL = 0;
    _nPointCntR = 0;
    _nPointCntXY = 0;
    
    [self setNeedsDisplay];
}

- (void)dispScreen:(const float *)pLeftData :(const float *)pRightData :(float)fTotal :(int)nStart :(int)nData :(int)nChannel :(float)fLevelL :(float)fLevelR :(int)nPosL :(int)nPosR :(float)fOffset
{
    int i;
    int x, x2;
    CGFloat y;
    CGPoint *pPoint;
    int nPoint;
    int nMin = 0, nMax = 0;
    
    if ((_pPointBufL == NULL && _pPointBufR == NULL) || nChannel != _nChannel) {
        _nChannel = nChannel;
        _bLch = (nChannel != CH_RIGHT_ONLY);
        _bRch = (nChannel == CH_STEREO || nChannel == CH_RIGHT_ONLY);
        
        [self allocWave];
        [self resetPointCnt];
    }
    
    int xMin = (int)((nStart + fOffset) * _nScaleWidth / fTotal + 0.5);
    int xMax = (int)((nStart + nData + fOffset) * _nScaleWidth / fTotal + 0.5);
    
    if (_bLch) {
        pPoint = _pPointBufL;
        nPoint = (nStart <= 0) ? 0 : _nPointCntL;
        
        x2 = 0;
        for (i = 0; i < nData && x2 <= _nScaleRight; i++) {
            x = (nStart + i + fOffset) * _nScaleWidth / fTotal;
            y = _nScaleHeight / 2 - ((pLeftData[i] * _nScaleDiv / fLevelL) + (_nScaleHeight * nPosL / 100));
            
            if ((int)x != (int)x2) {
                if (x2 != 0) {
                    pPoint[nPoint].x = x2;
                    pPoint[nPoint].y = nMin;
                    nPoint++;
                    if (nMin != nMax) {
                        pPoint[nPoint].x = x2;
                        pPoint[nPoint].y = nMax;
                        nPoint++;
                    }
                }
                
                x2 = x;
                nMin = nMax = y;
            } else {
                if (y < nMin)
                    nMin = y;
                if (y > nMax)
                    nMax = y;
            }
            
            //if (y < yMin)
                //yMin = y;
            //if (y > yMax)
                //yMax = y;
        }
        
        _nPointCntL = nPoint;
    }

    if (_bRch) {
        pPoint = _pPointBufR;
        nPoint = (nStart <= 0) ? 0 : _nPointCntR;
        
        x2 = 0;
        for (i = 0; i < nData && x2 <= _nScaleRight; i++) {
            x = (nStart + i + fOffset) * _nScaleWidth / fTotal;
            y = _nScaleHeight / 2 - ((pRightData[i] * _nScaleDiv / fLevelR) + (_nScaleHeight * nPosR / 100));
            
            if ((int)x != (int)x2) {
                if (x2 != 0) {
                    pPoint[nPoint].x = x2;
                    pPoint[nPoint].y = nMin;
                    nPoint++;
                    if (nMin != nMax) {
                        pPoint[nPoint].x = x2;
                        pPoint[nPoint].y = nMax;
                        nPoint++;
                    }
                }
                
                x2 = x;
                nMin = nMax = y;
            } else {
                if (y < nMin)
                    nMin = y;
                if (y > nMax)
                    nMax = y;
            }
        }
        
        _nPointCntR = nPoint;
    }
    
    [_viewOsData setNeedsDisplayInRect:CGRectMake(xMin - 1, 0, xMax - xMin + 1, _nScaleHeight)];
}

- (void)dispXY:(const float *)pLeftData :(const float *)pRightData :(int)nData :(float)fLevelL :(float)fLevelR :(int)nPosL :(int)nPosR
{
    int i;
    int x, y;
    CGPoint *pPoint;
    
    if (_pPointBufXY == NULL || _nPointBufSize != nData) {
        [self allocXY:nData];
        [self resetPointCnt];
    }
    
    pPoint = _pPointBufXY;

    int x2 = INT_MAX;
    int y2 = INT_MAX;
    int count = 0;
    for (i = 0; i < nData; i++) {
        x = _nScaleWidth / 2 + ((int)(pLeftData[i] * _nScaleDiv / fLevelL) + (_nScaleHeight * nPosL / 100));
        y = _nScaleHeight / 2 - ((int)(pRightData[i] * _nScaleDiv / fLevelR) + (_nScaleHeight * nPosR / 100));
        if (x != x2 || y != y2) {
            _pPointBufXY[count++] = CGPointMake(x, y);

            x2 = x;
            y2 = y;
        }
    }
    
    _nPointCntXY = count;

    [_viewOsData setNeedsDisplay];
}

- (void)drawDataView:(CGContextRef)context;
{
    if (_nPointCntL)
        DrawPolyline(context, _pPointBufL, _nPointCntL, _colorLeft);
    
    if (_nPointCntR)
        DrawPolyline(context, _pPointBufR, _nPointCntR, _colorRight);
    
    if (_nPointCntXY)
        DrawPolyline(context, _pPointBufXY, _nPointCntXY, _colorXY);
}

- (void)clearScreen
{
    [self resetPointCnt];
}

- (void)dispTriggerLevel:(int)nTrigLevel :(int)nChannel :(BOOL)bDraw
{
    int y;
    CGRect rect;
    
    if (_bTrigLevel) {
        y = _nScaleVCenter - _nTrigLevel * _nScaleHeight / 100;
        rect = CGRectMake(_nScaleLeft - 10, y - 5, 10, 10);
        [self setNeedsDisplayInRect:rect];
    }
    
    if (bDraw) {
        y = _nScaleVCenter - nTrigLevel * _nScaleHeight / 100;
        rect = CGRectMake(_nScaleLeft - 10, y - 5, 10, 10);
        [self setNeedsDisplayInRect:rect];
    }
    
    _nTrigLevel = nTrigLevel;
    _nTrigChannel = nChannel;
    _bTrigLevel = bDraw;
}

- (void)dispText:(NSString *)text :(int)nLine
{
    _sScreenText[nLine] = [[NSString alloc] initWithString:text];
}

@end
