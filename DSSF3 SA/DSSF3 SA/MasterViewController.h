//
//  MasterViewController.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/07.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EditFolderViewController.h"

@interface MasterViewController : UITableViewController <UIPopoverControllerDelegate, EditFolderViewControllerDelegate>

- (void)reloadFolderList:(int)folderId :(int)selectedDataId;
- (int)getFolderIdFromIndexPath:(NSIndexPath *)indexPath;
- (void)dragOver:(NSIndexPath *)index;

@end

