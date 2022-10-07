//
//  PresetViewController.m
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2020/04/21.
//  Copyright © 2020 TRC. All rights reserved.
//

#import "PresetViewController.h"
#import "Common.h"

#define PRESET_DIR  @"Preset"
#define PRESET_EXT  @"d3ps"

@interface PresetList : NSObject
@property (nonatomic) NSString *fileName;
@property (nonatomic) NSDate *fileDate;
@end

@implementation PresetList
@end

@implementation PresetViewController
{
    NSMutableArray<PresetList *> *_presetList;
    NSMetadataQuery *_metadataQuery;
    BOOL pullDown;
    NSFileCoordinator *_fileCoordinator;
    NSOperationQueue *_queue;
    UITableViewCell *_headerCell;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                target:self action:@selector(insertNewPreset:)];
    self.navigationItem.leftBarButtonItem = addButton;

    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    _headerCell = [self.tableView dequeueReusableCellWithIdentifier:@"Header"];

    _presetList = [[NSMutableArray alloc] init];
    
    _metadataQuery = [[NSMetadataQuery alloc] init];
    [_metadataQuery setSearchScopes:[NSArray arrayWithObjects:NSMetadataQueryUbiquitousDocumentsScope, nil]];
    [_metadataQuery setPredicate:[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"%%K LIKE '*.%@'", PRESET_EXT], NSMetadataItemFSNameKey]];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(queryNotification:) name:NSMetadataQueryDidUpdateNotification object:_metadataQuery];
    [nc addObserver:self selector:@selector(queryNotification:) name:NSMetadataQueryDidFinishGatheringNotification object:_metadataQuery];
    [_metadataQuery startQuery];
    
    [self readPresetList];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _presetList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    PresetList *preset = _presetList[indexPath.row];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"];

    cell.textLabel.text = preset.fileName;
    cell.detailTextLabel.text = [formatter stringFromDate:preset.fileDate];

    return cell;
}

- (void)queryNotification:(NSNotification *)notification
{
    [self readPresetList];
}

- (void)readPresetList
{
    [_presetList removeAllObjects];
    
    NSArray *results = [_metadataQuery results];
    
    for (NSMetadataItem *item in results) {
        PresetList *preset = [[PresetList alloc] init];
        preset.fileName = [[item valueForAttribute:NSMetadataItemFSNameKey] stringByDeletingPathExtension];
        preset.fileDate = [item valueForAttribute:NSMetadataItemFSContentChangeDateKey];
        [_presetList addObject:preset];
    }

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"fileDate" ascending:NO];
    NSArray *sortarray = [NSArray arrayWithObject:sortDescriptor];
    _presetList = [[_presetList sortedArrayUsingDescriptors:sortarray] mutableCopy];
    
    [self.tableView reloadData];
}

- (void)insertNewPreset:(id)sender
{
    NSString *fileName = [self checkFileName:@"New Preset"];
    [self savePresetFile:fileName];
    
    PresetList *preset = [[PresetList alloc] init];
    preset.fileName = fileName;
    preset.fileDate = [NSDate date];
    [_presetList insertObject:preset atIndex:0];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)savePresetFile:(NSString *)fileName
{
    NSString *presetDir = [self getPresetDir];
    NSString *filePath = [[presetDir stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:PRESET_EXT];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:presetDir])
        [fileManager createDirectoryAtPath:presetDir withIntermediateDirectories:YES attributes:nil error:nil];

    int nSelectedTab = g_oSetData.nSelectedTab;
    g_oSetData.nSelectedTab = g_oSetData.nPrevSelectedTab;
    NSDictionary *setData = [g_oSetData getAllData];
    g_oSetData.nSelectedTab = nSelectedTab;
//    [NSKeyedArchiver archiveRootObject:setData toFile:filePath];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:setData requiringSecureCoding:NO error:nil];
    [data writeToFile:filePath atomically:NO];
}

- (NSString *)getPresetDir
{
    NSURL *containerURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
    NSString *documentsDir = [[containerURL URLByAppendingPathComponent:@"Documents"] path];
    NSString *presetDir = [documentsDir stringByAppendingPathComponent:PRESET_DIR];
    
    return presetDir;
}

- (NSString *)checkFileName:(NSString *)fileName
{
    NSString *name;
    int index;
    
    for (PresetList *preset in _presetList) {
        if ([fileName isEqualToString:preset.fileName]) {
            NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"^(.+) ([0-9]+)$" options:0 error:nil];
            NSTextCheckingResult *match = [regexp firstMatchInString:preset.fileName options:0 range:NSMakeRange(0, preset.fileName.length)];
            if (match) {
                name = [preset.fileName substringWithRange:[match rangeAtIndex:1]];
                index = [preset.fileName substringWithRange:[match rangeAtIndex:2]].intValue;
            } else {
                name = fileName;
                index = 0;
            }
            fileName = [self checkFileName:[NSString stringWithFormat:@"%@ %d", name, index + 1]];
            break;
        }
    }
    
    return fileName;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *filePath = [self getPathName:_presetList[indexPath.row].fileName];
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            [fileCoordinator coordinateWritingItemAtURL:fileURL options:NSFileCoordinatorWritingForDeleting
                error:nil byAccessor:^(NSURL* writingURL) {
                    [fileManager removeItemAtURL:writingURL error:nil];
            }];
        });
        
        [_presetList removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.editing) {
        PresetEditViewController *presetEditViewController = [[PresetEditViewController alloc] initWithNibName:@"PresetEditView" bundle:nil];
        presetEditViewController.preferredContentSize = presetEditViewController.view.bounds.size;
        presetEditViewController.delegate = self;
        presetEditViewController.fileName = _presetList[indexPath.row].fileName;
        presetEditViewController.index = indexPath.row;

        presetEditViewController.modalPresentationStyle = UIModalPresentationPopover;

        UIPopoverPresentationController *presentationController = presetEditViewController.popoverPresentationController;
        presentationController.sourceView = self.view;
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        presentationController.sourceRect = cell.frame;
        presentationController.delegate = self;
        [self presentViewController:presetEditViewController animated: YES completion: nil];
    } else {
        NSString *pathName = [self getPathName:_presetList[indexPath.row].fileName];
        NSURL *url = [NSURL fileURLWithPath:pathName];
        NSFileAccessIntent *readingIntent = [NSFileAccessIntent readingIntentWithURL:url
                                                                             options:NSFileCoordinatorReadingWithoutChanges];
        [self.fileCoordinator coordinateAccessWithIntents:@[readingIntent]
                                                    queue:self.queue
                                               byAccessor:^(NSError *error) {
                                                   if (!error) {
                                                       if ([NSThread isMainThread]) {
                                                           [self loadPreset:readingIntent.URL.path];
                                                       } else {
                                                           dispatch_async(dispatch_get_main_queue(), ^{
                                                               [self loadPreset:readingIntent.URL.path];
                                                           });
                                                       }
                                                   }
                                               }];
    }
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}

- (void)loadPreset:(NSString *)pathName
{
//    NSDictionary *data = [NSKeyedUnarchiver unarchiveObjectWithFile:pathName];
    NSData *data = [NSData dataWithContentsOfFile:pathName];
    NSSet *set = [NSSet setWithObjects:NSString.class, NSObject.class, nil];
    NSDictionary *setData = [NSKeyedUnarchiver unarchivedObjectOfClasses:set fromData:data error:nil];
    [g_oSetData setAllData:setData];

    NSNotification *notification = [NSNotification notificationWithName:@"InitViews" object:self];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)changeFileName:(NSString *)fileName :(NSInteger)index
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager moveItemAtPath:[self getPathName:_presetList[index].fileName] toPath:[self getPathName:fileName] error:nil];
    
    _presetList[index].fileName = fileName;
}
                    
- (NSString *)getPathName:(NSString *)fileName
{
    return [[[self getPresetDir] stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:PRESET_EXT];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSInteger offset = -self.navigationController.navigationBar.frame.size.height;
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

- (NSFileCoordinator*)fileCoordinator
{
    if (!_fileCoordinator) {
        _fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    }
    return _fileCoordinator;
}

- (NSOperationQueue*)queue
{
    if (!_queue) {
        _queue = [[NSOperationQueue alloc] init];
    }
    return _queue;
}

@end
