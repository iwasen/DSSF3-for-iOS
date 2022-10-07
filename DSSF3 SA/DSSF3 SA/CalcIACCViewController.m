//
//  CalcIACCViewController.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/28.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "CalcIACCViewController.h"

@interface CalcIACCViewController ()

@end

@implementation CalcIACCViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	self.outletWIACCLevel.floatValue = _fWIACCLevel;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)onOK:(id)sender
{
	_fWIACCLevel = self.outletWIACCLevel.floatValue;

	[self.delegate onOK];
}

@end
