//
//  RCPublicServiceProfilePlainCell.m
//  HelloIos
//
//  Created by litao on 15/4/10.
//  Copyright (c) 2015年 litao. All rights reserved.
//

#import "RCPublicServiceProfilePlainCell.h"
#import "RCPublicServiceViewConstants.h"
#import "RCKitCommonDefine.h"
@interface RCPublicServiceProfilePlainCell ()
@property(nonatomic, strong) UILabel *title;
@property(nonatomic, strong) UILabel *content;
@end

@implementation RCPublicServiceProfilePlainCell

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
    self.content.textColor = [UIColor grayColor];
    self.content.font = [UIFont systemFontOfSize:RCPublicServiceProfileSmallFont];
    [self.contentView addSubview:self.title];
    [self.contentView addSubview:self.content];
}

- (void)setTitle:(NSString *)title Content:(NSString *)content {
    self.title.text = title;
    self.content.text = content;
    [self updateFrame];
}

- (void)updateFrame {
    CGRect contentViewFrame = self.frame;
    UIFont *font1 = [UIFont systemFontOfSize:RCPublicServiceProfileBigFont];
    //设置一个行高上限
    CGSize size = CGSizeMake(RCPublicServiceProfileCellTitleWidth, 2000);
    //计算实际frame大小，并将label的frame变成实际大小
//    CGSize labelsize1 =
//        [self.title.text boundingRectWithSize:size
//                                      options:NSStringDrawingTruncatesLastVisibleLine |
//                                              NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
//                                   attributes:@{
//                                       NSFontAttributeName : [UIFont systemFontOfSize:RCPublicServiceProfileBigFont]
//                                   } context:nil]
//            .size;

//    CGSize labelsize1 = RC_MULTILINE_TEXTSIZE(self.title.text, [UIFont systemFontOfSize:RCPublicServiceProfileBigFont], size, NSLineBreakByTruncatingTail);
    CGSize labelsize1 = CGSizeZero;
    if (IOS_FSystenVersion < 7.0) {
        labelsize1 = RC_MULTILINE_TEXTSIZE_LIOS7(self.title.text, [UIFont systemFontOfSize:RCPublicServiceProfileBigFont], size, NSLineBreakByTruncatingTail);
    }else {
        labelsize1 = RC_MULTILINE_TEXTSIZE_GEIOS7(self.title.text, [UIFont systemFontOfSize:RCPublicServiceProfileBigFont], size);
    }


    
    self.title.frame = CGRectMake(2 * RCPublicServiceProfileCellPaddingLeft, RCPublicServiceProfileCellPaddingTop,
                                  labelsize1.width, labelsize1.height);

    size = CGSizeMake(self.frame.size.width - RCPublicServiceProfileCellPaddingLeft - RCPublicServiceProfileCellTitleWidth -
                          RCPublicServiceProfileCellPaddingRight - 20,
                      2000);
    UIFont *font2 = [UIFont systemFontOfSize:RCPublicServiceProfileSmallFont];
//    CGSize labelsize2 =
//        [self.content.text boundingRectWithSize:size
//                                        options:NSStringDrawingTruncatesLastVisibleLine |
//                                                NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
//                                     attributes:@{
//                                         NSFontAttributeName : font2
//                                     } context:nil]
//            .size;
    
//    CGSize labelsize2 = RC_MULTILINE_TEXTSIZE(self.content.text, font2, size, NSLineBreakByTruncatingTail);
    CGSize labelsize2 = CGSizeZero;
    if (IOS_FSystenVersion < 7.0) {
        labelsize2 = RC_MULTILINE_TEXTSIZE_LIOS7(self.content.text, font2, size, NSLineBreakByTruncatingTail);
    }else {
        labelsize2 = RC_MULTILINE_TEXTSIZE_GEIOS7(self.content.text, font2, size);
    }


    
    self.content.numberOfLines = 0;
    [self.content setContentMode:UIViewContentModeTop];
    float offset = 0;
    if (labelsize2.height < labelsize1.height) {
        offset = (labelsize1.height - labelsize2.height) / 2;
        offset += (font1.xHeight - font2.xHeight) / 2;
    }
    self.content.frame = CGRectMake(RCPublicServiceProfileCellPaddingLeft + RCPublicServiceProfileCellTitleWidth,
                                    RCPublicServiceProfileCellPaddingTop + offset, labelsize2.width, labelsize2.height);
    contentViewFrame.size.height = MAX(self.title.frame.size.height, self.content.frame.size.height) +
                                   RCPublicServiceProfileCellPaddingTop + RCPublicServiceProfileCellPaddingBottom;
    [self.content sizeToFit];
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
