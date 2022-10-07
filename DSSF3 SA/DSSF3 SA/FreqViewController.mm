//
//  FreqViewController.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/13.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "FreqViewController.h"
#import "Calc.h"
#import "Controls.h"

#define COLOR_LEFT			RGB(0, 128, 255)
#define COLOR_RIGHT			RGB(255, 64, 192)

@interface FreqViewController ()

@property (nonatomic, weak) IBOutlet FreqView *outletFreqLeft;
@property (nonatomic, weak) IBOutlet FreqView *outletFreqRight;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletMean;

@end

@implementation FreqViewController
{
    BOOL _bMean;
    float *_pFreqLeft;
    float *_pFreqRight;
    int _nData;
    UIColor *_colorLeft;
    UIColor *_colorRight;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)initialize
{
	_colorLeft = [[UIColor alloc] COLOR_LEFT];
	_colorRight = [[UIColor alloc] COLOR_RIGHT];
	self.outletMean.checked = YES;

	NSString *str;
	if (_pDbImpulseRec->nChannel == 1) {
		str = NSLocalizedString(@"IDS_SPECTRUM", nil);
		[self.outletFreqLeft initialize:str :1 :_colorLeft :17.0];
	} else {
		str = NSLocalizedString(@"IDS_LEFTCHANNEL", nil);
		[self.outletFreqLeft initialize:str :1 :_colorLeft :17.0];
		str = NSLocalizedString(@"IDS_RIGHTCHANNEL", nil);
		[self.outletFreqRight initialize:str :1 :_colorRight :17.0];
	}

	_nData = 1 << _pDbImpulseRec->nMeasTime;

	[self allocBuffer];

	self.outletFreqLeft.enabled = YES;
	if (_pDbImpulseRec->nChannel == 2)
		self.outletFreqRight.enabled = YES;
}

- (void)viewDidLayoutSubviews
{
	[self dispFreqWindow:YES];
}

- (void)dispFreqWindow:(BOOL)bCalc
{
	if (bCalc) {
		CalcPowerSpectrum(_pWaveLeft, _pWaveRight, _pFreqLeft, _pFreqRight, _nData);
		for (int i = 0; i < _nData; i++) {
			_pFreqLeft[i] /= _nData;
			if (_pDbImpulseRec->nChannel == 2)
				_pFreqRight[i] /= _nData;
		}
	}

	[self.outletFreqLeft setNeedsDisplay];
	if (_pDbImpulseRec->nChannel == 2)
		[self.outletFreqRight setNeedsDisplay];
}

- (void)drawGraphData:(CGContextRef)context :(id)sender
{
	_bMean = self.outletMean.checked;

	if (sender == self.outletFreqLeft)
		[self.outletFreqLeft dispGraph:context :_pFreqLeft :_nData :_fRate :10 :(int)(_fRate / 2) :-140 :0 :_bMean];
	else if (sender == self.outletFreqRight)
		[self.outletFreqRight dispGraph:context :_pFreqRight :_nData :_fRate :10 :(int)(_fRate / 2) :-140 :0 :_bMean];
}

- (void)dealloc
{
	[self freeBuffer];
}

- (void)allocBuffer
{
	[self freeBuffer];

	_pFreqLeft = new float[_nData];
	_pFreqRight = new float[_nData];
}

- (void)freeBuffer
{
	if (_pFreqLeft != NULL) {
		delete [] _pFreqLeft;
		_pFreqLeft = NULL;
	}

	if (_pFreqRight != NULL) {
		delete [] _pFreqRight;
		_pFreqRight = NULL;
	}
}

- (void)redraw
{
	[self dispFreqWindow:YES];
}

- (IBAction)onChangeMean:(id)sender
{
	[self dispFreqWindow:NO];
}

@end
