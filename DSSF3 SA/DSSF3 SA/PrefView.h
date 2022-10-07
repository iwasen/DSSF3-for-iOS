//
//  PrefView.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/10.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GraphView.h"

@interface PrefView : GraphView

- (void)initialize;
- (void)dispGraph:(CGContextRef)context :(const float *)pData :(int)nData :(float)maxTauE :(float)maxS;

@end
