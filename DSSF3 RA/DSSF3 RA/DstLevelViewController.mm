//
//  DstLevelViewController.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/10.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "DstLevelViewController.h"

#define MIN_FREQ_VAL	10
#define MAX_FREQ_VAL	10000

#define MIN_FREQ_POS 0
#define MAX_FREQ_POS 100

@interface DstLevelViewController ()

@property (nonatomic, weak) IBOutlet CtSlider *outletFreqSlider;
@property (nonatomic, weak) IBOutlet CtTextField *outletFreqEdit;
@property (nonatomic, weak) IBOutlet CtTextField *outletLeftTHD;
@property (nonatomic, weak) IBOutlet CtTextField *outletRightTHD;
@property (nonatomic, weak) IBOutlet DstLevelGraphView *outletGraph;
@property (nonatomic, weak) IBOutlet UILabel *outletLeftUnit;
@property (nonatomic, weak) IBOutlet UILabel *outletRightUnit;
@property (nonatomic, weak) IBOutlet CtTextField *outletLevelStart;
@property (nonatomic, weak) IBOutlet CtTextField *outletLevelEnd;
@property (nonatomic, weak) IBOutlet CtTextField *outletLevelPoint;
@property (nonatomic, weak) IBOutlet CtTextField *outletLevelCurrent;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletLevelSpline;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletChkMarker;
@property (nonatomic, weak) IBOutlet CtComboBox *outletComboHD;

@end

@implementation DstLevelViewController
{
    float *_pLeftDst[3];
    float *_pRightDst[3];
    float _fLevelCurrent;
    float _fLevelStep;
    float *_pLevel;
    int _nLevelPoint;
    int _nLevelCount;
    int _nLevelStart;
    int _nLevelEnd;
    BOOL _bValidData;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	[self.outletGraph initialize];

	[self initFreqSlider];

	self.outletLevelStart.intValue = -g_oSetData.Dst.nLevelStart;
	self.outletLevelEnd.intValue = -g_oSetData.Dst.nLevelEnd;
	self.outletLevelPoint.intValue = g_oSetData.Dst.nLevelPoint;
	self.outletFreqEdit.intValue = g_oSetData.Dst.nLevelFreq;

	self.outletLevelSpline.checked = g_oSetData.Dst.bLevelSpline;
	self.outletChkMarker.checked = g_oSetData.Dst.bLevelMarker;

	[self.outletComboHD addItem:@"THD" :0];
	[self.outletComboHD addItem:@"2ndHD" :0];
	[self.outletComboHD addItem:@"3rdHD" :0];
	self.outletComboHD.selectedIndex = g_oSetData.Dst.nLevelHD;

	[self dispUnit];
}

- (void)dealloc
{
	[self freeBuffers];
}

- (void)drawGraphScale:(CGContextRef)context
{
	if (!_bValidData) {
		_nLevelStart = g_oSetData.Dst.nLevelStart;
		_nLevelEnd = g_oSetData.Dst.nLevelEnd;
		_nLevelCount = 0;
		_nLevelPoint = 0;
	}

	[self dispUnit];

	[self.outletGraph drawScale:context :_nLevelStart :_nLevelEnd];
}

- (void)drawGraphData:(CGContextRef)context
{
	if (_bValidData) {
		[self.outletGraph drawData:context :_pLeftDst[g_oSetData.Dst.nLevelHD] :_pRightDst[g_oSetData.Dst.nLevelHD] :_pLevel :_nLevelCount :_nLevelStart :_nLevelEnd :_nLevelPoint];
	}
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
	self.outletFreqSlider.value = [self getPosFromFreq:g_oSetData.Dst.nLevelFreq];

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

- (IBAction)onChangeFreqSlider:(id)sender
{
	[self setFreq:[self getFreqFromPos:self.outletFreqSlider.value]];
}

- (void)setFreq:(int)nFreq
{
	self.outletFreqEdit.intValue = nFreq;
	self.outletFreqSlider.value = [self getPosFromFreq:nFreq];
	g_oSetData.Dst.nLevelFreq = nFreq;
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

- (void)initialize
{
	[self freeBuffers];

	[self.outletLevelCurrent blank];
	[self.outletGraph updateGraph];

	_bValidData = YES;
	_fLevelCurrent = g_oSetData.Dst.nLevelStart;
	_fLevelStep = (float)(g_oSetData.Dst.nLevelEnd - g_oSetData.Dst.nLevelStart) / (g_oSetData.Dst.nLevelPoint - 1);
	_nLevelPoint = g_oSetData.Dst.nLevelPoint;
	_nLevelCount = 0;

	for (int i = 0; i < 3; i++) {
		_pLeftDst[i] = new float[_nLevelPoint];
		if (g_oSetData.Dst.nChannel == 1)
			_pRightDst[i] = new float[_nLevelPoint];
	}

	_pLevel = new float[_nLevelPoint];
}

- (BOOL)waveOutData:(int *)nFreq :(float *)fLevel
{
	*nFreq = g_oSetData.Dst.nLevelFreq;
	*fLevel = _fLevelCurrent;

	self.outletLevelCurrent.text = [NSString stringWithFormat:@"%.1f", _fLevelCurrent];

	return YES;
}

- (BOOL)notifyTHD:(const float *)pLeftDst :(const float *)pRightDst
{
	for (int i = 0; i < 3; i++) {
		_pLeftDst[i][_nLevelCount] = pLeftDst[i];
		if (g_oSetData.Dst.nChannel == 1)
			_pRightDst[i][_nLevelCount] = pRightDst[i];
	}

	_pLevel[_nLevelCount] = _fLevelCurrent;
	++_nLevelCount;

	[self dispTHD:pLeftDst[g_oSetData.Dst.nLevelHD] :pRightDst[g_oSetData.Dst.nLevelHD]];
	[self.outletGraph updateGraph];

	if (_nLevelCount < _nLevelPoint) {
		_fLevelCurrent += _fLevelStep;
		return YES;
	} else
		return NO;
}

- (void)dispTHD:(float)fLeftTHD :(float)fRightTHD
{
	if (g_oSetData.Dst.nScaleMode == 0) {
		self.outletLeftTHD.text = [NSString stringWithFormat:@"%.4f", sqrt(fLeftTHD) * 100];
		if (g_oSetData.Dst.nChannel == 1)
			self.outletRightTHD.text = [NSString stringWithFormat:@"%.4f", sqrt(fRightTHD) * 100];
	} else {
		self.outletLeftTHD.text = [NSString stringWithFormat:@"%.1f", dB10(fLeftTHD)];
		if (g_oSetData.Dst.nChannel == 1)
			self.outletRightTHD.text = [NSString stringWithFormat:@"%.1f", dB10(fRightTHD)];
	}
}

- (void)dispUnit
{
	if (g_oSetData.Dst.nScaleMode == 0) {
		self.outletLeftUnit.text = @"%";
		self.outletRightUnit.text = @"%";
	} else {
		self.outletLeftUnit.text = @"dB";
		self.outletRightUnit.text = @"dB";
	}
}

- (void)freeBuffers
{
	for (int i = 0; i < 3; i++) {
		if (_pLeftDst[i] != NULL) {
			delete [] _pLeftDst[i];
			_pLeftDst[i] = NULL;
		}

		if (_pRightDst[i] != NULL) {
			delete [] _pRightDst[i];
			_pRightDst[i] = NULL;
		}
	}

	if (_pLevel != NULL) {
		delete [] _pLevel;
		_pLevel = NULL;
	}

	_bValidData = NO;
}

- (IBAction)onChangeLevelStart:(id)sender
{
	int nLevelStart = -self.outletLevelStart.intValue;

	if (nLevelStart != g_oSetData.Dst.nLevelStart) {
		g_oSetData.Dst.nLevelStart = nLevelStart;
		[self.outletGraph updateGraph];
	}
}

- (IBAction)onChangeLevelEnd:(id)sender
{
	int nLevelEnd = -self.outletLevelEnd.intValue;

	if (nLevelEnd != g_oSetData.Dst.nLevelEnd) {
		g_oSetData.Dst.nLevelEnd = nLevelEnd;
		[self.outletGraph updateGraph];
	}
}

- (IBAction)onChangeLevelPoint:(id)sender
{
	int nLevelPoint = self.outletLevelPoint.intValue;

	if (nLevelPoint <= 1)
		nLevelPoint = 1;

	g_oSetData.Dst.nLevelPoint = nLevelPoint;
}

- (IBAction)onChangeLevelSpline:(id)sender
{
	if (g_oSetData.Dst.bLevelSpline != self.outletLevelSpline.checked) {
		g_oSetData.Dst.bLevelSpline = self.outletLevelSpline.checked;
		[self.outletGraph updateGraph];
	}
}

- (IBAction)onChangeChkMarker:(id)sender
{
	g_oSetData.Dst.bLevelMarker = self.outletChkMarker.checked;
	[self.outletGraph updateGraph];
}

- (IBAction)onChangeComboHd:(id)sender
{
	g_oSetData.Dst.nLevelHD = self.outletComboHD.selectedIndex;
	[self.outletGraph updateGraph];
}

@end
