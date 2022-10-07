//
//  EchoView.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/05.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GraphView.h"

@interface EchoView : GraphView

- (void)initialize:(NSString *)title;
- (void)dispGraph:(CGContextRef)context :(float)totalTime :(float)startTime :(float)dispTime :(const float *)pData :(const float *)pData2 :(int)nData :(float)fRate :(float)t0 :(float)t1 :(float)dev :(float)fEndTime :(int)nMaxLevel :(int)nMinLevel :(float)fT20Reg0 :(float)fT20Reg1 :(float)fT30Reg0 :(float)fT30Reg1 :(float)fEDTReg0 :(float)fEDTReg1;
- (void)dispEnergy:(CGContextRef)context :(float)totalTime :(float)startTime :(float)dispTime :(const float *)pData :(int)nData :(int)nMaxLevel :(int)nMinLevel;

@end
