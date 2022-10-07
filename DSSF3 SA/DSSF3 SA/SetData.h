//
//  SetData.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/03.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SetDataObject : NSObject
{
	NSUserDefaults *_ud;
}
@end

@interface SetDataCalcParam : SetDataObject

@property (nonatomic, setter=nFreqBand:) int nFreqBand;
@property (nonatomic, setter=nStartFreq:) int nStartFreq;
@property (nonatomic, setter=nEndFreq:) int nEndFreq;
@property (nonatomic, setter=bAFilter:) BOOL bAFilter;
@property (nonatomic, setter=nSplRefData:) int nSplRefData;
@property (nonatomic, setter=fSplRefLevel:) float fSplRefLevel;
@property (nonatomic, setter=fDT1MinTime:) float fDT1MinTime;
@property (nonatomic, setter=fTsubEnd:) float fTsubEnd;
@property (nonatomic, setter=bTsubAuto:) BOOL bTsubAuto;
@property (nonatomic, setter=fTsubNoise:) float fTsubNoise;
@property (nonatomic, setter=fWIACCLevel:) float fWIACCLevel;
@property (nonatomic, setter=fPrefSPL:) float fPrefSPL;
@property (nonatomic, setter=fPrefTauE:) float fPrefTauE;
@property (nonatomic, setter=fGRefData:) float fGRefData;
@property (nonatomic, setter=fTCustom1:) float fTCustom1;
@property (nonatomic, setter=fTCustom2:) float fTCustom2;
@property (nonatomic, setter=fCCustom:) float fCCustom;

@end

@interface SetData : NSObject
{
	NSUserDefaults *_ud;
}

@property (nonatomic) SetDataCalcParam *Imp;

@end

extern SetData *setData;
