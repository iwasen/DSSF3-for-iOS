//
//  ImpulseViewController.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/13.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "ImpulseViewController.h"
#import "GraphViewController.h"
#import "Calc.h"
#import "Controls.h"

#define COLOR_LEFT		RGB(0, 128, 255)
#define COLOR_RIGHT		RGB(255, 64, 192)

#define SCROLL_RANGE 16384
#define MAX_ZOOM_TIME	512

@interface ImpulseViewController ()

@property (nonatomic, weak) IBOutlet ImpulseView *outletGraphLeft;
@property (nonatomic, weak) IBOutlet ImpulseView *outletGraphRight;
@property (nonatomic, weak) IBOutlet CtTextField *outletLeftT0;
@property (nonatomic, weak) IBOutlet CtTextField *outletLeftT1;
@property (nonatomic, weak) IBOutlet CtTextField *outletRightT0;
@property (nonatomic, weak) IBOutlet CtTextField *outletRightT1;
@property (nonatomic, weak) IBOutlet CtButton *outletChange;

@end

@implementation ImpulseViewController
{
    float _fTotalTime;
    int _nScrollPos;
    int _nScrollSize;
    UIColor *_colorLeft;
    UIColor *_colorRight;
    int _replayCount;
    float _maxData;
}


- (void)initialize
{
	_nScrollSize = -1;
	_nScrollPos = -1;
	_colorLeft = [[UIColor alloc] COLOR_LEFT];
	_colorRight = [[UIColor alloc] COLOR_RIGHT];

	NSString *str;
	if (_pDbImpulseRec->nChannel == 1) {
		str = NSLocalizedString(@"IDS_IR", nil);
		[self.outletGraphLeft initialize:str :_pDbAcParamRec != NULL ? 3 : 1 :_colorLeft];
	} else {
		str = NSLocalizedString(@"IDS_LEFTIR", nil);
		[self.outletGraphLeft initialize:str :_pDbAcParamRec != NULL ? 3 : 1 :_colorLeft];
		str = NSLocalizedString(@"IDS_RIGHTIR", nil);
		[self.outletGraphRight initialize:str :_pDbAcParamRec != NULL ? 3 : 1 :_colorRight];
	}

	_fTotalTime = (float)_nData / _fRate;

	self.outletGraphLeft.enabled = YES;
	if (_pDbImpulseRec->nChannel == 2)
		self.outletGraphRight.enabled = YES;

	if (_pDbAcParamRec == NULL) {
		self.outletLeftT0.enabled = NO;
		self.outletLeftT1.enabled = NO;
		self.outletRightT0.enabled = NO;
		self.outletRightT1.enabled = NO;
		self.outletChange.enabled = NO;
	} else {
		[self.outletGraphLeft setDeltaT1:_pDbAcParamRec->dbAcParamResult.fDeltaT0L :_pDbAcParamRec->dbAcParamResult.fDeltaT1L];
		[self.outletLeftT0 setFloatValue:_pDbAcParamRec->dbAcParamResult.fDeltaT0L decimalPosition:2];
		[self.outletLeftT1 setFloatValue:_pDbAcParamRec->dbAcParamResult.fDeltaT1L decimalPosition:2];
		if (_pDbImpulseRec->nChannel == 1) {
			self.outletRightT0.enabled = NO;
			self.outletRightT1.enabled = NO;
		} else {
			[self.outletGraphRight setDeltaT1:_pDbAcParamRec->dbAcParamResult.fDeltaT0R :_pDbAcParamRec->dbAcParamResult.fDeltaT1R];
			[self.outletRightT0 setFloatValue:_pDbAcParamRec->dbAcParamResult.fDeltaT0R decimalPosition:2];
			[self.outletRightT1 setFloatValue:_pDbAcParamRec->dbAcParamResult.fDeltaT1R decimalPosition:2];
		}
	}

	self.outletChange.enabled = NO;
}

- (void)viewDidLayoutSubviews
{
	[self dispGraphWindow];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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

	[self.outletGraphLeft setNeedsDisplay];
	[self.outletGraphRight setNeedsDisplay];
}

- (void)drawGraphData:(CGContextRef)context :(id)sender
{
	if (sender == self.outletGraphLeft)
		[self.outletGraphLeft dispImpulse:context :_fTotalTime :_fStartTime :_fDispTime :_pIRLeft :_nData];
	else if (sender == self.outletGraphRight)
		[self.outletGraphRight dispImpulse:context :_fTotalTime :_fStartTime :_fDispTime :_pIRRight :_nData];
}

- (void)redraw
{
	[self dispGraphWindow];
}

- (IBAction)onChange:(id)sender
{
	_pDbAcParamRec->dbAcParamResult.fDeltaT0L = self.outletLeftT0.floatValue;
	_pDbAcParamRec->dbAcParamResult.fDeltaT1L = self.outletLeftT1.floatValue;
	_pDbAcParamRec->dbAcParamResult.fDeltaT0R = self.outletRightT0.floatValue;
	_pDbAcParamRec->dbAcParamResult.fDeltaT1R = self.outletRightT1.floatValue;
	CalcTsub(_pDbImpulseRec, _hWaveData, _pDbAcParamRec, _fRate);
	[self.outletGraphLeft setDeltaT1:_pDbAcParamRec->dbAcParamResult.fDeltaT0L :_pDbAcParamRec->dbAcParamResult.fDeltaT1L];
	[self.outletGraphRight setDeltaT1:_pDbAcParamRec->dbAcParamResult.fDeltaT0R :_pDbAcParamRec->dbAcParamResult.fDeltaT1R];
	[(GraphViewController *)self.parentViewController changeData];
	self.outletChange.enabled = NO;
}

- (IBAction)OnChangeLeftT0:(id)sender
{
	[self.outletGraphLeft setDeltaT1:self.outletLeftT0.floatValue :self.outletLeftT1.floatValue];
	[self.outletGraphLeft setNeedsDisplay];
	self.outletChange.enabled = YES;
}

- (IBAction)OnChangeLeftT1:(id)sender
{
	[self.outletGraphLeft setDeltaT1:self.outletLeftT0.floatValue :self.outletLeftT1.floatValue];
	[self.outletGraphLeft setNeedsDisplay];
	self.outletChange.enabled = YES;
}

- (IBAction)OnChangeRightT0:(id)sender
{
	[self.outletGraphRight setDeltaT1:self.outletRightT0.floatValue :self.outletRightT1.floatValue];
	[self.outletGraphRight setNeedsDisplay];
	self.outletChange.enabled = YES;
}

- (IBAction)OnChangeRightT1:(id)sender
{
	[self.outletGraphRight setDeltaT1:self.outletRightT0.floatValue :self.outletRightT1.floatValue];
	[self.outletGraphRight setNeedsDisplay];
	self.outletChange.enabled = YES;
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

- (IBAction)onReplay:(id)sender
{
	float maxLeft = 0, maxRight = 0;
	maxLeft = GetMaxData(_pIRLeft, _nData);
	if (_pDbImpulseRec->nChannel == 2)
		maxRight = GetMaxData(_pIRRight, _nData);
	_maxData = MAX(maxLeft, maxRight);

	_replayCount = 0;
	[AudioOutput start:_pDbImpulseRec->nSampling :_pDbImpulseRec->nChannel :4096 :self];
}

- (void)audioOutputData:(AudioData *)audioData
{
	int dataSize = MIN(4096, _nData - _replayCount);

	for (int i = 0; i < dataSize; i++) {
		audioData->pLeftData[i] = _pIRLeft[_replayCount] / _maxData;
		if (_pDbImpulseRec->nChannel == 2)
			audioData->pRightData[i] = _pIRRight[_replayCount] / _maxData;

		_replayCount++;
	}

	audioData->nDataSize = dataSize;
}

@end
