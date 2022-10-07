//
//  CalibrationViewController.h
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2016/12/14.
//  Copyright © 2016年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FreqView.h"

@protocol CalibrationViewDelegate

- (void)setMicCalID:(int)nMicCalID;

@end

@interface CalibrationViewController : UIViewController <GraphViewDelegate>

@property (nonatomic) int nMicCalID;
@property (nonatomic, weak) id<CalibrationViewDelegate> delegate;
@property (nonatomic, weak) IBOutlet UIScrollView *outletScrollView;

@end
