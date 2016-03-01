//
//  RCVoIPCallingViewController.h
//  iOS_VoipLib
//
//  Created by MiaoGuangfa on 3/27/15.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCVoIPBaseViewController.h"

@interface RCVoIPCallingViewController : RCVoIPBaseViewController
- (instancetype) initWithCallId:(NSString *)callId withTargetName:(NSString *) targetName withPortraitUri:(NSString *)portraitUri;

@end
