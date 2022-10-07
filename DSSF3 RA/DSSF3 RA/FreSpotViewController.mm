//
//  FreSpotViewController.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/05/29.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "FreSpotViewController.h"
#import "Common.h"

#define MIN_LEVEL_VAL	-60
#define MAX_LEVEL_VAL	0

#define GUARD_CNT	2

@interface FreSpotViewController ()

@property (nonatomic, weak) IBOutlet FreGraphView *outletGraph;
@property (nonatomic, weak) IBOutlet CtTextField *outletFreqStart;
@property (nonatomic, weak) IBOutlet CtTextField *outletFreqEnd;
@property (nonatomic, weak) IBOutlet CtTextField *outletFreqPoint;
@property (nonatomic, weak) IBOutlet CtTextField *outletFreqCurrent;
@property (nonatomic, weak) IBOutlet CtSlider *outletLevelSlider;
@property (nonatomic, weak) IBOutlet CtTextField *outletLevelEdit;

@end

@implementation FreSpotViewController
{
    int _nSampleRate;
    int _nChannel;
    float *_pWaveLeft;
    float *_pWaveRight;
    float *_pLeftData;
    float *_pRightData;
    float *_pFreq;
    float _fFreqCurrent;
    float _fFreqStep;
    float _fLevel;
    int _nFreqPoint;
    int _nFreqCount;
    int _nFreqStart;
    int _nFreqEnd;
    float _fAngle;
    int _nWaveInOffset;
    int _nWaveBufSize;
    int _nGuardCnt;
    BOOL _bValidData;
    BOOL _bFreqChange;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	[self.outletGraph initialize:1 :g_oSetData.Fre.nSpotFreqStart :g_oSetData.Fre.nSpotFreqEnd];

	[self initLevelSlider];

	self.outletFreqStart.intValue = g_oSetData.Fre.nSpotFreqStart;
	self.outletFreqEnd.intValue = g_oSetData.Fre.nSpotFreqEnd;
	self.outletFreqPoint.intValue = g_oSetData.Fre.nSpotPoint;
	self.outletLevelEdit.intValue = -g_oSetData.Fre.nSpotLevel;

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
		_nFreqStart = g_oSetData.Fre.nSpotFreqStart;
		_nFreqEnd = g_oSetData.Fre.nSpotFreqEnd;
		_nFreqCount = 0;
		_nFreqPoint = 0;
	}

	[self.outletGraph drawScale:context :_nFreqStart :_nFreqEnd];
}

- (void)drawGraphData:(CGContextRef)context
{
/*
	SDataHold oDataHold;
	POSITION pos;
	for (pos = m_oDataHoldList.GetHeadPosition(); pos != NULL; m_oDataHoldList.GetNext(pos)) {
		oDataHold = m_oDataHoldList.GetAt(pos);
		m_cGraph.DispGraph(oDataHold.pLeftData, oDataHold.pRightData, oDataHold.pFreq, oDataHold.nFreqCount, m_nFreqStart, m_nFreqEnd, oDataHold.nFreqPoint, NO, oDataHold.colorLeft, oDataHold.colorRight);
	}
*/
	[self.outletGraph drawData:context :_pLeftData :_pRightData :_pFreq :_nFreqCount :_nFreqStart :_nFreqEnd :_nFreqPoint];
}

- (IBAction)onChangeFreqStart:(id)sender
{
	int nFreqStart = self.outletFreqStart.intValue;

	if (nFreqStart <= 1)
		nFreqStart = 1;

	if (nFreqStart != g_oSetData.Fre.nSpotFreqStart) {
		g_oSetData.Fre.nSpotFreqStart = nFreqStart;
		[self.outletGraph updateGraph];
	}
}

- (IBAction)onChangeFreqEnd:(id)sender
{
	int nFreqEnd = self.outletFreqEnd.intValue;

	if (nFreqEnd <= 1)
		nFreqEnd = 1;

	if (nFreqEnd != g_oSetData.Fre.nSpotFreqEnd) {
		g_oSetData.Fre.nSpotFreqEnd = nFreqEnd;
		[self.outletGraph updateGraph];
	}
}

- (IBAction)onChangeFreqPoint:(id)sender
{
	int nFreqPoint = self.outletFreqPoint.intValue;

	if (nFreqPoint <= 1)
		nFreqPoint = 1;

	g_oSetData.Fre.nSpotPoint = nFreqPoint;
}

- (IBAction)onChangeLevelEdit:(id)sender
{
	[self setLevel:-self.outletLevelEdit.intValue];
}

- (IBAction)onChnageLevelSlider:(id)sender
{
	[self setLevel:self.outletLevelSlider.value];
}

- (void)initLevelSlider
{
	self.outletLevelSlider.minValue = MIN_LEVEL_VAL;
	self.outletLevelSlider.maxValue = MAX_LEVEL_VAL;
	self.outletLevelSlider.value = g_oSetData.Fre.nSpotLevel;

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
	g_oSetData.Fre.nSpotLevel = nLevel;
}

- (int)initialize
{
	[self freeBuffers];

	[self.outletFreqCurrent blank];
	[self.outletGraph updateGraph];

	_bValidData = YES;
	_nSampleRate = g_oSetData.Fre.nSampleRate;
	_nChannel = g_oSetData.Fre.nChannel + 1;
	_fFreqCurrent = g_oSetData.Fre.nSpotFreqStart;
	_fFreqStep = pow((float)g_oSetData.Fre.nSpotFreqEnd / g_oSetData.Fre.nSpotFreqStart, 1.0 / (g_oSetData.Fre.nSpotPoint - 1));
	_nFreqPoint = g_oSetData.Fre.nSpotPoint;
	_nFreqCount = 0;
	_fLevel = pow(10.0, g_oSetData.Fre.nSpotLevel / 20.0);
	_nWaveInOffset = 0;
	_fAngle = 0;
	_nWaveBufSize = g_oSetData.Fre.nSampleRate / 5;
	_bFreqChange = NO;
	_nGuardCnt = GUARD_CNT;

	_pLeftData = new float[_nFreqPoint];
	_pWaveLeft = new float[_nSampleRate];
	if (g_oSetData.Fre.nChannel == 1) {
		_pWaveRight = new float[_nSampleRate];
		_pRightData = new float[_nFreqPoint];
	}
	_pFreq = new float[_nFreqPoint];

	return _nWaveBufSize;
}

- (void)freeBuffers
{
	if (_pWaveLeft != NULL) {
		delete [] _pWaveLeft;
		_pWaveLeft = NULL;
	}

	if (_pWaveRight != NULL) {
		delete [] _pWaveRight;
		_pWaveRight = NULL;
	}

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
	int bReset = NO;

	if (_bFreqChange) {
		_bFreqChange = NO;
		_nGuardCnt = GUARD_CNT;
		_nWaveInOffset = 0;
		_fAngle = 0;
		bReset = YES;
	}

	float fAngleStep = _fFreqCurrent / _nSampleRate * 2 * M_PI;
	for (int i = 0; i < _nWaveBufSize; i++) {
		*pData++ = sin(_fAngle) * _fLevel;

		_fAngle += fAngleStep;
		while (_fAngle >= 2 * M_PI)
			_fAngle -= 2 * M_PI;
	}

	self.outletFreqCurrent.text = [NSString stringWithFormat:@"%.0f", _fFreqCurrent];

	return bReset;
}

- (BOOL)waveInData:(const float *)pLeftData :(const float *)pRightData
{
	int i;

	if (_nGuardCnt > 0) {
		_nGuardCnt--;
		return YES;
	}

	for (i = 0; i < _nWaveBufSize; i++) {
		_pWaveLeft[_nWaveInOffset] = *pLeftData++;
		if (_nChannel == 2)
			_pWaveRight[_nWaveInOffset] = *pRightData++;

		_nWaveInOffset++;
	}

	if (_nWaveInOffset == _nSampleRate) {
		_nWaveInOffset = 0;

		if (_nFreqCount < _nFreqPoint) {
			_pLeftData[_nFreqCount] = [self calcFreqResponse:_pWaveLeft :_fFreqCurrent];
			if (_nChannel == 2)
				_pRightData[_nFreqCount] = [self calcFreqResponse:_pWaveRight :_fFreqCurrent];

			_pFreq[_nFreqCount++] = _fFreqCurrent;

			[self.outletGraph updateData];

			_fFreqCurrent *= _fFreqStep;

			if (_fFreqCurrent > g_oSetData.Fre.nSpotFreqEnd)
				_fFreqCurrent = g_oSetData.Fre.nSpotFreqEnd;

			_bFreqChange = YES;
		}
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
	float fSinSum = 0;
	float fCosSum = 0;
	float fAngleStep = _fFreqCurrent / _nSampleRate * 2 * M_PI;
	float fAngle = 0;
	for (i = 0; i < _nSampleRate; i++) {
		fSinSum += pData[i] * sin(fAngle);
		fCosSum += pData[i] * cos(fAngle);

		fAngle += fAngleStep;
		while (fAngle >= 2 * M_PI)
			fAngle -= 2 * M_PI;
	}

	fSinSum = fSinSum/* * fFilter*/ / _nSampleRate;
	fCosSum = fCosSum/* * fFilter*/ / _nSampleRate;

	return (fSinSum * fSinSum + fCosSum * fCosSum) * 2;
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
