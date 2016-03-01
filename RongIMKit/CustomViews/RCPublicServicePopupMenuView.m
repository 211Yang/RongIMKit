//
//  RCPublicServicePopupMenuView.m
//  RongIMKit
//
//  Created by litao on 15/6/17.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCPublicServicePopupMenuView.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import <RongIMLib/RongIMLib.h>

@interface RCPublicServicePopupMenuView ()
@property (nonatomic, strong)NSArray *menuItems;//RCPublicServiceMenuItem
@property (nonatomic, strong)NSMutableArray *itemViews; //UILabel
@property (nonatomic, strong)UIImageView *backgroudImageView;
@end

#define RC_PUBLIC_SERVICE_MENU_ITEM_HEIGHT 37
#define RC_PUBLIC_SERVICE_MENU_MARGIN_BOTTOM 8
#define RC_PUBLIC_SERVICE_MENU_MARGIN_TOP 3
#define RC_PUBLIC_SERVICE_MENU_ITEM_FONT_SIZE 16 //systemFontOfSize:RC_PUBLIC_SERVICE_MENU_ITEM_FONT_SIZE]
#define RC_PUBLIC_SERVICE_MENU_ITEM_PENDING_LEFT 7
#define RC_PUBLIC_SERVICE_MENU_ITEM_PENDING_RIGHT 7
#define RC_PUBLIC_SERVICE_MENU_PADDING_BOTTOM 5
#define RC_PUBLIC_SERVICE_MENU_ITEM_SEPARATE_PENDING_LEFT 12
#define RC_PUBLIC_SERVICE_MENU_ITEM_SEPARATE_PENDING_RIGHT 12

@implementation RCPublicServicePopupMenuView

- (void)awakeFromNib {
    [super awakeFromNib];
    if (self) {
        [self setup];
    }
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.layer.cornerRadius = 5;
    self.layer.masksToBounds = YES;
    UIImage *image = IMAGE_BY_NAMED(@"public_service_submenu_bg");
    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(15, 15, 15, 15) resizingMode:UIImageResizingModeStretch];
    self.backgroudImageView = [[UIImageView alloc] initWithImage:image];
    [self addSubview:self.backgroudImageView];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    self.backgroudImageView.frame = self.bounds;
//    [self.backgroudImageView setImage:[IMAGE_BY_NAMED(@"public_service_submenu_bg") stretchableImageWithLeftCapWidth:3 topCapHeight:3]];
    
}
- (void)layoutSubviews {
    
}
- (NSMutableArray *)itemViews {
    if (!_itemViews) {
        _itemViews = [[NSMutableArray alloc] init];
    }
    return _itemViews;
}
- (void)removeAllSubItems {
    for (UIView *subView in self.itemViews) {
        [subView removeFromSuperview];
    }
    [self.itemViews removeAllObjects];
    CGRect frame = self.frame;
    frame.size.height = 0;
    self.frame = frame;
}
- (void)displayMenuItems:(NSArray *)menuItems atPoint:(CGPoint)point withWidth:(CGFloat)width {
    self.menuItems = menuItems;
    if (![menuItems count]) {
        return;
    }
    CGFloat maxWidth = width;
    if(maxWidth>150)
        maxWidth=150;
    point.y -= RC_PUBLIC_SERVICE_MENU_PADDING_BOTTOM;
    CGFloat height = menuItems.count*(RC_PUBLIC_SERVICE_MENU_ITEM_HEIGHT + 1) + RC_PUBLIC_SERVICE_MENU_MARGIN_BOTTOM + RC_PUBLIC_SERVICE_MENU_MARGIN_TOP;
    CGRect frame = CGRectMake(point.x+((width - maxWidth))/2, point.y, maxWidth, height);
    self.frame = frame;
//    [UIView beginAnimations:nil context:NULL];
//    [UIView setAnimationDuration:0.01f];
    
    frame.origin.y -= height;
    self.frame = frame;
    
    for (UIView *subView in self.itemViews) {
        [subView removeFromSuperview];
    }
    [self.itemViews removeAllObjects];
    
    for (int i = 0; i < self.menuItems.count; i++) {
        if (i != 0) {
            UIView *line = [self newLine];
            line.frame =
            CGRectMake(RC_PUBLIC_SERVICE_MENU_ITEM_SEPARATE_PENDING_LEFT, (i * RC_PUBLIC_SERVICE_MENU_ITEM_HEIGHT+1) + RC_PUBLIC_SERVICE_MENU_MARGIN_TOP, maxWidth-RC_PUBLIC_SERVICE_MENU_ITEM_SEPARATE_PENDING_LEFT - RC_PUBLIC_SERVICE_MENU_ITEM_SEPARATE_PENDING_RIGHT, 1);
            [self addSubview:line];
        }
        RCPublicServiceMenuItem *menuItem = self.menuItems[i];
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(RC_PUBLIC_SERVICE_MENU_ITEM_PENDING_LEFT, (i * RC_PUBLIC_SERVICE_MENU_ITEM_HEIGHT+1) + 1 + RC_PUBLIC_SERVICE_MENU_MARGIN_TOP, maxWidth-RC_PUBLIC_SERVICE_MENU_ITEM_PENDING_LEFT - RC_PUBLIC_SERVICE_MENU_ITEM_PENDING_RIGHT, RC_PUBLIC_SERVICE_MENU_ITEM_HEIGHT)];
        [btn setTitle:menuItem.name forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btn.titleLabel setFont:[UIFont systemFontOfSize:RC_PUBLIC_SERVICE_MENU_ITEM_FONT_SIZE]];
        btn.tag = i;
        [self.itemViews addObject:btn];
        [btn setBackgroundColor:[UIColor whiteColor]];
        [self addSubview:btn];
        [btn addTarget:self action:@selector(onMenuButtonPressed:) forControlEvents:UIControlEventTouchDown];
    }
    
//    [UIView commitAnimations];
    [self becomeFirstResponder];
}
- (BOOL)becomeFirstResponder {
    [super becomeFirstResponder];
    return YES;
}
- (BOOL)canBecomeFirstResponder {
    return YES;
}
- (BOOL)resignFirstResponder {
    [super resignFirstResponder];
//    [UIView beginAnimations:nil context:NULL];
//    [UIView setAnimationDuration:0.01f];
//    [UIView setAnimationDelegate:self];
//    [UIView setAnimationDidStopSelector:@selector(removeAllSubItems)];
    [self removeAllSubItems];
    CGRect frame = self.frame;
    frame.origin.y += frame.size.height;
    //frame.size.height = 0;
    self.frame = frame;
//    [UIView commitAnimations];
    return YES;
}
- (void)onMenuButtonPressed:(id)sender {
    UIButton *btn = sender;
    RCPublicServiceMenuItem *selectedItem = self.menuItems[btn.tag];
    [self resignFirstResponder];
    [self.delegate onPublicServiceMenuItemSelected:selectedItem];
}
- (UIView *)newLine {
    UILabel *line = [UILabel new];
    line.backgroundColor = [UIColor colorWithRed:221 / 255.0 green:221 / 255.0 blue:221 / 255.0 alpha:1];
    return line;
}
@end
