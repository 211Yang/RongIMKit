//
//  RCConversationTableCell.m
//  RongIMKit
//
//  Created by xugang on 15/1/24.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCConversationCell.h"
#import "RCKitCommonDefine.h"
#import "RCUserInfoLoader.h"
#import "RCGroupLoader.h"
#import "RCKitUtility.h"
#import <RongIMLib/RongIMLib.h>
#import "RCloudImageView.h"
#import "RCIM.h"
@interface RCConversationCell () <RCUserInfoLoaderObserver,
RCGroupLoaderObserver>
{
    UIView * rightContentView;
}
/*!
 暂时只显示【草稿】，可扩展显示其他标签
 */
@property(strong, nonatomic) UILabel *messageTypeLabel;

@property(nonatomic, strong) NSDictionary *cellSubViews;

- (void)layoutCellView;
- (void)setAutoLayout;
@end

@implementation RCConversationCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.enableNotification = YES;
        [self layoutCellView];
    }
    
    return self;
}

- (void)layoutCellView {
    self.headerImageViewBackgroundView = [[UIView alloc] init];
    self.headerImageViewBackgroundView.backgroundColor = [UIColor clearColor];
    
    self.headerImageView = [[RCloudImageView alloc]
                            initWithFrame:CGRectMake(0, 0, [RCIM sharedRCIM]
                                                     .globalConversationPortraitSize.width,
                                                     [RCIM sharedRCIM]
                                                     .globalConversationPortraitSize.height)];
    self.headerImageView.layer.cornerRadius = 4;
    self.headerImageView.layer.masksToBounds = YES;
    self.headerImageView.image = IMAGE_BY_NAMED(@"default_portrait");
    self.headerImageView.placeholderImage = IMAGE_BY_NAMED(@"default_portrait");
    self.headerImageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *portraitTap = [[UITapGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(tapUserPortaitEvent:)];
    
    [self.headerImageView addGestureRecognizer:portraitTap];
    UILongPressGestureRecognizer *portraitLongPress =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressUserPortaitEvent:)];
    [self.headerImageView addGestureRecognizer:portraitLongPress];
    [self setHeaderImagePortraitStyle:[RCIM sharedRCIM]
     .globalConversationAvatarStyle];
    [self.headerImageViewBackgroundView addSubview:self.headerImageView];
    
    self.conversationTitle = [[UILabel alloc] init];
    self.conversationTitle.backgroundColor = [UIColor clearColor];
    self.conversationTitle.font =
    [UIFont boldSystemFontOfSize:16]; //[UIFont fontWithName:@"Heiti SC-Bold"
    // size:16];
    self.conversationTitle.textColor = HEXCOLOR(0x252525);
 
    self.messageContentLabel = [[UILabel alloc] init];
    self.messageContentLabel.backgroundColor = [UIColor clearColor];
    self.messageContentLabel.font = [UIFont systemFontOfSize:14];
    self.messageContentLabel.textColor = HEXCOLOR(0x8c8c8c);
    self.messageTypeLabel = [[UILabel alloc] init];
    self.messageTypeLabel.backgroundColor = [UIColor clearColor];
    self.messageTypeLabel.font = [UIFont systemFontOfSize:14];
    self.messageTypeLabel.textColor = HEXCOLOR(0x8c8c8c);
    
    self.messageCreatedTimeLabel = [[UILabel alloc] init];
    self.messageCreatedTimeLabel.backgroundColor = [UIColor clearColor];
    self.messageCreatedTimeLabel.font = [UIFont systemFontOfSize:14];
    self.messageCreatedTimeLabel.textColor = [UIColor lightGrayColor];
    self.messageCreatedTimeLabel.textAlignment = NSTextAlignmentRight;
    
    self.conversationStatusImageView = [[UIImageView alloc] initWithFrame:CGRectMake(38, 3, 14, 14)];
    self.conversationStatusImageView.backgroundColor = [UIColor clearColor];
    self.conversationStatusImageView.image =IMAGE_BY_NAMED(@"block_notification");
    self.lastSendMessageStatusView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    self.lastSendMessageStatusView.backgroundColor = [UIColor clearColor];
    self.bubbleTipView = nil;
    
    self.headerImageViewBackgroundView.translatesAutoresizingMaskIntoConstraints =NO;
    self.conversationTitle.translatesAutoresizingMaskIntoConstraints = NO;
    self.messageContentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.messageCreatedTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.messageTypeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    rightContentView = [[UIView alloc]init];
    rightContentView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.contentView addSubview:self.headerImageViewBackgroundView];
    [self.contentView addSubview:self.conversationTitle];
    [self.contentView addSubview:self.messageCreatedTimeLabel];
    [rightContentView addSubview:self.conversationStatusImageView];
    [rightContentView addSubview:self.lastSendMessageStatusView];
    [self.contentView addSubview:rightContentView];
    [self.contentView addSubview:self.messageTypeLabel];
    [self.contentView addSubview:self.messageContentLabel];
    self.cellSubViews = NSDictionaryOfVariableBindings(
                                                       _headerImageViewBackgroundView, _conversationTitle,_messageCreatedTimeLabel, _conversationStatusImageView,_lastSendMessageStatusView,rightContentView,_messageContentLabel,_messageTypeLabel);
    
    [self setAutoLayout];
}
- (void)tapUserPortaitEvent:(UIGestureRecognizer *)gestureRecognizer {
    __weak typeof(&*self) weakSelf = self;
    if ([self.delegate respondsToSelector:@selector(didTapCellPortrait:)]) {
        [self.delegate didTapCellPortrait:weakSelf.model];
    }
}

- (void)longPressUserPortaitEvent:(UIGestureRecognizer *)gestureRecognizer {
    __weak typeof(&*self) weakSelf = self;
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if ([self.delegate respondsToSelector:@selector(didLongPressCellPortrait:)]) {
            [self.delegate didLongPressCellPortrait:weakSelf.model];
        }
    }
}
- (void)setAutoLayout {
    [self.contentView
     addConstraints:
     [NSLayoutConstraint
      constraintsWithVisualFormat:
      @"H:|-13-[_headerImageViewBackgroundView(width)]-8-[_"
      @"conversationTitle]-5-[_messageCreatedTimeLabel(==80)]-9-"
      @"|" options:0 metrics:@{
                               @"width" :
                                   @([RCIM sharedRCIM].globalConversationPortraitSize.width)
                               } views:self.cellSubViews]];
    [self.contentView
     addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:
      @"V:|-10-[_headerImageViewBackgroundView]-10-"
      @"|" options:0 metrics:@{
                               @"height" :
                                   @([RCIM sharedRCIM].globalConversationPortraitSize.height)
                               } views:self.cellSubViews]];
    
    [self.contentView
     addConstraints:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"V:|-11-[_conversationTitle]-0-"
      @"[_messageContentLabel]-10-|"
      options:0
      metrics:nil
      views:self.cellSubViews]];
    [self.contentView
     addConstraints:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"H:|-13-[_headerImageViewBackgroundView(width)]-8-"
      @"[_messageTypeLabel]-0-[_messageContentLabel]-58-|"
      options:0
      metrics:@{
                @"width" :
                    @([RCIM sharedRCIM].globalConversationPortraitSize.width)
                }
      views:self.cellSubViews]];
    
    [self.contentView
     addConstraint:[NSLayoutConstraint constraintWithItem:_messageTypeLabel
                                                attribute:NSLayoutAttributeLeft
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem:_conversationTitle
                                                attribute:NSLayoutAttributeLeft
                                               multiplier:1
                                                 constant:0]];
    
    [self.contentView
     addConstraints:[NSLayoutConstraint
                     constraintsWithVisualFormat:
                     @"V:|-11-[_messageCreatedTimeLabel(30)]"
                     options:0
                     metrics:nil
                     views:self.cellSubViews]];

    [self.contentView
     addConstraints:[NSLayoutConstraint
                     constraintsWithVisualFormat:
                     @"H:[rightContentView(55)]-5-|"
                     options:0
                     metrics:nil
                     views:self.cellSubViews]];
    [self.contentView
     addConstraint:[NSLayoutConstraint
                    constraintWithItem:rightContentView
                    attribute:NSLayoutAttributeBottom
                    relatedBy:NSLayoutRelationEqual
                    toItem:self.contentView
                    attribute:NSLayoutAttributeBottom
                    multiplier:1
                    constant:-30]];
    [self.contentView
     addConstraints:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"V:|-11-[_conversationTitle]-0-[_messageTypeLabel]-10-|"
      options:0
      metrics:nil
      views:NSDictionaryOfVariableBindings(_messageTypeLabel,_messageContentLabel,_conversationTitle)]];
    [self.contentView
     addConstraints:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"V:|-11-[_conversationTitle]-0-[_messageContentLabel]-10-|"
      options:0
      metrics:nil
      views:NSDictionaryOfVariableBindings(_messageTypeLabel,_messageContentLabel,_conversationTitle)]];
    
}

- (void)setHeaderImagePortraitStyle:(RCUserAvatarStyle)portraitStyle {
    _portraitStyle = portraitStyle;
    if (_portraitStyle == RC_USER_AVATAR_RECTANGLE) {
        self.headerImageView.layer.cornerRadius = [[RCIM sharedRCIM] portraitImageViewCornerRadius];
    } else if (_portraitStyle == RC_USER_AVATAR_CYCLE) {
        self.headerImageView.layer.cornerRadius =
        [[RCIM sharedRCIM] globalConversationPortraitSize].height / 2;
    }
}

- (void)setIsShowNotificationNumber:(BOOL)isShowNotificationNumber
{
    if (_isShowNotificationNumber != isShowNotificationNumber)
    {
        _isShowNotificationNumber = isShowNotificationNumber;
    }
    self.bubbleTipView.isShowNotificationNumber = isShowNotificationNumber;
}

- (void)clearPreCellInfo {
    self.conversationTitle.text = nil;
    [self.headerImageView
     setPlaceholderImage:IMAGE_BY_NAMED(@"default_portrait")];
    self.messageCreatedTimeLabel.text = nil;
    self.messageContentLabel.text = nil;
    self.messageTypeLabel.text = nil;
    self.lastSendMessageStatusView.image = nil;
    
}

- (void)setDiscussionData:(RCDiscussion *)discussion
                    model:(RCConversationModel *)model {
    __weak typeof(&*self) __bloackself = self;
    if (discussion) {
        [__bloackself.conversationTitle setText:discussion.discussionName];
        __bloackself.model.conversationTitle = [_conversationTitle.text copy];
    }
    // if exsit draft
    if (__bloackself.model.draft && __bloackself.model.draft.length > 0) {
        [__bloackself.messageTypeLabel
         setText:NSLocalizedStringFromTable(@"Draft", @"RongCloudKit", nil)];
        [__bloackself.messageContentLabel setText:__bloackself.model.draft];
    } else {
        RCUserInfo *userInfo =
        [[RCUserInfoLoader sharedUserInfoLoader] loadUserInfo:model.senderUserId
                                                     observer:self];
        
        /**
         *  show the cache value if userInfo is NOT nil, or load them
         * from datasource
         */
        if (userInfo && model.lastestMessageId > 0 ) {
            [self.messageContentLabel
             setText:[NSString
                      stringWithFormat:
                      @"%@:%@", userInfo.name,
                      [self formatMessage:model.lastestMessage withMessageId:model.lastestMessageId]]];
        } else {
            [self.messageContentLabel
             setText:[self formatMessage:model.lastestMessage withMessageId:model.lastestMessageId]];
        }
    }
    self.messageCreatedTimeLabel.text =
    [RCKitUtility ConvertMessageTime:__bloackself.model.sentTime / 1000];
}

- (void)setDataModel:(RCConversationModel *)model {
    
    [self clearPreCellInfo];
    self.model = model;
    
    if (self.enableNotification) {
        // notify, hidden
        self.conversationStatusImageView.hidden = YES;
        CGRect vRect = self.lastSendMessageStatusView.frame;
        vRect.origin.x= 41;
        vRect.origin.y= 7;
        [self.lastSendMessageStatusView setFrame:vRect];
    } else {
        CGRect vRect = self.lastSendMessageStatusView.frame;
        vRect.origin.x= 25;
        vRect.origin.y= 7;
        [self.lastSendMessageStatusView setFrame:vRect];
        self.conversationStatusImageView.hidden = NO;
    }
    
    if (self.model.isTop) {
        [self.contentView
         setBackgroundColor:self.topCellBackgroundColor];
    } else {
        [self.contentView setBackgroundColor:self.cellBackgroundColor];
    }
    //修改草稿颜色
    if (model.draft && [model.draft length]) {
        [self.messageTypeLabel setTextColor:[UIColor colorWithRed:204 / 255.f
                                                               green:33 / 255.f
                                                                blue:33 / 255.f
                                                               alpha:1]];
    } else {
        self.messageTypeLabel.textColor = HEXCOLOR(0x8c8c8c);
    }
    if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_NORMAL) {
        //个人聊天，或者系统，客服
        if (model.conversationType == ConversationType_SYSTEM ||
            model.conversationType == ConversationType_PRIVATE ||
            model.conversationType == ConversationType_CUSTOMERSERVICE) {
            
            [self.headerImageView
             setPlaceholderImage:IMAGE_BY_NAMED(@"default_portrait_msg")];
            [[RCUserInfoLoader sharedUserInfoLoader] removeObserver:self];
            RCUserInfo *userInfo =
            [[RCUserInfoLoader sharedUserInfoLoader] loadUserInfo:model.targetId
                                                         observer:self];
            /**
             *  show the cache value if userInfo is NOT nil, or load them from
             * datasource
             */
            if (userInfo) {
                [self.headerImageView
                 setImageURL:[NSURL URLWithString:userInfo.portraitUri]];
                [self.conversationTitle setText:userInfo.name];
                self.model.conversationTitle = [_conversationTitle.text copy];
            }
            
            if (model.draft && model.draft.length > 0) {
                //[self.messageContentLabel setText:model.draft];
                [self.messageTypeLabel
                 setText:NSLocalizedStringFromTable(@"Draft", @"RongCloudKit", nil)];
                [self.messageContentLabel setText:model.draft];
                
            } else {
                [self.messageContentLabel
                 setText:[self formatMessage:model.lastestMessage withMessageId:model.lastestMessageId]];
            }
            self.messageCreatedTimeLabel.text =
            [RCKitUtility ConvertMessageTime:model.sentTime / 1000];
            if (!model.draft || [model.draft length]<1) {
                if ([RCIM sharedRCIM].enableReadReceipt && model.lastestMessage && [model.senderUserId isEqualToString:[RCIMClient sharedRCIMClient].currentUserInfo.userId]) {
                    if (model.sentStatus == SentStatus_READ) {
                        [self.lastSendMessageStatusView setImage:IMAGE_BY_NAMED(@"message_read_status")];
                    }else
                    {
                        //                [self.lastSendMessageStatusView setText:NSLocalizedStringFromTable(@"MessageHasSend", @"RongCloudKit",nil)];
                    }
                    
                }
            }
            
        }
        //群组
        else if (model.conversationType == ConversationType_GROUP) {
            [self.headerImageView
             setPlaceholderImage:IMAGE_BY_NAMED(@"default_group_portrait")];
            [[RCGroupLoader shareInstance] removeObserver:self];
            RCGroup *groupInfo =
            [[RCGroupLoader shareInstance] loadGroupByGroupId:model.targetId
                                                     observer:self];
            
            /**
             *  show the cache value if groupInfo is NOT nil, or load them from
             * datasource
             */
            
            if (model.draft && model.draft.length > 0) {
                [self.messageTypeLabel
                 setText:NSLocalizedStringFromTable(@"Draft", @"RongCloudKit", nil)];
                [self.messageContentLabel setText:model.draft];
            } else {
                RCUserInfo *userInfo = [[RCUserInfoLoader sharedUserInfoLoader] loadGroupUserInfo:model.senderUserId groupId:model.targetId observer:self];
                if (!userInfo.name.length) {
                    userInfo = [[RCUserInfoLoader sharedUserInfoLoader] loadUserInfo:model.senderUserId observer:self];
                }
                
                
                /**
                 *  show the cache value if userInfo is NOT nil, or load them from
                 * datasource
                 */
                
                if(model.lastestMessageId > 0){
                    if (userInfo) {
                        [self.messageContentLabel
                         setText:[NSString stringWithFormat:
                                  @"%@:%@", userInfo.name,
                                  [self formatMessage:model.lastestMessage withMessageId:model.lastestMessageId]]];
                    } else {
                        [self.messageContentLabel
                         setText:[self formatMessage:model.lastestMessage withMessageId:model.lastestMessageId]];
                    }
                }
            }
            if (groupInfo) {
                [self.headerImageView
                 setImageURL:[NSURL URLWithString:groupInfo.portraitUri]];
                [self.conversationTitle setText:groupInfo.groupName];
                self.model.conversationTitle = [_conversationTitle.text copy];
            }
            
            self.messageCreatedTimeLabel.text =
            [RCKitUtility ConvertMessageTime:model.sentTime / 1000];
        }
        // discussion
        else if (model.conversationType == ConversationType_DISCUSSION) {
            __weak typeof(&*self) __bloackself = self;
            
            [__bloackself.headerImageView
             setPlaceholderImage:IMAGE_BY_NAMED(@"default_discussion_portrait")];
            
            [[RCIMClient sharedRCIMClient] getDiscussion:model.targetId
                                                 success:^(RCDiscussion *discussion) {
                                                     NSLog(@"isMainThread > %d", [NSThread isMainThread]);
                                                     if ([NSThread isMainThread]) {
                                                         [self setDiscussionData:discussion model:model];
                                                     } else {
                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                             [self setDiscussionData:discussion model:model];
                                                         });
                                                     }
                                                     
                                                 }
                                                   error:^(RCErrorCode status) {
                                                       DebugLog(@"get discussion %@ fail", model.targetId);
                                                       __weak typeof(&*self) __bloackself = self;
                                                       
                                                       if ([NSThread isMainThread]) {
                                                           [__bloackself.conversationTitle setText:NSLocalizedStringFromTable(
                                                                                                                              @"DISCUSSION", @"RongCloudKit",
                                                                                                                              nil)];
                                                           __bloackself.model.conversationTitle = [_conversationTitle.text copy];
                                                       } else {
                                                           dispatch_async(dispatch_get_main_queue(), ^{
                                                               [__bloackself.conversationTitle setText:NSLocalizedStringFromTable(
                                                                                                                                  @"DISCUSSION", @"RongCloudKit",
                                                                                                                                  nil)];
                                                               __bloackself.model.conversationTitle = [_conversationTitle.text copy];
                                                           });
                                                       }
                                                       
                                                   }];
        }
        
    } else if (model.conversationModelType ==
               RC_CONVERSATION_MODEL_TYPE_COLLECTION) {
        //还需要做图
        if (model.conversationType == ConversationType_PRIVATE) {
            [self.headerImageView
             setPlaceholderImage:IMAGE_BY_NAMED(@"default_portrait")];
            [self.conversationTitle
             setText:NSLocalizedStringFromTable(
                                                @"conversation_private_collection_title", @"RongCloudKit",
                                                nil)];
            self.model.conversationTitle = [_conversationTitle.text copy];
        } else if (model.conversationType == ConversationType_SYSTEM) {
            [self.headerImageView
             setPlaceholderImage:IMAGE_BY_NAMED(@"default_portrait")];
            [self.conversationTitle
             setText:NSLocalizedStringFromTable(
                                                @"conversation_systemMessage_collection_title",
                                                @"RongCloudKit", nil)];
            self.model.conversationTitle = [_conversationTitle.text copy];
        } else if (model.conversationType == ConversationType_CUSTOMERSERVICE) {
            [self.headerImageView
             setPlaceholderImage:IMAGE_BY_NAMED(@"portrait_kefu")];
            [self.conversationTitle
             setText:NSLocalizedStringFromTable(
                                                @"conversation_customer_collection_title",
                                                @"RongCloudKit", nil)];
            self.model.conversationTitle = [_conversationTitle.text copy];
        } else if (model.conversationType == ConversationType_DISCUSSION) {
            [self.headerImageView
             setPlaceholderImage:IMAGE_BY_NAMED(
                                                @"default_discussion_collection_portrait")];
            [self.conversationTitle
             setText:NSLocalizedStringFromTable(
                                                @"conversation_discussion_collection_title",
                                                @"RongCloudKit", nil)];
            self.model.conversationTitle = [_conversationTitle.text copy];
        } else if (model.conversationType == ConversationType_GROUP) {
            [self.headerImageView
             setPlaceholderImage:IMAGE_BY_NAMED(@"default_collection_portrait")];
            [self.conversationTitle
             setText:NSLocalizedStringFromTable(
                                                @"conversation_group_collection_title", @"RongCloudKit",
                                                nil)];
            self.model.conversationTitle = [_conversationTitle.text copy];
        }
        
        // 统一设置
        if (model.draft && model.draft.length > 0) {
            [self.messageTypeLabel
             setText:NSLocalizedStringFromTable(@"Draft", @"RongCloudKit", nil)];
            [self.messageContentLabel setText:model.draft];
        } else {
            if (model.conversationType == ConversationType_GROUP) {
                RCGroup *group =
                [[RCGroupLoader shareInstance] loadGroupByGroupId:model.targetId
                                                         observer:self];
                if (model.lastestMessageId > 0) {
                    if (group) {
                        [self.messageContentLabel
                         setText:[NSString stringWithFormat:
                                  @"%@:%@", group.groupName,
                                  [self
                                   formatMessage:model.lastestMessage withMessageId:model.lastestMessageId]]];
                    } else {
                        [self.messageContentLabel
                         setText:[self formatMessage:model.lastestMessage withMessageId:model.lastestMessageId]];
                    }
                }
                
            } else if (model.conversationType == ConversationType_DISCUSSION) {
                
                if (model.lastestMessageId > 0) {
                    [self.messageContentLabel
                     setText:[self formatMessage:model.lastestMessage withMessageId:model.lastestMessageId]];
                    [[RCIMClient sharedRCIMClient] getDiscussion:model.targetId
                                                         success:^(RCDiscussion *discussion) {
                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                 [self.messageContentLabel
                                                                  setText:[NSString
                                                                           stringWithFormat:
                                                                           @"%@:%@", discussion.discussionName,
                                                                           [self
                                                                            formatMessage:model.lastestMessage withMessageId:model.lastestMessageId]]];
                                                             });
                                                         }
                                                           error:^(RCErrorCode status) {
                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                   [self.messageContentLabel
                                                                    setText:[self formatMessage:model.lastestMessage withMessageId:model.lastestMessageId]];
                                                               });
                                                           }];
                }
                
                
            } else {
                [self.messageContentLabel
                 setText:[self formatMessage:model.lastestMessage withMessageId:model.lastestMessageId]];
            }
        }
        self.messageCreatedTimeLabel.text =
        [RCKitUtility ConvertMessageTime:model.sentTime / 1000];
        
    } else if (model.conversationModelType ==
               RC_CONVERSATION_MODEL_TYPE_CUSTOMIZATION) {
        DebugLog(@"[RongIMKit]: RC_CONVERSATION_MODEL_TYPE_CUSTOMIZATION");
    } else if (model.conversationModelType ==
               RC_CONVERSATION_MODEL_TYPE_PUBLIC_SERVICE) {
        
        [self.headerImageView
         setPlaceholderImage:IMAGE_BY_NAMED(@"default_portrait")];
        ///[[RCUserInfoLoader sharedUserInfoLoader]removeObserver:self ];
        //        RCUserInfo *userInfo = [[RCUserInfoLoader
        //        sharedUserInfoLoader]loadUserInfo:model.targetId
        //        observer:self];
        RCPublicServiceProfile *serviceProfile = [[RCIMClient sharedRCIMClient]
                                                  getPublicServiceProfile:(RCPublicServiceType)model.conversationType
                                                  publicServiceId:model.targetId];
        /**
         *  show the cache value if userInfo is NOT nil, or load them from
         * datasource
         */
        if (serviceProfile) {
            [self.headerImageView
             setImageURL:[NSURL URLWithString:serviceProfile.portraitUrl]];
            [self.conversationTitle setText:serviceProfile.name];
            self.model.conversationTitle = [_conversationTitle.text copy];
        }
        
        if (model.draft && model.draft.length > 0) {
            [self.messageTypeLabel
             setText:NSLocalizedStringFromTable(@"Draft", @"RongCloudKit", nil)];
            [self.messageContentLabel setText:model.draft];
            
        } else {
            [self.messageContentLabel
             setText:[self formatMessage:model.lastestMessage withMessageId:model.lastestMessageId]];
        }
        self.messageCreatedTimeLabel.text =
        [RCKitUtility ConvertMessageTime:model.sentTime / 1000];
    }
    
    if (nil == self.bubbleTipView) {
        self.bubbleTipView = [[RCMessageBubbleTipView alloc]
                              initWithParentView:self.headerImageViewBackgroundView
                              alignment:RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_TOP_RIGHT];
        
    }
    self.bubbleTipView.isShowNotificationNumber = self.isShowNotificationNumber;
    [self.bubbleTipView setBubbleTipNumber:(int)model.unreadMessageCount];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)userInfoDidLoad:(NSNotification *)notification {
    __weak typeof(&*self) __blockSelf = self;
    
    RCUserInfo *userInfo = notification.object;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (userInfo) {
            if (__blockSelf.model.conversationType !=ConversationType_DISCUSSION && __blockSelf.model.conversationType !=ConversationType_GROUP) {
                [__blockSelf.headerImageView
                 setImageURL:[NSURL URLWithString:userInfo.portraitUri]];
                [__blockSelf.conversationTitle setText:userInfo.name];
                __blockSelf.model.conversationTitle = [_conversationTitle.text copy];
            }
        }
        
        if (__blockSelf.model.draft && __blockSelf.model.draft.length > 0) {
            [__blockSelf.messageTypeLabel
             setText:NSLocalizedStringFromTable(@"Draft", @"RongCloudKit", nil)];
            [__blockSelf.messageContentLabel setText:__blockSelf.model.draft];
        } else {
            //r如果当前是群组或者讨论组，更新messageContentLabel为  “name:message”格式
            if (__blockSelf.model.lastestMessageId > 0) {
                if (__blockSelf.model.conversationType == ConversationType_DISCUSSION||__blockSelf.model.conversationType == ConversationType_GROUP) {
                    if (userInfo) {
                        [__blockSelf.messageContentLabel
                         setText:[NSString stringWithFormat:
                                  @"%@:%@", userInfo.name,
                                  [self
                                   formatMessage:__blockSelf.model
                                   .lastestMessage withMessageId:__blockSelf.model.lastestMessageId]]];
                        
                    } else {
                        [__blockSelf.messageContentLabel
                         setText:[self
                                  formatMessage:__blockSelf.model.lastestMessage withMessageId:__blockSelf.model.lastestMessageId]];
                    }
                }
            }
        }
        
        //    self.messageCreatedTimeLabel.text =
        //        [RCKitUtility ConvertMessageTime:__blockSelf.model.sentTime / 1000];
    });
}
- (void)userInfoFailToLoad:(NSNotification *)notification {
    DebugLog(@"[RongIMKit]: %s", __FUNCTION__);
    __weak typeof(&*self) __blockSelf = self;
    
    RCUserInfo *userInfo = notification.object;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (__blockSelf.model.conversationType !=ConversationType_DISCUSSION && __blockSelf.model.conversationType !=ConversationType_GROUP)
        {
            if (userInfo) {
                [__blockSelf.headerImageView setImageURL:[NSURL URLWithString:userInfo.portraitUri]];
                [__blockSelf.conversationTitle setText:userInfo.name];
                __blockSelf.model.conversationTitle = [_conversationTitle.text copy];
            }
        }
        
        if (__blockSelf.model.draft && __blockSelf.model.draft.length > 0) {
            [__blockSelf.messageTypeLabel
             setText:NSLocalizedStringFromTable(@"Draft", @"RongCloudKit", nil)];
            [__blockSelf.messageContentLabel setText:__blockSelf.model.draft];
        } else {
            [self.messageContentLabel
             setText:[self
                      formatMessage:__blockSelf.model.lastestMessage withMessageId:__blockSelf.model.lastestMessageId]];
        }
        
        //    self.messageCreatedTimeLabel.text =
        //        [RCKitUtility ConvertMessageTime:__blockSelf.model.sentTime / 1000];
    });
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
#pragma mark, No cache, fetch group info from database
- (void)groupDidLoad:(NSNotification *)notification {
    __weak typeof(&*self) __blockSelf = self;
    
    RCGroup *groupInfo = notification.object;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (groupInfo) {
            if (__blockSelf.model.conversationModelType !=
                RC_CONVERSATION_MODEL_TYPE_COLLECTION) {
                [__blockSelf.headerImageView
                 setImageURL:[NSURL URLWithString:groupInfo.portraitUri]];
                [__blockSelf.conversationTitle setText:groupInfo.groupName];
                __blockSelf.model.conversationTitle = [_conversationTitle.text copy];
            }
        }
        
        if (__blockSelf.model.draft && __blockSelf.model.draft.length > 0) {
            [__blockSelf.messageTypeLabel
             setText:NSLocalizedStringFromTable(@"Draft", @"RongCloudKit", nil)];
            [__blockSelf.messageContentLabel setText:__blockSelf.model.draft];
        } else {
            if (__blockSelf.model.lastestMessageId > 0) {
                if ((__blockSelf.model.conversationModelType !=
                     RC_CONVERSATION_MODEL_TYPE_COLLECTION )&&__blockSelf.model.conversationType != ConversationType_PRIVATE) {
                    RCUserInfo *userInfo = [[RCUserInfoLoader sharedUserInfoLoader]
                                            loadUserInfo:__blockSelf.model.senderUserId
                                            observer:self];
                    /**
                     *  show the cache value if userInfo is NOT nil, or load them from
                     * datasource
                     */
                    
                    if (userInfo) {
                        [__blockSelf.messageContentLabel
                         setText:[NSString stringWithFormat:
                                  @"%@:%@", userInfo.name,
                                  [self
                                   formatMessage:__blockSelf.model
                                   .lastestMessage withMessageId:__blockSelf.model.lastestMessageId]]];
                    } else {
                        [__blockSelf.messageContentLabel
                         setText:[self
                                  formatMessage:__blockSelf.model.lastestMessage withMessageId:__blockSelf.model.lastestMessageId]];
                    }
                } else {
                    if (groupInfo) {
                        [self.messageContentLabel
                         setText:[NSString stringWithFormat:
                                  @"%@:%@", groupInfo.groupName,
                                  [self
                                   formatMessage:__blockSelf.model
                                   .lastestMessage withMessageId:__blockSelf.model.lastestMessageId]]];
                    } else {
                        [self.messageContentLabel
                         setText:[self
                                  formatMessage:__blockSelf.model.lastestMessage withMessageId:__blockSelf.model.lastestMessageId]];
                    }
                }
            }
            
            //[__blockSelf.messageContentLabel setText:[RCKitUtility
            // formatMessage:__blockSelf.model.lastestMessage]];
        }
        //    __blockSelf.messageCreatedTimeLabel.text =
        //        [RCKitUtility ConvertMessageTime:__blockSelf.model.sentTime / 1000];
    });
}
- (void)groupFailToLoad:(NSNotification *)notification {
    DebugLog(@"[RongIMKit]: %s", __FUNCTION__);
    __weak typeof(&*self) __blockSelf = self;
    
    RCGroup *groupInfo = notification.object;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (groupInfo) {
            [__blockSelf.headerImageView
             setImageURL:[NSURL URLWithString:groupInfo.portraitUri]];
            [__blockSelf.conversationTitle setText:groupInfo.groupName];
            __blockSelf.model.conversationTitle = [_conversationTitle.text copy];
        }
        
        if (__blockSelf.model.draft && __blockSelf.model.draft.length > 0) {
            [__blockSelf.messageTypeLabel
             setText:NSLocalizedStringFromTable(@"Draft", @"RongCloudKit", nil)];
            [__blockSelf.messageContentLabel setText:__blockSelf.model.draft];
        } else {
            [__blockSelf.messageContentLabel
             setText:[self
                      formatMessage:__blockSelf.model.lastestMessage withMessageId:__blockSelf.model.lastestMessageId]];
        }
        //    __blockSelf.messageCreatedTimeLabel.text =
        //        [RCKitUtility ConvertMessageTime:__blockSelf.model.sentTime / 1000];
    });
}

- (NSString *)formatMessage:(RCMessageContent *)messageContent withMessageId:(long)messageId {
    if ([RCIM sharedRCIM].showUnkownMessage && messageId > 0 && !messageContent) {
        return NSLocalizedStringFromTable(@"unknown_message_cell_tip",@"RongCloudKit",nil);
    } else {
        return [RCKitUtility formatMessage:messageContent];
    }
}
@end
