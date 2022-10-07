//
//  FftViewController.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/12.
//  Copyright (c) 2015年 aizawa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FftScaleView.h"
#import "FftDataView.h"
#import "FftCompareView.h"
#import "Common.h"
#import "Filter.h"
#import "SubViewController.h"
#import "CalibrationViewController.h"
#import "FileIO.h"
#import "AudioEx.h"

#define MAX_3DD	32
#define MAX_OCT	(MAX_OCT3*8)

#define VM_SINGLE	0
#define VM_OVERLAY	1
#define VM_SPLIT	2

#define CRF_RANGE	10

struct FFTDATA
{
    float *_pPowerSpecBuf;
    CAverageBuf _oPowerSpecBuf;
    float _fFftAllPower;
    CGPoint *_pPwsPoint;
    int _nPwsPointCount;
    int _nPwsDispFreq;
    int _nPwsFreqPos;
    int _nPwsLevelPos;
    float *_pPwsPeakLevel;
    CGPoint *_pPwsPeakPoint;
    int _nPwsPeakCount;
    float _fOctData[MAX_OCT];
    BOOL _bOctData;
    float _fOctPeakLevel[MAX_OCT];
    int _nOctDispBand;
    CGPoint *_p3ddPoint[MAX_3DD];
    int _n3ddPointCount[MAX_3DD];
    int _n3ddCurrentPtr;
    float *_pCrfBuf;
    CGPoint *_pCrfPoint;
    int _nCrfPointCount;
    int _nCrfDispTime;
    int _nCrfTimePos;
    int _nCrfLevelPos;
    float *_pCepBuf;
    CGPoint *_pCepPoint;
    int _nCepPointCount;
    int _nCepDispTime;
    int _nCepTimePos;
    int _nCepLevelPos;
    float *_pCepPeakLevel;
    CGPoint *_pCepPeakPoint;
    int _nCepPeakCount;
    UIImage *_pSpgImage;
};

@interface FftViewController : SubViewController <AudioInputData, FftScaleViewDelegate, FftDataViewDelegate, FftCompareViewDelegate, CalibrationViewDelegate>
{
    FftScaleView *_viewFftScale;
    FftDataView *_viewFftData1;
    FftDataView *_viewFftData2;
    FftCompareView *_viewCompare1;
    FftCompareView *_viewCompare2;
    CGSize _sizeGraphView;
    CGRect _rectGraphView;
    float *_pLeftWaveBuf;
    float *_pRightWaveBuf;
    int _nMode;
    int _nFrameLeft;
    int _nFrameTop;
    int _nFrameRight;
    int _nFrameBottom;
    int _nFrameWidth;
    int _nFrameHeight;
    int _nScaleWidth;
    int _nScaleHeight;
    int _nScaleWidth2;
    int _nScaleHeight2;
    
    BOOL _bStart;
    FFTDATA _aFftData[2];
    BOOL _bPeakReset;
    float _fFreqStep;
    float _fTimeStep2;
    float _fTimeStep;
    int _nViewMode;
    int _nCrfRange;
    BOOL _bLch;
    BOOL _bRch;
    int _nOctBand;
    NSMutableArray *_aFreqScale;
    char _bOctScaleFlag[MAX_OCT + 1];
    int _dx, _dy;
    int _nMaxFreq;
    int _nMinFreq;
    int _nMaxLevel;
    int _nMinLevel;
    int _nFftSize;
    int _nPeakHoldTimer;
    int _nBarWidth;
    int _nChannel;
    int _nSamplingRate;
    int *_p3ddCheckTbl;
    float *_pWindowFunc;
    float *_pFftBufL;
    float *_pFftBufR;
    float *_pFftBufM;
    float _fOctTbl[MAX_OCT + 1];
    float *_pFilterTblL;
    float *_pFilterTblR;
    float *_pPhaseBuf;
    float *_pSpgLevel;
    float *_pCoherenceBuf;
    float *_pCrossBufRe;
    float *_pCrossBufIm;
    float _fLogMaxFreq;
    float _fLogMinFreq;
    float _fOctBarStep;
    float _fLeftOffset, _fRightOffset;
    float _fSpgTimeStep;
    float *_pLogFreqTbl;
    CGPoint *_p3ddWork;
    CAverageBuf _oCrossBufRe;
    CAverageBuf _oCrossBufIm;
    CRFFT _oFFT;
    BOOL _bSmoothingReset;
    float _fSmoothing1;
    float _fSmoothing2;
    CGPoint *_pCrsPoint;
    int _nCrsPointCount;
    int _nCrsDispFreq;
    int _nCrsFreqPos;
    int _nCrsLevelPos;
    float *_pCrsPeakLevel;
    CGPoint *_pCrsPeakPoint;
    int _nCrsPeakCount;
    float *_pCrsBuf;
    float _fCrossAllPower;
    CGPoint *_pPhsPoint;
    int _nPhsPointCount;
    CGPoint *_pCohPoint;
    int _nCohPointCount;
    int _nPhsDispFreq;
    int _nPhsFreqPos;
    int _nPhsLevelPos;
    int _nCohDispFreq;
    int _nCohFreqPos;
    int _nCohLevelPos;
    UIColor *_colorLeft;
    UIColor *_colorLeftPeak;
    UIColor *_colorLeftLine;
    UIColor *_colorRight;
    UIColor *_colorRightPeak;
    UIColor *_colorRightLine;
    UIColor *_colorGreen;
    UIColor *_colorLightGreen;
    UIColor *_colorPhase;
    UIColor *_colorCross;
    UIColor *_colorCrossPeak;
    UIColor *_colorCoherence;
	UIColor *_colorWhite;
    UIColor *_colorBlack;
    UIColor *_colorGray;
    UIColor *_colorLightGray;
    UIColor *_colorText;
    UIColor *_colorOctBar;
    UIColor *_colorScaleBg;
    UIColor *_colorSaveLeft;
    UIColor *_colorSaveRight;
    UIColor *_colorSaveLightGreen;
    UIColor *_colorSaveCross;
    UIColor *_colorSaveCoherence;
    UIImage *_imageOctLeft;
    UIImage *_imageOctRight;
    UIImage *_imageOctPeakLeft;
    UIImage *_imageOctPeakRight;
    UIImage *_imageSaveOctLeft;
    UIImage *_imageSaveOctRight;
    NSDictionary *_fontAttrs;
	int _nWaveBufCount;
	BOOL _bWaveBufFill;
    float _fBlockTime;
    float _fTimeCount;
	DbMicCalRec _oMicCalDataL;
	DbMicCalRec _oMicCalDataR;
}

@property (nonatomic, weak) IBOutlet UIView *outletBaseView;
@property (nonatomic, weak) IBOutlet UIView *outletGraphView;
@property (nonatomic, weak) IBOutlet UIScrollView *outletScrollView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletMode;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletMode2;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletOnOff;
@property (nonatomic, weak) IBOutlet CtComboBox *outletSampleRate;
@property (nonatomic, weak) IBOutlet CtComboBox *outletFftSize;
@property (nonatomic, weak) IBOutlet CtComboBox *outletWindowFunction;
@property (nonatomic, weak) IBOutlet CtComboBox *outletChannel;
@property (nonatomic, weak) IBOutlet CtComboBox *outletFilter;
@property (nonatomic, weak) IBOutlet CtComboBox *outletSmoothing;
@property (nonatomic, weak) IBOutlet CtComboBox *outletAverage;
@property (nonatomic, weak) IBOutlet CtComboBox *outletTimeResolution;
@property (nonatomic, weak) IBOutlet CtComboBox *outletTimeRange;
@property (nonatomic, weak) IBOutlet CtComboBox *outletTimeDataNum;
@property (nonatomic, weak) IBOutlet CtComboBox *outletOctaveBand;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletFreqScale;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletTimeDir;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletColorScale;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletCorrelation;
@property (nonatomic, weak) IBOutlet UISegmentedControl *outletPeakHoldMode;
@property (nonatomic, weak) IBOutlet UISwitch *outletLRSplit;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletAutoLevel;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletAutoFreq;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletPeakDisp;
@property (nonatomic, weak) IBOutlet CtCheckBox *outletPeakHold;
@property (nonatomic, weak) IBOutlet CtTextField *outletMaxLevel;
@property (nonatomic, weak) IBOutlet CtTextField *outletMinLevel;
@property (nonatomic, weak) IBOutlet CtTextField *outletMaxFreq;
@property (nonatomic, weak) IBOutlet CtTextField *outletMinFreq;
@property (nonatomic, weak) IBOutlet CtTextField *outletAutoStop;
@property (nonatomic, weak) IBOutlet CtTextField *outletPeakHoldTime;
@property (nonatomic, weak) IBOutlet CtTextField *outletPeakLevelLeft;
@property (nonatomic, weak) IBOutlet CtTextField *outletPeakLevelRight;
@property (nonatomic, weak) IBOutlet CtTextField *outletPeakFreqLeft;
@property (nonatomic, weak) IBOutlet CtTextField *outletPeakFreqRight;
@property (nonatomic, weak) IBOutlet CtButton *outletPeakReset;
@property (nonatomic, weak) IBOutlet CtButton *outletDispMode;
@property (nonatomic, weak) IBOutlet CtSlider *outletCrfZoom;
@property (nonatomic, weak) IBOutlet CtGroupBox *outletPeakFreq;
@property (nonatomic, weak) IBOutlet CtGroupBox *outletPeakLevel;
@property (nonatomic, weak) IBOutlet CtTextField *outletMicCal;
@property (nonatomic, weak) IBOutlet CtButton *outletCompare;
@property (nonatomic, weak) IBOutlet CtButton *outletErase;

- (void)drawNote:(NSString *)text :(int)top :(int)right;
- (void)setDispMode;

@end
