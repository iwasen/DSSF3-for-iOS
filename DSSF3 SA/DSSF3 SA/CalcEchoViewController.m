//
//  CalcEchoViewController.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/27.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "CalcEchoViewController.h"
#import "UIViewController+MJPopupViewController.h"

@interface CalcEchoViewController ()

@end

@implementation CalcEchoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

	self.outletTsubEnd.floatValue = _fTsubEnd;
	self.outletTsubAuto.checked = _bTsubAuto;
	self.outletTsubNoise.floatValue = _fTsubNoise;
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
	_fTsubEnd = self.outletTsubEnd.floatValue;
	_bTsubAuto = self.outletTsubAuto.checked;
	_fTsubNoise = self.outletTsubNoise.floatValue;

	[self.delegate onOK];
}

@end
