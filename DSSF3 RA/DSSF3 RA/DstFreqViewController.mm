//
//  DstFreqViewController.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/10.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "DstFreqViewController.h"

#define MIN_LEVEL_VAL	-60
#define MAX_LEVEL_VAL	0

@interface DstFreqViewController ()

@property (nonatomic, weak) IBOutlet CtSlider *outletLevelSlider;
@property (nonatomic, weak) IBOutlet CtTextField *outletLevelEdit;
@property (nonatomic, weak) IBOutlet CtTextField *outletLeftTHD;
@property (nonatomic, weak) IBOutlet CtTextField *outletRightTHD;
@property (nonatomic, weak) IBOutlet DstFreqGraphView *outletGraph;
@property (nonatomic, weak) IBOutlet UILabel *outletLeftUnit;
@property (nonatomic, weak) IBOutlet UILabel *outletRightUnit;
@property (nonatomic, weak) IBOutlet CtTextField *outletFreqStart;
@property (nonatomic, weak) IBOutlet CtTextField *outletFreqEnd;
@property (nonatomic, weak) IBOutlet CtTextField *outletFreqPoint;
@property (nonatomic, weak) IBOutlet CtTextField *outletFreqCurrent;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletFreqSpline;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletChkMarker;
@property (nonatomic, weak) IBOutlet CtComboBox *outletComboHD;

@end

@implementation DstFreqViewController
{
    float *_pLeftDst[3];
    float *_pRightDst[3];
    float *_pFreq;
    float _fFreqCurrent;
    float _fFreqStep;
    int _nFreqPoint;
    int _nFreqCount;
    int _nFreqStart;
    int _nFreqEnd;
    BOOL _bValidData;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	[self.outletGraph initialize];

	[self initLevelSlider];

	self.outletFreqStart.intValue = g_oSetData.Dst.nFreqStart;
	self.outletFreqEnd.intValue = g_oSetData.Dst.nFreqEnd;
	self.outletFreqPoint.intValue = g_oSetData.Dst.nFreqPoint;
	self.outletLevelEdit.intValue = -g_oSetData.Dst.nFreqLevel;

	self.outletFreqSpline.checked = g_oSetData.Dst.bFreqSpline;
	self.outletChkMarker.checked = g_oSetData.Dst.bFreqMarker;

	[self.outletComboHD addItem:@"THD" :0];
	[self.outletComboHD addItem:@"2ndHD" :0];
	[self.outletComboHD addItem:@"3rdHD" :0];
	self.outletComboHD.selectedIndex = g_oSetData.Dst.nFreqHD;

	[self dispUnit];
}

- (void)dealloc
{
	[self freeBuffers];
}

- (void)drawGraphScale:(CGContextRef)context
{
	if (!_bValidData) {
		_nFreqStart = g_oSetData.Dst.nFreqStart;
		_nFreqEnd = g_oSetData.Dst.nFreqEnd;
		_nFreqCount = 0;
		_nFreqPoint = 0;
	}

	[self dispUnit];

	[self.outletGraph drawScale:context :_nFreqStart :_nFreqEnd];
}

- (void)drawGraphData:(CGContextRef)context
{

	if (_bValidData) {
		[self.outletGraph drawData:context :_pLeftDst[g_oSetData.Dst.nFreqHD] :_pRightDst[g_oSetData.Dst.nFreqHD] :_pFreq :_nFreqCount :_nFreqStart :_nFreqEnd :_nFreqPoint];
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

- (void)initLevelSlider
{
	int nLevel;
	NSString *str;

	self.outletLevelSlider.minValue = MIN_LEVEL_VAL;
	self.outletLevelSlider.maxValue = MAX_LEVEL_VAL;
	self.outletLevelSlider.value = g_oSetData.Dst.nFreqLevel;

	for (nLevel = MIN_LEVEL_VAL; nLevel <= MAX_LEVEL_VAL; nLevel += 10) {
		if (abs(nLevel) % 20 == 0)
			str = [NSString stringWithFormat:@"%d", nLevel];
		else
			str = @"";
		[self.outletLevelSlider addTic:nLevel :str];
	}
}

- (IBAction)onChangeLevelSlider:(id)sender
{
	[self setLevel:self.outletLevelSlider.value];
}

- (void)setLevel:(int)nLevel
{
	if (nLevel < MIN_LEVEL_VAL)
		nLevel = MIN_LEVEL_VAL;
	else if (nLevel > MAX_LEVEL_VAL)
		nLevel = MAX_LEVEL_VAL;

	self.outletLevelEdit.intValue = -nLevel;
	self.outletLevelSlider.value = nLevel;
	g_oSetData.Dst.nFreqLevel = nLevel;
}

- (IBAction)onChangeLevelEdit:(id)sender
{
	[self setLevel:-self.outletLevelEdit.intValue];
}

- (void)initialize
{
	[self freeBuffers];

	[self.outletFreqCurrent blank];
	[self.outletLeftTHD blank];
	[self.outletRightTHD blank];
	[self.outletGraph updateGraph];

	_bValidData = YES;
	_fFreqCurrent = g_oSetData.Dst.nFreqStart;
	_fFreqStep = pow((float)g_oSetData.Dst.nFreqEnd / g_oSetData.Dst.nFreqStart, 1.0 / (g_oSetData.Dst.nFreqPoint - 1));
	_nFreqPoint = g_oSetData.Dst.nFreqPoint;
	_nFreqCount = 0;

	for (int i = 0; i < 3; i++) {
		_pLeftDst[i] = new float[_nFreqPoint];
		if (g_oSetData.Dst.nChannel == 1)
			_pRightDst[i] = new float[_nFreqPoint];
	}

	_pFreq = new float[_nFreqPoint];
}

- (BOOL)waveOutData:(int *)nFreq :(float *)fLevel
{
	*nFreq = (int)(_fFreqCurrent + 0.5);
	*fLevel = g_oSetData.Dst.nFreqLevel;

	self.outletFreqCurrent.intValue = *nFreq;

	return YES;
}

- (BOOL)notifyTHD:(const float *)pLeftDst :(const float *)pRightDst
{
	for (int i = 0; i < 3; i++) {
		_pLeftDst[i][_nFreqCount] = pLeftDst[i];
		if (g_oSetData.Dst.nChannel == 1)
			_pRightDst[i][_nFreqCount] = pRightDst[i];
	}

	_pFreq[_nFreqCount] = _fFreqCurrent;
	++_nFreqCount;

	[self dispTHD:pLeftDst[g_oSetData.Dst.nFreqHD] :pRightDst[g_oSetData.Dst.nFreqHD]];
	[self.outletGraph updateData];

	if (_nFreqCount < _nFreqPoint) {
		_fFreqCurrent *= _fFreqStep;
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

	if (_pFreq != NULL) {
		delete [] _pFreq;
		_pFreq = NULL;
	}

	_bValidData = NO;
}

- (IBAction)onChangeFreqStart:(id)sender
{
	int nFreqStart = self.outletFreqStart.intValue;

	if (nFreqStart <= 1)
		nFreqStart = 1;

	if (nFreqStart != g_oSetData.Dst.nFreqStart) {
		g_oSetData.Dst.nFreqStart = nFreqStart;
		[self.outletGraph updateGraph];
	}
}

- (IBAction)onChangeFreqEnd:(id)sender
{
	int nFreqEnd = self.outletFreqEnd.intValue;

	if (nFreqEnd <= 1)
		nFreqEnd = 1;

	if (nFreqEnd != g_oSetData.Dst.nFreqEnd) {
		g_oSetData.Dst.nFreqEnd = nFreqEnd;
		[self.outletGraph updateGraph];
	}
}

- (IBAction)onChangeFreqPoint:(id)sender
{
	int nFreqPoint = self.outletFreqPoint.intValue;

	if (nFreqPoint <= 1)
		nFreqPoint = 1;

	g_oSetData.Dst.nFreqPoint = nFreqPoint;
}

- (IBAction)onChangeFreqSpline:(id)sender
{
	if (g_oSetData.Dst.bFreqSpline != self.outletFreqSpline.checked) {
		g_oSetData.Dst.bFreqSpline = self.outletFreqSpline.checked;
		[self.outletGraph updateGraph];
	}
}

- (IBAction)onChangeChkMarker:(id)sender
{
	g_oSetData.Dst.bFreqMarker = self.outletChkMarker.checked;
	[self.outletGraph updateGraph];
}

- (IBAction)onChangeComboHd:(id)sender
{
	g_oSetData.Dst.nFreqHD = self.outletComboHD.selectedIndex;
	[self.outletGraph updateGraph];
}

@end
