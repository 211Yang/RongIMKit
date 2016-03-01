//
//  RCGroupLoader.m
//  RongIMKit
//
//  Created by Liv on 15/1/27.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCGroupLoader.h"
#import "RCGroupCache.h"
#import "RCIM.h"

#define kGroupNotificationLoaded(s) [@"kGroupNotificationLoaded-" stringByAppendingFormat:@"%ld", (s)]
#define kGroupNotificationLoadFailed(s) [@"kGroupNotificationLoadFailed-" stringByAppendingFormat:@"%ld", (s)]
@implementation RCGroupLoader

+ (instancetype)shareInstance {
    static RCGroupLoader *loader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      loader = [[[self class] alloc] init];
    });
    return loader;
}

- (RCGroup *)loadGroupByGroupId:(NSString *)groupId observer:(id<RCGroupLoaderObserver>)observer {
    RCGroup *group = [[RCGroupCache shareInstace] getGroupByGroupId:groupId];
    if (!group) {
        if ([observer respondsToSelector:@selector(groupDidLoad:)]) {
            [[NSNotificationCenter defaultCenter] addObserver:observer
                                                     selector:@selector(groupDidLoad:)
                                                         name:kGroupNotificationLoaded((unsigned long)[observer hash])
                                                       object:nil];
        }

        if ([observer respondsToSelector:@selector(groupFailToLoad:)]) {
            [[NSNotificationCenter defaultCenter]
                addObserver:observer
                   selector:@selector(groupFailToLoad:)
                       name:kGroupNotificationLoadFailed((unsigned long)[observer hash])
                     object:nil];
        }

        [[[RCIM sharedRCIM] groupInfoDataSource]
            getGroupInfoWithGroupId:groupId
                         completion:^(RCGroup *groupInfo) {

                           if (groupInfo) {
                               [[RCGroupCache shareInstace] insertOrUpdateGroup:groupInfo ByGroupId:groupId];
                               [[NSNotificationCenter defaultCenter]
                                   postNotificationName:kGroupNotificationLoaded((unsigned long)[observer hash])
                                                 object:groupInfo
                                               userInfo:nil];
                           } else {
                               RCGroup *__groupInfo =
                                   [[RCGroup alloc] initWithGroupId:groupId groupName:nil portraitUri:nil];
                               [[NSNotificationCenter defaultCenter]
                                   postNotificationName:kGroupNotificationLoadFailed((unsigned long)[observer hash])
                                                 object:__groupInfo
                                               userInfo:nil];
                           }
                         }];
    }
    return group;
}

- (void)removeObserver:(id<RCGroupLoaderObserver>)observer {
    [[NSNotificationCenter defaultCenter] removeObserver:observer
                                                    name:kGroupNotificationLoaded((unsigned long)[observer hash])
                                                  object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer
                                                    name:kGroupNotificationLoadFailed((unsigned long)[observer hash])
                                                  object:self];
}

@end
