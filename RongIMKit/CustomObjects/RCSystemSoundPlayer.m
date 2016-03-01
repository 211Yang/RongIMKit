//
//  RongSystemSoundPlayer.m
//  RongIMKit
//
//  Created by xugang on 15/1/22.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCSystemSoundPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <AudioToolbox/AudioToolbox.h>
#import "RCVoicePlayer.h"
#import "RCVoiceRecorder.h"

#define kPlayDuration 0.9

static RCSystemSoundPlayer *rcSystemSoundPlayerHandler = nil;

@interface RCSystemSoundPlayer ()

@property(nonatomic, assign) SystemSoundID soundId;
@property(nonatomic, assign) NSTimeInterval startTime;
@property(nonatomic, assign) NSTimeInterval stopTime;
@property(nonatomic, strong) NSString *soundFilePath;

@property(nonatomic, strong)NSString *targetId;
@property(nonatomic, assign)RCConversationType conversationType;
@end

@implementation RCSystemSoundPlayer

+ (RCSystemSoundPlayer *)defaultPlayer {

    @synchronized(self) {
        if (nil == rcSystemSoundPlayerHandler) {
            rcSystemSoundPlayerHandler = [[[self class] alloc] init];
        }
    }

    return rcSystemSoundPlayerHandler;
}

- (void)setIgnoreConversationType:(RCConversationType)conversationType targetId:(NSString *)targetId {
    self.conversationType = conversationType;
    self.targetId = targetId;
}
- (void)resetIgnoreConversation {
    self.targetId = nil;
}

- (void)setSystemSoundPath:(NSString *)path {
    if (nil == path) {
        return;
    }

    _soundFilePath = path;
}
- (void)playSoundByMessage:(RCMessage *)rcMessage {
    if (rcMessage.conversationType == self.conversationType && [rcMessage.targetId isEqualToString:self.targetId]) {
        return;
    }

    [self needPlaySoundByMessage:rcMessage];
}
- (void)needPlaySoundByMessage:(RCMessage *)rcMessage {
    if (RCSDKRunningMode_Backgroud == [RCIMClient sharedRCIMClient].sdkRunningMode) {
        return;
    }
    //如果来信消息时正在播放或录制语音消息
    if([RCVoicePlayer defaultPlayer].isPlaying || [RCVoiceRecorder defaultVoiceRecorder].isRecording){
        return;
    }
        
        
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];

    NSError *err = nil;
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord  error:&err];

#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_7_0
    //是否扬声器播放
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride), &audioRouteOverride);
#else
    [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
#endif

    [audioSession setActive:YES error:&err];

    if (nil != err) {
        DebugLog(@"[RongIMKit]: Exception is thrown when setting audio session");
        return;
    }
    if (nil == _soundFilePath) {
        // no redefined path, use the default
        _soundFilePath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"RongCloud.bundle"]
            stringByAppendingPathComponent:@"sms-received.caf"];
    }

    if (nil != _soundFilePath) {
        OSStatus error =
            AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:_soundFilePath], &_soundId);
        if (error != kAudioServicesNoError) { //获取的声音的时候，出现错误
            DebugLog(@"[RongIMKit]: Exception is thrown when creating system sound ID");
            return;
        }
        _stopTime = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval duration = _stopTime - _startTime;
        if (duration > kPlayDuration) {
            AudioServicesPlaySystemSound(_soundId);
            _startTime = _stopTime;
        }
    } else {
        DebugLog(@"[RongIMKit]: Not found the related sound resource file in RongCloud.bundle");
    }
    //[audioSession setActive:NO error:&err];
    [[AVAudioSession sharedInstance] setActive:NO
                                   withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                         error:nil];
}

@end
