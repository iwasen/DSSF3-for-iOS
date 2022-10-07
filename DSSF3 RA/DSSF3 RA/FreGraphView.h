//
//  FreGraphView.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/01.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FreDataView.h"

@protocol FreDrawGraphDelegate

- (void)drawGraphScale:(CGContextRef)context;
- (void)drawGraphData:(CGContextRef)context;

@end

@interface FreGraphView : UIView <FreDataViewDelegate>

@property (nonatomic, weak) IBOutlet id<FreDrawGraphDelegate> delegate;

- (void)initialize:(int)nMode :(int)nFreqStart :(int)nFreqEnd;
- (void)updateGraph;
- (void)updateData;
- (void)drawScale:(CGContextRef)context :(int)nFreqStart :(int)nFreqEnd;
- (void)drawData:(CGContextRef)context :(const float *)pLeftFre :(const float *)pRightFre :(const float *)pFreq :(int)nFreqCount :(int)nFreqStart :(int) nFreqEnd :(int)nFreqPoint;

@end
