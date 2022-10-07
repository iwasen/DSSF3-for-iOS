//
//  FftCompareView.m
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2020/03/17.
//  Copyright © 2020 TRC. All rights reserved.
//

#import "FftCompareView.h"

@implementation FftCompareView

- (id)initWithDataView:(UIView *)dataView
{
    self = [super init];
    if (self) {
        self.hidden = YES;
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [dataView addSubview:self];

        [dataView addConstraints:@[
            [NSLayoutConstraint constraintWithItem:self
                 attribute:NSLayoutAttributeLeft
                 relatedBy:NSLayoutRelationEqual
                    toItem:dataView
                 attribute:NSLayoutAttributeLeft
                multiplier:1.0
                  constant:0.0],
            [NSLayoutConstraint constraintWithItem:self
                 attribute:NSLayoutAttributeTop
                 relatedBy:NSLayoutRelationEqual
                    toItem:dataView
                 attribute:NSLayoutAttributeTop
                multiplier:1.0
                  constant:0.0],
            [NSLayoutConstraint constraintWithItem:self
                 attribute:NSLayoutAttributeRight
                 relatedBy:NSLayoutRelationEqual
                    toItem:dataView
                 attribute:NSLayoutAttributeRight
                multiplier:1.0
                  constant:0.0],
            [NSLayoutConstraint constraintWithItem:self
                 attribute:NSLayoutAttributeBottom
                 relatedBy:NSLayoutRelationEqual
                    toItem:dataView
                 attribute:NSLayoutAttributeBottom
                multiplier:1.0
                  constant:0.0]
        ]];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetLineWidth(context, 1.0);
    CGContextSetShouldAntialias(context, NO);
    CGContextSetAllowsAntialiasing(context, NO);
    
    [_delegate setCompareColor];

    if (_leftChannel)
        [self.delegate drawDataView:context :0];
    
    if (_rightChannel)
        [self.delegate drawDataView:context :1];
    
    [_delegate restoreColor];
}

@end
