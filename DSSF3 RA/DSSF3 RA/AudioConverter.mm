//
//  AudioConverter.m
//  DSSF3 RA
//
//  Created by 相沢伸一 on 2019/08/19.
//  Copyright © 2019 TRC. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <AudioToolbox/AudioToolbox.h>

#ifndef MAC_OS_X_VERSION_10_7
// CoreServices defines eofErr, replaced in 10.7 by kAudioFileEndOfFileError
#include <CoreServices/CoreServices.h>
#endif


#define kInputFileLocation    CFSTR("/Insert/Path/To/Audio/File.xxx")
// #define kInputFileLocation    CFSTR("/Users/kevin/Desktop/tmp_storage/audio_tests/cdsd_scratch.aiff")
// #define kInputFileLocation    CFSTR("/Volumes/Sephiroth/Tunes//菅野よう子/ESCAFLOWNE - ORIGINAL MOVIE SOUNDTRACK/We're flying.m4a")

typedef struct MyAudioConverterSettings
{
    AudioStreamBasicDescription inputFormat; // input file's data stream description
    AudioStreamBasicDescription outputFormat; // output file's data stream description
    
    AudioFileID                   inputFile; // reference to your input file
    NSMutableData                *outputData; // reference to your output data
    
    UInt64                        inputFilePacketIndex; // current packet index in input file
    UInt64                        inputFilePacketCount; // total number of packts in input file
    UInt32                        inputFilePacketMaxSize; // maximum size a packet in the input file can be
    AudioStreamPacketDescription *inputFilePacketDescriptions; // array of packet descriptions for read buffer
    
    // KEVIN: sourceBuffer is never used outside of the callback. why couldn't it be a local there?
    UInt8 *sourceBuffer;
    UInt32 outputBufferSize;
} MyAudioConverterSettings;

static void CheckResult(OSStatus result)
{
    if (result != noErr)
        @throw [NSString stringWithFormat:@"%x", result];
}

OSStatus MyAudioConverterCallback(AudioConverterRef inAudioConverter,
                                  UInt32 *ioDataPacketCount,
                                  AudioBufferList *ioData,
                                  AudioStreamPacketDescription **outDataPacketDescription,
                                  void *inUserData);
void Convert(MyAudioConverterSettings *mySettings);


#pragma mark - utility functions -


#pragma mark - audio converter -

OSStatus MyAudioConverterCallback(AudioConverterRef inAudioConverter,
                                  UInt32 *ioDataPacketCount,
                                  AudioBufferList *ioData,
                                  AudioStreamPacketDescription **outDataPacketDescription,
                                  void *inUserData)
{
    MyAudioConverterSettings *audioConverterSettings = (MyAudioConverterSettings *)inUserData;
    
    // initialize in case of failure
    ioData->mBuffers[0].mData = NULL;
    ioData->mBuffers[0].mDataByteSize = 0;
    
    // if there are not enough packets to satisfy request, then read what's left
    if (audioConverterSettings->inputFilePacketIndex + *ioDataPacketCount > audioConverterSettings->inputFilePacketCount)
        *ioDataPacketCount = (UInt32)(audioConverterSettings->inputFilePacketCount - audioConverterSettings->inputFilePacketIndex);
    
    if(*ioDataPacketCount == 0)
        return noErr;
    
    if (audioConverterSettings->sourceBuffer != NULL)
    {
        delete [] audioConverterSettings->sourceBuffer;
        audioConverterSettings->sourceBuffer = NULL;
    }
    
    UInt32 ioNumBytes = *ioDataPacketCount * audioConverterSettings->inputFilePacketMaxSize;
    audioConverterSettings->sourceBuffer = new UInt8[ioNumBytes];
    
    OSStatus result = AudioFileReadPacketData(audioConverterSettings->inputFile, true, &ioNumBytes, audioConverterSettings->inputFilePacketDescriptions, audioConverterSettings->inputFilePacketIndex, ioDataPacketCount, audioConverterSettings->sourceBuffer);
/*
    OSStatus result = AudioFileReadPackets(audioConverterSettings->inputFile,
                                           true,
                                           &outByteCount,
                                           audioConverterSettings->inputFilePacketDescriptions,
                                           audioConverterSettings->inputFilePacketIndex,
                                           ioDataPacketCount,
                                           audioConverterSettings->sourceBuffer);
*/
    // it's not an error if we just read the remainder of the file
#ifdef MAC_OS_X_VERSION_10_7
    if (result == kAudioFileEndOfFileError && *ioDataPacketCount) result = noErr;
#else
    if (result == eofErr && *ioDataPacketCount) result = noErr;
#endif
    else if (result != noErr) return result;
    
    audioConverterSettings->inputFilePacketIndex += *ioDataPacketCount;
    
    // KEVIN: in "// initialize in case of failure", we assumed there was only 1
    // buffer (since we set it up ourselves in Convert()). so why be careful to
    // iterate over potentially multiple buffers here?
    /*
     UInt32 bufferIndex;
     for (bufferIndex = 0; bufferIndex < ioData->mNumberBuffers; bufferIndex++)
     {
     ioData->mBuffers[bufferIndex].mData = audioConverterSettings->sourceBuffer;
     ioData->mBuffers[bufferIndex].mDataByteSize = outByteCount;
     }
     */
    // chris' hacky asssume-one-buffer equivalent
    ioData->mBuffers[0].mData = audioConverterSettings->sourceBuffer;
    ioData->mBuffers[0].mDataByteSize = ioNumBytes;
    
    if (outDataPacketDescription)
        *outDataPacketDescription = audioConverterSettings->inputFilePacketDescriptions;
    
    return result;
}

void Convert(MyAudioConverterSettings *mySettings)
{
    // create audioConverter object
    AudioConverterRef    audioConverter;
    CheckResult(AudioConverterNew(&mySettings->inputFormat, &mySettings->outputFormat, &audioConverter));

    // allocate packet descriptions if the input file is VBR
    UInt32 packetsPerBuffer = 0;
    UInt32 outputBufferSize = 32 * 1024; // 32 KB is a good starting point
    UInt32 sizePerPacket = mySettings->inputFormat.mBytesPerPacket;
    if (sizePerPacket == 0)
    {
        UInt32 size = sizeof(sizePerPacket);
        CheckResult(AudioConverterGetProperty(audioConverter, kAudioConverterPropertyMaximumOutputPacketSize, &size, &sizePerPacket));
        
        // make sure the buffer is large enough to hold at least one packet
        if (sizePerPacket > outputBufferSize)
            outputBufferSize = sizePerPacket;
        
        packetsPerBuffer = outputBufferSize / sizePerPacket;
        mySettings->inputFilePacketDescriptions = new AudioStreamPacketDescription[packetsPerBuffer];
        
    }
    else
    {
        packetsPerBuffer = outputBufferSize / sizePerPacket;
    }
    
    // allocate destination buffer
    Float32 *outputBuffer = new Float32[outputBufferSize]; // CHRIS: not sizeof(UInt8*). check book text!
    mySettings->outputBufferSize = outputBufferSize;
    
    UInt32 outputFilePacketPosition = 0; //in bytes
    while(1)
    {
        // wrap the destination buffer in an AudioBufferList
        AudioBufferList convertedData;
        convertedData.mNumberBuffers = 1;
        convertedData.mBuffers[0].mNumberChannels = mySettings->inputFormat.mChannelsPerFrame;
        convertedData.mBuffers[0].mDataByteSize = outputBufferSize;
        convertedData.mBuffers[0].mData = outputBuffer;
        
        // now call the audioConverter to transcode the data. This function will call
        // the callback function as many times as required to fulfill the request.
        UInt32 ioOutputDataPackets = packetsPerBuffer;
        OSStatus error = AudioConverterFillComplexBuffer(audioConverter,
                                                         MyAudioConverterCallback,
                                                         mySettings,
                                                         &ioOutputDataPackets,
                                                         &convertedData,
                                                         (mySettings->inputFilePacketDescriptions ? mySettings->inputFilePacketDescriptions : nil));
        if (error || !ioOutputDataPackets)
        {
            //        fprintf(stderr, "err: %ld, packets: %ld\n", err, ioOutputDataPackets);
            break;    // this is our termination condition
        }
        
        // write the converted data to the output file
        // KEVIN: QUESTION: 3rd arg seems like it should be a byte count, not packets. why does this work?
        [mySettings->outputData appendBytes:convertedData.mBuffers[0].mData length:convertedData.mBuffers[0].mDataByteSize];
/*
        AudioFileWritePackets(mySettings->outputFile,
                                           FALSE,
                                           ioOutputDataPackets,
                                           NULL,
                                           outputFilePacketPosition / mySettings->outputFormat.mBytesPerPacket,
                                           &ioOutputDataPackets,
                              convertedData.mBuffers[0].mData);
*/
        // advance the output file write location
        outputFilePacketPosition += (ioOutputDataPackets * mySettings->outputFormat.mBytesPerPacket);
    }
    
    delete [] outputBuffer;
    
    if (mySettings->inputFilePacketDescriptions)
        delete [] mySettings->inputFilePacketDescriptions;
    
    AudioConverterDispose(audioConverter);
}

bool AudioConverter(NSURL *inputURL, int *sampleRate, int *channels, NSData **data)
{
    MyAudioConverterSettings audioConverterSettings = {0};
 
   @try {
        // open the input audio file
        CFURLRef inputFileURL = (__bridge CFURLRef)inputURL;
        CheckResult(AudioFileOpenURL(inputFileURL, kAudioFileReadPermission, 0, &audioConverterSettings.inputFile));

        // get the audio data format from the file
        UInt32 propSize = sizeof(audioConverterSettings.inputFormat);
        CheckResult(AudioFileGetProperty(audioConverterSettings.inputFile, kAudioFilePropertyDataFormat, &propSize, &audioConverterSettings.inputFormat));
        
        // get the total number of packets in the file
        propSize = sizeof(audioConverterSettings.inputFilePacketCount);
        CheckResult(AudioFileGetProperty(audioConverterSettings.inputFile, kAudioFilePropertyAudioDataPacketCount, &propSize, &audioConverterSettings.inputFilePacketCount));
        
        // get size of the largest possible packet
        propSize = sizeof(audioConverterSettings.inputFilePacketMaxSize);
        CheckResult(AudioFileGetProperty(audioConverterSettings.inputFile, kAudioFilePropertyMaximumPacketSize, &propSize, &audioConverterSettings.inputFilePacketMaxSize));
        
        // define the ouput format. AudioConverter requires that one of the data formats be LPCM
        audioConverterSettings.outputFormat.mSampleRate = audioConverterSettings.inputFormat.mSampleRate;
        audioConverterSettings.outputFormat.mFormatID = kAudioFormatLinearPCM;
        audioConverterSettings.outputFormat.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked;
        audioConverterSettings.outputFormat.mBytesPerPacket = sizeof(Float32) * audioConverterSettings.inputFormat.mChannelsPerFrame;
        audioConverterSettings.outputFormat.mFramesPerPacket = 1;
        audioConverterSettings.outputFormat.mBytesPerFrame = sizeof(Float32) * audioConverterSettings.inputFormat.mChannelsPerFrame;
        audioConverterSettings.outputFormat.mChannelsPerFrame = audioConverterSettings.inputFormat.mChannelsPerFrame;
        audioConverterSettings.outputFormat.mBitsPerChannel = 32;

        // create output file
        // KEVIN: TODO: this fails if file exists. isn't there an overwrite flag we can use?
        audioConverterSettings.outputData = [[NSMutableData alloc] init];

        Convert(&audioConverterSettings);
    } @catch (...) {
        if (audioConverterSettings.inputFile)
            AudioFileClose(audioConverterSettings.inputFile);

        return false;
    }

    AudioFileClose(audioConverterSettings.inputFile);

    *sampleRate = audioConverterSettings.outputFormat.mSampleRate;
    *channels = audioConverterSettings.outputFormat.mChannelsPerFrame;
    *data = audioConverterSettings.outputData;
    
    return true;
}
