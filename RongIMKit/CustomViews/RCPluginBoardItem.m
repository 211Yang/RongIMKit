//
//  RCPluginBoardItem.m
//  CollectionViewTest
//
//  Created by Liv on 15/3/15.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCPluginBoardItem.h"
#import "RCKitCommonDefine.h"

@implementation RCPluginBoardItem

- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image tag:(NSInteger)tag
{
    self = [super init];
    if (self) {
        _title = title;
        _image = image;
        super.tag = tag;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIView *myView = [UIView new];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    imageView.image = _image;
    myView.layer.cornerRadius = 5;
    [myView addSubview:imageView];

    UILabel *label = [UILabel new];
    [label setText:_title];
    [label setTextColor:HEXCOLOR(0xababad)];
    [label setFont:[UIFont systemFontOfSize:12]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [myView addSubview:label];

    [self.contentView addSubview:myView];

    // add contraints
    [myView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [imageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [label setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self.contentView
        addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[myView(60)]|"
                                                               options:kNilOptions
                                                               metrics:nil
                                                                 views:NSDictionaryOfVariableBindings(myView)]];
    [self.contentView
        addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[myView]|"
                                                               options:kNilOptions
                                                               metrics:nil
                                                                 views:NSDictionaryOfVariableBindings(myView)]];

    [self.contentView
        addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView(60)]|"
                                                               options:kNilOptions
                                                               metrics:nil
                                                                 views:NSDictionaryOfVariableBindings(imageView)]];

    [self.contentView
        addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[label]|"
                                                               options:kNilOptions
                                                               metrics:nil
                                                                 views:NSDictionaryOfVariableBindings(label, myView)]];
    [self.contentView addConstraints:[NSLayoutConstraint
                                         constraintsWithVisualFormat:@"V:|[imageView(60)]-5-[label]|"
                                                             options:kNilOptions
                                                             metrics:nil
                                                               views:NSDictionaryOfVariableBindings(label, imageView)]];
}
@end
