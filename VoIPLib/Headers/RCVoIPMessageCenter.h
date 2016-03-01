//
//  RCVoIPObserverCenter.h
//  iOS_VoipLib
//
//  Created by MiaoGuangfa on 4/1/15.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLib/RongIMLib.h>

//The key for VoIP call state: (calling, accept, finish).
UIKIT_EXTERN NSString *const kReceivedVoIPCallStateNotification;

//The key for VoIP call is running or not.
UIKIT_EXTERN NSString *const kVoIPRunningStateNotification;

UIKIT_EXTERN NSString *const kRCVoIPUserinfoNofification;

@protocol RCVoIPUserInfoProvider <NSObject>

/**
 *  获取用户信息。
 *
 *  @param userId     用户 Id。
 *  @param completion 用户信息
 */
- (void)getVoIPUserInfoWithUserId:(NSString *)userId completion:(void(^)(RCUserInfo* userInfo))completion;
@end




@interface RCVoIPMessageCenter : NSObject

@property (nonatomic, copy) NSString *currentAppKey;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *currentUserId;
@property (nonatomic, weak) id<RCVoIPUserInfoProvider> userInfoProvider;

@property (nonatomic, assign, readonly) BOOL isRunning;

+ (RCVoIPMessageCenter *)sharedInstance;

- (void) registerVoIPMessage;

- (BOOL) filterAndDispatchVoIPMessage:(RCMessage *)message;

- (void) startOutgoingVoIPCallWithCallId:(NSString *)callId;
- (void) dismissVoIPViewController;
- (void) speakerStatusDidChangeWithEnableSpeaker:(BOOL) enable;
@end
