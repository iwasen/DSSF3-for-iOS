//
//  FreSubViewController.h
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2019/07/02.
//  Copyright © 2019 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Common.h"

NS_ASSUME_NONNULL_BEGIN

@interface FreSubViewController : UIViewController

@property (nonatomic, weak) IBOutlet CtButton *outletStartStop;
@property (nonatomic, weak) IBOutlet CtComboBox *outletSampleRate;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletChannel;
@property (nonatomic, weak) IBOutlet CtTextField *outletElapseTime;
@property (nonatomic, weak) IBOutlet CtTextField *outletMinLevel;
@property (nonatomic, weak) IBOutlet CtTextField *outletMaxLevel;

@end

NS_ASSUME_NONNULL_END
