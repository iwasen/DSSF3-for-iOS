//
//  Common.cpp
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/07.
//  Copyright (c) 2015年 aizawa. All rights reserved.
//

#import "Common.h"

SetData *g_oSetData;

NSString *g_tWindowFunc[WF_NUM] = {
    @"Rectangular", @"Triangular", @"Hamming", @"Hanning", @"Blackman", @"Blackman-Harris", @"Flat-Top"
};

NSString *g_pFreqScale1[MAX_OCT1 + 1] = {
    @"ALL",
    @"16", @"31.5", @"63",
    @"125", @"250", @"500",
    @"1k", @"2k", @"4k",
    @"8k", @"16k", @""
};

NSString *g_pFreqScale3[MAX_OCT3 + 1] = {
    @"ALL",
    @"16", @"20", @"25", @"31.5", @"40", @"50", @"63", @"80", @"100", @"125",
    @"160", @"200", @"250", @"315", @"400", @"500", @"630", @"800", @"1k", @"1.25k",
    @"1.6k", @"2k", @"2.5k", @"3.15k", @"4k", @"5k", @"6.3k", @"8k", @"10k", @"12.5k",
    @"16k", @"20k", @"25k", @"31.5k", @"40k", @"50k", @""
};

const int g_nOctBandTbl[OCT_BAND_NUM] = {
    1, 3, 6, 12, 24
};

void SetSampleRateList(CtComboBox *comboBox, int nDefault)
{
    static int tSampleRate[] = {
        96000, 88200, 64000, 48000, 44100, 32000, 22050, 16000, 11025, 8000
    };
    NSString *strBuf;
    int i;
    int nIndex = -1;
    int nSelect = -1;

    [comboBox resetContent];
    
    for (i = 0; i < sizeof(tSampleRate) / sizeof(int); i++) {
        strBuf = [NSString stringWithFormat:@"%.3f kHz", (float)tSampleRate[i] / 1000];
        nIndex = [comboBox addItem:strBuf :tSampleRate[i]];
        
        if (tSampleRate[i] == nDefault)
            nSelect = nIndex;
    }
    
    if (nSelect != -1)
        comboBox.selectedIndex = nSelect;
}

void SetChannelList(CtComboBox *comboBox, int nDefault)
{
    static NSString *tChannel[] = {@"IDS_MONO", @"IDS_STEREO", @"IDS_LEFT_ONLY", @"IDS_RIGHT_ONLY", @"IDS_DIFFERENCE"};
    int i;
    NSString *str;
    
    for (i = 0; i < sizeof(tChannel) / sizeof(NSString *); i++) {
        str = NSLocalizedString(tChannel[i], nil);
        [comboBox addItem:str :0];
    }
    comboBox.selectedIndex = nDefault;
}

void SetWindowFuncList(CtComboBox *comboBox)
{
    int i;
    
    for (i = 0; i < WF_NUM; i++)
        [comboBox addItem:g_tWindowFunc[i] :0];
}

void SetFilterNameList(CtComboBox *comboBox)
{
    static NSString *tFilterName[] = {
        @"IDS_FLAT", @"IDS_AWEIGHTING", @"IDS_BWEIGHTING", @"IDS_CWEIGHTING"
    };
    int i;
    
    for (i = 0; i < 4; i++) {
        [comboBox addItem:NSLocalizedString(tFilterName[i], nil) :0];
    }
}

void SetWaveFormList(CtComboBox *combo, int nSel)
{

	static NSString *tWaveForm[N_WAVE_FORM] = {
		@"IDS_SINUSOIDAL", @"IDS_TRIANGULAR", @"IDS_SQUARE", @"IDS_SAWTOOTH"
	};
	int i;
	NSString *str;

	for (i = 0; i < N_WAVE_FORM; i++) {
		str = NSLocalizedString(tWaveForm[i], nil);
		[combo addItem:str :0];
	}
/*
	str.LoadString(IDS_WAVEFORM);
	for (i = 0; i < MAX_WAVEFORM; i++) {
		str2.Format("%s:%d", str, i + 1);
		combo.AddString(str2);
	}
*/
	combo.selectedIndex = nSel;
}

int GetLinearScaleStep(int nMaxValue, int nMinvalue, int nScaleSize)
{
    int step = (nMaxValue - nMinvalue) / (nScaleSize / 40);
    if (step == 0)
        step = 1;
    
    int scale = (int)log10((float)step);
    int num = (int)(step / pow(10.0, scale));
    
    if (num < 2)
        num = 1;
    else if (num < 5)
        num = 2;
    else
        num = 5;
    
    return (int)(num * pow(10.0, scale));
}

int GetLogScaleStep(int nValue)
{
    return (int)(pow(10.0, (float)(int)log10((float)nValue)) + 0.5);
}

float GetLogScaleStep(float fValue)
{
    return pow(10, floor(log10(fValue) + 1e-3));
}

float GetLinearScaleStep(float fRange, int nPixel, int *pStep)
{
    float t1, t2;
    int nStep;
    
    if (fRange <= 0)
        return 1;
    
    t1 = fRange / nPixel;
    float fStep = pow(10.0, floor(log10(t1)));
    t2 = t1 / fStep;
    if (t2 < 2) {
        fStep *= 0.5;
        nStep = 2;
    } else if (t2 < 5)
        nStep = 2;
    else
        nStep = 5;
    
    if (pStep != NULL)
        *pStep = nStep;
    
    return fStep;
}

int GetScaleStartValue(int nMinValue, int nStep)
{
    if (nMinValue > 0)
        nMinValue += nStep - 1;
    
    return nMinValue / nStep * nStep;
}

float GetScaleStartValue(float fMinValue, float fStep)
{
    return floor(fMinValue / fStep + 1e-3) * fStep;
}


void GetAxisName(int nMode, NSString **sNameX, NSString **sNameY)
{
    switch (nMode) {
        case FFT_MODE_PWS:
        case FFT_MODE_OCT:
        case FFT_MODE_3DD:
        case FFT_MODE_SPG:
            *sNameX = NSLocalizedString(@"IDS_FREQUENCY", nil);
            *sNameY = NSLocalizedString(@"IDS_SPL", nil);
            break;
        case FFT_MODE_CRF:
            *sNameX = NSLocalizedString(@"IDS_TAU", nil);
            *sNameY = NSLocalizedString(@"IDS_CORRELATION", nil);
            break;
        case FFT_MODE_PHS:
            *sNameX = NSLocalizedString(@"IDS_FREQUENCY", nil);
            *sNameY = NSLocalizedString(@"IDS_PHASE2", nil);
            break;
        case FFT_MODE_CRS:
            *sNameX = NSLocalizedString(@"IDS_FREQUENCY", nil);
            *sNameY = NSLocalizedString(@"IDS_LEVEL", nil);
            break;
        case FFT_MODE_COH:
            *sNameX = NSLocalizedString(@"IDS_FREQUENCY", nil);
            *sNameY = NSLocalizedString(@"IDS_COHERENCE2", nil);
            break;
        case FFT_MODE_CEP:
            *sNameX = NSLocalizedString(@"IDS_TIME", nil);
            *sNameY = NSLocalizedString(@"IDS_LEVEL", nil);
            break;
    }
}

void GetAxisUnit(int nMode, NSString **sUnitX, NSString **sUnitY)
{
    switch (nMode) {
        case FFT_MODE_PWS:
        case FFT_MODE_OCT:
        case FFT_MODE_3DD:
        case FFT_MODE_SPG:
            *sUnitX = @"Hz";
            *sUnitY = @"dB";
            break;
        case FFT_MODE_CRF:
            *sUnitX = @"ms";
            *sUnitY = @"";
            break;
        case FFT_MODE_PHS:
            *sUnitX = @"Hz";
            *sUnitY = @"deg";
            break;
        case FFT_MODE_CRS:
            *sUnitX = @"Hz";
            *sUnitY = @"dB";
            break;
        case FFT_MODE_COH:
            *sUnitX = @"Hz";
            *sUnitY = @"";
            break;
        case FFT_MODE_CEP:
            *sUnitX = @"ms";
            *sUnitY = @"dB";
            break;
    }
}

NSString *GetNumberString(int nNumber)
{
	NSString *str;

	if (nNumber < 1000)
		str = [NSString stringWithFormat:@"%d", nNumber];
	else if (nNumber < 1000000)
		str = [NSString stringWithFormat:@"%dk", nNumber / 1000];
	else
		str = [NSString stringWithFormat:@"%dM", nNumber / 1000000];

	return str;
}

void SetContentSize(UIScrollView *scrollView)
{
	if (scrollView != nil) {
		CGFloat maxY = 0;
		for (UIView *view in scrollView.subviews) {
			CGFloat y = view.frame.origin.y + view.frame.size.height;
			if (y > maxY)
				maxY = y;
		}

		CGSize size = scrollView.frame.size;

		scrollView.contentSize = CGSizeMake(size.width, maxY + 10);
	}
}
