//
//  RCImagePickerCollectionViewCell.h
//
//
//  Created by Liv on 15/3/23.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCImagePickerCollectionViewCell : UICollectionViewCell

/**
 *  显示图片
 */
@property(nonatomic, strong) UIImageView *imageView;

/**
 *  cell被选中小图
 */
@property(nonatomic, strong) UIImageView *selectImage;
@end
