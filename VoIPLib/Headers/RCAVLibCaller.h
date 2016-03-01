//
//  RCAVLibCaller.h
//  iOS-IMKit
//
//  Created by Heq.Shinoda on 14-7-30.
//  Copyright (c) 2014年 Heq.Shinoda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCAVUserInfo : NSObject

@property UInt64 Id;
@property UInt32 assrc;
@property UInt32 vssrc;

@end

@interface RCAVLibCaller : NSObject

@property(nonatomic, assign) int voipLocalPort;

+(RCAVLibCaller*)sharedAVLibCaller;
-(void)createAvLibLinkWithUserId:(NSString*)userId audioSessionId:(NSString*)audioSessionId remoteIP:(NSString*)remoteIP port:(int)port;
-(void)UnInitAVSDK;

//设置扬声器
-(int)SetLoudSpeakerEnable:(BOOL)enable;
-(int)setAudioMute:(BOOL)isMute;
@end

