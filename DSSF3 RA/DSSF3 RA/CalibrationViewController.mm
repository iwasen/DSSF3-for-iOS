//
//  CalibrationViewController.m
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2016/12/14.
//  Copyright © 2016年 TRC. All rights reserved.
//

#import "CalibrationViewController.h"
#import "Common.h"
#import "Global.h"
#import "FileIO.h"
#import "Filter.h"
#import "AudioEx.h"

#define SAMPLING_RATE	48000
#define NFREQ_RATE	44100
#define NFREQ_MIN	20
#define NFREQ_MAX	(NFREQ_RATE / 2)
#define NFFT_SIZE	4096
#define WAVEBUF_SAMPLESPERBUFFER	8192
#define WAVEBUF_NUM		4
#define MIN_LEVEL_BAR	600
#define MAX_LEVEL_BAR	1400
#define N_MEAN	5

@interface MicCalList : NSObject
@property (nonatomic) int nMicCalID;
@property (nonatomic, retain) NSString *sMicInfo;
@end

@implementation MicCalList
@end

@interface FreqList : NSObject
@property (nonatomic) float fFreq;
@property (nonatomic) float fLevel;
@end

@implementation FreqList
@end

@interface CalibrationViewController () <UITableViewDelegate, UITableViewDataSource, AudioInputData, AudioOutputData, GraphViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *outletMicCalList;
@property (nonatomic, weak) IBOutlet UISwitch *outletSignalOut;
@property (nonatomic, weak) IBOutlet CtTextField *outletMicInfo;
@property (nonatomic, weak) IBOutlet CtTextField *outletMicAmpInfo;
@property (nonatomic, weak) IBOutlet CtTextField *outletComment;
@property (nonatomic, weak) IBOutlet CtComboBox *outletFilter;
@property (nonatomic, weak) IBOutlet UISlider *outletLevelBar;
@property (nonatomic, weak) IBOutlet UITextField *outletInputLevel;
@property (nonatomic, weak) IBOutlet FreqView *outletFreqResponse;
@property (nonatomic, weak) IBOutlet UITableView *outletFreqList;
@property (nonatomic, weak) IBOutlet CtTextField *outletLevel;
@property (nonatomic, weak) IBOutlet CtTextField *outletFreq;

@end

@implementation CalibrationViewController
{
    int _nSortItem;
    int _nSortDir;
    float _fAngle;
    NSMutableArray *_pMicCalList;
    NSMutableArray *_pFreqList;
    BOOL _bUpdate;
    float *_pFreqData;
    float *_pFilterTbl;
    float _fInputSens;
    CRFFT _oRFFT;
    float _fMeanBuf[N_MEAN];
    int _nMeanBufPtr;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
	_nSortItem = -1;
	_fAngle = 0;
	_pMicCalList = [[NSMutableArray alloc] init];
	_pFreqList = [[NSMutableArray alloc] init];

	memset(_fMeanBuf, 0, sizeof(_fMeanBuf));
	_nMeanBufPtr = 0;
	_fInputSens = 100;

	self.outletMicCalList.delegate = self;
	self.outletFreqList.delegate = self;

	[self setMicCalList];

	[self initFreqList];

	for (int i = 0; i < _pMicCalList.count; i++) {
		MicCalList *micCalList = [_pMicCalList objectAtIndex:i];
		if (micCalList.nMicCalID == self.nMicCalID) {
			[self.outletMicCalList selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
			[self readMicCalData:self.nMicCalID];
			break;
		}
	}

	self.outletLevelBar.minimumValue = MIN_LEVEL_BAR;
	self.outletLevelBar.maximumValue = MAX_LEVEL_BAR;
	self.outletLevelBar.value = _fInputSens * 10;

	SetFilterNameList(self.outletFilter);
	self.outletFilter.selectedIndex = 0;

	_pFreqData = new float[NFFT_SIZE];
	_pFilterTbl = new float[WAVEBUF_SAMPLESPERBUFFER];

	[self.outletFreqResponse initialize:nil :0 :[[UIColor alloc] RGB(255, 0, 0)] :14.0];
	self.outletFreqResponse.enabled = YES;
	[self dispFreqWindow];

	[AudioInputEx prepare:SAMPLING_RATE :NUM_CHANNELS_1 :WAVEBUF_SAMPLESPERBUFFER :self];
	[AudioInputEx start];

	_bUpdate = FALSE;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)viewWillDisappear:(BOOL)animated
{
	[AudioOutputEx stop];
	[AudioInputEx stop];
}

-(void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];

	if (IS_PHONE) {
		SetContentSize(self.outletScrollView);
	}
}

- (void)dealloc
{
	if (_pFreqData != NULL) {
		delete [] _pFreqData;
		_pFreqData = NULL;
	}

	if (_pFilterTbl != NULL) {
		delete [] _pFilterTbl;
		_pFilterTbl = NULL;
	}
}

- (void)setMicCalList
{
	CDbMicCal dbMicCal;
	DbMicCalRec dbMicCalRec;

	if (!dbMicCal.Open())
		return;

	[_pMicCalList removeAllObjects];

	while (dbMicCal.ReadRecNext(&dbMicCalRec)) {
		if (dbMicCalRec.nMicCalID >= 0) {
			MicCalList *pMicCalList = [[MicCalList alloc] init];
			pMicCalList.nMicCalID = dbMicCalRec.nMicCalID;
			pMicCalList.sMicInfo = dbMicCalRec.sMicInfo;
			[_pMicCalList addObject:pMicCalList];
		}
	}

	[self sortMicCalList];

	[self.outletMicCalList reloadData];
}

- (IBAction)onRegist:(CtButton *)sender
{
	MessageBoxOKCalcel(self, NSLocalizedString(@"IDS_MSG_SAVEMICCAL", nil), ^(UIAlertAction *action) {
		if (self.outletMicInfo.text.length == 0) {
			MessageBoxOK(self, NSLocalizedString(@"IDS_MSG_INPUTMICINFO", nil), nil);
			return;
		}

		[self registMicCalData:0];

		[self setMicCalList];
		[self setTabCtrl];
	}, nil);
}

- (IBAction)onChange:(id)sender
{
	int index;

	if ((index = [self getCurSel]) == -1) {
		MessageBoxOK(self, NSLocalizedString(@"IDS_MSG_SELECTMICCAL", nil), nil);
		return;
	}

	MessageBoxOKCalcel(self, NSLocalizedString(@"IDS_MSG_CHANGEMICCAL", nil), ^(UIAlertAction *action) {
		if (self.outletMicInfo.text.length == 0) {
			MessageBoxOK(self, NSLocalizedString(@"IDS_MSG_INPUTMICINFO", nil), nil);
			return;
		}

		int nMicCalID = ((MicCalList *)[self->_pMicCalList objectAtIndex:index]).nMicCalID;

		[self changeMicCalData:nMicCalID];
		/* 右チャネル設定（ペンディング）
		 if (m_pMicCalR != NULL)
		 m_pMicCalR->ChangeMicCalData(MICCAL_RIGHT(nMicCalID));
		 else {
		 CDbMicCal dbMicCal;

		 if (dbMicCal.Open())
			dbMicCal.DeleteID(MICCAL_RIGHT(nMicCalID));
		 }
		 */
		[self setMicCalList];
		[self setCurSel:index];
	}, nil);
}

- (IBAction)onDelete:(id)sender
{
	int index;

	if ((index = [self getCurSel]) == -1) {
		MessageBoxOK(self, NSLocalizedString(@"IDS_MSG_SELECTMICCAL", nil), nil);
		return;
	}

	MessageBoxOKCalcel(self, NSLocalizedString(@"IDS_MSG_DELTEMICCAL", nil), ^(UIAlertAction *action) {
		CDbMicCal dbMicCal;

		if (!dbMicCal.Open())
			return;

		int nMicCalID = ((MicCalList *)[self->_pMicCalList objectAtIndex:index]).nMicCalID;

		dbMicCal.DeleteID(nMicCalID);
/* 右チャネル設定（ペンディング）
		dbMicCal.DeleteID(MICCAL_RIGHT(nMicCalID));
*/
		[self setMicCalList];
	}, nil);
}

- (int)getCurSel
{
	for (int i = 0; i < [self.outletMicCalList numberOfRowsInSection:0]; i++) {
		UITableViewCell *cell = [self.outletMicCalList cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
		if (cell.selected)
			return i;
	}

	return -1;
}

- (void)setCurSel:(int)index
{
	[self.outletMicCalList selectRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger count = 0;

	if (tableView == self.outletMicCalList)
		count = _pMicCalList.count;
	else if (tableView == self.outletFreqList)
		count = _pFreqList.count;

	return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"Cell";
	UITableViewCell *cell = nil;

	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];

	if (tableView == self.outletMicCalList) {
		MicCalList *data = [_pMicCalList objectAtIndex:indexPath.row];
		cell.textLabel.text = data.sMicInfo;
	} else if (tableView == self.outletFreqList) {
		FreqList *data = [_pFreqList objectAtIndex:indexPath.row];
		cell.textLabel.text = [NSString stringWithFormat:@"%gHz - %gdB", data.fFreq, data.fLevel];
		cell.backgroundColor = [UIColor groupTableViewBackgroundColor];
	}

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == self.outletMicCalList) {
		[self setTabCtrl];
	} else if (tableView == self.outletFreqList) {
		FreqList *freqList = [_pFreqList objectAtIndex:indexPath.row];
		self.outletFreq.floatValue = freqList.fFreq;
		self.outletLevel.floatValue = freqList.fLevel;
	}
}

- (IBAction)onRead:(id)sender
{
	int index;

	if ((index = [self getCurSel]) == -1) {
		MessageBoxOK(self, NSLocalizedString(@"IDS_MSG_SELECTMICCAL", nil), nil);
		return;
	}

	[self saveCheck];

	MicCalList *micCalList = [_pMicCalList objectAtIndex:index];
	[self.delegate setMicCalID:micCalList.nMicCalID];

	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onReset:(id)sender
{
	[self.delegate setMicCalID:-1];

	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onCancel:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onSignalOut:(id)sender
{
	if (self.outletSignalOut.isOn) {
		_fAngle = 0;
		[AudioOutputEx prepare:SAMPLING_RATE :NUM_CHANNELS_1 :WAVEBUF_SAMPLESPERBUFFER :self];
		[AudioOutputEx start];
	} else
		[AudioOutputEx stop];
}

- (void)audioOutputData:(AudioData *)audioData
{
	float fAngleStep = 1000.0 / SAMPLING_RATE;
	float *pWaveBuf = audioData->pLeftData;
	int i;
	float s;

	for (i = 0; i < WAVEBUF_SAMPLESPERBUFFER; i++) {
		s = sin(2 * M_PI * _fAngle);
		*pWaveBuf++ = s;
		_fAngle += fAngleStep;
		while (_fAngle >= 1.0)
			_fAngle -= 1.0;
	}

	audioData->nDataSize = WAVEBUF_SAMPLESPERBUFFER;
}

- (void)saveCheck
{
	int index;

	if ((index = [self getCurSel]) == -1)
		return;

	MicCalList *micCalList = [_pMicCalList objectAtIndex:index];
	int nMicCalID = micCalList.nMicCalID;

	if (_bUpdate) {
		MessageBoxOKCalcel(self, NSLocalizedString(@"IDS_MSG_CHANGEDATA", nil), ^(UIAlertAction *action) {
			[self changeMicCalData:nMicCalID];
		}, nil);
	}
}

- (void)setTabCtrl
{
	int index;
	int nMicCalID;

	if ((index = [self getCurSel]) != -1) {
		MicCalList *micCalList = [_pMicCalList objectAtIndex:index];
		nMicCalID = micCalList.nMicCalID;
	} else
		nMicCalID = -1;

	if (nMicCalID != -1)
		[self readMicCalData:nMicCalID];
}

- (void)initFreqList
{
	static float initFreq[] = {10, 100, 1000, 10000};

	for (int i = 0; i < sizeof(initFreq) / sizeof(float); i++) {
		FreqList *freqList = [[FreqList alloc] init];
		freqList.fFreq = initFreq[i];
		freqList.fLevel = 0;
		[_pFreqList addObject:freqList];
	}
}

- (void)readMicCalData:(int)nMicCalID
{
	CDbMicCal dbMicCal;
	DbMicCalRec dbMicCalRec;
	int i;

	if (!dbMicCal.Open())
		return;

	if (!dbMicCal.SearchRecID(nMicCalID))
		return;

	if (!dbMicCal.ReadRecID(nMicCalID, &dbMicCalRec))
		return;

	self.outletMicInfo.text = dbMicCalRec.sMicInfo;
	self.outletMicAmpInfo.text = dbMicCalRec.sMicAmpInfo;
	self.outletComment.text = dbMicCalRec.sComment;
	_fInputSens = -dbMicCalRec.fInputSens;

	self.outletLevelBar.value = _fInputSens * 10;

	[_pFreqList removeAllObjects];
	for (i = 0; i < dbMicCalRec.nFreqData; i++) {
		FreqList *freqList = [[FreqList alloc] init];
		freqList.fFreq = dbMicCalRec.aFreq[i].freq;
		freqList.fLevel = dbMicCalRec.aFreq[i].level;
		[_pFreqList addObject:freqList];
	}

	[self sortFreqList];

	[self.outletFreqList reloadData];

	if (_pFreqData != NULL)
		[self dispFreqWindow];
/* マイクのレベル設定（ペンディング）
	CRtaApp *pWinApp = (CRtaApp *)AfxGetApp();
	pWinApp->m_pWndRta->SetInputDevice(dbMicCalRec.nInputSel, dbMicCalRec.nInputVol);
*/
	_bUpdate = FALSE;
}

- (int)registMicCalData:(int)nMicCalID
{
	CDbMicCal dbMicCal;
	DbMicCalRec dbMicCalRec;

	if (!dbMicCal.Open())
		return -1;

	if (nMicCalID < 0)
		dbMicCalRec.nMicCalID = nMicCalID;
	else {
		if (!dbMicCal.GetNewID(&dbMicCalRec.nMicCalID))
			return -1;
	}

	[self getMicCalData:&dbMicCalRec];

	dbMicCal.StoreRec(&dbMicCalRec);
	_bUpdate = FALSE;

	return dbMicCalRec.nMicCalID;
}

- (void)changeMicCalData:(int)nMicCalID
{
	CDbMicCal dbMicCal;
	DbMicCalRec dbMicCalRec;

	if (!dbMicCal.Open())
		return;

	dbMicCalRec.nMicCalID = nMicCalID;
	[self getMicCalData:&dbMicCalRec];

	dbMicCal.UpdateRec(&dbMicCalRec);
	_bUpdate = FALSE;
}

- (IBAction)onFreqRegist:(id)sender
{
	float freq = self.outletFreq.floatValue;
	if (freq <= 0) {
		MessageBoxOK(self, NSLocalizedString(@"IDS_MSG_UNDER0FREQ", nil), nil);
		return;
	}

	FreqList *freqList = nil;
	BOOL find = false;
	for (int i = 0; i < _pFreqList.count; i++) {
		freqList = [_pFreqList objectAtIndex:i];
		if (freqList.fFreq == freq) {
			find = true;
			break;
		}
	}
	if (!find) {
		if (_pFreqList.count == MICCAL_NFREQ) {
			MessageBoxOK(self, [NSString stringWithFormat:NSLocalizedString(@"IDS_MSG_INPUTNDATA", nil), MICCAL_NFREQ], nil);
			return;
		}
		freqList = [[FreqList alloc] init];
		freqList.fFreq = self.outletFreq.floatValue;
		freqList.fLevel = self.outletLevel.floatValue;
		[_pFreqList addObject:freqList];
	} else {
		freqList.fLevel = self.outletLevel.floatValue;
	}

	[self sortFreqList];

	[self.outletFreqList reloadData];

	[self dispFreqWindow];

	_bUpdate = TRUE;
}

- (IBAction)onFreqDelete:(id)sender
{
	float freq = self.outletFreq.floatValue;
	for (int i = 0; i < _pFreqList.count; i++) {
		FreqList *freqList = [_pFreqList objectAtIndex:i];
		if (freqList.fFreq == freq) {
			[_pFreqList removeObjectAtIndex:i];

			[self.outletFreqList reloadData];

			[self dispFreqWindow];

			_bUpdate = TRUE;
			break;
		}
	}
}

- (void)dispFreqWindow
{
	[self makeFreqData];
	[self.outletFreqResponse setNeedsDisplay];
}
- (void)drawGraphData:(CGContextRef)context :(id)sender
{
	if (sender == self.outletFreqResponse)
		[self.outletFreqResponse dispGraph:context :_pFreqData :NFFT_SIZE :NFREQ_RATE :NFREQ_MIN :NFREQ_MAX :-20 :20 :FALSE];
}

- (void)makeFreqData
{
	FilterData micCalData[MICCAL_NFREQ];

	int nItem = (int)_pFreqList.count;
	for (int i = 0; i < _pFreqList.count; i++) {
		FreqList *freqList = [_pFreqList objectAtIndex:i];
		micCalData[i].fFreq = freqList.fFreq;
		micCalData[i].fLevel = freqList.fLevel;
	}

	MakeFilterTbl3(_pFreqData, NFFT_SIZE, NFREQ_RATE, micCalData, nItem, 10);

	[self setFilter:micCalData :nItem];
}

- (void)getMicCalData:(DbMicCalRec *)pDbMicCalRec
{
	pDbMicCalRec->sMicInfo = self.outletMicInfo.text;
	pDbMicCalRec->sMicAmpInfo = self.outletMicAmpInfo.text;
	pDbMicCalRec->sComment = self.outletComment.text;
	pDbMicCalRec->fInputSens = -_fInputSens;
/* マイク設定（ペンディング）
	CRtaApp *pWinApp = (CRtaApp *)AfxGetApp();
	int nInputDevice, nInputVolume;
	pWinApp->m_pWndRta->GetInputDevice(&nInputDevice, &nInputVolume);
	pDbMicCalRec->nInputSel = nInputDevice;
	pDbMicCalRec->nInputVol = nInputVolume;
*/
	pDbMicCalRec->nFreqData = [self getFreqData:(FilterData *)pDbMicCalRec->aFreq];
}

- (int)getFreqData:(FilterData *)pFilterData
{
	int nFreqData;
	int i;

	nFreqData = (int)_pFreqList.count;
	for (i = 0; i < nFreqData; i++) {
		FreqList *freqList = [_pFreqList objectAtIndex:i];
		pFilterData->fFreq = freqList.fFreq;
		pFilterData->fLevel = freqList.fLevel;
		pFilterData++;
	}

	for ( ; i < MICCAL_NFREQ; i++) {
		pFilterData->fFreq = 0;
		pFilterData->fLevel = 0;
		pFilterData++;
	}

	return nFreqData;
}

- (IBAction)onChangeMicInfo:(id)sender
{
	_bUpdate = TRUE;
}

- (void)audioInputData:(AudioData *)audioData
{
	int i, j;
	float xt, yt;
	float fPower;
	float fftBuf[WAVEBUF_SAMPLESPERBUFFER];

	for (i = 0; i < WAVEBUF_SAMPLESPERBUFFER; i++) {
		fftBuf[i] = audioData->pLeftData[i];
	}

	_oRFFT.fft(WAVEBUF_SAMPLESPERBUFFER, fftBuf);

	fPower = 0;
	for (i = 1; i < WAVEBUF_SAMPLESPERBUFFER / 2; i++) {
		j = i * 2;

		xt = fftBuf[j] * _pFilterTbl[i];
		yt = fftBuf[j + 1] * _pFilterTbl[i];

		fPower += xt * xt + yt * yt;
	}

	_fMeanBuf[_nMeanBufPtr] = fPower * 4;
	if (++_nMeanBufPtr >= N_MEAN)
		_nMeanBufPtr = 0;

	fPower = 0;
	for (i = 0; i < N_MEAN; i++)
		fPower += _fMeanBuf[i];

	fPower /= N_MEAN;

	if (fPower > 0)
		self.outletInputLevel.text = [NSString stringWithFormat:@"%.1lf", dB10(fPower) + _fInputSens];
}

- (IBAction)onSlider:(id)sender
{
	if (sender == self.outletLevelBar) {
		_fInputSens = self.outletLevelBar.value / 10.0;
	}
}

- (void)setFilter:(const FilterData *)pFilterData :(int)nFilterData
{
	int i;

	MakeFilterTbl3(_pFilterTbl, WAVEBUF_SAMPLESPERBUFFER, SAMPLING_RATE, pFilterData, nFilterData, 20);
	_pFilterTbl[0] = 0;
	for (i = 1; i < WAVEBUF_SAMPLESPERBUFFER; i++)
		_pFilterTbl[i] = 1 / (_pFilterTbl[i] * WAVEBUF_SAMPLESPERBUFFER);

	int nFilter = self.outletFilter.selectedIndex;
	if (nFilter != 0) {
		float *pFilter = new float[WAVEBUF_SAMPLESPERBUFFER];
		MakeFilterTbl2(pFilter, WAVEBUF_SAMPLESPERBUFFER, SAMPLING_RATE, nFilter, 20);
		for (i = 0; i < WAVEBUF_SAMPLESPERBUFFER; i++)
			_pFilterTbl[i] *= pFilter[i];
		delete [] pFilter;
	}
}

- (IBAction)onSelchangeFilter:(id)sender
{
	[self makeFreqData];
}

- (void)sortMicCalList
{
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self.sMicInfo" ascending:YES];
	_pMicCalList = [NSMutableArray arrayWithArray:[_pMicCalList sortedArrayUsingDescriptors:@[sortDescriptor]]];
}

- (void)sortFreqList
{
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self.fFreq" ascending:YES];
	_pFreqList = [NSMutableArray arrayWithArray:[_pFreqList sortedArrayUsingDescriptors:@[sortDescriptor]]];
}

@end
