//
//  EditDataViewController.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/19.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EditDataViewControllerDelegate

- (void)closeEditImpulse:(int)impulseId;

@end

@interface EditDataViewController : UIViewController

@property (nonatomic, weak) id<EditDataViewControllerDelegate> delegate;
@property (nonatomic) int impulseId;

@end
