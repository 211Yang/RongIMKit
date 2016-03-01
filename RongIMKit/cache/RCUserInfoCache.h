//
//  RCUserInfoCache.h
//  RongIMKit
//
//  Created by xugang on 15/1/23.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLib/RongIMLib.h>
@interface RCUserInfoCache : NSObject

+ (RCUserInfoCache *)sharedCache;

- (void)clearCache;
- (void)insertOrUpdateUserInfo:(RCUserInfo *)userInfo userId:(NSString *)userId;
- (RCUserInfo *)fetchUserInfo:(NSString *)userId;

- (RCUserInfo *)fetchGroupUserInfo:(NSString *)userId groupId:(NSString *)groupId;
- (void)insertOrUpdateGroupUserInfo:(RCUserInfo *)userInfo userId:(NSString *)userId groupId:(NSString *)groupId;
@end
