//
//  CalcIACCViewController.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/28.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Controls.h"

@protocol CalcIACCViewControllerDelegate

- (void)onOK;

@end

@interface CalcIACCViewController : UIViewController

@property (nonatomic, weak) id<CalcIACCViewControllerDelegate> delegate;
@property (nonatomic) float fWIACCLevel;

@property (nonatomic, weak) IBOutlet CtTextField *outletWIACCLevel;

@end
