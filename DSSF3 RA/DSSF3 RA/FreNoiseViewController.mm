//
//  FreNoiseViewController.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/05/29.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "FreNoiseViewController.h"
#import "Common.h"
#import "Noise.h"
#import "Filter.h"

#define MIN_LEVEL_VAL	-60
#define MAX_LEVEL_VAL	0

static const int s_tFftSize[] = {32768, 16384, 8192, 4096};
static const int s_tTimeConstant[] = {1, 2, 4, 8, 16};

@interface FreNoiseViewController ()

@property (nonatomic, weak) IBOutlet FreGraphView *outletGraph;
@property (nonatomic, weak) IBOutlet CtTextField *outletFreqStart;
@property (nonatomic, weak) IBOutlet CtTextField *outletFreqEnd;
@property (nonatomic, weak) IBOutlet CtSlider *outletLevelSlider;
@property (nonatomic, weak) IBOutlet CtTextField *outletLevelEdit;
@property (nonatomic, weak) IBOutlet CtComboBox *outletResolution;
@property (nonatomic, weak) IBOutlet CtComboBox *outletAveraging;

@end

@implementation FreNoiseViewController
{
    int _nSampleRate;
    int _nChannel;
    float *_pWaveLeft;
    float *_pWaveRight;
    CAverageBuf _oLeftData;
    CAverageBuf _oRightData;
    float *_pFreq;
    int _nFreqStart;
    int _nFreqEnd;
    int _nLevel;
    int _nWaveBufSize;
    int _nFreqPoint;
    BOOL _bValidData;
    CRFFT _oFFT;
    CNoise _oNoise;
    float *_pFilterTblL;
    float *_pFilterTblR;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	[self.outletGraph initialize:2 :g_oSetData.Fre.nNoiseFreqStart :g_oSetData.Fre.nNoiseFreqEnd];

	[self initLevelSlider];

	[self setResolutionList];
	[self setAveragingList];

	self.outletFreqStart.intValue = g_oSetData.Fre.nNoiseFreqStart;
	self.outletFreqEnd.intValue = g_oSetData.Fre.nNoiseFreqEnd;
	self.outletLevelEdit.intValue = -g_oSetData.Fre.nNoiseLevel;
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
		_nFreqStart = g_oSetData.Fre.nNoiseFreqStart;
		_nFreqEnd = g_oSetData.Fre.nNoiseFreqEnd;
		_nFreqPoint = 0;
	}

	[self.outletGraph drawScale:context :_nFreqStart :_nFreqEnd];
}

- (void)drawGraphData:(CGContextRef)context
{
	[self.outletGraph drawData:context
						  :_oLeftData.GetBuf() + 1
						  :_nChannel == 1 ? NULL : _oRightData.GetBuf() + 1
						  :_pFreq + 1 :_nFreqPoint == 0 ? 0 : _nFreqPoint - 1
						  :_nFreqStart :_nFreqEnd :0];
}

- (IBAction)onChangeFreqStart:(id)sender
{
	int nFreqStart = self.outletFreqStart.intValue;

	if (nFreqStart <= 1)
		nFreqStart = 1;

	if (nFreqStart != g_oSetData.Fre.nNoiseFreqStart) {
		g_oSetData.Fre.nNoiseFreqStart = nFreqStart;
		[self.outletGraph updateGraph];
	}
}

- (IBAction)onChangeFreqEnd:(id)sender
{
	int nFreqEnd = self.outletFreqEnd.intValue;

	if (nFreqEnd <= 1)
		nFreqEnd = 1;

	if (nFreqEnd != g_oSetData.Fre.nNoiseFreqEnd) {
		g_oSetData.Fre.nNoiseFreqEnd = nFreqEnd;
		[self.outletGraph updateGraph];
	}
}

- (IBAction)onChangeLevelEdit:(id)sender
{
	[self setLevel:-self.outletLevelEdit.intValue];
}

- (IBAction)onChangeResolution:(id)sender
{
	g_oSetData.Fre.nNoiseResolution = self.outletResolution.selectedIndex;
//	CFreDlg *pDlg = (CFreDlg *)GetParent();
//	pDlg->Restart();
}

- (IBAction)onChangeAveraging:(id)sender
{
	g_oSetData.Fre.nNoiseAveraging = self.outletAveraging.selectedIndex;

	if (_bValidData)
		[self allocAverageBuf];
}

- (IBAction)onChangeLevelSlider:(id)sender
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
	g_oSetData.Fre.nNoiseLevel = nLevel;
}

- (int)initialize
{
	[self freeBuffers];

	[self.outletGraph updateGraph];

	_bValidData = YES;
	_nSampleRate = g_oSetData.Fre.nSampleRate;
	_nChannel = g_oSetData.Fre.nChannel + 1;
	_nWaveBufSize = s_tFftSize[g_oSetData.Fre.nNoiseResolution];
	_nFreqPoint = _nWaveBufSize / 2;
	_nLevel = g_oSetData.Fre.nNoiseLevel;

	_pWaveLeft = new float[_nWaveBufSize];
	if (g_oSetData.Fre.nChannel == 1)
		_pWaveRight = new float[_nWaveBufSize];

	_pFreq = new float[_nFreqPoint];

	[self allocAverageBuf];

	for (int i = 0; i < _nFreqPoint; i++)
		_pFreq[i] = (float)_nSampleRate / _nWaveBufSize * i;

	[self makeFilterTbl];

	return _nWaveBufSize;
}

- (void)allocAverageBuf
{
	int nAverageNum = (s_tTimeConstant[g_oSetData.Fre.nNoiseAveraging] * _nSampleRate + _nWaveBufSize / 2) / _nWaveBufSize;
	_oLeftData.Alloc(_nFreqPoint, nAverageNum);
	if (_nChannel == 2)
		_oRightData.Alloc(_nFreqPoint, nAverageNum);
}

- (void)setResolutionList
{
	NSString *sText;

	[self.outletResolution resetContent];
	for (int i = 0; i < sizeof(s_tFftSize) / sizeof(int); i++) {
		sText = [NSString stringWithFormat:@"%.1f Hz", (float)g_oSetData.Fre.nSampleRate / s_tFftSize[i]];
		[self.outletResolution addItem:sText :0];
	}
	self.outletResolution.selectedIndex = g_oSetData.Fre.nNoiseResolution;
}

- (void)setAveragingList
{
	NSString *sText;

	[self.outletAveraging resetContent];
	for (int i = 0; i < sizeof(s_tTimeConstant) / sizeof(int); i++) {
		sText = [NSString stringWithFormat:@"%d s", s_tTimeConstant[i]];
		[self.outletAveraging addItem:sText :0];
	}
	self.outletAveraging.selectedIndex = g_oSetData.Fre.nNoiseAveraging;
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

	if (_pFreq != NULL) {
		delete [] _pFreq;
		_pFreq = NULL;
	}

	if (_pFilterTblL != NULL) {
		delete [] _pFilterTblL;
		_pFilterTblL = NULL;
	}

	if (_pFilterTblR != NULL) {
		delete [] _pFilterTblR;
		_pFilterTblR = NULL;
	}

	_bValidData = NO;
}

- (BOOL)waveOutData:(float *)pData
{
	BOOL bReset = NO;

	if (_nLevel != g_oSetData.Fre.nNoiseLevel) {
		bReset = YES;
		_nLevel = g_oSetData.Fre.nNoiseLevel;
	}

	float fLevel = pow(10.0, _nLevel / 20.0);
	_oNoise.GeneratePinkNoise(pData, _nWaveBufSize, fLevel);

	return bReset;
}

- (BOOL)waveInData:(const float *)pLeftData :(const float *)pRightData
{
	for (int i = 0; i < _nWaveBufSize; i++) {
		_pWaveLeft[i] = *pLeftData++;
		if (_nChannel == 2)
			_pWaveRight[i] = *pRightData++;
	}

	[self calcFreqResponse:_pWaveLeft :_oLeftData.GetBuf() :_pFilterTblL];
	_oLeftData.Averaging();
	if (_nChannel == 2) {
		[self calcFreqResponse:_pWaveRight :_oRightData.GetBuf() :_pFilterTblR];
		_oRightData.Averaging();
	}

	[self.outletGraph updateData];

	return YES;
}

- (void)calcFreqResponse:(float *)pWave :(float *)pData :(const float *)pFilterTbl
{
	int i, j;
	float xt, yt;

	_oFFT.fft(_nWaveBufSize, pWave);

	for (i = 1; i < _nFreqPoint; i++) {
		j = i * 2;
		xt = pWave[j] * pFilterTbl[i];
		yt = pWave[j + 1] * pFilterTbl[i];

		*pData++ = (xt * xt + yt * yt) * i;
	}
}

- (BOOL)checkDataExist
{
	return _bValidData != 0;
}

- (void)makeFilterTbl
{
//	CFreDlg *pDlg = (CFreDlg *)GetParent();

	_pFilterTblL = new float[_nWaveBufSize];
	_pFilterTblR = new float[_nWaveBufSize];

	MakeFilterTbl3(_pFilterTblL, _nWaveBufSize, _nSampleRate, /*(FilterData *)pDlg->m_oMicCalDataL.aFreq*/NULL, /*pDlg->m_oMicCalDataL.nFreqData*/0, 20);
	MakeFilterTbl3(_pFilterTblR, _nWaveBufSize, _nSampleRate, /*(FilterData *)pDlg->m_oMicCalDataR.aFreq*/NULL, /*pDlg->m_oMicCalDataR.nFreqData*/0, 20);
	float sensL = 1.0;//pow(10.0, -pDlg->m_oMicCalDataL.fInputSens / 20);
	float sensR = 1.0;//pow(10.0, -pDlg->m_oMicCalDataR.fInputSens / 20);

	_pFilterTblL[0] = 0;
	_pFilterTblR[0] = 0;

	float t = (g_oSetData.Fre.nMicCalID == -1) ? _nWaveBufSize * 0.0525 : _nWaveBufSize * 0.052;
	for (int i = 1; i < _nWaveBufSize; i++) {
		_pFilterTblL[i] = sensL / (_pFilterTblL[i] * t);
		_pFilterTblR[i] = sensR / (_pFilterTblR[i] * t);
	}
}

- (void)updateGraph
{
	[self.outletGraph updateGraph];
}

- (void)changeSampleRate
{
	[self setResolutionList];
}

@end
