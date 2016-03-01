//
//  RCUserInfoLoader.h
//  RongIMKit
//
//  Created by xugang on 15/1/23.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLib/RongIMLib.h>
@protocol RCUserInfoLoaderObserver;

@interface RCUserInfoLoader : NSObject
+ (RCUserInfoLoader *)sharedUserInfoLoader;

- (RCUserInfo *)loadUserInfo:(NSString *)userId observer:(id<RCUserInfoLoaderObserver>)observer;
- (void)removeObserver:(id<RCUserInfoLoaderObserver>)observer;
- (RCUserInfo *)loadGroupUserInfo:(NSString *)userId groupId:(NSString *)groupId observer:(id<RCUserInfoLoaderObserver>)observer;

@end

@protocol RCUserInfoLoaderObserver <NSObject>

@optional
- (void)userInfoDidLoad:(NSNotification *)notification;
- (void)userInfoFailToLoad:(NSNotification *)notification;

- (void)groupUserInfoDidLoad:(NSNotification *)notification;
- (void)groupUserInfoFailToLoad:(NSNotification *)notification;
@end
