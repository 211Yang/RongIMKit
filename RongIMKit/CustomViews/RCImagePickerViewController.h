//
//  RCImagePickerViewController.h
//
//  Created by Liv on 15/3/23.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RCImagePickerViewControllerDelegate;

@interface RCImagePickerViewController : UICollectionViewController

/**
 *  factory method
 *
 *  @return return a instance
 */
+ (instancetype)imagePickerViewController;

@property(nonatomic, weak) id<RCImagePickerViewControllerDelegate> delegate;
@property(strong, nonatomic) NSArray *photos;
@end

@protocol RCImagePickerViewControllerDelegate <NSObject>

@optional
// 选择图片后回调事件
- (void)imagePickerViewController:(RCImagePickerViewController *)imagePickerViewController
                   selectedImages:(NSArray *)selectedImages isSendFullImage:(BOOL)enable;

@end
