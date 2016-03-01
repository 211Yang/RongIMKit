//
//  RCUserInfoLoader.m
//  RongIMKit
//
//  Created by xugang on 15/1/23.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCUserInfoLoader.h"
#import "RCUserInfoCache.h"
#import "RCIM.h"

#define kUserInfoNotificationLoaded(s) [@"kUserInfoNotificationLoaded-" stringByAppendingFormat:@"%ld", (s)]
#define kUserInfoNotificationLoadFailed(s) [@"kUserInfoNotificationLoadFailed-" stringByAppendingFormat:@"%ld", (s)]

#define kGroupUserInfoNotificationLoaded(s) [@"kGroupUserInfoNotificationLoaded-" stringByAppendingFormat:@"%ld", (s)]
#define kGroupUserInfoNotificationLoadFailed(s) [@"kGroupUserInfoNotificationLoadFailed-" stringByAppendingFormat:@"%ld", (s)]

static RCUserInfoLoader *__rc_userInfoLoader = nil;

@implementation RCUserInfoLoader

+ (RCUserInfoLoader *)sharedUserInfoLoader {

    @synchronized(self) {
        if (nil == __rc_userInfoLoader) {
            __rc_userInfoLoader = [[[self class] alloc] init];
        }
    }

    return __rc_userInfoLoader;
}

- (RCUserInfo *)loadUserInfo:(NSString *)userId observer:(id<RCUserInfoLoaderObserver>)observer {
    if (nil == userId) {
        return nil;
    }
    RCUserInfo *__userInfo = [[RCUserInfoCache sharedCache] fetchUserInfo:userId];

    if (__userInfo) {
        return __userInfo;
    } else {

        if ([observer respondsToSelector:@selector(userInfoDidLoad:)]) {
            [[NSNotificationCenter defaultCenter]
                addObserver:observer
                   selector:@selector(userInfoDidLoad:)
                       name:kUserInfoNotificationLoaded((unsigned long)[observer hash])
                     object:nil];
        }

        if ([observer respondsToSelector:@selector(userInfoFailToLoad:)]) {
            [[NSNotificationCenter defaultCenter]
                addObserver:observer
                   selector:@selector(userInfoFailToLoad:)
                       name:kUserInfoNotificationLoadFailed((unsigned long)[observer hash])
                     object:nil];
        }

        if ([RCIM sharedRCIM].userInfoDataSource && [[RCIM sharedRCIM].userInfoDataSource respondsToSelector:@selector(getUserInfoWithUserId:completion:)])
        {
            [[RCIM sharedRCIM].userInfoDataSource getUserInfoWithUserId:userId completion:^(RCUserInfo *userInfo) {
                 if (userInfo && userInfo.userId) {
                     [[RCUserInfoCache sharedCache] insertOrUpdateUserInfo:userInfo userId:userId];
                     [[NSNotificationCenter defaultCenter]
                      postNotificationName:kUserInfoNotificationLoaded((unsigned long)[observer hash])
                      object:userInfo
                      userInfo:nil];
                 } else {
                     RCUserInfo *__userInfo = [[RCUserInfo alloc] initWithUserId:userId name:nil portrait:nil];
                     [[NSNotificationCenter defaultCenter]
                      postNotificationName:kUserInfoNotificationLoadFailed((unsigned long)[observer hash])
                      object:__userInfo
                      userInfo:nil];
                     DebugLog(@"userInfoProvider 获取信息失败，请检查，否则会影响头像和昵称显示");
                 }
             }];
        }
        return nil;
    }
}

- (RCUserInfo *)loadGroupUserInfo:(NSString *)userId groupId:(NSString *)groupId observer:(id<RCUserInfoLoaderObserver>)observer {
    if (nil == userId) {
        return nil;
    }
    RCUserInfo *__userInfo = [[RCUserInfoCache sharedCache] fetchGroupUserInfo:userId groupId:groupId];
    
    if (__userInfo) {
        return __userInfo;
    } else {
        
        if ([observer respondsToSelector:@selector(groupUserInfoDidLoad:)]) {
            [[NSNotificationCenter defaultCenter]
             addObserver:observer
             selector:@selector(groupUserInfoDidLoad:)
             name:kGroupUserInfoNotificationLoaded((unsigned long)[observer hash])
             object:nil];
        }
        
        if ([observer respondsToSelector:@selector(groupUserInfoFailToLoad:)]) {
            [[NSNotificationCenter defaultCenter]
             addObserver:observer
             selector:@selector(groupUserInfoFailToLoad:)
             name:kGroupUserInfoNotificationLoadFailed((unsigned long)[observer hash])
             object:nil];
        }
        
        if ([RCIM sharedRCIM].groupUserInfoDataSource && [[RCIM sharedRCIM].groupUserInfoDataSource respondsToSelector:@selector(getUserInfoWithUserId:inGroup:completion:)]) {
            [[RCIM sharedRCIM].groupUserInfoDataSource getUserInfoWithUserId:userId
                                                                     inGroup:(NSString *)groupId
                                                                  completion:^(RCUserInfo *userInfo) {
                if (userInfo && userInfo.userId) {
                    [[RCUserInfoCache sharedCache] insertOrUpdateGroupUserInfo:userInfo userId:userId groupId:groupId];
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:kGroupUserInfoNotificationLoaded((unsigned long)[observer hash])
                     object:userInfo
                     userInfo:@{@"groupId":groupId}];
                } else {
                    RCUserInfo *__userInfo = [[RCUserInfo alloc] initWithUserId:userId name:nil portrait:nil];
                    [[RCUserInfoCache sharedCache] insertOrUpdateGroupUserInfo:__userInfo userId:userId groupId:groupId];
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:kGroupUserInfoNotificationLoadFailed((unsigned long)[observer hash])
                     object:__userInfo
                     userInfo:@{@"groupId":groupId}];
                   // DebugLog(@"groupUserInfoProvider 获取信息失败，请检查，否则会影响头像和昵称显示");
                }
            }];
        }
        return nil;
    }
}
- (void)removeObserver:(id<RCUserInfoLoaderObserver>)observer {

    [[NSNotificationCenter defaultCenter] removeObserver:observer
                                                    name:kUserInfoNotificationLoaded((unsigned long)[observer hash])
                                                  object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer
                                                    name:kUserInfoNotificationLoadFailed((unsigned long)[observer hash])
                                                  object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer
                                                    name:kGroupUserInfoNotificationLoaded((unsigned long)[observer hash])
                                                  object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer
                                                    name:kGroupUserInfoNotificationLoadFailed((unsigned long)[observer hash])
                                                  object:self];
}

@end
