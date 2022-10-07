//
//  DstManualViewController.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/10.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "DstManualViewController.h"

#define MIN_FREQ_VAL	10
#define MAX_FREQ_VAL	10000
#define MIN_LEVEL_VAL	-60
#define MAX_LEVEL_VAL	0

#define MIN_FREQ_POS 0
#define MAX_FREQ_POS 100

#define MAX_HARMONICS	30

@interface DstManualViewController ()

@property (nonatomic, weak) IBOutlet CtSlider *outletFreqSlider;
@property (nonatomic, weak) IBOutlet CtTextField *outletFreqEdit;
@property (nonatomic, weak) IBOutlet CtSlider *outletLevelSlider;
@property (nonatomic, weak) IBOutlet CtTextField *outletLevelEdit;
@property (nonatomic, weak) IBOutlet CtTextField *outletLeftTHD;
@property (nonatomic, weak) IBOutlet CtTextField *outletRightTHD;
@property (nonatomic, weak) IBOutlet DstManualGraphView *outletGraph;
@property (nonatomic, weak) IBOutlet UILabel *outletLeftUnit;
@property (nonatomic, weak) IBOutlet UILabel *outletRightUnit;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletAverage;

@end

@implementation DstManualViewController
{
    float *_pLeftDst;
    float *_pRightDst;
    BOOL _bValidData;
    int _nChannel;
    int _nMaxHarmonics;
    int _nAverageCnt;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	[self.outletGraph initialize];

	[self initFreqSlider];
	[self initLevelSlider];

	self.outletFreqEdit.intValue = g_oSetData.Dst.nManualFreq;
	self.outletLevelEdit.intValue = -g_oSetData.Dst.nManualLevel;
	self.outletAverage.checked = g_oSetData.Dst.bManualAverage;

	[self dispTHD];
}

- (void)dealloc
{
	[self freeBuffers];
}

- (void)drawGraphScale:(CGContextRef)context
{
	if (!_bValidData) {
		_nChannel = g_oSetData.Dst.nChannel;
		_nMaxHarmonics = g_oSetData.Dst.nMaxHarmonics;
	}

	[self.outletGraph drawScale:context :_nMaxHarmonics];
}

- (void)drawGraphData:(CGContextRef)context
{
	[self dispTHD];
	[self.outletGraph drawData:context :_pLeftDst :_pRightDst :_nChannel :_nMaxHarmonics];
}

- (void)updateGraph
{
	[self.outletGraph updateGraph];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)initFreqSlider
{
	int nFreq;
	int nPos;
	NSString *str;

	self.outletFreqSlider.minValue = MIN_FREQ_POS;
	self.outletFreqSlider.maxValue = MAX_FREQ_POS;
	self.outletFreqSlider.value = [self getPosFromFreq:g_oSetData.Dst.nManualFreq];

	for (nFreq = MIN_FREQ_VAL; nFreq <= MAX_FREQ_VAL; ) {
		nPos = [self getPosFromFreq:nFreq];
		if (nFreq == 10 || nFreq == 100)
			str = [NSString stringWithFormat:@"%d", nFreq];
		else if (nFreq == 1000 || nFreq == 10000)
			str = [NSString stringWithFormat:@"%dk", nFreq / 1000];
		else
			str = @"";
		[self.outletFreqSlider addTic:nPos :str];

		 if (nFreq < 100)
			nFreq += 10;
		else if (nFreq < 1000)
			nFreq += 100;
		else if (nFreq < 10000)
			nFreq += 1000;
		else
			nFreq += 10000;
	}
}

- (void)initLevelSlider
{
	int nLevel;
	NSString *str;

	self.outletLevelSlider.minValue = MIN_LEVEL_VAL;
	self.outletLevelSlider.maxValue = MAX_LEVEL_VAL;
	self.outletLevelSlider.value = g_oSetData.Dst.nManualLevel;

	for (nLevel = MIN_LEVEL_VAL; nLevel <= MAX_LEVEL_VAL; nLevel += 10) {
		if (abs(nLevel) % 20 == 0)
			str = [NSString stringWithFormat:@"%d", nLevel];
		else
			str = @"";
		[self.outletLevelSlider addTic:nLevel :str];
	}
}

- (IBAction)onChangeFreqSlider:(id)sender
{
	[self setFreq:[self getFreqFromPos:self.outletFreqSlider.value]];
}

- (IBAction)onChangeLevelSlider:(id)sender
{
	[self setLevel :self.outletLevelSlider.value];
}

- (void)setFreq:(int)nFreq
{
	if (nFreq <= 0)
		nFreq = 1;

	self.outletFreqEdit.intValue = nFreq;
	self.outletFreqSlider.value = [self getPosFromFreq:nFreq];
	g_oSetData.Dst.nManualFreq = nFreq;
}

- (void)setLevel:(int)nLevel
{
	if (nLevel < MIN_LEVEL_VAL)
		nLevel = MIN_LEVEL_VAL;
	else if (nLevel > MAX_LEVEL_VAL)
		nLevel = MAX_LEVEL_VAL;

	self.outletLevelEdit.intValue = -nLevel;
	self.outletLevelSlider.value = nLevel;
	g_oSetData.Dst.nManualLevel = nLevel;
}

- (int)getPosFromFreq:(int)nFreq
{
	if (nFreq < MIN_FREQ_VAL)
		nFreq = MIN_FREQ_VAL;
	else if (nFreq > MAX_FREQ_VAL)
		nFreq = MAX_FREQ_VAL;

	return (int)((log((float)nFreq) - log((float)MIN_FREQ_VAL)) * MAX_FREQ_POS / (log((float)MAX_FREQ_VAL) - log((float)MIN_FREQ_VAL)) + 0.5);
}

- (int)getFreqFromPos:(int)nPos
{
	if (nPos < MIN_FREQ_POS)
		nPos = MIN_FREQ_POS;
	else if (nPos > MAX_FREQ_POS)
		nPos = MAX_FREQ_POS;

	return (int)(exp(log((float)MIN_FREQ_VAL) + nPos * (log((float)MAX_FREQ_VAL) - log((float)MIN_FREQ_VAL)) / MAX_FREQ_POS) + 0.5);
}

- (IBAction)onChangeFreqEdit:(id)sender
{
	[self setFreq:self.outletFreqEdit.intValue];
}

- (IBAction)onChangeLevelEdit:(id)sender
{
	[self setLevel:-self.outletLevelEdit.intValue];
}

- (IBAction)onChangeAverage:(id)sender
{
	g_oSetData.Dst.bManualAverage = self.outletAverage.checked;
}

- (void)initialize
{
	[self freeBuffers];
	[self.outletGraph updateGraph];

	_pLeftDst = new float[MAX_HARMONICS];
	memset(_pLeftDst, 0, sizeof(float) * MAX_HARMONICS);
	if (g_oSetData.Dst.nChannel == 1) {
		_pRightDst = new float[MAX_HARMONICS];
		memset(_pRightDst, 0, sizeof(float) * MAX_HARMONICS);
	}

	_nAverageCnt = 0;
}

- (BOOL)waveOutData:(int *)nFreq :(float *)fLevel
{
	*nFreq = g_oSetData.Dst.nManualFreq;
	*fLevel = g_oSetData.Dst.nManualLevel;

	return YES;
}

- (BOOL)notifyTHD:(const float *)pLeftDst :(const float *)pRightDst
{
	_bValidData = YES;

	if (_nMaxHarmonics != g_oSetData.Dst.nMaxHarmonics) {
		_nMaxHarmonics = g_oSetData.Dst.nMaxHarmonics;
		[self.outletGraph updateGraph];
	}

	if (g_oSetData.Dst.bManualAverage && _nAverageCnt != 0) {
		for (int i = 0; i < _nMaxHarmonics; i++) {
			_pLeftDst[i] = (_pLeftDst[i] * _nAverageCnt + pLeftDst[i]) / (_nAverageCnt + 1);
			if (_pRightDst != NULL)
				_pRightDst[i] = (_pRightDst[i] * _nAverageCnt + pRightDst[i]) / (_nAverageCnt + 1);
		}

		_nAverageCnt++;
	} else {
		memcpy(_pLeftDst, pLeftDst, sizeof(float) * _nMaxHarmonics);
		if (_pRightDst != NULL)
			memcpy(_pRightDst, pRightDst, sizeof(float) * _nMaxHarmonics);

		_nAverageCnt = 1;
	}

	[self.outletGraph updateData];

	return YES;
}

- (void)dispTHD
{
	if (g_oSetData.Dst.nScaleMode == 0) {
		if (_pLeftDst != NULL)
			self.outletLeftTHD.text = [NSString stringWithFormat:@"%.4f", sqrt(_pLeftDst[0]) * 100];
		if (_pRightDst != NULL)
			self.outletRightTHD.text = [NSString stringWithFormat:@"%.4f", sqrt(_pRightDst[0]) * 100];

		self.outletLeftUnit.text = @"%";
		self.outletRightUnit.text = @"%";
	} else {
		if (_pLeftDst != NULL)
			self.outletLeftTHD.text = [NSString stringWithFormat:@"%.1f", dB10(_pLeftDst[0])];
		if (_pRightDst != NULL)
			self.outletRightTHD.text = [NSString stringWithFormat:@"%.1f", dB10(_pRightDst[0])];

		self.outletLeftUnit.text = @"dB";
		self.outletRightUnit.text = @"dB";
	}
}

- (void)freeBuffers
{
	if (_pLeftDst != NULL) {
		delete [] _pLeftDst;
		_pLeftDst = NULL;
	}

	if (_pRightDst != NULL) {
		delete [] _pRightDst;
		_pRightDst = NULL;
	}

	_bValidData = NO;
}

@end
