//
//  SgPulseController.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/04/16.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "SgPulseController.h"
#import "Common.h"

@interface SgPulseController ()

@property (nonatomic, weak) IBOutlet CtComboBox *outletPulseWidth;
@property (nonatomic, weak) IBOutlet CtTextField *outletPulseNum;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletPulseContinue;
@property (nonatomic, weak) IBOutlet CtTextField *outletPulseCycle;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletPulsePolarity;

@end

@implementation SgPulseController

- (void)viewDidLoad {
    [super viewDidLoad];

	[self setPulseWidth];

	self.outletPulsePolarity.selectedSegmentIndex = g_oSetData.Sg.nPulsePolarity;
	self.outletPulseNum.intValue = g_oSetData.Sg.nPulseNum;
	self.outletPulseContinue.checked = g_oSetData.Sg.bPulseContinue;
	self.outletPulseCycle.floatValue = g_oSetData.Sg.fPulseCycle;

	self.outletPulseNum.enabled = !g_oSetData.Sg.bPulseContinue;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)setPulseWidth
{
	float t;
	int i;
	NSString *str;

	t = 1000.0 / g_oSetData.Sg.nSampleRate;

	[self.outletPulseWidth resetContent];
	for (i = 1; i < 50; i++) {
		str = [NSString stringWithFormat:@"%.3f", t * i];
		[self.outletPulseWidth addItem:str :0];
	}
	self.outletPulseWidth.selectedIndex = g_oSetData.Sg.nPulseWidth;
}

- (IBAction)changePulseWidth:(CtComboBox *)sender
{
	g_oSetData.Sg.nPulseWidth = sender.selectedIndex;
}

- (IBAction)changePulsePolarity:(UISegmentedControl *)sender
{
	g_oSetData.Sg.nPulsePolarity = (int)sender.selectedSegmentIndex;
}

- (IBAction)changeChangePulseNum:(CtTextField *)sender
{
	g_oSetData.Sg.nPulseNum = sender.intValue;
}

- (IBAction)changePulseContinue:(CtCheckBox *)sender
{
	g_oSetData.Sg.bPulseContinue = self.outletPulseContinue.checked;
	self.outletPulseNum.enabled = !g_oSetData.Sg.bPulseContinue;
}

- (IBAction)changeChangePulseCycle:(CtTextField *)sender
{
	g_oSetData.Sg.fPulseCycle = self.outletPulseCycle.floatValue;
}

@end
