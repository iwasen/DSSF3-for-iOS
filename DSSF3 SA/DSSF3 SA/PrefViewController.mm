//
//  PrefViewController.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/13.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "PrefViewController.h"
#import "Calc.h"
#import "Controls.h"

#define MAX_TE	300

@interface PrefViewController ()

@property (nonatomic, weak) IBOutlet PrefView *outletGraphPref;
@property (nonatomic, weak) IBOutlet CtTextField *outletTauE;
@property (nonatomic, weak) IBOutlet CtTextField *outletBestSPL;
@property (nonatomic, weak) IBOutlet CtTextField *outletBestTauE;
@property (nonatomic, weak) IBOutlet CtTextField *outletS4;
@property (nonatomic, weak) IBOutlet CtTextField *outletS3;
@property (nonatomic, weak) IBOutlet CtTextField *outletS2;
@property (nonatomic, weak) IBOutlet CtTextField *outletS1;
@property (nonatomic, weak) IBOutlet CtTextField *outletS;

@end

@implementation PrefViewController
{
    float *_pData;
    float _fSPL, _fDT1, _fTsub, _fIACC, _fA;
    float _maxS;
    int _maxTauE;
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
	[self.outletGraphPref initialize];

	self.outletBestSPL.text = [NSString stringWithFormat:@"%.2lf", LogMean(_pDbAcParamRec->dbAcParamData[0].fSplL, _pDbAcParamRec->dbAcParamData[0].fSplR) + _fAdjustSPL];

	[self allocBuffer];

	[self getParameter];
	[self dispPrefWindow];
	self.outletTauE.text = self.outletBestTauE.text;
	[self dispPreference];

	self.outletGraphPref.enabled = YES;
}

- (void)viewDidLayoutSubviews
{
	[self dispPrefWindow];
}

- (void)dealloc
{
	[self freeBuffer];
}

- (void)allocBuffer
{
	[self freeBuffer];

	_pData = new float[MAX_TE];
}

- (void)freeBuffer
{
	if (_pData != NULL) {
		delete [] _pData;
		_pData = NULL;
	}
}

- (void)dispPrefWindow
{
	float s[5];
	int i;

	_maxS = -1000;
	for (i = 0; i < MAX_TE; i++) {
		CalcPreference(_fSPL, _fDT1, _fTsub, _fIACC, _fA, i + 1, self.outletBestSPL.floatValue, s);
		_pData[i] = s[0];
		if (_pData[i] > _maxS) {
			_maxS = _pData[i];
			_maxTauE = i + 1;
		}
	}
	self.outletBestTauE.intValue = _maxTauE;

	[self.outletGraphPref setNeedsDisplay];
}

- (void)drawGraphData:(CGContextRef)context :(id)sender
{
	[self.outletGraphPref dispGraph:context :_pData :MAX_TE :_maxTauE :_maxS];
}

- (IBAction)onCalc:(id)sender
{
	[self getParameter];
	[self dispPrefWindow];
	[self dispPreference];
}

- (void)dispPreference
{
	float s[5];

	if (_maxTauE <= 0) {
		MessageBoxOK(self, NSLocalizedString(@"IDS_MSG_TAUE", nil), nil);
		return;
	}

	CalcPreference(_fSPL, _fDT1, _fTsub, _fIACC, _fA, self.outletTauE.floatValue, self.outletBestSPL.floatValue, s);
	[self.outletS setFloatValue:s[0] decimalPosition:2];
	[self.outletS1 setFloatValue:s[1] decimalPosition:2];
	[self.outletS2 setFloatValue:s[2] decimalPosition:2];
	[self.outletS3 setFloatValue:s[3] decimalPosition:2];
	[self.outletS4 setFloatValue:s[4] decimalPosition:2];
}

- (void)getParameter
{
	DbAcParamData *pAcParam = &_pDbAcParamRec->dbAcParamData[0];

	_fSPL = MeanSPL(pAcParam->fSplL, pAcParam->fSplR) + _fAdjustSPL;
	_fDT1 = MeanDT1(_pDbAcParamRec->dbAcParamResult.fDeltaT1L - _pDbAcParamRec->dbAcParamResult.fDeltaT0L, _pDbAcParamRec->dbAcParamResult.fDeltaT1R - _pDbAcParamRec->dbAcParamResult.fDeltaT0R);
	_fTsub = MeanTsub(pAcParam->tSubL, pAcParam->tSubR);
	_fIACC = pAcParam->fIACC;
	_fA = MeanA(pAcParam->fAL, pAcParam->fAR);
}

- (void)redraw
{
	[self getParameter];
	[self dispPrefWindow];
	[self dispPreference];
}

@end
