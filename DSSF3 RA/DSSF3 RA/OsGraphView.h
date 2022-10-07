//
//  OsGraphView.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/18.
//  Copyright (c) 2015年 aizawa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DrawView.h"
#import "OsDataView.h"

@interface OsGraphView : UIView <OsDataViewDelegate>

@property (nonatomic) int nHDiv;
@property (nonatomic) int nVDiv;

- (void)createDataView;
- (void)drawDataView:(CGContextRef)context;
- (void)dispScreen:(const float *)pLeftData :(const float *)pRightData :(float)fTotal :(int)nStart :(int)nData :(int)nChannel :(float)fLevelL :(float)fLevelR :(int)nPosL :(int)nPosR :(float)fOffset;
- (void)dispXY:(const float *)pLeftData :(const float *)pRightData :(int)nData :(float)fLevelL :(float)fLevelR :(int)nPosL :(int)nPosR;
- (void)clearScreen;
- (void)dispTriggerLevel:(int)nTrigLevel :(int)nChannel :(BOOL)bDraw;
- (void)dispText:(NSString*)text :(int)nLine;

@end
