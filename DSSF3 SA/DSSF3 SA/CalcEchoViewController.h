//
//  CalcEchoViewController.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/27.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Controls.h"

@protocol CalcEchoViewControllerDelegate

- (void)onOK;

@end

@interface CalcEchoViewController : UIViewController

@property (nonatomic, weak) id<CalcEchoViewControllerDelegate> delegate;
@property (nonatomic) float fTsubEnd;
@property (nonatomic) BOOL bTsubAuto;
@property (nonatomic) float fTsubNoise;

@property (nonatomic, weak) IBOutlet CtTextField *outletTsubNoise;
@property (nonatomic, weak) IBOutlet CtTextField *outletTsubEnd;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletTsubAuto;

@end
