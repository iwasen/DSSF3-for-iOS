//
//  Common.h
//  DSSF3
//
//  Created by 相沢伸一 on 2015/03/07.
//  Copyright (c) 2015年 aizawa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Global.h"
#import "FFT.h"
#import "AverageBuf.h"
#import "SetData.h"
#import "CtComboBox.h"
#import "CtButton.h"
#import "CtTextField.h"
#import "CtGroupBox.h"
#import "CtSlider.h"
#import "CtCheckBox.h"

#define MIN_FREQ 10.0
#define MAX_FREQ 20000.0

#define MIN_PHASE -180
#define MAX_PHASE 180

#define SG_MODE_TONE	0
#define SG_MODE_NOISE	1
#define SG_MODE_SWEEP	2
#define SG_MODE_PULSE	3
#define SG_MODE_SYNTH	4
#define SG_MODE_SCALE	5
#define SG_MODE_WAVE	6

#define FFT_MODE_PWS	0
#define FFT_MODE_OCT	1
#define FFT_MODE_3DD	2
#define FFT_MODE_CRF	3
#define FFT_MODE_PHS	4
#define FFT_MODE_SPG	5
#define FFT_MODE_CRS	6
#define FFT_MODE_COH	7
#define FFT_MODE_CEP	8
#define FFT_MODE_NUM	9

#define CH_MONO			0
#define CH_STEREO		1
#define CH_LEFT_ONLY	2
#define CH_RIGHT_ONLY	3
#define CH_DIFFERENCE	4

#define WAVE_SIN		0
#define WAVE_TRIANGLE	1
#define WAVE_SQUARE		2
#define WAVE_SAW		3
#define WAVE_USER		4

#define NOISE_WHITE		0
#define NOISE_PINK		1
#define NOISE_BROWN		2

#define NOISE_MODE_MONO		0
#define NOISE_MODE_STEREO	1
#define NOISE_MODE_INVERSE	2

#define MAX_OCT1		12
#define MAX_OCT3		40
#define OCT_BAND_NUM	5

#define dB10(x)	(x == 0 ? -1000 : log10((float)(x)) * 10)
#define dB20(x)	(x == 0 ? -1000 : log10((float)(x)) * 20)
#define PowDouble(v) ((float)((unsigned int)1 << (v - 1)))

#define MEMCLEAR(ptr,size)	memset(ptr,0,sizeof(*(ptr))*size)

#define RGB(r,g,b)          initWithRed:(float)r / 255 green:(float)g / 255 blue:(float)b / 255 alpha:1.0
#define COLOR_LEFT			RGB(0, 128, 255)
#define COLOR_RIGHT			RGB(255, 64, 192)
#define COLOR_LEFT_PEAK		RGB(0, 0, 255)
#define COLOR_RIGHT_PEAK	RGB(255, 0, 0)
#define COLOR_LEFT_LINE		RGB(160, 192, 255)
#define COLOR_RIGHT_LINE	RGB(255, 160, 192)
#define COLOR_LEFT_ZERO		RGB(0x33, 0x33, 0xee)
#define COLOR_RIGHT_ZERO	RGB(0xee, 0x33, 0x33)
#define COLOR_TEXT			RGB(0, 0, 0)
#define COLOR_GRAPH			RGB(255, 255, 255)
#define COLOR_LIGHTGRAY		RGB(192, 192, 192)
#define COLOR_GRAY			RGB(128, 128, 128)
#define COLOR_BLACK			RGB(0, 0, 0)
#define COLOR_WHITE			RGB(255, 255, 255)
#define COLOR_RED			RGB(255, 0, 0)
#define COLOR_GREEN			RGB(0, 192, 0)
#define COLOR_BLUE			RGB(0, 0, 255)
#define COLOR_LIGHTGREEN	RGB(160, 255, 160)
#define COLOR_PHASE			RGB(0x00, 0x80, 0xc0)
#define COLOR_CROSS			RGB(0x50, 0xa0, 0x50)
#define COLOR_CROSS_PEAK	RGB(0x00, 0x80, 0x00)
#define COLOR_COHERENCE		RGB(0xa0, 0x50, 0x20)
#define COLOR_OCTBAR        RGB(0xe0, 0xe0, 0xe0)
#define COLOR_SCALE_BG      RGB(0xe8, 0xe8, 0xe8)

#define FONT_SIZE_SCALE         17
#define FONT_SIZE_INDICATIOR    15
#define FONT_SIZE_OS            16

#define RTA_MIN_LEVEL	-80

#define N_WAVE_FORM	4

#define METHOD_MSEQ			0
#define METHOD_TSP			1

#define STAGE_OFFSET		10
#define STAGE_NUM			10

extern SetData *g_oSetData;
extern NSString *g_pFreqScale1[];
extern NSString *g_pFreqScale3[];
extern const int g_nOctBandTbl[];

extern void SetSampleRateList(CtComboBox *comboBox, int nDefault);
extern void SetChannelList(CtComboBox *comboBox, int nDefault);
extern void SetWindowFuncList(CtComboBox *comboBox);
extern int GetLinearScaleStep(int nMaxValue, int nMinvalue, int nScaleSize);
extern void SetFilterNameList(CtComboBox *comboBox);
extern void SetWaveFormList(CtComboBox *combo, int nSel);
extern int GetLogScaleStep(int nValue);
extern float GetLogScaleStep(float fValue);
extern float GetLinearScaleStep(float fRange, int nPixel, int *pStep);
extern int GetScaleStartValue(int nMinValue, int nStep);
extern float GetScaleStartValue(float fMinValue, float fStep);
extern void GetAxisName(int nMode, NSString **sNameX, NSString **sNameY);
extern void GetAxisUnit(int nMode, NSString **sUnitX, NSString **sUnitY);
extern NSString *GetNumberString(int nNumber);
extern void SetContentSize(UIScrollView *scrollView);
