//
//  VersionViewController.m
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2015/09/01.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "VersionViewController.h"
#import "UIViewController+MJPopupViewController.h"

@interface VersionViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *outletIconImageView;

@end

@implementation VersionViewController

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)onClose:(id)sender
{
	[self.parent dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
}

@end
