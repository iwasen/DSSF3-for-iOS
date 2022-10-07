//
//  OsDataView.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/18.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "OsDataView.h"
#import "OsGraphView.h"

@implementation OsDataView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetLineWidth(context, 1);
    CGContextSetAllowsAntialiasing(context, NO);
    CGContextSetShouldAntialias(context, NO);

    [self.delegate drawDataView:context];
}

@end
