//
//  RCAssetHelper.h
//
//  获取系统相册图片
//  Created by Liv on 15/3/24.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#define ShareRCAssetHelper [RCAssetHelper shareAssetHelper]

@interface RCAssetHelper : NSObject

@property(nonatomic, strong) ALAssetsLibrary *assetLibrary;
@property(nonatomic, strong) NSMutableArray *assetsGroups;

/**
 *  return a instance
 *
 *  @return return value description
 */
+ (instancetype)shareAssetHelper;

/**
 *  获取分组的所有图片
 *
 *  @param alGroup 要操作的分组
 *  @param results 结果回传
 */
- (void)getPhotosOfGroup:(ALAssetsGroup *)alGroup results:(void (^)(NSArray *photos))results;

/**
 *  根据分组类型获取分组
 *
 *  @param groupType 分组类型
 *  @param results   结果回传
 */
- (void)getGroupsWithALAssetsGroupType:(ALAssetsGroupType)groupType
                      resultCompletion:(void (^)(ALAssetsGroup *assetGroup))result;
@end
