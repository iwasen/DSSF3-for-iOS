//
//  FreDataView.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/05.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FreDataViewDelegate

- (void)drawDataView:(CGContextRef)context;

@end

@interface FreDataView : UIView

@property (nonatomic, weak) id<FreDataViewDelegate> delegate;

@end
