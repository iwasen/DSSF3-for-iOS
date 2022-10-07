#import <Foundation/Foundation.h>

#define FILTER_F	0
#define FILTER_A	1
#define FILTER_B	2
#define FILTER_C	3

struct FilterData {
	float fFreq;
	float fLevel;
};

extern bool MakeFilterTbl2(float *pFilterTbl, int nData, float fRate, int nFilterType, int nLog);
extern void MakeFilterTbl3(float *pFilterTbl, int nData, float fRate, const FilterData *pFilterData, int nFilterData, int nLog);
