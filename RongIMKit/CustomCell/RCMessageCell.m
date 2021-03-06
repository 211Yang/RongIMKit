//
//  RCMessageCommonCell.m
//  RongIMKit
//
//  Created by xugang on 15/1/28.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCMessageCell.h"
#import "RCUserInfoLoader.h"
#import "RCKitUtility.h"
#import "RCTipLabel.h"
#import "RCKitUtility.h"
#import "RCloudImageView.h"
#import "RongIMKit.h"
#import "RCKitCommonDefine.h"
#import <RongIMLib/RongIMLib.h>

@interface RCMessageCell () <RCUserInfoLoaderObserver>
//- (void) configure;
- (void)setCellAutoLayout;

@end

// static int indexCell = 1;

@implementation RCMessageCell

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupMessageCellView];
    }
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupMessageCellView];
    }
    return self;
}
- (void)setupMessageCellView
{
    _isDisplayNickname = NO;
    self.delegate = nil;
    
    self.portraitImageView = [[RCloudImageView alloc]
                              initWithPlaceholderImage:[RCKitUtility imageNamed:@"default_portrait_msg" ofBundle:@"RongCloud.bundle"]];
    
    self.messageContentView = [[RCContentView alloc] initWithFrame:CGRectZero];
    self.statusContentView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.nicknameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.nicknameLabel.backgroundColor = [UIColor clearColor];
    [self.nicknameLabel setFont:[UIFont systemFontOfSize:12.5f]];
    [self.nicknameLabel setTextColor:[UIColor grayColor]];
    
    //点击头像
    UITapGestureRecognizer *portraitTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapUserPortaitEvent:)];
    portraitTap.numberOfTapsRequired = 1;
    portraitTap.numberOfTouchesRequired = 1;
    [self.portraitImageView addGestureRecognizer:portraitTap];
    
    UILongPressGestureRecognizer *portraitLongPress =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressUserPortaitEvent:)];
    [self.portraitImageView addGestureRecognizer:portraitLongPress];
    
    
    self.portraitImageView.userInteractionEnabled = YES;
    
    [self.baseContentView addSubview:self.portraitImageView];
    [self.baseContentView addSubview:self.messageContentView];
    [self.baseContentView addSubview:self.statusContentView];
    [self.baseContentView addSubview:self.nicknameLabel];
    [self setPortraitStyle:[RCIM sharedRCIM].globalMessageAvatarStyle];
    
    self.statusContentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    _statusContentView.backgroundColor = [UIColor clearColor];
    [self.baseContentView addSubview:_statusContentView];
    
    __weak typeof(&*self) __blockself = self;
    [self.messageContentView registerFrameChangedEvent:^(CGRect frame) {
        if (__blockself.model) {
            if (__blockself.model.messageDirection == MessageDirection_SEND) {
                __blockself.statusContentView.frame = CGRectMake(
                                                                 frame.origin.x - 10 - 25, frame.origin.y + (frame.size.height - 25) / 2.0f, 25, 25);
            } else {
                __blockself.statusContentView.frame = CGRectZero;
            }
        }
        
    }];
    
    self.messageFailedStatusView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    [_messageFailedStatusView
     setImage:[RCKitUtility imageNamed:@"message_send_fail_status" ofBundle:@"RongCloud.bundle"]
     forState:UIControlStateNormal];
    [self.statusContentView addSubview:_messageFailedStatusView];
    _messageFailedStatusView.hidden = YES;
    [_messageFailedStatusView addTarget:self
                                 action:@selector(didclickMsgFailedView:)
                       forControlEvents:UIControlEventTouchUpInside];
    
    self.messageActivityIndicatorView =
    [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.statusContentView addSubview:_messageActivityIndicatorView];
    _messageActivityIndicatorView.hidden = YES;
    self.messageHasReadStatusView = [[UIView alloc] initWithFrame:CGRectMake(10, 3, 25, 25)];
    UIImageView *hasReadView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    [hasReadView setImage:IMAGE_BY_NAMED(@"message_read_status")];
    [self.messageHasReadStatusView addSubview:hasReadView] ;
    [self.statusContentView addSubview:self.messageHasReadStatusView];
    self.messageHasReadStatusView.hidden = YES;
    self.messageSendSuccessStatusView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 40, 20)];
    UILabel *sendSuccessLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 20)];
    //        sendSuccessLabel.text = NSLocalizedStringFromTable(@"MessageHasSend", @"RongCloudKit",
    //                                                           nil);
    sendSuccessLabel.font = [UIFont systemFontOfSize:14];
    sendSuccessLabel.textColor = HEXCOLOR(0x8c8c8c);
    [self.messageSendSuccessStatusView addSubview:sendSuccessLabel] ;
    [self.statusContentView addSubview:self.messageSendSuccessStatusView];
    self.messageSendSuccessStatusView.hidden = YES;

}
- (void)setPortraitStyle:(RCUserAvatarStyle)portraitStyle {
    _portraitStyle = portraitStyle;

    if (_portraitStyle == RC_USER_AVATAR_RECTANGLE) {
        self.portraitImageView.layer.cornerRadius = [[RCIM sharedRCIM] portraitImageViewCornerRadius];
    }
    if (_portraitStyle == RC_USER_AVATAR_CYCLE) {
        self.portraitImageView.layer.cornerRadius = [[RCIM sharedRCIM] globalMessagePortraitSize].height/2;
    }
    self.portraitImageView.layer.masksToBounds = YES;
}
//- (void)prepareForReuse
//{
//    [super prepareForReuse];
//
//}

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    self.messageSendSuccessStatusView.hidden = YES;
    self.messageHasReadStatusView.hidden = YES;

    _isDisplayNickname = model.isDisplayNickname;
    if(model.content.senderUserInfo && [model.content.senderUserInfo.userId length]>0 && [model.content.senderUserInfo.portraitUri length]>0 && (model.conversationType != ConversationType_GROUP))
    {
        
        model.userInfo = model.content.senderUserInfo;
        [self.portraitImageView setImageURL:[NSURL URLWithString:model.content.senderUserInfo.portraitUri]];
        [self.nicknameLabel setText:model.content.senderUserInfo.name];
    }else{
    
        // DebugLog(@"%s", __FUNCTION__);
        //如果是客服，跟换默认头像
        if (ConversationType_CUSTOMERSERVICE == model.conversationType) {
            if (model.messageDirection == MessageDirection_RECEIVE) {
                [self.portraitImageView setPlaceholderImage:[RCKitUtility imageNamed:@"portrait_kefu" ofBundle:@"RongCloud.bundle"]];
            } else {
                [self.portraitImageView setPlaceholderImage:[RCKitUtility imageNamed:@"default_portrait_msg" ofBundle:@"RongCloud.bundle"]];
            }
        }
        if (ConversationType_APPSERVICE == model.conversationType ||
            ConversationType_PUBLICSERVICE == model.conversationType) {
            if (model.messageDirection == MessageDirection_RECEIVE) {
                RCPublicServiceProfile *serviceProfile =
                [[RCIMClient sharedRCIMClient] getPublicServiceProfile:(RCPublicServiceType)model.conversationType publicServiceId:model.senderUserId];
                     if (serviceProfile) {
                    // model.userInfo = userInfo;
                    [self.portraitImageView setImageURL:[NSURL URLWithString:serviceProfile.portraitUrl]];
                    [self.nicknameLabel setText:serviceProfile.name];
                }
            }else{
                    [[RCUserInfoLoader sharedUserInfoLoader] removeObserver:self];
                    RCUserInfo *userInfo =
                    [[RCUserInfoLoader sharedUserInfoLoader] loadUserInfo:model.senderUserId observer:self];
                    if (userInfo) {
                        model.userInfo = userInfo;
                        [self.portraitImageView setImageURL:[NSURL URLWithString:userInfo.portraitUri]];
                        [self.nicknameLabel setText:userInfo.name];
                    }else {
                        [self.portraitImageView setImageURL:nil];
                        [self.nicknameLabel setText:nil];
                    }
            }
        } else if (ConversationType_GROUP == model.conversationType) {
            if(model.content.senderUserInfo && [model.content.senderUserInfo.userId length]>0 && [model.content.senderUserInfo.portraitUri length]>0 && ![RCIM sharedRCIM].groupUserInfoDataSource)
            {
                
                model.userInfo = model.content.senderUserInfo;
                [self.portraitImageView setImageURL:[NSURL URLWithString:model.content.senderUserInfo.portraitUri]];
                [self.nicknameLabel setText:model.content.senderUserInfo.name];
            }else{
                [[RCUserInfoLoader sharedUserInfoLoader] removeObserver:self];
                RCUserInfo *userInfo = [[RCUserInfoLoader sharedUserInfoLoader] loadGroupUserInfo:model.senderUserId groupId:self.model.targetId observer:self];
                if (userInfo.name.length) {
                    if (!userInfo.portraitUri.length) {
                        userInfo.portraitUri = [[RCUserInfoLoader sharedUserInfoLoader] loadUserInfo:model.senderUserId observer:self].portraitUri;
                    }
                } else {
                    userInfo = [[RCUserInfoLoader sharedUserInfoLoader] loadUserInfo:model.senderUserId observer:self];
                }
                
                if (userInfo) {
                    model.userInfo = userInfo;
                    [self.portraitImageView setImageURL:[NSURL URLWithString:userInfo.portraitUri]];
                    [self.nicknameLabel setText:userInfo.name];
                } else {
                    [self.portraitImageView setImageURL:nil];
                    [self.nicknameLabel setText:nil];
                }
            }
        } else {
            [[RCUserInfoLoader sharedUserInfoLoader] removeObserver:self];
            RCUserInfo *userInfo = [[RCUserInfoLoader sharedUserInfoLoader] loadUserInfo:model.senderUserId observer:self];
            if (userInfo) {
                model.userInfo = userInfo;
                [self.portraitImageView setImageURL:[NSURL URLWithString:userInfo.portraitUri]];
                [self.nicknameLabel setText:userInfo.name];
            } else {
                [self.portraitImageView setImageURL:nil];
                [self.nicknameLabel setText:nil];
            }
        }
    }

    [self setCellAutoLayout];
}
- (void)setCellAutoLayout {

    _messageContentViewWidth = 200;
    // receiver
    if (MessageDirection_RECEIVE == self.messageDirection) {
        self.nicknameLabel.hidden = !self.isDisplayNickname;
        CGFloat portraitImageX = 10;
        self.portraitImageView.frame = CGRectMake(portraitImageX, 10, [RCIM sharedRCIM].globalMessagePortraitSize.width,
                                                  [RCIM sharedRCIM].globalMessagePortraitSize.height);
        self.nicknameLabel.frame =
            CGRectMake(portraitImageX + self.portraitImageView.bounds.size.width + 12, 10, 200, 17);

        CGFloat messageContentViewY = 10;
        if (self.isDisplayNickname) {
            messageContentViewY = 10 + 17 + 3;
        }
        self.messageContentView.frame =
            CGRectMake(portraitImageX + self.portraitImageView.bounds.size.width + 12, messageContentViewY,
                       _messageContentViewWidth, self.baseContentView.bounds.size.height - (messageContentViewY));
    } else { // owner
        self.nicknameLabel.hidden = YES;
        CGFloat portraitImageX =
            self.baseContentView.bounds.size.width - ([RCIM sharedRCIM].globalMessagePortraitSize.width + 10);
        self.portraitImageView.frame = CGRectMake(portraitImageX, 10, [RCIM sharedRCIM].globalMessagePortraitSize.width,
                                                  [RCIM sharedRCIM].globalMessagePortraitSize.height);

        self.messageContentView.frame =
            CGRectMake(self.baseContentView.bounds.size.width -
                           (_messageContentViewWidth + 12 + [RCIM sharedRCIM].globalMessagePortraitSize.width + 10),
                       10, _messageContentViewWidth, self.baseContentView.bounds.size.height - (10));
    }

    [self updateStatusContentView:self.model];
}

- (void)updateStatusContentView:(RCMessageModel *)model {
    self.messageSendSuccessStatusView.hidden = YES;
    self.messageHasReadStatusView.hidden = YES;
    if (model.messageDirection == MessageDirection_RECEIVE) {
        self.statusContentView.hidden = YES;
        return;
    } else {
        self.statusContentView.hidden = NO;
    }
    __weak typeof(&*self) __blockSelf = self;

    dispatch_async(dispatch_get_main_queue(), ^{

      if (__blockSelf.model.sentStatus == SentStatus_SENDING) {
          __blockSelf.messageFailedStatusView.hidden = YES;
          __blockSelf.messageHasReadStatusView.hidden = YES;
          __blockSelf.messageSendSuccessStatusView.hidden = YES;
          if (__blockSelf.messageActivityIndicatorView) {
              __blockSelf.messageActivityIndicatorView.hidden = NO;
              if (__blockSelf.messageActivityIndicatorView.isAnimating == NO) {
                  [__blockSelf.messageActivityIndicatorView startAnimating];
              }
          }

      } else if (__blockSelf.model.sentStatus == SentStatus_FAILED) {
          __blockSelf.messageFailedStatusView.hidden = NO;
          __blockSelf.messageHasReadStatusView.hidden = YES;
          __blockSelf.messageSendSuccessStatusView.hidden = YES;
          if (__blockSelf.messageActivityIndicatorView) {
              __blockSelf.messageActivityIndicatorView.hidden = YES;
              if (__blockSelf.messageActivityIndicatorView.isAnimating == YES) {
                  [__blockSelf.messageActivityIndicatorView stopAnimating];
              }
          }
      } else if (__blockSelf.model.sentStatus == SentStatus_SENT) {
          __blockSelf.messageFailedStatusView.hidden = YES;
          if (__blockSelf.messageActivityIndicatorView) {
              __blockSelf.messageActivityIndicatorView.hidden = YES;
              if (__blockSelf.messageActivityIndicatorView.isAnimating == YES) {
                  [__blockSelf.messageActivityIndicatorView stopAnimating];
              }
          }
          if([RCIM sharedRCIM].enableReadReceipt && self.isDisplayReadStatus)
          {
              __blockSelf.messageSendSuccessStatusView.hidden = NO;
          }
      }//更新成已读状态
      else if (__blockSelf.model.sentStatus == SentStatus_READ && self.isDisplayReadStatus) {
          __blockSelf.messageHasReadStatusView.hidden = NO;
          __blockSelf.statusContentView.frame = CGRectMake(self.messageContentView.frame.origin.x - 25 , self.messageContentView.frame.size.height-3  , 10, 10);
          
          __blockSelf.messageFailedStatusView.hidden = YES;
          __blockSelf.messageSendSuccessStatusView.hidden = YES;
          if (__blockSelf.messageActivityIndicatorView) {
              __blockSelf.messageActivityIndicatorView.hidden = YES;
              if (__blockSelf.messageActivityIndicatorView.isAnimating == YES) {
                  [__blockSelf.messageActivityIndicatorView stopAnimating];
              }
          }

      }
    });
}

#pragma mark private
- (void)tapUserPortaitEvent:(UIGestureRecognizer *)gestureRecognizer {
    __weak typeof(&*self) weakSelf = self;
    if ([self.delegate respondsToSelector:@selector(didTapCellPortrait:)]) {
        [self.delegate didTapCellPortrait:weakSelf.model.senderUserId];
    }
}

- (void)longPressUserPortaitEvent:(UIGestureRecognizer *)gestureRecognizer {
    __weak typeof(&*self) weakSelf = self;
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if ([self.delegate respondsToSelector:@selector(didLongPressCellPortrait:)]) {
            [self.delegate didLongPressCellPortrait:weakSelf.model.senderUserId];
        }
    }
}
//-(void)tapBubbleBackgroundViewEvent:(UIGestureRecognizer *)gestureRecognizer
//{
//    if ([self.delegate respondsToSelector:@selector(didTapMessageCell:)]) {
//        [self.delegate didTapMessageCell:self.model];
//    }
//}

// resend event
//- (void)msgStatusViewTapEventHandler:(id)sender
//{
//    //DebugLog(@"%s", __FUNCTION__);
//
//    //resend the failed message.
//    if ([self.delegate respondsToSelector:@selector(didTapMsgStatusViewForResending:)]) {
//        [self.delegate didTapMsgStatusViewForResending:self.model];
//    }
//
//}
- (void)imageMessageSendProgressing:(NSInteger)progress {
}
- (void)messageCellUpdateSendingStatusEvent:(NSNotification *)notification {

    RCMessageCellNotificationModel *notifyModel = notification.object;

    if (self.model.messageId == notifyModel.messageId) {
        DebugLog(@"messageCellUpdateSendingStatusEvent >%@ ", notifyModel.actionName);
        if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_BEGIN]) {
            self.model.sentStatus = SentStatus_SENDING;
            [self updateStatusContentView:self.model];

        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_FAILED]) {
            self.model.sentStatus = SentStatus_FAILED;
            [self updateStatusContentView:self.model];
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_SUCCESS]) {
            if (self.model.sentStatus != SentStatus_READ) {
                self.model.sentStatus = SentStatus_SENT;
                [self updateStatusContentView:self.model];
            }
        } else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_PROGRESS]) {
            [self imageMessageSendProgressing:notifyModel.progress];
        }
        else if ([notifyModel.actionName isEqualToString:CONVERSATION_CELL_STATUS_SEND_HASREAD] && [RCIM sharedRCIM].enableReadReceipt) {
            self.model.sentStatus = SentStatus_READ;
            [self updateStatusContentView:self.model];
        }

    }
}
//- (void) showSendingMessageActivityIndicator
//{
//    //self.msgStatusView.hidden = NO;
//    //[self.msgStatusView setImage:nil forState:UIControlStateNormal];
//    //[self.msgStatusView addSubview:self.messageActivityIndicatorView];
//    //[self.messageActivityIndicatorView startAnimating];
//}
//- (void) hideSendingMessageActivityIndicator
//{
////    if (self.messageActivityIndicatorView.isAnimating) {
////        [self.messageActivityIndicatorView stopAnimating];
////        [self.messageActivityIndicatorView removeFromSuperview];
////    }
//}

- (void)userInfoDidLoad:(NSNotification *)notification {
    __weak typeof(&*self) __blockSelf = self;

    RCUserInfo *userInfo = notification.object;

    if (userInfo && [userInfo.userId isEqualToString:self.model.senderUserId]) {
        self.model.userInfo = userInfo;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (userInfo.portraitUri.length) {
                [__blockSelf.portraitImageView setImageURL:[NSURL URLWithString:userInfo.portraitUri]];
            }
          [__blockSelf.nicknameLabel setText:userInfo.name];
        });
    }
}

- (void)userInfoFailToLoad:(NSNotification *)notification {
    // DebugLog(@"[RongIMKit]: %s", __FUNCTION__);
    __weak typeof(&*self) __blockSelf = self;

    RCUserInfo *userInfo = notification.object;

    if (userInfo) {
        self.model.userInfo = userInfo;
        dispatch_async(dispatch_get_main_queue(), ^{
          [__blockSelf.portraitImageView setImageURL:[NSURL URLWithString:userInfo.portraitUri]];
          [__blockSelf.nicknameLabel setText:userInfo.name];
        });
    }
}



- (void)groupUserInfoDidLoad:(NSNotification *)notification {
    RCUserInfo *userInfo = notification.object;
    
    if (userInfo.name) {
        NSDictionary *groupIdDict = notification.userInfo;
        if (self.model.conversationType ==  ConversationType_GROUP && [groupIdDict[@"groupId"] isEqualToString:self.model.targetId]) {
            [self userInfoDidLoad:notification];
        }
    } else {
        
    }
}
- (void)groupUserInfoFailToLoad:(NSNotification *)notification {
    
}

- (void)didclickMsgFailedView:(UIButton *)button {
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(didTapmessageFailedStatusViewForResend:)]) {
            [self.delegate didTapmessageFailedStatusViewForResend:self.model];
        }
    }
}

@end
