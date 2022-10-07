//
//  DstSubViewController.h
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2019/07/03.
//  Copyright © 2019 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Common.h"

NS_ASSUME_NONNULL_BEGIN

@interface DstSubViewController : UIViewController

@property (nonatomic, weak) IBOutlet CtButton *outletStartStop;
@property (nonatomic, weak) IBOutlet CtComboBox *outletSampleRate;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletChannel;
@property (nonatomic, weak) IBOutlet CtComboBox *outletMaxHarmonics;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletScaleMode;
@property (nonatomic, weak) IBOutlet CtComboBox *outletScaleMax;
@property (nonatomic, weak) IBOutlet CtComboBox *outletScaleMin;
@property (nonatomic, weak) IBOutlet CtTextField *outletElapseTime;
@property (nonatomic, weak) IBOutlet CtComboBox *outletGuardTime;

@end

NS_ASSUME_NONNULL_END
