//
//  RCMPSingleNewsCell.h
//  RongIMKit
//
//  Created by litao on 15/4/15.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import <RongIMKit/RongIMKit.h>

@interface RCPublicServiceImgTxtMsgCell : RCMessageBaseCell
@property (nonatomic, weak)id<RCPublicServiceMessageCellDelegate> publicServiceDelegate;
+ (CGFloat)getCellHeight:(RCMessageModel *)model withWidth:(CGFloat)width;
@end
