
#import <RongIMLib/RongIMLib.h>

typedef NS_ENUM(NSUInteger, FinishState) {
    FINISH_NORMAL = 0,
    FINISH_REFUSE
};

UIKIT_EXTERN NSString *const RCVoIPFinishMessageTypeIdentifier;

@interface RCVoIPFinishMessage : RCMessageContent
@property (nonatomic, copy) NSString* toId;
@property (nonatomic, assign) FinishState finishState;

+(instancetype)messageWithProperties:(NSDictionary *)dict;

@end
