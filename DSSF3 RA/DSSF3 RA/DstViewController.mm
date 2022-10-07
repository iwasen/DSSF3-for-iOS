//
//  DstViewController.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/09.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "DstViewController.h"
#import "DstSubViewController.h"

#define MAX_HARMONICS	20
#define MAX_GUARD_CNT	12

@interface DstViewController ()

@property (nonatomic, weak) IBOutlet UISegmentedControl *outletDstMode;
@property (nonatomic, weak) IBOutlet UIView *outletDstContainer;
@property (nonatomic, weak) IBOutlet CtButton *outletStartStop;
@property (nonatomic, weak) IBOutlet CtComboBox *outletSampleRate;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletChannel;
@property (nonatomic, weak) IBOutlet CtComboBox *outletMaxHarmonics;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletScaleMode;
@property (nonatomic, weak) IBOutlet CtComboBox *outletScaleMax;
@property (nonatomic, weak) IBOutlet CtComboBox *outletScaleMin;
@property (nonatomic, weak) IBOutlet CtTextField *outletElapseTime;
@property (nonatomic, weak) IBOutlet CtComboBox *outletGuardTime;

@end

@implementation DstViewController
{
    NSArray *_DstViews;
    BOOL _bStart;
    int _nSampleRate;
    int _nChannel;
    int _nBufSize;
    int _nFreq;
    float _fLevel;
    int _nWaveOutOffset;
    int _nWaveInOffset;
    int _nGuardCnt;
    float *_pLeftData;
    float *_pRightData;
    float _pLeftDst[MAX_HARMONICS];
    float _pRightDst[MAX_HARMONICS];
    float *_pSinTable;
    int _nTimeCount;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	UINib *nib = [UINib nibWithNibName:IS_PHONE ? @"DstView_iPhone" : @"DstView_iPad" bundle:nil];
	_DstViews = [nib instantiateWithOwner:nil options:nil];
    
    [self initViews];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(initViews) name:@"InitViews" object:nil];
}

- (void)initViews
{
	[self setMode];

	SetSampleRateList(self.outletSampleRate, g_oSetData.Dst.nSampleRate);

	[self setMaxHarmonics];
	[self setGuardTime];

	self.outletChannel.selectedSegmentIndex = g_oSetData.Dst.nChannel;
	self.outletScaleMode.selectedSegmentIndex = g_oSetData.Dst.nScaleMode;

	[self setScaleSelectAll];

	//EnableDataHoldButton();
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];

	[self stop];
}

- (void)dealloc
{
	[self freeBuffers];
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
	DstSubViewController *viewController;

	self.outletDstMode.selectedSegmentIndex = g_oSetData.Dst.nMode;

	for (viewController in self.childViewControllers)
		[self hideContentController:viewController];

	viewController = _DstViews[g_oSetData.Dst.nMode];
	viewController.view.frame = self.outletDstContainer.bounds;

	if (IS_PHONE) {
		self.outletStartStop = viewController.outletStartStop;
		self.outletSampleRate = viewController.outletSampleRate;
		self.outletChannel = viewController.outletChannel;
		self.outletElapseTime = viewController.outletElapseTime;
		self.outletMaxHarmonics = viewController.outletMaxHarmonics;
		self.outletScaleMode = viewController.outletScaleMode;
		self.outletScaleMax = viewController.outletScaleMax;
		self.outletScaleMin = viewController.outletScaleMin;
		self.outletElapseTime = viewController.outletElapseTime;
		self.outletGuardTime = viewController.outletGuardTime;

		SetSampleRateList(self.outletSampleRate, g_oSetData.Dst.nSampleRate);
		[self setMaxHarmonics];
		[self setGuardTime];
		self.outletChannel.selectedSegmentIndex = g_oSetData.Dst.nChannel;
		self.outletScaleMode.selectedSegmentIndex = g_oSetData.Dst.nScaleMode;
		[self setScaleSelectAll];
	}

	[self displayContentController:viewController];
}

- (void)displayContentController:(UIViewController *)content
{
	[self addChildViewController:content];
	[self.outletDstContainer addSubview:content.view];
	[content didMoveToParentViewController:self];
}

- (void)hideContentController:(UIViewController *)content
{
	[content willMoveToParentViewController:nil];
	[content.view removeFromSuperview];
	[content removeFromParentViewController];
}

- (void)setMaxHarmonics
{
	int i;
	NSString *str;

	for (i = 2; i <= MAX_HARMONICS; i++) {
		str = [NSString stringWithFormat:@"%d", i];
		[self.outletMaxHarmonics addItem:str :i];
	}
	self.outletMaxHarmonics.selectedItemData = g_oSetData.Dst.nMaxHarmonics;
}

- (void)setGuardTime
{
	int i;
	NSString *str;

	for (i = 2; i <= MAX_GUARD_CNT; i += 2) {
		str = [NSString stringWithFormat:@"%.1f sec", (float)i / 4];
		[self.outletGuardTime addItem:str :i];
	}
	self.outletGuardTime.selectedItemData = g_oSetData.Dst.nGuardCnt;
}

- (void)setScaleSelectAll
{
	[self setScaleSelect:self.outletScaleMax :0 :-40 :g_oSetData.Dst.nScaleMax];
	[self setScaleSelect:self.outletScaleMin :-40 :-120 :g_oSetData.Dst.nScaleMin];
}

- (void)setScaleSelect:(CtComboBox *)combo :(int)nMax :(int)nMin :(int)nDef
{
	int i;
	NSString *str;

	[combo resetContent];

	for (i = nMax; i >= nMin; i -= 20) {
		if (g_oSetData.Dst.nScaleMode == 0)
			str = [NSString stringWithFormat:@"%1g%%", pow(10.0, i / 20) * 100];
		else
			str = [NSString stringWithFormat:@"%ddB", i];
		[combo addItem:str :i];
	}
	combo.selectedItemData = nDef;
}

- (void)stop
{
	[AudioOutput stop];
	[AudioInputEx stop];
}

- (void)start
{
	[self freeBuffers];

	_nSampleRate = g_oSetData.Dst.nSampleRate;
	_nChannel = g_oSetData.Dst.nChannel + 1;
	_nBufSize = g_oSetData.Dst.nSampleRate / 5;
	_nGuardCnt = g_oSetData.Dst.nGuardCnt;
	_nFreq = 0;
	_fLevel = 0;
	_nWaveOutOffset = 0;
	_nWaveInOffset = 0;
	_nTimeCount = 0;

	NSObject<DstMode> *dstMode = _DstViews[g_oSetData.Dst.nMode];
	[dstMode initialize];

	[self makeSinTable];

	_pLeftData = new float[_nSampleRate];
	if (_nChannel == 2)
		_pRightData = new float[_nSampleRate];

	memset(_pLeftDst, 0, sizeof(_pLeftDst));
	memset(_pRightDst, 0, sizeof(_pRightDst));

	[AudioOutput prepare:g_oSetData.Dst.nSampleRate :NUM_CHANNELS_1 :_nBufSize :self];
	[AudioInputEx prepare:g_oSetData.Dst.nSampleRate :_nChannel :_nBufSize :self];

	[AudioOutput start];
	[AudioInputEx start];
}

- (void)freeBuffers
{
	if (_pLeftData != NULL) {
		delete [] _pLeftData;
		_pLeftData = NULL;
	}

	if (_pRightData != NULL) {
		delete [] _pRightData;
		_pRightData = NULL;
	}

	if (_pSinTable != NULL) {
		delete [] _pSinTable;
		_pSinTable = NULL;
	}
}

- (void)makeSinTable
{
	int i;

	_pSinTable = new float[_nSampleRate];

	for (i = 0; i < _nSampleRate; i++)
		_pSinTable[i] = sin(2 * M_PI * i / _nSampleRate);
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
	[self freeBuffers];
	//	EnableOutputFile();
	//	EnableDataHoldButton();
}

- (void)audioOutputData:(AudioData *)audioData
{
	BOOL bContinue;
	int i;
	int nFreq = 0;
	float fLevel = 0;

	NSObject<DstMode> *dstMode = _DstViews[g_oSetData.Dst.nMode];
	bContinue = [dstMode waveOutData:&nFreq :&fLevel];

	if (!bContinue)
		return;

	if (nFreq != _nFreq || fLevel != _fLevel) {
		_nFreq = nFreq;
		_fLevel = fLevel;
		_nGuardCnt = g_oSetData.Dst.nGuardCnt;
		_nWaveInOffset = 0;
		[AudioOutput reset];
	}

	float fTmp = pow(10.0, fLevel / 20.0);
	for (i = 0; i < _nBufSize; i++) {
		audioData->pLeftData[i] = _pSinTable[_nWaveOutOffset] * fTmp;
		_nWaveOutOffset = (_nWaveOutOffset + nFreq) % _nSampleRate;
	}

	audioData->nDataSize = _nBufSize;
}

- (void)audioInputStop
{
	[AudioOutput stop];
}

- (void)audioInputData:(AudioData *)audioData
{
	BOOL bContinue = YES;
	int i;

	int nTimeCount = ++_nTimeCount / 5;
	self.outletElapseTime.text = [NSString stringWithFormat:@"%d:%02d:%02d", nTimeCount / 3600, nTimeCount / 60 % 60, nTimeCount % 60];

	if (_nGuardCnt > 0) {
		_nGuardCnt--;
		return;
	}

	for (i = 0; i < _nBufSize; i++) {
		_pLeftData[_nWaveInOffset] = audioData->pLeftData[i];
		if (_nChannel == 2)
			_pRightData[_nWaveInOffset] = audioData->pRightData[i];

		_nWaveInOffset++;
	}

	if (_nWaveInOffset == _nSampleRate) {
		[self calcTHD];
		_nWaveInOffset = 0;

		NSObject<DstMode> *dstMode = _DstViews[g_oSetData.Dst.nMode];
		bContinue = [dstMode notifyTHD:_pLeftDst :_pRightDst];
	}

	if (!bContinue)
		audioData->nDataSize = 0;
}

- (void)calcTHD
{
	float fLeftHarmonic = 0;
	float fRightHarmonic = 0;
	float fLeftTotal;
	float fRightTotal = 0;
	int i;

	for (i = 0; i < g_oSetData.Dst.nMaxHarmonics; i++) {
		_pLeftDst[i] = [self getHarmonic:_pLeftData :i + 1];
		if (_nChannel == 2)
			_pRightDst[i] = [self getHarmonic:_pRightData :i + 1];

		if (i != 0) {
			fLeftHarmonic += _pLeftDst[i];
			if (_nChannel == 2)
				fRightHarmonic += _pRightDst[i];
		}
	}

	fLeftTotal = _pLeftDst[0] + fLeftHarmonic;
	_pLeftDst[0] = fLeftHarmonic;
	if (_nChannel == 2) {
		fRightTotal = _pRightDst[0] + fRightHarmonic;
		_pRightDst[0] = fRightHarmonic;
	}

	for (i = 0; i < g_oSetData.Dst.nMaxHarmonics; i++) {
		_pLeftDst[i] = _pLeftDst[i] / fLeftTotal;
		if (_nChannel == 2)
			_pRightDst[i] = _pRightDst[i] / fRightTotal;
	}
}

- (float)getHarmonic:(const float *)pData :(int)nHarmonic
{
	int i;
	int nStep = _nFreq * nHarmonic;
	int nSinOffset = 0;
	int nCosOffset = _nSampleRate / 4;
	float fSinSum = 0;
	float fCosSum = 0;

	if (nStep >= _nSampleRate / 2)
		return 0;

	for (i = 0; i < _nSampleRate; i++) {
		fSinSum += pData[i] * _pSinTable[nSinOffset];
		fCosSum += pData[i] * _pSinTable[nCosOffset];

		nSinOffset = (nSinOffset + nStep) % _nSampleRate;
		nCosOffset = (nCosOffset + nStep) % _nSampleRate;
	}

	return fSinSum * fSinSum + fCosSum * fCosSum;
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

	g_oSetData.Dst.nSampleRate = sender.selectedItemData;

	if (bStart)
		[self start];
}

- (IBAction)onChangeChannel:(UISegmentedControl *)sender
{
	BOOL bStart = _bStart;

	if (bStart)
		[self stop];

	g_oSetData.Dst.nChannel = (int)sender.selectedSegmentIndex;

	if (bStart)
		[self start];
}

- (IBAction)onChangeMaxHarmonics:(CtComboBox *)sender
{
	g_oSetData.Dst.nMaxHarmonics = sender.selectedItemData;
	[self redrawGraph];
}

- (IBAction)onChangeScaleMode:(UISegmentedControl *)sender
{
	g_oSetData.Dst.nScaleMode = (int)sender.selectedSegmentIndex;
	[self setScaleSelectAll];
	[self redrawGraph];
}

- (IBAction)onChangeScaleMax:(CtComboBox *)sender
{
	g_oSetData.Dst.nScaleMax = sender.selectedItemData;
	[self redrawGraph];
}

- (IBAction)onChangeScaleMin:(CtComboBox *)sender
{
	g_oSetData.Dst.nScaleMin = sender.selectedItemData;
	[self redrawGraph];
}

- (IBAction)onChangeDstMode:(UISegmentedControl *)sender
{
	g_oSetData.Dst.nMode = (int)sender.selectedSegmentIndex;
	[self stop];
	[self setMode];
	//EnableOutputFile();
	//EnableDataHoldButton();
}

- (IBAction)onChangeGuardTime:(CtComboBox *)sender
{
	g_oSetData.Dst.nGuardCnt = sender.selectedItemData;
}

- (void)redrawGraph
{
	NSObject<DstMode> *dstMode = _DstViews[g_oSetData.Dst.nMode];
	[dstMode updateGraph];
}

@end
