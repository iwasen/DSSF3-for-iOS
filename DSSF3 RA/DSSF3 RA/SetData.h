//
//  SetData.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/18.
//  Copyright (c) 2015年 aizawa. All rights reserved.
//

#import <UIKit/UIKit.h>

#define N_SG_PRESET		4
#define N_SG_COMPONENT	8

@interface SetDataObject : NSObject
{
    NSUserDefaults *_ud;
}
@end

@interface SetDataSg : SetDataObject

@property (nonatomic, setter=nMode:) int nMode;
@property (nonatomic, setter=nSampleRate:) int nSampleRate;
@property (nonatomic, setter=nLevelL:) int nLevelL;
@property (nonatomic, setter=nLevelR:) int nLevelR;
@property (nonatomic, setter=bRendou:) BOOL bRendou;
@property (nonatomic, setter=fFreqL:) float fFreqL;
@property (nonatomic, setter=fFreqR:) float fFreqR;
@property (nonatomic, setter=bRendouF:) BOOL bRendouF;
@property (nonatomic, setter=nFreqRange:) int nFreqRange;
@property (nonatomic, setter=nToneWave:) int nToneWave;
@property (nonatomic, setter=fPresetFreq1:) float fPresetFreq1;
@property (nonatomic, setter=fPresetFreq2:) float fPresetFreq2;
@property (nonatomic, setter=fPresetFreq3:) float fPresetFreq3;
@property (nonatomic, setter=fPresetFreq4:) float fPresetFreq4;
@property (nonatomic, setter=nPhase:) int nPhase;
@property (nonatomic, setter=nNoiseType:) int nNoiseType;
@property (nonatomic, setter=nNoiseMode:) int nNoiseMode;
@property (nonatomic, setter=fTimeDiff:) float fTimeDiff;
@property (nonatomic, setter=fStartFreq:) float fStartFreq;
@property (nonatomic, setter=fEndFreq:) float fEndFreq;
@property (nonatomic, setter=fSweepSpeed:) float fSweepSpeed;
@property (nonatomic, setter=bSweepLoop:) BOOL bSweepLoop;
@property (nonatomic, setter=nSweepWave:) int nSweepWave;
@property (nonatomic, setter=nPulseWidth:) int nPulseWidth;
@property (nonatomic, setter=nPulsePolarity:) int nPulsePolarity;
@property (nonatomic, setter=nPulseNum:) int nPulseNum;
@property (nonatomic, setter=bPulseContinue:) BOOL bPulseContinue;
@property (nonatomic, setter=fPulseCycle:) float fPulseCycle;
@property (nonatomic, setter=fReferencePitch:) float fReferencePitch;
@property (nonatomic, setter=nScale:) int nScale;
@property (nonatomic, setter=nOctave:) int nOctave;
@property (nonatomic, setter=nScaleWave:) int nScaleWave;
@property (nonatomic, setter=bPlayMode:) BOOL bPlayMode;
@property (nonatomic, setter=fCompFreq1:) float fCompFreq1;
@property (nonatomic, setter=fCompFreq2:) float fCompFreq2;
@property (nonatomic, setter=fCompFreq3:) float fCompFreq3;
@property (nonatomic, setter=fCompFreq4:) float fCompFreq4;
@property (nonatomic, setter=fCompFreq5:) float fCompFreq5;
@property (nonatomic, setter=fCompFreq6:) float fCompFreq6;
@property (nonatomic, setter=fCompFreq7:) float fCompFreq7;
@property (nonatomic, setter=fCompFreq8:) float fCompFreq8;
@property (nonatomic, setter=nCompLevel1:) int nCompLevel1;
@property (nonatomic, setter=nCompLevel2:) int nCompLevel2;
@property (nonatomic, setter=nCompLevel3:) int nCompLevel3;
@property (nonatomic, setter=nCompLevel4:) int nCompLevel4;
@property (nonatomic, setter=nCompLevel5:) int nCompLevel5;
@property (nonatomic, setter=nCompLevel6:) int nCompLevel6;
@property (nonatomic, setter=nCompLevel7:) int nCompLevel7;
@property (nonatomic, setter=nCompLevel8:) int nCompLevel8;
@property (nonatomic, setter=fSynthFreq:) float fSynthFreq;
@property (nonatomic, setter=nSynthWave:) int nSynthWave;
@property (nonatomic, setter=fWaveFreq:) float fWaveFreq;
@property (nonatomic, setter=nWaveFormNo:) int nWaveFormNo;
@property (nonatomic, setter=nTimeRange:) int nTimeRange;
@property (nonatomic, setter=fSweepTime:) float fSweepTime;
@property (nonatomic, setter=fStartLevel:) float fStartLevel;
@property (nonatomic, setter=fEndLevel:) float fEndLevel;

@end

@interface SetDataFft : SetDataObject

@property (nonatomic, setter=bShowSettings:) BOOL bShowSettings;
@property (nonatomic, setter=nSampleRate:) int nSampleRate;
@property (nonatomic, setter=nMode:) int nMode;
@property (nonatomic, setter=nChannel:) int nChannel;
@property (nonatomic, setter=bAutoFreq:) BOOL bAutoFreq;
@property (nonatomic, setter=nMinFreq:) int nMinFreq;
@property (nonatomic, setter=nMaxFreq:) int nMaxFreq;
@property (nonatomic, setter=bAutoLevel:) BOOL bAutoLevel;
@property (nonatomic, setter=nMinLevel:) int nMinLevel;
@property (nonatomic, setter=nMaxLevel:) int nMaxLevel;
@property (nonatomic, setter=nFftScale:) int nFftScale;
@property (nonatomic, setter=nSmoothing:) int nSmoothing;
@property (nonatomic, setter=nWindowFunc:) int nWindowFunc;
@property (nonatomic, setter=nFftSize:) int nFftSize;
@property (nonatomic, setter=bPeakDisp:) BOOL bPeakDisp;
@property (nonatomic, setter=bPeakHold:) BOOL bPeakHold;
@property (nonatomic, setter=nPeakHoldMode:) int nPeakHoldMode;
@property (nonatomic, setter=nPeakHoldTime:) int nPeakHoldTime;
@property (nonatomic, setter=nTimeDir:) int nTimeDir;
@property (nonatomic, setter=nTimeDataNum:) int nTimeDataNum;
@property (nonatomic, setter=nCorrelation:) int nCorrelation;
@property (nonatomic, setter=nMicCalID:) int nMicCalID;
@property (nonatomic, setter=nFilter:) int nFilter;
@property (nonatomic, setter=bRlSplit:) BOOL bRlSplit;
@property (nonatomic, setter=nCrfZoom:) int nCrfZoom;
@property (nonatomic, setter=nTimeRes:) int nTimeRes;
@property (nonatomic, setter=nAverage:) int nAverage;
@property (nonatomic, setter=nOctaveBand:) int nOctaveBand;
@property (nonatomic, setter=nTimeRange:) int nTimeRange;
@property (nonatomic, setter=nColorScale:) int nColorScale;
@property (nonatomic, setter=nAutoStopTime:) int nAutoStopTime;

@end

@interface SetDataOs : SetDataObject

@property (nonatomic, setter=bShowSettings:) BOOL bShowSettings;
@property (nonatomic, setter=nSampleRate:) int nSampleRate;
@property (nonatomic, setter=nChannel:) int nChannel;
@property (nonatomic, setter=nLevelL:) int nLevelL;
@property (nonatomic, setter=nLevelR:) int nLevelR;
@property (nonatomic, setter=bLevelAuto:) BOOL bLevelAuto;
@property (nonatomic, setter=nPosL:) int nPosL;
@property (nonatomic, setter=nPosR:) int nPosR;
@property (nonatomic, setter=nSweep:) int nSweep;
@property (nonatomic, setter=nDelayRange:) int nDelayRange;
@property (nonatomic, setter=nTrigLevel:) int nTrigLevel;
@property (nonatomic, setter=nTrigChannel:) int nTrigChannel;
@property (nonatomic, setter=nTrigSlope:) int nTrigSlope;
@property (nonatomic, setter=bTrigAuto:) BOOL bTrigAuto;
@property (nonatomic, setter=bTrigHighCut:) BOOL bTrigHighCut;
@property (nonatomic, setter=bTrigLowCut:) BOOL bTrigLowCut;
@property (nonatomic, setter=bTrigDisp:) BOOL bTrigDisp;
@property (nonatomic, setter=bTrigPos:) BOOL bTrigPos;
@property (nonatomic, setter=bTrigFree:) BOOL bTrigFree;
@property (nonatomic, setter=bReverseL:) BOOL bReverseL;
@property (nonatomic, setter=bReverseR:) BOOL bReverseR;
@property (nonatomic, setter=bXY:) BOOL bXY;
@property (nonatomic, setter=bRendou:) BOOL bRendou;
@property (nonatomic, setter=bZeroLevel:) BOOL bZeroLevel;
@property (nonatomic, setter=fCalLevel:) float fCalLevel;
@property (nonatomic, setter=nCalType:) int nCalType;
@property (nonatomic, setter=fCalValue:) float fCalValue;
@property (nonatomic, setter=sCalUnit:) NSString *sCalUnit;

@end

@interface SetDataFre : SetDataObject

@property (nonatomic, setter=nSampleRate:) int nSampleRate;
@property (nonatomic, setter=nChannel:) int nChannel;
@property (nonatomic, setter=nMode:) int nMode;
@property (nonatomic, setter=nMinLevel:) int nMinLevel;
@property (nonatomic, setter=nMaxLevel:) int nMaxLevel;
@property (nonatomic, setter=nSweepFreqStart:) int nSweepFreqStart;
@property (nonatomic, setter=nSweepFreqEnd:) int nSweepFreqEnd;
@property (nonatomic, setter=nSweepTime:) int nSweepTime;
@property (nonatomic, setter=nSweepLevel:) int nSweepLevel;
@property (nonatomic, setter=nSpotFreqStart:) int nSpotFreqStart;
@property (nonatomic, setter=nSpotFreqEnd:) int nSpotFreqEnd;
@property (nonatomic, setter=nSpotPoint:) int nSpotPoint;
@property (nonatomic, setter=nSpotLevel:) int nSpotLevel;
@property (nonatomic, setter=nNoiseFreqStart:) int nNoiseFreqStart;
@property (nonatomic, setter=nNoiseFreqEnd:) int nNoiseFreqEnd;
@property (nonatomic, setter=nNoiseResolution:) int nNoiseResolution;
@property (nonatomic, setter=nNoiseAveraging:) int nNoiseAveraging;
@property (nonatomic, setter=bShowSettnNoiseLevelings:) int nNoiseLevel;
@property (nonatomic, setter=nMicCalID:) int nMicCalID;

@end

@interface SetDataDst : SetDataObject

@property (nonatomic, setter=nSampleRate:) int nSampleRate;
@property (nonatomic, setter=nChannel:) int nChannel;
@property (nonatomic, setter=nVolume:) int nVolume;
@property (nonatomic, setter=nMaxHarmonics:) int nMaxHarmonics;
@property (nonatomic, setter=nGuardCnt:) int nGuardCnt;
@property (nonatomic, setter=nScaleMode:) int nScaleMode;
@property (nonatomic, setter=nScaleMax:) int nScaleMax;
@property (nonatomic, setter=nScaleMin:) int nScaleMin;
@property (nonatomic, setter=nMode:) int nMode;
@property (nonatomic, setter=nManualFreq:) int nManualFreq;
@property (nonatomic, setter=nManualLevel:) int nManualLevel;
@property (nonatomic, setter=bManualAverage:) BOOL bManualAverage;
@property (nonatomic, setter=nFreqStart:) int nFreqStart;
@property (nonatomic, setter=nFreqEnd:) int nFreqEnd;
@property (nonatomic, setter=nFreqPoint:) int nFreqPoint;
@property (nonatomic, setter=nFreqLevel:) int nFreqLevel;
@property (nonatomic, setter=bFreqSpline:) BOOL bFreqSpline;
@property (nonatomic, setter=nLevelStart:) int nLevelStart;
@property (nonatomic, setter=nLevelEnd:) int nLevelEnd;
@property (nonatomic, setter=nLevelPoint:) int nLevelPoint;
@property (nonatomic, setter=nLevelFreq:) int nLevelFreq;
@property (nonatomic, setter=bLevelSpline:) BOOL bLevelSpline;
@property (nonatomic, setter=bFreqMarker:) BOOL bFreqMarker;
@property (nonatomic, setter=bLevelMarker:) BOOL bLevelMarker;
@property (nonatomic, setter=nFreqHD:) int nFreqHD;
@property (nonatomic, setter=nLevelHD:) int nLevelHD;

@end

@interface SetDataImp : SetDataObject

@property (nonatomic, setter=nSampleRate:) int nSampleRate;
@property (nonatomic, setter=nTime:) int nTime;
@property (nonatomic, setter=nMeasureNum:) int nMeasureNum;
@property (nonatomic, setter=nChannel:) int nChannel;
@property (nonatomic, setter=nFileType:) int nFileType;
@property (nonatomic, setter=nFileFormat:) int nFileFormat;
@property (nonatomic, setter=nIFilterID:) int nIFilterID;
@property (nonatomic, setter=bAutoLevel:) BOOL bAutoLevel;
@property (nonatomic, setter=bAutoRetry:) BOOL bAutoRetry;
@property (nonatomic, setter=nMethod:) int nMethod;
@property (nonatomic, setter=fOffsetTime:) float fOffsetTime;

@end

@interface SetDataRec : SetDataObject

@property (nonatomic, setter=nPriority:) int nPriority;
@property (nonatomic, setter=bAutoRecording:) BOOL bAutoRecording;
@property (nonatomic, setter=bUseiCloud:) BOOL bUseiCloud;

@end

@interface SetData : NSObject
{
    NSUserDefaults *_ud;
}

@property (nonatomic, setter=nSelectedTab:) int nSelectedTab;
@property (nonatomic) int nPrevSelectedTab;
@property (nonatomic) SetDataSg *Sg;
@property (nonatomic) SetDataFft *Fft;
@property (nonatomic) SetDataOs *Os;
@property (nonatomic) SetDataFre *Fre;
@property (nonatomic) SetDataDst *Dst;
@property (nonatomic) SetDataImp *Imp;
@property (nonatomic) SetDataRec *Rec;

- (NSDictionary *)getAllData;
- (void)setAllData:(NSDictionary *)data;

@end
