//
//  RCVoicePlayer.h
//  RongIMKit
//
//  Created by xugang on 15/1/22.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RongIMKit.h"
@protocol RCVoicePlayerObserver;

@interface RCVoicePlayer : NSObject

@property(nonatomic, readonly) BOOL isPlaying;
@property(nonatomic, copy) NSString *messageId;

+ (RCVoicePlayer *)defaultPlayer;
- (BOOL)playVoice:(NSString *)messageId voiceData:(NSData *)data observer:(id<RCVoicePlayerObserver>)observer;
- (BOOL)playVoice:(NSString *)messageId messageReciveStatus:(RCReceivedStatus)reciveStatus messageDirection:(RCMessageDirection)messageDirection voiceData:(NSData *)data observer:(id<RCVoicePlayerObserver>)observer;
- (void)stopPlayVoice;

@end

@protocol RCVoicePlayerObserver <NSObject>

- (void)PlayerDidFinishPlaying:(BOOL)isFinish;

- (void)audioPlayerDecodeErrorDidOccur:(NSError *)error;

@end