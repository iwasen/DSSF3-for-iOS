//
//  CtSlider.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/04/07.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "CtSlider.h"

#define IS_PAD      ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#define IS_PHONE    ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)

#define SLIDER_HIGHT    40
#define TIC_MARGIN      16
#define TIC_TEXT_SIZE	16

@interface SliderTic : NSObject

@property (nonatomic) int position;
@property (nonatomic) NSString *text;

@end

@implementation SliderTic

@end

@implementation CtSlider
{
    UISlider *_slider;
    NSMutableArray *_tics;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self _setup1];
	}
	return self;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	[self _setup2];
	self.backgroundColor = [UIColor clearColor];
}

- (void)prepareForInterfaceBuilder
{
	[super prepareForInterfaceBuilder];

	[self _setup1];
	[self _setup2];
}

- (void)_setup1
{
	_tics = [NSMutableArray array];
	_slider = [[UISlider alloc] init];
}

- (void)_setup2
{
	_slider.minimumValue = _minValue;
    _slider.maximumValue = _maxValue;

    [_slider addTarget:self action:@selector(changeValue:) forControlEvents:UIControlEventValueChanged];
    [_slider addTarget:self action:@selector(touchUp:) forControlEvents:UIControlEventTouchUpInside];
    [_slider addTarget:self action:@selector(touchUp:) forControlEvents:UIControlEventTouchUpOutside];

    [self addSubview:_slider];
}

- (void)layoutSubviews
{
	[super layoutSubviews];

	_slider.transform = CGAffineTransformMakeRotation(0);
	_slider.frame = [self getSliderFrame:self.frame.size];

	if (_vertical)
		_slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
}

- (CGRect)getSliderFrame:(CGSize)size
{
	CGRect frame = CGRectMake(0, 0, 0, 0);

    if (_vertical) {
        switch (_ticPosition) {
            case 0:
            case 1:
                frame = CGRectMake((SLIDER_HIGHT - size.height) / 2, (size.height - SLIDER_HIGHT) / 2, size.height, SLIDER_HIGHT);
                break;
            case 2:
                frame = CGRectMake((SLIDER_HIGHT - size.height) / 2 + (size.width - SLIDER_HIGHT), (size.height - SLIDER_HIGHT) / 2, size.height, SLIDER_HIGHT);
                break;
            case 3:
                frame = CGRectMake((SLIDER_HIGHT - size.height) / 2 + (size.width - SLIDER_HIGHT) / 2, (size.height - SLIDER_HIGHT) / 2, size.height, SLIDER_HIGHT);
                break;
        }
    } else {
        switch (_ticPosition) {
            case 0:
            case 1:
                frame = CGRectMake(0, 0, size.width, SLIDER_HIGHT);
                break;
            case 2:
                frame = CGRectMake(0, size.height - SLIDER_HIGHT, size.width, SLIDER_HIGHT);
                break;
            case 3:
                frame = CGRectMake(0, (size.height - SLIDER_HIGHT) / 2, size.width, SLIDER_HIGHT);
                break;
        }
    }
    
    return frame;
}

- (void)changeValue:(UISlider *)sender
{
    int value = floor(sender.value + 0.5);
    sender.value = value;
    if (value != _value) {
        _value = value;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (void)touchUp:(UISlider *)sender
{
    sender.value = floor(sender.value + 0.5);
    [self sendActionsForControlEvents:UIControlEventTouchDragExit];
}

- (void)drawRect:(CGRect)rect
{
	CGFloat width, height;
    CGRect rectTic;

    if (_vertical) {
        width = (_ticLength != 0) ? _ticLength : rect.size.width - SLIDER_HIGHT;
        height = rect.size.height - TIC_MARGIN * 2;
        switch (_ticPosition) {
            case 1:
                rectTic = CGRectMake(SLIDER_HIGHT, TIC_MARGIN, width, height);
                [self drawTic:rectTic];
				[self drawText:rectTic];
                break;
            case 2:
                rectTic = CGRectMake(rect.size.width - (width + SLIDER_HIGHT), TIC_MARGIN, width, height);
                [self drawTic:rectTic];
				[self drawText:rectTic];
                break;
            case 3:
                rectTic = CGRectMake(width / 2 + SLIDER_HIGHT, TIC_MARGIN, width / 2, height);
                [self drawTic:rectTic];

                rectTic = CGRectMake(0, TIC_MARGIN, width / 2, height);
                [self drawTic:rectTic];
                break;
            default:
                return;
        }
    } else {
        width = rect.size.width - TIC_MARGIN * 2;
        height = (_ticLength != 0) ? _ticLength : rect.size.height - SLIDER_HIGHT;
        switch (_ticPosition) {
            case 1:
                rectTic = CGRectMake(TIC_MARGIN, SLIDER_HIGHT, width, height);
                [self drawTic:rectTic];
				[self drawText:rectTic];
                break;
            case 2:
                rectTic = CGRectMake(TIC_MARGIN, rect.size.height - (height + SLIDER_HIGHT), width, height);
                [self drawTic:rectTic];
				[self drawText:rectTic];
                break;
            case 3:
                rectTic = CGRectMake(TIC_MARGIN, height / 2 + SLIDER_HIGHT, width, height / 2);
                [self drawTic:rectTic];

                rectTic = CGRectMake(TIC_MARGIN, 0, width, height / 2);
                [self drawTic:rectTic];
                break;
            default:
                return;
        }
    }
}

- (void)drawTic:(CGRect)rectTic
{
    int range = _maxValue - _minValue;

    if (range > 0 && rectTic.size.width > 0 && rectTic.size.height > 0 && _ticFreq > 0) {
        CGFloat x, y;
		
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetStrokeColorWithColor(context, self.enabled ? [UIColor grayColor].CGColor : [UIColor lightGrayColor].CGColor);

		if (_tics.count == 0) {
			CGPoint segments[(range / _ticFreq + 1) * 2];

			int count = 0;
			for (int i = 0; i <= range; i += _ticFreq) {
				if (_vertical) {
					x = rectTic.origin.x;
					y = rectTic.origin.y + (rectTic.size.height - i * rectTic.size.height / range);
					segments[count++] = CGPointMake(x, y);
					segments[count++] = CGPointMake(x + rectTic.size.width, y);
				} else {
					x = rectTic.origin.x + i * rectTic.size.width / range;
					y = rectTic.origin.y;
					segments[count++] = CGPointMake(x, y);
					segments[count++] = CGPointMake(x, y + rectTic.size.height);
				}
			}
			CGContextStrokeLineSegments(context, segments, count);
		} else {
			CGPoint segments[_tics.count * 2];

			int count = 0;
			for (SliderTic *sliderTic in _tics) {
				if (_vertical) {
					x = rectTic.origin.x;
					y = rectTic.origin.y + (rectTic.size.height - (sliderTic.position - _minValue) * rectTic.size.height / range);
					segments[count++] = CGPointMake(x, y);
					segments[count++] = CGPointMake(x + rectTic.size.width, y);
				} else {
					x = rectTic.origin.x + (sliderTic.position - _minValue) * rectTic.size.width / range;
					y = rectTic.origin.y;
					segments[count++] = CGPointMake(x, y);
					segments[count++] = CGPointMake(x, y + rectTic.size.height);
				}
			}
			CGContextStrokeLineSegments(context, segments, count);
		}
    }
}

- (void)drawText:(CGRect)rectTic
{
	if (_tics.count != 0) {
		CGFloat x, y;
		int range = _maxValue - _minValue;
		NSDictionary *fontAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
								   [UIFont systemFontOfSize:IS_PHONE ? TIC_TEXT_SIZE * 0.9 : TIC_TEXT_SIZE], NSFontAttributeName,
								   nil];

		for (SliderTic *sliderTic in _tics) {
			if (sliderTic.text != nil) {
				CGSize size = [sliderTic.text sizeWithAttributes:fontAttrs];
				if (_vertical) {
					x = rectTic.origin.x - 5 - size.width;
					y = rectTic.origin.y + (rectTic.size.height - (sliderTic.position - _minValue) * rectTic.size.height / range) - size.height / 2;
				} else {
					x = rectTic.origin.x + (sliderTic.position - _minValue) * rectTic.size.width / range - size.width / 2;
					y = rectTic.origin.y + rectTic.size.height;
				}
				[sliderTic.text drawAtPoint:CGPointMake(x, y) withAttributes:fontAttrs];
			}
		}
	}
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    _slider.enabled = enabled;
}

- (void)setSliderValue:(int)value
{
    _value = value;
    _slider.value = _value;
}

- (void)setMinValue:(int)minValue
{
    _minValue = minValue;
    _slider.minimumValue = _minValue;
}

- (void)setMaxValue:(int)maxValue
{
    _maxValue = maxValue;
    _slider.maximumValue = _maxValue;
}

- (void)clearTics
{
    [_tics removeAllObjects];
}

- (void)addTic:(CGFloat)position :(NSString *)text
{
    SliderTic *tic = [[SliderTic alloc] init];
    tic.position = position;
    tic.text = text;
    [_tics addObject:tic];
}

@end
