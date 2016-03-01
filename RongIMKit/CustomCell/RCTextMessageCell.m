//
//  RCTextMessageCell.m
//  RongIMKit
//
//  Created by xugang on 15/2/2.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCTextMessageCell.h"
#import "RCKitUtility.h"
#import "RongIMKit.h"
#import "RCKitCommonDefine.h"

@interface RCTextMessageCell ()

- (void)initialize;

@end

@implementation RCTextMessageCell

- (NSDictionary *)attributeDictionary {
    if (self.messageDirection == MessageDirection_SEND) {
        return @{
            @(NSTextCheckingTypeLink) : @{NSForegroundColorAttributeName : [UIColor blueColor]},
            @(NSTextCheckingTypePhoneNumber) : @{NSForegroundColorAttributeName : [UIColor blueColor]}
        };
    } else {
        return @{
            @(NSTextCheckingTypeLink) : @{NSForegroundColorAttributeName : [UIColor blueColor]},
            @(NSTextCheckingTypePhoneNumber) : @{NSForegroundColorAttributeName : [UIColor blueColor]}
        };
    }
    return nil;
}

- (NSDictionary *)highlightedAttributeDictionary {
    return [self attributeDictionary];
}
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
    self.bubbleBackgroundView = [[UIImageView alloc] initWithFrame:CGRectZero];
    [self.messageContentView addSubview:self.bubbleBackgroundView];

    self.textLabel = [[RCAttributedLabel alloc] initWithFrame:CGRectZero];
    self.textLabel.attributeDictionary = [self attributeDictionary];
    self.textLabel.highlightedAttributeDictionary = [self highlightedAttributeDictionary];
    [self.textLabel setFont:[UIFont systemFontOfSize:Text_Message_Font_Size]];

    self.textLabel.numberOfLines = 0;
    [self.textLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [self.textLabel setTextAlignment:NSTextAlignmentLeft];
    [self.textLabel setTextColor:[UIColor blackColor]];
    if (IOS_FSystenVersion < 7.0) {
        [self.textLabel setBackgroundColor:[UIColor clearColor]];
    }
    self.textLabel.delegate=self;
    [self.bubbleBackgroundView addSubview:self.textLabel];
    self.bubbleBackgroundView.userInteractionEnabled = YES;
    UILongPressGestureRecognizer *longPress =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
    [self.bubbleBackgroundView addGestureRecognizer:longPress];


    UITapGestureRecognizer *textMessageTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapTextMessage:)];
    textMessageTap.numberOfTapsRequired = 1;
    textMessageTap.numberOfTouchesRequired = 1;
    [self.textLabel addGestureRecognizer:textMessageTap];
    self.textLabel.userInteractionEnabled = YES;
}
- (void)tapTextMessage:(UIGestureRecognizer *)gestureRecognizer {

    if (self.textLabel.currentTextCheckingType == NSTextCheckingTypeLink) {
        // open url
        NSString *urlString = [self.textLabel.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        // http://
//        if (![urlString hasPrefix:@"http"]){
//            urlString = [@"http://" stringByAppendingString:urlString];
//        }
        
        if ([self.delegate respondsToSelector:@selector(didTapUrlInMessageCell:model:)]) {
            [self.delegate didTapUrlInMessageCell:urlString model:self.model];
            return;
        }
    } else if (self.textLabel.currentTextCheckingType == NSTextCheckingTypePhoneNumber) {
        // call phone number
        NSString *number = [@"tel://" stringByAppendingString:self.textLabel.text];
        if ([self.delegate respondsToSelector:@selector(didTapPhoneNumberInMessageCell:model:)]) {
            [self.delegate didTapPhoneNumberInMessageCell:number model:self.model];
            return;
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(didTapMessageCell:)]) {
        [self.delegate didTapMessageCell:self.model];
    }
}
- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];

    [self setAutoLayout];
}
- (void)setAutoLayout {
    RCTextMessage *_textMessage = (RCTextMessage *)self.model.content;
    if (_textMessage) {
        self.textLabel.text = _textMessage.content;
    } else {
        DebugLog(@"[RongIMKit]: RCMessageModel.content is NOT RCTextMessage object");
    }
    // ios 7
//    CGSize __textSize =
//        [_textMessage.content
//            boundingRectWithSize:CGSizeMake(self.baseContentView.bounds.size.width -
//                                                (10 + [RCIM sharedRCIM].globalMessagePortraitSize.width + 10) * 2 - 5 -
//                                                35,
//                                            8000)
//                         options:NSStringDrawingTruncatesLastVisibleLine |NSStringDrawingUsesLineFragmentOrigin |
//                                 NSStringDrawingUsesFontLeading
//                      attributes:@{
//                          NSFontAttributeName : [UIFont systemFontOfSize:Text_Message_Font_Size]
//                      } context:nil]
//            .size;
    
//    CGSize __textSize = RC_MULTILINE_TEXTSIZE(_textMessage.content, [UIFont systemFontOfSize:Text_Message_Font_Size], CGSizeMake(self.baseContentView.bounds.size.width -
//                                                                                                                                 (10 + [RCIM sharedRCIM].globalMessagePortraitSize.width + 10) * 2 - 5 -
//                                                                                                                                 35,
//                                                                                                                                 8000), NSLineBreakByTruncatingTail);
    CGSize __textSize = CGSizeZero;
    if (IOS_FSystenVersion < 7.0) {
        __textSize = RC_MULTILINE_TEXTSIZE_LIOS7(_textMessage.content, [UIFont systemFontOfSize:Text_Message_Font_Size], CGSizeMake(self.baseContentView.bounds.size.width -
                                                                                                                                    (10 + [RCIM sharedRCIM].globalMessagePortraitSize.width + 10) * 2 - 5 -
                                                                                                                                    35,
                                                                                                                                    8000), NSLineBreakByTruncatingTail);
    }else {
        __textSize = RC_MULTILINE_TEXTSIZE_GEIOS7(_textMessage.content, [UIFont systemFontOfSize:Text_Message_Font_Size], CGSizeMake(self.baseContentView.bounds.size.width -
                                                                                                                                     (10 + [RCIM sharedRCIM].globalMessagePortraitSize.width + 10) * 2 - 5 -
                                                                                                                                     35,
                                                                                                                                     8000));
    }


    __textSize = CGSizeMake(ceilf(__textSize.width), ceilf(__textSize.height));
    float maxWidth=self.baseContentView.bounds.size.width -(10 + [RCIM sharedRCIM].globalMessagePortraitSize.width + 10) * 2 - 5 -35;
    if(__textSize.width>maxWidth)
    {
        __textSize.width=maxWidth;
    }
    CGSize __labelSize = CGSizeMake(__textSize.width + 5, __textSize.height + 5);

    CGFloat __bubbleWidth = __labelSize.width + 12 + 20 < 50 ? 50 : (__labelSize.width + 12 + 20);
    CGFloat __bubbleHeight = __labelSize.height + 5 + 5 < 35 ? 35 : (__labelSize.height + 5 + 5);

    CGSize __bubbleSize = CGSizeMake(__bubbleWidth, __bubbleHeight);

    CGRect messageContentViewRect = self.messageContentView.frame;

    //拉伸图片
    // CGFloat top, CGFloat left, CGFloat bottom, CGFloat right
    if (MessageDirection_RECEIVE == self.messageDirection) {
        messageContentViewRect.size.width = __bubbleSize.width;
        messageContentViewRect.size.height = __bubbleSize.height;
        self.messageContentView.frame = messageContentViewRect;

        self.bubbleBackgroundView.frame = CGRectMake(-8, 0, __bubbleSize.width, __bubbleSize.height);

        self.textLabel.frame = CGRectMake(20, 5, __labelSize.width, __labelSize.height);
        self.bubbleBackgroundView.image = [RCKitUtility imageNamed:@"chat_from_bg_normal" ofBundle:@"RongCloud.bundle"];
        UIImage *image = self.bubbleBackgroundView.image;
        self.bubbleBackgroundView.image = [self.bubbleBackgroundView.image
            resizableImageWithCapInsets:UIEdgeInsetsMake(image.size.height * 0.8, image.size.width * 0.8,
                                                         image.size.height * 0.2, image.size.width * 0.2)];
    } else {
        messageContentViewRect.size.width = __bubbleSize.width+8;
        messageContentViewRect.size.height = __bubbleSize.height;
        messageContentViewRect.origin.x =
            self.baseContentView.bounds.size.width -
            (messageContentViewRect.size.width + 12 + [RCIM sharedRCIM].globalMessagePortraitSize.width + 10)+16;
        self.messageContentView.frame = messageContentViewRect;

        self.bubbleBackgroundView.frame = CGRectMake(0, 0, __bubbleSize.width, __bubbleSize.height);
        self.textLabel.frame = CGRectMake(12, 5, __labelSize.width, __labelSize.height);
        self.bubbleBackgroundView.image = [RCKitUtility imageNamed:@"chat_to_bg_normal" ofBundle:@"RongCloud.bundle"];
        UIImage *image = self.bubbleBackgroundView.image;
        CGRect statusFrame = self.statusContentView.frame;
        statusFrame.origin.x = statusFrame.origin.x +5;
        [self.statusContentView setFrame:statusFrame];
        self.bubbleBackgroundView.image = [self.bubbleBackgroundView.image
            resizableImageWithCapInsets:UIEdgeInsetsMake(image.size.height * 0.8, image.size.width * 0.2,
                                                         image.size.height * 0.2, image.size.width * 0.8)];
    }
    // self.bubbleBackgroundView.image = image;
}

- (void)longPressed:(id)sender {
    UILongPressGestureRecognizer *press = (UILongPressGestureRecognizer *)sender;
    if (press.state == UIGestureRecognizerStateEnded) {
        DebugLog(@"long press end");
        return;
    } else if (press.state == UIGestureRecognizerStateBegan) {
        [self.delegate didLongTouchMessageCell:self.model inView:self.bubbleBackgroundView];
    }
}

- (void)attributedLabel:(RCAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    NSString *urlString=[url absoluteString];
    if (![urlString hasPrefix:@"http"]) {
        urlString = [@"http://" stringByAppendingString:urlString];
    }
    if ([self.delegate respondsToSelector:@selector(didTapUrlInMessageCell:model:)]) {
        [self.delegate didTapUrlInMessageCell:urlString model:self.model];
        return;
    }
}

/**
 Tells the delegate that the user did select a link to an address.
 
 @param label The label whose link was selected.
 @param addressComponents The components of the address for the selected link.
 */
- (void)attributedLabel:(RCAttributedLabel *)label didSelectLinkWithAddress:(NSDictionary *)addressComponents
{
    
}

/**
 Tells the delegate that the user did select a link to a phone number.
 
 @param label The label whose link was selected.
 @param phoneNumber The phone number for the selected link.
 */
- (void)attributedLabel:(RCAttributedLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber
{
    NSString *number = [@"tel://" stringByAppendingString:phoneNumber];
    if ([self.delegate respondsToSelector:@selector(didTapPhoneNumberInMessageCell:model:)]) {
        [self.delegate didTapPhoneNumberInMessageCell:number model:self.model];
        return;
    }
}

-(void)attributedLabel:(RCAttributedLabel *)label didTapLabel:(NSString *)content
{
    if ([self.delegate respondsToSelector:@selector(didTapMessageCell:)]) {
        [self.delegate didTapMessageCell:self.model];
    }
}

@end
