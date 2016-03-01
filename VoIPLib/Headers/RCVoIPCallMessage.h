
#import <RongIMLib/RongIMLib.h>

UIKIT_EXTERN NSString *const RCVoIPCallMessageTypeIdentifier;

@interface RCVoIPCallMessage : RCMessageContent
@property (nonatomic, copy) NSString* sessionId;
@property (nonatomic, copy) NSString* ip;
@property (nonatomic, assign) int port;
@property (nonatomic, assign) int controlPort;
@property (nonatomic, copy) NSString* toId;
@property (nonatomic, copy) NSString* toUserName;
@property (nonatomic, copy) NSString* fromId;
@property (nonatomic, copy) NSString* fromUserName;

+(instancetype)messageWithProperties:(NSDictionary *)dict;
@end
