//
//  FreViewController.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/05/28.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "FreViewController.h"
#import "FreSubViewController.h"

@interface FreViewController ()

@property (nonatomic, weak) IBOutlet UISegmentedControl *outletFreMode;
@property (nonatomic, weak) IBOutlet UIView *outletFreContainer;
@property (nonatomic, weak) IBOutlet CtButton *outletStartStop;
@property (nonatomic, weak) IBOutlet CtComboBox *outletSampleRate;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletChannel;
@property (nonatomic, weak) IBOutlet CtTextField *outletElapseTime;
@property (nonatomic, weak) IBOutlet CtTextField *outletMinLevel;
@property (nonatomic, weak) IBOutlet CtTextField *outletMaxLevel;

@end

@implementation FreViewController
{
    NSArray *_FreViews;
    int _nSampleRate;
    int _nChannel;
    int _nBufSize;
    BOOL _bStart;
    float _fTimeCount;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	UINib *nib = [UINib nibWithNibName:IS_PHONE ? @"FreView_iPhone" : @"FreView_iPad" bundle:nil];
	_FreViews = [nib instantiateWithOwner:nil options:nil];
    
    [self initViews];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(initViews) name:@"InitViews" object:nil];
}

- (void)initViews
{
	[self setMode];

//	[self enableDataHoldButton];

	SetSampleRateList(self.outletSampleRate, g_oSetData.Fre.nSampleRate);
	self.outletChannel.selectedSegmentIndex = g_oSetData.Fre.nChannel;
	self.outletMaxLevel.intValue = g_oSetData.Fre.nMaxLevel;
	self.outletMinLevel.intValue = g_oSetData.Fre.nMinLevel;

//	SetMicCalData();
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];

	[self stop];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)setMode
{
	FreSubViewController *viewController;

	self.outletFreMode.selectedSegmentIndex = g_oSetData.Fre.nMode;

	for (viewController in self.childViewControllers)
		[self hideContentController:viewController];
	viewController = _FreViews[g_oSetData.Fre.nMode];
	viewController.view.frame = self.outletFreContainer.bounds;

	if (IS_PHONE) {
		self.outletStartStop = viewController.outletStartStop;
		self.outletSampleRate = viewController.outletSampleRate;
		self.outletChannel = viewController.outletChannel;
		self.outletElapseTime = viewController.outletElapseTime;
		self.outletMinLevel = viewController.outletMinLevel;
		self.outletMaxLevel = viewController.outletMaxLevel;

		self.outletStartStop.selected = NO;
		self.outletElapseTime.text = @"";
		SetSampleRateList(self.outletSampleRate, g_oSetData.Fre.nSampleRate);
		self.outletChannel.selectedSegmentIndex = g_oSetData.Fre.nChannel;
		self.outletMaxLevel.intValue = g_oSetData.Fre.nMaxLevel;
		self.outletMinLevel.intValue = g_oSetData.Fre.nMinLevel;
	}

	[self displayContentController:viewController];
}

- (void)displayContentController:(UIViewController *)content
{
	[self addChildViewController:content];
	[self.outletFreContainer addSubview:content.view];
	[content didMoveToParentViewController:self];
}

- (void)hideContentController:(UIViewController *)content
{
	[content willMoveToParentViewController:nil];
	[content.view removeFromSuperview];
	[content removeFromParentViewController];
}

- (IBAction)changeFreMode:(UISegmentedControl *)sender
{
	[self stop];

	g_oSetData.Fre.nMode = (int)sender.selectedSegmentIndex;
	[self setMode];
}

- (IBAction)onTapStartStop:(CtButton *)sender
{
	if (_bStart)
		[self stop];
	else
		[self start];
}

- (IBAction)onChangeSampleRate:(CtComboBox *)sender
{
	BOOL bStart = _bStart;

	if (bStart)
		[self stop];

	g_oSetData.Fre.nSampleRate = sender.selectedItemData;

	NSObject<FreMode> *freMode = _FreViews[g_oSetData.Fre.nMode];
	[freMode changeSampleRate];

	if (bStart)
		[self start];
}

- (IBAction)onChangeChannel:(UISegmentedControl *)sender
{
	BOOL bStart = _bStart;

	if (bStart)
		[self stop];

	g_oSetData.Fre.nChannel = (int)sender.selectedSegmentIndex;

	if (bStart)
		[self start];
}

- (IBAction)onChangeMaxLevel:(CtTextField *)sender
{
	if (sender.intValue != g_oSetData.Fre.nMaxLevel) {
		g_oSetData.Fre.nMaxLevel = sender.intValue;
		[self redrawGraph];
	}
}

- (IBAction)onChangeMinLevel:(CtTextField *)sender
{
	if (sender.intValue != g_oSetData.Fre.nMinLevel) {
		g_oSetData.Fre.nMinLevel = sender.intValue;
		[self redrawGraph];
	}
}

- (void)start
{
	_nSampleRate = g_oSetData.Fre.nSampleRate;
	_nChannel = g_oSetData.Fre.nChannel + 1;
	_fTimeCount = 0;

	NSObject<FreMode> *freMode = _FreViews[g_oSetData.Fre.nMode];
	_nBufSize = [freMode initialize];

	[AudioOutput prepare:g_oSetData.Fre.nSampleRate :NUM_CHANNELS_1 :_nBufSize :self];
	[AudioInputEx prepare:g_oSetData.Fre.nSampleRate :_nChannel :_nBufSize :self];

	[AudioOutput start];
	[AudioInputEx start];
}

- (void)stop
{
	[AudioOutput stop];
	[AudioInputEx stop];
}

- (void)restart
{
	if (_bStart) {
		[self stop];
		[self start];
	}
}

- (void)redrawGraph
{
	NSObject<FreMode> *freMode = _FreViews[g_oSetData.Fre.nMode];
	[freMode updateGraph];
}

- (void)audioOutputStart:(AudioInfo *)audioInfo
{
	_bStart = YES;
	self.outletStartStop.selected = YES;
}

- (void)audioOutputStop
{
	[AudioInputEx stop];
	_bStart = NO;
	self.outletStartStop.selected = NO;
//	EnableOutputFile();
//	EnableDataHoldButton();
}

- (void)audioOutputData:(AudioData *)audioData
{
	NSObject<FreMode> *freMode = _FreViews[g_oSetData.Fre.nMode];
	if ([freMode waveOutData:audioData->pLeftData])
		[AudioOutput reset];

	audioData->nDataSize = _nBufSize;
}

- (void)audioInputStart:(AudioInfo *)audioInfo
{
}

- (void)audioInputStop
{
	[AudioOutput stop];
}

- (void)audioInputData:(AudioData *)audioData
{
	_fTimeCount += (float)_nBufSize / _nSampleRate;
	int nTimeCount = (int)_fTimeCount;
	self.outletElapseTime.text = [NSString stringWithFormat:@"%d:%02d:%02d", nTimeCount / 3600, nTimeCount / 60 % 60, nTimeCount % 60];

	NSObject<FreMode> *freMode = _FreViews[g_oSetData.Fre.nMode];
	if (![freMode waveInData:audioData->pLeftData :audioData->pRightData])
		audioData->nDataSize = 0;
}

@end
