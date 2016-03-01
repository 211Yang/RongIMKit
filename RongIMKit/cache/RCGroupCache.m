//
//  RCGroupInfoCache.m
//  RongIMKit
//
//  Created by Liv on 15/1/27.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCGroupCache.h"
dispatch_queue_t __rc__groupInfo_operation_queue;

@interface RCGroupCache ()
@property(nonatomic, strong) NSMutableDictionary *groupDictionary;

@end

@implementation RCGroupCache

+ (instancetype)shareInstace {
    static RCGroupCache *groupCache = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
      groupCache = [[[self class] alloc] init];
      __rc__groupInfo_operation_queue = dispatch_queue_create("com.rongcloud.groupInfoQueue", NULL);

    });
    return groupCache;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.groupDictionary = [NSMutableDictionary new];
    }
    return self;
}

- (void)clearCache {
    __weak typeof(&*self) __blockSelf = self;
    dispatch_sync(__rc__groupInfo_operation_queue, ^{
      [__blockSelf.groupDictionary removeAllObjects];
    });
}

- (void)insertOrUpdateGroup:(RCGroup *)group ByGroupId:(NSString *)groupId {
    __weak typeof(&*self) __blockSelf = self;
    dispatch_async(__rc__groupInfo_operation_queue, ^{
      [__blockSelf.groupDictionary setObject:group forKey:groupId];
    });
}

- (RCGroup *)getGroupByGroupId:(NSString *)groupId {
    __weak typeof(&*self) __blockSelf = self;
    __block RCGroup *group = nil;

    dispatch_sync(__rc__groupInfo_operation_queue, ^{
      group = [__blockSelf.groupDictionary objectForKey:groupId];
    });

    return group;
}

@end
