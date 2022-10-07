//
//  SgSweepController.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/04/15.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "SgSweepController.h"
#import "Common.h"

@interface SgSweepController ()

@property (nonatomic, weak) IBOutlet CtTextField *outletStartFreq;
@property (nonatomic, weak) IBOutlet CtTextField *outletEndFreq;
@property (nonatomic, weak) IBOutlet CtTextField *outletStartLevel;
@property (nonatomic, weak) IBOutlet CtTextField *outletEndLevel;
@property (nonatomic, weak) IBOutlet CtTextField *outletSweepTime;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletLoop;
@property (nonatomic, weak) IBOutlet CtComboBox *outletWaveForm;

@end

@implementation SgSweepController

- (void)viewDidLoad {
    [super viewDidLoad];

	self.outletStartFreq.floatValue = g_oSetData.Sg.fStartFreq;
	self.outletEndFreq.floatValue = g_oSetData.Sg.fEndFreq;
	self.outletStartLevel.floatValue = g_oSetData.Sg.fStartLevel;
	self.outletEndLevel.floatValue = g_oSetData.Sg.fEndLevel;
	self.outletSweepTime.floatValue = g_oSetData.Sg.fSweepTime;
	self.outletLoop.checked = g_oSetData.Sg.bSweepLoop;

	SetWaveFormList(self.outletWaveForm, g_oSetData.Sg.nSweepWave);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)changeStartFreq:(CtTextField *)sender
{
	g_oSetData.Sg.fStartFreq = self.outletStartFreq.floatValue;
}

- (IBAction)changeEndFreq:(CtTextField *)sender
{
	g_oSetData.Sg.fEndFreq = self.outletEndFreq.floatValue;
}

- (IBAction)changeStartLevel:(CtTextField *)sender
{
	g_oSetData.Sg.fStartLevel = self.outletStartLevel.floatValue;
}

- (IBAction)changeEndLevel:(CtTextField *)sender
{
	g_oSetData.Sg.fEndLevel = self.outletEndLevel.floatValue;
}

- (IBAction)changeSweepSpeed:(CtTextField *)sender
{
	g_oSetData.Sg.fSweepTime = self.outletSweepTime.floatValue;
}

- (IBAction)changeLoop:(CtCheckBox *)sender
{
	g_oSetData.Sg.bSweepLoop = self.outletLoop.checked;
}

- (IBAction)changeWaveForm:(CtComboBox *)sender
{
	g_oSetData.Sg.nSweepWave = self.outletWaveForm.selectedIndex;
}

@end
