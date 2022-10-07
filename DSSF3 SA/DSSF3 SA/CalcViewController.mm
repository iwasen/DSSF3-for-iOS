//
//  CalcViewController.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/20.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "CalcViewController.h"
#import "SetData.h"
#import "Calc.h"
#import "MMDB.h"
#import "Controls.h"
#import "UIViewController+MJPopupViewController.h"

@interface CalcViewController ()

@property (atomic) BOOL cancelFlag;

@property (nonatomic, weak) IBOutlet UISegmentedControl *outletTargetData;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletFreqBand;
@property (nonatomic, weak) IBOutlet CtComboBox *outletStartFreq;
@property (nonatomic, weak) IBOutlet CtComboBox *outletEndFreq;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletAFilter;
@property (nonatomic, weak) IBOutlet CtTextField *outletPrefSPL;
@property (nonatomic, weak) IBOutlet CtTextField *outletPrefTauE;
@property (nonatomic, weak) IBOutlet CtTextField *outletWIACCLevel;
@property (nonatomic, weak) IBOutlet CtTextField *outletDT1MinTime;
@property (nonatomic, weak) IBOutlet CtTextField *outletTsubNoise;
@property (nonatomic, weak) IBOutlet CtTextField *outletTsubEnd;
@property (nonatomic, weak) IBOutlet CtTextField *outletSplRefLevel;
@property (nonatomic, weak) IBOutlet CtComboBox *outletSplRefData;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletTsubAuto;
@property (nonatomic, weak) IBOutlet CtTextField *outletGRefData;
@property (nonatomic, weak) IBOutlet CtTextField *outletTCustom1;
@property (nonatomic, weak) IBOutlet CtTextField *outletTCustom2;
@property (nonatomic, weak) IBOutlet CtTextField *outletCCustom;

@end

@implementation CalcViewController
{
    CalcProgressViewController *_calcProgressViewController;
    int _targetData;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	self.outletFreqBand.selectedSegmentIndex = setData.Imp.nFreqBand;
	self.outletAFilter.checked = setData.Imp.bAFilter;
	self.outletSplRefLevel.floatValue = setData.Imp.fSplRefLevel;
	self.outletDT1MinTime.floatValue = setData.Imp.fDT1MinTime;
	self.outletTsubEnd.floatValue = setData.Imp.fTsubEnd;
	self.outletTsubAuto.checked = setData.Imp.bTsubAuto;
	self.outletTsubNoise.floatValue = setData.Imp.fTsubNoise * 100;
	self.outletWIACCLevel.floatValue = setData.Imp.fWIACCLevel;
	self.outletPrefSPL.floatValue = setData.Imp.fPrefSPL;
	self.outletPrefTauE.floatValue = setData.Imp.fPrefTauE;
	self.outletGRefData.floatValue = setData.Imp.fGRefData;
	self.outletTCustom1.floatValue = setData.Imp.fTCustom1;
	self.outletTCustom2.floatValue = setData.Imp.fTCustom2;
	self.outletCCustom.floatValue = setData.Imp.fCCustom;

	[self setSplRefData];

	[self setFreq];

	[self onChangeTsubAuto:self.outletTsubAuto];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)onCalculation:(id)sender
{
	setData.Imp.nFreqBand = (int)self.outletFreqBand.selectedSegmentIndex;
	setData.Imp.bAFilter = self.outletAFilter.checked;
	setData.Imp.nSplRefData = [self getSplRefData];
	setData.Imp.fSplRefLevel = self.outletSplRefLevel.floatValue;
	setData.Imp.fDT1MinTime = self.outletDT1MinTime.floatValue;
	setData.Imp.fTsubEnd = self.outletTsubEnd.floatValue;
	setData.Imp.bTsubAuto = self.outletTsubAuto.checked;
	setData.Imp.fTsubNoise = self.outletTsubNoise.floatValue / 100;
	setData.Imp.fWIACCLevel = self.outletWIACCLevel.floatValue;
	setData.Imp.fPrefSPL = self.outletPrefSPL.floatValue;
	setData.Imp.fPrefTauE = self.outletPrefTauE.floatValue;
	setData.Imp.fGRefData = self.outletGRefData.floatValue;
	setData.Imp.fTCustom1 = self.outletTCustom1.floatValue;
	setData.Imp.fTCustom2 = self.outletTCustom2.floatValue;
	setData.Imp.fCCustom = self.outletCCustom.floatValue;

	_targetData = (int)self.outletTargetData.selectedSegmentIndex;
	self.cancelFlag = NO;

	_calcProgressViewController = [[CalcProgressViewController alloc] initWithNibName:@"CalcProgressView" bundle:nil];
	_calcProgressViewController.delegate = self;
	[self presentPopupViewController:_calcProgressViewController animationType:MJPopupViewAnimationFade enableBackground:NO];

	[NSThread detachNewThreadSelector:@selector(calcThread)
							 toTarget:self
						   withObject:nil];
}

- (void)onCancelCalculation
{
	self.cancelFlag = YES;
	[self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
}

- (void)calcThread
{
	@autoreleasepool {
		[self calcAcParam];
		[self performSelectorOnMainThread:@selector(endCalc:) withObject:nil waitUntilDone:NO];
	}
}

- (void)calcAcParam
{
	CDbFolder dbFolder;
	DbFolderRec dbFolderRec;
	CDbImpulse dbImpulse;
	DbImpulseRec dbImpulseRec;
	CDbAcParam dbAcParam;
	DbAcParamRec dbAcParamRec;
	int i;
	int eof;
	int nRec;
	HWAVEDATA hWaveData;
	double fScale = 1.0;
	CString str;

	if (_folderId != 0) {
		if (!dbFolder.Open())
			return;

		if (!dbFolder.ReadRecID(_folderId, &dbFolderRec))
			return;

		if (dbFolderRec.fScale != 0)
			fScale = dbFolderRec.fScale;

		dbFolder.DBClose();
	}

	if (!dbImpulse.Open())
		return;

	if (!dbAcParam.Open())
		return;

	dbImpulse.DBChgIdx(dbImpulse.m_nIdxImpulseID);
	str.Format("#%d=%ld", dbImpulse.m_nIdxFolderID, _folderId);
	dbImpulse.DBSelect(str, &nRec);

	for (i = 0; ; i++, dbImpulse.DBSkip(1)) {
		[self performSelectorOnMainThread:@selector(setProgressBar:) withObject:[NSNumber numberWithFloat:(float)i / nRec] waitUntilDone:YES];

		if (dbImpulse.DBEof(&eof) != 0 || eof)
			break;

		if (!dbImpulse.ReadRecID(-1, &dbImpulseRec))
			break;

		switch (_targetData) {
			case 0:
				if (dbAcParam.SearchID(dbImpulseRec.nImpulseID))
					continue;
				break;
		}

		if ((hWaveData = MMWaveReadDB(dbImpulse, "WAVEDATA")) == NULL)
			continue;

		memset(&dbAcParamRec, 0, sizeof(dbAcParamRec));
		dbAcParamRec.nImpulseID = dbImpulseRec.nImpulseID;
		if (CalcAcParam(&dbImpulseRec, hWaveData, &dbAcParamRec, dbImpulseRec.nSampling / fScale, self, @selector(setProgressMessage:))) {
			delete [] hWaveData;
			break;
		}

		delete [] hWaveData;

		if (dbAcParam.SearchID(dbAcParamRec.nImpulseID))
			dbAcParam.UpdateRec(&dbAcParamRec);
		else
			dbAcParam.StoreRec(&dbAcParamRec);

		if (self.cancelFlag)
			return;
	}

	[self performSelectorOnMainThread:@selector(setProgressBarEnd:) withObject:[NSNumber numberWithFloat:1.0] waitUntilDone:YES];
	[self performSelectorOnMainThread:@selector(setProgressMessage:) withObject:NSLocalizedString(@"IDS_CALC_END", nil) waitUntilDone:YES];
	[NSThread sleepForTimeInterval:1.5];
}

- (void)setProgressBar:(NSNumber *)num
{
	[_calcProgressViewController setProgress:num.floatValue :YES];
}

- (void)setProgressBarEnd:(NSNumber *)num
{
	[_calcProgressViewController setProgress:num.floatValue :NO];
}

- (void)setProgressMessage:(NSString *)message
{
	[_calcProgressViewController setMessage:message];
}

- (void)endCalc:(NSObject *)dummy
{
	[self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)setFreq
{
	int i;
	const FREQBAND *pFilter;
	NSString *str;

	[self.outletStartFreq resetContent];
	[self.outletEndFreq resetContent];

	str = NSLocalizedString(@"IDS_NONE", nil);
	[self.outletStartFreq addItem:str :0];

	pFilter = &g_tFilterTbl[self.outletFreqBand.selectedSegmentIndex];
	for (i = 1; i < pFilter->nData; i++) {
		str = [NSString stringWithFormat:@"%g", pFilter->fDispFreq[i]];
		[self.outletStartFreq addItem:str :0];
		[self.outletEndFreq addItem:str :0];
	}

	if (setData.Imp.nStartFreq > pFilter->nData)
		setData.Imp.nStartFreq = pFilter->nData - 1;

	if (setData.Imp.nEndFreq > pFilter->nData - 1)
		setData.Imp.nEndFreq = pFilter->nData - 2;

	self.outletStartFreq.selectedIndex = setData.Imp.nStartFreq;
	self.outletEndFreq.selectedIndex = setData.Imp.nEndFreq;

	self.outletEndFreq.enabled = (setData.Imp.nStartFreq != 0);
}

- (IBAction)onChangeOctave:(id)sender
{
	[self setFreq];
}

- (IBAction)onChangeStartFreq
{
	setData.Imp.nStartFreq = self.outletStartFreq.selectedIndex;
	self.outletEndFreq.enabled = (setData.Imp.nStartFreq != 0);
}

- (IBAction)onChangeEndFreq
{
	setData.Imp.nEndFreq = self.outletEndFreq.selectedIndex;
}

- (void)setSplRefData
{
	CDbImpulse dbImpulse;
	DbImpulseRec dbImpulseRec;
	NSString *str;
	int nRec;
	int index;

	str = NSLocalizedString(@"IDS_ABSVALUE", nil);
	index = [self.outletSplRefData addItem:str :SPL_ABSOLUTE];
	if (setData.Imp.nSplRefData == SPL_ABSOLUTE)
		self.outletSplRefData.selectedIndex = index;

	str = NSLocalizedString(@"IDS_MAXVALUE", nil);
	index = [self.outletSplRefData addItem:str :SPL_MAXREF];
	if (setData.Imp.nSplRefData == SPL_MAXREF)
		self.outletSplRefData.selectedIndex = index;

	if (!dbImpulse.Open())
		return;

	dbImpulse.DBChgIdx(dbImpulse.m_nIdxImpulseID);
	str = [NSString stringWithFormat:@"#%d=%d", dbImpulse.m_nIdxFolderID, _folderId];
	dbImpulse.DBSelect([str cStringUsingEncoding:NSUTF8StringEncoding], &nRec);

	for (;;) {
		if (!dbImpulse.ReadRecNext(&dbImpulseRec))
			break;

		index = [self.outletSplRefData addItem:dbImpulseRec.sTitle :dbImpulseRec.nImpulseID];
		if (setData.Imp.nSplRefData == dbImpulseRec.nImpulseID)
			self.outletSplRefData.selectedIndex = index;
	}

	[self onChangeSplRefData:self.outletSplRefData];
}

- (int)getSplRefData
{
	return self.outletSplRefData.selectedItemData;
}

- (IBAction)onChangeSplRefData:(id)sender
{
	self.outletSplRefLevel.enabled = (self.outletSplRefData.selectedItemData != SPL_ABSOLUTE);
}

- (IBAction)onChangeTsubAuto:(id)sender
{
	self.outletTsubEnd.enabled = (!self.outletTsubAuto.checked);
}

@end
