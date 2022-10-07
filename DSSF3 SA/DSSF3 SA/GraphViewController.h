//
//  GraphViewController.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/13.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MDSpreadViewClasses.h"

@interface GraphViewController : UIViewController <MDSpreadViewDataSource, MDSpreadViewDelegate>

@property (nonatomic) int folderId;
@property (nonatomic) int impulseId;

- (void)changeData;

@end
