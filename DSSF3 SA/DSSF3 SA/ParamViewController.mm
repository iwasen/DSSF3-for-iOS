//
//  ParamViewController.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/13.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "ParamViewController.h"
#import "Calc.h"
#import "Controls.h"

#define ITEM_SPL	0
#define ITEM_A		1
#define ITEM_TSUB	2
#define ITEM_IACC	3
#define ITEM_TIACC	4
#define ITEM_WIACC	5

#define ITEM_G		6
#define ITEM_T20	7
#define ITEM_T30	8
#define ITEM_T_CUSTOM	9
#define ITEM_EDT	10
#define ITEM_C50	11
#define ITEM_C80	12
#define ITEM_C_CUSTOM	13
#define ITEM_D50	14
#define ITEM_TS		15
#define ITEM_IACCE	16
#define ITEM_IACCL	17

@interface ParamViewController ()

@property (nonatomic, weak) IBOutlet ParamView *outletGraphParam;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletParamItem1;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletParamItem2;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletParamItem3;

@end

@implementation ParamViewController
{
    int *_pDataFreq;
    float *_pDataAll;
    float *_pDataLeft;
    float *_pDataRight;
    float _fScaleMin, _fScaleMax, _fScaleStep;
    NSString *_vAxis;
    float *_dataAll, *_dataLeft, *_dataRight;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.outletParamItem2.selectedSegmentIndex = -1;
	self.outletParamItem3.selectedSegmentIndex = -1;
}

- (void)initialize
{
	//_iParamItem = _pParent->_nParamItem;

	[self.outletGraphParam initialize];

	[self allocBuffer];

	if (_pDbImpulseRec->nChannel == 1) {
		[self.outletParamItem1 setEnabled:NO forSegmentAtIndex:3];
		[self.outletParamItem1 setEnabled:NO forSegmentAtIndex:4];
		[self.outletParamItem1 setEnabled:NO forSegmentAtIndex:5];
	}

	self.outletGraphParam.enabled = YES;
}

- (void)viewDidLayoutSubviews
{
	[self dispParamWindow];
}

- (void)allocBuffer
{
	int nData = _pDbAcParamRec->nDataNum;
	int i;

	[self freeBuffer];

	_pDataFreq = new int[nData];
	for (i = 0; i < nData; i++)
		_pDataFreq[i] = _pDbAcParamRec->dbAcParamData[i].nFreq;

	_pDataAll = new float[nData];
	if (_pDbImpulseRec->nChannel == 2) {
		_pDataLeft = new float[nData];
		_pDataRight = new float[nData];
	}

}

- (void)freeBuffer
{
	if (_pDataFreq != NULL) {
		delete [] _pDataFreq;
		_pDataFreq = NULL;
	}

	if (_pDataAll != NULL) {
		delete [] _pDataAll;
		_pDataAll = NULL;
	}

	if (_pDataLeft != NULL) {
		delete [] _pDataLeft;
		_pDataLeft = NULL;
	}

	if (_pDataRight != NULL) {
		delete [] _pDataRight;
		_pDataRight = NULL;
	}
}

- (void)dealloc
{
	[self freeBuffer];
}

- (void)redraw
{
	[self dispParamWindow];
}

- (IBAction)onChangeParamItem1:(id)sender
{
	self.outletParamItem2.selectedSegmentIndex = -1;
	self.outletParamItem3.selectedSegmentIndex = -1;
	[self dispParamWindow];

//	_pParent->_nParamItem = _iParamItem;
}

- (IBAction)onChangeParamItem2:(id)sender
{
	self.outletParamItem1.selectedSegmentIndex = -1;
	self.outletParamItem3.selectedSegmentIndex = -1;
	[self dispParamWindow];

	//	_pParent->_nParamItem = _iParamItem;
}

- (IBAction)onChangeParamItem3:(id)sender
{
	self.outletParamItem1.selectedSegmentIndex = -1;
	self.outletParamItem2.selectedSegmentIndex = -1;
	[self dispParamWindow];

	//	_pParent->_nParamItem = _iParamItem;
}

- (void)dispParamWindow
{
	DbAcParamData *pFreqRec;
	float *pDataAll = _pDataAll;
	float *pDataLeft = _pDataLeft;
	float *pDataRight = _pDataRight;
	int nData = _pDbAcParamRec->nDataNum;
	int i;
	CString str, str2;
	NSString *title;
	int nRemark;
	int nParamItem;

	if (self.outletParamItem1.selectedSegmentIndex != -1)
		nParamItem = (int)self.outletParamItem1.selectedSegmentIndex;
	else if (self.outletParamItem2.selectedSegmentIndex != -1)
		nParamItem = (int)self.outletParamItem2.selectedSegmentIndex + 6;
	else
		nParamItem = (int)self.outletParamItem3.selectedSegmentIndex + 12;

	switch (nParamItem) {
		case ITEM_SPL:
			for (i = 0, pFreqRec = _pDbAcParamRec->dbAcParamData; i < nData; i++, pFreqRec++) {
				if (_pDbImpulseRec->nChannel == 1) {
					pDataAll[i] = pFreqRec->fSplL + _fAdjustSPL;
				} else {
					pDataAll[i] = MeanSPL(pFreqRec->fSplL, pFreqRec->fSplR) + _fAdjustSPL;
					pDataLeft[i] = pFreqRec->fSplL + _fAdjustSPL;
					pDataRight[i] = pFreqRec->fSplR + _fAdjustSPL;
				}
			}
			_fScaleMin = -80;
			_fScaleMax = 80;
			_fScaleStep = 10;
			title = @"SPL";
			nRemark = (_pDbImpulseRec->nChannel) == 1 ? 1 : 4;
			_vAxis = @"SPL [dB]";
			break;
		case ITEM_A:
			for (i = 0, pFreqRec = _pDbAcParamRec->dbAcParamData; i < nData; i++, pFreqRec++) {
				if (_pDbImpulseRec->nChannel == 1)
					pDataAll[i] = pFreqRec->fAL;
				else {
					pDataAll[i] = MeanA(pFreqRec->fAL, pFreqRec->fAR);
					pDataLeft[i] = pFreqRec->fAL;
					pDataRight[i] = pFreqRec->fAR;
				}
			}
			_fScaleMin = 0;
			_fScaleMax = 20;
			_fScaleStep = 1;
			title = @"A-value";
			nRemark = (_pDbImpulseRec->nChannel) == 1 ? 1 : 4;
			_vAxis = @"A-value";
			break;
		case ITEM_TSUB:
			for (i = 0, pFreqRec = _pDbAcParamRec->dbAcParamData; i < nData; i++, pFreqRec++) {
				if (_pDbImpulseRec->nChannel == 1)
					pDataAll[i] = pFreqRec->tSubL;
				else {
					pDataAll[i] = MeanTsub(pFreqRec->tSubL, pFreqRec->tSubR);
					pDataLeft[i] = pFreqRec->tSubL;
					pDataRight[i] = pFreqRec->tSubR;
				}
			}
			_fScaleMin = 0;
			_fScaleMax = 5;
			_fScaleStep = 0.5;
			title = @"Tsub";
			nRemark = (_pDbImpulseRec->nChannel) == 1 ? 1 : 4;
			_vAxis = @"Tsub [s]";
			break;
		case ITEM_IACC:
			if (_pDbImpulseRec->nChannel == 2) {
				for (i = 0, pFreqRec = _pDbAcParamRec->dbAcParamData; i < nData; i++, pFreqRec++)
					pDataAll[i] = pFreqRec->fIACC;
			}
			pDataLeft = pDataRight = NULL;
			_fScaleMin = 0;
			_fScaleMax = 1;
			_fScaleStep = 0.1;
			title = @"IACC";
			nRemark = 1;
			_vAxis = @"IACC";
			break;
		case ITEM_TIACC:
			if (_pDbImpulseRec->nChannel == 2) {
				for (i = 0, pFreqRec = _pDbAcParamRec->dbAcParamData; i < nData; i++, pFreqRec++)
					pDataAll[i] = pFreqRec->tIACC;
			}
			pDataLeft = pDataRight = NULL;
			_fScaleMin = -2;
			_fScaleMax = 2;
			_fScaleStep = 0.2;
			title = @"τIACC";
			nRemark = 1;
			_vAxis = @"τIACC [ms]";
			break;
		case ITEM_WIACC:
			if (_pDbImpulseRec->nChannel == 2) {
				for (i = 0, pFreqRec = _pDbAcParamRec->dbAcParamData; i < nData; i++, pFreqRec++)
					pDataAll[i] = pFreqRec->wIACC;
			}
			pDataLeft = pDataRight = NULL;
			_fScaleMin = 0;
			_fScaleMax = 10;
			_fScaleStep = 1;
			title = @"W_IACC";
			nRemark = 1;
			_vAxis = @"W_IACC [ms]";
			break;
		case ITEM_G:
			for (i = 0, pFreqRec = _pDbAcParamRec->dbAcParamData; i < nData; i++, pFreqRec++) {
				if (_pDbImpulseRec->nChannel == 1) {
					pDataAll[i] = pFreqRec->fG_L + _fAdjustSPL;
				} else {
					pDataAll[i] = MeanSPL(pFreqRec->fG_L, pFreqRec->fG_R) + _fAdjustSPL;
					pDataLeft[i] = pFreqRec->fG_L + _fAdjustSPL;
					pDataRight[i] = pFreqRec->fG_R + _fAdjustSPL;
				}
			}
			_fScaleMin = -80;
			_fScaleMax = 80;
			_fScaleStep = 10;
			title = @"G";
			nRemark = (_pDbImpulseRec->nChannel) == 1 ? 1 : 4;
			_vAxis = @"G [dB]";
			break;
		case ITEM_T20:
			for (i = 0, pFreqRec = _pDbAcParamRec->dbAcParamData; i < nData; i++, pFreqRec++) {
				if (_pDbImpulseRec->nChannel == 1)
					pDataAll[i] = pFreqRec->fT20_L;
				else {
					pDataAll[i] = MeanTsub(pFreqRec->fT20_L, pFreqRec->fT20_R);
					pDataLeft[i] = pFreqRec->fT20_L;
					pDataRight[i] = pFreqRec->fT20_R;
				}
			}
			_fScaleMin = 0;
			_fScaleMax = 5;
			_fScaleStep = 0.5;
			title = @"T20";
			nRemark = (_pDbImpulseRec->nChannel) == 1 ? 1 : 4;
			_vAxis = @"T20 [s]";
			break;
		case ITEM_T30:
			for (i = 0, pFreqRec = _pDbAcParamRec->dbAcParamData; i < nData; i++, pFreqRec++) {
				if (_pDbImpulseRec->nChannel == 1)
					pDataAll[i] = pFreqRec->fT30_L;
				else {
					pDataAll[i] = MeanTsub(pFreqRec->fT30_L, pFreqRec->fT30_R);
					pDataLeft[i] = pFreqRec->fT30_L;
					pDataRight[i] = pFreqRec->fT30_R;
				}
			}
			_fScaleMin = 0;
			_fScaleMax = 5;
			_fScaleStep = 0.5;
			title = @"T30";
			nRemark = (_pDbImpulseRec->nChannel) == 1 ? 1 : 4;
			_vAxis = @"T30 [s]";
			break;
		case ITEM_T_CUSTOM:
			for (i = 0, pFreqRec = _pDbAcParamRec->dbAcParamData; i < nData; i++, pFreqRec++) {
				if (_pDbImpulseRec->nChannel == 1)
					pDataAll[i] = pFreqRec->fTCustom_L;
				else {
					pDataAll[i] = MeanTsub(pFreqRec->fTCustom_L, pFreqRec->fTCustom_R);
					pDataLeft[i] = pFreqRec->fTCustom_L;
					pDataRight[i] = pFreqRec->fTCustom_R;
				}
			}
			_fScaleMin = 0;
			_fScaleMax = 5;
			_fScaleStep = 0.5;
			title = @"T_custom";
			nRemark = (_pDbImpulseRec->nChannel) == 1 ? 1 : 4;
			_vAxis = @"T_custom [s]";
			break;
		case ITEM_EDT:
			for (i = 0, pFreqRec = _pDbAcParamRec->dbAcParamData; i < nData; i++, pFreqRec++) {
				if (_pDbImpulseRec->nChannel == 1)
					pDataAll[i] = pFreqRec->fEDT_L;
				else {
					pDataAll[i] = MeanTsub(pFreqRec->fEDT_L, pFreqRec->fEDT_R);
					pDataLeft[i] = pFreqRec->fEDT_L;
					pDataRight[i] = pFreqRec->fEDT_R;
				}
			}
			_fScaleMin = 0;
			_fScaleMax = 5;
			_fScaleStep = 0.5;
			title = @"EDT";
			nRemark = (_pDbImpulseRec->nChannel) == 1 ? 1 : 4;
			_vAxis = @"EDT [s]";
			break;
		case ITEM_C50:
			for (i = 0, pFreqRec = _pDbAcParamRec->dbAcParamData; i < nData; i++, pFreqRec++) {
				if (_pDbImpulseRec->nChannel == 1)
					pDataAll[i] = pFreqRec->fC50_L;
				else {
					pDataAll[i] = MeanTsub(pFreqRec->fC50_L, pFreqRec->fC50_R);
					pDataLeft[i] = pFreqRec->fC50_L;
					pDataRight[i] = pFreqRec->fC50_R;
				}
			}
			_fScaleMin = -40;
			_fScaleMax = 40;
			_fScaleStep = 5;
			title = @"C50";
			nRemark = (_pDbImpulseRec->nChannel) == 1 ? 1 : 4;
			_vAxis = @"C50 [dB]";
			break;
		case ITEM_C80:
			for (i = 0, pFreqRec = _pDbAcParamRec->dbAcParamData; i < nData; i++, pFreqRec++) {
				if (_pDbImpulseRec->nChannel == 1)
					pDataAll[i] = pFreqRec->fC80_L;
				else {
					pDataAll[i] = MeanTsub(pFreqRec->fC80_L, pFreqRec->fC80_R);
					pDataLeft[i] = pFreqRec->fC80_L;
					pDataRight[i] = pFreqRec->fC80_R;
				}
			}
			_fScaleMin = -40;
			_fScaleMax = 40;
			_fScaleStep = 5;
			title = @"C80";
			nRemark = (_pDbImpulseRec->nChannel) == 1 ? 1 : 4;
			_vAxis = @"C80 [dB]";
			break;
		case ITEM_C_CUSTOM:
			for (i = 0, pFreqRec = _pDbAcParamRec->dbAcParamData; i < nData; i++, pFreqRec++) {
				if (_pDbImpulseRec->nChannel == 1)
					pDataAll[i] = pFreqRec->fCCustom_L;
				else {
					pDataAll[i] = MeanTsub(pFreqRec->fCCustom_L, pFreqRec->fCCustom_R);
					pDataLeft[i] = pFreqRec->fCCustom_L;
					pDataRight[i] = pFreqRec->fCCustom_R;
				}
			}
			_fScaleMin = -40;
			_fScaleMax = 40;
			_fScaleStep = 5;
			title = @"C_custom";
			nRemark = (_pDbImpulseRec->nChannel) == 1 ? 1 : 4;
			_vAxis = @"C_custom [dB]";
			break;
		case ITEM_D50:
			for (i = 0, pFreqRec = _pDbAcParamRec->dbAcParamData; i < nData; i++, pFreqRec++) {
				if (_pDbImpulseRec->nChannel == 1)
					pDataAll[i] = pFreqRec->fD50_L;
				else {
					pDataAll[i] = MeanTsub(pFreqRec->fD50_L, pFreqRec->fD50_R);
					pDataLeft[i] = pFreqRec->fD50_L;
					pDataRight[i] = pFreqRec->fD50_R;
				}
			}
			_fScaleMin = 0;
			_fScaleMax = 100;
			_fScaleStep = 10;
			title = @"D50";
			nRemark = (_pDbImpulseRec->nChannel) == 1 ? 1 : 4;
			_vAxis = @"D50 [%]";
			break;
		case ITEM_TS:
			for (i = 0, pFreqRec = _pDbAcParamRec->dbAcParamData; i < nData; i++, pFreqRec++) {
				if (_pDbImpulseRec->nChannel == 1)
					pDataAll[i] = pFreqRec->fTs_L;
				else {
					pDataAll[i] = MeanTsub(pFreqRec->fTs_L, pFreqRec->fTs_R);
					pDataLeft[i] = pFreqRec->fTs_L;
					pDataRight[i] = pFreqRec->fTs_R;
				}
			}
			_fScaleMin = 0;
			_fScaleMax = 2;
			_fScaleStep = 0.2;
			title = @"Ts";
			nRemark = (_pDbImpulseRec->nChannel) == 1 ? 1 : 4;
			_vAxis = @"Ts [s]";
			break;
		case ITEM_IACCE:
			if (_pDbImpulseRec->nChannel == 2) {
				for (i = 0, pFreqRec = _pDbAcParamRec->dbAcParamData; i < nData; i++, pFreqRec++)
					pDataAll[i] = pFreqRec->fIACCE;
			}
			pDataLeft = pDataRight = NULL;
			_fScaleMin = 0;
			_fScaleMax = 1;
			_fScaleStep = 0.1;
			title = @"IACCE";
			nRemark = 1;
			_vAxis = @"IACCE";
			break;
		case ITEM_IACCL:
			if (_pDbImpulseRec->nChannel == 2) {
				for (i = 0, pFreqRec = _pDbAcParamRec->dbAcParamData; i < nData; i++, pFreqRec++)
					pDataAll[i] = pFreqRec->fIACCL;
			}
			pDataLeft = pDataRight = NULL;
			_fScaleMin = 0;
			_fScaleMax = 1;
			_fScaleStep = 0.1;
			title = @"IACCL";
			nRemark = 1;
			_vAxis = @"IACCL";
			break;
		default:
			return;
	}

	_dataAll = pDataAll;
	_dataLeft = pDataLeft;
	_dataRight = pDataRight;

	[self.outletGraphParam setNeedsDisplay];
	[self.outletGraphParam dispRemark:title :nRemark];
}

- (void)drawGraphData:(CGContextRef)context :(id)sender
{
	[self.outletGraphParam dispGraph:context :_pDataFreq :_pDbAcParamRec->dbAcParamCond.nFreqBand :_dataAll :_dataLeft :_dataRight :_pDbAcParamRec->nDataNum :_fScaleMin :_fScaleMax :_fScaleStep :_vAxis];
}

@end
