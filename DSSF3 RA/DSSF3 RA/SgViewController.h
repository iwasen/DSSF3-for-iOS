//
//  SgViewController.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/04/03.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioEx.h"

@interface SgViewController : UIViewController <AudioOutputData>

- (void)start;
- (void)stop;

@end
