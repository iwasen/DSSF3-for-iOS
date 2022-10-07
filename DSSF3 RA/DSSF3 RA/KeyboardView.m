//
//  KeyboardView.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/04/18.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "KeyboardView.h"

@implementation KeyboardView
{
    CGRect _rectKey[88];
    int _nOctave[88];
    int _nKey[88];
    BOOL _bKeyPress;
    BOOL _bMarker;
    CGRect _rectMarker;
}

- (void)layoutSubviews
{
	[super layoutSubviews];

	int i;

	CGSize size = self.frame.size;
	CGFloat nWhiteKeyWidth = size.width / 52;
	CGFloat nWhiteKeyHeight = size.height;
	CGFloat nBlackKeyWidth = nWhiteKeyWidth * 2 / 3;
	CGFloat nBlackKeyHeight = size.height * 2 / 3;

	int nOctave, nKey, nIndex;
	static const int tWhiteKey[7] = {0, 2, 4, 5, 7, 9, 11};
	static const int tBlackKey[5] = {1, 3, 6, 8, 10};

	for (i = 0; i < 52; i++) {
		nIndex = i + 36;
		_rectKey[nIndex] = CGRectMake(i * nWhiteKeyWidth, 0, nWhiteKeyWidth, nWhiteKeyHeight);
		_nOctave[nIndex] = (i + 5) / 7;
		_nKey[nIndex] = tWhiteKey[(i + 5) % 7];
	}

	static const int key[5] = {1, 2, 4, 5, 6};
	static const int pos[5] = {0, 1, 0, 0, 0};

	for (i = 0; i < 36; i++) {
		nOctave = (i + 4) / 5;
		nKey = (i + 4) % 5;
		CGFloat x = (nOctave * 7 + key[nKey] - 5) * nWhiteKeyWidth - nBlackKeyWidth / 2 + pos[nKey];

		nIndex = i;
		_rectKey[nIndex] = CGRectMake(x, 0, nBlackKeyWidth, nBlackKeyHeight);
		_nOctave[nIndex] = nOctave;
		_nKey[nIndex] = tBlackKey[nKey];
	}
}

- (void)drawRect:(CGRect)rect
{
	int i;

	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
	CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);

	for (i = 0; i < 52; i++)
		CGContextStrokeRect(context, _rectKey[i + 36]);

	for (i = 0; i < 36; i++)
		CGContextFillRect(context, _rectKey[i]);

	if (_bMarker) {
		CGContextSetFillColorWithColor(context, [UIColor greenColor].CGColor);
		CGContextFillRect(context, _rectMarker);
	}
}

- (void)setMarker:(int)nOctave :(int)nKey
{
	if (_bMarker) {
		[self setNeedsDisplayInRect:_rectMarker];
		_bMarker = NO;
	}

	for (int i = 0; i < 88; i++) {
		if (_nOctave[i] == nOctave && _nKey[i] == nKey) {
			_rectMarker = CGRectMake(_rectKey[i].origin.x + 1, _rectKey[i].size.height - 14, _rectKey[i].size.width - 2, 8);
/*
			switch (nKey) {
				case 1:
				case 3:
				case 6:
				case 8:
				case 10:
					break;
				default:
					_MarkerRect.left++;
					_MarkerRect.right--;
					break;
			}
*/
			[self setNeedsDisplayInRect:_rectMarker];

			_bMarker = YES;
			break;
		}
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	_bKeyPress = YES;
	[self notifyMessage:touches];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (_bKeyPress)
		[self notifyMessage:touches];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	_bKeyPress = NO;
	_touchKey = 0;
	_touchOctave = 0;
	[self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	_bKeyPress = NO;
}

- (void)notifyMessage:(NSSet *)touches
{
	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self];

	for (int i = 0; i < 88; i++) {
		if (CGRectContainsPoint(_rectKey[i], location)) {
			_touchKey = _nKey[i];
			_touchOctave = _nOctave[i];
			[self sendActionsForControlEvents:UIControlEventValueChanged];
			break;
		}
	}
}

@end
