//
//  SgNoiseController.m
//  DSSF3
//
//  Created by 相沢伸一 on 2015/04/15.
//  Copyright (c) 2015年 YMEC. All rights reserved.
//

#import "SgNoiseController.h"
#import "Common.h"

static const int tMaxTimeRange[] = {10, 100, 1000};

@interface SgNoiseController ()

@property (nonatomic, weak) IBOutlet UISegmentedControl *outletNoiseType;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletNoiseMode;
@property (nonatomic, weak) IBOutlet CtSlider *outletTime;
@property (nonatomic, weak) IBOutlet CtTextField *outletTimeText;
@property (nonatomic, weak) IBOutlet CtButton *outletTime0;
@property (nonatomic, weak) IBOutlet CtComboBox *outletTimeRange;

@end

@implementation SgNoiseController

- (void)viewDidLoad {
    [super viewDidLoad];

	self.outletNoiseType.selectedSegmentIndex = g_oSetData.Sg.nNoiseType;
	self.outletNoiseMode.selectedSegmentIndex = g_oSetData.Sg.nNoiseMode;

	NSString *str;
	for (int i = 0; i < sizeof(tMaxTimeRange) / sizeof(int); i++) {
		str = [NSString stringWithFormat:@"%d ms", tMaxTimeRange[i]];
		[self.outletTimeRange addItem:str :0];
	}
	self.outletTimeRange.selectedIndex = g_oSetData.Sg.nTimeRange;

	[self setTimeDiffRange];

	[self setTimeDiff:g_oSetData.Sg.fTimeDiff];

	[self enableTimeDiff];

	//m_cTimeValue.SetValidChar(VC_NUM | VC_MINUS | VC_POINT);
	
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)setTimeDiffRange
{
	int i;
	NSString *str;
	int nTimeRange = tMaxTimeRange[g_oSetData.Sg.nTimeRange];

	[self.outletTime clearTics];

	for (i = 0; i <= 20; i++) {
		if (i % 5 == 0)
			str = [NSString stringWithFormat:@"%d", (i - 10) * nTimeRange / 10];
		else
			str = nil;

		[self.outletTime addTic:i * 10 :str];
	}
}

- (void)setTimeDiff:(float)fTime
{
	if (fTime < -tMaxTimeRange[g_oSetData.Sg.nTimeRange])
		fTime = -tMaxTimeRange[g_oSetData.Sg.nTimeRange];
	else if (fTime > tMaxTimeRange[g_oSetData.Sg.nTimeRange])
		fTime = tMaxTimeRange[g_oSetData.Sg.nTimeRange];

	self.outletTimeText.floatValue = fTime;
	int nPos = (int)((fTime + tMaxTimeRange[g_oSetData.Sg.nTimeRange]) / tMaxTimeRange[g_oSetData.Sg.nTimeRange] * 100 + 0.5);
	self.outletTime.value = nPos;
	//m_cTimeValueSpin.SetPos(nPos);
	g_oSetData.Sg.fTimeDiff = fTime;
}

- (void)enableTimeDiff
{
	BOOL bEnable = (g_oSetData.Sg.nNoiseMode != NOISE_MODE_STEREO);
	self.outletTimeRange.enabled = bEnable;
	self.outletTime.enabled = bEnable;
	self.outletTimeText.enabled = bEnable;
	self.outletTime0.enabled = bEnable;
}

- (IBAction)changeNoiseType:(UISegmentedControl *)sender
{
	if (g_oSetData.Sg.nNoiseType != sender.selectedSegmentIndex) {
		g_oSetData.Sg.nNoiseType = (int)sender.selectedSegmentIndex;
		//GetOwner()->SendMessage(WM_SG_CHANGE, 1, 0);
	}

}

- (IBAction)changeNoiseMode:(UISegmentedControl *)sender
{
	if (g_oSetData.Sg.nNoiseMode != sender.selectedSegmentIndex) {
		g_oSetData.Sg.nNoiseMode = (int)sender.selectedSegmentIndex;
		//GetOwner()->SendMessage(WM_SG_CHANGE, 1, 0);
		[self enableTimeDiff];
	}
}

- (IBAction)changeTime:(CtSlider *)sender
{
	[self setTimeDiff:(self.outletTime.value - 100) * tMaxTimeRange[g_oSetData.Sg.nTimeRange] / 100.0];
}

- (IBAction)changeTimeText:(CtTextField *)sender
{
	[self setTimeDiff:self.outletTimeText.floatValue];
}

- (IBAction)touchTime0:(CtButton *)sender
{
	[self setTimeDiff:0];
}

- (IBAction)changeTimeRange:(CtComboBox *)sender
{
	int nOldTimeRange = g_oSetData.Sg.nTimeRange;

	g_oSetData.Sg.nTimeRange = self.outletTimeRange.selectedIndex;

	[self setTimeDiffRange];

	[self setTimeDiff:g_oSetData.Sg.fTimeDiff / tMaxTimeRange[nOldTimeRange] * tMaxTimeRange[g_oSetData.Sg.nTimeRange]];
}

@end
