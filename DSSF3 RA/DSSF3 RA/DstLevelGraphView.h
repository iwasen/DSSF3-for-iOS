//
//  DstLevelGraphView.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/13.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DstDataView.h"

@protocol DstDrawLevelGraphDelegate

- (void)drawGraphScale:(CGContextRef)context;
- (void)drawGraphData:(CGContextRef)context;

@end

@interface DstLevelGraphView : UIView <DstDataViewDelegate>

@property (nonatomic, weak) IBOutlet id<DstDrawLevelGraphDelegate> delegate;

- (void)initialize;
- (void)updateGraph;
- (void)updateData;
- (void)drawScale:(CGContextRef)context :(int)nLevelStart :(int)nLevelEnd;
- (void)drawData:(CGContextRef)context :(const float *)pLeftDst :(const float *)pRightDst :(const float *)pLevel :(int)nLevelCount :(int)nLevelStart :(int)nLevelEnd :(int)nLevelPoint;

@end
