//
//  DetailViewController.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/07.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FolderData.h"
#import "ImpData.h"
#import "EditDataViewController.h"
#import "I3DragBetweenHelper.h"

@interface DetailViewController : UITableViewController <UIPopoverControllerDelegate, EditDataViewControllerDelegate, I3DragBetweenDelegate>

@property (nonatomic) int folderId;

- (void)showDetail:(UIViewController *)masterViewController :(int)folderId :(int)selectedDataId;
//- (void)displayDataList:(int)selectedDataId;

@end

