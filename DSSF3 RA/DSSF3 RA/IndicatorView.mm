//
//  IndicatorView.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/21.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "IndicatorView.h"
#import "Common.h"

@implementation IndicatorView
{
    int nChannel;
    UIImage *_imageLeft;
    UIImage *_imageRight;
    CGFloat _fLevelLeft;
    CGFloat _fLevelRight;
    CGFloat _fPrevLeft;
    CGFloat _fPrevRight;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGFloat height = self.bounds.size.height / 2;
    
    [_imageLeft drawInRect:CGRectMake(0, 0, _fLevelLeft, height)];
    [_imageRight drawInRect:CGRectMake(0, height, _fLevelRight, height)];
}

- (void)awakeFromNib
{
	[super awakeFromNib];

    _imageLeft = [UIImage imageNamed:@"IndicatorLeft.png"];
    _imageRight = [UIImage imageNamed:@"IndicatorRight.png"];
}

- (void)clear
{
    _fLevelLeft = 0;
    _fLevelRight = 0;
    _fPrevLeft = 0;
    _fPrevRight = 0;
    
    [self setNeedsDisplay];
}

- (void)inputAudioData:(AudioData *)audioData
{
    CGRect rect;
    float fMaxData;
    
    fMaxData = GetMaxData(audioData->pLeftData, audioData->nDataSize);
    if (fMaxData != 0)
        _fLevelLeft = self.bounds.size.width * (RTA_MIN_LEVEL - dB20(fMaxData)) / RTA_MIN_LEVEL;
    else
        _fLevelLeft = 0;
    
    if (_fLevelLeft < 0)
        _fLevelLeft = 0;
    
    if (audioData->nChannel == 2) {
        fMaxData = GetMaxData(audioData->pRightData, audioData->nDataSize);
        if (fMaxData != 0)
            _fLevelRight = self.bounds.size.width * (RTA_MIN_LEVEL - dB20(fMaxData)) / RTA_MIN_LEVEL;
        else
            _fLevelRight = 0;
        
        if (_fLevelRight < 0)
            _fLevelRight = 0;
    } else {
        _fLevelRight = _fLevelLeft;
    }

	CGFloat leftMin = fmin(_fPrevLeft, _fLevelLeft);
	CGFloat leftMax = fmax(_fPrevLeft, _fLevelLeft);
	CGFloat rightMin = fmin(_fPrevRight, _fLevelRight);
	CGFloat rightMax = fmax(_fPrevRight, _fLevelRight);

	rect.origin.y = 0;
	rect.origin.x = fmin(leftMin, rightMin);
	rect.size.width = fmax(leftMax, rightMax) - rect.origin.x;
	rect.size.height = self.bounds.size.height;
	[self setNeedsDisplayInRect:rect];

	_fPrevLeft = _fLevelLeft;
	_fPrevRight = _fLevelRight;
}

@end
