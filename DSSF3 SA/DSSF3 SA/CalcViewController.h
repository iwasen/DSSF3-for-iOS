//
//  CalcViewController.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/20.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CalcProgressViewController.h"

@interface CalcViewController : UIViewController <CalcProgressViewControllerDelegate>

@property (nonatomic) int folderId;
@property (nonatomic) int impulseId;

@end
