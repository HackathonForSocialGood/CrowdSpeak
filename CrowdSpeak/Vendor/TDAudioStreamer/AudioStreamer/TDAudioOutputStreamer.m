//
//  TDAudioOutputStreamer.m
//  TDAudioStreamer
//
//  Created by Tony DiPasquale on 11/14/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import <AVFoundation/AVFoundation.h>
#import "TDAudioOutputStreamer.h"
#import "TDAudioStream.h"

@interface TDAudioOutputStreamer () <TDAudioStreamDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

@property (strong, nonatomic) TDAudioStream *audioStream;
@property (strong, nonatomic) AVAssetReader *assetReader;
@property (strong, nonatomic) AVAssetReaderTrackOutput *assetOutput;
@property (strong, nonatomic) NSThread *streamThread;

@property (assign, atomic) BOOL isStreaming;
@property (nonatomic, strong) dispatch_queue_t sampleQueue;


@end


@implementation TDAudioOutputStreamer


- (instancetype) initWithOutputStream:(NSOutputStream *)stream
{
    self = [super init];
    if (!self) return nil;

    self.audioStream = [[TDAudioStream alloc] initWithOutputStream:stream];
    self.audioStream.delegate = self;
    self.sampleQueue = dispatch_queue_create("sampleQueue", 0);
    NSLog(@"Init");

    return self;
}

- (void)start
{
    if (![[NSThread currentThread] isEqual:[NSThread mainThread]]) {
        return [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:YES];
    }

    NSLog(@"Start");
    self.streamThread = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
    [self.streamThread start];
}

- (void)run
{
    @autoreleasepool {
        [self.audioStream open];

        self.isStreaming = YES;
        NSLog(@"Loop");

        while (self.isStreaming && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) ;

        NSLog(@"Done");
    }
}


- (void) streamAudioFromMic
{
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    [session beginConfiguration];
    AVCaptureDevice * microphone = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    NSError * error = nil;
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:microphone error:&error];
    [session addInput:input];
    // Add inputs and outputs.
    AVCaptureAudioDataOutput * output = [[AVCaptureAudioDataOutput alloc] init];
    [output setSampleBufferDelegate:self queue:self.sampleQueue];
    [session addOutput:output];
    
    [session commitConfiguration];
    [session startRunning];

}


- (void)streamAudioFromURL:(NSURL *)url
{
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSError *assetError;

    self.assetReader = [AVAssetReader assetReaderWithAsset:asset error:&assetError];
    self.assetOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:asset.tracks[0] outputSettings:nil];
    if (![self.assetReader canAddOutput:self.assetOutput]) return;

    [self.assetReader addOutput:self.assetOutput];
    [self.assetReader startReading];
    NSLog(@"Read Asset");
}

- (void)sendDataChunk
{
    CMSampleBufferRef sampleBuffer;

    sampleBuffer = [self.assetOutput copyNextSampleBuffer];

    if (sampleBuffer == NULL || CMSampleBufferGetNumSamples(sampleBuffer) == 0) {
        CFRelease(sampleBuffer);
        return;
    }

    CMBlockBufferRef blockBuffer;
    AudioBufferList audioBufferList;

    OSStatus err = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(AudioBufferList), NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &blockBuffer);

    if (err) {
        CFRelease(sampleBuffer);
        return;
    }

    for (NSUInteger i = 0; i < audioBufferList.mNumberBuffers; i++) {
        AudioBuffer audioBuffer = audioBufferList.mBuffers[i];
        [self.audioStream writeData:audioBuffer.mData maxLength:audioBuffer.mDataByteSize];
        NSLog(@"buffer size: %u", (unsigned int)audioBuffer.mDataByteSize);
    }

    CFRelease(blockBuffer);
    CFRelease(sampleBuffer);
}

- (void)stop
{
    [self performSelector:@selector(stopThread) onThread:self.streamThread withObject:nil waitUntilDone:YES];
}

- (void)stopThread
{
    self.isStreaming = NO;
    [self.audioStream close];
    NSLog(@"Stop");
}

#pragma mark - TDAudioStreamDelegate

- (void)audioStream:(TDAudioStream *)audioStream didRaiseEvent:(TDAudioStreamEvent)event
{
    switch (event) {
        case TDAudioStreamEventWantsData:
            [self sendDataChunk];
            break;

        case TDAudioStreamEventError:
            // TODO: shit!
            NSLog(@"Stream Error");
            break;

        case TDAudioStreamEventEnd:
            // TODO: shit!
            NSLog(@"Stream Ended");
            break;

        default:
            break;
    }
}


#pragma mark AVCaptureAudioDataOutputSampleBufferDelegate


- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"Did output");
}


@end
