//
//  MMDB.m
//  DSSF3 SA
//
//  Created by 相沢伸一 on 2015/07/21.
//  Copyright (c) 2015年 TRC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "MMDB.h"

#define MMTYPE_WAV		0x1411

struct WaveBinaryData
{
	int size;
	char *data;
};

static OSStatus readFunc(void *inClientData, SInt64 inPosition, UInt32 requestCount, void *buffer, UInt32 *actualCount)
{
	WaveBinaryData *pWaveData =(WaveBinaryData *)inClientData;
	memcpy(buffer, pWaveData->data + inPosition, requestCount);
	*actualCount = requestCount;

	return errSecSuccess;
}

static SInt64 getSizeFunc(void *inClientData)
{
	WaveBinaryData *pWaveData =(WaveBinaryData *)inClientData;
	return pWaveData->size;
}

static HWAVEDATA ReadWavDB(CPSDB &db, int binarySize)
{
	HWAVEDATA hWaveData = NULL;
	WaveBinaryData waveData;
	waveData.size = binarySize;
	waveData.data = new char[binarySize];
	LONG readNum;
	db.DBReadBinary(NULL, waveData.data, binarySize, &readNum);

	AudioFileID audioFileID;
	AudioFileOpenWithCallbacks(&waveData, readFunc, NULL, getSizeFunc, NULL, kAudioFileWAVEType, &audioFileID);

	AudioStreamBasicDescription fileDescription;
	UInt32 propertySize = sizeof(AudioStreamBasicDescription);
	if (AudioFileGetProperty(audioFileID, kAudioFilePropertyDataFormat, &propertySize, &fileDescription) == errSecSuccess) {
		SInt64 dataSize64;
		UInt32 dataSize;
		// 読みこんだファイルのデータ部のバイト数を dataSize へ
		propertySize = sizeof (SInt64);
		if (AudioFileGetProperty(audioFileID, kAudioFilePropertyAudioDataByteCount, &propertySize, &dataSize64) == errSecSuccess) {
			dataSize = (UInt32)dataSize64;
			hWaveData = new char[sizeof(WAVEDATA) + dataSize];
			PWAVEDATA pWaveData = (PWAVEDATA)hWaveData;
			pWaveData->nChannels = fileDescription.mChannelsPerFrame;
			pWaveData->nBitsPerSample = fileDescription.mBitsPerChannel;
			pWaveData->nSamplesPerSec = fileDescription.mSampleRate;
			pWaveData->dataSize = dataSize;
			AudioFileReadBytes(audioFileID, false, 0, &dataSize, pWaveData->waveData);
		}
	}

	AudioFileClose(audioFileID);

	delete [] waveData.data;

	return hWaveData;
}

HWAVEDATA MMWaveReadDB(CPSDB &db, LPCTSTR fieldName)
{
	SHORT	mmType;
	HWAVEDATA hWaveData = NULL;
	int binarySize;
	int readSize;

	if (db.DBGetBinarySize(fieldName, &binarySize) == 0) {
		if (db.DBReadBinary(fieldName, &mmType, 2, &readSize) == 0) {
			switch (mmType) {
				case MMTYPE_WAV:
					hWaveData = ReadWavDB(db, binarySize - 2);
					break;
			}
		}
	}

	return hWaveData;
}

void MMWaveWriteDB(CPSDB &db, LPCTSTR fieldName, const char *data, int dataSize)
{
	SHORT	mmType = MMTYPE_WAV;

	db.DBWriteBinary(fieldName, &mmType, 2);
	db.DBWriteBinary(NULL, data, dataSize);
}
