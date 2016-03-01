//
//  RCTextView.m
//  iOS-IMKit
//
//  Created by Liv on 14/10/30.
//  Copyright (c) 2014年 RongCloud. All rights reserved.
//

#import "RCTextView.h"

@implementation RCTextView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _disableActionMenu = NO;
    }
    return self;
}
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (self.disableActionMenu) {
        return NO;
    }
    [[UIMenuController sharedMenuController] setMenuItems:nil];
    return [super canPerformAction:action withSender:sender];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    _disableActionMenu = NO;
}

@end
