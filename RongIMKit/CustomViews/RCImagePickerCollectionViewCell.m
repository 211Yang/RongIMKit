//
//  RCImagePickerCollectionViewCell.m
//
//
//  Created by Liv on 15/3/23.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCImagePickerCollectionViewCell.h"
#import "RCKitUtility.h"
@interface RCImagePickerCollectionViewCell ()

@property(nonatomic, strong) NSArray *vConstraints;
@property(nonatomic, strong) NSArray *hConstraints;

@end

@implementation RCImagePickerCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self addSubview:_imageView];

        _selectImage = [[UIImageView alloc] initWithFrame:CGRectZero];
        _selectImage.image = [RCKitUtility imageNamed:@"deselect" ofBundle:@"RongCloud.bundle"];
        _selectImage.alpha = 0.65;
        [self addSubview:_selectImage];

        [_selectImage setTranslatesAutoresizingMaskIntoConstraints:NO];
        _vConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_selectImage(22)]-0-|"
                                                                options:kNilOptions
                                                                metrics:nil
                                                                  views:NSDictionaryOfVariableBindings(_selectImage)];
        _hConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_selectImage(22)]-0-|"
                                                                options:kNilOptions
                                                                metrics:nil
                                                                  views:NSDictionaryOfVariableBindings(_selectImage)];

        [self addConstraints:_vConstraints];
        [self addConstraints:_hConstraints];
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    if (selected) {
        _selectImage.image = [RCKitUtility imageNamed:@"selected" ofBundle:@"RongCloud.bundle"];
    } else {
        _selectImage.image = [RCKitUtility imageNamed:@"deselect" ofBundle:@"RongCloud.bundle"];
    }
}
@end
