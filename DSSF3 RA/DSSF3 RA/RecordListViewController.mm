//
//  RecordListViewController.m
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2017/01/30.
//  Copyright © 2017年 TRC. All rights reserved.
//

#import "RecordListViewController.h"

@interface RecordFile : NSObject

@property (nonatomic) NSString *filePath;
@property (nonatomic) NSString *fileName;
@property (nonatomic) NSDate *fileDate;
@property (nonatomic) NSNumber *fileSize;

@end

@implementation RecordFile
@end

@implementation RecordListViewController
{
    NSMutableArray<RecordFile *> *_fileList;
    NSMetadataQuery *_metadataQuery;
    BOOL pullDown;
    UITableViewCell *_headerCell;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	_fileList = [[NSMutableArray alloc] init];
    
    if (self.bUseiCloud) {
        _metadataQuery = [[NSMetadataQuery alloc] init];
        [_metadataQuery setSearchScopes:[NSArray arrayWithObjects:NSMetadataQueryUbiquitousDocumentsScope, nil]];
        [_metadataQuery setPredicate:[NSPredicate predicateWithFormat:@"%K LIKE '*.wav'", NSMetadataItemFSNameKey]];

        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(queryNotification:) name:NSMetadataQueryDidUpdateNotification object:_metadataQuery];
        [nc addObserver:self selector:@selector(queryNotification:) name:NSMetadataQueryDidFinishGatheringNotification object:_metadataQuery];
        [_metadataQuery startQuery];
    }

    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    _headerCell = [self.tableView dequeueReusableCellWithIdentifier:@"Header"];

    [self readFileList];
}

- (void)viewDidDisappear:(BOOL)animated
{
    if (_metadataQuery == nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        _metadataQuery = nil;
    }
}

- (void)queryNotification:(NSNotification *)notification
{
    [self readFileList];
}

- (void)readFileList
{
    [_fileList removeAllObjects];
    
    if (self.bUseiCloud) {
        NSArray *results = [_metadataQuery results];
        
        for(NSMetadataItem *item in results) {
            RecordFile *recordFile = [[RecordFile alloc] init];
            recordFile.filePath = [item valueForAttribute:NSMetadataItemPathKey];
            recordFile.fileName = [item valueForAttribute:NSMetadataItemFSNameKey];
            recordFile.fileDate = [item valueForAttribute:NSMetadataItemFSContentChangeDateKey];
            recordFile.fileSize = [item valueForAttribute:NSMetadataItemFSSizeKey];
            [_fileList addObject:recordFile];
        }
    } else {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        for (NSString *fileName in [fileManager contentsOfDirectoryAtPath:self.dir error:nil]) {
            if ([fileName hasSuffix:@".wav"]) {
                RecordFile *recordFile = [[RecordFile alloc] init];
                recordFile.filePath = [self.dir stringByAppendingPathComponent:fileName];
                recordFile.fileName = fileName;
                NSDictionary *dict = [fileManager attributesOfItemAtPath:recordFile.filePath error:nil];
                recordFile.fileDate = [dict objectForKey:NSFileModificationDate];
                recordFile.fileSize = [dict objectForKey:NSFileSize];
                [_fileList addObject:recordFile];
            }
        }
    }
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return _fileList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

	RecordFile *recordFile = _fileList[indexPath.row];

	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
	NSString *dateString = [formatter stringFromDate:recordFile.fileDate];

	cell.textLabel.text = recordFile.fileName;
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@  %.1fMB", dateString, recordFile.fileSize.floatValue / 1024 / 1024];

    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSURL *fileURL = [NSURL fileURLWithPath:_fileList[indexPath.row].filePath];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            [fileCoordinator coordinateWritingItemAtURL:fileURL options:NSFileCoordinatorWritingForDeleting
                error:nil byAccessor:^(NSURL* writingURL) {
                    [fileManager removeItemAtURL:writingURL error:nil];
            }];
        });
        
		[_fileList removeObjectAtIndex:indexPath.row];
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (!tableView.editing) {
        [_delegate loadFile:self :[NSURL fileURLWithPath:_fileList[indexPath.row].filePath]];
	}
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.bUseiCloud) {
        //NSInteger offset = -self.navigationController.navigationBar.frame.size.height;
        NSInteger offset = 0;
        if (!pullDown && scrollView.contentOffset.y < offset - _headerCell.frame.size.height) {
            pullDown = YES;
            self.tableView.tableHeaderView = _headerCell.contentView;
        }
        
        if (pullDown && scrollView.contentOffset.y == offset) {
            [self->_metadataQuery startQuery];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0), dispatch_get_main_queue(), ^{
                self.tableView.tableHeaderView = nil;
                self->pullDown = NO;
            });
        }
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
