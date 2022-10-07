//
//  EditDataViewController.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/19.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "EditDataViewController.h"
#import "FileIO.h"
#import "Controls.h"

@interface EditDataViewController ()

@property (nonatomic, weak) IBOutlet CtTextField *outletTitle;
@property (nonatomic, weak) IBOutlet CtTextField *outletComment;

@end

@implementation EditDataViewController
{
    DbImpulseRec _dbImpulseRec;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)viewWillAppear:(BOOL)animated
{
	CDbImpulse dbImpulse;

	if (dbImpulse.Open()) {
		dbImpulse.ReadRecID(_impulseId, &_dbImpulseRec);

		self.outletTitle.text = _dbImpulseRec.sTitle;
		self.outletComment.text = _dbImpulseRec.sComment;
	}
}

- (IBAction)onDone:(id)sender
{
	[self updateFolder];

	[self.delegate closeEditImpulse:_dbImpulseRec.nImpulseID];

	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onCancel:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateFolder
{
	CDbImpulse dbImpulse;

	if (dbImpulse.Open()) {
		_dbImpulseRec.sTitle = self.outletTitle.text;
		_dbImpulseRec.sComment = self.outletComment.text;

		dbImpulse.UpdateRec(&_dbImpulseRec);
	}
}

@end
