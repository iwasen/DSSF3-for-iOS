//
//  InformationViewController.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/17.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "InformationViewController.h"
#import "Common.h"
#import "Calc.h"
#import "Controls.h"

@interface InformationViewController ()

@property (nonatomic, weak) IBOutlet UIScrollView *outletScrollView;
@property (nonatomic, weak) IBOutlet UIView *outletBaseView;

@property (nonatomic, weak) IBOutlet CtTextField *outletFolderTitle;
@property (nonatomic, weak) IBOutlet CtTextField *outletName;
@property (nonatomic, weak) IBOutlet CtTextField *outletPlace;
@property (nonatomic, weak) IBOutlet CtTextField *outletFolderComment;
@property (nonatomic, weak) IBOutlet CtTextField *outletDate;
@property (nonatomic, weak) IBOutlet CtTextField *outletScale;

@property (nonatomic, weak) IBOutlet CtTextField *outletSampling;
@property (nonatomic, weak) IBOutlet CtTextField *outletMeasureTime;
@property (nonatomic, weak) IBOutlet CtTextField *outletMeasureNum;
@property (nonatomic, weak) IBOutlet CtTextField *outletChannel;
@property (nonatomic, weak) IBOutlet CtTextField *outletTitle;
@property (nonatomic, weak) IBOutlet CtTextField *outletComment;
@property (nonatomic, weak) IBOutlet CtTextField *outletTime;

@property (nonatomic, weak) IBOutlet UISegmentedControl *outletFreqBand;
@property (nonatomic, weak) IBOutlet CtTextField *outletStartFreq;
@property (nonatomic, weak) IBOutlet CtTextField *outletEndFreq;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletAFilter;
@property (nonatomic, weak) IBOutlet CtTextField *outletPrefSPL;
@property (nonatomic, weak) IBOutlet CtTextField *outletPrefTauE;
@property (nonatomic, weak) IBOutlet CtTextField *outletIACCWLevel;
@property (nonatomic, weak) IBOutlet CtTextField *outletDT1MinTime;
@property (nonatomic, weak) IBOutlet CtTextField *outletTsubNoise;
@property (nonatomic, weak) IBOutlet CtTextField *outletTsubEnd;
@property (nonatomic, weak) IBOutlet CtTextField *outletSplRefLevel;
@property (nonatomic, weak) IBOutlet CtTextField *outletSplRefData;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletTsubAuto;
@property (nonatomic, weak) IBOutlet CtTextField *outletGRefData;
@property (nonatomic, weak) IBOutlet CtTextField *outletTCustom1;
@property (nonatomic, weak) IBOutlet CtTextField *outletTCustom2;
@property (nonatomic, weak) IBOutlet CtTextField *outletCCustom;

@end

@implementation InformationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	CString str;

	[self setFolderInfo];
	[self setMeasurementConditions];
	[self setCalculationConditions];
	self.outletScrollView.contentSize = self.outletBaseView.bounds.size;
}

- (void)setFolderInfo
{
	self.outletFolderTitle.text = _dbFolderRec->sTitle;
	self.outletName.text = _dbFolderRec->sName;
	self.outletPlace.text = _dbFolderRec->sPlace;
	self.outletFolderComment.text = _dbFolderRec->sComment;
	self.outletDate.text = FormatTime(_dbFolderRec->sDate);
	self.outletScale.text = [NSString stringWithFormat:@"1/%g", _fScale];

}

- (void)setMeasurementConditions
{
	self.outletSampling.intValue = _dbImpulseRec->nSampling;
	self.outletMeasureTime.text = [NSString stringWithFormat:@"%.3f", (float)_nWaveData / _dbImpulseRec->nSampling];
	self.outletMeasureNum.intValue = _dbImpulseRec->nMeasNum;
	self.outletChannel.text = (_dbImpulseRec->nChannel == 1) ? @"Mono" : @"Stereo";
	self.outletTitle.text = _dbImpulseRec->sTitle;
	self.outletComment.text = _dbImpulseRec->sComment;
	self.outletTime.text = FormatTime(_dbImpulseRec->sTime);

}

- (void)setCalculationConditions
{
	if (!_bCalculated)
		return;

	self.outletFreqBand.selectedSegmentIndex = _dbAcParamRec->dbAcParamCond.nFreqBand;

	if (_dbAcParamRec->dbAcParamCond.nSplRefData == SPL_ABSOLUTE)
		self.outletSplRefData.text = NSLocalizedString(@"IDS_ABSVALUE", nil);
	else if (_dbAcParamRec->dbAcParamCond.nSplRefData == SPL_MAXREF)
		self.outletSplRefData.text = NSLocalizedString(@"IDS_MAXVALUE", nil);
	else {
		CDbImpulse dbImpulse;
		DbImpulseRec dbImpulseRec;

		if (dbImpulse.Open()) {
			if (dbImpulse.ReadRecID(_dbAcParamRec->dbAcParamCond.nSplRefData, &dbImpulseRec))
				self.outletSplRefData.text = dbImpulseRec.sTitle;
		}
	}

	if (_dbAcParamRec->dbAcParamCond.nSplRefData != SPL_ABSOLUTE)
		self.outletSplRefLevel.floatValue = _dbAcParamRec->dbAcParamCond.fSplRefLevel;

	if (!_dbAcParamRec->dbAcParamCond.bTsubAuto)
		self.outletTsubEnd.floatValue = _dbAcParamRec->dbAcParamCond.fTsubEnd;

	self.outletTsubAuto.checked = _dbAcParamRec->dbAcParamCond.bTsubAuto;
	self.outletTsubNoise.floatValue = _dbAcParamRec->dbAcParamCond.fTsubNoise * 100;
	self.outletDT1MinTime.floatValue = _dbAcParamRec->dbAcParamCond.fDT1MinTime;
	self.outletIACCWLevel.floatValue = _dbAcParamRec->dbAcParamCond.fWIACCLevel;
	self.outletPrefSPL.floatValue = _dbAcParamRec->dbAcParamCond.fPrefSPL;
	self.outletPrefTauE.floatValue = _dbAcParamRec->dbAcParamCond.fPrefTauE;

	int index = 1;
	if (_dbAcParamRec->dbAcParamCond.bAFilter)
		index++;
	if (_dbAcParamRec->nDataNum > index) {
		self.outletStartFreq.text = GetDispFreq(_dbAcParamRec->dbAcParamData[index].nFreq, _dbAcParamRec->dbAcParamCond.nFreqBand, NO);
		self.outletEndFreq.text = GetDispFreq(_dbAcParamRec->dbAcParamData[_dbAcParamRec->nDataNum - 1].nFreq, _dbAcParamRec->dbAcParamCond.nFreqBand, NO);
	}
	self.outletAFilter.checked = _dbAcParamRec->dbAcParamCond.bAFilter;

	self.outletGRefData.floatValue = _dbAcParamRec->dbAcParamCond.fGRefData;
	self.outletTCustom1.floatValue = _dbAcParamRec->dbAcParamCond.fTCustom1;
	self.outletTCustom2.floatValue = _dbAcParamRec->dbAcParamCond.fTCustom2;
	self.outletCCustom.floatValue = _dbAcParamRec->dbAcParamCond.fCCustom;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
