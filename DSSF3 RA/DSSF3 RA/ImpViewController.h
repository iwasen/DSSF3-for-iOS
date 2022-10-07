//
//  ImpViewController.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/15.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Common.h"
#import "ImpView.h"
#import "SubViewController.h"
#import "AudioEx.h"

@interface ImpViewController : SubViewController <AudioInputData, AudioOutputData, ImpDrawGraphDelegate>

@end
