//
//  SetData.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/03.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "SetData.h"

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

@implementation SetDataCalcParam

- (id)initWithUserDefaults:(NSUserDefaults *)userDefaults :(NSMutableDictionary *)defaultValues
{
	if (self = [super initWithUserDefaults:userDefaults]) {
		SET_DEFAULT(Imp, nStartFreq, 1);
		SET_DEFAULT(Imp, nEndFreq, 10);
		SET_DEFAULT(Imp, nSplRefData, -1);
		SET_DEFAULT(Imp, fSplRefLevel, 0);
		SET_DEFAULT(Imp, fDT1MinTime, 10.0);
		SET_DEFAULT(Imp, fTsubEnd, -20.0);
		SET_DEFAULT(Imp, bTsubAuto, YES);
		SET_DEFAULT(Imp, fTsubNoise, 0.5);
		SET_DEFAULT(Imp, fWIACCLevel, 0.1);
		SET_DEFAULT(Imp, fPrefSPL, 0);
		SET_DEFAULT(Imp, fPrefTauE, 100.0);
		SET_DEFAULT(Imp, fTCustom1, -5);
		SET_DEFAULT(Imp, fTCustom2, -20);
		SET_DEFAULT(Imp, fCCustom, 40);
	}
	return self;
}

- (void)readData
{
	GET_DATA(Imp, int, nFreqBand)
	GET_DATA(Imp, int, nStartFreq)
	GET_DATA(Imp, int, nEndFreq)
	GET_DATA(Imp, BOOL, bAFilter)
	GET_DATA(Imp, int, nSplRefData)
	GET_DATA(Imp, float, fSplRefLevel)
	GET_DATA(Imp, float, fDT1MinTime)
	GET_DATA(Imp, float, fTsubEnd)
	GET_DATA(Imp, BOOL, bTsubAuto)
	GET_DATA(Imp, float, fTsubNoise)
	GET_DATA(Imp, float, fWIACCLevel)
	GET_DATA(Imp, float, fPrefSPL)
	GET_DATA(Imp, float, fPrefTauE)
	GET_DATA(Imp, float, fGRefData)
	GET_DATA(Imp, float, fTCustom1)
	GET_DATA(Imp, float, fTCustom2)
	GET_DATA(Imp, float, fCCustom)
}

SET_DATA(Imp, int, nFreqBand)
SET_DATA(Imp, int, nStartFreq)
SET_DATA(Imp, int, nEndFreq)
SET_DATA(Imp, BOOL, bAFilter)
SET_DATA(Imp, int, nSplRefData)
SET_DATA(Imp, float, fSplRefLevel)
SET_DATA(Imp, float, fDT1MinTime)
SET_DATA(Imp, float, fTsubEnd)
SET_DATA(Imp, BOOL, bTsubAuto)
SET_DATA(Imp, float, fTsubNoise)
SET_DATA(Imp, float, fWIACCLevel)
SET_DATA(Imp, float, fPrefSPL)
SET_DATA(Imp, float, fPrefTauE)
SET_DATA(Imp, float, fGRefData)
SET_DATA(Imp, float, fTCustom1)
SET_DATA(Imp, float, fTCustom2)
SET_DATA(Imp, float, fCCustom)

@end

@implementation SetData

- (id)init
{
	if (self = [super init]) {
		_ud = [NSUserDefaults standardUserDefaults];
		NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];

		_Imp = [[SetDataCalcParam alloc] initWithUserDefaults:_ud :defaultValues];

		[_ud registerDefaults:defaultValues];

		[_Imp readData];
	}
	return self;
}

@end

SetData *setData;
