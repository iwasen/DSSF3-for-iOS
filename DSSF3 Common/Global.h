//
//  Global.h
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/08.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <UIKit/UIKit.h>

#define IS_PAD      ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#define IS_PHONE    ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)

#define WF_RECTANGLAR	0
#define WF_TRIANGLAR	1
#define WF_HAMMING		2
#define WF_HANNING		3
#define WF_BLACKMAN		4
#define WF_BLACKMANHARRIS	5
#define WF_FLATTOP		6
#define WF_NUM			7

#define PowFloat(v) ((float)((unsigned long)1 << (v - 1)))

extern void MakeWindowFunc(int type, int size, float *data, float fMul = 1);
extern float GetMaxData(const float *pData, int nData);
extern void MessageBox(UIViewController *viewController, NSString *title, NSString *msg, NSString *button1, void (^handler1)(UIAlertAction *action), BOOL preferredAction1, NSString *button2, void (^handler2)(UIAlertAction *action), BOOL preferredAction2);
extern void MessageBoxOK(UIViewController *viewController, NSString *title, void (^handlerOK)(UIAlertAction *action));
extern void MessageBoxOKCalcel(UIViewController *viewController, NSString *title, void (^handlerOK)(UIAlertAction *action), void (^handlerCancel)(UIAlertAction *action));
extern NSURL *SaveWavFile(float *pLeftData, float *pRightData, int channels, int sampleRate, int numSample, NSString *filePath);
extern BOOL ReadWavFile(float **pLeftData, float **pRightData, int *channels, int *sampleRate, int *numSample, NSString *filePath);
extern int ConvertToInt(float fData, int nBits);
extern void CopyWaveFromDouble(void *pWaveData, const float *pLeftData, const float *pRightData, int nDataNum, int nBits, float fMul);
extern void CopyWaveToDouble(const void *pWaveData, float *pLeftData, float *pRightData, int nDataNum, int nBits);
extern CGFloat AdjustFontSize(CGFloat fontSize, CGFloat iPhoneSize = 0.75);
