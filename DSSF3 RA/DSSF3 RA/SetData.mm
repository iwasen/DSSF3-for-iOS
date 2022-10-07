//
//  SetData.cpp
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/18.
//  Copyright (c) 2015年 aizawa. All rights reserved.
//

#import "SetData.h"
#import "Common.h"

#define GET_DATA(group, type, name) _ ## name = GET_ ## type(group, name);
#define GET_int(group, name) (int)[_ud integerForKey:GET_KEY(group, name)]
#define GET_float(group, name) [_ud floatForKey:GET_KEY(group, name)]
#define GET_BOOL(group, name) [_ud boolForKey:GET_KEY(group, name)]
#define GET_NSStringPtr(group, name) [_ud stringForKey:GET_KEY(group, name)]

#define SET_DATA(group, type, name) - (void)name:(type)value {_ ## name = value; SET_ ## type(group, name);}
#define SET_int(group, name) [_ud setInteger:value forKey:GET_KEY(group, name)]
#define SET_float(group, name) [_ud setFloat:value forKey:GET_KEY(group, name)]
#define SET_BOOL(group, name) [_ud setBool:value forKey:GET_KEY(group, name)]
#define SET_NSStringPtr(group, name) [_ud setObject:value forKey:GET_KEY(group, name)]

#define SET_DEFAULT(group, name, value) [defaultValues setObject:@#value forKey:GET_KEY(group, name)]
#define GET_KEY(group, name) @#group "." #name

typedef NSString *NSStringPtr;
typedef float *floatPtr;
typedef int *intPtr;

@implementation SetDataObject

- (id)initWithUserDefaults:(NSUserDefaults *)userDefaults
{
    if (self = [super init]) {
        _ud = userDefaults;
    }
    return self;
}

@end

@implementation SetDataSg

- (id)initWithUserDefaults:(NSUserDefaults *)userDefaults :(NSMutableDictionary *)defaultValues
{
    if (self = [super initWithUserDefaults:userDefaults]) {
        SET_DEFAULT(Sg, nSampleRate, 44100);
        SET_DEFAULT(Sg, nLevelL, 50);
        SET_DEFAULT(Sg, nLevelR, 50);
        SET_DEFAULT(Sg, bRendou, YES);
        SET_DEFAULT(Sg, fFreqL, 1000.0);
        SET_DEFAULT(Sg, fFreqR, 1000.0);
        SET_DEFAULT(Sg, bRendouF, YES);
        SET_DEFAULT(Sg, fStartFreq, 100.0);
        SET_DEFAULT(Sg, fEndFreq, 10000.0);
        SET_DEFAULT(Sg, fSweepSpeed, 0.5);
        SET_DEFAULT(Sg, nPulseNum, 1);
        SET_DEFAULT(Sg, fPulseCycle, 10);
        SET_DEFAULT(Sg, fPresetFreq1, 10);
        SET_DEFAULT(Sg, fPresetFreq2, 100);
        SET_DEFAULT(Sg, fPresetFreq3, 1000);
        SET_DEFAULT(Sg, fPresetFreq4, 10000);
        SET_DEFAULT(Sg, fReferencePitch, 440);
        SET_DEFAULT(Sg, nScale, 9);
        SET_DEFAULT(Sg, nOctave, 4);
		SET_DEFAULT(Sg, fCompFreq1, 1);
		SET_DEFAULT(Sg, fCompFreq2, 2);
		SET_DEFAULT(Sg, fCompFreq3, 3);
		SET_DEFAULT(Sg, fCompFreq4, 4);
		SET_DEFAULT(Sg, fCompFreq5, 5);
		SET_DEFAULT(Sg, fCompFreq6, 6);
		SET_DEFAULT(Sg, fCompFreq7, 7);
		SET_DEFAULT(Sg, fCompFreq8, 8);
		SET_DEFAULT(Sg, nCompLevel1, 50);
        SET_DEFAULT(Sg, fSynthFreq, 1000);
        SET_DEFAULT(Sg, fWaveFreq, 200);
        SET_DEFAULT(Sg, fSweepTime, 10);
    }
    return self;
}

- (void)readData
{
    GET_DATA(Sg, int, nMode)
    GET_DATA(Sg, int, nSampleRate)
    GET_DATA(Sg, int, nLevelL)
    GET_DATA(Sg, int, nLevelR)
    GET_DATA(Sg, BOOL, bRendou)
    GET_DATA(Sg, float, fFreqL)
    GET_DATA(Sg, float, fFreqR)
    GET_DATA(Sg, BOOL, bRendouF)
    GET_DATA(Sg, int, nFreqRange)
    GET_DATA(Sg, int, nToneWave)
    GET_DATA(Sg, float, fPresetFreq1)
	GET_DATA(Sg, float, fPresetFreq2)
	GET_DATA(Sg, float, fPresetFreq3)
	GET_DATA(Sg, float, fPresetFreq4)
    GET_DATA(Sg, int, nPhase)
    GET_DATA(Sg, int, nNoiseType)
    GET_DATA(Sg, int, nNoiseMode)
    GET_DATA(Sg, float, fTimeDiff)
    GET_DATA(Sg, float, fStartFreq)
    GET_DATA(Sg, float, fEndFreq)
    GET_DATA(Sg, float, fSweepSpeed)
    GET_DATA(Sg, BOOL, bSweepLoop)
    GET_DATA(Sg, int, nSweepWave)
    GET_DATA(Sg, int, nPulseWidth)
    GET_DATA(Sg, int, nPulsePolarity)
    GET_DATA(Sg, int, nPulseNum)
    GET_DATA(Sg, BOOL, bPulseContinue)
    GET_DATA(Sg, float, fPulseCycle)
    GET_DATA(Sg, float, fReferencePitch)
    GET_DATA(Sg, int, nScale)
    GET_DATA(Sg, int, nOctave)
    GET_DATA(Sg, int, nScaleWave)
    GET_DATA(Sg, BOOL, bPlayMode)
    GET_DATA(Sg, float, fCompFreq1)
	GET_DATA(Sg, float, fCompFreq2)
	GET_DATA(Sg, float, fCompFreq3)
	GET_DATA(Sg, float, fCompFreq4)
	GET_DATA(Sg, float, fCompFreq5)
	GET_DATA(Sg, float, fCompFreq6)
	GET_DATA(Sg, float, fCompFreq7)
	GET_DATA(Sg, float, fCompFreq8)
    GET_DATA(Sg, int, nCompLevel1)
	GET_DATA(Sg, int, nCompLevel2)
	GET_DATA(Sg, int, nCompLevel3)
	GET_DATA(Sg, int, nCompLevel4)
	GET_DATA(Sg, int, nCompLevel5)
	GET_DATA(Sg, int, nCompLevel6)
	GET_DATA(Sg, int, nCompLevel7)
	GET_DATA(Sg, int, nCompLevel8)
    GET_DATA(Sg, float, fSynthFreq)
    GET_DATA(Sg, int, nSynthWave)
    GET_DATA(Sg, float, fWaveFreq)
    GET_DATA(Sg, int, nWaveFormNo)
    GET_DATA(Sg, int, nTimeRange)
    GET_DATA(Sg, float, fSweepTime)
    GET_DATA(Sg, float, fStartLevel)
    GET_DATA(Sg, float, fEndLevel)
}

SET_DATA(Sg, int, nMode)
SET_DATA(Sg, int, nSampleRate)
SET_DATA(Sg, int, nLevelL)
SET_DATA(Sg, int, nLevelR)
SET_DATA(Sg, BOOL, bRendou)
SET_DATA(Sg, float, fFreqL)
SET_DATA(Sg, float, fFreqR)
SET_DATA(Sg, BOOL, bRendouF)
SET_DATA(Sg, int, nFreqRange)
SET_DATA(Sg, int, nToneWave)
SET_DATA(Sg, float, fPresetFreq1)
SET_DATA(Sg, float, fPresetFreq2)
SET_DATA(Sg, float, fPresetFreq3)
SET_DATA(Sg, float, fPresetFreq4)
SET_DATA(Sg, int, nPhase)
SET_DATA(Sg, int, nNoiseType)
SET_DATA(Sg, int, nNoiseMode)
SET_DATA(Sg, float, fTimeDiff)
SET_DATA(Sg, float, fStartFreq)
SET_DATA(Sg, float, fEndFreq)
SET_DATA(Sg, float, fSweepSpeed)
SET_DATA(Sg, BOOL, bSweepLoop)
SET_DATA(Sg, int, nSweepWave)
SET_DATA(Sg, int, nPulseWidth)
SET_DATA(Sg, int, nPulsePolarity)
SET_DATA(Sg, int, nPulseNum)
SET_DATA(Sg, BOOL, bPulseContinue)
SET_DATA(Sg, float, fPulseCycle)
SET_DATA(Sg, float, fReferencePitch)
SET_DATA(Sg, int, nScale)
SET_DATA(Sg, int, nOctave)
SET_DATA(Sg, int, nScaleWave)
SET_DATA(Sg, BOOL, bPlayMode)
SET_DATA(Sg, float, fCompFreq1)
SET_DATA(Sg, float, fCompFreq2)
SET_DATA(Sg, float, fCompFreq3)
SET_DATA(Sg, float, fCompFreq4)
SET_DATA(Sg, float, fCompFreq5)
SET_DATA(Sg, float, fCompFreq6)
SET_DATA(Sg, float, fCompFreq7)
SET_DATA(Sg, float, fCompFreq8)
SET_DATA(Sg, int, nCompLevel1)
SET_DATA(Sg, int, nCompLevel2)
SET_DATA(Sg, int, nCompLevel3)
SET_DATA(Sg, int, nCompLevel4)
SET_DATA(Sg, int, nCompLevel5)
SET_DATA(Sg, int, nCompLevel6)
SET_DATA(Sg, int, nCompLevel7)
SET_DATA(Sg, int, nCompLevel8)
SET_DATA(Sg, float, fSynthFreq)
SET_DATA(Sg, int, nSynthWave)
SET_DATA(Sg, float, fWaveFreq)
SET_DATA(Sg, int, nWaveFormNo)
SET_DATA(Sg, int, nTimeRange)
SET_DATA(Sg, float, fSweepTime)
SET_DATA(Sg, float, fStartLevel)
SET_DATA(Sg, float, fEndLevel)

@end

@implementation SetDataFft

- (id)initWithUserDefaults:(NSUserDefaults *)userDefaults :(NSMutableDictionary *)defaultValues
{
    if (self = [super initWithUserDefaults:userDefaults]) {
        SET_DEFAULT(Fft, bShowSettings, YES);
        SET_DEFAULT(Fft, nSampleRate, 44100);
        SET_DEFAULT(Fft, nChannel, 0);
        SET_DEFAULT(Fft, nMinFreq, 20);
        SET_DEFAULT(Fft, nMaxFreq, 20000);
        SET_DEFAULT(Fft, bAutoFreq, YES);
        SET_DEFAULT(Fft, nMinLevel, -140);
        SET_DEFAULT(Fft, nMaxLevel, 0);
        SET_DEFAULT(Fft, bAutoLevel, YES);
        SET_DEFAULT(Fft, nWindowFunc, 3);
        SET_DEFAULT(Fft, nFftSize, 4096);
        SET_DEFAULT(Fft, nPeakHoldTime, 5);
        SET_DEFAULT(Fft, nTimeDir, 0);
        SET_DEFAULT(Fft, nTimeDataNum, 20);
        SET_DEFAULT(Fft, nMicCalID, -1);
        SET_DEFAULT(Fft, nCrfZoom, 1);
        SET_DEFAULT(Fft, nTimeRes, 2);
        SET_DEFAULT(Fft, nSmoothing, 125);
        SET_DEFAULT(Fft, bRlSplit, 0);
        SET_DEFAULT(Fft, nOctaveBand, 1);
        SET_DEFAULT(Fft, nTimeRange, 5);
    }
    return self;
}

- (void)readData
{
    GET_DATA(Fft, BOOL, bShowSettings)
    GET_DATA(Fft, int, nSampleRate)
    GET_DATA(Fft, int, nMode)
    GET_DATA(Fft, int, nChannel)
    GET_DATA(Fft, BOOL, bAutoFreq)
    GET_DATA(Fft, int, nMinFreq)
    GET_DATA(Fft, int, nMaxFreq)
    GET_DATA(Fft, BOOL, bAutoLevel)
    GET_DATA(Fft, int, nMinLevel)
    GET_DATA(Fft, int, nMaxLevel)
    GET_DATA(Fft, int, nFftScale)
    GET_DATA(Fft, int, nSmoothing)
    GET_DATA(Fft, int, nWindowFunc)
    GET_DATA(Fft, int, nFftSize)
    GET_DATA(Fft, BOOL, bPeakDisp)
    GET_DATA(Fft, BOOL, bPeakHold)
    GET_DATA(Fft, int, nPeakHoldMode)
    GET_DATA(Fft, int, nPeakHoldTime)
    GET_DATA(Fft, int, nTimeDir)
    GET_DATA(Fft, int, nTimeDataNum)
    GET_DATA(Fft, int, nCorrelation)
    GET_DATA(Fft, int, nMicCalID)
    GET_DATA(Fft, int, nFilter)
    GET_DATA(Fft, BOOL, bRlSplit)
    GET_DATA(Fft, int, nCrfZoom)
    GET_DATA(Fft, int, nTimeRes)
    GET_DATA(Fft, int, nAverage)
    GET_DATA(Fft, int, nOctaveBand)
    GET_DATA(Fft, int, nTimeRange)
    GET_DATA(Fft, int, nColorScale)
    GET_DATA(Fft, int, nAutoStopTime)
}

SET_DATA(Fft, BOOL, bShowSettings)
SET_DATA(Fft, int, nSampleRate)
SET_DATA(Fft, int, nMode)
SET_DATA(Fft, int, nChannel)
SET_DATA(Fft, BOOL, bAutoFreq)
SET_DATA(Fft, int, nMinFreq)
SET_DATA(Fft, int, nMaxFreq)
SET_DATA(Fft, BOOL, bAutoLevel)
SET_DATA(Fft, int, nMinLevel)
SET_DATA(Fft, int, nMaxLevel)
SET_DATA(Fft, int, nFftScale)
SET_DATA(Fft, int, nSmoothing)
SET_DATA(Fft, int, nWindowFunc)
SET_DATA(Fft, int, nFftSize)
SET_DATA(Fft, BOOL, bPeakDisp)
SET_DATA(Fft, BOOL, bPeakHold)
SET_DATA(Fft, int, nPeakHoldMode)
SET_DATA(Fft, int, nPeakHoldTime)
SET_DATA(Fft, int, nTimeDir)
SET_DATA(Fft, int, nTimeDataNum)
SET_DATA(Fft, int, nCorrelation)
SET_DATA(Fft, int, nMicCalID)
SET_DATA(Fft, int, nFilter)
SET_DATA(Fft, BOOL, bRlSplit)
SET_DATA(Fft, int, nCrfZoom)
SET_DATA(Fft, int, nTimeRes)
SET_DATA(Fft, int, nAverage)
SET_DATA(Fft, int, nOctaveBand)
SET_DATA(Fft, int, nTimeRange)
SET_DATA(Fft, int, nColorScale)
SET_DATA(Fft, int, nAutoStopTime)

@end

@implementation SetDataOs

- (id)initWithUserDefaults:(NSUserDefaults *)userDefaults :(NSMutableDictionary *)defaultValues
{
    if (self = [super initWithUserDefaults:userDefaults]) {
        SET_DEFAULT(Os, bShowSettings, YES);
        SET_DEFAULT(Os, nSampleRate, 44100);
        SET_DEFAULT(Os, nChannel, 0);
        SET_DEFAULT(Os, bLevelAuto, YES);
        SET_DEFAULT(Os, nSweep, 9);
        SET_DEFAULT(Os, bTrigDisp, YES);
        SET_DEFAULT(Os, bTrigPos, YES);
        SET_DEFAULT(Os, bTrigFree, YES);
        SET_DEFAULT(Os, bRendou, YES);
        SET_DEFAULT(Os, bZeroLevel, YES);
        SET_DEFAULT(Os, sCalUnit, );

    }
    return self;
}

-(void)readData
{
    GET_DATA(Os, BOOL, bShowSettings)
    GET_DATA(Os, int, nSampleRate)
    GET_DATA(Os, int, nChannel)
    GET_DATA(Os, int, nLevelL)
    GET_DATA(Os, int, nLevelR)
    GET_DATA(Os, BOOL, bLevelAuto)
    GET_DATA(Os, int, nPosL)
    GET_DATA(Os, int, nPosR)
    GET_DATA(Os, int, nSweep)
    GET_DATA(Os, int, nDelayRange)
    GET_DATA(Os, int, nTrigLevel)
    GET_DATA(Os, int, nTrigChannel)
    GET_DATA(Os, int, nTrigSlope)
    GET_DATA(Os, BOOL, bTrigAuto)
    GET_DATA(Os, BOOL, bTrigHighCut)
    GET_DATA(Os, BOOL, bTrigLowCut)
    GET_DATA(Os, BOOL, bTrigDisp)
    GET_DATA(Os, BOOL, bTrigPos)
    GET_DATA(Os, BOOL, bTrigFree)
    GET_DATA(Os, BOOL, bReverseL)
    GET_DATA(Os, BOOL, bReverseR)
    GET_DATA(Os, BOOL, bXY)
    GET_DATA(Os, BOOL, bRendou)
    GET_DATA(Os, BOOL, bZeroLevel)
    GET_DATA(Os, float, fCalLevel)
    GET_DATA(Os, int, nCalType)
    GET_DATA(Os, float, fCalValue)
    GET_DATA(Os, NSStringPtr, sCalUnit)
}

SET_DATA(Os, BOOL, bShowSettings)
SET_DATA(Os, int, nSampleRate)
SET_DATA(Os, int, nChannel)
SET_DATA(Os, int, nLevelL)
SET_DATA(Os, int, nLevelR)
SET_DATA(Os, BOOL, bLevelAuto)
SET_DATA(Os, int, nPosL)
SET_DATA(Os, int, nPosR)
SET_DATA(Os, int, nSweep)
SET_DATA(Os, int, nDelayRange)
SET_DATA(Os, int, nTrigLevel)
SET_DATA(Os, int, nTrigChannel)
SET_DATA(Os, int, nTrigSlope)
SET_DATA(Os, BOOL, bTrigAuto)
SET_DATA(Os, BOOL, bTrigHighCut)
SET_DATA(Os, BOOL, bTrigLowCut)
SET_DATA(Os, BOOL, bTrigDisp)
SET_DATA(Os, BOOL, bTrigPos)
SET_DATA(Os, BOOL, bTrigFree)
SET_DATA(Os, BOOL, bReverseL)
SET_DATA(Os, BOOL, bReverseR)
SET_DATA(Os, BOOL, bXY)
SET_DATA(Os, BOOL, bRendou)
SET_DATA(Os, BOOL, bZeroLevel)
SET_DATA(Os, float, fCalLevel)
SET_DATA(Os, int, nCalType)
SET_DATA(Os, float, fCalValue)
SET_DATA(Os, NSStringPtr, sCalUnit)

@end

@implementation SetDataFre

- (id)initWithUserDefaults:(NSUserDefaults *)userDefaults :(NSMutableDictionary *)defaultValues
{
	if (self = [super initWithUserDefaults:userDefaults]) {
		SET_DEFAULT(Fre, nSampleRate, 48000);
		SET_DEFAULT(Fre, nMinLevel, -80);
		SET_DEFAULT(Fre, nMaxLevel, 0);
		SET_DEFAULT(Fre, nSweepFreqStart, 20);
		SET_DEFAULT(Fre, nSweepFreqEnd, 20000);
		SET_DEFAULT(Fre, nSweepTime, 20);
		SET_DEFAULT(Fre, nSweepLevel, -10);
		SET_DEFAULT(Fre, nSpotFreqStart, 20);
		SET_DEFAULT(Fre, nSpotFreqEnd, 20000);
		SET_DEFAULT(Fre, nSpotPoint, 20);
		SET_DEFAULT(Fre, nSpotLevel, -10);
		SET_DEFAULT(Fre, nNoiseFreqStart, 20);
		SET_DEFAULT(Fre, nNoiseFreqEnd, 20000);
		SET_DEFAULT(Fre, nNoiseResolution, 1);
		SET_DEFAULT(Fre, nNoiseAveraging, 3);
		SET_DEFAULT(Fre, nNoiseLevel, -10);
		SET_DEFAULT(Fre, nMicCalID, -1);
	}
	return self;
}

-(void)readData
{
	GET_DATA(Fre, int, nSampleRate)
	GET_DATA(Fre, int, nChannel)
	GET_DATA(Fre, int, nMode)
	GET_DATA(Fre, int, nMinLevel)
	GET_DATA(Fre, int, nMaxLevel)
	GET_DATA(Fre, int, nSweepFreqStart)
	GET_DATA(Fre, int, nSweepFreqEnd)
	GET_DATA(Fre, int, nSweepTime)
	GET_DATA(Fre, int, nSweepLevel)
	GET_DATA(Fre, int, nSpotFreqStart)
	GET_DATA(Fre, int, nSpotFreqEnd)
	GET_DATA(Fre, int, nSpotPoint)
	GET_DATA(Fre, int, nSpotLevel)
	GET_DATA(Fre, int, nNoiseFreqStart)
	GET_DATA(Fre, int, nNoiseFreqEnd)
	GET_DATA(Fre, int, nNoiseResolution)
	GET_DATA(Fre, int, nNoiseAveraging)
	GET_DATA(Fre, int, nNoiseLevel)
	GET_DATA(Fre, int, nMicCalID)
}

SET_DATA(Fre, int, nSampleRate)
SET_DATA(Fre, int, nChannel)
SET_DATA(Fre, int, nMode)
SET_DATA(Fre, int, nMinLevel)
SET_DATA(Fre, int, nMaxLevel)
SET_DATA(Fre, int, nSweepFreqStart)
SET_DATA(Fre, int, nSweepFreqEnd)
SET_DATA(Fre, int, nSweepTime)
SET_DATA(Fre, int, nSweepLevel)
SET_DATA(Fre, int, nSpotFreqStart)
SET_DATA(Fre, int, nSpotFreqEnd)
SET_DATA(Fre, int, nSpotPoint)
SET_DATA(Fre, int, nSpotLevel)
SET_DATA(Fre, int, nNoiseFreqStart)
SET_DATA(Fre, int, nNoiseFreqEnd)
SET_DATA(Fre, int, nNoiseResolution)
SET_DATA(Fre, int, nNoiseAveraging)
SET_DATA(Fre, int, nNoiseLevel)
SET_DATA(Fre, int, nMicCalID)

@end

@implementation SetDataDst

- (id)initWithUserDefaults:(NSUserDefaults *)userDefaults :(NSMutableDictionary *)defaultValues
{
	if (self = [super initWithUserDefaults:userDefaults]) {
		SET_DEFAULT(Dst, nSampleRate, 48000);
		SET_DEFAULT(Dst, nMaxHarmonics, 20);
		SET_DEFAULT(Dst, nGuardCnt, 4);
		SET_DEFAULT(Dst, nScaleMin, -100);
		SET_DEFAULT(Dst, nScaleMax, -20);
		SET_DEFAULT(Dst, nManualFreq, 1000);
		SET_DEFAULT(Dst, nManualLevel, -10);
		SET_DEFAULT(Dst, nFreqStart, 20);
		SET_DEFAULT(Dst, nFreqEnd, 10000);
		SET_DEFAULT(Dst, nFreqPoint, 20);
		SET_DEFAULT(Dst, nFreqLevel, -10);
		SET_DEFAULT(Dst, nLevelStart, -40);
		SET_DEFAULT(Dst, nLevelEnd, 0);
		SET_DEFAULT(Dst, nLevelPoint, 20);
		SET_DEFAULT(Dst, nLevelFreq, 1000);
		SET_DEFAULT(Dst, bFreqMarker, YES);
		SET_DEFAULT(Dst, bLevelMarker, YES);
	}
	return self;
}

-(void)readData
{
	GET_DATA(Dst, int, nSampleRate)
	GET_DATA(Dst, int, nChannel)
	GET_DATA(Dst, int, nVolume)
	GET_DATA(Dst, int, nMaxHarmonics)
	GET_DATA(Dst, int, nGuardCnt)
	GET_DATA(Dst, int, nScaleMode)
	GET_DATA(Dst, int, nScaleMax)
	GET_DATA(Dst, int, nScaleMin)
	GET_DATA(Dst, int, nMode)
	GET_DATA(Dst, int, nManualFreq)
	GET_DATA(Dst, int, nManualLevel)
	GET_DATA(Dst, BOOL, bManualAverage)
	GET_DATA(Dst, int, nFreqStart)
	GET_DATA(Dst, int, nFreqEnd)
	GET_DATA(Dst, int, nFreqPoint)
	GET_DATA(Dst, int, nFreqLevel)
	GET_DATA(Dst, BOOL, bFreqSpline)
	GET_DATA(Dst, int, nLevelStart)
	GET_DATA(Dst, int, nLevelEnd)
	GET_DATA(Dst, int, nLevelPoint)
	GET_DATA(Dst, int, nLevelFreq)
	GET_DATA(Dst, BOOL, bLevelSpline)
	GET_DATA(Dst, BOOL, bFreqMarker)
	GET_DATA(Dst, BOOL, bLevelMarker)
	GET_DATA(Dst, int, nFreqHD)
	GET_DATA(Dst, int, nLevelHD)
}

SET_DATA(Dst, int, nSampleRate)
SET_DATA(Dst, int, nChannel)
SET_DATA(Dst, int, nVolume)
SET_DATA(Dst, int, nMaxHarmonics)
SET_DATA(Dst, int, nGuardCnt)
SET_DATA(Dst, int, nScaleMode)
SET_DATA(Dst, int, nScaleMax)
SET_DATA(Dst, int, nScaleMin)
SET_DATA(Dst, int, nMode)
SET_DATA(Dst, int, nManualFreq)
SET_DATA(Dst, int, nManualLevel)
SET_DATA(Dst, BOOL, bManualAverage)
SET_DATA(Dst, int, nFreqStart)
SET_DATA(Dst, int, nFreqEnd)
SET_DATA(Dst, int, nFreqPoint)
SET_DATA(Dst, int, nFreqLevel)
SET_DATA(Dst, BOOL, bFreqSpline)
SET_DATA(Dst, int, nLevelStart)
SET_DATA(Dst, int, nLevelEnd)
SET_DATA(Dst, int, nLevelPoint)
SET_DATA(Dst, int, nLevelFreq)
SET_DATA(Dst, BOOL, bLevelSpline)
SET_DATA(Dst, BOOL, bFreqMarker)
SET_DATA(Dst, BOOL, bLevelMarker)
SET_DATA(Dst, int, nFreqHD)
SET_DATA(Dst, int, nLevelHD)

@end

@implementation SetDataImp

- (id)initWithUserDefaults:(NSUserDefaults *)userDefaults :(NSMutableDictionary *)defaultValues
{
	if (self = [super initWithUserDefaults:userDefaults]) {
		SET_DEFAULT(Imp, nSampleRate, 48000);
		SET_DEFAULT(Imp, nTime, 4);
		SET_DEFAULT(Imp, nChannel, 1);
		SET_DEFAULT(Imp, nMeasureNum, 1);
		SET_DEFAULT(Imp, bAutoLevel, NO);
		SET_DEFAULT(Imp, bAutoRetry, NO);
	}
	return self;
}

-(void)readData
{
	GET_DATA(Imp, int, nSampleRate)
	GET_DATA(Imp, int, nTime)
	GET_DATA(Imp, int, nMeasureNum)
	GET_DATA(Imp, int, nChannel)
	GET_DATA(Imp, int, nFileType)
	GET_DATA(Imp, int, nFileFormat)
	GET_DATA(Imp, int, nIFilterID)
	GET_DATA(Imp, BOOL, bAutoLevel)
	GET_DATA(Imp, BOOL, bAutoRetry)
	GET_DATA(Imp, int, nMethod)
	GET_DATA(Imp, float, fOffsetTime)
}

SET_DATA(Imp, int, nSampleRate)
SET_DATA(Imp, int, nTime)
SET_DATA(Imp, int, nMeasureNum)
SET_DATA(Imp, int, nChannel)
SET_DATA(Imp, int, nFileType)
SET_DATA(Imp, int, nFileFormat)
SET_DATA(Imp, int, nIFilterID)
SET_DATA(Imp, BOOL, bAutoLevel)
SET_DATA(Imp, BOOL, bAutoRetry)
SET_DATA(Imp, int, nMethod)
SET_DATA(Imp, float, fOffsetTime)

@end

@implementation SetDataRec

- (id)initWithUserDefaults:(NSUserDefaults *)userDefaults :(NSMutableDictionary *)defaultValues
{
	if (self = [super initWithUserDefaults:userDefaults]) {
		SET_DEFAULT(Rec, nPriority, 0);
        SET_DEFAULT(Rec, nAutoRecording, NO);
        SET_DEFAULT(Rec, nUseiCloud, NO);
	}
	return self;
}

-(void)readData
{
	GET_DATA(Rec, int, nPriority)
    GET_DATA(Rec, BOOL, bAutoRecording)
    GET_DATA(Rec, BOOL, bUseiCloud)
}

SET_DATA(Rec, int, nPriority)
SET_DATA(Rec, BOOL, bAutoRecording)
SET_DATA(Rec, BOOL, bUseiCloud)

@end

@implementation SetData

- (id)init
{
    if (self = [super init]) {
        _ud = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];

        SET_DEFAULT(Main, nSelectedTab, 1);
        _nPrevSelectedTab = _nSelectedTab;

        _Sg = [[SetDataSg alloc] initWithUserDefaults:_ud :defaultValues];
        _Fft = [[SetDataFft alloc] initWithUserDefaults:_ud :defaultValues];
        _Os = [[SetDataOs alloc] initWithUserDefaults:_ud :defaultValues];
		_Fre = [[SetDataFre alloc] initWithUserDefaults:_ud :defaultValues];
		_Dst = [[SetDataDst alloc] initWithUserDefaults:_ud :defaultValues];
		_Imp = [[SetDataImp alloc] initWithUserDefaults:_ud :defaultValues];
		_Rec = [[SetDataRec alloc] initWithUserDefaults:_ud :defaultValues];

        [_ud registerDefaults:defaultValues];
        
		GET_DATA(Main, int, nSelectedTab)

        [_Sg readData];
        [_Fft readData];
        [_Os readData];
		[_Fre readData];
		[_Dst readData];
		[_Imp readData];
		[_Rec readData];
    }
    return self;
}

- (void)nSelectedTab:(int)value
{
    _nPrevSelectedTab = _nSelectedTab;
    
    _nSelectedTab = value;
    SET_int(Main, nSelectedTab);
}

- (NSDictionary *)getAllData
{
    return [_ud dictionaryRepresentation];
}

- (void)setAllData:(NSDictionary *)data
{
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [_ud removePersistentDomainForName:appDomain];
    
    [_ud registerDefaults:data];

    GET_DATA(Main, int, nSelectedTab)

    [_Sg readData];
    [_Fft readData];
    [_Os readData];
    [_Fre readData];
    [_Dst readData];
    [_Imp readData];
    [_Rec readData];
}

@end
