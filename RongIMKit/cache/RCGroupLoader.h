//
//  RCGroupLoader.h
//  RongIMKit
//
//  Created by Liv on 15/1/27.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLib/RongIMLib.h>
/**
 *  加载成功或者失败回调
 */
@protocol RCGroupLoaderObserver <NSObject>

@optional
- (void)groupDidLoad:(NSNotification *)notification;

- (void)groupFailToLoad:(NSNotification *)notification;

@end

@interface RCGroupLoader : NSObject

+ (instancetype)shareInstance;

/**
 *  根据userid加载缓存数据
 *
 *  @param userId
 *  @param observer 传入代理类
 *
 *  @return 群组对象
 */
- (RCGroup *)loadGroupByGroupId:(NSString *)groupId observer:(id<RCGroupLoaderObserver>)observer;
- (void)removeObserver:(id<RCGroupLoaderObserver>)observer;
@end
