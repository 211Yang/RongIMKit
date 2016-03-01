//
//  RCPublicServicePopupMenuView.h
//  RongIMKit
//
//  Created by litao on 15/6/17.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RongIMLib/RongIMLib.h>

@protocol RCPublicServicePopupMenuItemSelectedDelegate <NSObject>
- (void)onPublicServiceMenuItemSelected:(RCPublicServiceMenuItem *)selectedMenuItem;
@end

@interface RCPublicServicePopupMenuView : UIView
@property (nonatomic, weak)id<RCPublicServicePopupMenuItemSelectedDelegate> delegate;
- (void)displayMenuItems:(NSArray *)menuItems atPoint:(CGPoint)point withWidth:(CGFloat)width;
@end
