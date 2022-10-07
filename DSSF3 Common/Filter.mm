// Filter.cpp : インプリメンテーション ファイル
//

#import "Filter.h"
#import "Spline.h"

#define FPOW(a,b) (float)pow(a,b)

static const FilterData AFilter[] = {
	{FPOW(10.0, 1.0), -70.4}, {FPOW(10.0, 1.1), -63.4}, {FPOW(10.0, 1.2), -56.7}, {FPOW(10.0, 1.3), -50.5}, {FPOW(10.0, 1.4), -44.7},
	{FPOW(10.0, 1.5), -39.4}, {FPOW(10.0, 1.6), -34.6}, {FPOW(10.0, 1.7), -30.2}, {FPOW(10.0, 1.8), -26.2}, {FPOW(10.0, 1.9), -22.5},
	{FPOW(10.0, 2.0), -19.1}, {FPOW(10.0, 2.1), -16.1}, {FPOW(10.0, 2.2), -13.4}, {FPOW(10.0, 2.3), -10.9}, {FPOW(10.0, 2.4),  -8.6},
	{FPOW(10.0, 2.5),  -6.6}, {FPOW(10.0, 2.6),  -4.8}, {FPOW(10.0, 2.7),  -3.2}, {FPOW(10.0, 2.8),  -1.9}, {FPOW(10.0, 2.9),  -0.8},
	{FPOW(10.0, 3.0),   0.0}, {FPOW(10.0, 3.1),   0.6}, {FPOW(10.0, 3.2),   1.0}, {FPOW(10.0, 3.3),   1.2}, {FPOW(10.0, 3.4),   1.3},
	{FPOW(10.0, 3.5),   1.2}, {FPOW(10.0, 3.6),   1.0}, {FPOW(10.0, 3.7),   0.5}, {FPOW(10.0, 3.8),  -0.1}, {FPOW(10.0, 3.9),  -1.1},
	{FPOW(10.0, 4.0),  -2.5}, {FPOW(10.0, 4.1),  -4.3}, {FPOW(10.0, 4.2),  -6.6}, {FPOW(10.0, 4.3),  -9.3}
};

static const FilterData BFilter[] = {
	{FPOW(10.0, 1.0), -38.2}, {FPOW(10.0, 1.1), -33.2}, {FPOW(10.0, 1.2), -28.5}, {FPOW(10.0, 1.3), -24.2}, {FPOW(10.0, 1.4), -20.4},
	{FPOW(10.0, 1.5), -17.1}, {FPOW(10.0, 1.6), -14.2}, {FPOW(10.0, 1.7), -11.6}, {FPOW(10.0, 1.8),  -9.3}, {FPOW(10.0, 1.9),  -7.4},
	{FPOW(10.0, 2.0),  -5.6}, {FPOW(10.0, 2.1),  -4.2}, {FPOW(10.0, 2.2),  -3.0}, {FPOW(10.0, 2.3),  -2.0}, {FPOW(10.0, 2.4),  -1.3},
	{FPOW(10.0, 2.5),  -0.8}, {FPOW(10.0, 2.6),  -0.5}, {FPOW(10.0, 2.7),  -0.3}, {FPOW(10.0, 2.8),  -0.1}, {FPOW(10.0, 2.9),   0.0},
	{FPOW(10.0, 3.0),   0.0}, {FPOW(10.0, 3.1),   0.0}, {FPOW(10.0, 3.2),   0.0}, {FPOW(10.0, 3.3),  -0.1}, {FPOW(10.0, 3.4),  -0.2},
	{FPOW(10.0, 3.5),  -0.4}, {FPOW(10.0, 3.6),  -0.7}, {FPOW(10.0, 3.7),  -1.2}, {FPOW(10.0, 3.8),  -1.9}, {FPOW(10.0, 3.9),  -2.9},
	{FPOW(10.0, 4.0),  -4.3}, {FPOW(10.0, 4.1),  -6.1}, {FPOW(10.0, 4.2),  -8.4}, {FPOW(10.0, 4.3), -11.1}
};

static const FilterData CFilter[] = {
	{FPOW(10.0, 1.0), -14.3}, {FPOW(10.0, 1.1), -11.2}, {FPOW(10.0, 1.2),  -8.5}, {FPOW(10.0, 1.3),  -6.2}, {FPOW(10.0, 1.4),  -4.4},
	{FPOW(10.0, 1.5),  -3.0}, {FPOW(10.0, 1.6),  -2.0}, {FPOW(10.0, 1.7),  -1.3}, {FPOW(10.0, 1.8),  -0.8}, {FPOW(10.0, 1.9),  -0.5},
	{FPOW(10.0, 2.0),  -0.3}, {FPOW(10.0, 2.1),  -0.2}, {FPOW(10.0, 2.2),  -0.1}, {FPOW(10.0, 2.3),   0.0}, {FPOW(10.0, 2.4),   0.0},
	{FPOW(10.0, 2.5),   0.0}, {FPOW(10.0, 2.6),   0.0}, {FPOW(10.0, 2.7),   0.0}, {FPOW(10.0, 2.8),   0.0}, {FPOW(10.0, 2.9),   0.0},
	{FPOW(10.0, 3.0),   0.0}, {FPOW(10.0, 3.1),   0.0}, {FPOW(10.0, 3.2),  -0.1}, {FPOW(10.0, 3.3),  -0.2}, {FPOW(10.0, 3.4),  -0.3},
	{FPOW(10.0, 3.5),  -0.5}, {FPOW(10.0, 3.6),  -0.8}, {FPOW(10.0, 3.7),  -1.3}, {FPOW(10.0, 3.8),  -2.0}, {FPOW(10.0, 3.9),  -3.0},
	{FPOW(10.0, 4.0),  -4.4}, {FPOW(10.0, 4.1),  -6.2}, {FPOW(10.0, 4.2),  -8.5}, {FPOW(10.0, 4.3), -11.2}
};

bool MakeFilterTbl2(float *pFilterTbl, int nData, float fRate, int nFilterType, int nLog)
{
	const FilterData *pFilterData;
	int nFilterData;

	switch (nFilterType) {
	case FILTER_F:
		pFilterData = NULL;
		nFilterData = 0;
		break;
	case FILTER_A:
		pFilterData = AFilter;
		nFilterData = sizeof(AFilter) / sizeof(FilterData);
		break;
	case FILTER_B:
		pFilterData = BFilter;
		nFilterData = sizeof(BFilter) / sizeof(FilterData);
		break;
	case FILTER_C:
		pFilterData = CFilter;
		nFilterData = sizeof(CFilter) / sizeof(FilterData);
		break;
	default:
		return false;
	}

	MakeFilterTbl3(pFilterTbl, nData, fRate, pFilterData, nFilterData, nLog);

	return true;
}

void MakeFilterTbl3(float *pFilterTbl, int nData, float fRate, const FilterData *pFilterData, int nFilterData, int nLog)
{
	int i;

	if (nFilterData < 3) {
		pFilterTbl[0] = 0;
		for (i = 1; i < nData; i++)
			pFilterTbl[i] = 1.0;
		return;
	}

	CSpline spline;
	float *pFreq = new float[nFilterData];
	float *pLevel = new float[nFilterData];

	for (i = 0; i < nFilterData; i++) {
		pFreq[i] = log(pFilterData->fFreq);
		pLevel[i] = pFilterData->fLevel;
		pFilterData++;
	}

	spline.MakeTable(pFreq, pLevel, nFilterData);

	pFilterTbl[0] = 0;
	for (i = 1; i <= nData / 2; i++)
		pFilterTbl[i] = pFilterTbl[nData - i] = FPOW(10.0, spline.Spline(log((float)i / nData * fRate)) / nLog);

	delete [] pFreq;
	delete [] pLevel;
}
