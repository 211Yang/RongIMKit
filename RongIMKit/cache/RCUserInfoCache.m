//
//  RCUserInfoCache.m
//  RongIMKit
//
//  Created by xugang on 15/1/23.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCUserInfoCache.h"
#import "RCIM.h"

static RCUserInfoCache *__rc_userinfocache = nil;

static dispatch_queue_t __rc__userInfo_operation_queue;

@interface RCUserInfoCache ()

@property(nonatomic, strong) NSMutableDictionary *cacheUserInfoDictionary;
@property(nonatomic, strong) NSMutableDictionary *cacheGroupUserInfoDictionary;
@end

@implementation RCUserInfoCache

+ (RCUserInfoCache *)sharedCache {
    @synchronized(self) {
        if (nil == __rc_userinfocache) {
            __rc_userinfocache = [[RCUserInfoCache alloc] init];
            __rc_userinfocache.cacheUserInfoDictionary = [[NSMutableDictionary alloc] init];
            __rc_userinfocache.cacheGroupUserInfoDictionary = [[NSMutableDictionary alloc] init];
            __rc__userInfo_operation_queue = dispatch_queue_create("com.rongcloud.userInfoQueue", NULL);
        }
    }
    return __rc_userinfocache;
}

- (void)clearCache {
    __weak typeof(&*self) __blockSelf = self;
    dispatch_sync(__rc__userInfo_operation_queue, ^{
      [__blockSelf.cacheUserInfoDictionary removeAllObjects];
      [__blockSelf.cacheGroupUserInfoDictionary removeAllObjects];
    });
}

- (void)insertOrUpdateUserInfo:(RCUserInfo *)userInfo userId:(NSString *)userId {
    __weak typeof(&*self) __blockSelf = self;
    dispatch_async(__rc__userInfo_operation_queue, ^{
      [__blockSelf.cacheUserInfoDictionary setObject:userInfo forKey:userId];
    });
}

- (void)insertOrUpdateGroupUserInfo:(RCUserInfo *)userInfo userId:(NSString *)userId groupId:(NSString *)groupId {
    __weak typeof(&*self) __blockSelf = self;
    dispatch_async(__rc__userInfo_operation_queue, ^{
        NSMutableDictionary *userDictionary = __blockSelf.cacheGroupUserInfoDictionary[groupId];
        if (!userDictionary) {
            userDictionary = [[NSMutableDictionary alloc] init];
        }
        [userDictionary setObject:userInfo forKey:userId];
        [__blockSelf.cacheGroupUserInfoDictionary setObject:userDictionary forKey:userId];
    });
}

- (RCUserInfo *)fetchUserInfo:(NSString *)userId {

    __block RCUserInfo *userinfo = nil;
    __weak typeof(&*self) __blockSelf = self;
    dispatch_sync(__rc__userInfo_operation_queue, ^{
      userinfo = [__blockSelf.cacheUserInfoDictionary objectForKey:userId];
    });

    if (!userinfo) {
        
        if ([RCIM sharedRCIM].userInfoDataSource && [[RCIM sharedRCIM].userInfoDataSource respondsToSelector:@selector(getUserInfoWithUserId:completion:)]) {
            [[RCIM sharedRCIM].userInfoDataSource getUserInfoWithUserId:userId
                                                             completion:^(RCUserInfo *userInfo) {
                                                                 if (userInfo && userInfo.userId) {
                                                                     [[RCUserInfoCache sharedCache] insertOrUpdateUserInfo:userInfo userId:userId];
                                                                 }
                                                             }];
        }
    }
    return userinfo;
}

- (RCUserInfo *)fetchGroupUserInfo:(NSString *)userId groupId:(NSString *)groupId {
    
    __block RCUserInfo *userinfo = nil;
    __weak typeof(&*self) __blockSelf = self;
    dispatch_sync(__rc__userInfo_operation_queue, ^{
        NSMutableDictionary *userDictionary = [__blockSelf.cacheGroupUserInfoDictionary objectForKey:groupId];
        userinfo = [userDictionary objectForKey:userId];
    });
    
    if (!userinfo) {
        
        if ([RCIM sharedRCIM].groupUserInfoDataSource && [[RCIM sharedRCIM].groupUserInfoDataSource respondsToSelector:@selector(getUserInfoWithUserId:inGroup:completion:)]) {
            [[RCIM sharedRCIM].groupUserInfoDataSource getUserInfoWithUserId:userId
                                                                     inGroup:(NSString *)groupId
                                                                  completion:^(RCUserInfo *userInfo) {
                                                                 if (userInfo && userInfo.userId) {
                                                                     [[RCUserInfoCache sharedCache] insertOrUpdateGroupUserInfo:userInfo userId:userId groupId:groupId];
                                                                 }
                                                             }];
        }
    }
    return userinfo;
}
@end
