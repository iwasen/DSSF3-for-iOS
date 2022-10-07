//
//  RootViewController.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/13.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "RootViewController.h"
#import "GraphViewController.h"
#import "CalcViewController.h"

@implementation RootViewController
{
    int _folderId;
    int _dataId;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)showGraphView:(int)folderId :(int)dataId
{
	_folderId = folderId;
	_dataId = dataId;
	[self performSegueWithIdentifier:@"Graph" sender:self];
}

- (void)showCalcView:(int)folderId :(int)dataId
{
	_folderId = folderId;
	_dataId = dataId;
	[self performSegueWithIdentifier:@"Calculation" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"Graph"]) {
		GraphViewController *controller = segue.destinationViewController;
		controller.folderId = _folderId;
		controller.impulseId = _dataId;
	} else if ([segue.identifier isEqualToString:@"Calculation"]) {
		CalcViewController *controller = segue.destinationViewController;
		controller.folderId = _folderId;
		controller.impulseId = _dataId;
	}
}

@end
