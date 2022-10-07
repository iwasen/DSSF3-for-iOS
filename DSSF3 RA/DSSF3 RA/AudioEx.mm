//
//  AudioEx.m
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2017/01/23.
//  Copyright © 2017年 TRC. All rights reserved.
//

#import "AudioEx.h"

static int _recMode = REC_MODE_RECORD;
static __weak id <AudioRecorder> _recTarget;
static __weak id <AudioInputData> _inputTarget;
static __weak id <AudioOutputData> _outputTarget;
static BOOL _inputOpenFlag;

@implementation AudioEx

+ (void)setRecMode:(int)recMode :(id <AudioRecorder>)target
{
	_recMode = recMode;
	_recTarget = target;
}

+ (int)getPlaybackSampleRate
{
	if (_recMode == REC_MODE_PLAY && _recTarget != nil) {
		return [_recTarget getSampleRate];
	}
	return 0;
}

+ (void)audioInputStart:(AudioInfo *)audioInfo
{
	[_recTarget audioRecordStart:audioInfo];

	if ([_inputTarget respondsToSelector:@selector(audioInputStart:)])
		[_inputTarget audioInputStart:audioInfo];
}

+ (void)audioInputStop
{
	[_recTarget audioRecordStop];

	if ([_inputTarget respondsToSelector:@selector(audioInputStop)])
		[_inputTarget audioInputStop];
}

+ (void)audioInputData:(AudioData *)audioData
{
	[_recTarget audioRecordData:audioData];

	[_inputTarget audioInputData:audioData];
}

+ (void)audioOutputStart:(AudioInfo *)audioInfo
{
	switch (_recMode) {
		case REC_MODE_RECORD:
			[_recTarget audioRecordStart:audioInfo];

			if ([_outputTarget respondsToSelector:@selector(audioOutputStart:)])
				[_outputTarget audioOutputStart:audioInfo];
			break;
		case REC_MODE_PLAY:
			[_recTarget audioPlayStart:audioInfo];

			if ([_inputTarget respondsToSelector:@selector(audioInputStart:)])
				[_inputTarget audioInputStart:audioInfo];
			break;
	}
}

+ (void)audioOutputStop
{
	switch (_recMode) {
		case REC_MODE_RECORD:
			[_recTarget audioRecordStop];

			if ([_outputTarget respondsToSelector:@selector(audioOutputStop)])
				[_outputTarget audioOutputStop];
			break;
		case REC_MODE_PLAY:
			[_recTarget audioPlayStop];

			if ([_inputTarget respondsToSelector:@selector(audioInputStop)])
				[_inputTarget audioInputStop];
			break;
	}
}

+ (void)audioOutputData:(AudioData *)audioData
{
	switch (_recMode) {
		case REC_MODE_RECORD:
			[_outputTarget audioOutputData:audioData];

			if (!_inputOpenFlag)
				[_recTarget audioRecordData:audioData];
			break;
		case REC_MODE_PLAY:
			[_recTarget audioPlayData:audioData];

			if (audioData->nDataSize != 0)
				[_inputTarget audioInputData:audioData];
			break;
	}
}

@end

@implementation AudioInputEx

+ (void)prepare:(int)sampleRate :(int)channels :(int)samplePerBuffer :(id <AudioInputData>)target
{
	switch (_recMode) {
		case REC_MODE_RECORD:
			_inputTarget = target;
			[AudioInput prepare:sampleRate :channels :samplePerBuffer :(id <AudioInputData>)AudioEx.class];
			break;
		case REC_MODE_PLAY:
			_inputTarget = target;
			[AudioOutput prepare:sampleRate :channels :samplePerBuffer :(id <AudioOutputData>)AudioEx.class];
			break;
		default:
			_inputTarget = nil;
			[AudioInput prepare:sampleRate :channels :samplePerBuffer :target];
			break;
	}
}

+ (void)start:(int)sampleRate :(int)channels :(int)samplePerBuffer :(id <AudioInputData>)target
{
	[self prepare:sampleRate :channels :samplePerBuffer :target];
	[self start];
}

+ (void)start
{
	if (_recMode == REC_MODE_PLAY)
		[AudioOutput start];
	else
		[super start];
}

+ (void)stop
{
	if (_recMode == REC_MODE_PLAY)
		[AudioOutput stop];
	else
		[super stop];
}

+ (void)reset
{
	if (_recMode == REC_MODE_PLAY)
		[AudioOutput reset];
	else
		[super reset];
}

+ (int)getTime
{
	if (_recMode == REC_MODE_PLAY)
		return [AudioOutput getTime];
	else
		return [super getTime];
}

@end

@implementation AudioOutputEx

+ (void)prepare:(int)sampleRate :(int)channels :(int)samplePerBuffer :(id <AudioOutputData>)target
{
	if (_recMode == REC_MODE_RECORD && !_inputOpenFlag) {
		_outputTarget = target;
		[super prepare:sampleRate :channels :samplePerBuffer :(id <AudioOutputData>)AudioEx.class];
	} else {
		_outputTarget = nil;
		[super prepare:sampleRate :channels :samplePerBuffer :target];
	}
}

+ (void)start:(int)sampleRate :(int)channels :(int)samplePerBuffer :(id <AudioOutputData>)target
{
	[self prepare:sampleRate :channels :samplePerBuffer :target];
	[super start];
}

@end
