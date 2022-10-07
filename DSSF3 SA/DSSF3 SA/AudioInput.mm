//
//  AudioInput.m
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2017/01/09.
//  Copyright © 2017年 TRC. All rights reserved.
//

#import "AudioInput.h"

#define TOTAL_INPUT_BUF_SIZE	(65536 * 2)

@implementation AudioInput

static AudioQueueRef _inputQueue;
static AudioQueueBufferRef _inputBuffers[NUM_BUFFERS];
static AUDIO_SAMPLE *_bufLeft;
static AUDIO_SAMPLE *_bufRight;
static BOOL _bufFlag;
static int _bufNum;
static int _bufReadIndex;
static int _bufWriteIndex;
static int _bufDataSize;
static AudioData _audioData;
static __weak id <AudioInputData> _target;
static __weak id <AudioInputData> _monitor;
static int _sampleRate;
static int _channels;
static int _samplePerBuffer;
static int _bufferSize;
static NSTimer *_timer;

+ (void)prepare:(int)sampleRate :(int)channels :(int)samplePerBuffer :(id <AudioInputData>)target
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

	if ([_target respondsToSelector:@selector(audioInputStart:)])
		[_target audioInputStart:&audioInfo];

	if ([_monitor respondsToSelector:@selector(audioInputStart:)])
		[_monitor audioInputStart:&audioInfo];

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

	AudioQueueNewInput(&dataFormat, audioInputCallback, (__bridge void *)(self), CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &_inputQueue);

	for (int i = 0; i < NUM_BUFFERS; i++) {
		AudioQueueAllocateBuffer(_inputQueue, _bufferSize, &_inputBuffers[i]);
		AudioQueueEnqueueBuffer(_inputQueue, _inputBuffers[i], 0, NULL);
	}
}

+ (void)start:(int)sampleRate :(int)channels :(int)samplePerBuffer :(id <AudioInputData>)target
{
	[self prepare:sampleRate :channels :samplePerBuffer :target];
	[self start];
}

+ (void)start
{
	AudioQueueStart(_inputQueue, NULL);

	_timer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)_samplePerBuffer / _sampleRate target:self selector:@selector(timerEvent:) userInfo:nil repeats:YES];
}

+ (void)stop
{
	if (_timer != nil) {
		[_timer invalidate];
		_timer = nil;
	}

	if (_inputQueue != nil) {
		AudioQueueFlush(_inputQueue);
		AudioQueueStop(_inputQueue, YES);
		for (int i = 0; i < NUM_BUFFERS; i++) {
			AudioQueueFreeBuffer(_inputQueue, _inputBuffers[i]);
		}
		AudioQueueDispose(_inputQueue, YES);

		_inputQueue = nil;

		if ([_target respondsToSelector:@selector(audioInputStop)])
			[_target audioInputStop];

		if ([_monitor respondsToSelector:@selector(audioInputStop)])
			[_monitor audioInputStop];

		_target = nil;
	}

	[self freeBuffer];
}

+ (void)reset
{
	AudioQueueReset(_inputQueue);
}

+ (void)setMonitor:(id <AudioInputData>)monitor
{
	_monitor = monitor;
}

+ (int)getTime
{
	AudioTimeStamp timeStamp;
	AudioQueueGetCurrentTime(_inputQueue, NULL, &timeStamp, NULL);
	return (int)timeStamp.mSampleTime;
}

static void audioInputCallback(
							   void* inUserData,
							   AudioQueueRef inAQ,
							   AudioQueueBufferRef inBuffer,
							   const AudioTimeStamp *inStartTime,
							   UInt32 inNumberPacketDescriptions,
							   const AudioStreamPacketDescription *inPacketDescs)
{
	[(__bridge Class)inUserData audioInput:inAQ :inBuffer];
}

+ (void)audioInput:(AudioQueueRef)inAQ :(AudioQueueBufferRef)inBuffer
{
	int dataSize = inBuffer->mAudioDataByteSize / (_channels * sizeof(AUDIO_SAMPLE));
	AUDIO_SAMPLE *bufPtr = (AUDIO_SAMPLE *)inBuffer->mAudioData;

	for (;;) {
		int copySize = MIN(dataSize, _samplePerBuffer - _bufDataSize);
		if (copySize == 0)
			break;

		if (_bufFlag && _bufWriteIndex == _bufReadIndex) {
			DLog(@"write overflow");
			break;
		}

		int bufPos = _samplePerBuffer * _bufWriteIndex + _bufDataSize;
		for (int i = 0; i < copySize; i++) {
			_bufLeft[bufPos + i] = *bufPtr++;
            if (_channels == 2) {
				_bufRight[bufPos + i] = *bufPtr++;
#ifdef DEBUG
                _bufRight[bufPos + i] *= 2;
#endif
            }
		}

		dataSize -= copySize;
		_bufDataSize += copySize;
		if (_bufDataSize >= _samplePerBuffer) {
			_bufFlag = YES;
			_bufWriteIndex = (_bufWriteIndex + 1) % _bufNum;
			_bufDataSize = 0;
		}
	}

	AudioQueueEnqueueBuffer(_inputQueue, inBuffer, 0, NULL);
}

+ (void)timerEvent:(NSTimer *)timer
{
	if (_timer != nil && _bufFlag) {
		_audioData.pLeftData = &_bufLeft[_samplePerBuffer * _bufReadIndex];
		_audioData.pRightData = &_bufRight[_samplePerBuffer * _bufReadIndex];
		_audioData.nDataSize = _samplePerBuffer;
		_audioData.nChannel = _channels;

		[_target audioInputData:&_audioData];
		[_monitor audioInputData:&_audioData];

		_bufReadIndex = (_bufReadIndex + 1) % _bufNum;
		if (_bufReadIndex == _bufWriteIndex)
			_bufFlag = NO;

		if (_audioData.nDataSize == 0)
			[self stop];
	} else
		DLog(@"read overflow");
}

+ (void)allocBuffer
{
	_bufNum = TOTAL_INPUT_BUF_SIZE / _bufferSize;
	if (_bufNum < 3)
		_bufNum = 3;

	int bufSize = _samplePerBuffer * _bufNum;
	DLog(@"bufNum=%d bufSize=%d", _bufNum, bufSize);
	_bufLeft = new AUDIO_SAMPLE[bufSize];
	_bufRight = new AUDIO_SAMPLE[bufSize];

	_bufFlag = NO;
	_bufReadIndex = 0;
	_bufWriteIndex = 0;
	_bufDataSize = 0;
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
