//
//  MtfViewController.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/13.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "MtfViewController.h"
#import "Calc.h"
#import "Controls.h"

#define COLOR_LEFT			RGB(0, 128, 255)
#define COLOR_RIGHT			RGB(255, 64, 192)

@interface MtfViewController ()

@property (nonatomic, weak) IBOutlet MtfView *outletMtfLeft;
@property (nonatomic, weak) IBOutlet MtfView *outletMtfRight;
@property (nonatomic, weak) IBOutlet CtTextField *outletSTIL;
@property (nonatomic, weak) IBOutlet CtTextField *outletSTIR;
@property (nonatomic, weak) IBOutlet CtTextField *outletSTIML;
@property (nonatomic, weak) IBOutlet CtTextField *outletSTIMR;
@property (nonatomic, weak) IBOutlet CtTextField *outletSTIFL;
@property (nonatomic, weak) IBOutlet CtTextField *outletSTIFR;
@property (nonatomic, weak) IBOutlet CtTextField *outletRASTIL;
@property (nonatomic, weak) IBOutlet CtTextField *outletRASTIR;

@end

@implementation MtfViewController
{
    float *_pMtfLeft;
    float *_pMtfRight;
}

- (void)initialize
{
	UIColor *colorLeft = [[UIColor alloc] COLOR_LEFT];
	UIColor *colorRight = [[UIColor alloc] COLOR_RIGHT];

	NSString *str;
	if (_pDbImpulseRec->nChannel == 1) {
		[self.outletMtfLeft initialize:NULL :1 :colorLeft];
	} else {
		str = NSLocalizedString(@"IDS_LEFTCHANNEL", nil);
		[self.outletMtfLeft initialize:str :1 :colorLeft];
		str = NSLocalizedString(@"IDS_RIGHTCHANNEL", nil);
		[self.outletMtfRight initialize:str :1 :colorRight];
	}

	[self allocBuffer];

	self.outletMtfLeft.enabled = YES;
	if (_pDbImpulseRec->nChannel == 2)
		self.outletMtfRight.enabled = YES;
}

- (void)viewDidLayoutSubviews
{
	[self dispGraphWindow];
}

- (void)dealloc
{
	[self freeBuffer];
}

- (void)allocBuffer
{
	[self freeBuffer];

	_pMtfLeft = new float[N_MTF_FREQ];
	_pMtfRight = new float[N_MTF_FREQ];
}

- (void)freeBuffer
{
	if (_pMtfLeft != NULL) {
		delete [] _pMtfLeft;
		_pMtfLeft = NULL;
	}

	if (_pMtfRight != NULL) {
		delete [] _pMtfRight;
		_pMtfRight = NULL;
	}
}

- (void)dispGraphWindow
{
	CalcMTF(_pIRLeft, _nData, _fRate, g_tMtfFreq, N_MTF_FREQ, _pMtfLeft, FALSE, 0);
	[self.outletMtfLeft setNeedsDisplay];

	[self.outletSTIL setFloatValue:_pDbAcParamResult->fSTI_L decimalPosition:3];
	[self.outletSTIML setFloatValue:_pDbAcParamResult->fSTIM_L decimalPosition:3];
	[self.outletSTIFL setFloatValue:_pDbAcParamResult->fSTIF_L decimalPosition:3];
	[self.outletRASTIL setFloatValue:_pDbAcParamResult->fRASTI_L decimalPosition:3];

	if (_pDbImpulseRec->nChannel == 2) {
		CalcMTF(_pIRRight, _nData, _fRate, g_tMtfFreq, N_MTF_FREQ, _pMtfRight, FALSE, 0);
		[self.outletMtfRight setNeedsDisplay];

		[self.outletSTIR setFloatValue:_pDbAcParamResult->fSTI_R decimalPosition:3];
		[self.outletSTIMR setFloatValue:_pDbAcParamResult->fSTIM_R decimalPosition:3];
		[self.outletSTIFR setFloatValue:_pDbAcParamResult->fSTIF_R decimalPosition:3];
		[self.outletRASTIR setFloatValue:_pDbAcParamResult->fRASTI_R decimalPosition:3];
	}
}

- (void)drawGraphData:(CGContextRef)context :(id)sender
{
	if (sender == self.outletMtfLeft)
		[self.outletMtfLeft dispGraph:context :_pMtfLeft :g_tMtfFreq];
	else if (sender == self.outletMtfRight)
		[self.outletMtfRight dispGraph:context :_pMtfRight :g_tMtfFreq];
}

- (void)redraw
{

}

@end
