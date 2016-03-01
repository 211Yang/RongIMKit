//
//  RCAssetHelper.m
//
//
//  Created by Liv on 15/3/24.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCAssetHelper.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <UIKit/UIKit.h>

@implementation RCAssetHelper

- (instancetype)init {
    if (self = [super init]) {
        _assetLibrary = [[ALAssetsLibrary alloc] init];
        //_assetsGroups = [NSMutableArray new];
    }
    return self;
}

+ (instancetype)shareAssetHelper {
    static RCAssetHelper *assetHelper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      assetHelper = [[RCAssetHelper alloc] init];
    });
    return assetHelper;
}

- (void)getGroupsWithALAssetsGroupType:(ALAssetsGroupType)groupType
                      resultCompletion:(void (^)(ALAssetsGroup *assetGroup))result {
    [self.assetLibrary enumerateGroupsWithTypes:groupType
        usingBlock:^(ALAssetsGroup *group, BOOL *stop) {

          if (nil == group) {
              result(group);
              *stop = YES;
          } else {
              result(group);
          }
          //        if (group) {
          //            [_assetsGroups addObject:group];
          //        }

          // enumer终止时，iOS SDK将group置空
          //        if (!group) {
          //            results(_assetsGroups);
          //        }

        }
        failureBlock:^(NSError *error) {
          UIAlertView *alertView =
              [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"AccessRightTitle", @"RongCloudKit", nil)
                                         message:NSLocalizedStringFromTable(@"PhotoAccessRight", @"RongCloudKit", nil)
                                        delegate:nil
                               cancelButtonTitle:NSLocalizedStringFromTable(@"Cancel", @"RongCloudKit", nil)
                               otherButtonTitles:nil];
          [alertView show];
        }];
}

- (void)getPhotosOfGroup:(ALAssetsGroup *)alGroup results:(void (^)(NSArray *photos))results {
    if (!alGroup)
        return;

    [alGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
    NSMutableArray *resultArray = [NSMutableArray new];

    [alGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
      if (result) {
          [resultArray insertObject:result atIndex:index];
      }

      if (!result) {
          results(resultArray);
      }

    }];
}

@end
