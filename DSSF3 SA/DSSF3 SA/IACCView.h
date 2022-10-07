//
//  IACCView.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/06.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GraphView.h"

@interface IACCView : GraphView

- (void)initialize:(NSString *)title :(int)nRemark;
- (void)dispGraph:(CGContextRef)context :(const float *)pData :(int)nData :(float)fRate :(float)IACC :(float)TIACC :(float)WIACC1 :(float)WIACC2;

@end
