//
//  DstFreqGraphView.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/10.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DstDataView.h"

@protocol DstDrawFreqGraphDelegate

- (void)drawGraphScale:(CGContextRef)context;
- (void)drawGraphData:(CGContextRef)context;

@end

@interface DstFreqGraphView : UIView <DstDataViewDelegate>

@property (nonatomic, weak) IBOutlet id<DstDrawFreqGraphDelegate> delegate;

- (void)initialize;
- (void)updateGraph;
- (void)updateData;
- (void)drawScale:(CGContextRef)context :(int)nFreqStart :(int)nFreqEnd;
- (void)drawData:(CGContextRef)context :(const float *)pLeftDst :(const float *)pRightDst :(const float *)pFreq :(int)nFreqCount :(int)nFreqStart :(int)nFreqEnd :(int)nFreqPoint;

@end
