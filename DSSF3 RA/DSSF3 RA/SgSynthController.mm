//
//  SgSynthController.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/04/17.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "SgSynthController.h"
#import "Common.h"

#define MIN_POS 0
#define MAX_POS 300

@interface SgSynthController ()

@property (nonatomic, weak) IBOutlet CtComboBox *outletWaveForm;
@property (nonatomic, weak) IBOutlet CtSlider *outletFreqSlider;
@property (nonatomic, weak) IBOutlet CtTextField *outletSynthFreq;
@property (nonatomic, weak) IBOutlet CtTextField *outletCompFreq1;
@property (nonatomic, weak) IBOutlet CtTextField *outletCompFreq2;
@property (nonatomic, weak) IBOutlet CtTextField *outletCompFreq3;
@property (nonatomic, weak) IBOutlet CtTextField *outletCompFreq4;
@property (nonatomic, weak) IBOutlet CtTextField *outletCompFreq5;
@property (nonatomic, weak) IBOutlet CtTextField *outletCompFreq6;
@property (nonatomic, weak) IBOutlet CtTextField *outletCompFreq7;
@property (nonatomic, weak) IBOutlet CtTextField *outletCompFreq8;
@property (nonatomic, weak) IBOutlet CtTextField *outletCompLevel1;
@property (nonatomic, weak) IBOutlet CtTextField *outletCompLevel2;
@property (nonatomic, weak) IBOutlet CtTextField *outletCompLevel3;
@property (nonatomic, weak) IBOutlet CtTextField *outletCompLevel4;
@property (nonatomic, weak) IBOutlet CtTextField *outletCompLevel5;
@property (nonatomic, weak) IBOutlet CtTextField *outletCompLevel6;
@property (nonatomic, weak) IBOutlet CtTextField *outletCompLevel7;
@property (nonatomic, weak) IBOutlet CtTextField *outletCompLevel8;
@property (nonatomic, weak) IBOutlet CtSlider *outletLevelSlider1;
@property (nonatomic, weak) IBOutlet CtSlider *outletLevelSlider2;
@property (nonatomic, weak) IBOutlet CtSlider *outletLevelSlider3;
@property (nonatomic, weak) IBOutlet CtSlider *outletLevelSlider4;
@property (nonatomic, weak) IBOutlet CtSlider *outletLevelSlider5;
@property (nonatomic, weak) IBOutlet CtSlider *outletLevelSlider6;
@property (nonatomic, weak) IBOutlet CtSlider *outletLevelSlider7;
@property (nonatomic, weak) IBOutlet CtSlider *outletLevelSlider8;

@end

@implementation SgSynthController

- (void)viewDidLoad {
    [super viewDidLoad];

	[self setFreqRange];
	[self setLevelScale];

	self.outletLevelSlider1.value = g_oSetData.Sg.nCompLevel1;
	self.outletCompFreq1.floatValue = g_oSetData.Sg.fCompFreq1;
	self.outletCompLevel1.intValue = g_oSetData.Sg.nCompLevel1;

	self.outletLevelSlider2.value = g_oSetData.Sg.nCompLevel2;
	self.outletCompFreq2.floatValue = g_oSetData.Sg.fCompFreq2;
	self.outletCompLevel2.intValue = g_oSetData.Sg.nCompLevel2;

	self.outletLevelSlider3.value = g_oSetData.Sg.nCompLevel3;
	self.outletCompFreq3.floatValue = g_oSetData.Sg.fCompFreq3;
	self.outletCompLevel3.intValue = g_oSetData.Sg.nCompLevel3;

	self.outletLevelSlider4.value = g_oSetData.Sg.nCompLevel4;
	self.outletCompFreq4.floatValue = g_oSetData.Sg.fCompFreq4;
	self.outletCompLevel4.intValue = g_oSetData.Sg.nCompLevel4;

	self.outletLevelSlider5.value = g_oSetData.Sg.nCompLevel5;
	self.outletCompFreq5.floatValue = g_oSetData.Sg.fCompFreq5;
	self.outletCompLevel5.intValue = g_oSetData.Sg.nCompLevel5;

	self.outletLevelSlider6.value = g_oSetData.Sg.nCompLevel6;
	self.outletCompFreq6.floatValue = g_oSetData.Sg.fCompFreq6;
	self.outletCompLevel6.intValue = g_oSetData.Sg.nCompLevel6;

	self.outletLevelSlider7.value = g_oSetData.Sg.nCompLevel7;
	self.outletCompFreq7.floatValue = g_oSetData.Sg.fCompFreq7;
	self.outletCompLevel7.intValue = g_oSetData.Sg.nCompLevel7;

	self.outletLevelSlider8.value = g_oSetData.Sg.nCompLevel8;
	self.outletCompFreq8.floatValue = g_oSetData.Sg.fCompFreq8;
	self.outletCompLevel8.intValue = g_oSetData.Sg.nCompLevel8;

	self.outletFreqSlider.value = [self calcSliderPos:g_oSetData.Sg.fSynthFreq];

	self.outletSynthFreq.floatValue = g_oSetData.Sg.fSynthFreq;

	SetWaveFormList(self.outletWaveForm, g_oSetData.Sg.nSynthWave);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)setFreqRange
{
	int	nFreq;
	int pos;
	int nTic;
	NSString *str;

	[self.outletFreqSlider clearTics];
	for (nFreq = (int)MIN_FREQ, nTic = 0; nFreq <= (int)MAX_FREQ; nTic++) {
		pos = [self calcSliderPos:nFreq];

		if (nTic % 9 == 0)
			str = GetNumberString(nFreq);
		else
			str = nil;

		[self.outletFreqSlider addTic:pos :str];

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

- (void)setLevelScale
{
	[self.outletLevelSlider1 addTic:0 :@"0"];
	[self.outletLevelSlider1 addTic:25 :nil];
	[self.outletLevelSlider1 addTic:50 :@"50"];
	[self.outletLevelSlider1 addTic:75 :nil];
	[self.outletLevelSlider1 addTic:100 :@"100"];
}

- (int)calcSliderPos:(float)fFreq
{
	if (fFreq < MIN_FREQ)
		fFreq = MIN_FREQ;
	else if (fFreq > MAX_FREQ)
		fFreq = MAX_FREQ;

	int nPos = (int)((log(fFreq) - log(MIN_FREQ)) * MAX_POS / (log(MAX_FREQ) - log(MIN_FREQ)) + 0.5);

	if (nPos < 0)
		nPos = 0;
	else if (nPos > MAX_POS)
		nPos = MAX_POS;

	return nPos;
}

- (void)setSynthFreq:(float)fFreq
{
	if (fFreq < 0)
		fFreq = 0;
	else if (fFreq > MAX_FREQ)
		fFreq = MAX_FREQ;

	if (self.outletSynthFreq.floatValue != fFreq)
		self.outletSynthFreq.floatValue = fFreq;
	self.outletFreqSlider.value = [self calcSliderPos:fFreq];
	g_oSetData.Sg.fSynthFreq = fFreq;
}

- (float)calcFreq:(int)pos
{
	if (pos < MIN_POS)
		pos = MIN_POS;
	else if (pos > MAX_POS)
		pos = MAX_POS;

	return exp(log(MIN_FREQ) + pos * (log(MAX_FREQ) - log(MIN_FREQ)) / MAX_POS);
}

- (IBAction)compFreq1:(CtTextField *)sender
{
	g_oSetData.Sg.fCompFreq1 = sender.floatValue;
}

- (IBAction)compFreq2:(CtTextField *)sender
{
	g_oSetData.Sg.fCompFreq2 = sender.floatValue;
}

- (IBAction)compFreq3:(CtTextField *)sender
{
	g_oSetData.Sg.fCompFreq3 = sender.floatValue;
}

- (IBAction)compFreq4:(CtTextField *)sender
{
	g_oSetData.Sg.fCompFreq4 = sender.floatValue;
}

- (IBAction)compFreq5:(CtTextField *)sender
{
	g_oSetData.Sg.fCompFreq5 = sender.floatValue;
}

- (IBAction)compFreq6:(CtTextField *)sender
{
	g_oSetData.Sg.fCompFreq6 = sender.floatValue;
}

- (IBAction)compFreq7:(CtTextField *)sender
{
	g_oSetData.Sg.fCompFreq7 = sender.floatValue;
}

- (IBAction)compFreq8:(CtTextField *)sender
{
	g_oSetData.Sg.fCompFreq8 = sender.floatValue;
}

- (IBAction)compLevel1:(CtTextField *)sender
{
	if (self.outletCompLevel1.intValue > 100)
		self.outletCompLevel1.intValue = 100;

	g_oSetData.Sg.nCompLevel1 = self.outletCompLevel1.intValue;
	self.outletLevelSlider1.value = g_oSetData.Sg.nCompLevel1;
}

- (IBAction)compLevel2:(CtTextField *)sender
{
	if (self.outletCompLevel2.intValue > 100)
		self.outletCompLevel2.intValue = 100;

	g_oSetData.Sg.nCompLevel2 = self.outletCompLevel2.intValue;
	self.outletLevelSlider2.value = g_oSetData.Sg.nCompLevel2;
}

- (IBAction)compLevel3:(CtTextField *)sender
{
	if (self.outletCompLevel3.intValue > 100)
		self.outletCompLevel3.intValue = 100;

	g_oSetData.Sg.nCompLevel3 = self.outletCompLevel3.intValue;
	self.outletLevelSlider3.value = g_oSetData.Sg.nCompLevel3;
}

- (IBAction)compLevel4:(CtTextField *)sender
{
	if (self.outletCompLevel4.intValue > 100)
		self.outletCompLevel4.intValue = 100;

	g_oSetData.Sg.nCompLevel4 = self.outletCompLevel4.intValue;
	self.outletLevelSlider4.value = g_oSetData.Sg.nCompLevel4;
}

- (IBAction)compLevel5:(CtTextField *)sender
{
	if (self.outletCompLevel5.intValue > 100)
		self.outletCompLevel5.intValue = 100;

	g_oSetData.Sg.nCompLevel5 = self.outletCompLevel5.intValue;
	self.outletLevelSlider5.value = g_oSetData.Sg.nCompLevel5;
}

- (IBAction)compLevel6:(CtTextField *)sender
{
	if (self.outletCompLevel6.intValue > 100)
		self.outletCompLevel6.intValue = 100;

	g_oSetData.Sg.nCompLevel6 = self.outletCompLevel6.intValue;
	self.outletLevelSlider6.value = g_oSetData.Sg.nCompLevel6;
}

- (IBAction)compLevel7:(CtTextField *)sender
{
	if (self.outletCompLevel7.intValue > 100)
		self.outletCompLevel7.intValue = 100;

	g_oSetData.Sg.nCompLevel7 = self.outletCompLevel7.intValue;
	self.outletLevelSlider7.value = g_oSetData.Sg.nCompLevel7;
}

- (IBAction)compLevel8:(CtTextField *)sender
{
	if (self.outletCompLevel8.intValue > 100)
		self.outletCompLevel8.intValue = 100;

	g_oSetData.Sg.nCompLevel8 = self.outletCompLevel8.intValue;
	self.outletLevelSlider8.value = g_oSetData.Sg.nCompLevel8;
}

- (IBAction)changeSynthFreq:(CtSlider *)sender
{
	[self setSynthFreq:floor([self calcFreq:sender.value] + 0.5)];
}

- (IBAction)changeLevelSlider1:(CtSlider *)sender
{
	g_oSetData.Sg.nCompLevel1 = sender.value;
	self.outletCompLevel1.intValue = g_oSetData.Sg.nCompLevel1;
}

- (IBAction)changeLevelSlider2:(CtSlider *)sender
{
	g_oSetData.Sg.nCompLevel2 = sender.value;
	self.outletCompLevel2.intValue = g_oSetData.Sg.nCompLevel2;
}

- (IBAction)changeLevelSlider3:(CtSlider *)sender
{
	g_oSetData.Sg.nCompLevel3 = sender.value;
	self.outletCompLevel3.intValue = g_oSetData.Sg.nCompLevel3;
}

- (IBAction)changeLevelSlider4:(CtSlider *)sender
{
	g_oSetData.Sg.nCompLevel4 = sender.value;
	self.outletCompLevel4.intValue = g_oSetData.Sg.nCompLevel4;
}

- (IBAction)changeLevelSlider5:(CtSlider *)sender
{
	g_oSetData.Sg.nCompLevel5 = sender.value;
	self.outletCompLevel5.intValue = g_oSetData.Sg.nCompLevel5;
}

- (IBAction)changeLevelSlider6:(CtSlider *)sender
{
	g_oSetData.Sg.nCompLevel6 = sender.value;
	self.outletCompLevel6.intValue = g_oSetData.Sg.nCompLevel6;
}

- (IBAction)changeLevelSlider7:(CtSlider *)sender
{
	g_oSetData.Sg.nCompLevel7 = sender.value;
	self.outletCompLevel7.intValue = g_oSetData.Sg.nCompLevel7;
}

- (IBAction)changeLevelSlider8:(CtSlider *)sender
{
	g_oSetData.Sg.nCompLevel8 = sender.value;
	self.outletCompLevel8.intValue = g_oSetData.Sg.nCompLevel8;
}

- (IBAction)changeWaveForm:(CtComboBox *)sender
{
	g_oSetData.Sg.nSynthWave = self.outletWaveForm.selectedIndex;
}

- (IBAction)changeChangeSynthFreq:(CtTextField *)sender
{
	[self setSynthFreq:self.outletSynthFreq.floatValue];
}

@end
