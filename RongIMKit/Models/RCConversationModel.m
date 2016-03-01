//
//  RongConversationModel.m
//  RongIMKit
//
//  Created by xugang on 15/1/22.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCConversationModel.h"

@implementation RCConversationModel

/**
 *  用户使用的初始化方法
 */
- (id)init:(RCConversationModelType)conversationModelType exntend:(NSObject *)extend {
    self = [super init];
    if (self) {
        self.conversationModelType = conversationModelType;
        self.extend = extend;
    }

    return self;
}

/**
 *  SDK本身使用的初始化方法
 */
- (id)init:(RCConversationModelType)conversationModelType
    conversation:(RCConversation *)conversation
          extend:(NSObject *)extend {

    self = [super init];
    if (self) {
        self.extend = extend;
        self.conversationModelType = conversationModelType;
        self.targetId = conversation.targetId;
        self.conversationTitle = conversation.conversationTitle;
        self.unreadMessageCount = conversation.unreadMessageCount;
        self.isTop = conversation.isTop;
        self.sentStatus = conversation.sentStatus;
        self.receivedTime = conversation.receivedTime;
        self.sentTime = conversation.sentTime;
        self.draft = conversation.draft;
        self.objectName = conversation.objectName;
        self.senderUserId = conversation.senderUserId;
        //接口向后兼容 [[++
        _senderUserName = [conversation performSelector:@selector(senderUserName)];
        //接口向后兼容 --]]
        self.lastestMessageId = conversation.lastestMessageId;
        self.lastestMessage = conversation.lastestMessage;
        self.conversationType = conversation.conversationType;
        if (RC_CONVERSATION_MODEL_TYPE_PUBLIC_SERVICE == conversationModelType) {
            // self.conversationTitle = conversation.conversationTitle;
        }
    }

    return self;
}
@end
