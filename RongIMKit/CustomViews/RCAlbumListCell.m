//
//  RCAlbumListCell.m
//  RongIMKit
//
//  Created by 蔡建海 on 15/7/29.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCAlbumListCell.h"

@implementation RCAlbumListCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

//
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.imageView.center = CGPointMake(self.imageView.frame.size.width/2, self.imageView.frame.size.height/2);
    
    CGRect labelFrame = self.textLabel.frame;
    labelFrame.origin.x = self.imageView.frame.size.width + self.imageView.frame.origin.x + 12;
    
    self.textLabel.frame = labelFrame;
    
}

@end
