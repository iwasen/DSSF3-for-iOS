//
//  RecorderViewController.m
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2017/01/05.
//  Copyright © 2017年 TRC. All rights reserved.
//

#import "RecorderViewController.h"
#import "RecordListViewController.h"
#import "DocumentBrowserViewController.h"
#import "Common.h"
#import "RecView.h"
#import "AudioConverter.h"

#define SCROLL_RANGE 16384
#define MIN_DISP_TIME	0.001
#define MAX_ZOO_TIME		512

#define INIT_TIME	10
#define RECBUF_SIZE	(128 * 1024 * 1024)
#define RECORDER_DIR	@"Recorder"

@interface RecorderViewController ()

@property (nonatomic, weak) IBOutlet RecView *outletRecView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletMode;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletNormalization;
@property (nonatomic, weak) IBOutlet CtTextField *outletSelectStart;
@property (nonatomic, weak) IBOutlet CtTextField *outletSelectEnd;
@property (nonatomic, weak) IBOutlet CtTextField *outletSelectTime;
@property (nonatomic, weak) IBOutlet CtTextField *outletRecordTime;
@property (nonatomic, weak) IBOutlet CtButton *outletSelectAll;
@property (nonatomic, weak) IBOutlet CtButton *outletCut;
@property (nonatomic, weak) IBOutlet CtButton *outletPlayback;
@property (nonatomic, weak) IBOutlet CtButton *outletSave;
@property (nonatomic, weak) IBOutlet CtButton *outletLoad;
@property (nonatomic, weak) IBOutlet CtButton *outletTranstfer;
@property (nonatomic, weak) IBOutlet UISwitch *outletAutoRecording;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletUseiCloud;

@end

@implementation RecorderViewController
{
    float *_pLeftBuf;
    float *_pRightBuf;
    int _nRecCount;
    int _nPlayCount;
    int _nPlayEndCount;
    int _nRecSampleRate;
    int _nRecChannel;
    NSDate *_recDate;
    int _nPlayChannel;
    float _fTotalTime, _fStartTime, _fDispTime;
    float _fMaxData;
    float _fSelectStart;
    float _fSelectEnd;
    float _fPlayTime;
    int _nAllocSize;
    int _bufSize;
    UIDocumentInteractionController *_diController;
    NSFileCoordinator *_fileCoordinator;
    NSOperationQueue *_queue;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	_pLeftBuf = NULL;
	_pRightBuf = NULL;
	_fSelectStart = -1;
	_fSelectEnd = -1;
	_nRecCount = 0;
	_nRecChannel = 1;
	_nPlayChannel = 1;
	_fMaxData = 0;
	_nAllocSize = 0;

	[self.outletRecView initialize];

	self.outletRecView.enabled = YES;
    self.outletAutoRecording.on = g_oSetData.Rec.bAutoRecording;
    self.outletUseiCloud.selectedSegmentIndex = g_oSetData.Rec.bUseiCloud ? 1 : 0;

	[self initDispTime];
	[self dispWaveGraph];
	[self dispRecInfo];
	[self dispSelectArea];
	[self enableButton];

    if (g_oSetData.Rec.bAutoRecording) {
        self.outletMode.selectedSegmentIndex = REC_MODE_RECORD;
        [self onChangeMode:self.outletMode];
    }

    [self enableUseiCloud];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(notifyLoadWaveFile:) name:@"LoadWaveFile" object:nil];
    
    NSNotification *notification = [NSNotification notificationWithName:@"QueryWaveFile" object:self];
    [nc postNotification:notification];
}

- (void)viewDidAppear:(BOOL)animated
{
	[AudioInputEx stop];
	[AudioOutputEx stop];

    [self enableUseiCloud];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	[AudioInputEx stop];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)notifyLoadWaveFile:(NSNotification *)center
{
    NSURL *url = [[center userInfo] objectForKey:@"url"];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDictionary *dict = [fm attributesOfItemAtPath:url.path error:nil];
    if (dict != nil && ((NSNumber *)[dict objectForKey:NSFileSize]).longValue != 0) {
        NSDate *fileDate = [dict objectForKey:NSFileModificationDate];
        [self selectRecordFile:url.path :fileDate];
    }
}

- (void)enableUseiCloud
{
    NSURL *containerURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
    if (containerURL != nil) {
        self.outletUseiCloud.enabled = YES;
    } else {
        g_oSetData.Rec.bUseiCloud = NO;
        self.outletUseiCloud.selectedSegmentIndex = 0;
        self.outletUseiCloud.enabled = NO;
    }
}

- (IBAction)onChangeMode:(id)sender
{
	int recMode = (int)self.outletMode.selectedSegmentIndex;
	[AudioEx setRecMode:recMode :self];

    if (IS_PAD) {
        UITabBarController *tbc = (UITabBarController *)[self parentViewController];
        UITabBarItem *item1 = [tbc.tabBar.items objectAtIndex:6];
        switch (recMode) {
            case REC_MODE_OFF:
                item1.image = [[UIImage imageNamed:@"REC.png"] imageWithRenderingMode:UIImageRenderingModeAutomatic];
                break;
            case REC_MODE_RECORD:
                item1.image = [[UIImage imageNamed:@"REC_R.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
                break;
            case REC_MODE_PLAY:
                item1.image = [[UIImage imageNamed:@"REC_P.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
                break;
        }
    }
    
    if (recMode != REC_MODE_RECORD && g_oSetData.Rec.bAutoRecording) {
        self.outletAutoRecording.on = NO;
        [self onChangeAutoRecording:self.outletAutoRecording];
    }
}

- (IBAction)onChangeAutoRecording:(id)sender
{
    g_oSetData.Rec.bAutoRecording = self.outletAutoRecording.isOn;
    if (g_oSetData.Rec.bAutoRecording) {
        self.outletMode.selectedSegmentIndex = REC_MODE_RECORD;
        [self onChangeMode:self.outletMode];
    }
}

- (IBAction)onChangeUseiCloud:(id)sender
{
    g_oSetData.Rec.bUseiCloud = (self.outletUseiCloud.selectedSegmentIndex == 1);
}

- (void)enableButton
{
	BOOL bEnable = (_nRecCount != 0);
	[self.outletMode setEnabled:bEnable forSegmentAtIndex:2];
	self.outletSave.enabled = bEnable;
	self.outletSelectAll.enabled = bEnable;
	self.outletCut.enabled = bEnable;
	self.outletPlayback.enabled = bEnable;
	self.outletSelectStart.enabled = bEnable;
	self.outletSelectEnd.enabled = bEnable;
	self.outletSave.enabled = bEnable;
	self.outletTranstfer.enabled = bEnable;
}

- (void)audioRecordStart:(AudioInfo *)audioInfo
{
	_nRecCount = 0;
	_nRecSampleRate = audioInfo->nSampleRate;
	_nRecChannel = audioInfo->nChannel;
	_recDate = [NSDate date];
	[self allocBuf:_nRecChannel];
}

- (void)audioRecordStop
{
	_fTotalTime = (float)_nRecCount / _nRecSampleRate;
	_fSelectStart = 0;
	_fSelectEnd = _fTotalTime;
    
    if (g_oSetData.Rec.bAutoRecording) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyyMMdd_HHmmss"];
        NSString *date = [formatter stringFromDate:self->_recDate];
        NSString *fileName = [NSString stringWithFormat:@"dssf3_rec_%@_auto", date];
        [self saveWavFile:fileName];
    } else {
        self.outletMode.selectedSegmentIndex = REC_MODE_PLAY;
        [self onChangeMode:self];
    }
    
	[self dispWaveGraph];
	[self dispRecInfo];
	[self dispSelectArea];
	[self enableButton];
}

- (void)audioRecordData:(AudioData *)audioData
{
	int copySize = MIN(audioData->nDataSize, _nAllocSize - _nRecCount);
	if (copySize > 0) {
		memcpy(_pLeftBuf + _nRecCount, audioData->pLeftData, copySize * sizeof(AUDIO_SAMPLE));

		if (audioData->nChannel == 2)
			memcpy(_pRightBuf + _nRecCount, audioData->pRightData, copySize * sizeof(AUDIO_SAMPLE));

		_nRecCount += copySize;
	}
}

- (void)audioPlayStart:(AudioInfo *)audioInfo
{
	_fPlayTime = _fSelectStart;
	_bufSize = audioInfo->nBufSize;
	_nPlayCount = MIN((int)(_fSelectStart * _nRecSampleRate * _nRecChannel) / _nRecChannel * _nRecChannel, _nRecCount);
	_nPlayEndCount = MIN((int)(_fSelectEnd * _nRecSampleRate * _nRecChannel) / _nRecChannel * _nRecChannel, _nRecCount);
}

- (void)audioPlayStop
{
}

- (void)audioPlayData:(AudioData *)audioData
{
	int copySize = MIN(_bufSize, _nPlayEndCount - _nPlayCount);
	if (copySize > 0) {
		memcpy(audioData->pLeftData, _pLeftBuf + _nPlayCount, copySize * sizeof(AUDIO_SAMPLE));

		if (audioData->nChannel == 2) {
			float *pBuf = (_nRecChannel == 2) ? _pRightBuf : _pLeftBuf;
			memcpy(audioData->pRightData, pBuf + _nPlayCount, copySize * sizeof(AUDIO_SAMPLE));
		}

		_nPlayCount += copySize;
	}

	audioData->nDataSize = copySize;
}

- (void)allocBuf:(int)channels
{
	_nAllocSize = RECBUF_SIZE / channels;

	while (true) {
		_pLeftBuf = new float[_nAllocSize];
		if (_pLeftBuf != NULL) {
			if (channels == 2) {
				_pRightBuf = new float[_nAllocSize];
				if (_pRightBuf != NULL)
					break;
				else
					[self freeBuf];
			} else
				break;
		}

		_nAllocSize /= 2;
	}
}

- (void)freeBuf
{
	if (_pLeftBuf != NULL) {
		delete [] _pLeftBuf;
		_pLeftBuf = NULL;
	}

	if (_pRightBuf != NULL) {
		delete [] _pRightBuf;
		_pRightBuf = NULL;
	}
}

- (void)dispWaveGraph
{
	if (_fDispTime == 0)
		_fDispTime = _fTotalTime;
	else if (_fDispTime < MIN_DISP_TIME)
		_fDispTime = MIN_DISP_TIME;
	else if (_fDispTime > _fTotalTime)
		_fDispTime = _fTotalTime;

	if (_fStartTime < 0)
		_fStartTime = 0;
	else if (_fStartTime > _fTotalTime - _fDispTime)
		_fStartTime = _fTotalTime - _fDispTime;

	[self.outletRecView setNeedsDisplay];
}

- (void)drawGraphData:(CGContextRef)context :(id)sender
{
	float fMaxData;

	if (self.outletNormalization.checked) {
		if (_fMaxData == 0)
			_fMaxData = GetMaxData(_pLeftBuf, _nRecCount);
		fMaxData = _fMaxData;
	} else
		fMaxData = 1.0;

	[self.outletRecView dispGraph:context :_fTotalTime :_fStartTime :_fDispTime :_pLeftBuf :_nRecCount :0 :fMaxData :_fSelectStart :_fSelectEnd];
}

- (void)initDispTime
{
	_fTotalTime = INIT_TIME;
	_fDispTime = _fTotalTime;
	_fStartTime = 0;
}

- (IBAction)onSave:(id)sender
{
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"IDS_SAVE", nil) message:NSLocalizedString(@"IDS_MSG_SAVEFILENAME", nil) preferredStyle:UIAlertControllerStyleAlert];

	[alert addAction:[UIAlertAction actionWithTitle:@"OK"
											  style:UIAlertActionStyleDefault
											handler:^(UIAlertAction *action) {
												UITextField *textField = alert.textFields[0];
												NSString *fileName = textField.text;
												if (fileName.length == 0)
													fileName = textField.placeholder;
												[self saveWavFile:fileName];
											}]];
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"IDS_CANCEL", nil)
											  style:UIAlertActionStyleCancel
											handler:nil]];

	[alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"yyyyMMdd_HHmmss"];
		NSString *date = [formatter stringFromDate:self->_recDate];
		NSString *fileName = [NSString stringWithFormat:@"dssf3_rec_%@", date];

		textField.placeholder = fileName;
		textField.clearButtonMode = UITextFieldViewModeAlways;
		textField.delegate = self;
	}];

	[self presentViewController:alert animated:YES completion:nil];
}

- (void)saveWavFile:(NSString *)fileName
{
    NSString *documentsDir = [self getDocumentsDir];
    NSString *recorderDir = [documentsDir stringByAppendingPathComponent:RECORDER_DIR];
	NSString *filePath = [[recorderDir stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:@"wav"];

    NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath:recorderDir])
		[fileManager createDirectoryAtPath:recorderDir withIntermediateDirectories:YES attributes:nil error:nil];
	SaveWavFile(_pLeftBuf, _pRightBuf, _nRecChannel, _nRecSampleRate, _nRecCount, filePath);

	NSDictionary<NSFileAttributeKey,id> *dict = [NSDictionary dictionaryWithObject:_recDate forKey:NSFileModificationDate];
	[fileManager setAttributes:dict ofItemAtPath:filePath error:nil];
}

- (NSString *)getDocumentsDir
{
    NSString *documentsDir;
    
    if (g_oSetData.Rec.bUseiCloud) {
        NSURL *containerURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
        documentsDir = [[containerURL URLByAppendingPathComponent:@"Documents"] path];
    } else {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        documentsDir = paths.firstObject;
    }
    
    return documentsDir;
}

- (IBAction)onLoad:(id)sender
{
	if (IS_PHONE) {
        RecordListViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"RecordListViewController"];
        viewController.delegate = self;
        viewController.dir = [[self getDocumentsDir] stringByAppendingPathComponent:RECORDER_DIR];
        viewController.bUseiCloud = g_oSetData.Rec.bUseiCloud;
		[self.parentViewController.navigationController pushViewController:viewController animated:YES];
	}
}

- (IBAction)onImport:(id)sender
{
    if (IS_PHONE) {
        DocumentBrowserViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"DocumentBrowserViewController"];
        viewController.delegate = (id)self;
        [self.parentViewController.navigationController pushViewController:viewController animated:YES];
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

-(void)documentBrowser:(UIDocumentBrowserViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)documentURLs
{
    NSURL *sourceURL = documentURLs.firstObject;
    if (sourceURL != nil) {
        [self loadFile:controller :sourceURL];
    }
}

- (void)loadFile:(UIViewController *)controller :(NSURL *)sourceURL
{
    NSFileAccessIntent *readingIntent = [NSFileAccessIntent readingIntentWithURL:sourceURL
                                                                         options:NSFileCoordinatorReadingWithoutChanges];
    [self.fileCoordinator coordinateAccessWithIntents:@[readingIntent]
                                                queue:self.queue
                                           byAccessor:^(NSError *error) {
                                               if (!error) {
                                                   if ([NSThread isMainThread]) {
                                                       [self readFile:controller :readingIntent.URL];
                                                   } else {
                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                           [self readFile:controller :readingIntent.URL];
                                                       });
                                                   }
                                               }
                                           }];
}
             
- (void)readFile:(UIViewController *)controller :(NSURL *)sourceURL
{
    BOOL bStartAccessing = [sourceURL startAccessingSecurityScopedResource];

    NSFileManager *fm = [NSFileManager defaultManager];
    NSDictionary *dict = [fm attributesOfItemAtPath:sourceURL.path error:nil];
    if (dict != nil && ((NSNumber *)[dict objectForKey:NSFileSize]).longValue != 0) {
        NSDate *fileDate = [dict objectForKey:NSFileModificationDate];
        [self selectRecordFile:sourceURL.path :fileDate];
        [controller.navigationController popViewControllerAnimated:YES];
    }

    if (bStartAccessing) {
        [sourceURL stopAccessingSecurityScopedResource];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"RecordList"]) {
		RecordListViewController *viewController = segue.destinationViewController;
		viewController.delegate = self;
		viewController.dir = [[self getDocumentsDir] stringByAppendingPathComponent:RECORDER_DIR];
        viewController.bUseiCloud = g_oSetData.Rec.bUseiCloud;
	} else if ([segue.identifier isEqualToString:@"Import"]) {
        DocumentBrowserViewController *viewController = segue.destinationViewController;
        viewController.delegate = (id)self;
    }
}

- (void)selectRecordFile:(NSString *)filePath :(NSDate *)fileDate
{
	[self freeBuf];
	
    if ([[filePath lowercaseString] hasSuffix:@".wav"]) {
        if (!ReadWavFile(&_pLeftBuf, &_pRightBuf, &_nRecChannel, &_nRecSampleRate, &_nRecCount, filePath)) {
            MessageBoxOK(self, NSLocalizedString(@"IDS_ERR_OUTOFMEMORY", nil), NULL);
            _nRecCount = 0;
        }
    } else {
        NSData *data;
        if (AudioConverter([NSURL fileURLWithPath:filePath], &_nRecSampleRate, &_nRecChannel, &data)) {
            int dataSize = (int)data.length;
            const Float32 *dataBuffer = (const float *)data.bytes;
            _nRecCount = dataSize / (sizeof(Float32) * _nRecChannel);
            _pLeftBuf = new float[_nRecCount];
            if (_nRecChannel == 2)
                _pRightBuf = new float[_nRecCount];
            for (int i = 0; i < _nRecCount; i++) {
                _pLeftBuf[i] = *dataBuffer++;
                if (_nRecChannel == 2)
                    _pRightBuf[i] = *dataBuffer++;
            }
        } else {
            MessageBoxOK(self, NSLocalizedString(@"IDS_ERR_OUTOFMEMORY", nil), NULL);
            _nRecCount = 0;
        }
    }

	_fTotalTime = (float)_nRecCount / _nRecSampleRate;
	_fDispTime = _fTotalTime;
	_fStartTime = 0;
	_fMaxData = 0;
	_fSelectStart = 0;
	_fSelectEnd = _fTotalTime;
	_recDate = fileDate;

	self.outletMode.selectedSegmentIndex = REC_MODE_PLAY;
	[self onChangeMode:self];

	[self dispWaveGraph];
	[self dispRecInfo];
	[self dispSelectArea];
	[self enableButton];
}

- (IBAction)onExport:(id)sender
{
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyyMMdd_HHmmss"];
	NSString *date = [formatter stringFromDate:_recDate];

	NSString *filePath = [NSString stringWithFormat:@"%@dssf3_rec_%@.wav",
						  NSTemporaryDirectory(), date];
	NSURL *url = SaveWavFile(_pLeftBuf, _pRightBuf, _nRecChannel, _nRecSampleRate, _nRecCount, filePath);

	_diController = [UIDocumentInteractionController interactionControllerWithURL:url];
	[_diController presentOptionsMenuFromRect:self.outletRecView.frame inView:self.view animated:YES];
}

- (void)dispSelectArea
{
	if (_fSelectStart != -1)
		self.outletSelectStart.text = [NSString stringWithFormat:@"%.2f", _fSelectStart];

	if (_fSelectEnd != -1)
		self.outletSelectEnd.text = [NSString stringWithFormat:@"%.2f", _fSelectEnd];

	[self dispSelectTime];
}

- (void)dispSelectTime
{
	if (_fSelectStart != -1)
		self.outletSelectTime.text = [NSString stringWithFormat:@"%.2f", _fSelectEnd - _fSelectStart];
}

- (IBAction)onSelectAll:(id)sender
{
	_fSelectStart = 0;
	_fSelectEnd = _fTotalTime;

	[self dispWaveGraph];
	[self dispSelectArea];
}

- (IBAction)onCut:(id)sender
{
	int nSelectStart;
	int nSelectEnd;
	int nSample;

	nSelectStart = MIN((int)(_fSelectStart * _nRecSampleRate), _nRecCount / _nRecChannel);
	nSelectEnd = MIN((int)(_fSelectEnd * _nRecSampleRate), _nRecCount / _nRecChannel);
	nSample = (nSelectEnd - nSelectStart) * _nRecChannel;

	if (nSample <= 0)
		return;

	memcpy(_pLeftBuf, _pLeftBuf + nSelectStart, nSample * sizeof(AUDIO_SAMPLE));

	if (_nRecChannel == 2)
		memcpy(_pRightBuf, _pRightBuf + nSelectStart, nSample * sizeof(AUDIO_SAMPLE));

	_nRecCount = nSample;

	_fTotalTime = (float)_nRecCount / _nRecSampleRate;
	_fDispTime = _fTotalTime;
	_fStartTime = 0;
	_fMaxData = 0;
	_fSelectStart = 0;
	_fSelectEnd = _fTotalTime;

	[self dispWaveGraph];
	[self dispRecInfo];
	[self dispSelectArea];
}

- (IBAction)onChangeSelectStart:(id)sender
{
	_fSelectStart = self.outletSelectStart.floatValue;

	if (_fSelectStart < 0)
		_fSelectStart = 0;

	if (_fSelectStart > _fSelectEnd - MIN_DISP_TIME)
		_fSelectStart = _fSelectEnd - MIN_DISP_TIME;

	[self dispWaveGraph];
	[self dispSelectTime];
}

- (IBAction)onChangeSelectEnd:(id)sender
{
	_fSelectEnd = self.outletSelectEnd.floatValue;

	if (_fSelectEnd > _fTotalTime)
		_fSelectEnd = _fTotalTime;

	if (_fSelectEnd < _fSelectStart + MIN_DISP_TIME)
		_fSelectEnd = _fSelectStart + MIN_DISP_TIME;

	[self dispWaveGraph];
	[self dispSelectTime];
}

- (IBAction)onChangeNormalization:(id)sender
{
	[self dispWaveGraph];
}

- (void)dispRecInfo
{
    int nTotalTime = _nRecCount == 0 ? 0 : (int)_fTotalTime;

	self.outletRecordTime.text = [NSString stringWithFormat:@"%d:%02d:%02d", nTotalTime / 3600, nTotalTime / 60 % 60, nTotalTime % 60];
}

- (void)moveGraph:(id)sender :(float)move
{
	_fStartTime += move * _fDispTime;
	[self dispWaveGraph];
}

- (void)zoomGraph:(id)sender :(float)zoom
{
	_fDispTime *= zoom;
	[self dispWaveGraph];
}

- (void)getSelectArea:(float *)selectStart :(float *)selectEnd
{
	*selectStart = _fSelectStart;
	*selectEnd = _fSelectEnd;
}

- (void)changeSelectStart:(float)selectStart
{
	_fSelectStart = selectStart;

	if (_fSelectStart < _fStartTime)
		_fSelectStart = _fStartTime;

	if (_fSelectStart > _fSelectEnd - MIN_DISP_TIME)
		_fSelectStart = _fSelectEnd - MIN_DISP_TIME;

	[self dispSelectArea];
}

- (void)changeSelectEnd:(float)selectEnd
{
	_fSelectEnd = selectEnd;

	if (_fSelectEnd < _fSelectStart + MIN_DISP_TIME)
		_fSelectEnd = _fSelectStart + MIN_DISP_TIME;

	if (_fSelectEnd > _fStartTime + _fDispTime)
		_fSelectEnd = _fStartTime + _fDispTime;

	[self dispSelectArea];
}

- (IBAction)onPlayback:(id)sender
{
	if (!self.outletPlayback.selected) {
		[AudioEx setRecMode:REC_MODE_PLAY :self];
		[AudioInputEx start:_nRecSampleRate :NUM_CHANNELS_2 :1024 :self];
	} else {
		[AudioInputEx stop];
	}
}

- (void)audioInputStart:(AudioInfo *)audioInfo
{
	self.outletPlayback.selected = YES;
}

- (void)audioInputStop
{
	[AudioEx setRecMode:(int)self.outletMode.selectedSegmentIndex :self];
	self.outletPlayback.selected = NO;
}

- (void)audioInputData:(AudioData *)audioData
{
}

- (int)getSampleRate
{
	return _nRecSampleRate;
}

@end
