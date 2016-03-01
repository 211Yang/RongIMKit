//
//  RCPublicServiceProfileTelCell.m
//  HelloIos
//
//  Created by litao on 15/4/10.
//  Copyright (c) 2015年 litao. All rights reserved.
//

#import "RCPublicServiceProfileTelCell.h"
#import "RCPublicServiceViewConstants.h"
#import "RCKitCommonDefine.h"
@interface RCPublicServiceProfileTelCell ()
@property(nonatomic, strong) UILabel *title;
@property(nonatomic, strong) UILabel *content;
@end

@implementation RCPublicServiceProfileTelCell

- (instancetype)init {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"hello"];
    ;

    if (self) {
        [self setup];
    }

    return self;
}

- (void)setup {
    CGRect bounds = [[UIScreen mainScreen] bounds];
    bounds.size.height = 0;

    self.frame = bounds;

    self.title = [[UILabel alloc] initWithFrame:CGRectZero];
    self.content = [[UILabel alloc] initWithFrame:CGRectZero];

    self.title.numberOfLines = 0;
    self.title.font = [UIFont systemFontOfSize:RCPublicServiceProfileBigFont];
    self.title.textColor = [UIColor blackColor];
    self.title.textAlignment = NSTextAlignmentLeft;
    self.content.numberOfLines = 0;
    self.content.lineBreakMode = NSLineBreakByCharWrapping;
    self.content.textAlignment = NSTextAlignmentRight;
    self.content.textColor = [UIColor grayColor];
    self.content.font = [UIFont systemFontOfSize:RCPublicServiceProfileSmallFont];
    [self.contentView addSubview:self.title];
    [self.contentView addSubview:self.content];
}

- (void)setTitle:(NSString *)title Content:(NSString *)content {
    self.title.text = title;
    self.content.text = content;
    if (content && content.length > 0) {
        UITapGestureRecognizer *tapGesture =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTel:)];
        [self addGestureRecognizer:tapGesture];
    }
    [self updateFrame];
}
- (void)onTel:(id)sender {
    NSMutableString *str = [[NSMutableString alloc] initWithFormat:@"telprompt://%@", self.content.text];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:str]];
}
- (void)updateFrame {
    CGRect contentViewFrame = self.frame;

    UIFont *font = [UIFont systemFontOfSize:RCPublicServiceProfileBigFont];
    //设置一个行高上限
    CGSize size = CGSizeMake(RCPublicServiceProfileCellTitleWidth, 2000);
    //计算实际frame大小，并将label的frame变成实际大小
//    CGSize labelsize =
//        [self.title.text boundingRectWithSize:size
//                                      options:NSStringDrawingTruncatesLastVisibleLine |
//                                              NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
//                                   attributes:@{
//                                       NSFontAttributeName : font
//                                   } context:nil]
//            .size;
//    CGSize labelsize = RC_MULTILINE_TEXTSIZE(self.title.text, font, size, NSLineBreakByTruncatingTail);
    CGSize labelsize = CGSizeZero;
    if (IOS_FSystenVersion < 7.0) {
        labelsize = RC_MULTILINE_TEXTSIZE_LIOS7(self.title.text, font, size, NSLineBreakByTruncatingTail);
    }else {
        labelsize = RC_MULTILINE_TEXTSIZE_GEIOS7(self.title.text, font, size);
    }


    
    self.title.frame = CGRectMake(2 * RCPublicServiceProfileCellPaddingLeft, RCPublicServiceProfileCellPaddingTop,
                                  labelsize.width, labelsize.height);

    size = CGSizeMake(self.frame.size.width - RCPublicServiceProfileCellPaddingLeft - RCPublicServiceProfileCellTitleWidth -
                          RCPublicServiceProfileCellPaddingRight,
                      2000);
    font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
//    labelsize =
//        [self.content.text boundingRectWithSize:size
//                                        options:NSStringDrawingTruncatesLastVisibleLine |
//                                                NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
//                                     attributes:@{
//                                         NSFontAttributeName : font
//                                     } context:nil]
//            .size;
    
//    labelsize = RC_MULTILINE_TEXTSIZE(self.content.text, font, size, NSLineBreakByTruncatingTail);
     labelsize = CGSizeZero;
    if (IOS_FSystenVersion < 7.0) {
        labelsize = RC_MULTILINE_TEXTSIZE_LIOS7(self.content.text, font, size, NSLineBreakByTruncatingTail);
    }else {
        labelsize = RC_MULTILINE_TEXTSIZE_GEIOS7(self.content.text, font, size);
    }


    if (RCPublicServiceProfileCellPaddingLeft + RCPublicServiceProfileCellTitleWidth + labelsize.width <
        contentViewFrame.size.width) {
        self.content.frame =
            CGRectMake(contentViewFrame.size.width - labelsize.width - RCPublicServiceProfileCellPaddingLeft - 20,
                       RCPublicServiceProfileCellPaddingTop, labelsize.width, labelsize.height);
    } else
        self.content.frame = CGRectMake(100, 8, labelsize.width, labelsize.height);
    contentViewFrame.size.height = MAX(self.title.frame.size.height, self.content.frame.size.height) +
                                   RCPublicServiceProfileCellPaddingTop + RCPublicServiceProfileCellPaddingBottom;
    self.frame = contentViewFrame;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextFillRect(context, rect);

    //上分割线，
    CGContextSetStrokeColorWithColor(context, HEXCOLOR(0xFFFFFF).CGColor);
    CGContextStrokeRect(context, CGRectMake(5, -1, rect.size.width - 10, 1));

    //下分割线
    CGContextSetStrokeColorWithColor(context, HEXCOLOR(0xe2e2e2).CGColor);
    CGContextStrokeRect(context, CGRectMake(5, rect.size.height, rect.size.width - 10, 1));
}
@end