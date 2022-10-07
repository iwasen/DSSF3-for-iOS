//
//  CalcProgressViewController.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/21.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "CalcProgressViewController.h"

@interface CalcProgressViewController ()

@property (nonatomic, weak) IBOutlet UIProgressView *outletProgressBar;
@property (nonatomic, weak) IBOutlet UILabel *outletMessage;

@end

@implementation CalcProgressViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.outletProgressBar.transform = CGAffineTransformMakeScale(1.0, 3.0);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)setProgress:(float)progress :(BOOL)animated
{
	[self.outletProgressBar setProgress:progress animated:animated];
}

- (void)setMessage:(NSString *)message
{
	self.outletMessage.text = message;
}

- (IBAction)onCancelButton:(id)sender
{
	[self.delegate onCancelCalculation];
}

@end
