//
//  MtfView.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/12.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GraphView.h"

@interface MtfView : GraphView

- (void)initialize:(NSString *)title :(int)nRemark :(UIColor *)color;
- (void)dispGraph:(CGContextRef)context :(const float *)pMtfData :(const float *)pMtfFreq;

@end
