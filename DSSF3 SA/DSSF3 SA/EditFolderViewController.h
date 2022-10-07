//
//  EditFolderViewController.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/18.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EditFolderViewControllerDelegate

- (void)closeEditFolder:(int)folderId;

@end

@interface EditFolderViewController : UIViewController

@property (nonatomic, weak) id<EditFolderViewControllerDelegate> delegate;
@property (nonatomic) int folderId;

@end
