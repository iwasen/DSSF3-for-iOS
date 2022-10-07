//
//  FftDataView.h
//  SoundTest
//
//  Created by 相沢伸一 on 2015/03/07.
//  Copyright (c) 2015年 aizawa. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FftDataViewDelegate

- (void)drawDataView:(CGContextRef)context :(int)channel;
- (void)setCompareColor;
- (void)restoreColor;

@end

@interface FftDataView : UIView

@property (nonatomic, weak) id<FftDataViewDelegate> delegate;
@property (nonatomic) BOOL leftChannel;
@property (nonatomic) BOOL rightChannel;

- (void)display;

@end
