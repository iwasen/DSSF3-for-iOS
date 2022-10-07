//
//  GraphViewController.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/13.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "GraphViewController.h"
#import "Common.h"
#import "Global.h"
#import "MMDB.h"
#import "FileIO.h"
#import "IRMethod.h"
#import "Calc.h"
#import "InformationViewController.h"
#import "ImpulseViewController.h"
#import "EchoViewController.h"
#import "IACCViewController.h"
#import "FreqViewController.h"
#import "PrefViewController.h"
#import "ParamViewController.h"
#import "MtfViewController.h"

@interface GraphViewController ()

@property (nonatomic, weak) IBOutlet UISegmentedControl *outletGraphTab;
@property (nonatomic, weak) IBOutlet UIView *outletGraphContainer;
@property (nonatomic, weak) IBOutlet MDSpreadView *outletSpredView;
@property (nonatomic, weak) IBOutlet ImpulseViewController *outletImpulseViewController;
@property (nonatomic, weak) IBOutlet EchoViewController *outletEchoViewController;
@property (nonatomic, weak) IBOutlet IACCViewController *outletIACCViewController;
@property (nonatomic, weak) IBOutlet FreqViewController *outletFreqViewController;
@property (nonatomic, weak) IBOutlet PrefViewController *outletPrefViewController;
@property (nonatomic, weak) IBOutlet ParamViewController *outletParamViewController;
@property (nonatomic, weak) IBOutlet MtfViewController *outletMtfViewController;

@end

@implementation GraphViewController
{
    NSArray *_GraphViews;
    float *_pWaveLeft;
    float *_pWaveRight;
    float *_pIRLeft;
    float *_pIRRight;
    int _nData;
    int _nWaveData;
    DbFolderRec _dbFolderRec;
    DbImpulseRec _dbImpulseRec;
    DbAcParamRec _dbAcParamRec;
    HWAVEDATA _hWaveData;
    float _fScale;
    float _fRate;
    int _nMethod;
    float _fAdjustSPL;
    BOOL _bCalculated;
    CIRMethod *_pMethod;
    BOOL _bChangeData;
    int _nCurrentDataNo;
    //    float _fStartTimeIR;
    //    float _fDispTimeIR;
    //    float _fStartTimeEcho;
    //    float _fDispTimeEcho;
    UIDocumentInteractionController *_diController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	[self setFolderInfo];

	[self readData];

	UINib *nib = [UINib nibWithNibName:IS_PHONE ? @"Graph_iPhone" : @"Graph_iPad" bundle:nil];
	_GraphViews = [nib instantiateWithOwner:self options:nil];

	if (IS_PHONE) {
		[self.outletGraphTab setTitleTextAttributes:
		 [NSDictionary dictionaryWithObject:[UIFont systemFontOfSize:10]
									forKey:NSFontAttributeName]
									forState:UIControlStateNormal];
	}

	[self initGraph];

	[self displayGraph];

	[self.outletSpredView selectCellForRowAtIndexPath:[MDIndexPath indexPathForRow:0 inSection:0] forColumnAtIndexPath:[MDIndexPath indexPathForColumn:0 inSection:0] withSelectionMode:MDSpreadViewSelectionModeRow animated:YES scrollPosition:MDSpreadViewScrollPositionNone];
}

- (void)dealloc
{
	[self freeBuffers];
}

- (BOOL)navigationShouldPopOnBackButton
{
	if (!_bChangeData)
		return YES;

	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"IDS_CONFIRMATION", nil) message:NSLocalizedString(@"IDS_MSG_SAVECALC", nil) preferredStyle:UIAlertControllerStyleAlert];
	[alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"IDS_YES", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		CDbAcParam dbAcParam;

		if (dbAcParam.Open())
			dbAcParam.UpdateRec(&self->_dbAcParamRec);

		[self.navigationController popViewControllerAnimated:YES];
	}]];
	[alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"IDS_NO", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		[self.navigationController popViewControllerAnimated:YES];
	}]];
	[self presentViewController:alertController animated:YES completion:nil];

	return NO;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([[segue identifier] isEqualToString:@"Information"]) {
		InformationViewController *nextViewController = [segue destinationViewController];

		nextViewController.bCalculated = _bCalculated;
		nextViewController.dbFolderRec = &_dbFolderRec;
		nextViewController.dbImpulseRec = &_dbImpulseRec;
		nextViewController.dbAcParamRec = &_dbAcParamRec;
		nextViewController.nWaveData = _nWaveData;
		nextViewController.fScale = _fScale;

		self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"IDS_BACK", nil)
																				 style:UIBarButtonItemStylePlain
																				target:nil
																				action:nil];
	}
}

- (void)initGraph
{
	DbAcParamRec *pDbAcParamRec;

	if (_bCalculated)
		pDbAcParamRec = &_dbAcParamRec;
	else
		pDbAcParamRec = NULL;

	self.outletImpulseViewController.hWaveData = _hWaveData;
	self.outletImpulseViewController.pDbImpulseRec = &_dbImpulseRec;
	self.outletImpulseViewController.pDbAcParamRec = pDbAcParamRec;
	self.outletImpulseViewController.pIRLeft = _pIRLeft;
	self.outletImpulseViewController.pIRRight = _pIRRight;
	self.outletImpulseViewController.fRate = _fRate;
	self.outletImpulseViewController.nData = _nWaveData;
//	self.outletImpulseViewController.fStartTime = _fStartTimeIR;
//	self.outletImpulseViewController.fDispTime = _fDispTimeIR;
	[self.outletImpulseViewController initialize];

	self.outletEchoViewController.hWaveData = _hWaveData;
	self.outletEchoViewController.pDbImpulseRec = &_dbImpulseRec;
	self.outletEchoViewController.pDbAcParamRec = pDbAcParamRec;
	self.outletEchoViewController.pIRLeft = _pIRLeft;
	self.outletEchoViewController.pIRRight = _pIRRight;
	self.outletEchoViewController.nData = _nWaveData;
	self.outletEchoViewController.fRate = _fRate;
//	self.outletEchoViewController.fStartTime = _fStartTimeEcho;
//	self.outletEchoViewController.fDispTime = _fDispTimeEcho;
	[self.outletEchoViewController initialize];

	if (_dbImpulseRec.nChannel == 2) {
		self.outletIACCViewController.pDbImpulseRec = &_dbImpulseRec;
		self.outletIACCViewController.pDbAcParamRec = pDbAcParamRec;
		self.outletIACCViewController.pIRLeft = _pIRLeft;
		self.outletIACCViewController.pIRRight = _pIRRight;
		self.outletIACCViewController.fRate = _fRate;
		self.outletIACCViewController.hWaveData = _hWaveData;
		[self.outletIACCViewController initialize];
	} else
		[self.outletGraphTab setEnabled:NO forSegmentAtIndex:2];

	self.outletFreqViewController.pDbImpulseRec = &_dbImpulseRec;
	self.outletFreqViewController.pWaveLeft = _pIRLeft;
	self.outletFreqViewController.pWaveRight = _pIRRight;
	self.outletFreqViewController.fRate = _fRate;
	[self.outletFreqViewController initialize];

	if (_dbImpulseRec.nChannel == 2 && _bCalculated) {
		self.outletPrefViewController.pDbImpulseRec = &_dbImpulseRec;
		self.outletPrefViewController.pDbAcParamRec = pDbAcParamRec;
		self.outletPrefViewController.fScale = _fScale;
		self.outletPrefViewController.fAdjustSPL = _fAdjustSPL;
		[self.outletPrefViewController initialize];
	} else
		[self.outletGraphTab setEnabled:NO forSegmentAtIndex:4];

	if (_bCalculated) {
		self.outletParamViewController.pDbImpulseRec = &_dbImpulseRec;
		self.outletParamViewController.pDbAcParamRec = pDbAcParamRec;
		self.outletParamViewController.fAdjustSPL = _fAdjustSPL;
		[self.outletParamViewController initialize];

		self.outletMtfViewController.pDbImpulseRec = &_dbImpulseRec;
		self.outletMtfViewController.pIRLeft = _pIRLeft;
		self.outletMtfViewController.pIRRight = _pIRRight;
		self.outletMtfViewController.nData = _nWaveData;
		self.outletMtfViewController.fRate = _fRate;
		self.outletMtfViewController.pDbAcParamResult = &pDbAcParamRec->dbAcParamResult;
		[self.outletMtfViewController initialize];
	} else {
		[self.outletGraphTab setEnabled:NO forSegmentAtIndex:5];
		[self.outletGraphTab setEnabled:NO forSegmentAtIndex:6];
	}
}

- (void)displayGraph
{
	UIViewController *viewController;

	for (viewController in self.childViewControllers)
		[self hideContentController:viewController];
	viewController = _GraphViews[self.outletGraphTab.selectedSegmentIndex];
	viewController.view.frame = self.outletGraphContainer.bounds;
	[self displayContentController:viewController];
}

- (void)displayContentController:(UIViewController *)content
{
	[self addChildViewController:content];
	[self.outletGraphContainer addSubview:content.view];
	[content didMoveToParentViewController:self];
}

- (void)hideContentController:(UIViewController *)content
{
	[content willMoveToParentViewController:nil];
	[content.view removeFromSuperview];
	[content removeFromParentViewController];
}

- (IBAction)changeGraphTab:(UISegmentedControl *)sender
{
	[self displayGraph];
}

- (BOOL)setFolderInfo
{
	CDbFolder dbFolder;

	_fScale = 1.0;

	if (_folderId != 0) {
		if (!dbFolder.Open())
			return NO;

		if (!dbFolder.ReadRecID(_folderId, &_dbFolderRec))
			return NO;

		if (_dbFolderRec.fScale != 0)
			_fScale = _dbFolderRec.fScale;
	}

	return YES;
}

- (BOOL)readData
{
	CDbImpulse dbImpulse;
	CDbAcParam dbAcParam;
	PWAVEDATA pWaveData;

//	_cPlayback.Stop();

	[self freeBuffers];

	if (!dbImpulse.Open())
		return NO;

	if (!dbAcParam.Open())
		return NO;

	if (!dbImpulse.ReadRecID(_impulseId, &_dbImpulseRec))
		return NO;

	if ((_hWaveData = MMWaveReadDB(dbImpulse, "WAVEDATA")) == NULL) {
		MessageBoxOK(self, NSLocalizedString(@"IDS_ERR_READDATA", nil), nil);
		return NO;
	}

	_nData = 1 << _dbImpulseRec.nMeasTime;

	_pWaveLeft = new float[_nData];
	_pIRLeft = new float[_nData];
	if (_dbImpulseRec.nChannel == 2) {
		_pWaveRight = new float[_nData];
		_pIRRight = new float[_nData];
	}

	pWaveData = (PWAVEDATA)_hWaveData;
	_nWaveData = ReadWaveData(_hWaveData, _pWaveLeft, _pWaveRight, _nData);

	_fRate = _dbImpulseRec.nSampling / _fScale;
	_nMethod = _dbImpulseRec.nBit & 0x03;

	if (dbAcParam.ReadRecID(_impulseId, &_dbAcParamRec)) {
		_fAdjustSPL = GetAdjustSPL(_folderId, _dbAcParamRec.dbAcParamCond.nSplRefData, _dbAcParamRec.dbAcParamCond.fSplRefLevel);
		_bCalculated = YES;
	} else {
		memset(&_dbAcParamRec, 0, sizeof(_dbAcParamRec));
		_fAdjustSPL = 0;
		_bCalculated = FALSE;
	}

//	[self initDispAcParamList];

//	[self dispCalcParam];

	if (_nMethod == METHOD_MSEQ)
		_pMethod = new CMSeq;
	else if (_nMethod == METHOD_TSP)
		_pMethod = new CTSP;

	_pMethod->InitMethod(_dbImpulseRec.bImpulseData ? 0 : _dbImpulseRec.nMeasTime);

	[self calcIR:_dbAcParamRec.dbAcParamData[_nCurrentDataNo].nFreq :_dbAcParamRec.dbAcParamCond.nFreqBand];

	self.title = _dbImpulseRec.sTitle;

	_bChangeData = NO;

	return TRUE;
}

- (void)freeBuffers
{
	if (_pWaveLeft != NULL) {
		delete [] _pWaveLeft;
		_pWaveLeft = NULL;
	}

	if (_pWaveRight != NULL) {
		delete [] _pWaveRight;
		_pWaveRight = NULL;
	}

	if (_pIRLeft != NULL) {
		delete [] _pIRLeft;
		_pIRLeft = NULL;
	}

	if (_pIRRight != NULL) {
		delete [] _pIRRight;
		_pIRRight = NULL;
	}

	if (_hWaveData != NULL) {
		delete [] _hWaveData;
		_hWaveData = NULL;
	}

	if (_pMethod != NULL) {
		delete _pMethod;
		_pMethod = NULL;
	}
}

- (void)calcIR:(int)nFreq :(int)freqBand
{
	int i;

	memcpy(_pIRLeft, _pWaveLeft, _nData * sizeof(float));

	if (_dbImpulseRec.nChannel == 2)
		memcpy(_pIRRight, _pWaveRight, _nData * sizeof(float));

	_pMethod->CalcImpulse(_pIRLeft);
	if (_dbImpulseRec.nChannel == 2)
		_pMethod->CalcImpulse(_pIRRight);

	if (_dbImpulseRec.bImpulseData) {
		for (i = 0; i < _nData; i++) {
			_pIRLeft[i] *= _nData;
			if (_dbImpulseRec.nChannel == 2)
				_pIRRight[i] *= _nData;
		}
	}

	CalcFilterAuto(_pIRLeft, _pIRRight, _nData, _fRate, nFreq, freqBand);
}

- (void)dispAcParamList
{
//	m_cParameterList.DeleteAllItems();

	if (!_bCalculated)
		return;

	[self.outletSpredView reloadData];
/*
	if (m_nParam == 0)
		DispAcParam1List();
	else
		DispAcParam2List();

	LVFINDINFO fi;
	fi.flags = LVFI_STRING;
	fi.psz = m_sCurrentFreq;
	m_nCurrentDataNo = m_cParameterList.FindItem(&fi);
	if (m_nCurrentDataNo == -1)
		m_nCurrentDataNo = 0;
	m_cParameterList.SetItemState(m_nCurrentDataNo, LVIS_SELECTED, LVIS_SELECTED);
*/
}

- (void)changeData
{
	[self dispAcParamList];

	[self redrawAll];

	_bChangeData = YES;
}

- (void)redrawAll
{
	[self.outletImpulseViewController redraw];
	[self.outletEchoViewController redraw];
	[self.outletIACCViewController redraw];
	[self.outletFreqViewController redraw];
	[self.outletPrefViewController redraw];
	[self.outletParamViewController redraw];
	[self.outletMtfViewController redraw];
}

static const NSString *tParam1Stereo[] = {
	@"SPL",
	@"SPL-L",
	@"SPL-R",
	@"Δt1",
	@"Δt1-L",
	@"Δt1-R",
	@"A",
	@"A-L",
	@"A-R",
	@"Tsub",
	@"Tsub-L",
	@"Tsub-R",
	@"IACC",
	@"τIACC",
	@"wIACC",
	@"S"
}, *tParam2Stereo[] = {
	@"G",
	@"G-L",
	@"G-R",
	@"T20",
	@"T20-L",
	@"T20-R",
	@"T30",
	@"T30-L",
	@"T30-R",
	@"Tc",
	@"Tc-L",
	@"Tc-R",
	@"EDT",
	@"EDT-L",
	@"EDT-R",
	@"C50",
	@"C50-L",
	@"C50-R",
	@"C80",
	@"C80-L",
	@"C80-R",
	@"Cc",
	@"Cc-L",
	@"Cc-R",
	@"D50",
	@"D50-L",
	@"D50-R",
	@"Ts",
	@"Ts-L",
	@"Ts-R",
	@"IACCE",
	@"IACCL"
}, *tParam1Mono[] = {
	@"SPL",
	@"Δt1",
	@"A-value",
	@"Tsub"
}, *tParam2Mono[] = {
	@"G",
	@"T20",
	@"T30",
	@"Tc",
	@"EDT",
	@"C50",
	@"C80",
	@"Cc",
	@"D50",
	@"Ts"
};

- (NSInteger)spreadView:(MDSpreadView *)aSpreadView numberOfColumnsInSection:(NSInteger)section
{
	if (_dbImpulseRec.nChannel == 1) {
		if (section == 0)
			return sizeof(tParam1Mono) / sizeof(NSString *);
		else
			return sizeof(tParam2Mono) / sizeof(NSString *);
	} else {
		if (section == 0)
			return sizeof(tParam1Stereo) / sizeof(NSString *);
		else
			return sizeof(tParam2Stereo) / sizeof(NSString *);
	}
}

- (NSInteger)spreadView:(MDSpreadView *)aSpreadView numberOfRowsInSection:(NSInteger)section
{
	return _dbAcParamRec.nDataNum;
}

- (NSInteger)numberOfColumnSectionsInSpreadView:(MDSpreadView *)aSpreadView
{
	return 2;
}

- (NSInteger)numberOfRowSectionsInSpreadView:(MDSpreadView *)aSpreadView
{
	return 1;
}

- (CGFloat)spreadView:(MDSpreadView *)aSpreadView heightForRowAtIndexPath:(MDIndexPath *)indexPath
{
	return 25; // 165 cells gives 60 fps. 250 cells gives 50 fps. 600 cells gives 25 fps
}

- (CGFloat)spreadView:(MDSpreadView *)aSpreadView heightForRowHeaderInSection:(NSInteger)rowSection
{
	return 22;
}

- (CGFloat)spreadView:(MDSpreadView *)aSpreadView heightForRowFooterInSection:(NSInteger)rowSection
{
	return 0;
}

- (CGFloat)spreadView:(MDSpreadView *)aSpreadView widthForColumnAtIndexPath:(MDIndexPath *)indexPath
{
	return 80;
}

- (CGFloat)spreadView:(MDSpreadView *)aSpreadView widthForColumnHeaderInSection:(NSInteger)columnSection
{
	return 70;
}

- (CGFloat)spreadView:(MDSpreadView *)aSpreadView widthForColumnFooterInSection:(NSInteger)columnSection
{
	return 0;
}

- (id)spreadView:(MDSpreadView *)aSpreadView titleForHeaderInRowSection:(NSInteger)rowSection forColumnSection:(NSInteger)columnSection
{
	return @"Freq.";
}

- (id)spreadView:(MDSpreadView *)aSpreadView titleForHeaderInRowSection:(NSInteger)section forColumnAtIndexPath:(MDIndexPath *)columnPath
{
	NSString const * const *cols;
 	if (_dbImpulseRec.nChannel == 1) {
		if (columnPath.section == 0)
			cols = tParam1Mono;
		else
			cols = tParam2Mono;
	} else {
		if (columnPath.section == 0)
			cols = tParam1Stereo;
		else
			cols = tParam2Stereo;
	}

	return cols[columnPath.column];
}

- (id)spreadView:(MDSpreadView *)aSpreadView titleForHeaderInColumnSection:(NSInteger)section forRowAtIndexPath:(MDIndexPath *)rowPath
{
	return GetDispFreq(_dbAcParamRec.dbAcParamData[rowPath.row].nFreq, _dbAcParamRec.dbAcParamCond.nFreqBand, NO);
}

- (MDSpreadViewCell *)spreadView:(MDSpreadView *)aSpreadView cellForRowAtIndexPath:(MDIndexPath *)rowPath forColumnAtIndexPath:(MDIndexPath *)columnPath
{
	static NSString *cellIdentifier = @"Cell";

	MDSpreadViewCell *cell = [aSpreadView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [[MDSpreadViewCell alloc] initWithStyle:MDSpreadViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.textLabel.textAlignment = NSTextAlignmentRight;
	}

	if (columnPath.section == 0)
		cell.textLabel.text = [self cellData1:rowPath.row :columnPath.column];
	else
		cell.textLabel.text = [self cellData2:rowPath.row :columnPath.column];

	//cell.textLabel.textColor = [UIColor colorWithRed:(arc4random()%100)/200. green:(arc4random()%100)/200. blue:(arc4random()%100)/200. alpha:1];

	return cell;
}

- (NSString *)cellData1:(NSInteger)row :(NSInteger)column
{
	DbAcParamData *pDbAcParamData = &_dbAcParamRec.dbAcParamData[row];
	NSString *str = @"";
	float s0;

	if (_dbImpulseRec.nChannel == 1) {
		switch (column) {
			case 0:
				str = [NSString stringWithFormat:@"%.2lf", pDbAcParamData->fSplL + _fAdjustSPL];
				break;
			case 1:
				if (pDbAcParamData->nFreq == FREQ_ALL) {
					str = [NSString stringWithFormat:@"%.2lf", _dbAcParamRec.dbAcParamResult.fDeltaT1L - _dbAcParamRec.dbAcParamResult.fDeltaT0L];
				}
				break;
			case 2:
				str = [NSString stringWithFormat:@"%.2lf", pDbAcParamData->fAL];
				break;
			case 3:
				str = [NSString stringWithFormat:@"%.3lf", pDbAcParamData->tSubL];
				break;
		}
	} else {
		switch (column) {
			case 0:
				str = [NSString stringWithFormat:@"%.2lf", MeanSPL(pDbAcParamData->fSplL, pDbAcParamData->fSplR) + _fAdjustSPL];
				break;
			case 1:
				str = [NSString stringWithFormat:@"%.2lf", pDbAcParamData->fSplL + _fAdjustSPL];
				break;
			case 2:
				str = [NSString stringWithFormat:@"%.2lf", pDbAcParamData->fSplR + _fAdjustSPL];
				break;
			case 3:
				if (pDbAcParamData->nFreq == FREQ_ALL) {
					str = [NSString stringWithFormat:@"%.2lf", MeanDT1(_dbAcParamRec.dbAcParamResult.fDeltaT1L - _dbAcParamRec.dbAcParamResult.fDeltaT0L, _dbAcParamRec.dbAcParamResult.fDeltaT1R - _dbAcParamRec.dbAcParamResult.fDeltaT0R)];
				}
				break;
			case 4:
				if (pDbAcParamData->nFreq == FREQ_ALL) {
					str = [NSString stringWithFormat:@"%.2lf", _dbAcParamRec.dbAcParamResult.fDeltaT1L - _dbAcParamRec.dbAcParamResult.fDeltaT0L];
				}
				break;
			case 5:
				if (pDbAcParamData->nFreq == FREQ_ALL) {
					str = [NSString stringWithFormat:@"%.2lf", _dbAcParamRec.dbAcParamResult.fDeltaT1R - _dbAcParamRec.dbAcParamResult.fDeltaT0R];
				}
				break;
			case 6:
				str = [NSString stringWithFormat:@"%.2lf", MeanA(pDbAcParamData->fAL, pDbAcParamData->fAR)];
				break;
			case 7:
				str = [NSString stringWithFormat:@"%.2lf", pDbAcParamData->fAL];
				break;
			case 8:
				str = [NSString stringWithFormat:@"%.2lf", pDbAcParamData->fAR];
				break;
			case 9:
				str = [NSString stringWithFormat:@"%.3lf", MeanTsub(pDbAcParamData->tSubL, pDbAcParamData->tSubR)];
				break;
			case 10:
				str = [NSString stringWithFormat:@"%.3lf", pDbAcParamData->tSubL];
				break;
			case 11:
				str = [NSString stringWithFormat:@"%.3lf", pDbAcParamData->tSubR];
				break;
			case 12:
				str = [NSString stringWithFormat:@"%.2lf", pDbAcParamData->fIACC];
				break;
			case 13:
				str = [NSString stringWithFormat:@"%.2lf", pDbAcParamData->tIACC];
				break;
			case 14:
				str = [NSString stringWithFormat:@"%.2lf", pDbAcParamData->wIACC];
				break;
			case 15:
				if (pDbAcParamData->nFreq == FREQ_ALL || pDbAcParamData->nFreq == FREQ_AFILTER) {
					if (CalcS0(&_dbAcParamRec, (int)row, _fAdjustSPL, &s0))
						str = [NSString stringWithFormat:@"%.2lf", s0];
					else
						str = @"----";
				}
				break;
		}
	}

	return str;
}

- (NSString *)cellData2:(NSInteger)row :(NSInteger)column
{
	DbAcParamData *pDbAcParamData = &_dbAcParamRec.dbAcParamData[row];
	NSString *str = @"";

	if (_dbImpulseRec.nChannel == 1) {
		switch (column) {
			case 0:
				str = [NSString stringWithFormat:@"%.2lf", pDbAcParamData->fG_L + _fAdjustSPL];
				break;
			case 1:
				str = [NSString stringWithFormat:@"%.3lf", pDbAcParamData->fT20_L];
				break;
			case 2:
				str = [NSString stringWithFormat:@"%.3lf", pDbAcParamData->fT30_L];
				break;
			case 3:
				str = [NSString stringWithFormat:@"%.3lf", pDbAcParamData->fTCustom_L];
				break;
			case 4:
				str = [NSString stringWithFormat:@"%.3lf", pDbAcParamData->fEDT_L];
				break;
			case 5:
				str = [NSString stringWithFormat:@"%.2lf", pDbAcParamData->fC50_L];
				break;
			case 6:
				str = [NSString stringWithFormat:@"%.2lf", pDbAcParamData->fC80_L];
				break;
			case 7:
				str = [NSString stringWithFormat:@"%.2lf", pDbAcParamData->fCCustom_L];
				break;
			case 8:
				str = [NSString stringWithFormat:@"%.3lf", pDbAcParamData->fD50_L];
				break;
			case 9:
				str = [NSString stringWithFormat:@"%.3lf", pDbAcParamData->fTs_L];
				break;
		}
	} else {
		switch (column) {
			case 0:
				str = [NSString stringWithFormat:@"%.2lf", MeanG(pDbAcParamData->fG_L, pDbAcParamData->fG_R) + _fAdjustSPL];
				break;
			case 1:
				str = [NSString stringWithFormat:@"%.2lf", pDbAcParamData->fG_L + _fAdjustSPL];
				break;
			case 2:
				str = [NSString stringWithFormat:@"%.2lf", pDbAcParamData->fG_R + _fAdjustSPL];
				break;
			case 3:
				str = [NSString stringWithFormat:@"%.3lf", MeanT(pDbAcParamData->fT20_L, pDbAcParamData->fT20_R)];
				break;
			case 4:
				str = [NSString stringWithFormat:@"%.3lf", pDbAcParamData->fT20_L];
				break;
			case 5:
				str = [NSString stringWithFormat:@"%.3lf", pDbAcParamData->fT20_R];
				break;
			case 6:
				str = [NSString stringWithFormat:@"%.3lf", MeanT(pDbAcParamData->fT30_L, pDbAcParamData->fT30_R)];
				break;
			case 7:
				str = [NSString stringWithFormat:@"%.3lf", pDbAcParamData->fT30_L];
				break;
			case 8:
				str = [NSString stringWithFormat:@"%.3lf", pDbAcParamData->fT30_R];
				break;
			case 9:
				str = [NSString stringWithFormat:@"%.3lf", MeanT(pDbAcParamData->fTCustom_L, pDbAcParamData->fTCustom_R)];
				break;
			case 10:
				str = [NSString stringWithFormat:@"%.3lf", pDbAcParamData->fTCustom_L];
				break;
			case 11:
				str = [NSString stringWithFormat:@"%.3lf", pDbAcParamData->fTCustom_R];
				break;
			case 12:
				str = [NSString stringWithFormat:@"%.3lf", MeanT(pDbAcParamData->fEDT_L, pDbAcParamData->fEDT_R)];
				break;
			case 13:
				str = [NSString stringWithFormat:@"%.3lf", pDbAcParamData->fEDT_L];
				break;
			case 14:
				str = [NSString stringWithFormat:@"%.3lf", pDbAcParamData->fEDT_R];
				break;
			case 15:
				str = [NSString stringWithFormat:@"%.2lf", MeanC(pDbAcParamData->fC50_L, pDbAcParamData->fC50_R)];
			case 16:
				str = [NSString stringWithFormat:@"%.2lf", pDbAcParamData->fC50_L];
				break;
			case 17:
				str = [NSString stringWithFormat:@"%.2lf", pDbAcParamData->fC50_R];
				break;
			case 18:
				str = [NSString stringWithFormat:@"%.2lf", MeanC(pDbAcParamData->fC80_L, pDbAcParamData->fC80_R)];
				break;
			case 19:
				str = [NSString stringWithFormat:@"%.2lf", pDbAcParamData->fC80_L];
				break;
			case 20:
				str = [NSString stringWithFormat:@"%.2lf", pDbAcParamData->fC80_R];
				break;
			case 21:
				str = [NSString stringWithFormat:@"%.2lf", MeanC(pDbAcParamData->fCCustom_L, pDbAcParamData->fCCustom_R)];
				break;
			case 22:
				str = [NSString stringWithFormat:@"%.2lf", pDbAcParamData->fCCustom_L];
				break;
			case 23:
				str = [NSString stringWithFormat:@"%.2lf", pDbAcParamData->fCCustom_R];
				break;
			case 24:
				str = [NSString stringWithFormat:@"%.2lf", MeanD(pDbAcParamData->fD50_L, pDbAcParamData->fD50_R)];
				break;
			case 25:
				str = [NSString stringWithFormat:@"%.2lf", pDbAcParamData->fD50_L];
				break;
			case 26:
				str = [NSString stringWithFormat:@"%.2lf", pDbAcParamData->fD50_R];
				break;
			case 27:
				str = [NSString stringWithFormat:@"%.3lf", MeanTs(pDbAcParamData->fTs_L, pDbAcParamData->fTs_R)];
				break;
			case 28:
				str = [NSString stringWithFormat:@"%.3lf", pDbAcParamData->fTs_L];
				break;
			case 29:
				str = [NSString stringWithFormat:@"%.3lf", pDbAcParamData->fTs_R];
				break;
			case 30:
				str = [NSString stringWithFormat:@"%.2lf", pDbAcParamData->fIACCE];
				break;
			case 31:
				str = [NSString stringWithFormat:@"%.2lf", pDbAcParamData->fIACCL];
				break;
		}
	}

	return str;
}

- (MDSpreadViewSelection *)spreadView:(MDSpreadView *)aSpreadView willHighlightCellWithSelection:(MDSpreadViewSelection *)selection
{
	return [MDSpreadViewSelection selectionWithRow:selection.rowPath column:selection.columnPath mode:MDSpreadViewSelectionModeRow];
}

- (MDSpreadViewSelection *)spreadView:(MDSpreadView *)aSpreadView willSelectCellWithSelection:(MDSpreadViewSelection *)selection
{
	return [MDSpreadViewSelection selectionWithRow:selection.rowPath column:selection.columnPath mode:MDSpreadViewSelectionModeRow];
}

- (void)spreadView:(MDSpreadView *)aSpreadView didSelectCellForRowAtIndexPath:(MDIndexPath *)rowPath forColumnAtIndexPath:(MDIndexPath *)columnPath
{
	if (_nCurrentDataNo != rowPath.row) {
		_nCurrentDataNo = (int)rowPath.row;
		//_sCurrentFreq = self.outletSpredView;
		[self calcIR:_dbAcParamRec.dbAcParamData[_nCurrentDataNo].nFreq :_dbAcParamRec.dbAcParamCond.nFreqBand];
		[self redrawAll];
	}
}

- (IBAction)onOutputCSV:(id)sender
{
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"data.csv"];
	FILE *fp;
	if ((fp = fopen([path UTF8String], "w")) != NULL) {
		fputs("Freq.", fp);
		for (int section = 0; section < 2; section++) {
			int numCols = (int)[self.outletSpredView numberOfColumnsInColumnSection:section];
			for (int col = 0; col < numCols; col++) {
				fprintf(fp, ",%s", [(NSString *)[self spreadView:self.outletSpredView titleForHeaderInRowSection:0 forColumnAtIndexPath:[MDIndexPath indexPathForColumn:col inSection:section]] UTF8String]);
			}
		}
		fputs("\r\n", fp);
		int numRows = (int)[self.outletSpredView numberOfRowsInRowSection:0];
		for (int row = 0; row < numRows; row++) {
			fputs([GetDispFreq(_dbAcParamRec.dbAcParamData[row].nFreq, _dbAcParamRec.dbAcParamCond.nFreqBand, NO) UTF8String], fp);
			for (int section = 0; section < 2; section++) {
				int numCols = (int)[self.outletSpredView numberOfColumnsInColumnSection:section];
				for (int col = 0; col < numCols; col++) {
					fprintf(fp, ",%s", [(section == 0 ? [self cellData1:row :col] : [self cellData2:row :col]) UTF8String]);
				}
			}
			fputs("\r\n", fp);
		}

		fclose(fp);

		NSURL *url = [NSURL fileURLWithPath:path];
		_diController = [UIDocumentInteractionController interactionControllerWithURL:url];
		[_diController presentOptionsMenuFromRect:self.outletSpredView.frame inView:self.view animated:YES];
	}
}

@end
