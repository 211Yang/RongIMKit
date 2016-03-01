//
//  RCNetworkIndicatorView.m
//  RongIMKit
//
//  Created by MiaoGuangfa on 3/16/15.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import "RCNetworkIndicatorView.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"

@interface RCNetworkIndicatorView ()

@property(nonatomic, strong) UIImageView *networkUnreachableImageView;
@property(nonatomic, strong) UILabel *networkUnreachableDescriptionLabel;

@end

@implementation RCNetworkIndicatorView
- (instancetype)initWithText:(NSString *)text {
    self = [super init];
    if (self) {
        // self.backgroundColor = HEXCOLOR(0xfbe8e8);
        self.networkUnreachableImageView = [[UIImageView alloc] init];
        self.networkUnreachableImageView.image = IMAGE_BY_NAMED(@"network_status_warning");

        self.networkUnreachableDescriptionLabel = [[UILabel alloc] init];
        self.networkUnreachableDescriptionLabel.textColor = HEXCOLOR(0x8c8c8c);
        self.networkUnreachableDescriptionLabel.font = [UIFont systemFontOfSize:15.0f];
        self.networkUnreachableDescriptionLabel.text = text;
        self.networkUnreachableDescriptionLabel.backgroundColor = [UIColor clearColor];

        [self addSubview:self.networkUnreachableImageView];
        [self addSubview:self.networkUnreachableDescriptionLabel];

        //self.translatesAutoresizingMaskIntoConstraints = NO;
        self.networkUnreachableImageView.translatesAutoresizingMaskIntoConstraints = NO;
        self.networkUnreachableDescriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;

        // set autoLayout
        NSDictionary *bindingViews =
            NSDictionaryOfVariableBindings(_networkUnreachableImageView, _networkUnreachableDescriptionLabel);

        [self addConstraints:[NSLayoutConstraint
                                 constraintsWithVisualFormat:@"H:|-26-[_networkUnreachableImageView(==width)]-10-[_"
                                                             @"networkUnreachableDescriptionLabel]-5-|"
                                                     options:0
                                                     metrics:@{
                                                         @"width" : @(self.networkUnreachableImageView.image.size.width)
                                                     } views:bindingViews]];
        [self
            addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:|-8-[_networkUnreachableImageView(>=height)]"
                                                   options:0
                                                   metrics:@{
                                                       @"height" : @(self.networkUnreachableImageView.image.size.height)
                                                   } views:bindingViews]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_networkUnreachableDescriptionLabel
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:_networkUnreachableImageView
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1
                                                          constant:2]];
    }
    return self;
}

@end
