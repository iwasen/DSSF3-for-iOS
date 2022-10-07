//
//  MainViewController.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/08.
//  Copyright (c) 2015年 aizawa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RtaView.h"
#import "AudioEx.h"

@interface MainViewController : UIViewController <AudioInputData, AudioOutputData>

@property (nonatomic, weak) IBOutlet RtaView *outletRtaView;
@property (nonatomic, weak) IBOutlet UIView *outletContainerView;

- (void)setMainTitle:(NSString *)subTitle;

@end

