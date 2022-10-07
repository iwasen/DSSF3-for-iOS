//
//  OsViewController.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/18.
//  Copyright (c) 2015年 aizawa. All rights reserved.
//

#import "OsViewController.h"
#import "Common.h"
#import "OsGraphView.h"

#define N_INTERPOLATION 15
#define MAX_LEVEL 50000

static const float tSweepTime[] = {
    1,
    0.5, 0.2, 0.1,
    0.05, 0.02, 0.01,
    0.005, 0.002, 0.001,
    0.0005, 0.0002, 0.0001,
    0.00005, 0.00002, 0.00001
};

static const int tInterpolation[] = {
    1,
    1, 1, 1,
    1, 1, 1,
    1, 1, 1,
    2, 2, 4,
    4, 8, 16
};

static const int tLevelRange[] = {
    1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000, 50000
};

@interface OsViewController ()

@property (nonatomic, weak) IBOutlet OsGraphView *outletGraphView;
@property (nonatomic, weak) IBOutlet UIScrollView *outletScrollView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletOnOff;
@property (nonatomic, weak) IBOutlet CtButton *outletDispMode;
@property (nonatomic, weak) IBOutlet CtSlider *outletPosLeft;
@property (nonatomic, weak) IBOutlet CtSlider *outletPosRight;
@property (nonatomic, weak) IBOutlet CtSlider *outletLevelLeft;
@property (nonatomic, weak) IBOutlet CtSlider *outletLevelRight;
@property (nonatomic, weak) IBOutlet CtSlider *outletDelay;
@property (nonatomic, weak) IBOutlet CtSlider *outletSweep;
@property (nonatomic, weak) IBOutlet CtSlider *outletTrigLevel;
@property (nonatomic, weak) IBOutlet CtTextField *outletPosLeftText;
@property (nonatomic, weak) IBOutlet CtTextField *outletPosRightText;
@property (nonatomic, weak) IBOutlet CtTextField *outletLevelLeftText;
@property (nonatomic, weak) IBOutlet CtTextField *outletLevelRightText;
@property (nonatomic, weak) IBOutlet CtTextField *outletDelayText;
@property (nonatomic, weak) IBOutlet CtTextField *outletSweepText;
@property (nonatomic, weak) IBOutlet CtTextField *outletTrigLevelText;
@property (nonatomic, weak) IBOutlet CtComboBox *outletDelayRange;
@property (nonatomic, weak) IBOutlet CtComboBox *outletSampleRate;
@property (nonatomic, weak) IBOutlet CtComboBox *outletChannel;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletLevelAuto;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletLevelLink;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletReverseLeft;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletReverseRight;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletXY;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletZeroLevel;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletTrigHighCut;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletTrigLowCut;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletTrigPos;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletTrigDisp;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletTrigFree;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletTrigSingle;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletTrigAuto;
@property (nonatomic, weak) IBOutlet CtButton *outletPosAlt;
@property (nonatomic, weak) IBOutlet CtButton *outletTrigReset;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletTrigChannel;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletTrigSlope;

@end

@implementation OsViewController
{
    OsGraphView *_viewOsGraph;
    CGRect _rectGraphView;
    CGSize _sizeGraphView;
    float *_bufLeft;
    float *_bufRight;
    BOOL _bStart;
    int _nBlockSize;
    BOOL _bTrigger;
    float _fTrigLevel;
    int _nTrigCounter;
    BOOL _bTrigSingle;
    BOOL _bTrigSingleMode;
    float _fTrigWork;
    float _fSweepTime;
    int _nSweepCounter;
    int _nDelayTime;
    int _nDelayCounter;
    int _nLvAdjCounterL;
    int _nLvAdjCounterR;
    int _nDelayVal;
    float _fAvrVal;
    int _nLevelL;
    int _nLevelR;
    float _fLevelL;
    float _fLevelR;
    float _fSweepDiv;
    float _fDelayTime;
    float _fOffset;
    BOOL _bMax;
    float *_pInterpolationFilter;
    float *_pInterpolationBufL;
    float *_pInterpolationBufR;
    int _nInterpolationPtr;
    float *_pLeftData;
    float *_pRightData;
    //    float _fTimeCount;
    //    int _nTimeCount;
    //    float _fBlockTime;
    BOOL _bLch;
    BOOL _bRch;
    float _fLevelMul;
    float _fLevelRangeMul;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _bStart = NO;
    _bTrigSingleMode = NO;
    _bMax = NO;
    _pInterpolationFilter = NULL;
    _pInterpolationBufL = new float[N_INTERPOLATION];
    _pInterpolationBufR = new float[N_INTERPOLATION];
    _pLeftData = NULL;
    _pRightData = NULL;
//	_fTimeCount = 0;
//	_nTimeCount = -1;
    _bLch = NO;
    _bRch = NO;
    _rectGraphView = self.outletGraphView.frame;

    [self initViews];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(initViews) name:@"InitViews" object:nil];
}

- (void)initViews
{
    self.outletGraphView.translatesAutoresizingMaskIntoConstraints = YES;

    if (IS_PAD) {
        [self setDispMode];
    }
    
    [self setLevelRange];
    
    [self setChannelMode];
    
    [self setLevelLeft];
    
    [self setLevelRight];
    
    self.outletLevelAuto.checked = g_oSetData.Os.bLevelAuto;
    self.outletLevelLink.checked = g_oSetData.Os.bRendou;
    
    self.outletPosLeft.minValue = -(self.outletGraphView.nVDiv * 5);
    self.outletPosLeft.maxValue = self.outletGraphView.nVDiv * 5;
    [self setPosLeft];
    
    self.outletPosRight.minValue = -(self.outletGraphView.nVDiv * 5);
    self.outletPosRight.maxValue = self.outletGraphView.nVDiv * 5;
    [self setPosRight];
    
    self.outletSweep.value = g_oSetData.Os.nSweep;
    [self setSweepVal];
    
    for (int i = 0; i < 4; i++) {
        NSString *str = [NSString stringWithFormat:@"%d ms", (int)pow(10.0, i)];
        [self.outletDelayRange addItem:str :0];
    }
    self.outletDelayRange.selectedIndex = g_oSetData.Os.nDelayRange;
    
    _nDelayVal = 0;
    [self setDelayVal];
    
    self.outletTrigLevel.minValue = -(self.outletGraphView.nVDiv * 5);
    self.outletTrigLevel.maxValue = self.outletGraphView.nVDiv * 5;
    self.outletTrigLevel.value = -g_oSetData.Os.nTrigLevel;
    self.outletTrigLevelText.intValue = g_oSetData.Os.nTrigLevel;
    
    self.outletTrigChannel.selectedSegmentIndex = g_oSetData.Os.nTrigChannel;
    self.outletTrigSlope.selectedSegmentIndex = g_oSetData.Os.nTrigSlope;
    
    self.outletTrigAuto.checked = g_oSetData.Os.bTrigAuto;
    self.outletTrigPos.checked = g_oSetData.Os.bTrigPos;
    self.outletTrigDisp.checked = g_oSetData.Os.bTrigDisp;
    self.outletTrigFree.checked = g_oSetData.Os.bTrigFree;
    self.outletTrigHighCut.checked = g_oSetData.Os.bTrigHighCut;
    self.outletTrigLowCut.checked = g_oSetData.Os.bTrigLowCut;
    
    self.outletReverseLeft.checked = g_oSetData.Os.bReverseL;
    self.outletReverseRight.checked = g_oSetData.Os.bReverseR;
    self.outletXY.checked = g_oSetData.Os.bXY;
    self.outletZeroLevel.checked = g_oSetData.Os.bZeroLevel;
    
    SetSampleRateList(self.outletSampleRate, g_oSetData.Os.nSampleRate);
    
    SetChannelList(self.outletChannel, g_oSetData.Os.nChannel);
    
    self.outletTrigLevel.enabled = !g_oSetData.Os.bTrigAuto;

	[self enableControls];

	[self enableTrigReset];
}

-(void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];

	if (IS_PHONE) {
		_rectGraphView = self.outletGraphView.frame;

		SetContentSize(self.outletScrollView);

		[self setDispMode];

		[self initScreen];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];

	[self stop];
}

- (void)setLevelRange
{
    float fCalFactor = (g_oSetData.Os.fCalValue == 0) ? 1 : g_oSetData.Os.fCalValue / g_oSetData.Os.fCalLevel;
    
    _fLevelRangeMul = pow(10, floor(log10(fCalFactor * 2)));
    _fLevelMul = _fLevelRangeMul / fCalFactor;
}

- (void)setChannelMode
{
    _bLch = (g_oSetData.Os.nChannel != CH_RIGHT_ONLY);
    _bRch = (g_oSetData.Os.nChannel == CH_STEREO || g_oSetData.Os.nChannel == CH_RIGHT_ONLY);
}

- (void)setLevelLeft
{
    self.outletLevelLeft.value = g_oSetData.Os.nLevelL;
    _nLevelL = tLevelRange[g_oSetData.Os.nLevelL];
    _fLevelL = _nLevelL / PowDouble(16);
    self.outletLevelLeftText.text = [self addNumberPrefix:_nLevelL * _fLevelRangeMul];
}

- (void)setLevelRight
{
    self.outletLevelRight.value = g_oSetData.Os.nLevelR;
    _nLevelR = tLevelRange[g_oSetData.Os.nLevelR];
    _fLevelR = _nLevelR / PowDouble(16);
    self.outletLevelRightText.text = [self addNumberPrefix:_nLevelR * _fLevelRangeMul];
}

- (void)setPosLeft
{
    self.outletPosLeft.value = g_oSetData.Os.nPosL;
    self.outletPosLeftText.intValue = g_oSetData.Os.nPosL;
    
    if (!g_oSetData.Os.bXY && g_oSetData.Os.bZeroLevel)
        [self.outletGraphView setNeedsDisplay];
}

- (void)setPosRight
{
    self.outletPosRight.value = g_oSetData.Os.nPosR;
    self.outletPosRightText.intValue = g_oSetData.Os.nPosR;
    
    if (!g_oSetData.Os.bXY && g_oSetData.Os.bZeroLevel)
        [self.outletGraphView setNeedsDisplay];
}

- (void)enableControls
{
    self.outletLevelLeft.enabled = !(g_oSetData.Os.nChannel == CH_RIGHT_ONLY);
    self.outletLevelLeftText.enabled = !(g_oSetData.Os.nChannel == CH_RIGHT_ONLY);
    self.outletPosLeft.enabled = _bLch;
    self.outletPosLeftText.enabled = _bLch;
    [self.outletTrigChannel setEnabled:_bLch forSegmentAtIndex:0];
    self.outletReverseLeft.enabled = _bLch;
    
    self.outletLevelRight.enabled = !(g_oSetData.Os.nChannel == CH_LEFT_ONLY);
    self.outletLevelRightText.enabled = !(g_oSetData.Os.nChannel == CH_LEFT_ONLY);
    self.outletPosRight.enabled = _bRch;
    self.outletPosRightText.enabled = _bRch;
    [self.outletTrigChannel setEnabled:_bRch forSegmentAtIndex:1];
    self.outletReverseRight.enabled = _bRch;
    
    self.outletPosAlt.enabled = (g_oSetData.Os.nChannel == CH_STEREO);
    self.outletXY.enabled = (g_oSetData.Os.nChannel == CH_STEREO);
    self.outletLevelLink.enabled = (g_oSetData.Os.nChannel == CH_MONO || g_oSetData.Os.nChannel == CH_STEREO || g_oSetData.Os.nChannel == CH_DIFFERENCE);
}

- (void)enableTrigReset
{
    self.outletTrigReset.enabled = (_bTrigSingleMode && _bTrigSingle);
}

- (void)dealloc
{
    [self freeDataBuf];
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
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
            if (!g_oSetData.Os.bShowSettings) {
                g_oSetData.Os.bShowSettings = YES;
                [self setDispMode];
            }
        } else if (distance > previousDistance) {
            if (g_oSetData.Os.bShowSettings) {
                g_oSetData.Os.bShowSettings = NO;
                [self setDispMode];
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
- (IBAction)changeOnOff:(UISegmentedControl *)sender
{
    if (sender.selectedSegmentIndex == 1)
        [self start];
    else
        [self stop];
}

- (IBAction)changeDispMode:(UIButton *)sender
{
    g_oSetData.Os.bShowSettings = !g_oSetData.Os.bShowSettings;
    
    [self setDispMode];
}

- (IBAction)changeLevelLeft:(CtSlider *)sender
{
    g_oSetData.Os.nLevelL = sender.value;
    _nLevelL = tLevelRange[g_oSetData.Os.nLevelL];
    _fLevelL = _nLevelL / PowDouble(16);
    self.outletLevelLeftText.text = [self addNumberPrefix:_nLevelL * _fLevelRangeMul];
    if ([self isLevelLink]) {
        g_oSetData.Os.nLevelR = g_oSetData.Os.nLevelL;
        [self setLevelRight];
    }
    [self dispInfo];
}

- (IBAction)changeLevelRight:(CtSlider *)sender
{
    g_oSetData.Os.nLevelR = sender.value;
    _nLevelR = tLevelRange[g_oSetData.Os.nLevelR];
    _fLevelR = _nLevelR / PowDouble(16);
    self.outletLevelRightText.text = [self addNumberPrefix:_nLevelR * _fLevelRangeMul];
    if ([self isLevelLink]) {
        g_oSetData.Os.nLevelL = g_oSetData.Os.nLevelR;
        [self setLevelLeft];
    }
    [self dispInfo];
}

- (IBAction)changePosLeft:(CtSlider *)sender
{
    g_oSetData.Os.nPosL = sender.value;
    [self setPosLeft];
    [self dispTriggerMark:NO];
}

- (IBAction)changePosRight:(CtSlider *)sender
{
    g_oSetData.Os.nPosR = sender.value;
    [self setPosRight];
    [self dispTriggerMark:NO];

}

- (IBAction)changeTrigLevel:(CtSlider *)sender
{
    g_oSetData.Os.nTrigLevel = sender.value;
    self.outletTrigLevelText.intValue = g_oSetData.Os.nTrigLevel;
    [self getTriggerLevel];
    _fTrigWork = _fTrigLevel;
    [self dispTriggerMark:YES];
}

- (IBAction)changeEndTrigLevel:(CtSlider *)sender
{
    [self dispTriggerMark:NO];
}

- (IBAction)changeLevelAuto:(CtCheckBox *)sender
{
    g_oSetData.Os.bLevelAuto = sender.checked;
}

- (IBAction)changeLevelLink:(CtCheckBox *)sender
{
    g_oSetData.Os.bRendou = sender.checked;
}

- (IBAction)changePosCenter
{
    g_oSetData.Os.nPosL = 0;
    [self setPosLeft];
    
    g_oSetData.Os.nPosR = 0;
    [self setPosRight];
    
    [self dispTriggerMark:NO];
}

- (IBAction)changePosAlt
{
    g_oSetData.Os.nPosL = 20;
    [self setPosLeft];
    
    g_oSetData.Os.nPosR = -20;
    [self setPosRight];
    
    [self dispTriggerMark:NO];
}

- (IBAction)changeSweep:(CtSlider *)sender
{
    g_oSetData.Os.nSweep = sender.value;
    [self setSweepVal];
    [self dispInfo];
}

- (IBAction)changeDelay:(CtSlider *)sender
{
    _nDelayVal = sender.value;
    [self setDelayVal];
    [self dispInfo];
}

- (IBAction)changeDelayRange:(CtComboBox *)sender
{
    g_oSetData.Os.nDelayRange = sender.selectedIndex;
    [self setDelayVal];
}

- (IBAction)changeReverseLeft:(CtCheckBox *)sender
{
    g_oSetData.Os.bReverseL = sender.checked;
}

- (IBAction)changeReverseRight:(CtCheckBox *)sender
{
    g_oSetData.Os.bReverseR = sender.checked;
}

- (IBAction)changeXY:(CtCheckBox *)sender
{
    g_oSetData.Os.bXY = sender.checked;
    if (_bStart) {
        [self.outletGraphView clearScreen];
        [self dispInfo];
    }
    [self dispTriggerMark:NO];
}

- (IBAction)changeZeroLevel:(CtCheckBox *)sender
{
    g_oSetData.Os.bZeroLevel = sender.checked;
    [self.outletGraphView setNeedsDisplay];
}

- (IBAction)changeTrigAuto:(CtCheckBox *)sender
{
    g_oSetData.Os.bTrigAuto = sender.checked;
    self.outletTrigLevel.enabled = !g_oSetData.Os.bTrigAuto;
}

- (IBAction)changeTrigChannel:(UISegmentedControl *)sender
{
    g_oSetData.Os.nTrigChannel = (int)sender.selectedSegmentIndex;
    [self dispTriggerMark:NO];
}

- (IBAction)changeTrigSlope:(UISegmentedControl *)sender
{
    g_oSetData.Os.nTrigSlope = (int)sender.selectedSegmentIndex;
}

- (IBAction)changeTrigHighcut:(CtCheckBox *)sender
{
    g_oSetData.Os.bTrigHighCut = sender.checked;
}

- (IBAction)changeTrigLowcut:(CtCheckBox *)sender
{
    g_oSetData.Os.bTrigLowCut = sender.checked;
}

- (IBAction)changeTrigPos:(CtCheckBox *)sender
{
    g_oSetData.Os.bTrigPos = sender.checked;
    [self dispTriggerMark:NO];
}

- (IBAction)changeTrigDisp:(CtCheckBox *)sender
{
    g_oSetData.Os.bTrigDisp = sender.checked;
    [self dispTriggerMark:NO];
}

- (IBAction)changeTrigFree:(CtCheckBox *)sender
{
    g_oSetData.Os.bTrigFree = sender.checked;
}

- (IBAction)changeTrigSingle:(CtCheckBox *)sender
{
    _bTrigSingleMode = sender.checked;
    [self enableTrigReset];
}

- (IBAction)changeTrigReset:(CtButton *)sender
{
    _bTrigSingle = NO;
    [self enableTrigReset];
}

- (IBAction)changeSampleRate:(CtComboBox *)sender
{
    g_oSetData.Os.nSampleRate = self.outletSampleRate.selectedItemData;
    [self setSweepVal];
    [self restart];
}

- (IBAction)changeChannel:(CtComboBox *)sender
{
    int nChannel = sender.selectedIndex;
    
    if (g_oSetData.Os.nChannel != nChannel) {
        g_oSetData.Os.nChannel = nChannel;
        [self setChannelMode];
        
        if (nChannel != CH_STEREO) {
            g_oSetData.Os.nTrigChannel = (nChannel == CH_RIGHT_ONLY) ? 1 : 0;
            if (self.outletTrigChannel.selectedSegmentIndex != g_oSetData.Os.nTrigChannel) {
                self.outletTrigChannel.selectedSegmentIndex = g_oSetData.Os.nTrigChannel;
            }
            
            g_oSetData.Os.bXY = NO;
            if (self.outletXY.checked != g_oSetData.Os.bXY) {
                self.outletXY.checked = g_oSetData.Os.bXY;
                [self.outletGraphView clearScreen];
            }
        }
        
        [self enableControls];
        
        if (!g_oSetData.Os.bXY && g_oSetData.Os.bZeroLevel)
            [self.outletGraphView setNeedsDisplay];
        
        [self restart];
    }
}

- (void)initScreen
{
    [self.outletGraphView clearScreen];
    [self dispTriggerMark:NO];
}

- (void)start
{
	int nPlaybackSampleRate = [AudioEx getPlaybackSampleRate];
	if (nPlaybackSampleRate != 0 && nPlaybackSampleRate != g_oSetData.Os.nSampleRate) {
		[self.outletSampleRate setSelectedItemData:nPlaybackSampleRate];
		[self changeSampleRate:self.outletSampleRate];
	}

	_nBlockSize = exp2((int)log2(g_oSetData.Os.nSampleRate / 10));
    [AudioInputEx start:g_oSetData.Os.nSampleRate :NUM_CHANNELS_2 :_nBlockSize :self];
}

- (void)stop
{
    [AudioInputEx stop];
}

- (void)setDispMode
{
    if (IS_PHONE) {
        g_oSetData.Os.bShowSettings = YES;
    }

    if (g_oSetData.Os.bShowSettings) {
        [self.outletDispMode setTitle:NSLocalizedString(@"IDS_GRAPH", nil) forState:UIControlStateNormal];
        self.outletGraphView.frame = _rectGraphView;
    } else {
        [self.outletDispMode setTitle:NSLocalizedString(@"IDS_SETTINGS", nil) forState:UIControlStateNormal];
        //self.outletGraphView.frame = self.view.bounds;
        [self.outletGraphView removeFromSuperview];
        self.outletGraphView.frame = CGRectMake(0, 0, self.view.bounds.size.width, 771);   //viewDidLoadでheight=1024となってしまうための応急処置
        [self.view addSubview:self.outletGraphView];
    }
    
    [self.view bringSubviewToFront:self.outletDispMode];
    [self.view bringSubviewToFront:self.outletOnOff];
    
    [self.outletGraphView createDataView];
    [self.outletGraphView clearScreen];
}

- (void)audioInputStart:(AudioInfo *)audioInfo
{
	self.outletOnOff.selectedSegmentIndex = 1;

	_bStart = YES;
	_bTrigger = NO;
	_nTrigCounter = (int)_fSweepTime;
	_bTrigSingle = NO;
	_fTrigWork = 0;
	_fAvrVal = 0;
	_nLvAdjCounterL = 0;
	_nLvAdjCounterR = 0;
	MEMCLEAR(_pInterpolationBufL, N_INTERPOLATION);
	MEMCLEAR(_pInterpolationBufR, N_INTERPOLATION);
	_nInterpolationPtr = 0;

	[self allocDataBuf];

	[self enableTrigReset];

	[self initScreen];

//	_fBlockTime = (float)_nBlockSize / g_oSetData.Os.nSampleRate;

	[self dispInfo];
	[self dispTriggerMark:NO];

	[self.outletGraphView setNeedsDisplay];
}

- (void)audioInputStop
{
	self.outletOnOff.selectedSegmentIndex = 0;

	_bStart = NO;
}

- (void)audioInputData:(AudioData *)audioData
{
    int i;
    int nDataCounter = 0;
    int nSweepCounter = 0;
    BOOL bAvail;
    float fOffset;
    int nBlockSize;
    int nOffset = -1;

    memcpy(_bufLeft, audioData->pLeftData, _nBlockSize * sizeof(float));
    memcpy(_bufRight, audioData->pRightData, _nBlockSize * sizeof(float));
    
    switch (g_oSetData.Os.nChannel) {
        case CH_MONO:
            for (i = 0; i < _nBlockSize; i++) {
                _bufLeft[i] = (_bufLeft[i] + _bufRight[i]) / 2;
            }
            break;
        case CH_DIFFERENCE:
            for (i = 0; i < _nBlockSize; i++) {
                _bufLeft[i] = _bufLeft[i] - _bufRight[i];
            }
            break;
    }
    
    if (g_oSetData.Os.bReverseL) {
        for (i = 0; i < _nBlockSize; i++)
            _bufLeft[i] = -_bufLeft[i];
    }
    
    if (g_oSetData.Os.bReverseR) {
        for (i = 0; i < _nBlockSize; i++)
            _bufRight[i] = -_bufRight[i];
    }
    
    if (g_oSetData.Os.bLevelAuto)
        [self autoLevelAdjust:_bufLeft :_bufRight];
    
    if (g_oSetData.Os.bXY) {
        [self.outletGraphView dispXY:_bufLeft :_bufRight :_nBlockSize :_fLevelL * _fLevelMul :_fLevelR * _fLevelMul :g_oSetData.Os.nPosL :g_oSetData.Os.nPosR];
        return;
    }
    
    nBlockSize = [self interpolation:_bufLeft :_bufRight];
    
    if (g_oSetData.Os.bTrigLowCut) {
        if (g_oSetData.Os.nTrigChannel == 0) {
            for (i = 0; i < nBlockSize; i++)
                _fAvrVal = (_fAvrVal * 9999 + _pLeftData[i]) / 10000;
        } else {
            for (i = 0; i < nBlockSize; i++)
                _fAvrVal = (_fAvrVal * 9999 + _pRightData[i]) / 10000;
        }
    }
    
    if (g_oSetData.Os.bTrigAuto)
        [self autoTrigAdjust:_bufLeft :_bufRight];
    
    [self getTriggerLevel];
    
    bAvail = YES;
    for (i = 0; i < nBlockSize; i++) {
        if ([self checkTrigger:i :&fOffset]) {
            if (bAvail && !_bTrigger) {
                _bTrigger = YES;
                _nDelayCounter = 0;
                _nSweepCounter = 0;
                _fOffset = fOffset;
            }
        }
        
        if (_bTrigger) {
            if (_nDelayCounter >= _nDelayTime * tInterpolation[g_oSetData.Os.nSweep]) {
                if (nOffset == -1) {
                    nOffset = i;
                    nDataCounter = 0;
                    nSweepCounter = _nSweepCounter;
                }
                
                nDataCounter++;
                
                if (_nSweepCounter++ > _fSweepTime) {
                    _bTrigger = NO;
                    bAvail = NO;
                }
            } else
                _nDelayCounter++;
        }
    }
    
    if (nOffset != -1) {
        if (nOffset != 0 && nSweepCounter == 0) {
            nOffset--;
            nSweepCounter--;
            nDataCounter++;
        }

        [self.outletGraphView dispScreen:&_pLeftData[nOffset] :&_pRightData[nOffset] :_fSweepTime :nSweepCounter :nDataCounter :g_oSetData.Os.nChannel : _fLevelL * _fLevelMul :_fLevelR * _fLevelMul :g_oSetData.Os.nPosL :g_oSetData.Os.nPosR :_fOffset];
    }
}

- (BOOL)checkTrigger:(int)nOffset :(float *)pOffset
{
    float fTrigWork;
    float fDataWork;
    BOOL bTrigger;
    
    fTrigWork = _fTrigWork;
    fDataWork = (g_oSetData.Os.nTrigChannel == 0) ? _pLeftData[nOffset] : _pRightData[nOffset];
    
    if (g_oSetData.Os.bTrigHighCut)
        fDataWork = (_fTrigWork * 3 + fDataWork) / 4;
    
    if (g_oSetData.Os.bTrigLowCut)
        fDataWork -= _fAvrVal;
    
    _fTrigWork = fDataWork;
    
    if (_bTrigSingleMode && _bTrigSingle)
        return NO;
    
    bTrigger = NO;
    if (g_oSetData.Os.nTrigSlope == 0) {
        if (fTrigWork < _fTrigLevel && _fTrigWork >= _fTrigLevel)
            bTrigger = YES;
    } else {
        if (fTrigWork > _fTrigLevel && _fTrigWork <= _fTrigLevel)
            bTrigger = YES;
    }
    
    if (bTrigger) {
        _nTrigCounter = (int)(_fSweepTime * 10);
        if (_bTrigSingleMode && !_bTrigSingle) {
            _bTrigSingle = YES;
            [self enableTrigReset];
        }
        *pOffset = (_fTrigWork - _fTrigLevel) / (_fTrigWork - fTrigWork);
        return YES;
    }
    
    if (g_oSetData.Os.bTrigFree && !_bTrigSingleMode && --_nTrigCounter < 0) {
        _nTrigCounter = (int)(_fSweepTime / 4);
        *pOffset = 0;
        return YES;
    }
    
    return NO;
}

- (void)getTriggerLevel
{
    float fLevel;
    
    _fTrigLevel = g_oSetData.Os.nTrigLevel;
    
    if (!g_oSetData.Os.bTrigPos)
        _fTrigLevel -= (g_oSetData.Os.nTrigChannel == 0) ? g_oSetData.Os.nPosL : g_oSetData.Os.nPosR;
    
    fLevel = (g_oSetData.Os.nTrigChannel == 0) ? _fLevelL : _fLevelR;
    _fTrigLevel = _fTrigLevel * fLevel * _fLevelMul / 10;
}

- (void)dispTriggerMark:(BOOL)bDisp
{
    int nTrigLevel;
    
    nTrigLevel = g_oSetData.Os.nTrigLevel;
    if (g_oSetData.Os.bTrigPos)
        nTrigLevel += (g_oSetData.Os.nTrigChannel == 0) ? g_oSetData.Os.nPosL : g_oSetData.Os.nPosR;
    
    [self.outletGraphView dispTriggerLevel:nTrigLevel :g_oSetData.Os.nTrigChannel :!g_oSetData.Os.bXY && (g_oSetData.Os.bTrigDisp || bDisp)];
}

- (void)autoLevelAdjust:(const float *)pLeftData :(const float *)pRightData
{
    float fPeakLeft = 0, fPeakRight = 0;
    float fData;
    int i;
    BOOL bRendou = [self isLevelLink];
    
    for (i = 0; i < _nBlockSize; i++) {
        fData = fabs(*pLeftData++);
        if (fData > fPeakLeft)
            fPeakLeft = fData;
        
        fData = fabs(*pRightData++);
        if (fData > fPeakRight)
            fPeakRight = fData;
    }
    
    if (bRendou)
        fPeakLeft = fmax(fPeakLeft, fPeakRight);
    
    if (_bLch) {
        if (fPeakLeft > _fLevelL * (self.outletGraphView.nVDiv - 2) / 2) {
            if (++_nLvAdjCounterL >= 10) {
                if (g_oSetData.Os.nLevelL < 15) {
                    g_oSetData.Os.nLevelL++;
                    [self setLevelLeft];
                    if (bRendou) {
                        g_oSetData.Os.nLevelR = g_oSetData.Os.nLevelL;
                        [self setLevelRight];
                    }
                    [self dispInfo];
                }
            }
        } else if (fPeakLeft < _fLevelL * 1.5) {
            if (++_nLvAdjCounterL >= 10) {
                if (g_oSetData.Os.nLevelL > 0) {
                    g_oSetData.Os.nLevelL--;
                    [self setLevelLeft];
                    if (bRendou) {
                        g_oSetData.Os.nLevelR = g_oSetData.Os.nLevelL;
                        [self setLevelRight];
                    }
                    [self dispInfo];
                }
            }
        } else
            _nLvAdjCounterL = 0;
    }
    
    if (_bRch && !bRendou) {
        if (fPeakRight > _fLevelR * (self.outletGraphView.nVDiv - 2) / 2) {
            if (++_nLvAdjCounterR >= 10) {
                if (g_oSetData.Os.nLevelR < 15) {
                    g_oSetData.Os.nLevelR++;
                    [self setLevelRight];
                    [self dispInfo];
                }
            }
        } else if (fPeakRight < _fLevelR * 1.5) {
            if (++_nLvAdjCounterR >= 10) {
                if (g_oSetData.Os.nLevelR > 0) {
                    g_oSetData.Os.nLevelR--;
                    [self setLevelRight];
                    [self dispInfo];
                }
            }
        } else
            _nLvAdjCounterR = 0;
    }
}

- (void)autoTrigAdjust:(const float *)pLeftData :(const float *)pRightData
{
    float fLeftSum = 0, fRightSum = 0, fSum;
    int i;
    
    for (i = 0; i < _nBlockSize; i++) {
        fLeftSum += *pLeftData++;
        fRightSum += *pRightData++;
    }
    
    fSum = (g_oSetData.Os.nTrigChannel == 0) ? fLeftSum : fRightSum;
    
    fSum = (fSum / _nBlockSize) * 10 / ((g_oSetData.Os.nTrigChannel == 0 ? _fLevelL : _fLevelR) * _fLevelMul);
    if (!g_oSetData.Os.bTrigPos)
        fSum += (g_oSetData.Os.nTrigChannel == 0) ? g_oSetData.Os.nPosL : g_oSetData.Os.nPosR;
    
    if (fabs(fSum - g_oSetData.Os.nTrigLevel) > 1) {
        g_oSetData.Os.nTrigLevel = (int)fSum;
        self.outletTrigLevel.value = g_oSetData.Os.nTrigLevel / 2;
        self.outletTrigLevelText.intValue = g_oSetData.Os.nTrigLevel;
        [self dispTriggerMark:NO];
    }
}

- (void)dispInfo
{
    NSMutableString *text;
    NSString *p, *p2;
    
    if (!_bStart)
        return;
    
    //sprintf_s(text, "SamplingRate:%gkHz", (float)g_oSetData.Os.nSamplingRate / 1000);
    text = [NSMutableString stringWithFormat:@"SamplingRate:%gkHz", (float)g_oSetData.Os.nSampleRate / 1000];
    [self.outletGraphView dispText:text :0];
    
    [text setString:@""];
    
    if (_bLch) {
        switch (g_oSetData.Os.nChannel) {
            case CH_MONO:
                p2 = @"Lch+Rch";
                break;
            case CH_DIFFERENCE:
                p2 = @"Lch-Rch";
                break;
            default:
                p2 = @"Lch";
                break;
        }
        
        //sprintf_s(p, nSize, "%s:%s%s/div  ", p2, AddNumberPrefix(_nLevelL * _fLevelRangeMul), g_oSetData.Os.sCalUnit);
        p = [NSString stringWithFormat:@"%@:%@%@/div  ", p2, [self addNumberPrefix:_nLevelL * _fLevelRangeMul], g_oSetData.Os.sCalUnit];
        [text appendString:p];
    }
    
    if (_bRch) {
        //sprintf_s(p, nSize, "Rch:%s%s/div  ", AddNumberPrefix(_nLevelR * _fLevelRangeMul), g_oSetData.Os.sCalUnit);
        p = [NSString stringWithFormat:@"Rch:%@%@/div  ", [self addNumberPrefix:_nLevelR * _fLevelRangeMul], g_oSetData.Os.sCalUnit];
        [text appendString:p];
    }
    
    if (!g_oSetData.Os.bXY) {
        //sprintf_s(p, nSize, "Time:%gms/div  Delay:%gms", _fSweepDiv, _fDelayTime);
        p = [NSString stringWithFormat:@"Time:%gms/div  Delay:%gms", _fSweepDiv, _fDelayTime];
        [text appendString:p];
    }
    
    [self.outletGraphView dispText:text :1];
}

- (void)makeInterpolationFilter:(int)n
{
    float a, h;
    int i, kn, k;
    
    if (_pInterpolationFilter != NULL) {
        delete [] _pInterpolationFilter;
        _pInterpolationFilter = NULL;
    }
    
    if (n == 1)
        return;
    
    kn = (N_INTERPOLATION - 1) * n + 1;
    _pInterpolationFilter = new float[kn];
    
    for (i = 0; i < kn; i++) {
        k = i - kn / 2;
        a = k * M_PI / n;
        if (a == 0)
            h = 1;
        else
            h = sin(a) / a;
        
        h *= (0.54 - 0.46 * cos(2 * M_PI * i / (kn - 1)));
        
        _pInterpolationFilter[i] = h;
    }
}

- (int)interpolation:(const float *)pLeftData :(const float *)pRightData
{
    int i, n;
    
    n = tInterpolation[g_oSetData.Os.nSweep];
    
    for (i = 0; i < _nBlockSize; i++) {
        if (n == 1) {
            _pLeftData[i * n] = *pLeftData++;
            _pRightData[i * n] = *pRightData++;
        } else {
            [self convolution:*pLeftData++ :&_pLeftData[i * n] :_pInterpolationBufL];
            [self convolution:*pRightData++ :&_pRightData[i * n] :_pInterpolationBufR];
        }
        
        if (++_nInterpolationPtr >= N_INTERPOLATION)
            _nInterpolationPtr = 0;
    }
    
    return _nBlockSize * n;
}

- (void)convolution:(float)in :(float *)out :(float *)pInterpolationBuf
{
    int i, j, k, n, kn, offset;
    float s;
    
    pInterpolationBuf[_nInterpolationPtr] = in;
    
    n = tInterpolation[g_oSetData.Os.nSweep];
    kn = (N_INTERPOLATION - 1) * n + 1;
    for (i = 0; i < n; i++) {
        s = 0;
        offset = _nInterpolationPtr;
        for (j = 0; j < N_INTERPOLATION; j++) {
            k = j * n + i;
            if (k < kn)
                s += pInterpolationBuf[offset] * _pInterpolationFilter[k];
            if (--offset < 0)
                offset = N_INTERPOLATION - 1;
        }
        *out++ = s;
    }
}

- (void)allocDataBuf
{
    [self freeDataBuf];

	_bufLeft = new float[_nBlockSize];
	_bufRight = new float[_nBlockSize];

    _pLeftData = new float[_nBlockSize * tInterpolation[g_oSetData.Os.nSweep]];
    _pRightData = new float[_nBlockSize * tInterpolation[g_oSetData.Os.nSweep]];
}

- (void)freeDataBuf
{
	if (_bufLeft != NULL) {
		delete [] _bufLeft;
		_bufLeft = NULL;
	}

	if (_bufRight != NULL) {
		delete [] _bufRight;
		_bufRight = NULL;
	}

    if (_pLeftData != NULL) {
        delete [] _pLeftData;
        _pLeftData = NULL;
    }
    
    if (_pRightData != NULL) {
        delete [] _pRightData;
        _pRightData = NULL;
    }
}

- (void)setSweepVal
{
    self.outletSweepText.floatValue = _fSweepDiv = tSweepTime[g_oSetData.Os.nSweep] * 1000;
    _fSweepTime = g_oSetData.Os.nSampleRate * tSweepTime[g_oSetData.Os.nSweep] * self.outletGraphView.nHDiv * tInterpolation[g_oSetData.Os.nSweep];
    _bTrigger = NO;
    _fTrigWork = 0;
    
    [self makeInterpolationFilter:tInterpolation[g_oSetData.Os.nSweep]];
    
    if (_bStart)
        [self allocDataBuf];
}

- (void)setDelayVal
{
    self.outletDelayText.floatValue = _fDelayTime = pow(10.0, self.outletDelayRange.selectedIndex) * _nDelayVal / 100;
    _nDelayTime = int(g_oSetData.Os.nSampleRate * _fDelayTime / 1000);
}

- (NSString *)addNumberPrefix:(float)fNumber
{
    float fMul;
    NSString *sPrefix;
    
    if (fNumber < 0.0001) {
        fMul = 1e6;
        sPrefix = NSLocalizedString(@"IDS_MICRO", nil);;
    } else if (fNumber < 0.1) {
        fMul = 1e3;
        sPrefix = @"m";
    } else {
        fMul = 1;
        sPrefix = @"";
    }
    
    return [NSString stringWithFormat:@"%g%@", fNumber * fMul, sPrefix];
}

- (void)restart
{
    if (_bStart) {
        [self stop];
        [self start];
    }
}

- (BOOL)isLevelLink
{
    switch (g_oSetData.Os.nChannel) {
        case CH_MONO:
        case CH_STEREO:
        case CH_DIFFERENCE:
            return g_oSetData.Os.bRendou;
    }
    return NO;
}

@end
