//
//  RongUIKit.m
//  RongIMKit
//
//  Created by xugang on 15/1/13.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCIM.h"
#import "RCKitUtility.h"
#import "RCLocalNotification.h"
#import "RCSystemSoundPlayer.h"
#import "RCOldMessageNotificationMessage.h"
#import "RCUserInfoLoader.h"
#import "RCUserInfoCache.h"
#import "RCGroupCache.h"
#if RC_VOIP_ENABLE
#import "RCVoIPMessageCenter.h"
#endif

NSString *const RCKitDispatchMessageNotification = @"RCKitDispatchMessageNotification";
NSString *const RCKitDispatchTypingMessageNotification = @"RCKitDispatchTypingMessageNotification";
NSString *const RCKitSendingMessageNotification = @"RCKitSendingMessageNotification";
NSString *const RCKitDispatchConnectionStatusChangedNotification = @"RCKitDispatchConnectionStatusChangedNotification";

@interface RCIM () <RCIMClientReceiveMessageDelegate, RCConnectionStatusChangeDelegate, RCUserInfoLoaderObserver
#if RC_VOIP_ENABLE
                    ,
                    RCVoIPUserInfoProvider
#endif
                    >
@property(nonatomic, strong) NSString *appKey;
@end

dispatch_queue_t __rc__conversationList_refresh_queue = NULL;

static RCIM *__rongUIKit = nil;
@implementation RCIM

+ (instancetype)sharedRCIM {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      if (__rongUIKit == nil) {
          __rongUIKit = [[RCIM alloc] init];
          __rongUIKit.userInfoDataSource = nil;
          __rongUIKit.groupInfoDataSource = nil;
          __rongUIKit.receiveMessageDelegate = nil;
          __rongUIKit.disableMessageNotificaiton = NO;
          __rongUIKit.disableMessageAlertSound = [[NSUserDefaults standardUserDefaults] boolForKey:@"rcMessageBeep"];
          __rongUIKit.enableMessageAttachUserInfo = NO;
          __rc__conversationList_refresh_queue = dispatch_queue_create("com.rongcloud.refreshConversationList", NULL);
          __rongUIKit.globalMessagePortraitSize = CGSizeMake(46, 46);
          __rongUIKit.globalConversationPortraitSize = CGSizeMake(46, 46);
          __rongUIKit.globalMessageAvatarStyle = RC_USER_AVATAR_RECTANGLE;
          __rongUIKit.globalConversationAvatarStyle = RC_USER_AVATAR_RECTANGLE;
          __rongUIKit.globalNavigationBarTintColor=[UIColor whiteColor];
          __rongUIKit.portraitImageViewCornerRadius = 4;
          __rongUIKit.maxVoiceDuration = 60;
      }
    });
    return __rongUIKit;
}
- (void)setDisableMessageAlertSound:(BOOL)disableMessageAlertSound
{
    [[NSUserDefaults standardUserDefaults] setBool:disableMessageAlertSound forKey:@"rcMessageBeep"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _disableMessageAlertSound = disableMessageAlertSound;
}
- (void)setGlobalMessagePortraitSize:(CGSize)globalMessagePortraitSize {
    CGFloat width = globalMessagePortraitSize.width;
    CGFloat height = globalMessagePortraitSize.height;

//    if (width < 45.0f) {
//        width = 45.0f;
//    }
//    if (width > 65.0f) {
//        width = 65.0f;
//    }
//
//    if (height < 45.0f) {
//        height = 45.0f;
//    }
//    if (height > 65.0f) {
//        height = 65.0f;
//    }

    _globalMessagePortraitSize.width = width;
    _globalMessagePortraitSize.height = height;
}
- (void)setGlobalConversationPortraitSize:(CGSize)globalConversationPortraitSize {
    CGFloat width = globalConversationPortraitSize.width;
    CGFloat height = globalConversationPortraitSize.height;

//    if (width < 45.0f) {
//        width = 45.0f;
//    }
//    if (width > 65.0f) {
//        width = 65.0f;
//    }
//
//    if (height < 45.0f) {
//        height = 45.0f;
//    }
//    if (height > 65.0f) {
//        height = 65.0f;
//    }

    if (height < 36.0f) {
        height = 36.0f;
    }

    _globalConversationPortraitSize.width = width;
    _globalConversationPortraitSize.height = height;
}

- (void)setCurrentUserInfo:(RCUserInfo *)currentUserInfo {
    if (currentUserInfo) {
        [[RCUserInfoCache sharedCache] insertOrUpdateUserInfo:currentUserInfo userId:currentUserInfo.userId];
    }
    [[RCIMClient sharedRCIMClient] setCurrentUserInfo:currentUserInfo];
}
- (RCUserInfo *)currentUserInfo {
    return [[RCIMClient sharedRCIMClient] currentUserInfo];
}
- (void)initWithAppKey:(NSString *)appKey {
    if ([self.appKey isEqual:appKey]) {
        NSLog(@"Warning:请不要重复调用Init！！！");
        return;
    }
    
    self.appKey = appKey;
    [[RCIMClient sharedRCIMClient] init:appKey];

#if RC_VOIP_ENABLE
    [RCVoIPMessageCenter sharedInstance].currentAppKey = appKey;
    [[RCVoIPMessageCenter sharedInstance] registerVoIPMessage];
    [RCVoIPMessageCenter sharedInstance].userInfoProvider = self;
#endif // RC_VOIP_ENABLE

    [self registerMessageType:[RCHandShakeMessage class]];
    [self registerMessageType:[RCSuspendMessage class]];
    [self registerMessageType:[RCOldMessageNotificationMessage class]];
    // listen receive message
    [[RCIMClient sharedRCIMClient] setReceiveMessageDelegate:self object:nil];
    [[RCIMClient sharedRCIMClient] setRCConnectionStatusChangeDelegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}
- (void)appEnterBackground
{ 
    //勿扰时段内关闭本地通知
    [[RCIMClient sharedRCIMClient] getNotificationQuietHours:^(NSString *startTime, int spansMin) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"HH:mm:ss"];
        if (startTime && startTime.length != 0) {
            NSDate *startDate = [dateFormatter dateFromString:startTime];
            NSDate *endDate = [startDate dateByAddingTimeInterval:spansMin * 60];
            NSString *nowDateString = [dateFormatter stringFromDate:[NSDate date]];
            NSDate *nowDate = [dateFormatter dateFromString:nowDateString];
            
            
            NSDate *earDate = [startDate earlierDate:nowDate];
            NSDate *laterDate = [endDate laterDate:nowDate];
            if (([startDate isEqualToDate:earDate] && [endDate isEqualToDate:laterDate]) || [nowDate isEqualToDate:startDate] || [nowDate isEqualToDate:endDate]) {
                
                //设置本地通知状态为关闭
                [self setDisableMessageNotificaiton:YES];
                
            }else{
                
                [self setDisableMessageNotificaiton:NO];
            }
            
        }
        
    } error:^(RCErrorCode status) {
        
    }];
}

- (void)registerMessageType:(Class)messageClass {
    [[RCIMClient sharedRCIMClient] registerMessageType:messageClass];

    //未完成，需要保存消息类型，在消息通知的时候通知
}
- (void)connectWithToken:(NSString *)token
                 success:(void (^)(NSString *userId))successBlock
                   error:(void (^)(RCConnectErrorCode status))errorBlock
          tokenIncorrect:(void (^)())tokenIncorrectBlock {

#if RC_VOIP_ENABLE
    [RCVoIPMessageCenter sharedInstance].token = token;
#endif // RC_VOIP_ENABLE

    [[RCIMClient sharedRCIMClient] connectWithToken:token
        success:^(NSString *userId) {
// get own userId
// self.currentUserId = userId;

#if RC_VOIP_ENABLE
          [RCVoIPMessageCenter sharedInstance].currentUserId = userId;
#endif // RC_VOIP_ENABLE
            if (successBlock!=nil) {
                successBlock(userId);
            }
        }
        error:^(RCConnectErrorCode status) {
            if(errorBlock!=nil)
                errorBlock(status);
        }
        tokenIncorrect:^() {
          tokenIncorrectBlock();
        }];
}

/**
 *  断开连接。
 *
 *  @param isReceivePush 是否接收回调。
 */
- (void)disconnect:(BOOL)isReceivePush {
    [[RCIMClient sharedRCIMClient] disconnect:isReceivePush];
}

/**
 *  断开连接。
 */
- (void)disconnect {
    [[RCIMClient sharedRCIMClient] disconnect];
}

/**
 *  Log out。不会接收到push消息。
 */
- (void)logout {
    [[RCIMClient sharedRCIMClient] logout];
}

- (void)setReceiveMessageDelegate:(id<RCIMReceiveMessageDelegate>)delegate {
    _receiveMessageDelegate = delegate;
}

- (void)onReceived:(RCMessage *)message left:(int)nLeft object:(id)object {

    if (message.content.senderUserInfo.userId) {
        [self refreshUserInfoCache:message.content.senderUserInfo
                        withUserId:message.content.senderUserInfo.userId];
    }
    
    NSDictionary *dic_left = @{ @"left" : @(nLeft) };
    if ([self.receiveMessageDelegate respondsToSelector:@selector(onRCIMReceiveMessage:left:)]) {
        [self.receiveMessageDelegate onRCIMReceiveMessage:message left:nLeft];
    }

#if RC_VOIP_ENABLE
    BOOL isVoIPMessage = [[RCVoIPMessageCenter sharedInstance] filterAndDispatchVoIPMessage:message];
    if (isVoIPMessage && [RCIMClient sharedRCIMClient].sdkRunningMode == RCSDKRunningMode_Backgroud) {
        NSDictionary *dictionary = [RCKitUtility getNotificationUserInfoDictionary:message];
        NSString *showMessage = [RCKitUtility formatMessage:message.content];

        if (showMessage
            && self.userInfoDataSource
            && [self.userInfoDataSource respondsToSelector:@selector(getUserInfoWithUserId:completion:)]) {
            [self.userInfoDataSource
             getUserInfoWithUserId:message.targetId
             completion:^(RCUserInfo *userInfo) {
                 if (nil == userInfo) {
                     return;
                 }
                 BOOL appComsumed = NO;
                 if ([self.receiveMessageDelegate respondsToSelector:@selector(onRCIMCustomLocalNotification:withSenderName:)]) {
                     appComsumed = [self.receiveMessageDelegate onRCIMCustomLocalNotification:message withSenderName:userInfo.name];
                 }
                 if (!appComsumed) {
                     [[RCLocalNotification defaultCenter]
                      postLocalNotification:[NSString stringWithFormat:@"%@:%@", userInfo.name, showMessage] userInfo:dictionary];
                 }
             }];
        }

        return;
    }
#endif
    
    // dispatch message
    [[NSNotificationCenter defaultCenter] postNotificationName:RCKitDispatchMessageNotification
                                                            object:message
                                                          userInfo:dic_left];
    //发出去的消息，不需要本地铃声和通知
    if (message.messageDirection == MessageDirection_SEND) {
        return;
    }
    
    
    BOOL isCustomMessageAlert = YES;
//    if ([message.content respondsToSelector:@selector(presentInConversation)]) {
//        isCustomMessageAlert =  (BOOL)[message.content performSelector:@selector(presentInConversation)];
//    }
    if (!([[message.content class] persistentFlag] & MessagePersistent_ISPERSISTED)) {
        isCustomMessageAlert = NO;
    }
    if (self.showUnkownMessageNotificaiton && message.messageId > 0 && !message.content) {
        isCustomMessageAlert = YES;
    }
    RCConversation *receivedConversation_ =
    [[RCIMClient sharedRCIMClient] getConversation:message.conversationType targetId:message.targetId];
    
    if (!receivedConversation_) {
        return;
    }
    if (0 == nLeft && [RCIMClient sharedRCIMClient].sdkRunningMode == RCSDKRunningMode_Foregroud && !self.disableMessageAlertSound && isCustomMessageAlert
        /*&&([message.content isMemberOfClass:RCImageMessage.class]
           || [message.content isMemberOfClass:RCTextMessage.class]
           || [message.content isMemberOfClass:RCVoiceMessage.class]
           || [message.content isMemberOfClass:RCLocationMessage.class]
           || [message.content isMemberOfClass:RCRichContentMessage.class])*/) {
               //获取接受到会话
       

        [[RCIMClient sharedRCIMClient] getConversationNotificationStatus:message.conversationType
            targetId:message.targetId
            success:^(RCConversationNotificationStatus nStatus) {

              if (NOTIFY == nStatus) {
                  BOOL appComsumed = NO;
                  if ([self.receiveMessageDelegate respondsToSelector:@selector(onRCIMCustomAlertSound:)]) {
                      appComsumed = [self.receiveMessageDelegate onRCIMCustomAlertSound:message];
                  }
                  if (!appComsumed) {
                      
                      if (![message.content isKindOfClass:[RCDiscussionNotificationMessage class]]) {
                          [[RCSystemSoundPlayer defaultPlayer] playSoundByMessage:message];
                      }
                  }
              }

            }
            error:^(RCErrorCode status){

            }];
    }

    if (0 == nLeft && NO == self.disableMessageNotificaiton &&
        [RCIMClient sharedRCIMClient].sdkRunningMode == RCSDKRunningMode_Backgroud && isCustomMessageAlert) {

        //聊天室消息不做本地通知
        if (ConversationType_CHATROOM == message.conversationType)
            return;
        NSDictionary *dictionary = [RCKitUtility getNotificationUserInfoDictionary:message];
        [[RCIMClient sharedRCIMClient] getConversationNotificationStatus:message.conversationType
            targetId:message.targetId
            success:^(RCConversationNotificationStatus nStatus) {
                
              if (NOTIFY == nStatus) {
                  NSString *showMessage = nil;
                  if (self.showUnkownMessageNotificaiton && message.objectName && !message.content) {
                      showMessage = NSLocalizedStringFromTable(@"unknown_message_notification_tip",@"RongCloudKit",nil);
                  } else {
                      showMessage = [RCKitUtility formatMessage:message.content];
                  }

                  if ((ConversationType_GROUP == message.conversationType)) {
                      [self.groupInfoDataSource
                          getGroupInfoWithGroupId:message.targetId
                                       completion:^(RCGroup *groupInfo) {
                                         if (nil == groupInfo) {
                                             return;
                                         }
                                           BOOL appComsumed = NO;
                                           if ([self.receiveMessageDelegate respondsToSelector:@selector(onRCIMCustomLocalNotification:withSenderName:)]) {
                                               appComsumed = [self.receiveMessageDelegate onRCIMCustomLocalNotification:message withSenderName:groupInfo.groupName];
                                           }
                                           if (!appComsumed) {
//                                               RCUserInfo *userInfo = [[RCUserInfoLoader sharedUserInfoLoader] loadGroupUserInfo:message.senderUserId groupId:message.targetId observer:nil];
//                                               if (!userInfo.name.length) {
//                                                   userInfo = [[RCUserInfoLoader sharedUserInfoLoader] loadUserInfo:message.senderUserId observer:nil];
//                                               }
//                                               if (userInfo.name) {
////                                                   
////                                                   NSString *abbrGroupName = groupInfo.groupName;
////                                                   if (abbrGroupName.length > 15) {
////                                                       abbrGroupName = [NSString stringWithFormat:@"%@...", [abbrGroupName substringToIndex:12]];
////                                                   }
////                                                   
////                                                   [[RCLocalNotification defaultCenter]
////                                                    postLocalNotification:[NSString stringWithFormat:@"%@(%@):%@",
////                                                                           userInfo.name,
////                                                                           abbrGroupName,
////                                                                           showMessage] userInfo:dictionary];
//                                                   [[RCLocalNotification defaultCenter]
//                                                    postLocalNotification:[NSString stringWithFormat:@"%@:%@",
//                                                                           userInfo.name,
//                                                                           showMessage] userInfo:dictionary];
//                                               } else
                                         [[RCLocalNotification defaultCenter]
                                             postLocalNotification:[NSString stringWithFormat:@"%@:%@",
                                                                                              groupInfo.groupName,
                                                                                              showMessage] userInfo:dictionary];
                                           }
                                       }];
                  } else if (ConversationType_DISCUSSION == message.conversationType) {
                      [[RCIMClient sharedRCIMClient] getDiscussion:message.targetId
                          success:^(RCDiscussion *discussion) {
                            if (nil == discussion) {
                                return;
                            }
                              BOOL appComsumed = NO;
                              if ([self.receiveMessageDelegate respondsToSelector:@selector(onRCIMCustomLocalNotification:withSenderName:)]) {
                                  appComsumed = [self.receiveMessageDelegate onRCIMCustomLocalNotification:message withSenderName:discussion.discussionName];
                              }
                              if (!appComsumed) {
//                                  RCUserInfo *userInfo = [[RCUserInfoLoader sharedUserInfoLoader] loadUserInfo:message.senderUserId observer:nil];
//                                  if (userInfo.name.length) {
////                                      NSString *abbrDiscussionName = discussion.discussionName;
////                                      if (abbrDiscussionName.length > 15) {
////                                          abbrDiscussionName = [NSString stringWithFormat:@"%@...", [abbrDiscussionName substringToIndex:12]];
////                                      }
////                                      [[RCLocalNotification defaultCenter]
////                                       postLocalNotification:[NSString stringWithFormat:@"%@(%@):%@", userInfo.name, abbrDiscussionName,
////                                                              showMessage] userInfo:dictionary];
//                                      [[RCLocalNotification defaultCenter]
//                                       postLocalNotification:[NSString stringWithFormat:@"%@:%@", userInfo.name,
//                                                              showMessage] userInfo:dictionary];
//                                  } else
                            [[RCLocalNotification defaultCenter]
                                postLocalNotification:[NSString stringWithFormat:@"%@:%@", discussion.discussionName,
                                                                                 showMessage] userInfo:dictionary];
                              }

                          }
                          error:^(RCErrorCode status){

                          }];
                  } else if (ConversationType_CUSTOMERSERVICE == message.conversationType) {
                      BOOL appComsumed = NO;
                      if ([self.receiveMessageDelegate respondsToSelector:@selector(onRCIMCustomLocalNotification:withSenderName:)]) {
                          appComsumed = [self.receiveMessageDelegate onRCIMCustomLocalNotification:message withSenderName:@"客服"];
                      }
                      if (!appComsumed) {
                      [[RCLocalNotification defaultCenter]
                       postLocalNotification:[NSString stringWithFormat:@"%@:%@", @"客服", showMessage] userInfo:dictionary];
                      }
                  } else if (ConversationType_APPSERVICE == message.conversationType ||
                             ConversationType_PUBLICSERVICE == message.conversationType) {
                      RCPublicServiceProfile *serviceProfile =
                      [[RCIMClient sharedRCIMClient] getPublicServiceProfile:(RCPublicServiceType)message.conversationType publicServiceId:message.targetId];
                      
                      if (serviceProfile) {
                          BOOL appComsumed = NO;
                          if ([self.receiveMessageDelegate respondsToSelector:@selector(onRCIMCustomLocalNotification:withSenderName:)]) {
                              appComsumed = [self.receiveMessageDelegate onRCIMCustomLocalNotification:message withSenderName:serviceProfile.name];
                          }
                          if (!appComsumed) {
                          [[RCLocalNotification defaultCenter]
                              postLocalNotification:[NSString
                                                        stringWithFormat:@"%@:%@", serviceProfile.name, showMessage] userInfo:dictionary];
                          }
                      }
                  } else if (ConversationType_SYSTEM == message.conversationType){
                      if (self.userInfoDataSource && [self.userInfoDataSource respondsToSelector:@selector(getUserInfoWithUserId:completion:)]) {
                          [self.userInfoDataSource getUserInfoWithUserId:message.targetId completion:^(RCUserInfo *userInfo) {
                               BOOL appComsumed = NO;
                               if ([self.receiveMessageDelegate respondsToSelector:@selector(onRCIMCustomLocalNotification: withSenderName:)]) {
                                   appComsumed = [self.receiveMessageDelegate onRCIMCustomLocalNotification:message withSenderName:(userInfo ? userInfo.name : nil)];
                               }
                               if (!appComsumed) {
                                   if (userInfo) {
                                       [[RCLocalNotification defaultCenter] postLocalNotification:[NSString stringWithFormat:@"%@:%@", userInfo.name, showMessage] userInfo:dictionary];
                                   } else {
                                       [[RCLocalNotification defaultCenter] postLocalNotification: showMessage userInfo:dictionary];
                                   }

                               }
                           }];
                      } else {
                          BOOL appComsumed = NO;
                          if ([self.receiveMessageDelegate respondsToSelector:@selector(onRCIMCustomLocalNotification:withSenderName:)]) {
                              appComsumed = [self.receiveMessageDelegate onRCIMCustomLocalNotification:message withSenderName:nil];
                          }
                          if (!appComsumed) {
                              [[RCLocalNotification defaultCenter] postLocalNotification: showMessage userInfo:dictionary];
                          }
                      }
                  } else {
                      
                      if (self.userInfoDataSource && [self.userInfoDataSource respondsToSelector:@selector(getUserInfoWithUserId:completion:)]) {
                          
                          [self.userInfoDataSource
                           getUserInfoWithUserId:message.targetId
                           completion:^(RCUserInfo *userInfo) {
                               if (nil == userInfo) {
                                   return;
                               }
                               BOOL appComsumed = NO;
                               if ([self.receiveMessageDelegate respondsToSelector:@selector(onRCIMCustomLocalNotification:withSenderName:)]) {
                                   appComsumed = [self.receiveMessageDelegate onRCIMCustomLocalNotification:message withSenderName:userInfo.name];
                               }
                               if (!appComsumed) {
                                   [[RCLocalNotification defaultCenter]
                                    postLocalNotification:[NSString stringWithFormat:@"%@:%@", userInfo.name,
                                                           showMessage] userInfo:dictionary];
                               }
                           }];
                      }
                  }
              }

            }
            error:^(RCErrorCode status){

            }];
    }
}

/**
 *  网络状态变化。
 *
 *  @param status 网络状态。
 */
- (void)onConnectionStatusChanged:(RCConnectionStatus)status {
    if (/*ConnectionStatus_NETWORK_UNAVAILABLE != status && */ConnectionStatus_UNKNOWN != status &&
        ConnectionStatus_Unconnected != status) {
        [[NSNotificationCenter defaultCenter] postNotificationName:RCKitDispatchConnectionStatusChangedNotification
                                                        object:[NSNumber numberWithInt:status]];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(delayNotifyUnConnectedStatus) withObject:nil afterDelay:3];
        });
    }
    if (self.connectionStatusDelegate) {
        [self.connectionStatusDelegate onRCIMConnectionStatusChanged:status];
    }
}

/*!
 获取当前SDK的连接状态
 
 @return 当前SDK的连接状态
 */
- (RCConnectionStatus)getConnectionStatus {
    return [[RCIMClient sharedRCIMClient] getConnectionStatus];
}

- (void)delayNotifyUnConnectedStatus {
    RCConnectionStatus status = [[RCIMClient sharedRCIMClient] getConnectionStatus];
    if (ConnectionStatus_NETWORK_UNAVAILABLE == status || ConnectionStatus_UNKNOWN == status ||
        ConnectionStatus_Unconnected == status) {
        [[NSNotificationCenter defaultCenter] postNotificationName:RCKitDispatchConnectionStatusChangedNotification
                                                            object:[NSNumber numberWithInt:status]];
    }
}
- (void)startVoIPCallWithTargetId:(NSString *)targetId {
#if RC_VOIP_ENABLE
    [[RCVoIPMessageCenter sharedInstance] startOutgoingVoIPCallWithCallId:targetId];
#endif
}

- (void)getVoIPUserInfoWithUserId:(NSString *)userId completion:(void (^)(RCUserInfo *))completion {
#if RC_VOIP_ENABLE
    RCUserInfo *__userInfo = [[RCUserInfoCache sharedCache] fetchUserInfo:userId];

    if (__userInfo) {
        completion(__userInfo);
    } else {
        
        if (self.userInfoDataSource && [self.userInfoDataSource respondsToSelector:@selector(getUserInfoWithUserId:completion:)]) {
            [self.userInfoDataSource getUserInfoWithUserId:userId completion:completion];
        }
    }
#endif
}

- (void)refreshUserInfoCache:(RCUserInfo *)userInfo withUserId:(NSString *)userId
{
    [[RCUserInfoCache sharedCache]insertOrUpdateUserInfo:userInfo userId:userId];
}

- (void)refreshGroupInfoCache:(RCGroup *)groupInfo withGroupId:(NSString *)groupId
{
    [[RCGroupCache shareInstace]insertOrUpdateGroup:groupInfo ByGroupId:groupId];
}

- (void)refreshGroupUserInfoCache:(RCUserInfo *)userInfo withUserId:(NSString *)userId withGroupId:(NSString *)groupId
{
    [[RCUserInfoCache sharedCache]insertOrUpdateGroupUserInfo:userInfo userId:userId groupId:groupId];
}

- (void)clearUserInfoCache
{
    [[RCUserInfoCache sharedCache] clearCache];
}

- (void)clearGroupInfoCache
{
    [[RCGroupCache shareInstace] clearCache];
}

- (RCMessage *)sendMessage:(RCConversationType)conversationType
                  targetId:(NSString *)targetId
                   content:(RCMessageContent *)content
               pushContent:(NSString *)pushContent
                  pushData:(NSString *)pushData
                   success:(void (^)(long messageId))successBlock
                     error:(void (^)(RCErrorCode nErrorCode,
                                     long messageId))errorBlock {
    RCMessage *rcMessage = [[RCIMClient sharedRCIMClient]
                            sendMessage:conversationType
                            targetId:targetId
                            content:content
                            pushContent:pushContent
                            pushData:pushData
                            success:^(long messageId) {
                                NSDictionary *statusDic = @{@"targetId":targetId,
                                                            @"conversationType":@(conversationType),
                                                            @"messageId": @(messageId),
                                                            @"sentStatus": @(SentStatus_SENT),
                                                            @"content":content};
                                [[NSNotificationCenter defaultCenter]
                                 postNotificationName:RCKitSendingMessageNotification
                                 object:nil
                                 userInfo:statusDic];
                                
                                successBlock(messageId);
                            } error:^(RCErrorCode nErrorCode, long messageId) {
                                NSDictionary *statusDic = @{@"targetId":targetId,
                                                            @"conversationType":@(conversationType),
                                                            @"messageId": @(messageId),
                                                            @"sentStatus": @(SentStatus_FAILED),
                                                            @"error": @(nErrorCode),
                                                            @"content":content};
                                [[NSNotificationCenter defaultCenter]
                                 postNotificationName:RCKitSendingMessageNotification
                                 object:nil
                                 userInfo:statusDic];
                                
                                errorBlock(nErrorCode,messageId);
                            }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:RCKitSendingMessageNotification
                                                        object:rcMessage
                                                      userInfo:nil];
    return rcMessage;
}

- (RCMessage *)sendImageMessage:(RCConversationType)conversationType
                       targetId:(NSString *)targetId
                        content:(RCMessageContent *)content
                    pushContent:(NSString *)pushContent
                       pushData:(NSString *)pushData
                       progress:(void (^)(int progress, long messageId))progressBlock
                        success:(void (^)(long messageId))successBlock
                          error:(void (^)(RCErrorCode errorCode, long messageId))errorBlock {
    RCMessage *rcMessage = [[RCIMClient sharedRCIMClient]
                            sendImageMessage:conversationType
                            targetId:targetId
                            content:content
                            pushContent:pushContent
                            pushData:pushData
                            progress:^(int progress, long messageId) {
                                NSDictionary *statusDic = @{@"targetId":targetId,
                                                            @"conversationType":@(conversationType),
                                                            @"messageId": @(messageId),
                                                            @"sentStatus": @(SentStatus_SENDING),
                                                            @"progress": @(progress)};
                                [[NSNotificationCenter defaultCenter]
                                 postNotificationName:RCKitSendingMessageNotification
                                 object:nil
                                 userInfo:statusDic];
                                
                                progressBlock(progress, messageId);
                            } success:^(long messageId) {
                                NSDictionary *statusDic = @{@"targetId":targetId,
                                                            @"conversationType":@(conversationType),
                                                            @"messageId": @(messageId),
                                                            @"sentStatus": @(SentStatus_SENT),
                                                            @"content":content};
                                [[NSNotificationCenter defaultCenter]
                                 postNotificationName:RCKitSendingMessageNotification
                                 object:nil
                                 userInfo:statusDic];
                                
                                successBlock(messageId);
                            } error:^(RCErrorCode errorCode, long messageId) {
                                NSDictionary *statusDic = @{@"targetId":targetId,
                                                            @"conversationType":@(conversationType),
                                                            @"messageId": @(messageId),
                                                            @"sentStatus": @(SentStatus_FAILED),
                                                            @"error": @(errorCode),
                                                            @"content":content};
                                [[NSNotificationCenter defaultCenter]
                                 postNotificationName:RCKitSendingMessageNotification
                                 object:nil
                                 userInfo:statusDic];
                                
                                errorBlock(errorCode, messageId);
                            }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:RCKitSendingMessageNotification
                                                        object:rcMessage
                                                      userInfo:nil];
    
    return rcMessage;
}
- (void)setMaxVoiceDuration:(NSUInteger)maxVoiceDuration {
    if (maxVoiceDuration < 5 || maxVoiceDuration > 60) {
        return;
    }
    _maxVoiceDuration = maxVoiceDuration;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}
@end
