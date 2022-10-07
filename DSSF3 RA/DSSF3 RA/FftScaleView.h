//
//  FftScaleView.h
//  SoundTest
//
//  Created by 相沢伸一 on 2015/03/07.
//  Copyright (c) 2015年 aizawa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FftDataView.h"
#import "DrawView.h"

@protocol FftScaleViewDelegate

- (void)drawScaleView:(CGContextRef)context;
- (void)touchesScaleView:(CGPoint)point;

@end

@interface FftScaleView : UIView

@property (nonatomic, weak) id<FftScaleViewDelegate, FftDataViewDelegate> delegate;

@end
