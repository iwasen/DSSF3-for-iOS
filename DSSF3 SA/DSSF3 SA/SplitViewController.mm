//
//  SplitViewController.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/09/01.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "SplitViewController.h"
#import "VersionViewController.h"
#import "UIViewController+MJPopupViewController.h"
#import "GLobal.h"

@implementation SplitViewController
{
    VersionViewController *_versionViewController;
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
- (void)viewDidLoad
{
    // for iOS14
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        appearance.backgroundColor = [UIColor whiteColor];
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    }
}

- (IBAction)onVersionButton:(id)sender
{
    _versionViewController = [[VersionViewController alloc] initWithNibName:IS_PHONE ? @"VersionView_iPhone" : @"VersionView_iPad" bundle:nil];
	_versionViewController.parent = self;
	if (_versionViewController.view.frame.size.width > self.view.frame.size.width)
		_versionViewController.view.frame = CGRectMake(10, 0, self.view.frame.size.width, _versionViewController.view.frame.size.height);
	[self presentPopupViewController:_versionViewController animationType:MJPopupViewAnimationFade enableBackground:YES];
}

@end
