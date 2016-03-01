//
//  RCKitUtility.m
//  iOS-IMKit
//
//  Created by xugang on 7/7/14.
//  Copyright (c) 2014 Heq.Shinoda. All rights reserved.
//

#import "RCKitUtility.h"
#import "RCIM.h"
#import "RCUserInfoLoader.h"
#import "RCUserInfoCache.h"

@interface RCWeakRef : NSObject
@property (nonatomic, weak)id weakRef;
+(instancetype)refWithObject:(id)obj;
@end

@implementation RCWeakRef
+(instancetype)refWithObject:(id)obj {
    RCWeakRef *ref = [[RCWeakRef alloc] init];
    ref.weakRef = obj;
    return ref;
}
@end


@interface RCKitUtility ()

@end

@implementation RCKitUtility

+ (NSString *)localizedDescription:(RCMessageContent *)messageContent {

    NSString *objectName = [[messageContent class] getObjectName];
    return NSLocalizedStringFromTable(objectName, @"RongCloudKit", nil);
}

+ (NSString *)ConvertMessageTime:(long long)secs {
    NSString *timeText = nil;

    NSDate *messageDate = [NSDate dateWithTimeIntervalSince1970:secs];

    //    DebugLog(@"messageDate==>%@",messageDate);
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];

    NSString *strMsgDay = [formatter stringFromDate:messageDate];

    NSDate *now = [NSDate date];
    NSString *strToday = [formatter stringFromDate:now];
    NSDate *yesterday = [[NSDate alloc] initWithTimeIntervalSinceNow:-(24 * 60 * 60)];
    NSString *strYesterday = [formatter stringFromDate:yesterday];

    NSString *_yesterday = nil;
    if ([strMsgDay isEqualToString:strToday]) {
        [formatter setDateFormat:@"HH':'mm"];
    } else if ([strMsgDay isEqualToString:strYesterday]) {
        _yesterday = NSLocalizedStringFromTable(@"Yesterday", @"RongCloudKit", nil);
        //[formatter setDateFormat:@"HH:mm"];
    }

    if (nil != _yesterday) {
        timeText = _yesterday; //[_yesterday stringByAppendingFormat:@" %@", timeText];
    } else {
        timeText = [formatter stringFromDate:messageDate];
    }

    return timeText;
}

+ (NSString *)ConvertChatMessageTime:(long long)secs {
    NSString *timeText = nil;

    NSDate *messageDate = [NSDate dateWithTimeIntervalSince1970:secs];

    //    DebugLog(@"messageDate==>%@",messageDate);
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];

    NSString *strMsgDay = [formatter stringFromDate:messageDate];

    NSDate *now = [NSDate date];
    NSString *strToday = [formatter stringFromDate:now];
    NSDate *yesterday = [[NSDate alloc] initWithTimeIntervalSinceNow:-(24 * 60 * 60)];
    NSString *strYesterday = [formatter stringFromDate:yesterday];

    NSString *_yesterday = nil;
    if ([strMsgDay isEqualToString:strToday]) {
        [formatter setDateFormat:@"HH':'mm"];
    } else if ([strMsgDay isEqualToString:strYesterday]) {
        _yesterday = NSLocalizedStringFromTable(@"Yesterday", @"RongCloudKit", nil);

        [formatter setDateFormat:@"HH:mm"];
    } else {
        [formatter setDateFormat:@"yyyy-MM-dd' 'HH':'mm"];
    }
    
    timeText = [formatter stringFromDate:messageDate];
    
    if (nil != _yesterday) {
        timeText = [_yesterday stringByAppendingFormat:@" %@", timeText];
    }

    return timeText;
}

+ (UIImage *)imageNamed:(NSString *)name ofBundle:(NSString *)bundleName {
    static NSMutableDictionary *loadedObjectDict = nil;
    if (!loadedObjectDict) {
        loadedObjectDict = [[NSMutableDictionary alloc] init];
    }
    
    NSString *keyString = [NSString stringWithFormat:@"%@%@", bundleName, name];
    RCWeakRef *ref = loadedObjectDict[keyString];
    if (ref.weakRef) {
        return ref.weakRef;
    }
    
    UIImage *image = nil;
    NSString *image_name = [NSString stringWithFormat:@"%@.png", name];
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString *bundlePath = [resourcePath stringByAppendingPathComponent:bundleName];
    NSString *image_path = [bundlePath stringByAppendingPathComponent:image_name];

    // NSString* path = [[[[NSBundle mainBundle] resourcePath]
    // stringByAppendingPathComponent:bundleName]stringByAppendingPathComponent:[NSString
    // stringWithFormat:@"%@.png",name]];

    // image = [UIImage imageWithContentsOfFile:image_path];
    image = [[UIImage alloc] initWithContentsOfFile:image_path];
    [loadedObjectDict setObject:[RCWeakRef refWithObject:image] forKey:keyString];
    
    return image;
}

//导航使用
+ (UIImage *)createImageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return theImage;
}

+ (NSString *)formatMessage:(RCMessageContent *)messageContent {

    if ([messageContent respondsToSelector:@selector(conversationDigest)]) {
        return [messageContent performSelector:@selector(conversationDigest)];
    }

    if ([messageContent isMemberOfClass:RCTextMessage.class]) {

        RCTextMessage *textMessage = (RCTextMessage *)messageContent;
        return textMessage.content;

    } else if ([messageContent isMemberOfClass:RCInformationNotificationMessage.class]) {
        RCInformationNotificationMessage *informationNotificationMessage =
            (RCInformationNotificationMessage *)messageContent;

        return informationNotificationMessage.message;

    } else if ([messageContent isMemberOfClass:RCDiscussionNotificationMessage.class]) {

        RCDiscussionNotificationMessage *notification = (RCDiscussionNotificationMessage *)messageContent;

        return [RCKitUtility __formatDiscussionNotificationMessageContent:notification];
    } else if ([messageContent isMemberOfClass:[RCContactNotificationMessage class]]) {
        RCContactNotificationMessage *notification = (RCContactNotificationMessage *)messageContent;
        return [RCKitUtility __formatContactNotificationMessageContent:notification];
    }

    return [RCKitUtility localizedDescription:messageContent];
}

#pragma mark private method
+ (NSString *)__formatContactNotificationMessageContent:(RCContactNotificationMessage *)contactNotification {
    RCUserInfo *userInfo = [[RCUserInfoCache sharedCache]  fetchUserInfo:contactNotification.sourceUserId];
    if (userInfo.name.length) {
        return [NSString stringWithFormat:NSLocalizedStringFromTable(@"FromFriendInvitation",@"RongCloudKit",nil),userInfo.name];
    } else {
        return NSLocalizedStringFromTable(@"AddFriendInvitation",@"RongCloudKit",nil);
    }
    return nil;
}

+ (NSString *)__formatDiscussionNotificationMessageContent:(RCDiscussionNotificationMessage *)discussionNotification {
    if (nil == discussionNotification) {
        DebugLog(@"[RongIMKit] : No userInfo in cache & db");
        return nil;
    }
    NSArray *operatedIds = nil;
    NSString *operationInfo = nil;

    //[RCKitUtility sharedInstance].discussionNotificationOperatorName = userInfo.name;
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

    // NSString *format = nil;
    NSString *message = nil;
    NSString *target = nil;
    if (operatedIds) {
        if (operatedIds.count == 1) {
            RCUserInfo *userInfo = [[RCUserInfoCache sharedCache]  fetchUserInfo:operatedIds[0]];
            if ([userInfo.name length]) {
                target = userInfo.name;
            } else {
                target = [[NSString alloc] initWithFormat:@"user<%@>", operatedIds[0]];
            }
            //target = [[NSString alloc] initWithFormat:@"user<%@>", operatedIds[0]];

        } else {
            NSString *_members = NSLocalizedStringFromTable(@"MemberNumber", @"RongCloudKit", nil);
            target = [NSString stringWithFormat:@"%lu %@", (unsigned long)operatedIds.count, _members, nil];
            // target = [NSString stringWithFormat:NSLocalizedString(@"%d位成员", nil), operatedIds.count, nil];
        }
    }

    NSString *operator;
    RCUserInfo *userInfo =
    [[RCUserInfoCache sharedCache]  fetchUserInfo:discussionNotification.operatorId];
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
            //            format = NSLocalizedString(@"%@邀请%@加入了讨论组", nil);
            //            message = [NSString stringWithFormat:format, operator, target, nil];
    } break;
    case RCQuitDiscussionNotification: {
        NSString *_quitDiscussion = NSLocalizedStringFromTable(@"QuitDiscussion", @"RongCloudKit", nil);

        // format = NSLocalizedString(@"%@退出了讨论组", nil);
            message = [NSString stringWithFormat:@"%@ %@", operator,_quitDiscussion, nil];
    } break;

    case RCRemoveDiscussionMemberNotification: {
        // format = NSLocalizedString(@"%@被%@移出了讨论组", nil);
        NSString *_by = NSLocalizedStringFromTable(@"By", @"RongCloudKit", nil);
        NSString *_removeDiscussion = NSLocalizedStringFromTable(@"RemoveDiscussion", @"RongCloudKit", nil);
            message = [NSString stringWithFormat:@"%@ %@ %@ %@", target,_by, operator,_removeDiscussion,nil];
    } break;
    case RCRenameDiscussionTitleNotification: {
        // format = NSLocalizedString(@"%@修改讨论组为\"%@\"", nil);
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

        // format = NSLocalizedString(@"%@%@了成员邀请", nil);
        message =
            [NSString stringWithFormat:@"%@ %@ %@", operator, target, _inviteStatus, nil];
    }
    default:
        break;
    }
    return message;
}

+ (NSDictionary *)getNotificationUserInfoDictionary:(RCMessage *)message {
    return [RCKitUtility getNotificationUserInfoDictionary:message.conversationType fromUserId:message.senderUserId targetId:message.targetId objectName:message.objectName messageId:message.messageId];
}

+ (NSDictionary *)getNotificationUserInfoDictionary:(RCConversationType)conversationType fromUserId:(NSString *)fromUserId targetId:(NSString *)targetId objectName:(NSString *)objectName {
    
    return [RCKitUtility getNotificationUserInfoDictionary:conversationType fromUserId:fromUserId targetId:targetId objectName:objectName messageId:0];
}

+ (NSDictionary *)getNotificationUserInfoDictionary:(RCConversationType)conversationType fromUserId:(NSString *)fromUserId targetId:(NSString *)targetId objectName:(NSString *)objectName messageId:(long)messageId {
    NSString *type = @"PR";
    switch (conversationType) {
        case ConversationType_PRIVATE:
            type = @"PR";
            break;
        case ConversationType_GROUP:
            type = @"GRP";
            break;
        case ConversationType_DISCUSSION:
            type = @"DS";
            break;
        case ConversationType_CUSTOMERSERVICE:
            type = @"CS";
            break;
        case ConversationType_SYSTEM:
            type = @"SYS";
            break;
        case ConversationType_APPSERVICE:
            type = @"MC";
            break;
        case ConversationType_PUBLICSERVICE:
            type = @"MP";
            break;
        case ConversationType_PUSHSERVICE:
            type = @"PH";
            break;
        default:
            return nil;
    }
    return @{@"rc":@{@"cType":type, @"fId":fromUserId, @"oName":objectName, @"tId":targetId, @"mId":[NSString stringWithFormat:@"%ld" ,messageId]}};
}

+ (NSDictionary *)getNotificationUserInfoDictionary:(RCConversationType)conversationType fromUserId:(NSString *)fromUserId targetId:(NSString *)targetId messageContent:(RCMessageContent *)messageContent {
    NSString *type = @"PR";
    switch (conversationType) {
        case ConversationType_PRIVATE:
            type = @"PR";
            break;
        case ConversationType_GROUP:
            type = @"GRP";
            break;
        case ConversationType_DISCUSSION:
            type = @"DS";
            break;
        case ConversationType_CUSTOMERSERVICE:
            type = @"CS";
            break;
        case ConversationType_SYSTEM:
            type = @"SYS";
            break;
        case ConversationType_APPSERVICE:
            type = @"MC";
            break;
        case ConversationType_PUBLICSERVICE:
            type = @"MP";
            break;
        case ConversationType_PUSHSERVICE:
            type = @"PH";
            break;
        default:
            return nil;
    }
    return @{@"rc":@{@"cType":type, @"fId":fromUserId, @"oName":[[messageContent class] getObjectName], @"tId":targetId}};
}
@end
