//
//  SgScaleController.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/04/17.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "SgScaleController.h"
#import "SgViewController.h"
#import "Common.h"
#import "KeyboardView.h"

@interface SgScaleController ()

@property (nonatomic, weak) IBOutlet KeyboardView *outletKeyboard;
@property (nonatomic, weak) IBOutlet CtButton *outletScaleC;
@property (nonatomic, weak) IBOutlet CtButton *outletScaleCs;
@property (nonatomic, weak) IBOutlet CtButton *outletScaleD;
@property (nonatomic, weak) IBOutlet CtButton *outletScaleDs;
@property (nonatomic, weak) IBOutlet CtButton *outletScaleE;
@property (nonatomic, weak) IBOutlet CtButton *outletScaleF;
@property (nonatomic, weak) IBOutlet CtButton *outletScaleFs;
@property (nonatomic, weak) IBOutlet CtButton *outletScaleG;
@property (nonatomic, weak) IBOutlet CtButton *outletScaleGs;
@property (nonatomic, weak) IBOutlet CtButton *outletScaleA;
@property (nonatomic, weak) IBOutlet CtButton *outletScaleAs;
@property (nonatomic, weak) IBOutlet CtButton *outletScaleB;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletPlayMode;
@property (nonatomic, weak) IBOutlet CtComboBox *outletWaveForm;
@property (nonatomic, weak) IBOutlet CtTextField *outletReferencePitch;
@property (nonatomic, weak) IBOutlet CtTextField *outletFreq;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletOctave;

@end

@implementation SgScaleController

- (void)viewDidLoad {
    [super viewDidLoad];

	self.outletReferencePitch.floatValue = g_oSetData.Sg.fReferencePitch;

	SetWaveFormList(self.outletWaveForm, g_oSetData.Sg.nScaleWave);

	self.outletPlayMode.checked = g_oSetData.Sg.bPlayMode;

	[self getScale:g_oSetData.Sg.nScale].selected = YES;
	self.outletOctave.selectedSegmentIndex = g_oSetData.Sg.nOctave;

	[self.outletKeyboard setMarker:g_oSetData.Sg.nOctave :g_oSetData.Sg.nScale];

	[self dispFreq];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (CtButton *)getScale:(int)scale
{
	switch (scale) {
		case 0:
			return self.outletScaleC;
		case 1:
			return self.outletScaleCs;
		case 2:
			return self.outletScaleD;
		case 3:
			return self.outletScaleDs;
		case 4:
			return self.outletScaleE;
		case 5:
			return self.outletScaleF;
		case 6:
			return self.outletScaleFs;
		case 7:
			return self.outletScaleG;
		case 8:
			return self.outletScaleGs;
		case 9:
			return self.outletScaleA;
		case 10:
			return self.outletScaleAs;
		case 11:
			return self.outletScaleB;
	}
	return nil;
}

- (void)dispFreq
{
	int nPitch = (g_oSetData.Sg.nOctave - 4) * 12 + (g_oSetData.Sg.nScale - 9);
	float fFreq = g_oSetData.Sg.fReferencePitch * pow(2.0, (float)nPitch / 12);

	NSString *str = [NSString stringWithFormat:@"%.1f", fFreq];
	self.outletFreq.text = str;
}

- (void)setScale:(int)nScale
{
	for (int i = 0; i < 12; i++)
		[self getScale:i].selected = NO;
	[self getScale:nScale].selected = YES;
	
	g_oSetData.Sg.nScale = nScale;
	[self.outletKeyboard setMarker:g_oSetData.Sg.nOctave :g_oSetData.Sg.nScale];
	[self dispFreq];
}

- (void)setOctave:(int)nOctave
{
	g_oSetData.Sg.nOctave = nOctave;
	[self.outletKeyboard setMarker:g_oSetData.Sg.nOctave :g_oSetData.Sg.nScale];
	[self dispFreq];
}

- (IBAction)changeKeyboard:(KeyboardView *)sender
{
	if (sender.touchKey != 0 || sender.touchOctave != 0) {
		if (g_oSetData.Sg.nOctave != sender.touchOctave) {
			self.outletOctave.selectedSegmentIndex = sender.touchOctave;

			[self setOctave:(int)self.outletOctave.selectedSegmentIndex];
		}

		if (g_oSetData.Sg.nScale != sender.touchKey) {
			[self setScale:sender.touchKey];
		}
	}

	if (g_oSetData.Sg.bPlayMode) {
		SgViewController *viewController = (SgViewController *)self.parentViewController;
		if (sender.touchKey != 0 || sender.touchOctave != 0)
			[viewController start];
		else
			[viewController stop];
	}
}

- (IBAction)touchScale:(CtButton *)sender
{
	[self setScale:(int)sender.tag];
}

- (IBAction)changeReferencePitch:(CtTextField *)sender
{
	g_oSetData.Sg.fReferencePitch = sender.floatValue;
	[self dispFreq];
}

- (IBAction)changeOctave:(UISegmentedControl *)sender
{
	[self setOctave:(int)sender.selectedSegmentIndex];
}

- (IBAction)changeWaveForm:(CtComboBox *)sender
{
	g_oSetData.Sg.nScaleWave = sender.selectedIndex;
}

- (IBAction)changePlayMode:(CtCheckBox *)sender
{
	g_oSetData.Sg.bPlayMode = sender.checked;
}

@end
