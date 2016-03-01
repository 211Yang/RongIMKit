//
//  RCVoipManager.h
//  iOS-IMKit
//
//  Created by Heq.Shinoda on 14-7-28.
//  Copyright (c) 2014年 Heq.Shinoda. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void (^VoipReceiveDataBlock)(NSData* vData,long length);
typedef void (^VoipErrorBlock)(int errorType, NSString* desc);

@interface RCVoIPManager : NSObject

@property(nonatomic, strong) NSString* currentAppKey;
@property(nonatomic, strong) NSString* connectToken;
@property(nonatomic, strong) NSString* currentUserId;

+(RCVoIPManager*)sharedVoipManager;

/**
 *  接口需要处理响应事件
 */
-(void)startVoipWith:(NSString *)targetId
        dataRecevier:(void (^)(NSData* vData,long length))dataRecevier
         errRecevier:(void (^)(int errorType, NSString* desc))errRecevier;

-(void)acceptVoipWith:(NSString*)targetId
            sessionId:(NSString*)sessionId
             remoteIP:(NSString*)remoteIP
           remotePort:(int)remotePort
    remoteControlPort:(int)remoteControlPort
         dataRecevier:(void (^)(NSData* vData,long length))dataRecevier
          errRecevier:(void (^)(int errorType, NSString* desc))errRecevier;

-(void)endVoipWith:(NSString*)targetId
         sessionId:(NSString*)sessionId
      dataRecevier:(void (^)(NSData* vData,long length))dataRecevier
       errRecevier:(void (^)(int errorType, NSString* desc))errRecevier;

@end
