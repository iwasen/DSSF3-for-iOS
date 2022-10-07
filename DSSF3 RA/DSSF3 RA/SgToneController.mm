//
//  SgToneController.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/04/15.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "SgToneController.h"
#import "Common.h"

@interface SgToneController ()

@property (nonatomic, weak) IBOutlet CtCheckBox *outletFreqLink;
@property (nonatomic, weak) IBOutlet CtSlider *outletFreqLeft;
@property (nonatomic, weak) IBOutlet CtSlider *outletFreqRight;
@property (nonatomic, weak) IBOutlet CtSlider *outletphase;
@property (nonatomic, weak) IBOutlet CtComboBox *outletFreqRange;
@property (nonatomic, weak) IBOutlet CtComboBox *outletWaveForm;
@property (nonatomic, weak) IBOutlet CtTextField *outletFreqLeftText;
@property (nonatomic, weak) IBOutlet CtTextField *outletFreqRightText;
@property (nonatomic, weak) IBOutlet CtTextField *outletPhaseText;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletPreset;
@property (nonatomic, weak) IBOutlet CtButton *outletSetPreset;
@property (nonatomic, weak) IBOutlet CtButton *outletPhase0;

@end

#define MIN_POS 0
#define MAX_POS 300

struct FreqRange {
	int nMinFreq;
	int nMaxFreq;
} tFreqRange[] = {
	{10, 20000},
	{10, 100},
	{100, 1000},
	{1000, 10000},
	{10000, 100000}
};

@implementation SgToneController
{
    int _nMinFreq;
    int _nMaxFreq;
    int _nFreqRange;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	[self setFreqRange:NO];

	self.outletFreqLeftText.floatValue = g_oSetData.Sg.fFreqL;
	self.outletFreqLeft.value = [self calcSliderPos:g_oSetData.Sg.fFreqL];

	self.outletFreqRightText.floatValue = g_oSetData.Sg.fFreqR;
	self.outletFreqRight.value = [self calcSliderPos:g_oSetData.Sg.fFreqR];

	self.outletFreqLink.checked = g_oSetData.Sg.bRendouF;

	[self setPhaseRange];

	self.outletPhaseText.intValue = g_oSetData.Sg.nPhase;
	self.outletphase.value = (g_oSetData.Sg.nPhase + 180) / 5;

	[self enablePhase];

	SetWaveFormList(self.outletWaveForm, g_oSetData.Sg.nToneWave);

	[self dispAllPresetFreq];
}

- (void)setFreqRange:(BOOL)bSetSlider
{
	NSString *str;

	int nMaxFreq = (int)(g_oSetData.Sg.nSampleRate / 2);

	tFreqRange[0].nMaxFreq = nMaxFreq;

	if (nMaxFreq > 10000) {
		_nFreqRange = 5;
		//		tFreqRange[4].nMaxFreq = nMaxFreq;
	} else {
		_nFreqRange = 4;
		//		tFreqRange[3].nMaxFreq = nMaxFreq;
	}

	[self.outletFreqRange resetContent];
	for (int i = 0; i < _nFreqRange; i++) {
		str = [NSString stringWithFormat:@"%@Hz-%@Hz", GetNumberString(tFreqRange[i].nMinFreq), GetNumberString(tFreqRange[i].nMaxFreq)];
		[self.outletFreqRange addItem:str :0];
	}

	if (g_oSetData.Sg.nFreqRange >= _nFreqRange)
		g_oSetData.Sg.nFreqRange = 0;
	self.outletFreqRange.selectedIndex = g_oSetData.Sg.nFreqRange;

	[self setFreqScale];

	if (bSetSlider) {
		[self setLFreq:self.outletFreqLeftText.floatValue];
		[self setRFreq:self.outletFreqRightText.floatValue];
	}
}

- (void)setPhaseRange
{
	NSString *str;

	for (int i = 0, nTic = 0; i <= 360; i += 45, nTic++) {
		str = nil;
		if (i % 90 == 0) {
			str = [NSString stringWithFormat:@"%d", i - 180];
		}
		[self.outletphase addTic:i / 5 :str];
	}
}

- (void)enablePhase
{
	BOOL bEnable = (g_oSetData.Sg.fFreqL == g_oSetData.Sg.fFreqR);

	self.outletphase.enabled = bEnable;
	self.outletPhaseText.enabled = bEnable;
	self.outletPhase0.enabled = bEnable;
}

- (void)dispAllPresetFreq
{
	for (int i = 0; i < N_SG_PRESET; i++)
		[self dispPresetFreq:i];
}

- (void)dispPresetFreq:(int)nPresetNo
{
	NSString *str;

	str = GetNumberString([self getPreset:nPresetNo]);

	[self.outletPreset setTitle:str forSegmentAtIndex:nPresetNo];
}

- (void)setFreqScale
{
	int	nFreq;
	int pos;
	int nTic;
	NSString *str;

	_nMinFreq = tFreqRange[g_oSetData.Sg.nFreqRange].nMinFreq;
	_nMaxFreq = tFreqRange[g_oSetData.Sg.nFreqRange].nMaxFreq;

	[self.outletFreqRight clearTics];
	for (nFreq = _nMinFreq, nTic = 0; nFreq <= _nMaxFreq; nTic++) {
		pos = [self calcSliderPos:nFreq];

		str = nil;
		if (g_oSetData.Sg.nFreqRange == 0) {
			if (nTic % 9 == 0)
				str = GetNumberString(nFreq);
		} else {
			if (nTic == 0 || nTic == 1 || nTic == 4 || nTic == 9)
				str = GetNumberString(nFreq);
		}

		[self.outletFreqRight addTic:pos :str];

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

- (int)calcSliderPos:(float)fFreq
{
	if (fFreq < MIN_FREQ)
		fFreq = MIN_FREQ;
	else if (fFreq > _nMaxFreq)
		fFreq = _nMaxFreq;

	int nPos = (int)((log(fFreq) - log((float)_nMinFreq)) * MAX_POS / (log((float)_nMaxFreq) - log((float)_nMinFreq)) + 0.5);

	if (nPos < 0)
		nPos = 0;
	else if (nPos > MAX_POS)
		nPos = MAX_POS;

	return nPos;
}

- (float)calcFreq:(int)pos
{
	if (pos < MIN_POS)
		pos = MIN_POS;
	else if (pos > MAX_POS)
		pos = MAX_POS;

	return exp(log((float)_nMinFreq) + pos * (log((float)_nMaxFreq) - log((float)_nMinFreq)) / MAX_POS);
}

- (void)setLFreq:(float)fFreq
{
	[self setLFreq2:fFreq];
	if (g_oSetData.Sg.bRendouF)
		[self setRFreq2:fFreq];

	[self enablePhase];
}

- (void)setLFreq2:(float)fFreq
{
	if (fFreq < 0)
		fFreq = 0;
	else if (fFreq > _nMaxFreq)
		fFreq = _nMaxFreq;

	if (self.outletFreqLeftText.floatValue != fFreq)
		self.outletFreqLeftText.floatValue = fFreq;
	self.outletFreqLeft.value = [self calcSliderPos:fFreq];
	//m_cFreqLSpin.SetPos32((int)fFreq);
	g_oSetData.Sg.fFreqL = fFreq;
}

- (void)setRFreq:(float)fFreq
{
	[self setRFreq2:fFreq];
	if (g_oSetData.Sg.bRendouF)
		[self setLFreq2:fFreq];

	[self enablePhase];
}

- (void)setRFreq2:(float)fFreq
{
	if (fFreq < 0)
		fFreq = 0;
	else if (fFreq > _nMaxFreq)
		fFreq = _nMaxFreq;

	if (self.outletFreqRightText.floatValue != fFreq)
		self.outletFreqRightText.floatValue = fFreq;
	self.outletFreqRight.value = [self calcSliderPos:fFreq];
	//m_cFreqRSpin.SetPos32((int)fFreq);
	g_oSetData.Sg.fFreqR = fFreq;
}

- (void)setPhase:(int)nPhase
{
	if (nPhase < MIN_PHASE)
		nPhase = MIN_PHASE;
	else if (nPhase > MAX_PHASE)
		nPhase = MAX_PHASE;

	if (self.outletphase.value != nPhase)
		self.outletPhaseText.intValue = nPhase;
	self.outletphase.value = (nPhase + 180) / 5;
	g_oSetData.Sg.nPhase = nPhase;
}

- (void)setPresetFreq:(int)nPresetNo
{
	if (self.outletSetPreset.selected) {
		[self setPreset:nPresetNo :g_oSetData.Sg.fFreqL];
		[self dispPresetFreq:nPresetNo];
		self.outletSetPreset.selected = NO;
	} else {
		//GetOwner()->SendMessage(WM_SG_CHANGE, 0, 1);

		g_oSetData.Sg.fFreqL = [self getPreset:nPresetNo];
		self.outletFreqLeftText.floatValue = g_oSetData.Sg.fFreqL;
		self.outletFreqLeft.value = [self calcSliderPos:g_oSetData.Sg.fFreqL];

		g_oSetData.Sg.fFreqR = [self getPreset:nPresetNo];
		self.outletFreqRightText.floatValue = g_oSetData.Sg.fFreqR;
		self.outletFreqRight.value = [self calcSliderPos:g_oSetData.Sg.fFreqR];
	}
}

- (float)getPreset:(int)presetNo
{
	switch (presetNo) {
		case 0:
			return g_oSetData.Sg.fPresetFreq1;
		case 1:
			return g_oSetData.Sg.fPresetFreq2;
		case 2:
			return g_oSetData.Sg.fPresetFreq3;
		case 3:
			return g_oSetData.Sg.fPresetFreq4;
	}
	return 0;
}

- (void)setPreset:(int)presetNo :(float)freq
{
	switch (presetNo) {
		case 0:
			g_oSetData.Sg.fPresetFreq1 = freq;
			break;
		case 1:
			g_oSetData.Sg.fPresetFreq2 = freq;
			break;
		case 2:
			g_oSetData.Sg.fPresetFreq3 = freq;
			break;
		case 3:
			g_oSetData.Sg.fPresetFreq4 = freq;
			break;
	}
}

- (IBAction)changeFreqLeft:(CtSlider *)sender
{
	[self setLFreq:floor([self calcFreq:sender.value] * 10 + 0.5) / 10];
}

- (IBAction)changeFreqRight:(CtSlider *)sender
{
	[self setRFreq:floor([self calcFreq:sender.value] * 10 + 0.5) / 10];
}

- (IBAction)changeFreqLeftText
{
	[self setLFreq:self.outletFreqLeftText.floatValue];
}

- (IBAction)changeFreqRightText
{
	[self setRFreq:self.outletFreqRightText.floatValue];
}

- (IBAction)changePhase:(CtSlider *)sender
{
	[self setPhase:sender.value * 5 - 180];
}

- (IBAction)changePhaseText:(CtTextField *)sender
{
	[self setPhase:sender.intValue];
}

- (IBAction)changePreset:(UISegmentedControl *)sender
{
	[self setPresetFreq:(int)sender.selectedSegmentIndex];
}

- (IBAction)changeFreqLink:(CtCheckBox *)sender
{
	g_oSetData.Sg.bRendouF = sender.checked;
}

- (IBAction)changeFreqRange:(CtComboBox *)sender
{
	g_oSetData.Sg.nFreqRange = sender.selectedIndex;
	[self setFreqScale];

	self.outletFreqLeft.value = [self calcSliderPos:g_oSetData.Sg.fFreqL];
	self.outletFreqRight.value = [self calcSliderPos:g_oSetData.Sg.fFreqR];
}

- (IBAction)changeWaveForm:(CtComboBox *)sender
{
	g_oSetData.Sg.nToneWave = sender.selectedIndex;
}

- (IBAction)touchPhase0:(CtButton *)sender
{
	[self setPhase:0];
}

- (IBAction)touchSetPreset:(CtButton *)sender
{
	sender.selected = !sender.selected;
}

@end
