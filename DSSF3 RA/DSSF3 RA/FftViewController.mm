//
//  FftViewController.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/12.
//  Copyright (c) 2015年 aizawa. All rights reserved.
//

#import "FftViewController.h"
#import "FftGraphPws.h"
#import "FftGraphOct.h"
#import "FftGraph3dd.h"
#import "FftGraphCrf.h"
#import "FftGraphPhs.h"
#import "FftGraphSpg.h"
#import "FftGraphCrs.h"
#import "FftGraphCoh.h"
#import "FftGraphCep.h"

#define LIMIT_FREQ	50000

@implementation FftViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	_colorLeft = [[UIColor alloc] COLOR_LEFT];
	_colorRight = [[UIColor alloc] COLOR_RIGHT];
	_colorLeftPeak = [[UIColor alloc] COLOR_LEFT_PEAK];
	_colorRightPeak = [[UIColor alloc] COLOR_RIGHT_PEAK];
	_colorLeftLine = [[UIColor alloc] COLOR_LEFT_LINE];
	_colorRightLine = [[UIColor alloc] COLOR_RIGHT_LINE];
	_colorGreen = [[UIColor alloc] COLOR_GREEN];
	_colorLightGreen = [[UIColor alloc] COLOR_LIGHTGREEN];
	_colorPhase = [[UIColor alloc] COLOR_PHASE];
	_colorCross = [[UIColor alloc] COLOR_CROSS];
	_colorCrossPeak = [[UIColor alloc] COLOR_CROSS_PEAK];
	_colorCoherence = [[UIColor alloc] COLOR_COHERENCE];
	_colorWhite = [UIColor whiteColor];
	_colorBlack = [UIColor blackColor];
	_colorGray = [[UIColor alloc] COLOR_GRAY];
	_colorLightGray = [[UIColor alloc] COLOR_LIGHTGRAY];
	_colorText = [[UIColor alloc] COLOR_TEXT];
	_colorOctBar = [[UIColor alloc] COLOR_OCTBAR];
	_colorScaleBg = [[UIColor alloc] COLOR_SCALE_BG];

	_imageOctLeft = [UIImage imageNamed:@"OctLeft.png"];
	_imageOctRight = [UIImage imageNamed:@"OctRight.png"];
	_imageOctPeakLeft = [UIImage imageNamed:@"OctPeakLeft.png"];
	_imageOctPeakRight = [UIImage imageNamed:@"OctPeakRight.png"];

	_aFreqScale = [[NSMutableArray alloc] init];

    [self initViews];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(receiveInitViews:) name:@"InitViews" object:nil];
}

- (void)initViews
{
	_oMicCalDataL.fInputSens = 0;
	_oMicCalDataL.nFreqData = 0;
	_oMicCalDataR.fInputSens = 0;
	_oMicCalDataR.nFreqData = 0;

    [self setMode:g_oSetData.Fft.nMode];
    self.outletGraphView.translatesAutoresizingMaskIntoConstraints = YES;
    _rectGraphView = self.outletGraphView.frame;

	[self setMicCalData];

	[self initFFT];

	[self createGraphView];

	[self initControls];
}

- (void)receiveInitViews:(NSNotification *)center
{
    [self initViews];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];

	[self stop];
}

-(void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];

	if (IS_PHONE) {
		[self resizeGraphView];

		SetContentSize(self.outletScrollView);
	}
}

- (void)createGraphView
{
    if (IS_PHONE) {
        g_oSetData.Fft.bShowSettings = YES;
    }

    if (g_oSetData.Fft.bShowSettings) {
        [self.outletDispMode setTitle:NSLocalizedString(@"IDS_GRAPH", nil) forState:UIControlStateNormal];
        self.outletGraphView.frame = _rectGraphView;

        if (IS_PAD) {
            self.outletCompare.hidden = YES;
            self.outletErase.hidden = YES;
        }
    } else {
        [self.outletDispMode setTitle:NSLocalizedString(@"IDS_SETTINGS", nil) forState:UIControlStateNormal];
		int topMargin = self.outletOnOff.frame.origin.y + self.outletOnOff.bounds.size.height + 5;
        [self.outletGraphView removeFromSuperview];
        self.outletGraphView.frame = CGRectMake(0, topMargin, self.outletBaseView.bounds.size.width, self.outletBaseView.bounds.size.height - topMargin);
        [self.outletBaseView addSubview:self.outletGraphView];
        
        if (IS_PAD) {
            self.outletCompare.hidden = NO;
            self.outletErase.hidden = NO;
        }
    }
    
    _sizeGraphView = self.outletGraphView.bounds.size;
    
    _fontAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                   [UIFont systemFontOfSize:17.0 * self.outletGraphView.bounds.size.width / 768], NSFontAttributeName,
                   _colorText, NSForegroundColorAttributeName,
                   nil];

    [_viewFftScale removeFromSuperview];
    _viewFftScale = [[FftScaleView alloc] initWithFrame:self.outletGraphView.bounds];
    _viewFftScale.delegate = self;
    [self.outletGraphView addSubview:_viewFftScale];
    
    CGRect rectScale = CGRectMake(_nFrameLeft, _nFrameTop, _nFrameWidth, _nFrameHeight);
    
    [_viewCompare1 removeFromSuperview];
    [_viewFftData1 removeFromSuperview];
    _viewFftData1 = [[FftDataView alloc] initWithFrame:rectScale];
    _viewFftData1.delegate = self;
    [self.outletGraphView addSubview:_viewFftData1];
    _viewCompare1 = [[FftCompareView alloc] initWithDataView:_viewFftData1];
    _viewCompare1.delegate = self;

    [_viewCompare2 removeFromSuperview];
    [_viewFftData2 removeFromSuperview];
    _viewFftData2 = [[FftDataView alloc] initWithFrame:rectScale];
    _viewFftData2.delegate = self;
    [self.outletGraphView addSubview:_viewFftData2];
    _viewCompare2 = [[FftCompareView alloc] initWithDataView:_viewFftData2];
    _viewCompare2.delegate = self;

    [self setDispMode];

	[self initFftMode];

    [self enableControls];
}

- (void)resizeGraphView
{
	_rectGraphView = self.outletGraphView.frame;

	if (g_oSetData.Fft.bShowSettings) {
		self.outletGraphView.frame = _rectGraphView;
	} else {
		int topMargin = self.outletOnOff.frame.origin.y + self.outletOnOff.bounds.size.height + 5;
		self.outletGraphView.frame = CGRectMake(0, topMargin, self.outletBaseView.bounds.size.width, self.outletBaseView.bounds.size.height - topMargin);
	}

	_sizeGraphView = self.outletGraphView.bounds.size;

	[self initFftMode];

	if (_nViewMode == VM_SPLIT) {
		_viewFftData1.frame = CGRectMake(_nFrameLeft, _nFrameTop, _nScaleWidth, _nScaleHeight);
		_viewFftData2.frame = CGRectMake(_nFrameLeft, _nFrameBottom - _nScaleHeight, _nScaleWidth, _nScaleHeight);
	} else {
		_viewFftData1.frame = CGRectMake(_nFrameLeft, _nFrameTop, _nScaleWidth, _nScaleHeight);
	}
}

- (void)dealloc
{
    [self freeBuffer];
    [self freeBuffer2];
}

- (void)initControls
{
    int i;
    NSString *str;
    
    SetSampleRateList(self.outletSampleRate, g_oSetData.Fft.nSampleRate);

    self.outletAutoFreq.checked = g_oSetData.Fft.bAutoFreq;
    self.outletMaxFreq.intValue = g_oSetData.Fft.nMaxFreq;
    self.outletMinFreq.intValue = g_oSetData.Fft.nMinFreq;
    
    self.outletAutoLevel.checked = g_oSetData.Fft.bAutoLevel;
    self.outletMaxLevel.intValue = g_oSetData.Fft.nMaxLevel;
    self.outletMinLevel.intValue = g_oSetData.Fft.nMinLevel;
    
    self.outletFreqScale.selectedSegmentIndex = g_oSetData.Fft.nFftScale;
    
    self.outletLRSplit.on = g_oSetData.Fft.bRlSplit;
    
    static const int tTimeConstant[] = {35, 125, 250, 500, 1000, 2000, 4000, 8000, 16000};
    str = NSLocalizedString(@"IDS_NONE", nil);
    [self.outletSmoothing addItem:str :0];
    for (i = 0; i < sizeof(tTimeConstant) / sizeof(int); i++) {
        int nTimeConstant = tTimeConstant[i];
        if (nTimeConstant < 1000)
            str = [NSString stringWithFormat:@"%dms", nTimeConstant];
        else
            str = [NSString stringWithFormat:@"%ds", nTimeConstant / 1000];
        if (nTimeConstant == 125)
            str = [str stringByAppendingString:@" (fast)"];
        else if (nTimeConstant == 1000)
            str = [str stringByAppendingString:@" (slow)"];
        [self.outletSmoothing addItem:str :nTimeConstant];
    }
    self.outletSmoothing.selectedItemData = g_oSetData.Fft.nSmoothing;
    
    SetWindowFuncList(self.outletWindowFunction);
    self.outletWindowFunction.selectedIndex = g_oSetData.Fft.nWindowFunc;
    
    SetFilterNameList(self.outletFilter);
    self.outletFilter.selectedIndex = g_oSetData.Fft.nFilter;
    
    for (i = 1024; i <= 65536; i *= 2) {
        str = [NSString stringWithFormat:@"%d", i];
        [self.outletFftSize addItem:str :i];
    }
    self.outletFftSize.selectedItemData = g_oSetData.Fft.nFftSize;
    
    self.outletPeakDisp.checked = g_oSetData.Fft.bPeakDisp;
    self.outletPeakHold.checked = g_oSetData.Fft.bPeakHold;
    self.outletPeakHoldMode.selectedSegmentIndex = g_oSetData.Fft.nPeakHoldMode;
    self.outletPeakHoldTime.intValue = g_oSetData.Fft.nPeakHoldTime;
    
    for (i = 5; i <= MAX_3DD; i++) {
        str = [NSString stringWithFormat:@"%d", i];
        [self.outletTimeDataNum addItem:str :i];
    }
    self.outletTimeDataNum.selectedItemData = g_oSetData.Fft.nTimeDataNum;
    
    static const int TimeResTbl[] = {1, 2, 4, 8};
    for (i = 0; i < sizeof(TimeResTbl) / sizeof(int); i++) {
        str = [NSString stringWithFormat:@"%dx", TimeResTbl[i]];
        [self.outletTimeResolution addItem:str :TimeResTbl[i]];
    }
    self.outletTimeResolution.selectedItemData = g_oSetData.Fft.nTimeRes;
    
    for (i = 0; i <= 10; i++) {
        if (i == 0)
            str = NSLocalizedString(@"IDS_NONE", nil);
        else
            str = [NSString stringWithFormat:@"%ds", i];
        [self.outletAverage addItem:str :i];
    }
    str = NSLocalizedString(@"IDS_INFINITE", nil);
    [self.outletAverage addItem:str :-1];
    self.outletAverage.selectedItemData = g_oSetData.Fft.nAverage;
    
    self.outletTimeDir.selectedSegmentIndex = g_oSetData.Fft.nTimeDir;
    self.outletCorrelation.selectedSegmentIndex = g_oSetData.Fft.nCorrelation;
    
    //DispResolution();
    
    for (i = 0; i < OCT_BAND_NUM; i++) {
        str = [NSString stringWithFormat:@"1/%d", g_nOctBandTbl[i]];
        [self.outletOctaveBand addItem:str :0];
    }
    self.outletOctaveBand.selectedIndex = g_oSetData.Fft.nOctaveBand;
    
    for (i = 1; i <= 20; i++) {
        str = [NSString stringWithFormat:@"%d s", i];
        [self.outletTimeRange addItem:str :i];
    }
    self.outletTimeRange.selectedItemData = g_oSetData.Fft.nTimeRange;
    
    SetChannelList(self.outletChannel, g_oSetData.Fft.nChannel);
    
    self.outletColorScale.selectedSegmentIndex = g_oSetData.Fft.nColorScale;
    
    self.outletCrfZoom.value = g_oSetData.Fft.nCrfZoom;
    
    self.outletAutoStop.intValue = g_oSetData.Fft.nAutoStopTime;
}

- (void)setMode:(int)mode
{
	if (self.outletMode.numberOfSegments == 9) {
		self.outletMode.selectedSegmentIndex = mode;
	} else {
		if (mode < 5) {
			self.outletMode.selectedSegmentIndex = mode;
			self.outletMode2.selectedSegmentIndex = -1;
		} else {
			self.outletMode.selectedSegmentIndex = -1;
			self.outletMode2.selectedSegmentIndex = mode - 5;
		}
	}
}

- (IBAction)tapCompare:(UIButton *)sender
{
    _viewCompare1.hidden = NO;
    _viewCompare1.leftChannel = _viewFftData1.leftChannel;
    _viewCompare1.rightChannel = _viewFftData1.rightChannel;
    [_viewCompare1 setNeedsDisplay];

    _viewCompare2.hidden = NO;
    _viewCompare2.leftChannel = _viewFftData2.leftChannel;
    _viewCompare2.rightChannel = _viewFftData2.rightChannel;
    [_viewCompare2 setNeedsDisplay];
}

- (IBAction)tapErase:(UIButton *)sender
{
    [self eraseCompareView];
}

- (void)eraseCompareView
{
    _viewCompare1.hidden = YES;
    _viewCompare2.hidden = YES;
/*
    _viewCompare1.leftChannel = NO;
    _viewCompare1.rightChannel = NO;
    [_viewCompare1 setNeedsDisplay];

    _viewCompare2.leftChannel = NO;
    _viewCompare2.rightChannel = NO;
    [_viewCompare2 setNeedsDisplay];
*/
}

- (IBAction)changeMode:(UISegmentedControl *)sender
{
    g_oSetData.Fft.nMode = (int)sender.selectedSegmentIndex;
	if (self.outletMode2 != nil) {
		self.outletMode2.selectedSegmentIndex = -1;
	}
    
    //if (n != FFT_MODE_OCT && _cDataRecord == YES) {
        //_cDataRecord = NO;
        //CloseDataRecord();
    //}
     
	[self changeModeSub];
}

- (IBAction)changeMode2:(UISegmentedControl *)sender
{
	g_oSetData.Fft.nMode = (int)sender.selectedSegmentIndex + 5;
	if (self.outletMode != nil) {
		self.outletMode.selectedSegmentIndex = -1;
	}

	[self changeModeSub];
}

- (void)changeModeSub
{
	_bPeakReset = YES;

	[self freeBuffer2];

	[self setDispMode];

	[self initFftMode];

	[self enableControls];

	[self redraw];
}

- (IBAction)changeOnOff:(UISegmentedControl *)sender
{
    if (sender.selectedSegmentIndex == 1) {
        [self start];
    } else {
        [self stop];
    }
}

- (IBAction)changeDispMode:(UIButton *)sender
{
    g_oSetData.Fft.bShowSettings = !g_oSetData.Fft.bShowSettings;

	[self freeBuffer2];
    [self createGraphView];
	[self initFftMode];
}

- (IBAction)changeLRSplit:(UISwitch *)sender
{
    if (g_oSetData.Fft.bRlSplit != self.outletLRSplit.isOn) {
        g_oSetData.Fft.bRlSplit = self.outletLRSplit.isOn;
        [self changeDispMode];
    }
}

- (IBAction)changeAutoLevel:(CtCheckBox *)sender
{
    if (g_oSetData.Fft.bAutoLevel != sender.checked) {
        g_oSetData.Fft.bAutoLevel = sender.checked;
        [self changeDispMode];
        [self enableControls];
    }
}

- (IBAction)changeMaxLevel:(CtTextField *)sender
{
    if (sender.intValue != g_oSetData.Fft.nMaxLevel) {
        g_oSetData.Fft.nMaxLevel = sender.intValue;
        [self changeDispMode];
    }
}

- (IBAction)changeMinLevel:(CtTextField *)sender
{
    if (sender.intValue != g_oSetData.Fft.nMinLevel) {
        g_oSetData.Fft.nMinLevel = sender.intValue;
        [self changeDispMode];
    }
}

- (IBAction)changeAutoFreq:(CtCheckBox *)sender
{
    if (g_oSetData.Fft.bAutoFreq != sender.checked) {
        g_oSetData.Fft.bAutoFreq = sender.checked;
        [self changeDispMode];
        [self enableControls];
    }
}

- (IBAction)changeMaxFreq:(CtTextField *)sender
{
    if (sender.intValue != g_oSetData.Fft.nMaxFreq) {
        if (sender.intValue < 0)
            sender.intValue = 0;
        else if (sender.intValue > LIMIT_FREQ)
            sender.intValue = LIMIT_FREQ;
        
        g_oSetData.Fft.nMaxFreq = sender.intValue;
        [self changeDispMode];
    }
}

- (IBAction)changeMinFreq:(CtTextField *)sender
{
    if (sender.intValue != g_oSetData.Fft.nMinFreq) {
        if (sender.intValue < 0)
            sender.intValue = 0;
        else if (sender.intValue > LIMIT_FREQ)
            sender.intValue = LIMIT_FREQ;
        
        g_oSetData.Fft.nMinFreq = sender.intValue;
        [self changeDispMode];
    }
}

- (IBAction)changeOctBand:(CtComboBox *)sender
{
    int nOctaveBand = sender.selectedIndex;
    
    if (g_oSetData.Fft.nOctaveBand != nOctaveBand) {
        g_oSetData.Fft.nOctaveBand = nOctaveBand;
        [self changeDispMode];
        [self changeDataRecord];
    }
}

- (IBAction)changeTimeDir:(UISegmentedControl *)sender
{
    if (g_oSetData.Fft.nTimeDir != sender.selectedSegmentIndex) {
        g_oSetData.Fft.nTimeDir = (int)sender.selectedSegmentIndex;
        
        if (g_oSetData.Fft.nMode == FFT_MODE_SPG)
            [self changeDispMode];
        else
            [self redraw];
    }
}

- (IBAction)changeSampleRate:(CtComboBox *)sender
{
    BOOL bStart = _bStart;
    if (bStart)
        [self stop];
    
    g_oSetData.Fft.nSampleRate = sender.selectedItemData;
    
    [self setFFT];
    
    //        ChangeDataRecord();
    
    if (bStart)
        [self start];
}

- (IBAction)changeFftSize:(CtComboBox *)sender
{
    BOOL bStart = _bStart;
    if (bStart)
        [self stop];
    
    g_oSetData.Fft.nFftSize = sender.selectedItemData;
    
    [self setFFT];
    
    [self changeDataRecord];
    
    if (bStart)
        [self start];
}

- (IBAction)changeWindowfunction:(CtComboBox *)sender
{
    if (g_oSetData.Fft.nWindowFunc != sender.selectedIndex) {
        g_oSetData.Fft.nWindowFunc = sender.selectedIndex;
        [self setFFT];
    }
}

- (IBAction)changeChannel:(CtComboBox *)sender
{
    int nChannel = sender.selectedIndex;
    
    if (g_oSetData.Fft.nChannel != nChannel) {
        g_oSetData.Fft.nChannel = nChannel;
        
        [self enableControls];
        
        [self changeDispMode];
        
        [self changeDataRecord];
    }
}

- (IBAction)changeColorScale:(UISegmentedControl *)sender
{
    if (g_oSetData.Fft.nColorScale != sender.selectedSegmentIndex) {
        g_oSetData.Fft.nColorScale = (int)sender.selectedSegmentIndex;
        
        [self changeDispMode];
    }
}

- (IBAction)changeCrfZoom:(CtSlider *)sender
{
    if (g_oSetData.Fft.nCrfZoom != sender.value) {
        g_oSetData.Fft.nCrfZoom = sender.value;
        [self changeDispMode];
    }
}

- (IBAction)changeFilter:(CtComboBox *)sender
{
    if (g_oSetData.Fft.nFilter != sender.selectedIndex) {
        g_oSetData.Fft.nFilter = sender.selectedIndex;
        [self setFFT];
    }
}

- (IBAction)changeSmoothing:(CtComboBox *)sender
{
    g_oSetData.Fft.nSmoothing = sender.selectedItemData;
}

- (IBAction)changeAverage:(CtComboBox *)sender
{
    BOOL bStart = _bStart;
    if (bStart)
        [self stop];
    
    g_oSetData.Fft.nAverage = sender.selectedItemData;
    
    [self setFFT];
    
    if (bStart)
        [self start];
}

- (IBAction)changeFreqScale:(UISegmentedControl *)sender
{
    if (g_oSetData.Fft.nFftScale != sender.selectedSegmentIndex) {
        g_oSetData.Fft.nFftScale = (int)sender.selectedSegmentIndex;
        [self changeDispMode];
    }
}

- (IBAction)changeCorrelation:(UISegmentedControl *)sender
{
    if (g_oSetData.Fft.nCorrelation != (int)sender.selectedSegmentIndex) {
        g_oSetData.Fft.nCorrelation = (int)sender.selectedSegmentIndex;
        [self enableControls];
        [self changeDispMode];
    }
}

- (IBAction)changeAutoStop:(CtTextField *)sender
{
    g_oSetData.Fft.nAutoStopTime = sender.intValue;
}

- (IBAction)changeTimeResolution:(CtComboBox *)sender
{
    BOOL bStart = _bStart;
    if (bStart)
        [self stop];
    
    g_oSetData.Fft.nTimeRes = sender.selectedItemData;
    
    [self setFFT];
    
    if (bStart)
        [self start];
}

- (IBAction)changeTimeRange:(CtComboBox *)sender
{
    g_oSetData.Fft.nTimeRange = sender.selectedItemData;
    
    [self changeDispMode];
}

- (IBAction)changeTimeDataNum:(CtComboBox *)sender
{
    g_oSetData.Fft.nTimeDataNum = sender.selectedItemData;
    [self changeDispMode];
}

- (IBAction)changePeakDisp:(CtCheckBox *)sender
{
    if (g_oSetData.Fft.bPeakDisp != sender.checked) {
        g_oSetData.Fft.bPeakDisp = sender.checked;
        
        if (!g_oSetData.Fft.bPeakDisp)
            [self resetDispFreqAll];
        
        [self redraw];
    }
}

- (IBAction)changePeakHold:(CtCheckBox *)sender
{
    if (g_oSetData.Fft.bPeakHold != sender.checked) {
        g_oSetData.Fft.bPeakHold = sender.checked;
        _bPeakReset = YES;
        [self enableControls];
        if (!_bStart)
            [self redraw];
        
        [self changeDataRecord];
    }
}

- (IBAction)changePeakHoldMode:(UISegmentedControl *)sender
{
    if (g_oSetData.Fft.nPeakHoldMode != (int)sender.selectedSegmentIndex) {
        g_oSetData.Fft.nPeakHoldMode = (int)sender.selectedSegmentIndex;
        [self enableControls];
    }
}

- (IBAction)changePeakHoldTime:(CtTextField *)sender
{
    if (g_oSetData.Fft.nPeakHoldTime != sender.intValue) {
        g_oSetData.Fft.nPeakHoldTime = sender.intValue;
    }
}

- (IBAction)tapPeakReset:(CtButton *)sender
{
    _bPeakReset = YES;
}

- (void)start
{
	int nPlaybackSampleRate = [AudioEx getPlaybackSampleRate];
	if (nPlaybackSampleRate != 0 && nPlaybackSampleRate != g_oSetData.Fft.nSampleRate) {
		[self.outletSampleRate setSelectedItemData:nPlaybackSampleRate];
		[self changeSampleRate:self.outletSampleRate];
	}

    [AudioInputEx start:g_oSetData.Fft.nSampleRate :NUM_CHANNELS_2 :g_oSetData.Fft.nFftSize / g_oSetData.Fft.nTimeRes :self];
}

- (void)stop
{
    [AudioInputEx stop];
}

- (void)enableControls
{
    BOOL bAutoFreq = NO;
    BOOL bAutoLevel = NO;
    BOOL bFreqScale = NO;
    BOOL bSmoothing = NO;
    BOOL bPeakDisp = NO;
    BOOL bPeakHold = NO;
    BOOL bAverage = NO;
    BOOL bChannel = NO;
    BOOL bFilter = NO;
    BOOL bMaxFreq = NO;
    BOOL bMinFreq = NO;
    BOOL bMaxLevel = NO;
    BOOL bMinLevel = NO;
    BOOL bPeakHoldMode = NO;
    BOOL bPeakHoldTime = NO;
    BOOL bPeakReset = NO;
    BOOL bOctBand = NO;
    BOOL bDataRecord = NO;
    BOOL bTimeDir = NO;
    BOOL bTimeDataNum = NO;
    BOOL bCorrelation = NO;
    BOOL bCfZoom = NO;
    BOOL bTimeRange = NO;
    BOOL bColorScale = NO;
    BOOL bRlSplit = NO;
    BOOL bCompare = NO;
    BOOL bErase = NO;
    
    switch (_nMode) {
        case FFT_MODE_PWS:
            bAutoFreq = YES;
            bAutoLevel = YES;
            bFreqScale = YES;
            bSmoothing = YES;
            bPeakDisp = YES;
            bPeakHold = YES;
            bAverage = YES;
            bChannel = YES;
            bFilter = YES;
            if (!g_oSetData.Fft.bAutoFreq) {
                bMaxFreq = YES;
                bMinFreq = YES;
            }
            if (!g_oSetData.Fft.bAutoLevel) {
                bMaxLevel = YES;
                bMinLevel = YES;
            }
            if (g_oSetData.Fft.bPeakHold) {
                bPeakHoldMode = YES;
                if (g_oSetData.Fft.nPeakHoldMode == 0)
                    bPeakHoldTime = YES;
                if (g_oSetData.Fft.nPeakHoldMode == 1)
                    bPeakReset = YES;
            }
            bCompare = YES;
            bErase = YES;
            break;
        case FFT_MODE_OCT:
            bAutoLevel = YES;
            bSmoothing = YES;
            bPeakDisp = YES;
            bPeakHold = YES;
            bAverage = YES;
            bOctBand = YES;
            bDataRecord = YES;
            bChannel = YES;
            bFilter = YES;
            if (!g_oSetData.Fft.bAutoLevel) {
                bMaxLevel = YES;
                bMinLevel = YES;
            }
            if (g_oSetData.Fft.bPeakHold) {
                bPeakHoldMode = YES;
                if (g_oSetData.Fft.nPeakHoldMode == 0)
                    bPeakHoldTime = YES;
                if (g_oSetData.Fft.nPeakHoldMode == 1)
                    bPeakReset = YES;
            }
            bCompare = YES;
            bErase = YES;
            break;
        case FFT_MODE_3DD:
            bAutoFreq = YES;
            bAutoLevel = YES;
            bFreqScale = YES;
            bSmoothing = YES;
            bTimeDir = YES;
            bTimeDataNum = YES;
            bAverage = YES;
            bChannel = YES;
            bFilter = YES;
            if (!g_oSetData.Fft.bAutoFreq) {
                bMaxFreq = YES;
                bMinFreq = YES;
            }
            if (!g_oSetData.Fft.bAutoLevel) {
                bMaxLevel = YES;
                bMinLevel = YES;
            }
            bCompare = YES;
            bErase = YES;
            break;
        case FFT_MODE_CRF:
            bCorrelation = YES;
            bCfZoom = YES;
            if (g_oSetData.Fft.nCorrelation == 0)
                bChannel = YES;
            bCompare = YES;
            bErase = YES;
            break;
        case FFT_MODE_PHS:
            bAutoFreq = YES;
            bFreqScale = YES;
            bSmoothing = YES;
            if (!g_oSetData.Fft.bAutoFreq) {
                bMaxFreq = YES;
                bMinFreq = YES;
            }
            bCompare = YES;
            bErase = YES;
            break;
        case FFT_MODE_SPG:
            bAutoFreq = YES;
            bAutoLevel = YES;
            bFreqScale = YES;
            bTimeDir = YES;
            bTimeRange = YES;
            bChannel = YES;
            bFilter = YES;
            if (!g_oSetData.Fft.bAutoFreq) {
                bMaxFreq = YES;
                bMinFreq = YES;
            }
            if (!g_oSetData.Fft.bAutoLevel) {
                bMaxLevel = YES;
                bMinLevel = YES;
            }
            bColorScale = YES;
            break;
        case FFT_MODE_CRS:
            bAutoFreq = YES;
            bAutoLevel = YES;
            bFreqScale = YES;
            bSmoothing = YES;
            bPeakDisp = YES;
            bPeakHold = YES;
            bAverage = YES;
            bChannel = YES;
            bFilter = YES;
            if (!g_oSetData.Fft.bAutoFreq) {
                bMaxFreq = YES;
                bMinFreq = YES;
            }
            if (!g_oSetData.Fft.bAutoLevel) {
                bMaxLevel = YES;
                bMinLevel = YES;
            }
            if (g_oSetData.Fft.bPeakHold) {
                bPeakHoldMode = YES;
                if (g_oSetData.Fft.nPeakHoldMode == 0)
                    bPeakHoldTime = YES;
                if (g_oSetData.Fft.nPeakHoldMode == 1)
                    bPeakReset = YES;
            }
            bCompare = YES;
            bErase = YES;
            break;
        case FFT_MODE_COH:
            bAutoFreq = YES;
            bFreqScale = YES;
            bFilter = YES;
            bSmoothing = YES;
            bAverage = YES;
            if (!g_oSetData.Fft.bAutoFreq) {
                bMaxFreq = YES;
                bMinFreq = YES;
            }
            bCompare = YES;
            bErase = YES;
            break;
        case FFT_MODE_CEP:
            bAutoLevel = YES;
            bSmoothing = YES;
            bPeakDisp = YES;
            bPeakHold = YES;
            bAverage = YES;
            bChannel = YES;
            bFilter = YES;
            if (!g_oSetData.Fft.bAutoLevel) {
                bMaxLevel = YES;
                bMinLevel = YES;
            }
            if (g_oSetData.Fft.bPeakHold) {
                bPeakHoldMode = YES;
                if (g_oSetData.Fft.nPeakHoldMode == 0)
                    bPeakHoldTime = YES;
                if (g_oSetData.Fft.nPeakHoldMode == 1)
                    bPeakReset = YES;
            }
            bCfZoom = YES;
            bCompare = YES;
            bErase = YES;
            break;
    }
    
    if (g_oSetData.Fft.nChannel == CH_STEREO && (_nMode != FFT_MODE_CRF || g_oSetData.Fft.nCorrelation != 1) && _nMode != FFT_MODE_PHS && _nMode != FFT_MODE_CRS && _nMode != FFT_MODE_COH) {
        bRlSplit = YES;
    }

    self.outletAutoFreq.enabled = bAutoFreq;
    self.outletAutoLevel.enabled = bAutoLevel;
    self.outletFreqScale.enabled = bFreqScale;
    self.outletSmoothing.enabled = bSmoothing;
    self.outletPeakDisp.enabled = bPeakDisp;
    self.outletPeakHold.enabled = bPeakHold;
    self.outletAverage.enabled = bAverage;
    self.outletChannel.enabled = bChannel;
    self.outletFilter.enabled = bFilter;
    self.outletMaxFreq.enabled = bMaxFreq;
    self.outletMinFreq.enabled = bMinFreq;
    self.outletMaxLevel.enabled = bMaxLevel;
    self.outletMinLevel.enabled = bMinLevel;
    self.outletPeakHoldMode.enabled = bPeakHoldMode;
    self.outletPeakHoldTime.enabled = bPeakHoldTime;
    self.outletPeakReset.enabled = bPeakReset;
    self.outletOctaveBand.enabled = bOctBand;
//    self.outletDataRecoed.enabled = bDataRecord;
    self.outletTimeDir.enabled = bTimeDir;
    self.outletTimeDataNum.enabled = bTimeDataNum;
    self.outletCorrelation.enabled = bCorrelation;
    self.outletCrfZoom.enabled = bCfZoom;
//    GetDlgItem(IDC_FFT_ZOOM_SCALE)->EnableWindow(bCfZoom);
    self.outletTimeRange.enabled = bTimeRange;
    self.outletColorScale.enabled = bColorScale;
    self.outletLRSplit.enabled = bRlSplit;
    self.outletCompare.enabled = bCompare;
    self.outletErase.enabled = bErase;
    
//    GetDlgItem(IDC_SCREEN_SHOT)->EnableWindow(!g_oSetData.Fft.bSeparateWindow[g_oSetData.Fft.nMode]);
    
    NSString *sNameX, *sNameY, *sUnitX, *sUnitY, *sAxisX, *sAxisY;
    GetAxisName(g_oSetData.Fft.nMode, &sNameX, &sNameY);
    GetAxisUnit(g_oSetData.Fft.nMode, &sUnitX, &sUnitY);
    if (sUnitX.length != 0)
        sAxisX = [NSString stringWithFormat:@"%@ [%@]", sNameX, sUnitX];
    else
        sAxisX = sNameX;
    self.outletPeakFreq.title = sAxisX;
    if (sUnitY.length != 0)
        sAxisY = [NSString stringWithFormat:@"%@ [%@]", sNameY, sUnitY];
    else
        sAxisY = sNameY;
    self.outletPeakLevel.title = sAxisY;
    
//    EnableCsvOutput();
}

- (void)changeDataRecord
{
    ////////////// 未実装
}

- (void)redraw
{
    [_viewFftScale setNeedsDisplay];
    [self eraseCompareView];
}

- (void)resetDispFreqAll
{
    switch (_nMode) {
        case FFT_MODE_PWS:
            [self resetDispFreqPws];
            break;
        case FFT_MODE_OCT:
            [self resetDispFreqOct];
            break;
        case FFT_MODE_CRF:
            [self resetDispFreqCrf];
            break;
        case FFT_MODE_PHS:
            [self resetDispFreqPhs];
            break;
        case FFT_MODE_CRS:
            [self resetDispFreqCrs];
            break;
        case FFT_MODE_COH:
            [self resetDispFreqCoh];
            break;
        case FFT_MODE_CEP:
            [self resetDispFreqCep];
            break;
    }
}

- (void)setFFT
{
    [self initFFT];
    
    //DispResolution();
    
    //_bEnableCsvOutput = NO;
    //EnableCsvOutput();
    
    [self changeDispMode];
}

- (void)changeDispMode
{
    [self clearPeak];
    
    [self initFftMode];
    
    [self redraw];
    
    //_bEnableCsvOutput = NO;
    //EnableCsvOutput();
}

- (void)clearPeak
{
    [self.outletPeakLevelLeft blank];
    [self.outletPeakLevelRight blank];
    [self.outletPeakFreqLeft blank];
    [self.outletPeakFreqRight blank];
}
/*
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (event.allTouches.count == 2) {
        //2本指でタッチしている場合は、２点間の距離を計算
        NSArray *twoFingers = [event.allTouches allObjects];
        UITouch *touch1 = [twoFingers objectAtIndex:0];
        UITouch *touch2 = [twoFingers objectAtIndex:1];
        CGPoint previous1 = [touch1 previousLocationInView:self.view];
        CGPoint previous2 = [touch2 previousLocationInView:self.view];
        CGPoint now1 = [touch1 locationInView:self.view];
        CGPoint now2 = [touch2 locationInView:self.view];
        
        //現状の距離と、前回の距離を比較して距離が縮まったか離れたかを判別
        CGFloat previousDistance = [self distanceWithPointA:previous1 pointB:previous2];
        CGFloat distance = [self distanceWithPointA:now1 pointB:now2];
        
        if (previousDistance > distance) {
            if (!g_oSetData.Fft.bShowSettings) {
                g_oSetData.Fft.bShowSettings = YES;
                [self createGraphView];
            }
        } else if (distance > previousDistance) {
            if (g_oSetData.Fft.bShowSettings) {
                g_oSetData.Fft.bShowSettings = NO;
                [self createGraphView];
            }
        }
    }
}

- (CGFloat)distanceWithPointA:(CGPoint)pointA pointB:(CGPoint)pointB
{
    CGFloat dx = fabs( pointB.x - pointA.x );
    CGFloat dy = fabs( pointB.y - pointA.y );
    return sqrt(dx * dx + dy * dy);
}
*/
- (void)initFftMode
{
    [self setViewMode];
    [self setMinMax];

    switch (_nMode) {
        case FFT_MODE_PWS:
            [self initPws];
            break;
        case FFT_MODE_OCT:
            [self initOct];
            break;
        case FFT_MODE_3DD:
            [self init3dd];
            break;
        case FFT_MODE_CRF:
            [self initCrf];
            break;
        case FFT_MODE_PHS:
            [self initPhs];
            break;
        case FFT_MODE_SPG:
            [self initSpg];
            break;
        case FFT_MODE_CRS:
            [self initCrs];
            break;
        case FFT_MODE_COH:
            [self initCoh];
            break;
        case FFT_MODE_CEP:
            [self initCep];
            break;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawScaleView:(CGContextRef)context
{
    CGRect rect = _viewFftScale.bounds;
    
    switch (_nMode) {
        case FFT_MODE_PWS:
            [self drawScalePws:rect];
            break;
        case FFT_MODE_OCT:
            [self drawScaleOct:rect];
            break;
        case FFT_MODE_3DD:
            [self drawScale3dd:rect];
            break;
        case FFT_MODE_CRF:
            [self drawScaleCrf:rect];
            break;
        case FFT_MODE_PHS:
            [self drawScalePhs:rect];
            break;
        case FFT_MODE_SPG:
            [self drawScaleSpg:rect];
            break;
        case FFT_MODE_CRS:
            [self drawScaleCrs:rect];
            break;
        case FFT_MODE_COH:
            [self drawScaleCoh:rect];
            break;
        case FFT_MODE_CEP:
            [self drawScaleCep:rect];
            break;
    }
    
    _viewFftData1.leftChannel = NO;
    _viewFftData1.rightChannel = NO;
    _viewFftData2.leftChannel = NO;
    _viewFftData2.rightChannel = NO;
    
    if (_nViewMode == VM_SPLIT) {
        _viewFftData2.hidden = NO;
        
        _viewFftData1.frame = CGRectMake(_nFrameLeft, _nFrameTop, _nScaleWidth, _nScaleHeight);
        _viewFftData2.frame = CGRectMake(_nFrameLeft, _nFrameBottom - _nScaleHeight, _nScaleWidth, _nScaleHeight);

        if (_bLch)
            _viewFftData1.leftChannel = YES;
        
        if (_bRch)
            _viewFftData2.rightChannel = YES;
        
        [_viewFftData1 setNeedsDisplay];
        [_viewFftData2 setNeedsDisplay];
    } else {
        _viewFftData2.hidden = YES;
        
        _viewFftData1.frame = CGRectMake(_nFrameLeft, _nFrameTop, _nScaleWidth, _nScaleHeight);
        
        if (_bLch)
            _viewFftData1.leftChannel = YES;
        
        if (_bRch)
            _viewFftData1.rightChannel = YES;

        [_viewFftData1 setNeedsDisplay];
    }
}

- (void)initFFT
{
    int i;
    
    [self freeBuffer];
    
    _nFftSize = g_oSetData.Fft.nFftSize;
    _nSamplingRate = g_oSetData.Fft.nSampleRate;
    _fFreqStep = (float)_nSamplingRate / _nFftSize;
    _fTimeStep = 1.0 / _fFreqStep;
    _fTimeStep2 = _fTimeStep / g_oSetData.Fft.nTimeRes;
    
    int nFftBufSize = _nFftSize / 2 + 1;
    
    _pLogFreqTbl = new float[nFftBufSize];
    _pLogFreqTbl[0] = 0;
    for (i = 1; i < nFftBufSize; i++)
        _pLogFreqTbl[i] = log(i * _fFreqStep);
    
    _pLeftWaveBuf = new float[_nFftSize];
    _pRightWaveBuf = new float[_nFftSize];
	_nWaveBufCount = 0;
	_bWaveBufFill = NO;

    _pFftBufL = new float[_nFftSize];
    _pFftBufR = new float[_nFftSize];
    _pFftBufM = new float[_nFftSize];
    
    _pPhaseBuf = new float[nFftBufSize];
    MEMCLEAR(_pPhaseBuf, nFftBufSize);
    
    _pCrossBufRe = new float[nFftBufSize];
    MEMCLEAR(_pCrossBufRe, nFftBufSize);
    
    _pCrossBufIm = new float[nFftBufSize];
    MEMCLEAR(_pCrossBufIm, nFftBufSize);
    
    _pCoherenceBuf = new float[nFftBufSize];
    MEMCLEAR(_pCoherenceBuf, nFftBufSize);
    
    int nAverageNum = (g_oSetData.Fft.nAverage >= 0) ? g_oSetData.Fft.nAverage * _nSamplingRate * g_oSetData.Fft.nTimeRes / _nFftSize : -1;
    
    _oCrossBufRe.Alloc(nFftBufSize, nAverageNum);
    _oCrossBufIm.Alloc(nFftBufSize, nAverageNum);
    
    for (i = 0; i < 2; i++) {
        FFTDATA *pFftData = &_aFftData[i];
        
        pFftData->_pPowerSpecBuf = new float[nFftBufSize];
        MEMCLEAR(pFftData->_pPowerSpecBuf, nFftBufSize);
        
        pFftData->_oPowerSpecBuf.Alloc(nFftBufSize, nAverageNum);
        
        pFftData->_pPwsPeakLevel = new float[nFftBufSize];
        
        pFftData->_pCrfBuf = new float[_nFftSize];
        MEMCLEAR(pFftData->_pCrfBuf, _nFftSize);
        
        pFftData->_pCepBuf = new float[_nFftSize];
        MEMCLEAR(pFftData->_pCepBuf, _nFftSize);
        
        pFftData->_pCepPeakLevel = new float[nFftBufSize];
    }
    
    _pCrsPeakLevel = new float[nFftBufSize];
    
    _pCrsBuf = new float[nFftBufSize];
    MEMCLEAR(_pCrsBuf, nFftBufSize);
    
    _pWindowFunc = new float[_nFftSize];
    MakeWindowFunc(g_oSetData.Fft.nWindowFunc, _nFftSize, _pWindowFunc, 2);
    
    _pFilterTblL = new float[_nFftSize];
    _pFilterTblR = new float[_nFftSize];
    MakeFilterTbl3(_pFilterTblL, _nFftSize, _nSamplingRate, (FilterData *)_oMicCalDataL.aFreq, _oMicCalDataL.nFreqData, 20);
    MakeFilterTbl3(_pFilterTblR, _nFftSize, _nSamplingRate, (FilterData *)_oMicCalDataR.aFreq, _oMicCalDataR.nFreqData, 20);
    float sensL = pow(10.0, -_oMicCalDataL.fInputSens / 20);
    float sensR = pow(10.0, -_oMicCalDataR.fInputSens / 20);
    _pFilterTblL[0] = 0;
    _pFilterTblR[0] = 0;
    for (i = 1; i < _nFftSize; i++) {
        _pFilterTblL[i] = sensL / _pFilterTblL[i];
        _pFilterTblR[i] = sensR / _pFilterTblR[i];
    }
    
    if (g_oSetData.Fft.nFilter != 0) {
        float *pFilter = new float[_nFftSize];
        MakeFilterTbl2(pFilter, _nFftSize, _nSamplingRate, g_oSetData.Fft.nFilter, 20);
        for (i = 0; i < _nFftSize; i++) {
            _pFilterTblL[i] *= pFilter[i];
            _pFilterTblR[i] *= pFilter[i];
        }
        delete [] pFilter;
    }
    
    _fLeftOffset = 0;
    _fRightOffset = 0;
}

- (void)initBuf
{
    for (int i = 0; i < 2; i++) {
        FFTDATA *pFftData = &_aFftData[i];
        
        pFftData->_oPowerSpecBuf.Reset();
    }
    
    _oCrossBufRe.Reset();
    _oCrossBufIm.Reset();
    
    _fSpgTimeStep = 0;
    _bPeakReset = YES;
    _bSmoothingReset = YES;
}

- (void)freeBuffer
{
    int i;
    
    if (_pLogFreqTbl != NULL) {
        delete [] _pLogFreqTbl;
        _pLogFreqTbl = NULL;
    }
    
    if (_pWindowFunc != NULL) {
        delete [] _pWindowFunc;
        _pWindowFunc = NULL;
    }
    
    if (_pLeftWaveBuf != NULL) {
        delete [] _pLeftWaveBuf;
        _pLeftWaveBuf = NULL;
    }
    
    if (_pRightWaveBuf != NULL) {
        delete [] _pRightWaveBuf;
        _pRightWaveBuf = NULL;
    }
    
    if (_pFftBufL != NULL) {
        delete [] _pFftBufL;
        _pFftBufL = NULL;
    }
    
    if (_pFftBufR != NULL) {
        delete [] _pFftBufR;
        _pFftBufR = NULL;
    }
    
    if (_pFftBufM != NULL) {
        delete [] _pFftBufM;
        _pFftBufM = NULL;
    }
    
    if (_pFilterTblL != NULL) {
        delete [] _pFilterTblL;
        _pFilterTblL = NULL;
    }
    
    if (_pFilterTblR != NULL) {
        delete [] _pFilterTblR;
        _pFilterTblR = NULL;
    }
    
    if (_pPhaseBuf != NULL) {
        delete [] _pPhaseBuf;
        _pPhaseBuf = NULL;
    }
    
    if (_pCrossBufRe != NULL) {
        delete [] _pCrossBufRe;
        _pCrossBufRe = NULL;
    }
    
    if (_pCrossBufIm != NULL) {
        delete [] _pCrossBufIm;
        _pCrossBufIm = NULL;
    }
    
    if (_pCrsBuf != NULL) {
        delete [] _pCrsBuf;
        _pCrsBuf = NULL;
    }
    
    if (_pCrsPeakLevel != NULL) {
        delete [] _pCrsPeakLevel;
        _pCrsPeakLevel = NULL;
    }
    
    if (_pCoherenceBuf != NULL) {
        delete [] _pCoherenceBuf;
        _pCoherenceBuf = NULL;
    }
    
    for (i = 0; i < 2; i++) {
        FFTDATA *pFftData = &_aFftData[i];
        
        if (pFftData->_pPowerSpecBuf != NULL) {
            delete [] pFftData->_pPowerSpecBuf;
            pFftData->_pPowerSpecBuf = NULL;
        }
        
        if (pFftData->_pPwsPeakLevel != NULL) {
            delete [] pFftData->_pPwsPeakLevel;
            pFftData->_pPwsPeakLevel = NULL;
        }
        
        if (pFftData->_pCrfBuf != NULL) {
            delete [] pFftData->_pCrfBuf;
            pFftData->_pCrfBuf = NULL;
        }
        
        if (pFftData->_pCepBuf != NULL) {
            delete [] pFftData->_pCepBuf;
            pFftData->_pCepBuf = NULL;
        }
        
        if (pFftData->_pCepPeakLevel != NULL) {
            delete [] pFftData->_pCepPeakLevel;
            pFftData->_pCepPeakLevel = NULL;
        }
    }
}

- (void)freeBuffer2
{
    int i, j;
    
    for (i = 0; i < 2; i++) {
        FFTDATA *pFftData = &_aFftData[i];
        
        if (_nMode == FFT_MODE_PWS) {
            if (pFftData->_pPwsPoint != NULL) {
                delete [] pFftData->_pPwsPoint;
                pFftData->_pPwsPoint = NULL;
            }
            
            if (pFftData->_pPwsPeakPoint != NULL) {
                delete [] pFftData->_pPwsPeakPoint;
                pFftData->_pPwsPeakPoint = NULL;
            }
        }
        
        if (_nMode == FFT_MODE_CRF) {
            if (pFftData->_pCrfPoint != NULL) {
                delete [] pFftData->_pCrfPoint;
                pFftData->_pCrfPoint = NULL;
            }
        }
        
        if (_nMode == FFT_MODE_3DD) {
            for (j = 0; j < MAX_3DD; j++) {
                if (pFftData->_p3ddPoint[j] != NULL)
                    delete [] pFftData->_p3ddPoint[j];
                pFftData->_p3ddPoint[j] = NULL;
            }
        }
        
        if (_nMode == FFT_MODE_CEP) {
            if (pFftData->_pCepPoint != NULL) {
                delete [] pFftData->_pCepPoint;
                pFftData->_pCepPoint = NULL;
            }
            
            if (pFftData->_pCepPeakPoint != NULL) {
                delete [] pFftData->_pCepPeakPoint;
                pFftData->_pCepPeakPoint = NULL;
            }
        }
    }
    
    if (_nMode == FFT_MODE_3DD) {
        if (_p3ddCheckTbl != NULL) {
            delete [] _p3ddCheckTbl;
            _p3ddCheckTbl = NULL;
        }
        
        if (_p3ddWork != NULL) {
            delete [] _p3ddWork;
            _p3ddWork = NULL;
        }
    }
    
    if (_nMode == FFT_MODE_PHS) {
        if (_pPhsPoint != NULL) {
            delete [] _pPhsPoint;
            _pPhsPoint = NULL;
        }
    }
    
    if (_nMode == FFT_MODE_SPG) {
        if (_pSpgLevel != NULL) {
            delete [] _pSpgLevel;
            _pSpgLevel = NULL;
        }
    }
    
    if (_nMode == FFT_MODE_CRS) {
        if (_pCrsPoint != NULL) {
            delete [] _pCrsPoint;
            _pCrsPoint = NULL;
        }
        
        if (_pCrsPeakPoint != NULL) {
            delete [] _pCrsPeakPoint;
            _pCrsPeakPoint = NULL;
        }
    }
    
    if (_nMode == FFT_MODE_COH) {
        if (_pCohPoint != NULL) {
            delete [] _pCohPoint;
            _pCohPoint = NULL;
        }
    }
}

- (void)audioInputStart:(AudioInfo *)audioInfo
{
	self.outletOnOff.selectedSegmentIndex = 1;
	_bStart = YES;

    _fBlockTime = (float)g_oSetData.Fft.nFftSize / g_oSetData.Fft.nSampleRate / g_oSetData.Fft.nTimeRes;
    _fTimeCount = 0;
    
	[self initBuf];

	_nWaveBufCount = 0;
	_bWaveBufFill = NO;
}

- (void)audioInputStop
{
	self.outletOnOff.selectedSegmentIndex = 0;
	_bStart = NO;
}

- (void)audioInputData:(AudioData *)audioData
{
    _fTimeCount += _fBlockTime;

    int nSize1 = g_oSetData.Fft.nFftSize / g_oSetData.Fft.nTimeRes;
    int nSize2 = g_oSetData.Fft.nFftSize - nSize1;
    memmove(_pLeftWaveBuf, _pLeftWaveBuf + nSize1, nSize2 * sizeof(float));
    memcpy(_pLeftWaveBuf + nSize2, audioData->pLeftData, nSize1 * sizeof(float));
    memmove(_pRightWaveBuf, _pRightWaveBuf + nSize1, nSize2 * sizeof(float));
    memcpy(_pRightWaveBuf + nSize2, audioData->pRightData, nSize1 * sizeof(float));

	if (!_bWaveBufFill) {
		if (_nWaveBufCount++ == g_oSetData.Fft.nTimeRes)
			_bWaveBufFill = YES;
	}

	if (_bWaveBufFill) {
		[self calcFftGraph:_pLeftWaveBuf :_pRightWaveBuf];

		[_viewFftData1 setNeedsDisplay];
		if (_viewFftData2.superview != nil)
			[_viewFftData2 setNeedsDisplay];
	}

    if (g_oSetData.Fft.nAutoStopTime != 0 && _fTimeCount >= g_oSetData.Fft.nAutoStopTime)
        [self stop];
}

- (void)setDispMode
{
    _nMode = g_oSetData.Fft.nMode;
    
    if (_nMode == FFT_MODE_SPG) {
        [self.outletGraphView bringSubviewToFront:_viewFftScale];
        _viewFftScale.backgroundColor = [UIColor clearColor];
        _viewFftData1.backgroundColor = nil;
        _viewFftData2.backgroundColor = nil;
    } else {
        [self.outletGraphView sendSubviewToBack:_viewFftScale];
        _viewFftScale.backgroundColor = _colorScaleBg;
        _viewFftData1.backgroundColor = [UIColor clearColor];
        _viewFftData2.backgroundColor = [UIColor clearColor];
    }
}

- (void)calcFftGraph:(float *)pLeftData :(float *)pRightData
{
    int i;
    float fLeftOffset, fRightOffset;
    float fLeftData, fRightData;
    BOOL bLeft = NO, bRight = NO, bMono = NO;
    BOOL bStereo = NO;
    float *pFftBufL = NULL, *pFftBufR = NULL;
    
    fLeftOffset = 0;
    fRightOffset = 0;
    for (i = 0; i < _nFftSize; i++) {
        fLeftOffset += pLeftData[i];
        fRightOffset += pRightData[i];
    }
    _fLeftOffset = (_fLeftOffset * 9 + fLeftOffset / _nFftSize) / 10;
    _fRightOffset = (_fRightOffset * 9 + fRightOffset / _nFftSize) / 10;

    switch (_nMode) {
        case FFT_MODE_CRF:
            if (g_oSetData.Fft.nCorrelation != 0)
                bStereo = YES;
            break;
        case FFT_MODE_CRS:
        case FFT_MODE_COH:
        case FFT_MODE_PHS:
            bStereo = YES;
            break;
    }
    
    if (g_oSetData.Fft.nChannel == CH_STEREO || bStereo) {
        for (i = 0; i < _nFftSize; i++) {
            _pFftBufL[i] = (pLeftData[i] - _fLeftOffset) * _pWindowFunc[i];
            _pFftBufR[i] = (pRightData[i] - _fRightOffset) * _pWindowFunc[i];
        }
        bLeft = YES;
        bRight = YES;
    }
    
    if (g_oSetData.Fft.nChannel == CH_LEFT_ONLY && !bLeft) {
        for (i = 0; i < _nFftSize; i++) {
            _pFftBufL[i] = (pLeftData[i] - _fLeftOffset) * _pWindowFunc[i];
        }
        bLeft = YES;
    }
    
    if (g_oSetData.Fft.nChannel == CH_RIGHT_ONLY && !bRight) {
        for (i = 0; i < _nFftSize; i++) {
            _pFftBufR[i] = (pRightData[i] - _fRightOffset) * _pWindowFunc[i];
        }
        bRight = YES;
    }
    
    if (g_oSetData.Fft.nChannel == CH_MONO) {
        for (i = 0; i < _nFftSize; i++) {
            fLeftData = pLeftData[i] - _fLeftOffset;
            fRightData = pRightData[i] - _fRightOffset;
            _pFftBufM[i] = (fLeftData + fRightData) / 2 * _pWindowFunc[i];
        }
        bMono = YES;
    }
    
    if (g_oSetData.Fft.nChannel == CH_DIFFERENCE) {
        for (i = 0; i < _nFftSize; i++) {
            fLeftData = pLeftData[i] - _fLeftOffset;
            fRightData = pRightData[i] - _fRightOffset;
            _pFftBufM[i] = (fLeftData - fRightData) * _pWindowFunc[i];
        }
        bMono = YES;
    }
    
    if (bMono) {
        _oFFT.fft(_nFftSize, _pFftBufM);
        pFftBufL = _pFftBufM;
    }
    
    if (bLeft) {
        _oFFT.fft(_nFftSize, _pFftBufL);
        pFftBufL = _pFftBufL;
    }
    
    if (bRight) {
        _oFFT.fft(_nFftSize, _pFftBufR);
        pFftBufR = _pFftBufR;
    }
    
    if (_bPeakReset) {
        _nPeakHoldTimer = 0;
        _bPeakReset = NO;
    }
    
    if (g_oSetData.Fft.nSmoothing == 0 || _bSmoothingReset) {
        _fSmoothing1 = 1;
        _fSmoothing2 = 0;
        _bSmoothingReset = NO;
    } else {
        _fSmoothing2 = pow(1 / M_E, (_fTimeStep2 * 1000) / (g_oSetData.Fft.nSmoothing));
        _fSmoothing1 = 1 - _fSmoothing2;
    }
    
    [self calcSpectrum:pFftBufL :pFftBufR];
    
    [self setDispData];
    
    if (++_nPeakHoldTimer >= (int)(_nSamplingRate / _nFftSize * g_oSetData.Fft.nPeakHoldTime * g_oSetData.Fft.nTimeRes)) {
        if (g_oSetData.Fft.nPeakHoldMode == 0)
            _nPeakHoldTimer = 0;
    }
}

- (void)calcSpectrum:(const float *)pFftBufL :(const float *)pFftBufR
{
    if (pFftBufL != NULL)
        [self calcPowerSpectrum:&_aFftData[0] :pFftBufL :_pFilterTblL];
    
    if (pFftBufR != NULL)
        [self calcPowerSpectrum:&_aFftData[1] :pFftBufR :_pFilterTblR];
    
    if (pFftBufL != NULL && pFftBufR != NULL)
        [self calcCrossSpectrum:pFftBufL :pFftBufR];
}

- (void)calcPowerSpectrum:(FFTDATA *)pFftData :(const float *)pBuf :(const float *)pFilterTbl
{
    int i, j;
    float xt, yt;
    float *pPowerSpecBuf1 = pFftData->_pPowerSpecBuf;
    int nFftSize2 = _nFftSize / 2;
    
    for (i = 1, j = 2; i < nFftSize2; i++) {
        xt = pBuf[j++] * pFilterTbl[i];
        yt = pBuf[j++] * pFilterTbl[i];
        
        pPowerSpecBuf1[i] = xt * xt + yt * yt;
    }
    
    pFftData->_oPowerSpecBuf.Smoothing(pPowerSpecBuf1, _fSmoothing1, _fSmoothing2);
    pFftData->_oPowerSpecBuf.Averaging();
    
    pFftData->_fFftAllPower = 0;
    float *pPowerSpecBuf2 = pFftData->_oPowerSpecBuf.GetBuf();
    for (i = 1; i < nFftSize2; i++)
        pFftData->_fFftAllPower += pPowerSpecBuf2[i];
}

- (void)calcCrossSpectrum:(const float *)pBufL :(const float *)pBufR
{
    int i, j;
    float xt1, yt1, xt2, yt2;
    int nFftSize2 = _nFftSize / 2;
    
    for (i = 1, j = 2; i < nFftSize2; i++) {
        xt1 = pBufL[j] * _pFilterTblL[i];
        xt2 = pBufR[j++] * _pFilterTblR[i];
        yt1 = pBufL[j] * _pFilterTblL[i];
        yt2 = pBufR[j++] * _pFilterTblR[i];
        
        _pCrossBufRe[i] = xt1 * xt2 + yt1 * yt2;
        _pCrossBufIm[i] = xt2 * yt1 - xt1 * yt2;
    }
    
    _oCrossBufRe.Smoothing(_pCrossBufRe, _fSmoothing1, _fSmoothing2);
    _oCrossBufRe.Averaging();
    
    _oCrossBufIm.Smoothing(_pCrossBufIm, _fSmoothing1, _fSmoothing2);
    _oCrossBufIm.Averaging();
}

- (void)setDispData
{
    switch (_nMode) {
        case FFT_MODE_PWS:
            [self setDispDataPws];
            break;
        case FFT_MODE_OCT:
            [self setDispDataOct];
            break;
        case FFT_MODE_3DD:
            [self setDispData3dd];
            break;
        case FFT_MODE_CRF:
            [self setDispDataCrf];
            break;
        case FFT_MODE_PHS:
            [self setDispDataPhs];
            break;
        case FFT_MODE_SPG:
            [self setDispDataSpg];
            break;
        case FFT_MODE_CRS:
            [self setDispDataCrs];
            break;
        case FFT_MODE_COH:
            [self setDispDataCoh];
            break;
        case FFT_MODE_CEP:
            [self setDispDataCep];
            break;
    }
}

- (void)setViewMode
{
    if ((_nMode == FFT_MODE_CRF && g_oSetData.Fft.nCorrelation != 0) || _nMode == FFT_MODE_PHS || _nMode == FFT_MODE_CRS || _nMode == FFT_MODE_COH) {
        _nChannel = CH_STEREO;
        _bLch = YES;
        _bRch = NO;
        _nViewMode = VM_SINGLE;
    } else {
        _nChannel = g_oSetData.Fft.nChannel;
        _bLch = (_nChannel != CH_RIGHT_ONLY);
        _bRch = (_nChannel == CH_STEREO || _nChannel == CH_RIGHT_ONLY);
        
        if (_nChannel == CH_STEREO) {
            if (g_oSetData.Fft.bRlSplit)
                _nViewMode = VM_SPLIT;
            else
                _nViewMode = VM_OVERLAY;
        } else
            _nViewMode = VM_SINGLE;
    }
}

- (void)setMinMax
{
    if (g_oSetData.Fft.bAutoFreq || _nMode == FFT_MODE_OCT) {
        _nMaxFreq = g_oSetData.Fft.nSampleRate / 2;
        _nMinFreq = fmax(20, g_oSetData.Fft.nSampleRate / g_oSetData.Fft.nFftSize);
    } else {
        _nMaxFreq = g_oSetData.Fft.nMaxFreq;
        if (g_oSetData.Fft.nFftScale == 0 && g_oSetData.Fft.nMinFreq == 0)
            _nMinFreq = 1;
        else
            _nMinFreq = g_oSetData.Fft.nMinFreq;
    }
    
    if (_nMinFreq >= _nMaxFreq)
        _nMaxFreq = _nMinFreq + 1;
    
    _fLogMaxFreq = log(_nMaxFreq);
    _fLogMinFreq = log(_nMinFreq);
    
    if (g_oSetData.Fft.bAutoLevel) {
        switch (_nMode) {
            case FFT_MODE_PWS:
            case FFT_MODE_PHS:
            case FFT_MODE_CRS:
            case FFT_MODE_COH:
                _nMaxLevel = ((int)(-_oMicCalDataL.fInputSens) + 19) / 20 * 20;
                _nMinLevel = _nMaxLevel - 120;
                break;
            case FFT_MODE_OCT:
                _nMaxLevel = ((int)(-_oMicCalDataL.fInputSens) + 9) / 10 * 10;
                _nMinLevel = _nMaxLevel - 100;
                break;
            case FFT_MODE_3DD:
                _nMaxLevel = ((int)(-_oMicCalDataL.fInputSens) + 9) / 10 * 10;
                _nMinLevel = _nMaxLevel - 110;
                break;
            case FFT_MODE_SPG:
                _nMaxLevel = ((int)(-_oMicCalDataL.fInputSens) + 9) / 10 * 10 - 10;
                _nMinLevel = _nMaxLevel - 60;
                break;
            case FFT_MODE_CEP:
                _nMaxLevel = 80;
                _nMinLevel = -80;
                break;
        }
    } else {
        _nMaxLevel = g_oSetData.Fft.nMaxLevel;
        _nMinLevel = g_oSetData.Fft.nMinLevel;
        if (_nMaxLevel == _nMinLevel)
            _nMinLevel = _nMaxLevel - 1;
    }
    
    if (_nMinLevel >= _nMaxLevel)
        _nMaxLevel = _nMinLevel + 1;
}

- (void)drawDataView:(CGContextRef)context :(int)channel
{
	switch (_nMode) {
        case FFT_MODE_PWS:
            [self drawDataPws:context :channel];
            break;
        case FFT_MODE_OCT:
            [self drawDataOct:context :channel];
            break;
        case FFT_MODE_3DD:
            [self drawData3dd:context :channel];
            break;
        case FFT_MODE_CRF:
            [self drawDataCrf:context :channel];
            break;
        case FFT_MODE_PHS:
            [self drawDataPhs:context :channel];
            break;
        case FFT_MODE_SPG:
            [self drawDataSpg:context :channel];
            break;
        case FFT_MODE_CRS:
            [self drawDataCrs:context :channel];
            break;
        case FFT_MODE_COH:
            [self drawDataCoh:context :channel];
            break;
        case FFT_MODE_CEP:
            [self drawDataCep:context :channel];
            break;
    }
}

- (void)drawNote:(NSString *)text :(int)top :(int)right
{
    CGSize size;
    CGFloat x, y;
    NSString *drawText;
    NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  [UIFont systemFontOfSize:FONT_SIZE_SCALE], NSFontAttributeName,
                                  nil];
    
    if (text == nil) {
        switch (_nChannel) {
            case CH_MONO:
                text = @"Mono";
                break;
            case CH_STEREO:
                text = @"";
                break;
            case CH_LEFT_ONLY:
                text = @"Lch";
                break;
            case CH_RIGHT_ONLY:
                text = @"Rch";
                break;
            case CH_DIFFERENCE:
                text = @"Difference";
                break;
        }
    }
    
    size = [text sizeWithAttributes:attrs];
    x = right - size.width - 10;
    y = top + 5;
    
    drawText = @"Lch";
    if ([text rangeOfString:drawText].location != NSNotFound)
        x = [self drawNoteSub:drawText :x :y :attrs :_colorLeft];
    
    drawText = @" / ";
    if ([text rangeOfString:drawText].location != NSNotFound)
        x = [self drawNoteSub:drawText :x :y :attrs :_colorGray];
    
    drawText = @"Rch";
    if ([text rangeOfString:drawText].location != NSNotFound)
        x = [self drawNoteSub:drawText :x :y :attrs :_colorRight];
    
    drawText = @"Mono";
    if ([text rangeOfString:drawText].location != NSNotFound)
        x = [self drawNoteSub:drawText :x :y :attrs :_colorLeft];
    
    drawText = @"Difference";
    if ([text rangeOfString:drawText].location != NSNotFound)
        x = [self drawNoteSub:drawText :x :y :attrs :_colorLeft];
}

- (CGFloat)drawNoteSub:(NSString *)text :(CGFloat)x :(CGFloat)y :(NSMutableDictionary *)attrs :(UIColor *)color
{
    CGSize size;
    
    [attrs removeObjectForKey:NSForegroundColorAttributeName];
    [attrs setValue:color forKey:NSForegroundColorAttributeName];
    DrawString(text, x, y, attrs);
    size = [text sizeWithAttributes:attrs];
    
    return x + size.width;
}

- (void)touchesScaleView:(CGPoint)point
{
	[self setDispFreq:point];
}

- (void)setDispFreq:(CGPoint)point
{
	if (point.x < 0 || point.x >= _nFrameRight || point.y < 0 || point.y >= _nFrameBottom) {
		[self resetDispFreq];
		return;
	}

	switch (_nMode) {
		case FFT_MODE_PWS:
			[self setDispFreqPws:point];
			break;
		case FFT_MODE_OCT:
			[self setDispFreqOct:point];
			break;
		case FFT_MODE_CRF:
			[self setDispFreqCrf:point];
			break;
		case FFT_MODE_PHS:
			[self setDispFreqPhs:point];
			break;
		case FFT_MODE_CRS:
			[self setDispFreqCrs:point];
			break;
		case FFT_MODE_COH:
			[self setDispFreqCoh:point];
			break;
		case FFT_MODE_CEP:
			[self setDispFreqCep:point];
			break;
	}
}

- (void)resetDispFreq
{
	switch (_nMode) {
		case FFT_MODE_PWS:
			[self resetDispFreqPws];
			break;
		case FFT_MODE_OCT:
			[self resetDispFreqOct];
			break;
		case FFT_MODE_CRF:
			[self resetDispFreqCrf];
			break;
		case FFT_MODE_PHS:
			[self resetDispFreqPhs];
			break;
		case FFT_MODE_CRS:
			[self resetDispFreqCrs];
			break;
		case FFT_MODE_COH:
			[self resetDispFreqCoh];
			break;
		case FFT_MODE_CEP:
			[self resetDispFreqCep];
			break;
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if([[segue identifier] isEqualToString:@"Calibration"]) {
		CalibrationViewController *nextViewController = [segue destinationViewController];
		nextViewController.nMicCalID = g_oSetData.Fft.nMicCalID;
		nextViewController.delegate = self;
	}
}

- (void)setMicCalID:(int)nMicCalID
{
	g_oSetData.Fft.nMicCalID = nMicCalID;
	[self setMicCalData];
	[self setFFT];
}

- (void)setMicCalData
{
	if (g_oSetData.Fft.nMicCalID != -1) {
		CDbMicCal dbMicCal;

		if (dbMicCal.Open()) {
			if (dbMicCal.ReadRecID(g_oSetData.Fft.nMicCalID, &_oMicCalDataL)) {
				if (dbMicCal.SearchRecID(-g_oSetData.Fft.nMicCalID - 1))
					dbMicCal.ReadRecID(-g_oSetData.Fft.nMicCalID - 1, &_oMicCalDataR);
				else
					_oMicCalDataR = _oMicCalDataL;

				self.outletMicCal.text = _oMicCalDataL.sMicInfo;

				return;
			}
		}
	}

	_oMicCalDataL.fInputSens = 0;
	_oMicCalDataL.nFreqData = 0;
	_oMicCalDataR.fInputSens = 0;
	_oMicCalDataR.nFreqData = 0;

	self.outletMicCal.text = @"";
}

- (void)setCompareColor
{
    _colorSaveLeft = _colorLeft;
    _colorSaveRight = _colorRight;
    _colorSaveLightGreen = _colorLightGreen;
    _colorSaveCross = _colorCross;
    _colorSaveCoherence = _colorCoherence;
    _imageSaveOctLeft = _imageOctLeft;
    _imageSaveOctRight = _imageOctRight;

    _colorLeft = [UIColor colorWithRed:0.2 green:0.2 blue:0.8 alpha:1.0];
    _colorRight = [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1.0];
    _colorLightGreen = _colorGreen;
    _colorCross = _colorGreen;
    _colorCoherence = _colorRightPeak;
    _imageOctLeft = nil;
    _imageOctRight = nil;
}

- (void)restoreColor
{
    _colorLeft = _colorSaveLeft;
    _colorRight = _colorSaveRight;
    _colorLightGreen = _colorSaveLightGreen;
    _colorCross = _colorSaveCross;
    _colorCoherence = _colorSaveCoherence;
    _imageOctLeft = _imageSaveOctLeft;
    _imageOctRight = _imageSaveOctRight;
}

@end
