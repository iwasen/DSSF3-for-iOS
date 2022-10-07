//
//  EchoViewController.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/13.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "EchoViewController.h"
#import "Calc.h"
#import "SetData.h"
#import "Controls.h"
#import "UIViewController+MJPopupViewController.h"
#import "GraphViewController.h"

#define COLOR_LEFT			RGB(0, 128, 255)
#define COLOR_RIGHT			RGB(255, 64, 192)

#define SCROLL_RANGE 16384
#define MAX_ZOOM_TIME	512

@interface EchoViewController ()

@property (nonatomic, weak) IBOutlet ImpulseView *outletGraphIR;
@property (nonatomic, weak) IBOutlet EchoView *outletGraphEE;
@property (nonatomic, weak) IBOutlet EchoView *outletGraphEcho;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletLeftRight;
@property (nonatomic, weak) IBOutlet CtButton *outletCalculate;

@end

@implementation EchoViewController
{
    float *_pEchoTime;
    float *_pEchoEnergy;
    float *_pEchoData;
    float *_pEchoData2;
    float _fTotalTime;
    int _nScrollPos;
    int _nScrollSize;
    float _fT0;
    float _fT1;
    Float64 _fDev;
    float _fTsubNoise;
    float _fT20Reg0, _fT20Reg1;
    float _fT30Reg0, _fT30Reg1;
    float _fEDTReg0, _fEDTReg1;
    Float64 _fEndTime;
    UIColor *_colorLeft;
    CalcEchoViewController *_calcEchoViewController;
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

	_nScrollSize = -1;
	_nScrollPos = -1;
	_colorLeft = [[UIColor alloc] COLOR_LEFT];

	str = NSLocalizedString(@"IDS_ECHOTIMEPATTERN", nil);
	[self.outletGraphIR initialize:str :1 :_colorLeft];
	str = NSLocalizedString(@"IDS_DECAYCURVE", nil);
	[self.outletGraphEE initialize:str];
	str = NSLocalizedString(@"IDS_SCHROEDER", nil);
	[self.outletGraphEcho initialize:str];

	_fTotalTime = (float)_nData / _fRate;

	[self allocBuffer];

	self.outletGraphIR.enabled = YES;
	self.outletGraphEE.enabled = YES;
	self.outletGraphEcho.enabled = YES;

	if (_pDbImpulseRec->nChannel == 1) {
		self.outletLeftRight.enabled = NO;
	}

	self.outletCalculate.enabled = (_pDbAcParamRec != NULL);

	[self calcGraphWindow];
	[self dispGraphWindow];
}

- (void)viewDidLayoutSubviews
{
	[self dispGraphWindow];
}

- (void)calcGraphWindow
{
	float *p1, *p2;
	int i;

	switch (self.outletLeftRight.selectedSegmentIndex) {
		case 0:		// Left+Right
			p1 = _pIRLeft;
			p2 = _pIRRight;
			for (i = 0; i < _nData; i++)
				_pEchoTime[i] = _pIRLeft[i] + _pIRRight[i];
			break;
		case 1:		// Left
			p1 = _pIRLeft;
			p2 = NULL;
			memcpy(_pEchoTime, _pIRLeft, _nData * sizeof(float));
			break;
		case 2:		// Right
			p1 = _pIRRight;
			p2 = NULL;
			memcpy(_pEchoTime, _pIRRight, _nData * sizeof(float));
			break;
		default:
			return;
	}

	if (_pDbAcParamRec != NULL) {
		switch (self.outletLeftRight.selectedSegmentIndex) {
			case 0:		// Left+Right
				_fT0 = (_pDbAcParamRec->dbAcParamResult.fDeltaT0L + _pDbAcParamRec->dbAcParamResult.fDeltaT0R) / 2;
				_fT1 = (_pDbAcParamRec->dbAcParamResult.fDeltaT1L + _pDbAcParamRec->dbAcParamResult.fDeltaT1R) / 2;
				break;
			case 1:		// Left
				_fT0 = _pDbAcParamRec->dbAcParamResult.fDeltaT0L;
				_fT1 = _pDbAcParamRec->dbAcParamResult.fDeltaT1L;
				break;
			case 2:		// Right
				_fT0 = _pDbAcParamRec->dbAcParamResult.fDeltaT0R;
				_fT1 = _pDbAcParamRec->dbAcParamResult.fDeltaT1R;
				break;
		}
		CalcParamTSub(p1, p2, _nData, _fRate, _fT1,
					  _pDbAcParamRec->dbAcParamCond.fTsubEnd, _pDbAcParamRec->dbAcParamCond.bTsubAuto, _pDbAcParamRec->dbAcParamCond.fTsubNoise, &_fDev, NULL, &_fEndTime);

		CalcParamTx2(p1, p2, _nData, _fRate, (int)(_fT0 / 1000 * _fRate), &_fT20Reg0, &_fT20Reg1, &_fT30Reg0, &_fT30Reg1, &_fEDTReg0, &_fEDTReg1);

		_fTsubNoise = _pDbAcParamRec->dbAcParamCond.fTsubNoise;
	} else {
		_fT1 = 0;
		_fDev = 0;
		_fTsubNoise = setData.Imp.fTsubNoise;
	}

	float power;
	for (i = 0; i < _nData; i++) {
		if (p2 != NULL)
			power = p1[i] * p1[i] + p2[i] * p2[i];
		else
			power = p1[i] * p1[i];
		_pEchoEnergy[i] = power;
	}

	float max = GetMaxData(_pEchoEnergy, _nData);
	for (i = 0; i < _nData; i++)
		_pEchoEnergy[i] /= max;

	if (_fTsubNoise != 0)
		CalcEchoData(p1, p2, _pEchoData, _nData, _fRate, _fT1, _fTsubNoise);
	CalcEchoData(p1, p2, _pEchoData2, _nData, _fRate, _fT1, 0);
}

- (void)redraw
{
	[self calcGraphWindow];
	[self dispGraphWindow];
}

- (void)dispGraphWindow
{
	int nScrollSize;
	int nScrollPos;

	if (_fDispTime == 0)
		_fDispTime = _fTotalTime;
	else if (_fDispTime < _fTotalTime / MAX_ZOOM_TIME)
		_fDispTime = _fTotalTime / MAX_ZOOM_TIME;
	else if (_fDispTime > _fTotalTime)
		_fDispTime = _fTotalTime;

	if (_fStartTime < 0)
		_fStartTime = 0;
	else if (_fStartTime > _fTotalTime - _fDispTime)
		_fStartTime = _fTotalTime - _fDispTime;

	nScrollSize = (int)(_fDispTime / _fTotalTime * SCROLL_RANGE);
	nScrollPos = (int)(_fStartTime / _fTotalTime * SCROLL_RANGE);

	if (nScrollSize != _nScrollSize || nScrollPos != _nScrollPos) {
		_nScrollSize = nScrollSize;
		_nScrollPos = nScrollPos;
	}

	[self.outletGraphIR setNeedsDisplay];
	[self.outletGraphEE setNeedsDisplay];
	[self.outletGraphEcho setNeedsDisplay];
}

- (void)drawGraphData:(CGContextRef)context :(id)sender
{
	if (sender == self.outletGraphIR)
		[self.outletGraphIR dispImpulse:context :_fTotalTime :_fStartTime :_fDispTime :_pEchoTime :_nData];
	else if (sender == self.outletGraphEE)
		[self.outletGraphEE dispEnergy:context :_fTotalTime :_fStartTime :_fDispTime :_pEchoEnergy :_nData :0 :-70];
	else if (sender == self.outletGraphEcho)
		[self.outletGraphEcho dispGraph:context :_fTotalTime :_fStartTime :_fDispTime :_fTsubNoise == 0 ? NULL : _pEchoData :_pEchoData2 :_nData :_fRate :_fT0 :_fT1 :_fDev :_fEndTime :10 :-70 :_fT20Reg0 :_fT20Reg1 :_fT30Reg0 :_fT30Reg1 :_fEDTReg0 :_fEDTReg1];
}

- (void)dealloc
{
	[self freeBuffer];
}

- (void)allocBuffer
{
	[self freeBuffer];

	_pEchoTime = new float[_nData];
	_pEchoEnergy = new float[_nData];
	_pEchoData = new float[_nData];
	_pEchoData2 = new float[_nData];
}

- (void)freeBuffer
{
	if (_pEchoTime != NULL) {
		delete [] _pEchoTime;
		_pEchoTime = NULL;
	}

	if (_pEchoEnergy != NULL) {
		delete [] _pEchoEnergy;
		_pEchoEnergy = NULL;
	}

	if (_pEchoData != NULL) {
		delete [] _pEchoData;
		_pEchoData = NULL;
	}

	if (_pEchoData2 != NULL) {
		delete [] _pEchoData2;
		_pEchoData2 = NULL;
	}
	
}

- (IBAction)onChangeLeftRight:(id)sender
{
	[self calcGraphWindow];
	[self dispGraphWindow];
}

- (IBAction)onCalculation:(id)sender
{
	_calcEchoViewController = [[CalcEchoViewController alloc] initWithNibName:@"CalcEcho" bundle:nil];
	_calcEchoViewController.delegate = self;
	_calcEchoViewController.fTsubEnd = _pDbAcParamRec->dbAcParamCond.fTsubEnd;
	_calcEchoViewController.bTsubAuto = _pDbAcParamRec->dbAcParamCond.bTsubAuto;
	_calcEchoViewController.fTsubNoise = _pDbAcParamRec->dbAcParamCond.fTsubNoise * 100;
	[self presentPopupViewController:_calcEchoViewController animationType:MJPopupViewAnimationFade enableBackground:YES];
}

- (void)onOK
{
	_pDbAcParamRec->dbAcParamCond.fTsubEnd = _calcEchoViewController.fTsubEnd;
	_pDbAcParamRec->dbAcParamCond.bTsubAuto = _calcEchoViewController.bTsubAuto;
	_pDbAcParamRec->dbAcParamCond.fTsubNoise = _calcEchoViewController.fTsubNoise / 100;
	CalcTsub(_pDbImpulseRec, _hWaveData, _pDbAcParamRec, _fRate);
	[(GraphViewController *)self.parentViewController changeData];

	[self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
}

- (void)moveGraph:(id)sender :(float)move
{
	_fStartTime += move * _fDispTime;
	[self dispGraphWindow];
}

- (void)zoomGraph:(id)sender :(float)zoom
{
	_fDispTime *= zoom;
	[self dispGraphWindow];
}

@end
