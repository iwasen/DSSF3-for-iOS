//
//  SgViewController.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/04/03.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "SgViewController.h"
#import "Common.h"
#import "SG.h"

@interface SgViewController ()

@property (nonatomic, weak) IBOutlet UISegmentedControl *outletSgMode;
@property (nonatomic, weak) IBOutlet UIView *outletSgContainer;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletOnOff;
@property (nonatomic, weak) IBOutlet CtComboBox *outletSampleRate;
@property (nonatomic, weak) IBOutlet CtSlider *outletLevelLeft;
@property (nonatomic, weak) IBOutlet CtSlider *outletLevelRight;
@property (nonatomic, weak) IBOutlet CtTextField *outletLevelLeftText;
@property (nonatomic, weak) IBOutlet CtTextField *outletLevelRightText;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletLevelLink;

@end

@implementation SgViewController
{
    BOOL _bStart;
    float _fTimeCount;
    float _fBlockTime;
    int _nTimeCount;
    NSArray *_sgViews;
    CSG _oSG;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
	UINib *nib = [UINib nibWithNibName:IS_PHONE ? @"SgView_iPhone" : @"SgView_iPad" bundle:nil];
    _sgViews = [nib instantiateWithOwner:nil options:nil];

    [self initViews];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(initViews) name:@"InitViews" object:nil];
}

- (void)initViews
{
    [self setMode];

    SetSampleRateList(self.outletSampleRate, g_oSetData.Sg.nSampleRate);
    
    [self setLevelL:g_oSetData.Sg.nLevelL];
    [self setLevelR:g_oSetData.Sg.nLevelR];

    self.outletLevelLink.checked = g_oSetData.Sg.bRendou;
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
	UIViewController *viewController;

	self.outletSgMode.selectedSegmentIndex = g_oSetData.Sg.nMode;

	for (viewController in self.childViewControllers)
		[self hideContentController:viewController];

	viewController = _sgViews[g_oSetData.Sg.nMode];
	viewController.view.frame = self.outletSgContainer.bounds;
	[self displayContentController:viewController];
}

- (void)displayContentController:(UIViewController *)content
{
	[self addChildViewController:content];
	[self.outletSgContainer addSubview:content.view];
	[content didMoveToParentViewController:self];
}

- (void)hideContentController:(UIViewController *)content
{
	[content willMoveToParentViewController:nil];
	[content.view removeFromSuperview];
	[content removeFromParentViewController];
}

- (IBAction)changeOnOff:(UISegmentedControl *)sender
{
    if (sender.selectedSegmentIndex == 1) {
        [self start];
    } else {
        [self stop];
    }
}

- (IBAction)changeSgMode:(UISegmentedControl *)sender
{
	[self stop];

	g_oSetData.Sg.nMode = (int)sender.selectedSegmentIndex;
	[self setMode];
}

- (IBAction)changeLevelLeft:(CtSlider *)sender
{
    [self setLevelL:sender.value];
}

- (IBAction)changeLevelRight:(CtSlider *)sender
{
    [self setLevelR:sender.value];
}

- (IBAction)changeLevelLeftText:(CtTextField *)sender
{
    [self setLevelL:sender.intValue];
}

- (IBAction)changeLevelRightText:(CtTextField *)sender
{
    [self setLevelR:sender.intValue];
}

- (IBAction)changeLevelLink:(CtCheckBox *)sender
{
    g_oSetData.Sg.bRendou = self.outletLevelLink.checked;
}

- (void)start
{
	if (!_bStart)
		[AudioOutputEx start:g_oSetData.Sg.nSampleRate :NUM_CHANNELS_2 :SG_SPB :self];
}

- (void)stop
{
	if (_bStart)
		[AudioOutputEx stop];
}

- (int)getChannel
{
    int nChannel = 1;
    
    switch (g_oSetData.Sg.nMode) {
        case SG_MODE_TONE:
        case SG_MODE_NOISE:
            nChannel = 2;
            break;
    }
    
    return nChannel;
}

- (void)setLevelL:(int)nLevel
{
    [self setLevelL2:nLevel];
    if (g_oSetData.Sg.bRendou)
        [self setLevelR2:nLevel];
}

- (void)setLevelL2:(int)nLevel
{
    if (nLevel < 0)
        nLevel = 0;
    else if (nLevel > 100)
        nLevel = 100;
    
    self.outletLevelLeftText.intValue = nLevel;
    self.outletLevelLeft.value = nLevel;
    
    g_oSetData.Sg.nLevelL = nLevel;
    
    [self setVolume];
}

- (void)setLevelR:(int)nLevel
{
    [self setLevelR2:nLevel];
    if (g_oSetData.Sg.bRendou)
        [self setLevelL2:nLevel];
}

- (void)setLevelR2:(int)nLevel
{
    if (nLevel < 0)
        nLevel = 0;
    else if (nLevel > 100)
        nLevel = 100;
    
    self.outletLevelRightText.intValue = nLevel;
    self.outletLevelRight.value = nLevel;
    
    g_oSetData.Sg.nLevelR = nLevel;
    
    [self setVolume];
}

- (void)setVolume
{
    //未実装
    //m_pWaveOut->SetVolume(g_oSetData.Sg.nLLevel * 0xffff / 100, g_oSetData.Sg.nRLevel * 0xffff / 100);
}

- (void)audioOutputStart:(AudioInfo *)audioInfo
{
	_bStart = YES;

	self.outletOnOff.selectedSegmentIndex = 1;

	_fBlockTime = (float)SG_SPB / g_oSetData.Sg.nSampleRate;

	_oSG.Init();

	[self setVolume];
}

- (void)audioOutputStop
{
	_bStart = NO;

	self.outletOnOff.selectedSegmentIndex = 0;
}

- (void)audioOutputData:(AudioData *)audioData
{
    audioData->nDataSize = _oSG.SetWaveData(audioData);
}

@end
