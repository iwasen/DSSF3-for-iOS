//
//  OsDataView.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/18.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OsDataViewDelegate

- (void)drawDataView:(CGContextRef)context;

@end

@interface OsDataView : UIView

@property (nonatomic, weak) id<OsDataViewDelegate> delegate;

@end
