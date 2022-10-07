//
//  DstDataView.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/10.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DstDataViewDelegate

- (void)drawDataView:(CGContextRef)context;

@end

@interface DstDataView : UIView

@property (nonatomic, weak) id<DstDataViewDelegate> delegate;

@end
