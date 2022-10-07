//
//  AudioOutput.m
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2017/01/09.
//  Copyright © 2017年 TRC. All rights reserved.
//

#import "AudioOutput.h"

static AudioQueueRef _outputQueue;
static AudioQueueBufferRef _outputBuffers[NUM_BUFFERS];
static AUDIO_SAMPLE *_bufLeft;
static AUDIO_SAMPLE *_bufRight;
static AudioData _audioData;
static __weak id <AudioOutputData> _target;
static __weak id <AudioOutputData> _monitor;
static int _sampleRate;
static int _channels;
static int _samplePerBuffer;
static int _bufferSize;

@implementation AudioOutput

+ (void)prepare:(int)sampleRate :(int)channels :(int)samplePerBuffer :(id <AudioOutputData>)target
{
	[self stop];

	_sampleRate = sampleRate;
	_channels = channels;
	_samplePerBuffer = samplePerBuffer;
	_bufferSize = samplePerBuffer * channels * sizeof(AUDIO_SAMPLE);
	_target = target;

	[self allocBuffer];

	AudioInfo audioInfo;
	audioInfo.nSampleRate = sampleRate;
	audioInfo.nChannel = channels;
	audioInfo.nBufSize = samplePerBuffer;

	if ([_target respondsToSelector:@selector(audioOutputStart:)])
		[_target audioOutputStart:&audioInfo];

	if ([_monitor respondsToSelector:@selector(audioOutputStart:)])
		[_monitor audioOutputStart:&audioInfo];

	AudioStreamBasicDescription dataFormat;
	dataFormat.mSampleRate = _sampleRate;
	dataFormat.mFormatID = kAudioFormatLinearPCM;
	dataFormat.mFormatFlags = kAudioFormatFlagsNativeFloatPacked;
	dataFormat.mBytesPerPacket = sizeof(AUDIO_SAMPLE) * _channels;
	dataFormat.mFramesPerPacket = 1;
	dataFormat.mBytesPerFrame = sizeof(AUDIO_SAMPLE) * _channels;
	dataFormat.mChannelsPerFrame = _channels;
	dataFormat.mBitsPerChannel = NUM_BITS;
	dataFormat.mReserved = 0;

	AudioQueueNewOutput(&dataFormat, audioOutputCallback, (__bridge void *)(self), CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &_outputQueue);

	for (int i = 0; i < NUM_BUFFERS; i++) {
		AudioQueueAllocateBuffer(_outputQueue, _bufferSize, &_outputBuffers[i]);
		[self audioOutput :_outputQueue :_outputBuffers[i]];
	}
}

+ (void)start:(int)sampleRate :(int)channels :(int)samplePerBuffer :(id <AudioOutputData>)target
{
	[self prepare:sampleRate :channels :samplePerBuffer :target];
	[self start];
}

+ (void)start
{
	AudioQueueStart(_outputQueue, NULL);
}

+ (void)stop
{
	if (_outputQueue != nil) {
		AudioQueueFlush(_outputQueue);
		AudioQueueStop(_outputQueue, YES);
		for (int i = 0; i < NUM_BUFFERS; i++) {
			AudioQueueFreeBuffer(_outputQueue, _outputBuffers[i]);
		}
		AudioQueueDispose(_outputQueue, YES);

		_outputQueue = nil;

		if ([_target respondsToSelector:@selector(audioOutputStop)])
			[_target audioOutputStop];

		if ([_monitor respondsToSelector:@selector(audioOutputStop)])
			[_monitor audioOutputStop];

		_target = nil;
	}

	[self freeBuffer];
}

+ (void)reset
{
	AudioQueueReset(_outputQueue);
}

+ (void)setMonitor:(id <AudioOutputData>)monitor
{
	_monitor = monitor;
}

+ (int)getTime
{
	AudioTimeStamp timeStamp;
	AudioQueueGetCurrentTime(_outputQueue, NULL, &timeStamp, NULL);
	return (int)timeStamp.mSampleTime;
}

static void audioOutputCallback(
								void *outUserData,
								AudioQueueRef outAQ,
								AudioQueueBufferRef outBuffer)
{
	[(__bridge Class)outUserData audioOutput:outAQ :outBuffer];
}

+ (void)audioOutput:(AudioQueueRef)outAQ :(AudioQueueBufferRef)outBuffer
{
	if (outBuffer->mUserData == (void *)YES) {
		[self stop];
		return;
	}

	[_target audioOutputData:&_audioData];
	[_monitor audioOutputData:&_audioData];

	if (_audioData.nDataSize != 0) {
		AUDIO_SAMPLE *bufPtr = (AUDIO_SAMPLE *)outBuffer->mAudioData;

		for (int i = 0; i < _audioData.nDataSize; i++) {
			*bufPtr++ = _bufLeft[i];
			if (_channels == 2)
				*bufPtr++ = _bufRight[i];
		}

		outBuffer->mAudioDataByteSize = _audioData.nDataSize * _channels * sizeof(AUDIO_SAMPLE);
		outBuffer->mUserData = (void *)NO;
	} else {
		memset(outBuffer->mAudioData, 0, outBuffer->mAudioDataBytesCapacity);
		outBuffer->mAudioDataByteSize = outBuffer->mAudioDataBytesCapacity;
		outBuffer->mUserData = (void *)YES;
	}

	AudioQueueEnqueueBuffer(outAQ, outBuffer, 0, NULL);
}

+ (void)allocBuffer
{
	_bufLeft = new AUDIO_SAMPLE[_samplePerBuffer];
	_bufRight = new AUDIO_SAMPLE[_samplePerBuffer];

	_audioData.pLeftData = _bufLeft;
	_audioData.pRightData = _bufRight;
	_audioData.nChannel = _channels;
}

+ (void)freeBuffer
{
	if (_bufLeft != NULL) {
		delete [] _bufLeft;
		_bufLeft = NULL;
	}

	if (_bufRight != NULL) {
		delete [] _bufRight;
		_bufRight = NULL;
	}
}
/*
+ (void)dealloc
{
	[self freeBuffer];
}
*/
@end
