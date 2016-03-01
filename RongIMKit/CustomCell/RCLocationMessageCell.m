//
//  RCLocationMessageCell.m
//  RongIMKit
//
//  Created by xugang on 15/2/2.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCLocationMessageCell.h"
#import "RongIMKit.h"
#import "RCKitUtility.h"
@interface RCLocationMessageCell ()

- (void)initialize;

@end

@implementation RCLocationMessageCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.pictureView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.pictureView.contentMode = UIViewContentModeScaleAspectFill;
    self.pictureView.clipsToBounds = YES;
    self.pictureView.layer.cornerRadius = 2.0f;
    self.pictureView.layer.masksToBounds = YES;
    self.pictureView.image = [RCKitUtility imageNamed:@"default_location" ofBundle:@"RongCloud.bundle"];
    
    // self.progressView = [[RCImageMessageProgressView alloc]initWithFrame:CGRectZero];

    self.locationNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.locationNameLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
    self.locationNameLabel.textAlignment = NSTextAlignmentCenter;
    self.locationNameLabel.textColor = [UIColor whiteColor];
    self.locationNameLabel.font = [UIFont systemFontOfSize:12.0f];

    [self.pictureView addSubview:self.locationNameLabel];

    [self.messageContentView addSubview:self.pictureView];
    UILongPressGestureRecognizer *longPress =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
    [self.pictureView addGestureRecognizer:longPress];
    UITapGestureRecognizer *pictureTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPicture:)];
    pictureTap.numberOfTapsRequired = 1;
    pictureTap.numberOfTouchesRequired = 1;
    [self.pictureView addGestureRecognizer:pictureTap];
    self.pictureView.userInteractionEnabled = YES;
}

- (void)tapPicture:(UIGestureRecognizer *)gestureRecognizer {
    if ([self.delegate respondsToSelector:@selector(didTapMessageCell:)]) {
        [self.delegate didTapMessageCell:self.model];
    }
}

#pragma mark override,
- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    RCLocationMessage *_locationMessage = (RCLocationMessage *)model.content;
    if (_locationMessage) {
        self.locationNameLabel.text = _locationMessage.locationName;
        if (_locationMessage.thumbnailImage != nil) {
            self.pictureView.image = _locationMessage.thumbnailImage;
        }
        //写死尺寸 原来400 *230
        CGSize imageSize = CGSizeMake(360 / 2.0f, 207 / 2.0f);
        //图片half
        imageSize = CGSizeMake(imageSize.width, imageSize.height);

        CGRect messageContentViewRect = self.messageContentView.frame;
        if (model.messageDirection == MessageDirection_RECEIVE) {
            messageContentViewRect.size.width = imageSize.width;
            messageContentViewRect.size.height = imageSize.height;
            self.messageContentView.frame = messageContentViewRect;
            self.pictureView.frame = CGRectMake(0, 0, imageSize.width, imageSize.height);
        } else {
            messageContentViewRect.size.width = imageSize.width;
            messageContentViewRect.size.height = imageSize.height;
            messageContentViewRect.origin.x =
                self.baseContentView.bounds.size.width -
                (imageSize.width + 12 + [RCIM sharedRCIM].globalMessagePortraitSize.width + 10);
            self.messageContentView.frame = messageContentViewRect;
            self.pictureView.frame = CGRectMake(0, 0, imageSize.width, imageSize.height);
        }

        self.locationNameLabel.frame = CGRectMake(0, imageSize.height - 20, imageSize.width, 20);

    } else {
        DebugLog(@"[RongIMKit]: RCMessageModel.content is NOT RCLocationMessage object");
    }

    [self setAutoLayout];
}

- (void)setAutoLayout {
}

//#pragma mark override, prepare to send message
//-(void)messageCellUpdateSendingStatusEvent:(NSNotification *)notification
//{
//    DebugLog(@"%s", __FUNCTION__);
//}
// override
- (void)msgStatusViewTapEventHandler:(id)sender {
    //[super msgStatusViewTapEventHandler:sender];

    // to do something.
}

- (void)longPressed:(id)sender {
    UILongPressGestureRecognizer *press = (UILongPressGestureRecognizer *)sender;
    if (press.state == UIGestureRecognizerStateEnded) {
        DebugLog(@"long press end");
        return;
    } else if (press.state == UIGestureRecognizerStateBegan) {
        [self.delegate didLongTouchMessageCell:self.model inView:self.pictureView];
    }
}

@end
