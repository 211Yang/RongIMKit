//
//  RCMessageBaseCell.m
//  RongIMKit
//
//  Created by xugang on 15/1/28.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCMessageBaseCell.h"
#import "RCTipLabel.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"

NSString *const KNotificationMessageBaseCellUpdateSendingStatus = @"KNotificationMessageBaseCellUpdateSendingStatus";

@interface RCMessageBaseCell ()

- (void)setBaseAutoLayout;

@end

@implementation RCMessageBaseCell

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupMessageBaseCellView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupMessageBaseCellView];
    }
    return self;
}

-(void)setupMessageBaseCellView{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(messageCellUpdateSendingStatusEvent:)
                                                 name:KNotificationMessageBaseCellUpdateSendingStatus
                                               object:nil];
    self.model = nil;
    self.baseContentView = [[UIView alloc] initWithFrame:CGRectZero];
    _isDisplayReadStatus = NO;
    [self.contentView addSubview:_baseContentView];
}

- (void)setDataModel:(RCMessageModel *)model {
    self.model = model;
    self.messageDirection = model.messageDirection;
    _isDisplayMessageTime = model.isDisplayMessageTime;
    if (self.isDisplayMessageTime) {
        [self.messageTimeLabel setText:[RCKitUtility ConvertChatMessageTime:model.sentTime / 1000] dataDetectorEnabled:NO];
        if (IOS_FSystenVersion < 7.0) {
            [self.messageTimeLabel setFont:[UIFont systemFontOfSize:10.0f]];
        }
    }

    [self setBaseAutoLayout];
}
- (void)setBaseAutoLayout {
    if (self.isDisplayMessageTime) {
        //计算time宽度
        //    CGSize timeTextSize_ =
        //        [self.messageTimeLabel.text boundingRectWithSize:CGSizeMake(self.bounds.size.width, TIME_LABEL_HEIGHT)
        //                                             options:NSStringDrawingUsesLineFragmentOrigin
        //                                          attributes:@{
        //                                              NSFontAttributeName : [UIFont systemFontOfSize:12.5f]
        //                                          } context:nil]
        //            .size;
        
        //    CGSize timeTextSize_ = RC_MULTILINE_TEXTSIZE(self.messageTimeLabel.text, [UIFont systemFontOfSize:12.5f], CGSizeMake(self.bounds.size.width, TIME_LABEL_HEIGHT), NSLineBreakByTruncatingTail);
        CGSize timeTextSize_ = CGSizeZero;
        if (IOS_FSystenVersion < 7.0) {
            timeTextSize_ = RC_MULTILINE_TEXTSIZE_LIOS7(self.messageTimeLabel.text, [UIFont systemFontOfSize:12.5f], CGSizeMake(self.bounds.size.width, TIME_LABEL_HEIGHT), NSLineBreakByTruncatingTail);
        }else {
            timeTextSize_ = RC_MULTILINE_TEXTSIZE_GEIOS7(self.messageTimeLabel.text, [UIFont systemFontOfSize:12.5f], CGSizeMake(self.bounds.size.width, TIME_LABEL_HEIGHT));
        }
        timeTextSize_ = CGSizeMake(ceilf(timeTextSize_.width + 10), ceilf(timeTextSize_.height));
        
        self.messageTimeLabel.hidden = NO;
        [self.messageTimeLabel setFrame:CGRectMake((self.bounds.size.width - timeTextSize_.width) / 2, 10, timeTextSize_.width, TIME_LABEL_HEIGHT)];
        [_baseContentView setFrame:CGRectMake(0, 10 + TIME_LABEL_HEIGHT, self.bounds.size.width,
                                              self.bounds.size.height - (10 + TIME_LABEL_HEIGHT))];
    } else {
        if (_messageTimeLabel) {
            self.messageTimeLabel.hidden = YES;
        }
        [_baseContentView setFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height - (0))];
    }
}

- (void)messageCellUpdateSendingStatusEvent:(NSNotification *)notification {
    DebugLog(@"%s", __FUNCTION__);
}

//大量cell不显示时间，使用延时加载
- (RCTipLabel *)messageTimeLabel {
    if (!_messageTimeLabel) {
        _messageTimeLabel = [RCTipLabel greyTipLabel];
        [self.contentView addSubview:_messageTimeLabel];
    }
    return _messageTimeLabel;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
