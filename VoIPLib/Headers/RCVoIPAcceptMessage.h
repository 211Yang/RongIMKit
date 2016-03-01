
#import <RongIMLib/RongIMLib.h>

UIKIT_EXTERN NSString *const RCVoIPAcceptMessageTypeIdentifier;

@interface RCVoIPAcceptMessage : RCMessageContent

@property(nonatomic, copy) NSString* toId;

+(instancetype)messageWithProperties:(NSDictionary *)dict;

@end
