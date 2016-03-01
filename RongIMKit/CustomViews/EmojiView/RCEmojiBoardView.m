//
//  RCEmojiView.m
//  RCIM
//
//  Created by Heq.Shinoda on 14-5-29.
//  Copyright (c) 2014年 RongCloud. All rights reserved.
//

#import "RCEmojiBoardView.h"
#import "EmojiStringDefine.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCEmojiPageControl.h"

#define RC_EMOJI_WIDTH 35

@interface RCEmojiBoardView ()

@property(nonatomic, assign) int emojiTotal;
@property(nonatomic, assign) int emojiTotalPage;
@property(nonatomic, assign) int emojiColumn;
@property(nonatomic, assign) int emojiRow;
@property(nonatomic, assign) int emojiMaxCountPerPage;
@property(nonatomic, assign) CGFloat emojiMariginHorizontalMin;
@property(nonatomic, assign) CGFloat emojiSpanVertial;
@property(nonatomic, assign) CGFloat emojiSpanHorizontal;
@property(nonatomic, strong) NSArray *faceEmojiArray;
@property(nonatomic, assign) int emojiLoadedPage;

@end

@implementation RCEmojiBoardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
        NSString *bundlePath = [resourcePath stringByAppendingPathComponent:@"Emoji.plist"];
        DebugLog(@"Emoji.plist > %@", bundlePath);
        self.faceEmojiArray = [[NSArray alloc]initWithContentsOfFile:bundlePath];
        self.emojiLoadedPage = 0;
        
        [self generateDefaultLayoutParameters];
        self.backgroundColor = HEXCOLOR(0xebebeb);

        self.emojiBackgroundView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 178)];
        self.emojiBackgroundView.backgroundColor = HEXCOLOR(0xfafafa);
        self.emojiBackgroundView.pagingEnabled = YES;
        self.emojiBackgroundView.contentSize = CGSizeMake(self.emojiTotalPage * self.frame.size.width, 178);
        self.emojiBackgroundView.showsHorizontalScrollIndicator = NO;
        self.emojiBackgroundView.showsVerticalScrollIndicator = NO;
        self.emojiBackgroundView.delegate = self;
        [self addSubview:self.emojiBackgroundView];

        UIView *splitLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 1)];
        [splitLine setBackgroundColor:HEXCOLOR(0xdcdcdc)];
        [self addSubview:splitLine];
        
        [self loadLabelView];
    }
    return self;
}

- (void)generateDefaultLayoutParameters {
    self.emojiSpanHorizontal = 44;
    self.emojiSpanVertial = 44;
    self.emojiRow = 3;
    self.emojiMariginHorizontalMin = 6;
    if (nil == self.faceEmojiArray ||  [self.faceEmojiArray count] == 0) {
        self.emojiTotal = 0;
    }else{
        self.emojiTotal = (int)[self.faceEmojiArray count]; //sizeof(faceEmojiArray) / sizeof(faceEmojiArray[0]); //(int)[self.faceEmojiArray count];//
    }
    self.emojiColumn = (int)self.frame.size.width / self.emojiSpanVertial;
    int left = (int)self.frame.size.width % 44;
    if (left < 12) {
        self.emojiColumn--;
        left += self.emojiSpanVertial;
    }
    self.emojiMaxCountPerPage = self.emojiColumn * self.emojiRow - 1;
    self.emojiMariginHorizontalMin = left / 2;
    self.emojiTotalPage =
        self.emojiTotal / self.emojiMaxCountPerPage + (self.emojiTotal % self.emojiMaxCountPerPage ? 1 : 0);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
- (void)loadLabelView {
    [self loadEmojiViewPartly];

    pageCtrl = [[RCEmojiPageControl alloc] initWithFrame:CGRectMake(0, 158, self.frame.size.width, 5)];
    pageCtrl.numberOfPages = self.emojiTotalPage; //总的图片页数
    pageCtrl.currentPage = 0;                     //当前页
    [pageCtrl addTarget:self action:@selector(pageTurn:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:pageCtrl];

    UIView *splitLine = [[UIView alloc] initWithFrame:CGRectMake(0, 178, self.frame.size.width, 1)];
    [splitLine setBackgroundColor:HEXCOLOR(0xbfbfbf)];
    [self addSubview:splitLine];

    UIButton *sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [sendBtn setBackgroundImage:IMAGE_BY_NAMED(@"emoji_btn_send_bg") forState:UIControlStateNormal];
    sendBtn.frame = CGRectMake(self.frame.size.width - 80, self.frame.size.height - 42, 80, 42);
    [sendBtn setTitle:NSLocalizedStringFromTable(@"Send", @"RongCloudKit", nil) forState:UIControlStateNormal];
    [sendBtn addTarget:self action:@selector(sendBtnHandle:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:sendBtn];
}

//延迟加载
- (void)loadEmojiViewPartly {
    //每次加载两页，防止快速移动
    int beginEmojiBtn = self.emojiLoadedPage * self.emojiMaxCountPerPage;
    int endEmojiBtn = MIN(self.emojiTotal, (self.emojiLoadedPage + 2) * self.emojiMaxCountPerPage);
    for (int i = beginEmojiBtn; i < endEmojiBtn; i++) {
        int pageIndex = i / self.emojiMaxCountPerPage;
        float startPos_X = self.emojiMariginHorizontalMin, startPos_Y = 12;
        float emojiPosX = startPos_X + 44 * (i % self.emojiMaxCountPerPage % self.emojiColumn) + 4 +
                          pageIndex * self.frame.size.width;
        float emojiPosY = startPos_Y + 44 * (i % self.emojiMaxCountPerPage / self.emojiColumn) + 4;
        UIButton *emojiBtn =
            [[UIButton alloc] initWithFrame:CGRectMake(emojiPosX, emojiPosY, RC_EMOJI_WIDTH, RC_EMOJI_WIDTH)];
        emojiBtn.titleLabel.font = [UIFont systemFontOfSize:32];
        [emojiBtn setBackgroundColor:[UIColor clearColor]];
        
       // NSString *emoji_ =
       // NSLog(@"<string>%@</string>", faceEmojiArray[i]);
        
        [emojiBtn setTitle:self.faceEmojiArray[i] forState:UIControlStateNormal];
        [emojiBtn addTarget:self action:@selector(emojiBtnHandle:) forControlEvents:UIControlEventTouchUpInside];
        [self.emojiBackgroundView addSubview:emojiBtn];

        if (((i + 1) >= self.emojiMaxCountPerPage && (i + 1) % self.emojiMaxCountPerPage == 0) ||
            i == self.emojiTotal - 1) {
            CGRect frame = emojiBtn.frame;
            UIButton *deleteButton =
                [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - self.emojiMariginHorizontalMin - 44,
                                                           frame.origin.y, RC_EMOJI_WIDTH, RC_EMOJI_WIDTH)];
            deleteButton.titleLabel.font = [UIFont systemFontOfSize:32];
            [deleteButton setBackgroundColor:[UIColor clearColor]];
            [deleteButton addTarget:self
                             action:@selector(emojiBtnHandle:)
                   forControlEvents:UIControlEventTouchUpInside];
            frame.origin.x =
                self.frame.size.width - self.emojiMariginHorizontalMin - 44 + pageIndex * self.frame.size.width;
            frame.size = CGSizeMake(35, 23);
            frame.origin.y = emojiPosY + (RC_EMOJI_WIDTH - frame.size.height)/2;
            deleteButton.frame = frame;
            [deleteButton setBackgroundImage:IMAGE_BY_NAMED(@"emoji_btn_delete") forState:UIControlStateNormal];
            [self.emojiBackgroundView addSubview:deleteButton];
        }
        if (self.emojiLoadedPage < pageIndex + 1) {
            self.emojiLoadedPage = pageIndex + 1;
        }
    }
}

- (void)emojiBtnHandle:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(didTouchEmojiView:touchedEmoji:)]) {
        [self.delegate didTouchEmojiView:self touchedEmoji:sender.titleLabel.text];
    }
}

- (void)sendBtnHandle:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(didSendButtonEvent:sendButton:)]) {
        [self.delegate didSendButtonEvent:self sendButton:sender];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self loadEmojiViewPartly];
}

//停止滚动的时候
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    //更新UIPageControl的当前页
    CGPoint offset = scrollView.contentOffset;
    CGRect bounds = scrollView.frame;
    [pageCtrl setCurrentPage:offset.x / bounds.size.width];
    DebugLog(@"%f", offset.x / bounds.size.width);
}

//然后是点击UIPageControl时的响应函数pageTurn
- (void)pageTurn:(UIPageControl *)sender {
    //令UIScrollView做出相应的滑动显示
    CGSize viewSize = self.emojiBackgroundView.frame.size;
    CGRect rect = CGRectMake(sender.currentPage * viewSize.width, 0, viewSize.width, viewSize.height);
    [self.emojiBackgroundView scrollRectToVisible:rect animated:YES];
}

- (float) getBoardViewBottonOriginY{
    float gap = (IOS_FSystenVersion < 7.0) ? 64 : 0 ;
    return [UIScreen mainScreen].bounds.size.height - gap;
}
//用于动画效果
- (void)setHidden:(BOOL)hidden {
    CGRect viewRect = self.frame;
    if (hidden) {
        viewRect.origin.y = [self getBoardViewBottonOriginY];
    } else {
        viewRect.origin.y = [self getBoardViewBottonOriginY] - self.frame.size.height;
    }
    [self setFrame:viewRect];
    [super setHidden:hidden];
}

@end
