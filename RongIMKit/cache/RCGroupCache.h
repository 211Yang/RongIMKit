//
//  RCGroupInfoCache.h
//  RongIMKit
//  群组缓存
//  Created by Liv on 15/1/27.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLib/RCGroup.h>

@interface RCGroupCache : NSObject

+ (instancetype)shareInstace;

/**
 *  插入、删除用户群组信息
 *
 *  @param group  群组对象
 *  @param userId 用户id
 */
- (void)insertOrUpdateGroup:(RCGroup *)group ByGroupId:(NSString *)groupId;

/**
 *  清除所有群组缓存
 */
- (void)clearCache;

/**
 *  根据用户id获取群组对象
 *
 *  @param userId 用户id
 *
 *  @return 用户群组信息
 */
- (RCGroup *)getGroupByGroupId:(NSString *)groupId;
@end
