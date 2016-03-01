//
//  RCChatSessionInputBarControl.m
//  RongIMKit
//
//  Created by xugang on 15/2/12.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCChatSessionInputBarControl.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCPublicServicePopupMenuView.h"

// NSString * const RCChatKeyboardNotificationKeyboardDidChangeFrame =
// @"RCChatKeyboardNotificationKeyboardDidChangeFrame";
// NSString * const RCChatKeyboardUserInfoKeyKeyboardDidChangeFrame  =
// @"RCChatKeyboardUserInfoKeyKeyboardDidChangeFrame";

#define RC_PUBLIC_SERVICE_MENU_BUTTON_FONT_SIZE 16 //systemFontOfSize:RC_PUBLIC_SERVICE_MENU_ITEM_FONT_SIZE]
#define RC_PUBLIC_SERVICE_MENU_ICON_GAP 3
#define RC_PUBLIC_SERVICE_MENU_SEPARATE_WIDTH 1
#define RC_PUBLIC_SERVICE_SUBMENU_PADDING 6
typedef void (^RCAnimationCompletionBlock)(BOOL finished);

@interface RCChatSessionInputBarControl () <UITextViewDelegate, RCPublicServicePopupMenuItemSelectedDelegate>

@property(nonatomic, strong) NSMutableArray *inputContainerSubViewConstraints;

@property(nonatomic, strong)RCPublicServicePopupMenuView *publicServicePopupMenu;

- (void)setAutoLayoutForSubViews:(RCChatSessionInputBarControlType)type style:(RCChatSessionInputBarControlStyle)style;

- (void)switchInputBoxOrRecord;

- (void)voiceRecordButtonTouchDown:(UIButton *)sender;
- (void)voiceRecordButtonTouchUpInside:(UIButton *)sender;
- (void)voiceRecordButtonTouchDragExit:(UIButton *)sender;
- (void)voiceRecordButtonTouchDragEnter:(UIButton *)sender;
- (void)voiceRecordButtonTouchUpOutside:(UIButton *)sender;

- (void)rcInputBar_registerForNotifications;
- (void)rcInputBar_unregisterForNotifications;
- (void)rcInputBar_didReceiveKeyboardWillShowNotification:(NSNotification *)notification;
- (void)rcInputBar_didReceiveKeyboardWillHideNotification:(NSNotification *)notification;

@end

@implementation RCChatSessionInputBarControl

- (id)initWithFrame:(CGRect)frame
    withContextView:(UIView *)contextView
               type:(RCChatSessionInputBarControlType)type
              style:(RCChatSessionInputBarControlStyle)style {
    self = [super initWithFrame:frame];
    if (self) {
        self.inputContainerSubViewConstraints = [[NSMutableArray alloc] init];
        [self setInputBarType:type style:style];
        _contextView = contextView;
        self.currentPositionY = frame.origin.y;
        self.originalPositionY = frame.origin.y;
        
        self.inputTextview_height=36.0f;
        self.backgroundColor = HEXCOLOR(0xF4F4F6);
        self.layer.borderWidth = 0.5;
        self.layer.borderColor = HEXCOLOR(0xdbdbdd).CGColor;
        
    }
    return self;
}

- (void)resetInputBar {
    if (self.inputContainerSubViewConstraints.count > 0) {
        [self.inputContainerView removeConstraints:_inputContainerSubViewConstraints];
        [_inputContainerSubViewConstraints removeAllObjects];
    }
    
    if (self.pubSwitchButton) {
        [self.pubSwitchButton removeFromSuperview];
        self.pubSwitchButton = nil;
    }
    
    if (self.switchButton) {
        [self.switchButton removeFromSuperview];
        self.switchButton = nil;
    }
    if (self.recordButton) {
        [self.recordButton removeFromSuperview];
        self.recordButton = nil;
    }
    if (self.inputTextView) {
        [self.inputTextView removeFromSuperview];
        self.inputTextView = nil;
    }
    if (self.emojiButton) {
        [self.emojiButton removeFromSuperview];
        self.emojiButton = nil;
    }
    if (self.additionalButton) {
        [self.additionalButton removeFromSuperview];
        self.additionalButton = nil;
    }
    
    if (self.inputContainerView) {
        [self.inputContainerView removeFromSuperview];
        self.inputContainerView = nil;
    }
    if (self.menuContainerView) {
        [self.menuContainerView removeFromSuperview];
        self.menuContainerView = nil;
    }
}

- (void)setInputBarType:(RCChatSessionInputBarControlType)type style:(RCChatSessionInputBarControlStyle)style {
    
    [self resetInputBar];
    
    if (RCChatSessionInputBarControlDefaultType == type) {
        
        self.inputContainerView = [[UIView alloc] initWithFrame:self.bounds];
        [self addSubview:_inputContainerView];
        
        [self configInputContainerView:style];
        [self setAutoLayoutForSubViews:type style:style];
        ;
        [self rcInputBar_registerForNotifications];
    } else if (type == RCChatSessionInputBarControlPubType) {
        [self.clientView addSubview:self.publicServicePopupMenu];
        CGRect containerViewFrame = self.bounds;
        containerViewFrame.size.width = containerViewFrame.size.width - 40;
        containerViewFrame.origin.x = 40;
        self.inputContainerView = [[UIView alloc] initWithFrame:containerViewFrame];
        self.menuContainerView = [[UIView alloc] initWithFrame:containerViewFrame];
        _menuContainerView.hidden = YES;
        self.inputContainerView.hidden = YES;
        [self addSubview:_inputContainerView];
        [self addSubview:_menuContainerView];
        
        self.pubSwitchButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [self.pubSwitchButton setFrame:CGRectMake(0, 0, 40, Height_ChatSessionInputBar)];
        [_pubSwitchButton setImage:IMAGE_BY_NAMED(@"pub_menu") forState:UIControlStateNormal];
        [_pubSwitchButton addTarget:self
                             action:@selector(pubSwitchValueChanged)
                   forControlEvents:UIControlEventTouchUpInside];
        [_pubSwitchButton setExclusiveTouch:YES];
        self.menuContainerView.hidden = NO;
        [self addSubview:_pubSwitchButton];
        
        [self configInputContainerView:style];
        [self setAutoLayoutForSubViews:type style:style];
        [self rcInputBar_registerForNotifications];
    }
}

- (void)configInputContainerView:(RCChatSessionInputBarControlStyle)style {
    self.switchButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [_switchButton setImage:IMAGE_BY_NAMED(@"chat_setmode_voice_btn_normal") forState:UIControlStateNormal];
    [_switchButton addTarget:self
                      action:@selector(switchInputBoxOrRecord)
            forControlEvents:UIControlEventTouchUpInside];
    [_switchButton setExclusiveTouch:YES];
    [self.inputContainerView addSubview:_switchButton];
    
    self.inputTextView = [[RCTextView alloc] initWithFrame:CGRectZero];
    _inputTextView.delegate = self;
    [_inputTextView setExclusiveTouch:YES];
    [_inputTextView setTextColor:[UIColor blackColor]];
    [_inputTextView setFont:[UIFont systemFontOfSize:16]];
    [_inputTextView setReturnKeyType:UIReturnKeySend];
    _inputTextView.backgroundColor = [UIColor colorWithRed:248 / 255.f green:248 / 255.f blue:248 / 255.f alpha:1];
    _inputTextView.enablesReturnKeyAutomatically = YES;
    _inputTextView.layer.cornerRadius = 4;
    _inputTextView.layer.masksToBounds = YES;
    _inputTextView.layer.borderWidth = 0.3f;
    _inputTextView.layer.borderColor = HEXCOLOR(0xA4A4A4).CGColor;
    [_inputTextView setAccessibilityLabel:@"chat_input_textView"];
    if (IOS_FSystenVersion >= 7.0) {
        _inputTextView.layoutManager.allowsNonContiguousLayout = NO;
    }
    [self.inputContainerView addSubview:_inputTextView];
    
    self.recordButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [_recordButton setExclusiveTouch:YES];
    [_recordButton setHidden:YES];
    [_recordButton setBackgroundImage:IMAGE_BY_NAMED(@"press_for_audio") forState:UIControlStateNormal];
    [_recordButton setBackgroundImage:IMAGE_BY_NAMED(@"press_for_audio_down") forState:UIControlStateHighlighted];
    [_recordButton setTitle:NSLocalizedStringFromTable(@"hold_to_talk_title", @"RongCloudKit", nil)
                   forState:UIControlStateNormal];
    [_recordButton setTitle:NSLocalizedStringFromTable(@"release_to_send_title", @"RongCloudKit", nil)
                   forState:UIControlStateHighlighted];
    [_recordButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_recordButton addTarget:self
                      action:@selector(voiceRecordButtonTouchDown:)
            forControlEvents:UIControlEventTouchDown];
    [_recordButton addTarget:self
                      action:@selector(voiceRecordButtonTouchUpInside:)
            forControlEvents:UIControlEventTouchUpInside];
    [_recordButton addTarget:self
                      action:@selector(voiceRecordButtonTouchUpOutside:)
            forControlEvents:UIControlEventTouchUpOutside];
    [_recordButton addTarget:self
                      action:@selector(voiceRecordButtonTouchDragExit:)
            forControlEvents:UIControlEventTouchDragExit];
    [_recordButton addTarget:self
                      action:@selector(voiceRecordButtonTouchDragEnter:)
            forControlEvents:UIControlEventTouchDragEnter];
    [_recordButton addTarget:self
                      action:@selector(voiceRecordButtonTouchCancel:)
            forControlEvents:UIControlEventTouchCancel];
    [self.inputContainerView addSubview:_recordButton];
    
    self.emojiButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [_emojiButton setImage:IMAGE_BY_NAMED(@"chatting_biaoqing_btn_normal") forState:UIControlStateNormal];
    [_emojiButton setImage:IMAGE_BY_NAMED(@"chatting_biaoqing_btn_selected") forState:UIControlStateSelected];
    [_emojiButton setExclusiveTouch:YES];
    [_emojiButton addTarget:self action:@selector(didTouchEmojiDown:) forControlEvents:UIControlEventTouchUpInside];
    [self.inputContainerView addSubview:_emojiButton];
    
    self.additionalButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [_additionalButton setImage:IMAGE_BY_NAMED(@"chat_setmode_add_btn_normal") forState:UIControlStateNormal];
    [_additionalButton setExclusiveTouch:YES];
    [_additionalButton addTarget:self
                          action:@selector(didTouchAddtionalDown:)
                forControlEvents:UIControlEventTouchUpInside];
    [self.inputContainerView addSubview:_additionalButton];
}

- (void)setAutoLayoutForSubViews:(RCChatSessionInputBarControlType)type style:(RCChatSessionInputBarControlStyle)style;
{
    
    if (type == RCChatSessionInputBarControlDefaultType) {
        self.inputContainerView.translatesAutoresizingMaskIntoConstraints = YES;
        [self setLayoutForInputContainerView:style];
    } else if (type == RCChatSessionInputBarControlPubType) {
        self.inputContainerView.translatesAutoresizingMaskIntoConstraints = YES;
        self.menuContainerView.translatesAutoresizingMaskIntoConstraints = YES;
        self.pubSwitchButton.translatesAutoresizingMaskIntoConstraints = YES;
        
        [self setLayoutForInputContainerView:style];
    }
}

- (void)setLayoutForInputContainerView:(RCChatSessionInputBarControlStyle)style {
    self.switchButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.recordButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.emojiButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.additionalButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSDictionary *_bindingViews =
    NSDictionaryOfVariableBindings(_switchButton, _inputTextView, _recordButton, _emojiButton, _additionalButton);
    
    NSString *format;
    
    switch (style) {
        case RC_CHAT_INPUT_BAR_STYLE_SWITCH_CONTAINER_EXTENTION:
            format =
            @"H:|-10-[_switchButton(30)]-10-[_recordButton]-10-[_emojiButton(" @"30)]-10-[_additionalButton(30)]-10-|";
            break;
        case RC_CHAT_INPUT_BAR_STYLE_EXTENTION_CONTAINER_SWITCH:
            format =
            @"H:|-10-[_additionalButton(30)]-10-[_recordButton]-10-[_" @"emojiButton(30)]-10-[_switchButton(30)]-10-|";
            break;
        case RC_CHAT_INPUT_BAR_STYLE_CONTAINER_SWITCH_EXTENTION:
            format =
            @"H:|-10-[_recordButton]-10-[_emojiButton(30)]-10-[_switchButton(" @"30)]-10-[_additionalButton(30)]-10-|";
            break;
        case RC_CHAT_INPUT_BAR_STYLE_CONTAINER_EXTENTION_SWITCH:
            format =
            @"H:|-10-[_recordButton]-10-[_emojiButton(30)]-10-[_" @"additionalButton(30)]-10-[_switchButton(30)]-10-|";
            break;
        case RC_CHAT_INPUT_BAR_STYLE_SWITCH_CONTAINER:
            format =
            @"H:|-10-[_switchButton(30)]-10-[_recordButton]-10-[_emojiButton(" @"30)]-10-[_additionalButton(0)]-0-|";
            break;
        case RC_CHAT_INPUT_BAR_STYLE_CONTAINER_SWITCH:
            format =
            @"H:|-10-[_recordButton]-10-[_emojiButton(30)]-10-[_switchButton(" @"30)]-10-[_additionalButton(0)]-0-|";
            break;
        case RC_CHAT_INPUT_BAR_STYLE_EXTENTION_CONTAINER:
            format =
            @"H:|-10-[_additionalButton(30)]-10-[_recordButton]-10-[_" @"emojiButton(30)]-10-[_switchButton(0)]-0-|";
            break;
        case RC_CHAT_INPUT_BAR_STYLE_CONTAINER_EXTENTION:
            format =
            @"H:|-10-[_recordButton]-10-[_emojiButton(30)]-10-[_" @"additionalButton(30)]-10-[_switchButton(0)]-0-|";
            break;
        case RC_CHAT_INPUT_BAR_STYLE_CONTAINER:
            format = @"H:|-0-[_switchButton(0)]-10-[_recordButton]-10-[_emojiButton(30)" @"]-10-[_additionalButton(0)]-0-|";
            break;
        default:
            break;
    }
    
    [self.inputContainerSubViewConstraints
     addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:nil views:_bindingViews]];
    
    [self.inputContainerSubViewConstraints
     addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[_switchButton(30)]"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:_bindingViews]];
    [self.inputContainerSubViewConstraints
     addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-7-[_recordButton(36)]"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:_bindingViews]];
    
    [self.inputContainerSubViewConstraints
     addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[_emojiButton(30)]"
                                                                 options:kNilOptions
                                                                 metrics:nil
                                                                   views:_bindingViews]];
    
    [self.inputContainerSubViewConstraints
     addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[_additionalButton(30)]"
                                                                 options:kNilOptions
                                                                 metrics:nil
                                                                   views:_bindingViews]];
    
    [self.inputContainerView addConstraints:self.inputContainerSubViewConstraints];
    [self updateConstraintsIfNeeded];
    [self layoutIfNeeded];
    self.inputTextView.translatesAutoresizingMaskIntoConstraints = YES;
    CGRect inputRect = CGRectMake(self.recordButton.frame.origin.x, self.recordButton.frame.origin.y,
                                  self.recordButton.frame.size.width, self.recordButton.frame.size.height);
    [self.inputTextView setFrame:inputRect];
}

- (void)setPublicServiceMenu:(RCPublicServiceMenu *)publicServiceMenu {
    for (UIView *subView in [self.menuContainerView subviews]) {
        [subView removeFromSuperview];
    }
    _publicServiceMenu = publicServiceMenu;
    
    NSUInteger count = publicServiceMenu.menuItems.count;
    CGRect round = self.menuContainerView.bounds;
    CGFloat itemWidth = (round.size.width - (count - 1) * RC_PUBLIC_SERVICE_MENU_SEPARATE_WIDTH) / count;
    CGFloat itemHeight = round.size.height;
    
    for (int i = 0; i < count; i++) {
        RCPublicServiceMenuItem *menuItem = publicServiceMenu.menuItems[i];
        
        UIView *container = [[UIView alloc] initWithFrame:CGRectMake(i * (itemWidth + 1), 0, itemWidth+1, itemHeight)];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        
        
        label.numberOfLines = 1;
        label.font = [UIFont systemFontOfSize:RC_PUBLIC_SERVICE_MENU_BUTTON_FONT_SIZE];
        label.textColor = [UIColor blackColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = menuItem.name;
        
        CGSize size = CGSizeMake(itemWidth, 2000);
        
        //        CGSize labelsize = [menuItem.name boundingRectWithSize:size
        //                                                       options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin |NSStringDrawingUsesFontLeading
        //                                                    attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:RC_PUBLIC_SERVICE_MENU_BUTTON_FONT_SIZE]}
        //                                                       context:nil].size;
        //        CGSize labelsize = RC_MULTILINE_TEXTSIZE(menuItem.name, [UIFont systemFontOfSize:RC_PUBLIC_SERVICE_MENU_BUTTON_FONT_SIZE], size, NSLineBreakByTruncatingTail);
        
        CGSize labelsize = CGSizeZero;
        
        if (IOS_FSystenVersion < 7.0) {
            
            labelsize = RC_MULTILINE_TEXTSIZE_LIOS7(menuItem.name, [UIFont systemFontOfSize:RC_PUBLIC_SERVICE_MENU_BUTTON_FONT_SIZE], size, NSLineBreakByTruncatingTail);
        }
        else
        {
            labelsize = RC_MULTILINE_TEXTSIZE_GEIOS7(menuItem.name, [UIFont systemFontOfSize:RC_PUBLIC_SERVICE_MENU_BUTTON_FONT_SIZE], size);
        }
        
        if (menuItem.type == RC_PUBLIC_SERVICE_MENU_ITEM_GROUP) {
            UIImageView *icon = [[UIImageView alloc] initWithImage:IMAGE_BY_NAMED(@"public_serive_menu_icon")];
            CGSize iconSize = icon.image.size;
            CGRect iconFrame = CGRectZero;
            iconFrame.origin.x = (itemWidth - labelsize.width - iconSize.width - RC_PUBLIC_SERVICE_MENU_ICON_GAP)/2;
            iconFrame.origin.y = (itemHeight - iconSize.height)/2;
            iconFrame.size = iconSize;
            icon.frame = iconFrame;
            
            CGRect lableFrame = CGRectZero;
            lableFrame.origin.x = iconFrame.origin.x + iconFrame.size.width + RC_PUBLIC_SERVICE_MENU_ICON_GAP;
            lableFrame.origin.y = (itemHeight - labelsize.height)/2;
            lableFrame.size = labelsize;
            label.frame = lableFrame;
            [container addSubview:icon];
            [container addSubview:label];
        } else {
            CGRect lableFrame = CGRectZero;
            lableFrame.origin.x = (itemWidth - labelsize.width)/2;
            lableFrame.origin.y = (itemHeight - labelsize.height)/2;
            lableFrame.size = labelsize;
            label.frame = lableFrame;
            [container addSubview:label];
        }
        
        if (i != count - 1) {
            UIView *line = [self newLine];
            line.frame = CGRectMake(itemWidth, 0, 1, itemHeight);
            [container addSubview:line];
        }
        UIGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onMenuGroupPushed:)];
        [container addGestureRecognizer:tapRecognizer];
        
        [self.menuContainerView addSubview:container];
        
        container.tag = i;
        //
        //        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        //        btn.frame = CGRectMake(i * itemWidth, 0, itemWidth, itemHeight);
        //
        //        if (menuItem.type == RC_PUBLIC_SERVICE_MENU_ITEM_GROUP) {
        //            [btn setImage:IMAGE_BY_NAMED(@"public_serive_menu_icon") forState:UIControlStateNormal];
        //            btn.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 7);
        //        }
        //
        //        btn.titleLabel.textAlignment = NSTextAlignmentCenter;
        //        [btn setTitle:menuItem.name forState:UIControlStateNormal];
        //        [btn setBackgroundColor:menuBackGroundColor];
        //        [btn.titleLabel setFont:[UIFont systemFontOfSize:RC_PUBLIC_SERVICE_MENU_BUTTON_FONT_SIZE]];
        //        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        //        btn.tag = i;
        //        [btn addTarget:self action:@selector(onMenuGroupPushed:) forControlEvents:UIControlEventTouchUpInside];
        //        btn.layer.borderWidth = 0.1;
        //        btn.layer.borderColor = [UIColor colorWithRed:191 / 255.f green:191 / 255.f blue:191 / 255.f alpha:1].CGColor;
        //        [btn setBackgroundImage:IMAGE_BY_NAMED(@"press_for_audio") forState:UIControlStateNormal];
        //        [btn setBackgroundImage:IMAGE_BY_NAMED(@"press_for_audio_down") forState:UIControlStateHighlighted];
        //         [self.menuContainerView addSubview:btn];
    }
}
- (void)onPublicServiceMenuItemSelected:(RCPublicServiceMenuItem *)selectedMenuItem {
    [self.delegate onPublicServiceMenuItemSelected:selectedMenuItem];
}

- (void)onMenuGroupPushed:(id)sender {
    
    UITapGestureRecognizer *recognizer = (UITapGestureRecognizer *)sender;
    UIView *touchedView = recognizer.view;
    int tag = (int)touchedView.tag;
    RCPublicServiceMenuItem *item = self.publicServiceMenu.menuItems[tag];
    
    CGRect frame = [self.clientView convertRect:touchedView.frame fromView:touchedView.superview];
    if (self.publicServicePopupMenu.frame.size.height > 0) {
        [self dismissPublicServiceMenuPopupView];
    } else {
        if (item.type != RC_PUBLIC_SERVICE_MENU_ITEM_GROUP) {
            [self onPublicServiceMenuItemSelected:item];
        } else {
            [self.publicServicePopupMenu displayMenuItems:item.subMenuItems atPoint:CGPointMake(frame.origin.x + RC_PUBLIC_SERVICE_SUBMENU_PADDING, frame.origin.y) withWidth:frame.size.width - RC_PUBLIC_SERVICE_SUBMENU_PADDING * 2];
        }
    }
}
- (void)onSubMenuPushed:(id)sender {
}
- (BOOL)canBecomeFirstResponder {
    return YES;
}
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(onSubMenuPushed:)) {
        return YES;
    }
    return NO; //隐藏系统默认的菜单项
}

#pragma mark - Notifications

- (void)rcInputBar_registerForNotifications {
    [self rcInputBar_unregisterForNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(rcInputBar_didReceiveKeyboardWillShowNotification:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(rcInputBar_didReceiveKeyboardWillHideNotification:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(switchToRecord)
                                                 name:@"switchToRecord"
                                               object:nil];
}

- (void)rcInputBar_unregisterForNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)rcInputBar_didReceiveKeyboardWillShowNotification:(NSNotification *)notification {
    DebugLog(@"%s", __FUNCTION__);
    
    NSDictionary *userInfo = [notification userInfo];
    CGRect keyboardBeginFrame = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect keyboardEndFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    if (!CGRectEqualToRect(keyboardBeginFrame, keyboardEndFrame)) {
        UIViewAnimationCurve animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
        NSInteger animationCurveOption = (animationCurve << 16);
        
        double animationDuration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        [UIView animateWithDuration:animationDuration
                              delay:0.0
                            options:animationCurveOption
                         animations:^{
                             if ([self.delegate respondsToSelector:@selector(keyboardWillShowWithFrame:)]) {
                                 [self.delegate keyboardWillShowWithFrame:keyboardEndFrame];
                             }
                         }
                         completion:^(BOOL finished) {
                             
                         }];
    }
}

- (void)rcInputBar_didReceiveKeyboardWillHideNotification:(NSNotification *)notification {
    DebugLog(@"%s", __FUNCTION__);
    
    NSDictionary *userInfo = [notification userInfo];
    CGRect keyboardBeginFrame = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect keyboardEndFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    if (!CGRectEqualToRect(keyboardBeginFrame, keyboardEndFrame)) {
        if ([self.delegate respondsToSelector:@selector(keyboardWillHide)]) {
            [self.delegate keyboardWillHide];
        }
    }
}

- (void)pubSwitchValueChanged {
    if (self.menuContainerView.hidden) {
        self.menuContainerView.hidden = NO;
        self.inputContainerView.hidden = YES;
        self.inputTextView.text = @"";
        
        _inputTextview_height = 36.0f;
        
        CGRect intputTextRect = self.inputTextView.frame;
        intputTextRect.size.height = _inputTextview_height;
        intputTextRect.origin.y = 7;
        [_inputTextView setFrame:intputTextRect];
        
        CGRect vRect = self.frame;
        vRect.size.height = Height_ChatSessionInputBar;
        vRect.origin.y = _originalPositionY;
        _currentPositionY = _originalPositionY;
        
        [self setFrame:vRect];
        
        CGRect rectFrame = self.inputContainerView.frame;
        rectFrame.size.height = vRect.size.height;
        self.inputContainerView.frame = rectFrame;
        
        [self.delegate chatSessionInputBarControlContentSizeChanged:vRect];
    } else {
        self.menuContainerView.hidden = YES;
        self.inputContainerView.hidden = NO;
    }
    
    [self.pubSwitchButton setImage:IMAGE_BY_NAMED(self.menuContainerView.hidden ? @"pub_menu" : @"pub_input")
                          forState:UIControlStateNormal];
    [self.delegate didTouchPubSwitchButton:_inputContainerView.hidden];
    [self dismissPublicServiceMenuPopupView];
}

- (void)switchInputBoxOrRecord {
    
    if (self.inputTextView.hidden) {
        [self switchToInputBox];
    } else {
        [self switchToRecord];
    }
}

- (void)switchToInputBox
{
    self.recordButton.hidden = YES;
    self.inputTextView.hidden = NO;
    _inputTextview_height = 36.0f;
    if (_inputTextView.contentSize.height < 70 && _inputTextView.contentSize.height > 36.0f) {
        _inputTextview_height = _inputTextView.contentSize.height;
    }
    if (_inputTextView.contentSize.height >= 70) {
        _inputTextview_height = 70;
    }
    
    CGRect intputTextRect = self.inputTextView.frame;
    intputTextRect.size.height = _inputTextview_height;
    intputTextRect.origin.y = 7;
    [_inputTextView setFrame:intputTextRect];
    
    CGRect vRect = self.frame;
    vRect.size.height = Height_ChatSessionInputBar + (_inputTextview_height - 36);
    vRect.origin.y = _originalPositionY - (_inputTextview_height - 36);
    self.frame = vRect;
    
    CGRect rectFrame = self.inputContainerView.frame;
    rectFrame.size.height = vRect.size.height;
    self.inputContainerView.frame = rectFrame;
    
    _currentPositionY = vRect.origin.y;
    [self.delegate chatSessionInputBarControlContentSizeChanged:vRect];
    [self.switchButton setImage:IMAGE_BY_NAMED(self.recordButton.hidden ? @"chat_setmode_voice_btn_normal"
                                               : @"chat_setmode_key_btn_normal")
                       forState:UIControlStateNormal];
    [self.switchButton setImage:IMAGE_BY_NAMED(self.recordButton.hidden ? @"chat_setmode_voice_btn_selected"
                                               : @"chat_setmode_key_btn_selected")
                       forState:UIControlStateHighlighted];
    
    
    [self.delegate didTouchSwitchButton:self.inputTextView.hidden];
}

- (void)switchToRecord
{
    if (self.inputTextView.hidden) {
        return;
    }
    else
    {
        self.inputTextView.hidden = YES;
        self.recordButton.hidden = NO;
        // self.inputTextView.text = @"";
        
        _inputTextview_height = 36.0f;
        
        CGRect intputTextRect = self.inputTextView.frame;
        intputTextRect.size.height = _inputTextview_height;
        intputTextRect.origin.y = 7;
        [_inputTextView setFrame:intputTextRect];
        
        CGRect vRect = self.frame;
        vRect.size.height = Height_ChatSessionInputBar;
        vRect.origin.y = _originalPositionY;
        _currentPositionY = _originalPositionY;
        
        [self setFrame:vRect];
        
        CGRect rectFrame = self.inputContainerView.frame;
        rectFrame.size.height = vRect.size.height;
        self.inputContainerView.frame = rectFrame;
        
        [self.delegate chatSessionInputBarControlContentSizeChanged:vRect];
        [self.switchButton setImage:IMAGE_BY_NAMED(self.recordButton.hidden ? @"chat_setmode_voice_btn_normal"
                                                   : @"chat_setmode_key_btn_normal")
                           forState:UIControlStateNormal];
        [self.switchButton setImage:IMAGE_BY_NAMED(self.recordButton.hidden ? @"chat_setmode_voice_btn_selected"
                                                   : @"chat_setmode_key_btn_selected")
                           forState:UIControlStateHighlighted];
        
        
        [self.delegate didTouchSwitchButton:self.inputTextView.hidden];
    }
}

- (void)didTouchEmojiDown:(UIButton *)sender {
    if (self.inputTextView.hidden) {
        [self switchInputBoxOrRecord];
    }
    [self.delegate didTouchEmojiButton:sender];
}
- (void)didTouchAddtionalDown:(UIButton *)sender {
    if (self.inputTextView.hidden) {
        [self switchInputBoxOrRecord];
    }
    [self.delegate didTouchAddtionalButton:sender];
}

- (void)voiceRecordButtonTouchDown:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(didTouchRecordButon:event:)]) {
        [self.delegate didTouchRecordButon:sender event:UIControlEventTouchDown];
    }
}
- (void)voiceRecordButtonTouchUpInside:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(didTouchRecordButon:event:)]) {
        [self.delegate didTouchRecordButon:sender event:UIControlEventTouchUpInside];
    }
}

- (void)voiceRecordButtonTouchCancel:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(didTouchRecordButon:event:)]) {
        [self.delegate didTouchRecordButon:sender event:UIControlEventTouchCancel];
    }
}
- (void)voiceRecordButtonTouchDragExit:(UIButton *)sender {
    
    if ([self.delegate respondsToSelector:@selector(didTouchRecordButon:event:)]) {
        [self.delegate didTouchRecordButon:sender event:UIControlEventTouchDragExit];
    }
}
- (void)voiceRecordButtonTouchDragEnter:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(didTouchRecordButon:event:)]) {
        [self.delegate didTouchRecordButon:sender event:UIControlEventTouchDragEnter];
    }
}
- (void)voiceRecordButtonTouchUpOutside:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(didTouchRecordButon:event:)]) {
        [self.delegate didTouchRecordButon:sender event:UIControlEventTouchUpOutside];
    }
}

#pragma mark <UITextViewDelegate>
- (void)changeInputViewFrame:(NSString *)text textView:(UITextView *)textView range:(NSRange)range {
    _inputTextview_height = 36.0f;
    if (_inputTextView.contentSize.height < 70 && _inputTextView.contentSize.height > 36.0f) {
        _inputTextview_height = _inputTextView.contentSize.height;
        
    }
    if (_inputTextView.contentSize.height >= 70) {
        _inputTextview_height = 70;
        
    }
    
    CGSize textViewSize=[self TextViewAutoCalculateRectWith:text FontSize:16.0 MaxSize:CGSizeMake(_inputTextView.frame.size.width, 70)];
    
    CGSize textSize=[self TextViewAutoCalculateRectWith:textView.text FontSize:16.0 MaxSize:CGSizeMake(_inputTextView.frame.size.width, 70)];
    if (textViewSize.height<=36.0f&&range.location==0) {
        _inputTextview_height=36.0f;
    }
    else if(textViewSize.height>36.0f&&textViewSize.height<=55.0f)
    {
        _inputTextview_height=55.0f;
    }
    else if (textViewSize.height>55)
    {
        _inputTextview_height=70.0f;
    }
    
    if ([text isEqualToString:@""]&&range.location!=0) {
        if (textSize.width>=_inputTextView.frame.size.width&&range.length==1) {
            if (_inputTextView.contentSize.height < 70 && _inputTextView.contentSize.height > 36.0f) {
                _inputTextview_height = _inputTextView.contentSize.height;
                
            }
            if (_inputTextView.contentSize.height >= 70) {
                _inputTextview_height = 70;
                
            }
        }
        
        else
        {
            NSString *headString=[textView.text substringToIndex:range.location];
            NSString *lastString=[textView.text substringFromIndex:range.location+range.length];
            
            CGSize locationSize=[self TextViewAutoCalculateRectWith:[NSString stringWithFormat:@"%@%@",headString,lastString] FontSize:16.0 MaxSize:CGSizeMake(_inputTextView.frame.size.width, 70)];
            if (locationSize.height<=36.0) {
                _inputTextview_height=36.0;
                
            }
            if (locationSize.height>36.0&&locationSize.height<=55.0) {
                _inputTextview_height= 55.0;
                
            }
            if (locationSize.height>55.0) {
                _inputTextview_height=70.0;
                
            }
            
        }
        
    }
    float animateDuration = 0.5;
    [UIView animateWithDuration:animateDuration
                     animations:^{
                         CGRect intputTextRect = self.inputTextView.frame;
                         intputTextRect.size.height = _inputTextview_height;
                         //intputTextRect.origin.y = 7;
                         [_inputTextView setFrame:intputTextRect];
                         CGRect vRect = self.frame;
                         vRect.size.height = Height_ChatSessionInputBar + (_inputTextview_height - 36);
                         vRect.origin.y = _originalPositionY - (_inputTextview_height - 36);
                         self.frame = vRect;
                         CGRect rectFrame = self.inputContainerView.frame;
                         rectFrame.size.height = vRect.size.height;
                         self.inputContainerView.frame = rectFrame;
                         
                         _currentPositionY = vRect.origin.y;
                         [self.delegate chatSessionInputBarControlContentSizeChanged:vRect];
                         if (_inputTextview_height>70.0) {
                             textView.contentOffset=CGPointMake(0, 100);
                         }
                     }];
    }

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    [self.delegate inputTextView:textView shouldChangeTextInRange:range replacementText:text];
    if ([text isEqualToString:@"\n"]) {
        if ([self.delegate respondsToSelector:@selector(didTouchKeyboardReturnKey:text:)]) {
            NSString *_needToSendText = textView.text;
            NSString *_formatString =
            [_needToSendText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (0 == [_formatString length]) {
                //                UIAlertView *notAllowSendSpace = [[UIAlertView alloc]
                //                        initWithTitle:nil
                //                              message:NSLocalizedStringFromTable(@"whiteSpaceMessage", @"RongCloudKit", nil)
                //                             delegate:self
                //                    cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"RongCloudKit", nil)
                //                    otherButtonTitles:nil, nil];
                //                [notAllowSendSpace show];
            } else {
                [self.delegate didTouchKeyboardReturnKey:self text:[_needToSendText copy]];
            }
        }
        self.inputTextView.text = @"";
        
        _inputTextview_height = 36.0f;
        
        CGRect intputTextRect = self.inputTextView.frame;
        intputTextRect.size.height = _inputTextview_height;
        intputTextRect.origin.y = 7;
        [_inputTextView setFrame:intputTextRect];
        
        CGRect vRect = self.frame;
        vRect.size.height = Height_ChatSessionInputBar;
        vRect.origin.y = _originalPositionY;
        _currentPositionY = _originalPositionY;
        
        [self setFrame:vRect];
        
        CGRect rectFrame = self.inputContainerView.frame;
        rectFrame.size.height = vRect.size.height;
        self.inputContainerView.frame = rectFrame;
        
        [self.delegate chatSessionInputBarControlContentSizeChanged:vRect];
        
        return NO;
    }
    
    [self changeInputViewFrame:text textView:textView range:range];
    return YES;
}

- (CGSize)TextViewAutoCalculateRectWith:(NSString*)text FontSize:(CGFloat)fontSize MaxSize:(CGSize)maxSize

{
    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc]init];
    paragraphStyle.lineBreakMode=NSLineBreakByWordWrapping;
    if (text) {
        CGSize labelSize = CGSizeZero;
        if (IOS_FSystenVersion < 7.0) {
            labelSize = RC_MULTILINE_TEXTSIZE_LIOS7(text, [UIFont systemFontOfSize:fontSize], maxSize, NSLineBreakByTruncatingTail);
        }
        else
        {
            labelSize = RC_MULTILINE_TEXTSIZE_GEIOS7(text, [UIFont systemFontOfSize:fontSize], maxSize);
        }
//        NSDictionary* attributes =@{NSFontAttributeName:[UIFont systemFontOfSize:fontSize],NSParagraphStyleAttributeName:paragraphStyle.copy};
//        CGSize labelSize = [text boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading|NSStringDrawingTruncatesLastVisibleLine attributes:attributes context:nil].size;
        labelSize.height=ceil(labelSize.height);
        labelSize.width=ceil(labelSize.width);
        return labelSize;
    } else {
        return CGSizeZero;
    }
}
- (void)textViewDidEndEditing:(UITextView *)textView {
    DebugLog(@"%s, %@", __FUNCTION__, textView.text);
    // filter the space
}
- (void)textViewDidChange:(UITextView *)textView {
    CGRect line = [textView caretRectForPosition:textView.selectedTextRange.start];
    CGFloat overflow = line.size.height - (textView.contentOffset.y + textView.bounds.size.height -
                                           textView.contentInset.bottom - textView.contentInset.top);
    if (overflow > 0) {
        // We are at the bottom of the visible text and introduced a line feed,
        // scroll down (iOS 7 does not do it)
        // Scroll caret to visible area
        CGPoint offset = textView.contentOffset;
        //offset.y += overflow + 7; // leave 7 pixels margin
        // Cannot animate with setContentOffset:animated: or caret will not appear
        [UIView animateWithDuration:.2
                         animations:^{
                             [textView setContentOffset:offset];
                         }];
    }
    
    
    NSRange range;
    range.location = self.inputTextView.text.length;
    [self changeInputViewFrame:self.inputTextView.text textView:self.inputTextView range:range];

}

- (RCPublicServicePopupMenuView *)publicServicePopupMenu {
    if (!_publicServicePopupMenu) {
        _publicServicePopupMenu = [[RCPublicServicePopupMenuView alloc] initWithFrame:CGRectZero];
        _publicServicePopupMenu.delegate = self;
        
    }
    return _publicServicePopupMenu;
}
- (void)setClientView:(UIView *)clientView {
    _clientView = clientView;
}

- (void)dismissPublicServiceMenuPopupView {
    [self.publicServicePopupMenu resignFirstResponder];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIView *)newLine {
    UILabel *line = [UILabel new];
    line.backgroundColor = [UIColor colorWithRed:221 / 255.0 green:221 / 255.0 blue:221 / 255.0 alpha:1];
    return line;
}
@end
