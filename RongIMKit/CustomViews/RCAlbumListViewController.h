//
//  RCAlbumListViewController.h
//  RongIMKit
//
//  Created by MiaoGuangfa on 6/4/15.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RCAlbumListViewControllerDelegate;

@interface RCAlbumListViewController : UITableViewController

@property (nonatomic, weak) id<RCAlbumListViewControllerDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *libraryList;

@end

@protocol RCAlbumListViewControllerDelegate <NSObject>

- (void)albumListViewController:(RCAlbumListViewController *)albumListViewController selectedImages:(NSArray *)selectedImages isSendFullImage:(BOOL)enable;

@end