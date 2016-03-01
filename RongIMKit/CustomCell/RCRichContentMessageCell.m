//
//  RCRichContentMessageCell.m
//  RongIMKit
//
//  Created by xugang on 15/2/2.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCRichContentMessageCell.h"
#import "RCAttributedLabel.h"
#import "RCloudImageView.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"

@interface RCRichContentMessageCell ()

- (void)initialize;
- (void)tapBubbleBackgroundViewEvent:(UIGestureRecognizer *)gestureRecognizer;

@end

@implementation RCRichContentMessageCell

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

#define RICH_CONTENT_TITLE_PADDING_TOP 4
#define RICH_CONTENT_TITLE_CONTENT_PADDING 4
#define RICH_CONTENT_PADDING_LEFT 4
#define RICH_CONTENT_PADDING_RIGHT 4
#define RICH_CONTENT_PADDING_BOTTOM 4
#define RICH_CONTENT_THUMBNAIL_CONTENT_PADDING 4

- (void)initialize {
    self.bubbleBackgroundView = [[UIImageView alloc] initWithFrame:CGRectZero];

    UITapGestureRecognizer *bubbleBackgroundViewTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapBubbleBackgroundViewEvent:)];
    UILongPressGestureRecognizer *contentViewLongPress =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
    
    bubbleBackgroundViewTap.numberOfTapsRequired = 1;
    bubbleBackgroundViewTap.numberOfTouchesRequired = 1;

    [self.contentView addGestureRecognizer:bubbleBackgroundViewTap];
    [self.contentView addGestureRecognizer:contentViewLongPress];
    self.contentView.userInteractionEnabled = YES;

    UIImage *bundleImage = [RCKitUtility imageNamed:@"rc_richcontentmsg_placeholder" ofBundle:@"RongCloud.bundle"];

    UIImage *_richContentThunbImage = [bundleImage resizableImageWithCapInsets:UIEdgeInsetsMake(1.f, 1.f, 1.f, 1.f)
                                                                  resizingMode:UIImageResizingModeStretch];

    self.richContentImageView = [[RCloudImageView alloc] initWithPlaceholderImage:_richContentThunbImage];
    self.richContentImageView.layer.cornerRadius = 2.0f;
    self.richContentImageView.layer.masksToBounds = YES;
    self.richContentImageView.contentMode=UIViewContentModeScaleAspectFill;
    self.richContentImageView.frame = CGRectMake(0, 0, RICH_CONTENT_THUMBNAIL_WIDTH, RICH_CONTENT_THUMBNAIL_HIGHT);

    self.titleLabel = [[RCAttributedLabel alloc] init];
    [self.titleLabel setFont:[UIFont boldSystemFontOfSize:RichContent_Title_Font_Size]];
    [self.titleLabel setNumberOfLines:3];

    self.digestLabel = [[RCAttributedLabel alloc] init];
    [self.digestLabel setFont:[UIFont systemFontOfSize:RichContent_Message_Font_Size]];
    [self.digestLabel setNumberOfLines:0];

    self.bubbleBackgroundView.layer.cornerRadius = 4;
    self.bubbleBackgroundView.layer.masksToBounds = YES;
    [self.bubbleBackgroundView addSubview:self.titleLabel];
    [self.bubbleBackgroundView addSubview:self.richContentImageView];
    [self.bubbleBackgroundView addSubview:self.digestLabel];
    [self.messageContentView addSubview:self.bubbleBackgroundView];
    [self.bubbleBackgroundView setBackgroundColor:[UIColor whiteColor]];
}
- (void)tapMessage:(UIGestureRecognizer *)gestureRecognizer {
    if ([self.delegate respondsToSelector:@selector(didTapMessageCell:)]) {
        [self.delegate didTapMessageCell:self.model];
    }
}
#pragma mark - override, configure RichContentMessage Cell
- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    RCRichContentMessage *richContentMsg = (RCRichContentMessage *)model.content;

    self.titleLabel.text = richContentMsg.title;
    self.digestLabel.text = richContentMsg.digest;

    CGSize richContentThumbImageFrame = CGSizeMake(RICH_CONTENT_THUMBNAIL_WIDTH, RICH_CONTENT_THUMBNAIL_HIGHT);
    CGRect messageContentViewRect = self.messageContentView.frame;

//    CGSize _titleLabelSize =
//        [richContentMsg.title
//            boundingRectWithSize:CGSizeMake(self.messageContentView.frame.size.width - RICH_CONTENT_PADDING_LEFT -
//                                                RICH_CONTENT_PADDING_RIGHT,
//                                            MAXFLOAT)
//                         options:(NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin |
//                                  NSStringDrawingUsesFontLeading)
//                      attributes:@{
//                          NSFontAttributeName : [UIFont systemFontOfSize:RichContent_Title_Font_Size]
//                      } context:nil]
//            .size;

//    CGSize _titleLabelSize = RC_MULTILINE_TEXTSIZE(richContentMsg.title, [UIFont systemFontOfSize:RichContent_Title_Font_Size], CGSizeMake(self.messageContentView.frame.size.width - RICH_CONTENT_PADDING_LEFT -
//                                                                                                                                           RICH_CONTENT_PADDING_RIGHT,
//                                                                                                                                           MAXFLOAT), NSLineBreakByTruncatingTail);
    CGSize _titleLabelSize = CGSizeZero;
    if (IOS_FSystenVersion < 7.0) {
        _titleLabelSize = RC_MULTILINE_TEXTSIZE_LIOS7(richContentMsg.title, [UIFont systemFontOfSize:RichContent_Title_Font_Size], CGSizeMake(self.messageContentView.frame.size.width - RICH_CONTENT_PADDING_LEFT -
                                                                                                                                              RICH_CONTENT_PADDING_RIGHT,
                                                                                                                                              MAXFLOAT), NSLineBreakByTruncatingTail);
    }else {
        _titleLabelSize = RC_MULTILINE_TEXTSIZE_GEIOS7(richContentMsg.title, [UIFont systemFontOfSize:RichContent_Title_Font_Size], CGSizeMake(self.messageContentView.frame.size.width - RICH_CONTENT_PADDING_LEFT -
                                                                                                                                               RICH_CONTENT_PADDING_RIGHT,
                                                                                                                                               MAXFLOAT));
    }


//    CGSize _digestLabelSize =
//        [richContentMsg.digest
//            boundingRectWithSize:CGSizeMake(self.messageContentView.frame.size.width -
//                                                richContentThumbImageFrame.width - RICH_CONTENT_PADDING_LEFT -4-
//                                                RICH_CONTENT_THUMBNAIL_CONTENT_PADDING - RICH_CONTENT_PADDING_RIGHT,
//                                            MAXFLOAT)
//                         options:(NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin |
//                                  NSStringDrawingUsesFontLeading)
//                      attributes:@{
//                          NSFontAttributeName : [UIFont systemFontOfSize:RichContent_Message_Font_Size]
//                      } context:nil]
//            .size;

//    CGSize _digestLabelSize = RC_MULTILINE_TEXTSIZE(richContentMsg.title, [UIFont systemFontOfSize:RichContent_Message_Font_Size], CGSizeMake(self.messageContentView.frame.size.width -
//                                                                                                                                           richContentThumbImageFrame.width - RICH_CONTENT_PADDING_LEFT -4-
//                                                                                                                                           RICH_CONTENT_THUMBNAIL_CONTENT_PADDING - RICH_CONTENT_PADDING_RIGHT,
//                                                                                                                                           MAXFLOAT), NSLineBreakByTruncatingTail);
    CGSize _digestLabelSize = CGSizeZero;
    if (IOS_FSystenVersion < 7.0) {
        _digestLabelSize = RC_MULTILINE_TEXTSIZE_LIOS7(richContentMsg.digest, [UIFont systemFontOfSize:RichContent_Message_Font_Size], CGSizeMake(self.messageContentView.frame.size.width -
                                                                                                                                                 richContentThumbImageFrame.width - RICH_CONTENT_PADDING_LEFT -4-
                                                                                                                                                 RICH_CONTENT_THUMBNAIL_CONTENT_PADDING - RICH_CONTENT_PADDING_RIGHT,
                                                                                                                                                 MAXFLOAT), NSLineBreakByTruncatingTail);
    }else {
        _digestLabelSize = RC_MULTILINE_TEXTSIZE_GEIOS7(richContentMsg.digest, [UIFont systemFontOfSize:RichContent_Message_Font_Size], CGSizeMake(self.messageContentView.frame.size.width -
                                                                                                                                                  richContentThumbImageFrame.width - RICH_CONTENT_PADDING_LEFT -4-
                                                                                                                                                  RICH_CONTENT_THUMBNAIL_CONTENT_PADDING - RICH_CONTENT_PADDING_RIGHT,
                                                                                                                                                  MAXFLOAT));
    }

    
    if (_digestLabelSize.height > richContentThumbImageFrame.height) {
        _digestLabelSize.height = richContentThumbImageFrame.height;
    }
//    if(_digestLabelSize.height<RICH_CONTENT_THUMBNAIL_HIGHT)
//        _digestLabelSize.height=RICH_CONTENT_THUMBNAIL_HIGHT;
//        
    
    messageContentViewRect.size.height = RICH_CONTENT_TITLE_PADDING_TOP + _titleLabelSize.height +
                                         RICH_CONTENT_TITLE_CONTENT_PADDING + _digestLabelSize.height +
                                         RICH_CONTENT_PADDING_BOTTOM;

    [self.richContentImageView setImageURL:[NSURL URLWithString:richContentMsg.imageURL]];


    self.titleLabel.frame =
        CGRectMake(RICH_CONTENT_PADDING_LEFT, RICH_CONTENT_TITLE_PADDING_TOP,
                   self.messageContentView.frame.size.width - RICH_CONTENT_PADDING_LEFT - RICH_CONTENT_PADDING_RIGHT,
                   _titleLabelSize.height);
    self.digestLabel.frame = CGRectMake(
        richContentThumbImageFrame.width + RICH_CONTENT_PADDING_LEFT + RICH_CONTENT_THUMBNAIL_CONTENT_PADDING+4,
        _titleLabelSize.height + RICH_CONTENT_TITLE_PADDING_TOP + RICH_CONTENT_TITLE_CONTENT_PADDING,
        _digestLabelSize.width, _digestLabelSize.height);

    self.richContentImageView.frame =
        CGRectMake(RICH_CONTENT_PADDING_LEFT,
                   _titleLabelSize.height + RICH_CONTENT_TITLE_PADDING_TOP + RICH_CONTENT_TITLE_CONTENT_PADDING,
                   richContentThumbImageFrame.width, richContentThumbImageFrame.height);

    self.bubbleBackgroundView.frame =
        CGRectMake(0, 0, self.messageContentView.frame.size.width,
                   (self.richContentImageView.frame.origin.y + self.richContentImageView.frame.size.height + 10));
    messageContentViewRect.size.height = messageContentViewRect.size.height+10;
    self.messageContentView.frame = messageContentViewRect;
    //NSLog(@"bound width is %f", self.bubbleBackgroundView.frame.size.width);
}

#pragma mark - cell tap event, open the related URL
- (void)tapBubbleBackgroundViewEvent:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        // to do something.
        RCRichContentMessage *richContentMsg = (RCRichContentMessage *)self.model.content;
        DebugLog(@"%s, URL > %@", __FUNCTION__, richContentMsg.imageURL);
        if (nil != richContentMsg.url) {
//            NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", richContentMsg.url]];
//            [[UIApplication sharedApplication] openURL:URL];
            if ([self.delegate respondsToSelector:@selector(didTapUrlInMessageCell:model:)]) {
                [self.delegate didTapUrlInMessageCell:richContentMsg.url model:self.model];
                return;
            }
        } else if (nil != richContentMsg.imageURL) {
//            NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", richContentMsg.imageURL]];
//            [[UIApplication sharedApplication] openURL:URL];
            if ([self.delegate respondsToSelector:@selector(didTapUrlInMessageCell:model:)]) {
                [self.delegate didTapUrlInMessageCell:richContentMsg.imageURL model:self.model];
                return;
            }
        }
        
        if ([self.delegate respondsToSelector:@selector(didTapMessageCell:)]) {
            [self.delegate didTapMessageCell:self.model];
        }
    }
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
@end
