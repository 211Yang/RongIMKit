//
//  RCTipMessageCell.m
//  RongIMKit
//
//  Created by xugang on 15/1/29.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCTipMessageCell.h"
#import "RCTipLabel.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"
#import "RCUserInfoLoader.h"
#import "RCUserInfoCache.h"

@interface RCTipMessageCell ()<RCAttributedLabelDelegate, RCUserInfoLoaderObserver>
@end

@implementation RCTipMessageCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.tipMessageLabel = [RCTipLabel greyTipLabel];
        self.tipMessageLabel.delegate = self;
        self.tipMessageLabel.userInteractionEnabled = YES;
        [self.baseContentView addSubview:self.tipMessageLabel];
        self.tipMessageLabel.marginInsets = UIEdgeInsetsMake(0.5f, 0.5f, 0.5f, 0.5f);
    }
    return self;
}

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];

    RCMessageContent *content = model.content;

    CGFloat maxMessageLabelWidth = self.baseContentView.bounds.size.width - 30 * 2;

    if ([content isMemberOfClass:[RCDiscussionNotificationMessage class]]) {
        RCDiscussionNotificationMessage *notification = (RCDiscussionNotificationMessage *)content;
        NSString *localizedMessage = [self formatDiscussionNotificationMessageContent:notification requireUserInfo:YES];
        self.tipMessageLabel.text = localizedMessage;
    }
    if ([content isMemberOfClass:[RCInformationNotificationMessage class]]) {
        RCInformationNotificationMessage *notification = (RCInformationNotificationMessage *)content;
        NSString *localizedMessage = [RCKitUtility formatMessage:notification];
        self.tipMessageLabel.text = localizedMessage;
    }

    NSString *__text = self.tipMessageLabel.text;
    // ios 7
//    CGSize __textSize =
//        [__text boundingRectWithSize:CGSizeMake(maxMessageLabelWidth, MAXFLOAT)
//                             options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin |
//                                     NSStringDrawingUsesFontLeading
//                          attributes:@{
//                              NSFontAttributeName : [UIFont systemFontOfSize:12.5f]
//                          } context:nil]
//            .size;
    
//    CGSize __textSize = RC_MULTILINE_TEXTSIZE(__text, [UIFont systemFontOfSize:12.5f], CGSizeMake(maxMessageLabelWidth, MAXFLOAT), NSLineBreakByTruncatingTail);
    CGSize __textSize = CGSizeZero;
    if (IOS_FSystenVersion < 7.0) {
        __textSize = RC_MULTILINE_TEXTSIZE_LIOS7(__text, [UIFont systemFontOfSize:12.5f], CGSizeMake(maxMessageLabelWidth, MAXFLOAT), NSLineBreakByTruncatingTail);
    }else {
        __textSize = RC_MULTILINE_TEXTSIZE_GEIOS7(__text, [UIFont systemFontOfSize:12.5f], CGSizeMake(maxMessageLabelWidth, MAXFLOAT));
    }


    __textSize = CGSizeMake(ceilf(__textSize.width), ceilf(__textSize.height));
    CGSize __labelSize = CGSizeMake(__textSize.width + 10, __textSize.height + 6);

    self.tipMessageLabel.frame = CGRectMake((self.baseContentView.bounds.size.width - __labelSize.width) / 2.0f, 10,
                                            __labelSize.width, __labelSize.height);
}



- (void)attributedLabel:(RCAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    NSString *urlString=[url absoluteString];
    if (![urlString hasPrefix:@"http"]) {
        urlString = [@"http://" stringByAppendingString:urlString];
    }
    if ([self.delegate respondsToSelector:@selector(didTapUrlInMessageCell:model:)]) {
        [self.delegate didTapUrlInMessageCell:urlString model:self.model];
        return;
    }
}

/**
 Tells the delegate that the user did select a link to an address.
 
 @param label The label whose link was selected.
 @param addressComponents The components of the address for the selected link.
 */
- (void)attributedLabel:(RCAttributedLabel *)label didSelectLinkWithAddress:(NSDictionary *)addressComponents
{
    
}

/**
 Tells the delegate that the user did select a link to a phone number.
 
 @param label The label whose link was selected.
 @param phoneNumber The phone number for the selected link.
 */
- (void)attributedLabel:(RCAttributedLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber
{
    NSString *number = [@"tel://" stringByAppendingString:phoneNumber];
    if ([self.delegate respondsToSelector:@selector(didTapPhoneNumberInMessageCell:model:)]) {
        [self.delegate didTapPhoneNumberInMessageCell:number model:self.model];
        return;
    }
}

-(void)attributedLabel:(RCAttributedLabel *)label didTapLabel:(NSString *)content
{
    if ([self.delegate respondsToSelector:@selector(didTapMessageCell:)]) {
        [self.delegate didTapMessageCell:self.model];
    }
}

- (NSString *)formatDiscussionNotificationMessageContent:(RCDiscussionNotificationMessage *)discussionNotification requireUserInfo:(BOOL)forceLoad {
    if (nil == discussionNotification) {
        DebugLog(@"[RongIMKit] : No userInfo in cache & db");
        return nil;
    }
    NSArray *operatedIds = nil;
    NSString *operationInfo = nil;
    
    switch (discussionNotification.type) {
        case RCInviteDiscussionNotification:
        case RCRemoveDiscussionMemberNotification: {
            NSString *trimedExtension = [discussionNotification.extension
                                         stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSArray *ids = [trimedExtension componentsSeparatedByString:@","];
            if (!ids || ids.count == 0) {
                ids = [NSArray arrayWithObject:trimedExtension];
            }
            operatedIds = ids;
        } break;
        case RCQuitDiscussionNotification:
            break;
            
        case RCRenameDiscussionTitleNotification:
        case RCSwichInvitationAccessNotification:
            operationInfo = discussionNotification.extension;
            break;
            
        default:
            break;
    }
    
    NSString *message = nil;
    NSString *target = nil;
    if (operatedIds) {
        if (operatedIds.count == 1) {
            RCUserInfo *userInfo = nil;
            if (forceLoad) {
                userInfo = [[RCUserInfoLoader sharedUserInfoLoader] loadUserInfo:operatedIds[0] observer:self];
            } else {
                userInfo = [[RCUserInfoCache sharedCache] fetchUserInfo:operatedIds[0]];
            }
            if ([userInfo.name length]) {
                target = userInfo.name;
            } else {
                target = [[NSString alloc] initWithFormat:@"user<%@>", operatedIds[0]];
            }
        } else {
            NSString *_members = NSLocalizedStringFromTable(@"MemberNumber", @"RongCloudKit", nil);
            target = [NSString stringWithFormat:@"%lu %@", (unsigned long)operatedIds.count, _members, nil];
        }
    }
    
    NSString *operator;
    RCUserInfo *userInfo = nil;
    if (forceLoad) {
        userInfo = [[RCUserInfoLoader sharedUserInfoLoader] loadUserInfo:discussionNotification.operatorId observer:self];
    } else {
        userInfo = [[RCUserInfoCache sharedCache] fetchUserInfo:discussionNotification.operatorId];
    }
    if ([userInfo.name length]) {
        operator= userInfo.name;
    } else {
        operator= [[NSString alloc]
                   initWithFormat:@"user<%@>", discussionNotification.operatorId];
    }
    switch (discussionNotification.type) {
        case RCInviteDiscussionNotification: {
            NSString *_invite = NSLocalizedStringFromTable(@"Invite", @"RongCloudKit", nil);
            NSString *_joinDiscussion = NSLocalizedStringFromTable(@"JoinDiscussion", @"RongCloudKit", nil);
            message = [NSString stringWithFormat:@"%@ %@ %@ %@",operator, _invite,target,_joinDiscussion, nil];
        } break;
        case RCQuitDiscussionNotification: {
            NSString *_quitDiscussion = NSLocalizedStringFromTable(@"QuitDiscussion", @"RongCloudKit", nil);
            message = [NSString stringWithFormat:@"%@ %@", operator,_quitDiscussion, nil];
        } break;
            
        case RCRemoveDiscussionMemberNotification: {
            NSString *_by = NSLocalizedStringFromTable(@"By", @"RongCloudKit", nil);
            NSString *_removeDiscussion = NSLocalizedStringFromTable(@"RemoveDiscussion", @"RongCloudKit", nil);
            message = [NSString stringWithFormat:@"%@ %@ %@ %@", target,_by, operator,_removeDiscussion,nil];
        } break;
        case RCRenameDiscussionTitleNotification: {
            NSString *_modifyDiscussion = NSLocalizedStringFromTable(@"ModifyDiscussion", @"RongCloudKit", nil);
            target = operationInfo;
            message = [NSString stringWithFormat:@"%@ %@\"%@\"", operator,_modifyDiscussion, target, nil];
        } break;
        case RCSwichInvitationAccessNotification: {
            // 1 for off, 0 for on
            BOOL canInvite = [operationInfo isEqualToString:@"1"] ? NO : YES;
            target = canInvite ? NSLocalizedStringFromTable(@"Open", @"RongCloudKit", nil)
            : NSLocalizedStringFromTable(@"Close", @"RongCloudKit", nil);
            
            NSString *_inviteStatus = NSLocalizedStringFromTable(@"InviteStatus", @"RongCloudKit", nil);
            message = [NSString stringWithFormat:@"%@ %@ %@", operator, target, _inviteStatus, nil];
        }
        default:
            break;
    }
    
    return message;
}

- (void)userInfoDidLoad:(NSNotification *)notification {
    RCUserInfo *userInfo = notification.object;
    
    if (userInfo
        && [self.model.content isMemberOfClass:[RCDiscussionNotificationMessage class]]) {
        
        __weak typeof(&*self) blockSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            RCDiscussionNotificationMessage *notificationMessage = (RCDiscussionNotificationMessage *)blockSelf.model.content;
            blockSelf.tipMessageLabel.text = [blockSelf formatDiscussionNotificationMessageContent:notificationMessage requireUserInfo:NO];
            
            CGFloat maxMessageLabelWidth = blockSelf.baseContentView.bounds.size.width - 30 * 2;
            NSString *__text = blockSelf.tipMessageLabel.text;
            CGSize __textSize = CGSizeZero;
            if (IOS_FSystenVersion < 7.0) {
                __textSize = RC_MULTILINE_TEXTSIZE_LIOS7(__text, [UIFont systemFontOfSize:12.5f], CGSizeMake(maxMessageLabelWidth, MAXFLOAT), NSLineBreakByTruncatingTail);
            }else {
                __textSize = RC_MULTILINE_TEXTSIZE_GEIOS7(__text, [UIFont systemFontOfSize:12.5f], CGSizeMake(maxMessageLabelWidth, MAXFLOAT));
            }
            
            __textSize = CGSizeMake(ceilf(__textSize.width), ceilf(__textSize.height));
            CGSize __labelSize = CGSizeMake(__textSize.width + 10, __textSize.height + 6);
            
            blockSelf.tipMessageLabel.frame = CGRectMake((blockSelf.baseContentView.bounds.size.width - __labelSize.width) / 2.0f, 10,
                                                         __labelSize.width, __labelSize.height);
        });
    }
}

@end
