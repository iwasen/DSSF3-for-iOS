//
//  MasterViewController.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/07.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "AppDelegate.h"
#import "FolderData.h"
#import "Common.h"
#import "FileIO.h"

@implementation MasterViewController
{
    NSMutableArray *_folderList;
    int _selectedDataId;
    NSIndexPath *_draggingIndex;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	self.clearsSelectionOnViewWillAppear = NO;
	self.preferredContentSize = CGSizeMake(320.0, 600.0);
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	_folderList = [[NSMutableArray alloc] init];
	[self displayFolderList:-1];

	self.navigationItem.rightBarButtonItem = self.editButtonItem;

	self.title = NSLocalizedString(@"IDS_FOLDER", nil);
}

- (void)displayFolderList:(int)selectedFolderId
{
	CDbFolder dbFolder;
	DbFolderRec dbFolderRec;
	CDbImpulse dbImpulse;
	NSMutableArray *folderList = [[NSMutableArray alloc] init];

	if (dbFolder.Open()) {
		while (dbFolder.ReadRecNext(&dbFolderRec)) {
			if (dbFolderRec.sType[0] == FOLDER_TYPE_IR) {
				FolderData *folderData = [[FolderData alloc] init];
				folderData.folderId = dbFolderRec.nFolderID;
				folderData.title = dbFolderRec.sTitle;
				[folderList addObject:folderData];
			}
		}
	}

	[_folderList removeAllObjects];
	[_folderList addObjectsFromArray:[folderList sortedArrayUsingComparator:^(FolderData *obj1, FolderData *obj2) {
		return [obj1.title compare:obj2.title];}]];

	if (dbImpulse.Open()) {
		LONG nRec;
		CString str;
		str.Format("#%d=%ld", dbImpulse.m_nIdxFolderID, 0);
		dbImpulse.DBSelect(str, &nRec);
		if (nRec != 0) {
			FolderData *folderData = [[FolderData alloc] init];
			folderData.folderId = 0;
			folderData.title = @"Inbox";
			[_folderList insertObject:folderData atIndex:0];
		}
	}

	[self.tableView reloadData];

	if (selectedFolderId != -1) {
		int selectedRow = -1;
		for (int i = 0; i < _folderList.count; i++) {
			if (((FolderData *)_folderList[i]).folderId == selectedFolderId) {
				selectedRow = i;
				break;
			}
		}

		[self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:selectedRow inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
	}
}

- (void)reloadFolderList:(int)folderId :(int)selectedDataId
{
	[self displayFolderList:folderId];

	_selectedDataId = selectedDataId;
	[self performSegueWithIdentifier:@"showDetail" sender:self];
}

- (void)insertNewObject:(id)sender
{
	CDbFolder dbFolder;
	if (dbFolder.Open()) {
		DbFolderRec dbFolderRec;
		int newFolderId;
		int index = 0;

		if (_folderList.count != 0 && ((FolderData *)_folderList[0]).folderId == 0)
			index = 1;

		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.dateFormat = @"yyyyMMdd";

		dbFolder.GetNewID(&newFolderId);
		dbFolderRec.sType = "I";
		dbFolderRec.nFolderID = newFolderId;
		dbFolderRec.sTitle = "New folder";
		dbFolderRec.sDate = [dateFormatter stringFromDate:[NSDate date]];
		dbFolderRec.fScale = 1.0;
		dbFolder.StoreRec(&dbFolderRec);

		FolderData *folderData = [[FolderData alloc] init];
		folderData.folderId = newFolderId;
		folderData.title = dbFolderRec.sTitle;
		[_folderList insertObject:folderData atIndex:index];

		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
		[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([[segue identifier] isEqualToString:@"showDetail"]) {
	    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
	    FolderData *folderData = _folderList[indexPath.row];
	    DetailViewController *detailViewController = (DetailViewController *)[[segue destinationViewController] topViewController];
		[detailViewController showDetail:self :folderData.folderId :[sender isKindOfClass:MasterViewController.class] ? _selectedDataId : -1];
//	    controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
//	    controller.navigationItem.leftItemsSupplementBackButton = YES;
	}
}

- (void)closeEditFolder:(int)folderId
{
	[self displayFolderList:folderId];
}

#pragma mark - Table View

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    FolderData *folderData = _folderList[indexPath.row];
    cell.textLabel.text = folderData.title;
//    cell.editingAccessoryType = UITableViewCellAccessoryDetailButton;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView.editing) {
        FolderData *folderData = _folderList[indexPath.row];
        if (folderData.folderId != 0) {
            EditFolderViewController *editFolderViewController = [[EditFolderViewController alloc] initWithNibName:@"EditFolder" bundle:nil];
            editFolderViewController.preferredContentSize = editFolderViewController.view.bounds.size;
            editFolderViewController.delegate = self;
            editFolderViewController.folderId = folderData.folderId;

            editFolderViewController.modalPresentationStyle = UIModalPresentationPopover;
            editFolderViewController.popoverPresentationController.sourceView = self.view;
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            editFolderViewController.popoverPresentationController.sourceRect = cell.frame;
            [self presentViewController:editFolderViewController animated: YES completion: nil];
        }
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return _folderList.count;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	FolderData *folderData = _folderList[indexPath.row];
	return folderData.folderId != 0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		FolderData *folderData = _folderList[indexPath.row];
		DeleteFolder(folderData.folderId);

		[_folderList removeObjectAtIndex:indexPath.row];
	    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing:editing animated:animated];
	[self.tableView setEditing:editing animated:YES];
	if (editing) { // 現在編集モードです。
		UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																					target:self action:@selector(insertNewObject:)];
		[self.navigationItem setLeftBarButtonItem:addButton animated:YES]; // 追加ボタンを表示します。
	} else { // 現在通常モードです。
		[self.navigationItem setLeftBarButtonItem:nil animated:YES]; // 追加ボタンを非表示にします。
	}
}

- (void)dragOver:(NSIndexPath *)index
{
	if (_draggingIndex != nil) {
		UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:_draggingIndex];
		cell.backgroundColor = [UIColor whiteColor];
	}

	if (index != nil) {
		UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:index];
		if (!cell.selected) {
			cell.backgroundColor = [UIColor colorWithRed:1.0 green:0.8 blue:0.6 alpha:1.0];
		}
	}

	_draggingIndex = index;
}

- (int)getFolderIdFromIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row >= 0 && indexPath.row < _folderList.count)
		return ((FolderData *)_folderList[indexPath.row]).folderId;
	else
		return 0;
}

@end
