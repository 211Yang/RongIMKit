//
//  RCVoiceRecorder.m
//  RongIMKit
//
//  Created by xugang on 15/1/22.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCVoiceRecorder.h"
#import <AVFoundation/AVFoundation.h>

static RCVoiceRecorder *rcVoiceRecorderHandler = nil;

@interface RCVoiceRecorder () <AVAudioRecorderDelegate>

@property(nonatomic, strong) NSDictionary *recordSettings;
@property(nonatomic, strong) NSURL *recordTempFileURL;
@property(nonatomic) BOOL isRecording;
@property(nonatomic, strong) AVAudioRecorder *recorder;
@property(nonatomic, weak) id<RCVoiceRecorderDelegate> voiceRecorderDelegate;
@end

@implementation RCVoiceRecorder
+ (RCVoiceRecorder *)defaultVoiceRecorder {
    @synchronized(self) {
        if (nil == rcVoiceRecorderHandler) {
            rcVoiceRecorderHandler = [[[self class] alloc] init];

            rcVoiceRecorderHandler.recordSettings = @{
                AVFormatIDKey : @(kAudioFormatLinearPCM),
                AVSampleRateKey : @8000.00f,
                AVNumberOfChannelsKey : @1,
                AVLinearPCMBitDepthKey : @16,
                AVLinearPCMIsNonInterleaved : @NO,
                AVLinearPCMIsFloatKey : @NO,
                AVLinearPCMIsBigEndianKey : @NO
            };

            rcVoiceRecorderHandler.recordTempFileURL =
                [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"tempAC.caf"]];
            DebugLog(@"[RongIMKit]: Using File called: %@", rcVoiceRecorderHandler.recordTempFileURL);
        }
        return rcVoiceRecorderHandler;
    }
}

- (BOOL)startRecordWithObserver:(id<RCVoiceRecorderDelegate>)observer {
    self.voiceRecorderDelegate = observer;
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    [audioSession setActive:YES error:nil];

    NSError *error = nil;

    if (nil == self.recorder) {
        self.recorder =
            [[AVAudioRecorder alloc] initWithURL:self.recordTempFileURL settings:self.recordSettings error:&error];
        self.recorder.delegate = self;
        self.recorder.meteringEnabled = YES;
    }

    BOOL isRecord = NO;
    isRecord = [self.recorder prepareToRecord];
    DebugLog(@"[RongIMKit]: prepareToRecord is %@", isRecord ? @"success" : @"failed");

    isRecord = [self.recorder record];
    DebugLog(@"[RongIMKit]: record is %@", isRecord ? @"success" : @"failed");
    self.isRecording = self.recorder.isRecording;
    return isRecord;
}

- (BOOL)cancelRecord {
    self.voiceRecorderDelegate = nil;
    if (nil != self.recorder && [self.recorder isRecording]) {
        [self.recorder stop];
        [self.recorder deleteRecording];
        self.recorder = nil;
        self.isRecording = self.recorder.isRecording;
        return YES;
    }
    [[AVAudioSession sharedInstance] setActive:NO
                                   withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                         error:nil];
    return NO;
}
- (void)stopRecord:(void (^)(NSData *, NSTimeInterval))compeletion {
    if (!self.recorder.url)
        return;
    NSURL *url = [[NSURL alloc] initWithString:self.recorder.url.absoluteString];
    NSData *currentRecordData = [NSData dataWithContentsOfURL:url];
    NSTimeInterval audioLength = self.recorder.currentTime;
    [self.recorder stop];
    self.isRecording = self.recorder.isRecording;
    self.recorder = nil;
    [[AVAudioSession sharedInstance] setActive:NO
                                   withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                         error:nil];
    compeletion(currentRecordData, audioLength);
}
- (CGFloat)updateMeters {
    if (nil != self.recorder) {
        [self.recorder updateMeters];
    }

    float peakPower = [self.recorder averagePowerForChannel:0];
    CGFloat power = (1.0 / 160.0) * (peakPower + 160.0);
    return power;
}
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    if ([self.voiceRecorderDelegate respondsToSelector:@selector(RCVoiceAudioRecorderDidFinishRecording:)]) {
        [self.voiceRecorderDelegate RCVoiceAudioRecorderDidFinishRecording:flag];
    }
    self.voiceRecorderDelegate = nil;
    self.isRecording = self.recorder.isRecording;
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error {
    if ([self.voiceRecorderDelegate respondsToSelector:@selector(RCVoiceAudioRecorderEncodeErrorDidOccur:)]) {
        [self.voiceRecorderDelegate RCVoiceAudioRecorderEncodeErrorDidOccur:error];
    }
    self.voiceRecorderDelegate = nil;
    self.isRecording = self.recorder.isRecording;
}
@end
