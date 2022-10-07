//
//  CalcProgressViewController.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/21.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CalcProgressViewControllerDelegate

- (void)onCancelCalculation;

@end

@interface CalcProgressViewController : UIViewController

@property (nonatomic, weak) id<CalcProgressViewControllerDelegate> delegate;

- (void)setProgress:(float)progress :(BOOL)animated;
- (void)setMessage:(NSString *)message;

@end
