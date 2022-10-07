//
//  DetailViewController.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/07.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "DetailViewController.h"
#import "MasterViewController.h"
#import "AppDelegate.h"
#import "RootViewController.h"
#import "Common.h"
#import "FileIO.h"

@implementation DetailViewController
{
    NSMutableArray *_dataList;
    BOOL _reload;
    __weak MasterViewController *_masterViewController;
    I3DragBetweenHelper *_helper;
}

#pragma mark - Managing the detail item

- (void)showDetail:(UIViewController *)masterViewController :(int)folderId :(int)selectedDataId
{
	if (_dataList == nil)
		_dataList = [[NSMutableArray alloc] init];

	_masterViewController = (MasterViewController *)masterViewController;
    _folderId = folderId;
	        
	[self displayDataList:selectedDataId];
}

- (void)displayDataList:(int)selectedDataId
{
	CDbImpulse dbImpulse;
	CDbAcParam dbAcParam;
	DbImpulseRec dbImpulseRec;

	[_dataList removeAllObjects];

	if (dbImpulse.Open() && dbAcParam.Open()) {
		dbImpulse.DBChgIdx(dbImpulse.m_nIdxImpulseID);

		LONG nRec;
		CString str;
		str.Format("#%d=%ld", dbImpulse.m_nIdxFolderID, _folderId);
		dbImpulse.DBSelect(str, &nRec);

		while (dbImpulse.ReadRecNext(&dbImpulseRec)) {
			ImpData *impData = [[ImpData alloc] init];
			impData.dataId = dbImpulseRec.nImpulseID;
			impData.title = dbImpulseRec.sTitle;
			impData.date = FormatTime(dbImpulseRec.sTime);
			impData.comment = dbImpulseRec.sComment;
			impData.calculated = dbAcParam.SearchID(dbImpulseRec.nImpulseID) != 0;
			[_dataList addObject:impData];
		}
	}

	[self.tableView reloadData];

	if (selectedDataId != -1) {
		int selectedRow = -1;
		for (int i = 0; i < _dataList.count; i++) {
			if (((ImpData *)_dataList[i]).dataId == selectedDataId) {
				selectedRow = i;
				break;
			}
		}

		[self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:selectedRow inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
	}
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.title = NSLocalizedString(@"IDS_DATA", nil);
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	if (IS_PHONE) {
		UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"IDS_CALC", nil) style:UIBarButtonItemStylePlain target:self action:@selector(onCalculation:)];
		self.navigationItem.rightBarButtonItems = @[self.editButtonItem, leftBarButtonItem];
	} else {
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"IDS_CALC", nil) style:UIBarButtonItemStylePlain target:self action:@selector(onCalculation:)];
		self.navigationItem.rightBarButtonItem = self.editButtonItem;
	}

	if (_dataList.count != 0) {
		self.navigationItem.leftBarButtonItem.enabled = YES;
		self.navigationItem.rightBarButtonItem.enabled = YES;
	} else {
		self.navigationItem.leftBarButtonItem.enabled = NO;
		self.navigationItem.rightBarButtonItem.enabled = NO;
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	if (_reload) {
		_reload = NO;
		[self displayDataList:-1];
	}
}

- (IBAction)onCalculation:(id)sender
{
	AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	RootViewController *rootViewController = (RootViewController *)appDelegate.window.rootViewController;

//	ImpData *impData = _dataList[indexPath.row];
	[rootViewController showCalcView:_folderId :0];

	_reload = YES;
}

- (void)closeEditImpulse:(int)impulseId
{
	[self displayDataList:impulseId];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return _dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

	ImpData *impData = _dataList[indexPath.row];
	cell.textLabel.text = impData.title;
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@  %@", impData.date, impData.comment];
	if (impData.calculated)
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView.editing) {
		EditDataViewController *editDataViewController = [[EditDataViewController alloc] initWithNibName:@"EditData" bundle:nil];
		editDataViewController.preferredContentSize = editDataViewController.view.bounds.size;
		ImpData *impData = _dataList[indexPath.row];
		editDataViewController.delegate = self;
		editDataViewController.impulseId = impData.dataId;

		editDataViewController.modalPresentationStyle = UIModalPresentationPopover;
		editDataViewController.popoverPresentationController.sourceView = self.view;
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		editDataViewController.popoverPresentationController.sourceRect = cell.frame;
		[self presentViewController:editDataViewController animated: YES completion: nil];
	} else {
		AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		RootViewController *rootViewController = (RootViewController *)appDelegate.window.rootViewController;

		ImpData *impData = _dataList[indexPath.row];
		[rootViewController showGraphView:_folderId :impData.dataId];
	}
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		ImpData *impData = _dataList[indexPath.row];
		DeleteImpulse(impData.dataId);

		[_dataList removeObjectAtIndex:indexPath.row];
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Detemine if it's in editing mode
	if (self.editing) {
		return UITableViewCellEditingStyleDelete;
	}
	return UITableViewCellEditingStyleNone;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing:editing animated:animated];
	[self.tableView setEditing:editing animated:YES];

	if (editing) {
		_helper = [[I3DragBetweenHelper alloc] initWithSuperview:self.view.superview.superview.superview.superview // The UIView we're draggin around in
													 srcView:self.tableView // The Src
													 dstView:_masterViewController.tableView]; // The Dst
        _helper.delegate = self;
	} else {
		_helper = nil;
	}
}

- (BOOL)isCellAtIndexPathDraggable:(NSIndexPath *)index inContainer:(UIView*)container
{
	return container == self.tableView;
}

- (void)draggingOnDstAtIndexPath:(NSIndexPath *)index
{
	[_masterViewController dragOver:index];
}

- (void)droppedOnDstAtIndexPath:(NSIndexPath *)to fromSrcIndexPath:(NSIndexPath*)from
{
	int folderId = [_masterViewController getFolderIdFromIndexPath:to];
	int dataId = ((ImpData *)_dataList[from.row]).dataId;
	if (folderId != 0 && dataId != 0) {
		CDbImpulse dbImpulse;
		DbImpulseRec dbImpulseRec;

		if (dbImpulse.Open()) {
			dbImpulse.DBChgIdx(dbImpulse.m_nIdxImpulseID);
			dbImpulse.ReadRecID(dataId, &dbImpulseRec);
			dbImpulseRec.nFolderID = folderId;
			dbImpulse.UpdateRec(&dbImpulseRec);

			[self displayDataList:0];
		}
	}

	[_masterViewController dragOver:nil];
}

@end
