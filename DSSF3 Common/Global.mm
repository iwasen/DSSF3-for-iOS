//
//  Global.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/08/08.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import "Global.h"
#import "Common.h"
#import <AudioToolbox/AudioToolbox.h>

void MakeWindowFunc(int type, int size, float *data, float fMul)
{
	int i;
	float m = fMul / size;
	float fTemp;

	switch (type) {
		case WF_RECTANGLAR:
			break;
		case WF_TRIANGLAR:
			m *= sqrt(3.0);
			break;
		case WF_HAMMING:
			m /= sqrt(0.3974);
			break;
		case WF_HANNING:
			m /= sqrt(0.375);
			break;
		case WF_BLACKMAN:
			m /= sqrt(0.3046);
			break;
		case WF_BLACKMANHARRIS:
			m /= sqrt(0.257963355);
			break;
		case WF_FLATTOP:
			m /= sqrt(3.770284);
			break;
	}

	int size1 = size - 1;

	for (i = 0; i < size; i++) {
		switch (type) {
			case WF_RECTANGLAR:
				*data++ = m;
				break;
			case WF_TRIANGLAR:
				*data++ = (float)(1.0 - abs(size / 2 - i) / (size / 2)) * m;
				break;
			case WF_HAMMING:
				*data++ = (float)(0.54 - 0.46 * cos(2 * M_PI * i / (size1))) * m;
				break;
			case WF_HANNING:
				*data++ = (float)(0.5 - 0.5 * cos(2 * M_PI * i / (size1))) * m;
				break;
			case WF_BLACKMAN:
				fTemp = 2 * M_PI * i / size1;
				*data++ = (float)(0.42 - 0.5 * cos(fTemp) + 0.08 * cos(2 * fTemp)) * m;
				break;
			case WF_BLACKMANHARRIS:
				fTemp = 2 * M_PI * i / size1;
				*data++ = (float)(0.35875 - 0.48829 * cos(fTemp) + 0.14128 * cos(2 * fTemp) - 0.01168 * cos(3 * fTemp)) * m;
				break;
			case WF_FLATTOP:
				fTemp = 2 * M_PI * i / size1;
				*data++ = (float)(1 - 1.93 * cos(fTemp) + 1.29 * cos(2 * fTemp) - 0.388 * cos(3 * fTemp) + 0.032 * cos(4 * fTemp)) * m;
				break;
		}
	}
}

float GetMaxData(const float *pData, int nData)
{
	float fMaxData = 0;

	if (pData != NULL) {
		int i;
		float fAbs;

		for (i = 0; i < nData; i++) {
			fAbs = fabs(*pData++);

			if (fAbs > fMaxData)
				fMaxData = fAbs;
		}
	}

	return fMaxData;
}

void MessageBox(UIViewController *viewController, NSString *title, NSString *msg, NSString *button1, void (^handler1)(UIAlertAction *action), BOOL preferredAction1, NSString *button2, void (^handler2)(UIAlertAction *action), BOOL preferredAction2)
{
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];

	if (viewController == nil) {
		viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
		while (viewController.presentedViewController) {
			viewController = viewController.presentedViewController;
		}
	}

	if (button1 != nil) {
		UIAlertAction *alertAction = [UIAlertAction actionWithTitle:button1 style:UIAlertActionStyleDefault handler:handler1];
		[alertController addAction:alertAction];
		if (preferredAction1)
			alertController.preferredAction = alertAction;
	}

	if (button2 != nil) {
		UIAlertAction *alertAction = [UIAlertAction actionWithTitle:button2 style:UIAlertActionStyleDefault handler:handler2];
		[alertController addAction:alertAction];
		if (preferredAction2)
			alertController.preferredAction = alertAction;
	}

	[viewController presentViewController:alertController animated:YES completion:nil];
}

void MessageBoxOK(UIViewController *viewController, NSString *title, void (^handlerOK)(UIAlertAction *action))
{
	MessageBox(viewController, title, nil, @"OK", handlerOK, FALSE, nil, nil, FALSE);
}

void MessageBoxOKCalcel(UIViewController *viewController, NSString *title, void (^handlerOK)(UIAlertAction *action), void (^handlerCancel)(UIAlertAction *action))
{
	MessageBox(viewController, title, nil, NSLocalizedString(@"IDS_CANCEL", nil), handlerCancel, FALSE, @"OK", handlerOK, TRUE);
}

NSURL *SaveWavFile(float *pLeftData, float *pRightData, int channels, int sampleRate, int numSample, NSString *filePath)
{
	AudioStreamBasicDescription outputFormat = {0};
	outputFormat.mSampleRate = sampleRate;
	outputFormat.mFormatID = kAudioFormatLinearPCM;
	outputFormat.mBitsPerChannel = sizeof(Float32) * 8;
	outputFormat.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked;
	outputFormat.mFramesPerPacket = 1;
	outputFormat.mChannelsPerFrame = channels;
	outputFormat.mBytesPerFrame = sizeof(Float32) * channels;
	outputFormat.mBytesPerPacket = sizeof(Float32) * channels;

	NSURL *url = [NSURL fileURLWithPath:filePath];
	CFURLRef outputFileURL = (__bridge CFURLRef)url;
	AudioFileID outAudioFile;
	AudioFileCreateWithURL(outputFileURL, kAudioFileWAVEType, &outputFormat, kAudioFileFlags_EraseFile, &outAudioFile);

	UInt32 sizeOfBuffer = (UInt32)(numSample * channels) * sizeof(Float32);
	Float32 *audioBuffer = new Float32[numSample * channels];
	for (int i = 0; i < numSample; i++) {
		if (channels == 1)
			audioBuffer[i] = pLeftData[i];
		else if (channels == 2) {
			audioBuffer[i * 2] = pLeftData[i];
			audioBuffer[i * 2 + 1] = pRightData[i];
		}
	}

	// Write to Output File
	AudioFileWriteBytes(outAudioFile, FALSE, 0, &sizeOfBuffer, audioBuffer);

	AudioFileClose(outAudioFile);

	delete [] audioBuffer;

	return url;
}

BOOL ReadWavFile(float **pLeftData, float **pRightData, int *channels, int *sampleRate, int *numSample, NSString *filePath)
{
	NSURL *url = [NSURL fileURLWithPath:filePath];
	CFURLRef inputFileURL = (__bridge CFURLRef)url;
	AudioFileID inAudioFile;
	AudioFileOpenURL(inputFileURL,
					 kAudioFileReadPermission,
					 0,
					 &inAudioFile);
    if (!inAudioFile) {
        NSLog(@"AudioFileOpenURL failed");
        return FALSE;
    }

	AudioStreamBasicDescription mFileDescription;
	// 読みこんだファイルの基本情報を mFileDescription へ
	UInt32 propertySize = sizeof(AudioStreamBasicDescription);
	if(AudioFileGetProperty(inAudioFile, kAudioFilePropertyDataFormat,
							&propertySize, &mFileDescription)) {
		NSLog(@"AudioFileGetProperty failed");
		AudioFileClose(inAudioFile);
		return FALSE;
	}

	SInt64 dataSize64;
	UInt32 dataSize;
	propertySize = sizeof(SInt64);
	AudioFileGetProperty(inAudioFile,
						 kAudioFilePropertyAudioDataByteCount,
						 &propertySize,
						 &dataSize64);
	dataSize = (UInt32)dataSize64;
	int samples = dataSize / mFileDescription.mBytesPerPacket;

	u_char *audioBuffer = NULL;
	float *left = NULL;
	float *right = NULL;

	try {
		audioBuffer = new u_char[dataSize];
		UInt32 ioBumBytes = dataSize;
		AudioFileReadBytes(inAudioFile, false, 0, &ioBumBytes, audioBuffer);
        
		left = new float[samples];
		if (mFileDescription.mChannelsPerFrame == 2)
			right = new float[samples];

        CopyWaveToDouble(audioBuffer, left, right, samples, (int)mFileDescription.mBitsPerChannel);

		delete [] audioBuffer;

		*channels = mFileDescription.mChannelsPerFrame;
		*sampleRate = mFileDescription.mSampleRate;
		*numSample = samples;
		*pLeftData = left;
		*pRightData = right;
	} catch (...) {
		if (audioBuffer != NULL)
			delete [] audioBuffer;
		if (left != NULL)
			delete [] left;
		if (right != NULL)
			delete [] right;

		return FALSE;
	}

	return TRUE;
}

int ConvertToInt(float fData, int nBits)
{
    double fMax = PowFloat(nBits);
    fData *= fMax - 1;
    
    if (fData > fMax - 1)
        fData = fMax - 1;
    else if (fData < -fMax)
        fData = -fMax;
    
    return (int)floor(fData + 0.5);
}

void CopyWaveFromDouble(void *pWaveData, const float *pLeftData, const float *pRightData, int nDataNum, int nBits, float fMul)
{
    u_char *bp;
    short *sp;
    float *fp;
    int i;
    union {
        int i;
        u_char b[4];
    } ib;
    
    switch (nBits) {
        case 16:
            sp = (short *)pWaveData;
            for (i = 0; i < nDataNum; i++) {
                *sp++ = (short)ConvertToInt(*pLeftData++ * fMul, 16);
                if (pRightData != NULL)
                    *sp++ = (short)ConvertToInt(*pRightData++ * fMul, 16);
            }
            break;
        case 24:
            bp = (u_char *)pWaveData;
            for (i = 0; i < nDataNum; i++) {
                ib.i = ConvertToInt(*pLeftData++ * fMul, 24);
                *bp++ = ib.b[0];
                *bp++ = ib.b[1];
                *bp++ = ib.b[2];
                
                if (pRightData != NULL) {
                    ib.i = ConvertToInt(*pRightData++ * fMul, 24);
                    *bp++ = ib.b[0];
                    *bp++ = ib.b[1];
                    *bp++ = ib.b[2];
                }
            }
            break;
        case 32:
            fp = (float *)pWaveData;
            for (i = 0; i < nDataNum; i++) {
                *fp++ = (float)(*pLeftData++ * fMul);
                if (pRightData != NULL)
                    *fp++ = (float)(*pRightData++ * fMul);
            }
            break;
    }
}

void CopyWaveToDouble(const void *pWaveData, float *pLeftData, float *pRightData, int nDataNum, int nBits)
{
    u_char *bp;
    short *sp;
    float *fp;
    int i;
    union {
        int i;
        u_char b[4];
    } ib;
    
    switch (nBits) {
        case 8:
            bp = (u_char *)pWaveData;
            for (i = 0; i < nDataNum; i++) {
                *pLeftData++ = (char)(*bp++ - 128) / PowFloat(8);
                if (pRightData != NULL)
                    *pRightData++ = (char)(*bp++ - 128) / PowFloat(8);
            }
            break;
        case 16:
            sp = (short *)pWaveData;
            for (i = 0; i < nDataNum; i++) {
                *pLeftData++ = *sp++ / PowFloat(16);
                if (pRightData != NULL)
                    *pRightData++ = *sp++ / PowFloat(16);
            }
            break;
        case 24:
            bp = (u_char *)pWaveData;
            ib.b[0] = 0;
            for (i = 0; i < nDataNum; i++) {
                ib.b[1] = *bp++;
                ib.b[2] = *bp++;
                ib.b[3] = *bp++;
                *pLeftData++ = ib.i / PowFloat(32);
                
                if (pRightData != NULL) {
                    ib.b[1] = *bp++;
                    ib.b[2] = *bp++;
                    ib.b[3] = *bp++;
                    *pRightData++ = ib.i / PowFloat(32);
                }
            }
            break;
        case 32:
            fp = (float *)pWaveData;
            
            double fAdj = 1;
            for (i = 0; i < nDataNum; i++) {
                if (fp[i] > 1.0) {
                    fAdj = 1.0 / PowFloat(16);
                    break;
                }
            }
            
            for (i = 0; i < nDataNum; i++) {
                *pLeftData++ = *fp++ * fAdj;
                if (pRightData != NULL)
                    *pRightData++ = *fp++ * fAdj;
            }
            break;
    }
}

CGFloat AdjustFontSize(CGFloat fontSize, CGFloat iPhoneSize)
{
	return IS_PHONE ? fontSize * iPhoneSize : fontSize;
}
