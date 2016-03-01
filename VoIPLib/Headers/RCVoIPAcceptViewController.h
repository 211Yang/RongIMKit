//
//  RCVoIPAcceptViewController.h
//  iOS_VoipLib
//
//  Created by MiaoGuangfa on 3/30/15.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCVoIPBaseViewController.h"

@interface RCVoIPAcceptViewController : RCVoIPBaseViewController
- (instancetype) initWithTargetId:(NSString *)targetId withSessionId:(NSString *)sessionId withTargetName:(NSString *)targetName withPortraitUri:(NSString *)portraitUri;
@end
