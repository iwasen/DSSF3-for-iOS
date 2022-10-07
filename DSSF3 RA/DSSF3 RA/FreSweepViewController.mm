//
//  FreSweepViewController.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/05/29.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "FreSweepViewController.h"
#import "Common.h"

#define MIN_LEVEL_VAL	-60
#define MAX_LEVEL_VAL	0

#define RESOLUTION	10

@interface FreSweepViewController ()

@property (nonatomic, weak) IBOutlet FreGraphView *outletGraph;
@property (nonatomic, weak) IBOutlet CtTextField *outletFreqStart;
@property (nonatomic, weak) IBOutlet CtTextField *outletFreqEnd;
@property (nonatomic, weak) IBOutlet CtTextField *outletSweepTime;
@property (nonatomic, weak) IBOutlet CtTextField *outletFreqCurrent;
@property (nonatomic, weak) IBOutlet CtSlider *outletLevelSlider;
@property (nonatomic, weak) IBOutlet CtTextField *outletLevelEdit;

@end

@implementation FreSweepViewController
{
    int _nSampleRate;
    int _nChannel;
    float *_pLeftData;
    float *_pRightData;
    float *_pFreq;
    float _fFreqCurrent;
    float _fFreqStep;
    float _fSweepAngle;
    float _fSweepStep;
    float _fSweepFreq;
    float _fSweepEnd;
    int _nFreqPoint;
    int _nFreqCount;
    int _nFreqStart;
    int _nFreqEnd;
    BOOL _bValidData;
    int _nWaveBufSize;
    float _fLevel;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];

	[self.outletGraph initialize:0 :g_oSetData.Fre.nSweepFreqStart :g_oSetData.Fre.nSweepFreqEnd];

	[self initLevelSlider];

	self.outletFreqStart.intValue = g_oSetData.Fre.nSweepFreqStart;
	self.outletFreqEnd.intValue = g_oSetData.Fre.nSweepFreqEnd;
	self.outletSweepTime.intValue = g_oSetData.Fre.nSweepTime;
	self.outletLevelEdit.intValue = -g_oSetData.Fre.nSweepLevel;

	[self.outletGraph updateGraph];
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

- (void)drawGraphScale:(CGContextRef)context
{
	if (!_bValidData) {
		_nFreqStart = g_oSetData.Fre.nSweepFreqStart;
		_nFreqEnd = g_oSetData.Fre.nSweepFreqEnd;
		_nFreqCount = 0;
	}

	[self.outletGraph drawScale:context :_nFreqStart :_nFreqEnd];
}

- (void)drawGraphData:(CGContextRef)context
{
	[self.outletGraph drawData:context :_pLeftData :_pRightData :_pFreq :_nFreqCount :_nFreqStart :_nFreqEnd :0];
}

- (IBAction)onChangeFreqStart:(id)sender
{
	int nFreqStart = self.outletFreqStart.intValue;

	if (nFreqStart <= 1)
		nFreqStart = 1;

	if (nFreqStart != g_oSetData.Fre.nSweepFreqStart) {
		g_oSetData.Fre.nSweepFreqStart = nFreqStart;
		[self.outletGraph updateGraph];
	}
}

- (IBAction)onChangeFreqEnd:(id)sender
{
	int nFreqEnd = self.outletFreqEnd.intValue;

	if (nFreqEnd <= 1)
		nFreqEnd = 1;

	if (nFreqEnd != g_oSetData.Fre.nSweepFreqEnd) {
		g_oSetData.Fre.nSweepFreqEnd = nFreqEnd;
		[self.outletGraph updateGraph];
	}
}

- (IBAction)onChangeSweepTime:(id)sender
{
	int nSweepTime = self.outletSweepTime.intValue;

	if (nSweepTime <= 1)
		nSweepTime = 1;

	g_oSetData.Fre.nSweepTime = nSweepTime;
}

- (IBAction)onChangeLevelEdit:(id)sender
{
	[self setLevel:-self.outletLevelEdit.intValue];
}

- (IBAction)onChangeLevelSlider:(id)sender
{
	[self setLevel:self.outletLevelSlider.value];
}

- (void)initLevelSlider
{
	self.outletLevelSlider.minValue = MIN_LEVEL_VAL;
	self.outletLevelSlider.maxValue = MAX_LEVEL_VAL;
	self.outletLevelSlider.value = g_oSetData.Fre.nSweepLevel;

	for (int nLevel = MIN_LEVEL_VAL; nLevel <= MAX_LEVEL_VAL; nLevel += 10)
		[self.outletLevelSlider addTic:nLevel :-nLevel % 20 == 0 ? [NSString stringWithFormat:@"%d", nLevel] : @""];
}

- (void)setLevel:(int)nLevel
{
	if (nLevel < MIN_LEVEL_VAL)
		nLevel = MIN_LEVEL_VAL;
	else if (nLevel > MAX_LEVEL_VAL)
		nLevel = MAX_LEVEL_VAL;

	self.outletLevelEdit.intValue = -nLevel;
	self.outletLevelSlider.value = nLevel;
	g_oSetData.Fre.nSweepLevel = nLevel;
}

- (int)initialize
{
	[self freeBuffers];

	[self.outletFreqCurrent blank];
	[self.outletGraph updateGraph];

	_bValidData = YES;
	_nSampleRate = g_oSetData.Fre.nSampleRate;
	_nChannel = g_oSetData.Fre.nChannel + 1;
	_fFreqCurrent = g_oSetData.Fre.nSweepFreqStart;
	_fFreqStep = pow((float)g_oSetData.Fre.nSweepFreqEnd / g_oSetData.Fre.nSweepFreqStart, 1.0 / (g_oSetData.Fre.nSweepTime * RESOLUTION));
	_nFreqPoint = g_oSetData.Fre.nSweepTime * RESOLUTION + 1;
	_nFreqCount = 0;
	_nWaveBufSize = g_oSetData.Fre.nSampleRate / RESOLUTION;
	_fSweepAngle = 0;
	_fSweepStep = pow((float)g_oSetData.Fre.nSweepFreqEnd / g_oSetData.Fre.nSweepFreqStart, 1.0 / (g_oSetData.Fre.nSampleRate * g_oSetData.Fre.nSweepTime));
	_fSweepFreq = g_oSetData.Fre.nSweepFreqStart / sqrt(_fFreqStep);
	_fSweepEnd = g_oSetData.Fre.nSweepFreqEnd * sqrt(_fFreqStep);
	_fLevel = pow(10.0, g_oSetData.Fre.nSweepLevel / 20.0);

	_pLeftData = new float[_nFreqPoint];
	if (g_oSetData.Fre.nChannel == 1) {
		_pRightData = new float[_nFreqPoint];
	}

	_pFreq = new float[_nFreqPoint];

	return _nWaveBufSize;
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

	if (_pFreq != NULL) {
		delete [] _pFreq;
		_pFreq = NULL;
	}

	_bValidData = NO;
}

- (BOOL)waveOutData:(float *)pData
{
	for (int i = 0; i < _nWaveBufSize; i++) {
		if (_fSweepFreq <= _fSweepEnd) {
			*pData++ = sin(2 * M_PI * _fSweepAngle) * _fLevel;

			float fAngleStep = _fSweepFreq / _nSampleRate;
			_fSweepAngle += fAngleStep;
			while (_fSweepAngle >= 1)
				_fSweepAngle -= 1;

			_fSweepFreq *= _fSweepStep;
		} else
			*pData++ = 0;
	}

	self.outletFreqCurrent.text = [NSString stringWithFormat:@"%.0f", _fFreqCurrent];

	return NO;
}

- (BOOL)waveInData:(const float *)pLeftData :(const float *)pRightData
{
	if (_nFreqCount < _nFreqPoint) {
		_pLeftData[_nFreqCount] = [self calcFreqResponse:pLeftData :_fFreqCurrent];
		if (_nChannel == 2)
			_pRightData[_nFreqCount] = [self calcFreqResponse:pRightData :_fFreqCurrent];

		_pFreq[_nFreqCount++] = _fFreqCurrent;

		[self.outletGraph updateData];

		_fFreqCurrent *= _fFreqStep;
		if (_fFreqCurrent > g_oSetData.Fre.nSweepFreqEnd)
			_fFreqCurrent = g_oSetData.Fre.nSweepFreqEnd;
	}

	return _nFreqCount < _nFreqPoint;
}

- (float)calcFreqResponse:(const float *)pData :(float)fFreq
{
	int i;
/*
	float fFilter;
	int nFilterData = oMicCalData.nFreqData;
	if (nFilterData < 3)
		fFilter = 1;
	else {
		CSpline spline;
		FilterData *pFilterData = (FilterData *)oMicCalData.aFreq;
		float *pFreq = new float[nFilterData];
		float *pLevel = new float[nFilterData];

		for (i = 0; i < nFilterData; i++) {
			pFreq[i] = log(pFilterData->fFreq);
			pLevel[i] = pFilterData->fLevel;
			pFilterData++;
		}

		spline.MakeTable(pFreq, pLevel, nFilterData);

		fFilter = pow(10.0, spline.Spline(log(fFreq)) / 20);

		delete [] pFreq;
		delete [] pLevel;
	}

	fFilter = pow(10.0, -oMicCalData.fInputSens / 20) / fFilter;
*/
	float fOffset = 0;
	for (i = 0; i < _nWaveBufSize; i++)
		fOffset += pData[i];
	fOffset /= _nWaveBufSize;

	float fSum = 0;
	for (i = 0; i < _nWaveBufSize; i++) {
		float fData = (*pData++ - fOffset)/* * fFilter*/;
		fSum += fData * fData;
	}

	return fSum / _nWaveBufSize;
}

- (BOOL)checkDataExist
{
	return _bValidData && _nFreqCount != 0;
}

- (void)updateGraph
{
	[self.outletGraph updateGraph];
}

- (void)changeSampleRate
{

}

@end
