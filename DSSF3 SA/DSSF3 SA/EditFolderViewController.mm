//
//  EditFolderViewController.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/18.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "EditFolderViewController.h"
#import "FileIO.h"
#import "Controls.h"

@interface EditFolderViewController ()

@property (nonatomic, weak) IBOutlet CtTextField *outletTitle;
@property (nonatomic, weak) IBOutlet CtTextField *outletName;
@property (nonatomic, weak) IBOutlet CtTextField *outletPlace;
@property (nonatomic, weak) IBOutlet CtTextField *outletComment;
@property (nonatomic, weak) IBOutlet CtTextField *outletDate;
@property (nonatomic, weak) IBOutlet CtTextField *outletScale;

@end

@implementation EditFolderViewController
{
    DbFolderRec _dbFolderRec;
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
	CDbFolder dbFolder;

	if (dbFolder.Open()) {
		dbFolder.ReadRecID(_folderId, &_dbFolderRec);

		self.outletTitle.text = _dbFolderRec.sTitle;
		self.outletName.text = _dbFolderRec.sName;
		self.outletPlace.text = _dbFolderRec.sPlace;
		self.outletComment.text = _dbFolderRec.sComment;
		self.outletDate.text = FormatTime(_dbFolderRec.sDate);
		self.outletScale.floatValue = _dbFolderRec.fScale;
	}
}

- (IBAction)onDone:(id)sender
{
	[self updateFolder];

	[self.delegate closeEditFolder:_dbFolderRec.nFolderID];

	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onCancel:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateFolder
{
	CDbFolder dbFolder;

	if (dbFolder.Open()) {
		_dbFolderRec.sTitle = self.outletTitle.text;
		_dbFolderRec.sName = self.outletName.text;
		_dbFolderRec.sPlace = self.outletPlace.text;
		_dbFolderRec.sComment = self.outletComment.text;
		_dbFolderRec.sDate = [self.outletDate.text stringByReplacingOccurrencesOfString:@"/" withString:@""];
		_dbFolderRec.fScale = self.outletScale.floatValue;

		dbFolder.UpdateRec(&_dbFolderRec);
	}
}

@end
