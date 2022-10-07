//
//  IACCViewController.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/07.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "IACCViewController.h"
#import "Calc.h"
#import "SetData.h"
#import "UIViewController+MJPopupViewController.h"
#import "CalcIACCViewController.h"
#import "GraphViewController.h"
#import "Controls.h"

@interface IACCViewController ()

@property (nonatomic, weak) IBOutlet IACCView	*outletGraphIACC;
@property (nonatomic, weak) IBOutlet CtButton	*outletChangeWIACC;

@end

@implementation IACCViewController
{
    int _nData;
    float *_pIACCData;
    int _nIACCData;
    Float64 _fIACC, _TIACC, _WIACC, _WIACC1, _WIACC2;
    CalcIACCViewController *_calcIACCViewController;
}

- (void)viewDidLayoutSubviews
{
	[self dispIACCWindow:YES];
}

- (void)dealloc
{
	[self freeBuffer];
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
	NSString *str;

	str = NSLocalizedString(@"IDS_CCF", nil);
	[self.outletGraphIACC initialize:str :4];

	_nData = 1 << _pDbImpulseRec->nMeasTime;
	_nIACCData = (int)(_fRate / 500);
	_nIACCData += _nIACCData - 1;

	[self allocBuffer];

	self.outletGraphIACC.enabled = YES;
	self.outletChangeWIACC.enabled = _pDbAcParamRec != NULL;
}

- (void)allocBuffer
{
	[self freeBuffer];

	_pIACCData = new float[_nIACCData];
}

- (void)freeBuffer
{
	if (_pIACCData != NULL) {
		delete [] _pIACCData;
		_pIACCData = NULL;
	}
}

- (void)drawGraphData:(CGContextRef)context :(id)sender
{
	[self.outletGraphIACC dispGraph:context :_pIACCData :_nIACCData :_fRate :_fIACC :_TIACC :_WIACC1 :_WIACC2];
}

- (void)redraw
{
	[self dispIACCWindow:YES];
}

- (void)dispIACCWindow:(BOOL)bCalc
{
	if (bCalc) {
		Float64 fWIACCLevel;

		CalcIACCData(_pIRLeft, _pIRRight, _nData, _pIACCData, _nIACCData);

		if (_pDbAcParamRec != NULL)
			fWIACCLevel = _pDbAcParamRec->dbAcParamCond.fWIACCLevel;
		else
			fWIACCLevel = setData.Imp.fWIACCLevel;
		CalcParamIACC(_pIACCData, _nIACCData, _fRate, &_fIACC, &_TIACC, &_WIACC, fWIACCLevel, &_WIACC1, &_WIACC2);
	}

	[self.outletGraphIACC setNeedsDisplay];
}

- (IBAction)onChangeWiacc:(id)sender
{
	_calcIACCViewController = [[CalcIACCViewController alloc] initWithNibName:@"CalcIACC" bundle:nil];
	_calcIACCViewController.delegate = self;
	_calcIACCViewController.fWIACCLevel = _pDbAcParamRec->dbAcParamCond.fWIACCLevel;
	[self presentPopupViewController:_calcIACCViewController animationType:MJPopupViewAnimationFade enableBackground:YES];
}

- (void)onOK
{
	_pDbAcParamRec->dbAcParamCond.fWIACCLevel = _calcIACCViewController.fWIACCLevel;
	CalcTsub(_pDbImpulseRec, _hWaveData, _pDbAcParamRec, _fRate);
	[(GraphViewController *)self.parentViewController changeData];

	[self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
}

@end
