//
//  RecordListViewController.h
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2017/01/30.
//  Copyright © 2017年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RecordListDelegate <NSObject>

- (void)loadFile:(UIViewController *)controller :(NSURL *)sourceURL;

@end

@interface RecordListViewController : UITableViewController

@property (nonatomic, weak) id<RecordListDelegate> delegate;
@property (nonatomic, strong) NSString *dir;
@property (nonatomic, assign) BOOL bUseiCloud;

@end
