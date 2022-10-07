//
//  ImpViewController.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/06/15.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "ImpViewController.h"
#import "MSeq.h"
#import "TSP.h"

#define IDT_RETRY			5000
#define SCROLL_RANGE		16384
#define MAX_ZOOM_TIME		4096
#define CHECK_DATA_NUM		4096
#define INIT_LEVEL_AUTO		4
#define INIT_LEVEL_MANUAL	2

@interface ImpViewController ()

@property (nonatomic, weak) IBOutlet ImpView *outletImpulseL;
@property (nonatomic, weak) IBOutlet ImpView *outletImpulseR;
@property (nonatomic, weak) IBOutlet UIScrollView *outletScrollView;
@property (nonatomic, weak) IBOutlet CtButton *outletStartStop;
@property (nonatomic, weak) IBOutlet CtComboBox *outletSampleRate;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletChannel;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletMethod;
@property (nonatomic, weak) IBOutlet CtComboBox *outletMeasureTime;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletAutoRetry;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletAutoLevel;
@property (nonatomic, weak) IBOutlet CtTextField *outletMeasureNum;
@property (nonatomic, weak) IBOutlet CtTextField *outletMrTime;
@property (nonatomic, weak) IBOutlet CtTextField *outletMrSampling;
@property (nonatomic, weak) IBOutlet CtTextField *outletMrMTime;
@property (nonatomic, weak) IBOutlet CtTextField *outletMrMNum;
@property (nonatomic, weak) IBOutlet CtTextField *outletOffsetTime;
@property (nonatomic, weak) IBOutlet CtButton *outletExportAnalyze;
@property (nonatomic, weak) IBOutlet CtButton *outletExportImpulse;

@end

@implementation ImpViewController
{
    CMSeq _oMSeq;
    CTSP _oTSP;
    CIRMethod *_pMethod;
    float *_pWaveOutData;
    float *_pLeftInputData;
    float *_pRightInputData;
    float *_pLeftImpulseData;
    float *_pRightImpulseData;
    int _nStage;
    int _nData;
    int _nChannel;
    int _nRate;
    int _nOutPtr;
    int _nOutCounter;
    BOOL _bOutEnd;
    int _nInPtr;
    int _nInCounter;
    BOOL _bInEnd;
    int _nWaveBufNum;
    float _fTotalTime;
    float _fStartTime;
    float _fDispTime;
    int _nRetryCounter;
    int _nMeasureNum;
    NSDate *_measurementTime;
    CRFFT _oRFFT;
    //    float *_pIFilter;
    //    int _nIFilter;
    //    long _nIFilterID;
    //    int _nMaxAdjLevel;
    //    BOOL _bPhaseAdj;
    //    int _nIfaSampling;
    //    BOOL _bInitialized;
    //    int _nScrollSize;
    //    int _nScrollPos;
    float *_pCheckBuf;
    int _nCheckCount;
    int _nMultiplier;
    BOOL _bImpulseData;
    int _nMethod;
    BOOL _bValidData;
    //    int _nBitsPerSample;
    BOOL _bStart;
    NSTimer *_retryTimer;
    int _inputTime;
    int _outputTime;
    BOOL _firstData;
    UIDocumentInteractionController *_diController;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	NSString *str;
	str = NSLocalizedString(@"IDS_LEFTCHANNEL", nil);
	[self.outletImpulseL initialize:str :1];
	str = NSLocalizedString(@"IDS_RIGHTCHANNEL", nil);
	[self.outletImpulseR initialize:str :2];
    
    [self initViews];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(initViews) name:@"InitViews" object:nil];
}

- (void)initViews
{
	[self enableImpWindow];

	SetSampleRateList(self.outletSampleRate, g_oSetData.Imp.nSampleRate);

	self.outletChannel.selectedSegmentIndex = g_oSetData.Imp.nChannel;
	self.outletMeasureNum.intValue = g_oSetData.Imp.nMeasureNum;

	self.outletAutoLevel.checked = g_oSetData.Imp.bAutoLevel;
	self.outletAutoRetry.checked = g_oSetData.Imp.bAutoRetry;
	self.outletOffsetTime.floatValue = g_oSetData.Imp.fOffsetTime;

	self.outletMethod.selectedSegmentIndex = g_oSetData.Imp.nMethod;

	[self setTimeList];

	_fTotalTime = float(1 << (g_oSetData.Imp.nTime + STAGE_OFFSET)) / g_oSetData.Imp.nSampleRate;
	[self initDispTime];
	[self dispImpWindow];

	[self startStopButton:NO];
}

-(void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];

	if (IS_PHONE) {

		SetContentSize(self.outletScrollView);
	}
}

- (void)dealloc
{
	[self freeBuffers];
}

- (void)drawGraphData:(CGContextRef)context :(int)nChannel
{
	if (nChannel == 1)
		[self.outletImpulseL drawData:context :_fTotalTime :_fStartTime :_fDispTime :_pLeftImpulseData :_nData];
	else if (nChannel == 2)
		[self.outletImpulseR drawData:context :_fTotalTime :_fStartTime :_fDispTime :_pRightImpulseData :_nData];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)onChangeStartStop:(CtButton *)sender
{
	if (sender.selected) {
		[self cancelMeasuring];

		[self initDispTime];
		[self dispImpWindow];
	} else
		[self startMeasuring];
}

- (void)startMeasuring
{
	NSDate *date = [NSDate date];

	[self setMeasuringParameters:g_oSetData.Imp.nSampleRate :TOPMSEQPARAM + g_oSetData.Imp.nTime :g_oSetData.Imp.nMeasureNum :g_oSetData.Imp.nChannel + 1 :date :g_oSetData.Imp.nMethod :0];

	_nWaveBufNum = MIN(4096, _nData);

	_pCheckBuf = new float[_nData];
	_nCheckCount = 0;
	_bImpulseData = NO;

	_nRetryCounter = 0;
	_nMultiplier = g_oSetData.Imp.bAutoLevel ? INIT_LEVEL_AUTO : INIT_LEVEL_MANUAL;

	[self start];
	[self startStopButton:YES];
}

- (void)setMeasuringParameters:(int)nRate :(int)nStage :(int)nMeasureNum :(int)nChannel :(NSDate *)currentTime :(int)nMethod :(int)nData
{
	[self freeBuffers];

	_measurementTime = currentTime;
	_nMeasureNum = nMeasureNum;

	_nStage = nStage;
	_nData = (nData == 0) ? 1 << _nStage : nData;

	_nChannel = nChannel;
	_nRate = nRate;
	_nMethod = nMethod;

	_pLeftInputData = new float[_nData];
	_pLeftImpulseData = new float[_nData];
	if (_nChannel == 2) {
		_pRightInputData = new float[_nData];
		_pRightImpulseData = new float[_nData];
	}

	_pWaveOutData = new float[1 << _nStage];

	if (_nMethod == METHOD_MSEQ)
		_pMethod = &_oMSeq;
	else
		_pMethod = &_oTSP;

	_pMethod->InitMethod(nStage);
	_pMethod->GenerateSequence(_pWaveOutData, 1);
}

- (void)start
{
	_nOutPtr = 0;
	_nOutCounter = 0;
	_bOutEnd = NO;
	_nInPtr = 0;
	_nInCounter = 0;
	_bInEnd = NO;
	_firstData = YES;

	//_nBitsPerSample = _pWaveIn->GetBitsPerSample();

	if (!(g_oSetData.Imp.bAutoRetry || g_oSetData.Imp.bAutoLevel) || _nCheckCount % 2 == 1) {
		memset(_pLeftInputData, 0, _nData * sizeof(float));
		if (_pRightInputData != NULL)
			memset(_pRightInputData, 0, _nData * sizeof(float));
	}

	[AudioOutput prepare:_nRate :NUM_CHANNELS_1 :_nWaveBufNum :self];
	[AudioInputEx prepare:_nRate :_nChannel :_nWaveBufNum :self];

	[AudioOutput start];
	[AudioInputEx start];
}

- (void)cancelMeasuring
{
	[self stop];

	[AudioOutput stop];
	[AudioInputEx stop];

	[self freeBuffers];
}

- (void)stop
{
	[self startStopButton:NO];
}

- (void)freeBuffers
{
	if (_pWaveOutData != NULL) {
		delete [] _pWaveOutData;
		_pWaveOutData = NULL;
	}

	if (_pLeftInputData != NULL) {
		delete [] _pLeftInputData;
		_pLeftInputData = NULL;
	}

	if (_pRightInputData != NULL) {
		delete [] _pRightInputData;
		_pRightInputData = NULL;
	}

	if (_pLeftImpulseData != NULL) {
		delete [] _pLeftImpulseData;
		_pLeftImpulseData = NULL;
	}

	if (_pRightImpulseData != NULL) {
		delete [] _pRightImpulseData;
		_pRightImpulseData = NULL;
	}

	if (_pCheckBuf != NULL) {
		delete [] _pCheckBuf;
		_pCheckBuf = NULL;
	}

	[self validData:NO];
}

- (void)audioOutputStop
{
	_bOutEnd = YES;
	if (_bInEnd)
		[self endProcess];
}

- (void)audioOutputData:(AudioData *)audioData
{
	audioData->nDataSize = 0;

	if (!(g_oSetData.Imp.bAutoRetry || g_oSetData.Imp.bAutoLevel) || _nCheckCount % 2 == 1) {
		if (_nOutCounter >= _nMeasureNum + 1)
			return;
	} else {
		if (_nOutCounter >= 1)
			return;
	}

	for (int i = 0; i < _nWaveBufNum; i++) {
		audioData->pLeftData[i] = (_pWaveOutData[_nOutPtr] / _nMultiplier);
		if (++_nOutPtr >= _nData) {
			_nOutPtr = 0;
			_nOutCounter++;
			break;
		}
	}

	audioData->nDataSize = _nWaveBufNum;
}

- (void)audioInputStop
{
	_bInEnd = YES;
	if (_bOutEnd)
		[self endProcess];
}

- (void)audioInputData:(AudioData *)audioData
{
	int i;
	int nEndCount;

	if (_firstData) {
		_outputTime = [AudioOutput getTime];
		_inputTime = [AudioInputEx getTime];
		_firstData = NO;
	}

	if (!(g_oSetData.Imp.bAutoRetry || g_oSetData.Imp.bAutoLevel) || _nCheckCount % 2 == 1) {
		if (_nInCounter >= 1) {
			if (_nChannel == 1) {
				for (i = 0; i < _nWaveBufNum; i++, _nInPtr++)
					_pLeftInputData[_nInPtr] += audioData->pLeftData[i] / _nMeasureNum;
			} else {
				for (i = 0; i < _nWaveBufNum; i++, _nInPtr++) {
					_pLeftInputData[_nInPtr] += audioData->pLeftData[i] / _nMeasureNum;
					_pRightInputData[_nInPtr] += audioData->pRightData[i] / _nMeasureNum;
				}
			}
		} else
			_nInPtr += _nWaveBufNum;

		nEndCount = _nMeasureNum + 1;
	} else {
		for (i = 0; i < _nWaveBufNum; i++, _nInPtr++)
			_pCheckBuf[_nInPtr] = audioData->pLeftData[i];

		nEndCount = 1;
	}

	if (_nInPtr >= _nData) {
		_nInPtr = 0;
		_nInCounter++;
	}

	if (_nInCounter >= nEndCount)
		audioData->nDataSize = 0;
}

- (void)endProcess
{
	if (!_bStart)
		return;

	if (g_oSetData.Imp.bAutoLevel) {
		if (_nCheckCount == 0) {
			if ([self levelCheck:_pCheckBuf])
				_nCheckCount++;

			_retryTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)_nData / _nRate target:self selector:@selector(timerEvent:) userInfo:nil repeats:NO];
			return;
		}
	}

	if (g_oSetData.Imp.bAutoRetry) {
		int nCheckDataNum = MIN(_nData, CHECK_DATA_NUM);
		float *pCheck1 = _pLeftInputData + (_nData - nCheckDataNum);
		float *pCheck2 = _pCheckBuf + (_nData - nCheckDataNum);

		if (_nCheckCount == 0 || [self timingCheck:pCheck1 :pCheck2 :nCheckDataNum] > 10) {
			_nRetryCounter += _nCheckCount % 2;
			_nCheckCount++;
			_retryTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)_nData / _nRate target:self selector:@selector(timerEvent:) userInfo:nil repeats:NO];
			return;
		}
	}

	int nTimeOffset = (_outputTime - _inputTime) + (g_oSetData.Imp.fOffsetTime / 1000 * _nRate);
	[self shiftCopy:_pLeftImpulseData :_pLeftInputData :_nData :nTimeOffset];
	memcpy(_pLeftInputData, _pLeftImpulseData, _nData * sizeof(float));
	_pMethod->CalcImpulse(_pLeftImpulseData);
	[self normalize:_pLeftImpulseData :_nData];
	if (_nChannel == 2) {
		[self shiftCopy:_pRightImpulseData :_pRightInputData :_nData :nTimeOffset];
		memcpy(_pRightInputData, _pRightImpulseData, _nData * sizeof(float));
		_pMethod->CalcImpulse(_pRightImpulseData);
		[self normalize:_pRightImpulseData :_nData];
	}

	[self stop];

	_fTotalTime = float(_nData) / _nRate;
	[self initDispTime];
	[self dispImpWindow];

	[self dispMeasureParam];

	[self validData:YES];
}

- (void)shiftCopy:(float *)pTo :(float *)pFrom :(int)nData :(int)nShift
{
	int nCopy;

	if (nShift < 0) {
		nShift = -nShift % nData;
		nCopy = nData - nShift;
		memcpy(pTo, pFrom + nShift, nCopy * sizeof(float));
		memcpy(pTo + nCopy, pFrom, (nData - nCopy) * sizeof(float));
	} else {
		nShift = nShift % nData;
		nCopy = nData - nShift;
		memcpy(pTo + nShift, pFrom, nCopy * sizeof(float));
		memcpy(pTo, pFrom + nCopy, (nData - nCopy) * sizeof(float));
	}
}

- (void)normalize:(float *)pData :(int)nData
{
	float maxData = GetMaxData(pData, nData);
	if (maxData != 0) {
		for (int i = 0; i < nData; i++) {
			pData[i] = pData[i] / maxData;
		}
	}
}

- (void)timerEvent:(NSTimer *)timer
{
	if (_bStart)
		[self start];
}

- (int)timingCheck:(const float *)pData1 :(const float *)pData2 :(int)nCheckDataNum
{
	int i, j;
	float xt1, yt1, xt2, yt2;

	float *pBuf1 = new float[nCheckDataNum];
	float *pBuf2 = new float[nCheckDataNum];

	memcpy(pBuf1, pData1, nCheckDataNum * sizeof(float));
	memcpy(pBuf2, pData2, nCheckDataNum * sizeof(float));

	_oRFFT.fft(nCheckDataNum, pBuf1);
	_oRFFT.fft(nCheckDataNum, pBuf2);

	pBuf1[0] = 0;
	pBuf1[1] = 0;

	for (i = 1; i < nCheckDataNum / 2; i++) {
		j = i * 2;

		xt1 = pBuf1[j];
		yt1 = pBuf1[j + 1];

		xt2 = pBuf2[j];
		yt2 = pBuf2[j + 1];

		pBuf1[j] = xt1 * xt2 + yt1 * yt2;
		pBuf1[j + 1] = xt2 * yt1 - xt1 * yt2;
	}

	_oRFFT.ifft(nCheckDataNum, pBuf1);

	int index = 0;
	float max = 0;
	for (i = 0; i < nCheckDataNum; i++) {
		if (pBuf1[i] > max) {
			max = pBuf1[i];
			index = i;
		}
	}
	if (index > nCheckDataNum / 2)
		index = nCheckDataNum - index;

	delete [] pBuf1;
	delete [] pBuf2;

	return index;
}

- (BOOL)levelCheck:(const float *)pData
{
	float fMaxData;
	float fAbsData;
	int i;

	fMaxData = 0;
	for (i = 0; i < _nData; i++) {
		fAbsData = fabs(*pData++);
		if (fAbsData > fMaxData)
			fMaxData = fAbsData;
	}

	if (fMaxData >= 1.0) {
		_nMultiplier *= 2;
		return NO;
	}

	if (fMaxData < 1 / 4) {
		if (_nMultiplier != 1) {
			_nMultiplier /= 2;
			return NO;
		}
	}

	return YES;
}

- (IBAction)onChangeSampleRate:(CtComboBox *)sender
{
	g_oSetData.Imp.nSampleRate = sender.selectedItemData;
	[self setTimeList];
	[self initDispTime];
	[self dispImpWindow];
}

- (IBAction)onChangeChangeMeasureTime:(CtComboBox *)sender
{
	g_oSetData.Imp.nTime = sender.selectedIndex;
	[self initDispTime];
	[self dispImpWindow];
}

- (void)setTimeList
{
	float sps;
	int i;
	NSString *strBuf;

	[self.outletMeasureTime resetContent];
	sps = g_oSetData.Imp.nSampleRate;
	for (i = 0; i < STAGE_NUM; i++) {
		strBuf = [NSString stringWithFormat:@"%.3f s", (1 << (i + STAGE_OFFSET)) / sps];
		[self.outletMeasureTime addItem:strBuf :0];
	}
	self.outletMeasureTime.selectedIndex = g_oSetData.Imp.nTime;
}

- (IBAction)onChangeChannel:(UISegmentedControl *)sender
{
	g_oSetData.Imp.nChannel = (int)sender.selectedSegmentIndex;
	[self enableImpWindow];
	[self dispImpWindow];
}

- (void)enableImpWindow
{
	if (g_oSetData.Imp.nChannel == CH_MONO) {
		self.outletImpulseL.enabled = YES;
		self.outletImpulseR.enabled = NO;
	} else {
		self.outletImpulseL.enabled = YES;
		self.outletImpulseR.enabled = YES;
	}
}

- (void)initDispTime
{
//	_fTotalTime = float(1 << tMSeqParam[g_oSetData.Imp.nTime].nBit) / g_tSamplingRate[g_oSetData.Imp.nSamplingRate];
	_fDispTime = _fTotalTime;
	_fStartTime = 0;
}

- (void)dispImpWindow
{
	if (_fDispTime == 0)
		_fDispTime = _fTotalTime;
	else if (_fDispTime < _fTotalTime / MAX_ZOOM_TIME)
		_fDispTime = _fTotalTime / MAX_ZOOM_TIME;
	else if (_fDispTime > _fTotalTime)
		_fDispTime = _fTotalTime;

	if (_fStartTime < 0)
		_fStartTime = 0;
	else if (_fStartTime > _fTotalTime - _fDispTime)
		_fStartTime = _fTotalTime - _fDispTime;

	[self.outletImpulseL setNeedsDisplay];
	[self.outletImpulseR setNeedsDisplay];
}

- (void)startStopButton:(BOOL)bStart
{
	if (bStart) {
		self.outletStartStop.selected = YES;
		[self enableControl:NO];
	} else {
		self.outletStartStop.selected = NO;
		[self enableControl:YES];
	}

	_bStart = bStart;
}

- (void)dispMeasureParam
{
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
	self.outletMrTime.text = [formatter stringFromDate:_measurementTime];

	self.outletMrSampling.intValue = _nRate;
	self.outletMrMTime.text = [NSString stringWithFormat:@"%.3f", _nData / (float)_nRate];
	self.outletMrMNum.intValue = _nMeasureNum;
	//self.outletMrChannel = (_nChannel == 1) ? "Mono" : "Stereo";
}

- (void)validData:(BOOL)bValid
{
	_bValidData = bValid;
	self.outletExportAnalyze.enabled = bValid;
	self.outletExportImpulse.enabled = bValid;
}

- (IBAction)onChangeMeasureNum:(CtTextField *)sender
{
	g_oSetData.Imp.nMeasureNum = sender.intValue;
}

- (IBAction)onChangeAutoLevel:(CtCheckBox *)sender
{
	g_oSetData.Imp.bAutoLevel = sender.checked;
}

- (IBAction)onChangeAutoRetry:(CtCheckBox *)sender
{
	g_oSetData.Imp.bAutoRetry = sender.checked;
}

- (void)enableControl:(BOOL)bEnable
{
//	self.outletFileLoad.EnableWindow(bEnable);
	self.outletSampleRate .enabled = bEnable;
//	self.outletAssist.EnableWindow(bEnable);
	self.outletMethod.enabled = bEnable;
	self.outletAutoLevel.enabled = bEnable;
	self.outletAutoRetry.enabled = bEnable;
	self.outletMeasureTime.enabled = bEnable;
	self.outletMeasureNum.enabled = bEnable;
	self.outletChannel.enabled = bEnable;
//	self.outletIfaSet.EnableWindow(bEnable);
//	self.outletGraphScroll.EnableWindow(bEnable);
//	self.outletExit.EnableWindow(bEnable);
}

- (IBAction)onChangeMethod:(UISegmentedControl *)sender
{
	g_oSetData.Imp.nMethod = (int)sender.selectedSegmentIndex;
}

- (IBAction)onChangeOffsetTime:(CtTextField *)sender
{
	g_oSetData.Imp.fOffsetTime = sender.floatValue;
}

- (IBAction)onTouchExportAnalyze:(CtButton *)sender
{
	NSString *time;
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyyMMddHHmmss"];
	time = [formatter stringFromDate:_measurementTime];

	NSString *pathName = [NSString stringWithFormat:@"%@%@_%@_%d_%d_%d_%d_%d.dssf3",
						  NSTemporaryDirectory(),
						  @"impulse",
						  time,
						  _nRate,
						  _nChannel,
						  _nMethod,
						  _nStage,
						  _nMeasureNum];

	NSURL *url = SaveWavFile(_pLeftInputData, _pRightInputData, _nChannel, _nRate, _nData, pathName);
	[self sendWavFile:url :nil];
}

- (IBAction)onTouchExportImpulse:(CtButton *)sender
{
	NSString *time;
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyyMMdd_HHmmss"];
	time = [formatter stringFromDate:_measurementTime];

	NSString *pathName = [NSString stringWithFormat:@"%@dssf3_impulse_%@.wav", NSTemporaryDirectory(), time];
	NSURL *url = SaveWavFile(_pLeftImpulseData, _pRightImpulseData, _nChannel, _nRate, _nData, pathName);
	[self sendWavFile:url :nil];
}

- (void)sendWavFile:(NSURL *)url :(NSString *)UTI
{
	_diController = [UIDocumentInteractionController interactionControllerWithURL:url];
	DLog(@"[UTI=%@]", _diController.UTI);
	if (UTI != nil)
		_diController.UTI = UTI;

	[_diController presentOptionsMenuFromRect:self.outletImpulseL.frame inView:self.view animated:YES];
}

- (void)moveGraph:(id)sender :(float)move
{
	_fStartTime += move * _fDispTime;
	[self dispImpWindow];
}

- (void)zoomGraph:(id)sender :(float)zoom
{
	_fDispTime *= zoom;
	[self dispImpWindow];
}

@end
