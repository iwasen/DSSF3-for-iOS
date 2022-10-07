//
//  DstSubViewController.m
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2019/07/03.
//  Copyright © 2019 TRC. All rights reserved.
//

#import "DstSubViewController.h"

@interface DstSubViewController ()

@property (nonatomic, weak) IBOutlet UIScrollView *outletScrollView;

@end

@implementation DstSubViewController

-(void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];

	if (IS_PHONE) {
		SetContentSize(self.outletScrollView);
	}
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
