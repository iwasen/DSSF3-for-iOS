//
//  FftCompareView.h
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2020/03/17.
//  Copyright © 2020 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FftCompareViewDelegate

- (void)drawDataView:(CGContextRef)context :(int)channel;
- (void)setCompareColor;
- (void)restoreColor;

@end

@interface FftCompareView : UIView

@property (nonatomic, weak) id<FftCompareViewDelegate> delegate;
@property (nonatomic) BOOL leftChannel;
@property (nonatomic) BOOL rightChannel;

- (id)initWithDataView:(UIView *)dataView;

@end

NS_ASSUME_NONNULL_END
