//
//  RCConversationViewController.m
//  RongIMKit
//
//  Created by xugang on 15/1/22.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCConversationViewController.h"
#import "RCMessageCell.h"
#import "RCTextMessageCell.h"
#import "RCImageMessageCell.h"
#import "RCVoiceMessageCell.h"
#import "RCRichContentMessageCell.h"
#import "RCLocationMessageCell.h"
#import "RCMessageModel.h"
#import "RCIM.h"
#import "RCImagePreviewController.h"
#import "RCVoicePlayer.h"
#import "RCLocationPickerViewController.h"
#import "RCLocationViewController.h"
#import "RCTipMessageCell.h"
#import "RCVoiceCaptureControl.h"
#import "RCKitUtility.h"
#import "RCConversationCollectionViewHeader.h"
#import "RCKitCommonDefine.h"
#if RC_VOIP_ENABLE
#import "RCVoIPMessageCenter.h"
#import "RCVoIPCallMessage.h"
#endif
#import "RCSystemSoundPlayer.h"
#import "RCImagePreviewController.h"
#import "RCSettingViewController.h"
#import "RCImagePickerViewController.h"
#import <RongIMLib/RongIMLib.h>
#import "RCPublicServiceMultiImgTxtCell.h"
#import "RCPublicServiceImgTxtMsgCell.h"
#import "RCPublicServiceProfileViewController.h"
#import "RCSystemSoundPlayer.h"
#import "RCAlbumListViewController.h"
#import "RCAssetHelper.h"
#import "RCUserInfoLoader.h"
#import "RCGroupLoader.h"
#import "RCOldMessageNotificationMessage.h"
#import "RCOldMessageNotificationMessageCell.h"
#import <objc/runtime.h>
#import "RCUserInfoCache.h"

//单个cell的高度是70（RCPlaginBoardCellSize）*2 + 上下padding的高度14*2 ＋
//上下两个图标之间的padding
#define Height_EmojBoardView 220.0f
#define Height_PluginBoardView 220.0f
// NSString *const RCNotificaitonDidPreviewPiecture =
// @"RCNotificaitonDidPreviewPiecture";
// 标准系统状态栏高度
#define SYS_STATUSBAR_HEIGHT                        20
// 热门栏高度
#define HOTSPOT_STATUSBAR_HEIGHT            20
#define APP_STATUSBAR_HEIGHT                (CGRectGetHeight([UIApplication sharedApplication].statusBarFrame))
// 根据APP_STATUSBAR_HEIGHT判断是不是存在热门栏
#define IS_HOTSPOT_CONNECTED                (APP_STATUSBAR_HEIGHT==(SYS_STATUSBAR_HEIGHT+HOTSPOT_STATUSBAR_HEIGHT)?YES:NO)

//typedef NS_ENUM(NSInteger, KBottomBarStatus) {
//  KBottomBarDefaultStatus = 0,
//  KBottomBarKeyboardStatus,
//  KBottomBarPluginStatus,
//  KBottomBarEmojiStatus,
//  KBottomBarRecordStatus
//};

@interface RCConversationViewController () <
    UICollectionViewDelegate, UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout, RCMessageCellDelegate,
    RCChatSessionInputBarControlDelegate, UIGestureRecognizerDelegate,
    UIScrollViewDelegate, RCEmojiViewDelegate, RCPluginBoardViewDelegate,
    RCVoiceCaptureControlDelegate, UIImagePickerControllerDelegate,
    RCLocationPickerViewControllerDelegate, UINavigationControllerDelegate,
    RCImagePickerViewControllerDelegate, RCAlbumListViewControllerDelegate,RCPublicServiceMessageCellDelegate,RCTypingStatusDelegate>

@property(nonatomic, strong)
    RCConversationCollectionViewHeader *collectionViewHeader;

@property(nonatomic) KBottomBarStatus currentBottomBarStatus;
@property(nonatomic) CGRect KeyboardFrame;

@property(nonatomic) BOOL isLoading;
//@property (nonatomic, strong) NSMutableArray *emojiTextArray;
@property(nonatomic, strong) UIImagePickerController *curPicker;

@property(nonatomic, strong) RCVoiceCaptureControl *voiceCaptureControl;

@property(nonatomic, strong) RCMessageModel *longPressSelectedModel;

@property(nonatomic, assign) BOOL isConversationAppear;

@property(nonatomic, assign) BOOL isTakeNewPhoto;
@property(nonatomic, assign) BOOL isAudioRecoderTimeOut;
@property(nonatomic, assign) BOOL isNeedScrollToButtom;
@property(nonatomic, assign) BOOL isChatRoomHistoryMessageLoaded;

@property (nonatomic, strong)RCDiscussion *currentDiscussion;

@property (nonatomic, strong) UIImageView *unreadRightBottomIcon;
@property (nonatomic, assign) NSInteger unreadNewMsgCount;

@property (nonatomic, assign) NSInteger  scrollNum;
@property (nonatomic, assign) NSInteger  sendOrReciveMessageNum;//记录新收到和自己新发送的消息数，用于计算加载历史消息时插入“以上是历史消息”cell 的位置

@property(nonatomic,assign)BOOL isClickAddButton;
@property(nonatomic,assign)BOOL isClickEmojiButton;
@property(nonatomic,assign)BOOL isClear;

@property (nonatomic, strong)UIView *typingStatusView;
@property (nonatomic, strong)UILabel *typingStatusLabel;
@property (nonatomic, strong) dispatch_queue_t rcTypingMessageQueue;
@property (nonatomic, strong) NSMutableArray *typingMessageArray;
@property (nonatomic, strong) NSTimer *typingStatusTimer;
@property (nonatomic,copy)  NSString *typingUserStr;
@property (nonatomic,copy)  NSString *navigationTitle;
- (void)rcinit;
- (void)registerNotification;
- (void)initializedSubViews;

- (void)layoutBottomBarWithStatus:(KBottomBarStatus)bottomBarStatus;

- (BOOL)appendMessageModel:(RCMessageModel *)model;
- (void)pushOldMessageModel:(RCMessageModel *)model;

- (void)loadLatestHistoryMessage;
- (void)loadMoreHistoryMessage;
/**
 *  梳理数据源，判断是否显示时间
 */
- (void)figureOutAllConversationDataRepository;

- (void)appendAndDisplayMessage:(RCMessage *)rcMessage;

- (void)scrollToBottomAnimated:(BOOL)animated;
- (void)tap4ResetDefaultBottomBarStatus:
    (UIGestureRecognizer *)gestureRecognizer;

@end

static NSString *const rctextCellIndentifier = @"rctextCellIndentifier";
static NSString *const rcimageCellIndentifier = @"rcimageCellIndentifier";
static NSString *const rcvoiceCellIndentifier = @"rcvoiceCellIndentifier";
static NSString *const rcrichCellIndentifier = @"rcrichCellIndentifier";
static NSString *const rclocationCellIndentifier = @"rclocationCellIndentifier";
static NSString *const rcTipMessageCellIndentifier =
    @"rcTipMessageCellIndentifier";
static NSString *const rcMPMsgCellIndentifier = @"rcMPMsgCellIndentifier";
static NSString *const rcMPSingleMsgCellIndentifier =
    @"rcMPSingleMsgCellIndentifier";
static NSString *const rcUnknownMessageCellIndentifier =
    @"rcUnknownMessageCellIndentifier";
static NSString *const rcOldMessageNotificationMessageCellIndentifier =
@"rcOldMessageNotificationMessageCellIndentifier";
bool isCanSendTypingMessage = YES;
@implementation RCConversationViewController

- (id)initWithConversationType:(RCConversationType)conversationType
                      targetId:(NSString *)targetId {
  self = [super init];
  if (self) {
    [self rcinit];
    self.conversationType = conversationType;
    self.targetId = targetId;
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    [self rcinit];
  }
  return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    [self rcinit];
  }
  return self;
}

- (void)rcinit {
  _isLoading = NO;
  _isConversationAppear = NO;
  self.conversationDataRepository = [[NSMutableArray alloc] init];
  self.conversationMessageCollectionView = nil;
  self.targetId = nil;
  _userName = nil; //废弃
  self.currentBottomBarStatus = KBottomBarDefaultStatus;
  [self registerNotification];
  self.KeyboardFrame = CGRectZero;
  self.isAudioRecoderTimeOut = NO;
  self.displayUserNameInCell = YES;
  self.defaultInputType = RCChatSessionInputBarInputText;
  self.defaultHistoryMessageCountOfChatRoom = 10;
  self.enableContinuousReadUnreadVoice = YES;
  self.isClear = NO;
  self.typingMessageArray = [[NSMutableArray alloc]init];
}
- (void)registerNotification {

  //注册接收消息
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(didReceiveMessageNotification:)
     name:RCKitDispatchMessageNotification
     object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(didSendingMessageNotification:)
     name:@"RCKitSendingMessageNotification"
     object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(receiveMessageHasReadNotification:)
     name:RCLibDispatchReadReceiptNotification
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(receivePlayVoiceFinishNotification:)
     name:@"kRCPlayVoiceFinishNotification"
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(handleAppResume)
     name:UIApplicationWillEnterForegroundNotification
     object:nil];
}
- (void)registerClass:(Class)cellClass
    forCellWithReuseIdentifier:(NSString *)identifier {
  [self.conversationMessageCollectionView registerClass:cellClass
                             forCellWithReuseIdentifier:identifier];
}
- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  // self.edgesForExtendedLayout = UIRectEdgeBottom | UIRectEdgeTop;
  // self.extendedLayoutIncludesOpaqueBars = YES;
  if (IOS_FSystenVersion >= 7.0) {
    // 左滑返回 和 按住事件冲突
    self.navigationController.interactivePopGestureRecognizer.delaysTouchesBegan=NO;
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.automaticallyAdjustsScrollViewInsets = NO;
  }
    
  [self initializedSubViews];

  if (!(self.conversationType == ConversationType_CHATROOM)) {
    //非聊天室加载历史数据
    [self loadLatestHistoryMessage];
  } else {
    //聊天室从服务器拉取消息，设置初始状态为为加载完成
    self.isChatRoomHistoryMessageLoaded = NO;
  }

  if (ConversationType_CHATROOM == self.conversationType) {
    [[RCIMClient sharedRCIMClient] joinChatRoom:self.targetId
        messageCount:self.defaultHistoryMessageCountOfChatRoom
        success:^{

        }
        error:^(RCErrorCode status) {
          __weak RCConversationViewController *weakSelf = self;
          dispatch_async(dispatch_get_main_queue(), ^{
            if (status == KICKED_FROM_CHATROOM) {
                [weakSelf loadErrorAlert:
                 NSLocalizedStringFromTable(@"JoinChatRoomRejected", @"RongCloudKit", nil)];
            } else {
                [weakSelf loadErrorAlert:
                 NSLocalizedStringFromTable(@"JoinChatRoomFailed", @"RongCloudKit", nil)];
            }
          });
        }];
  }
  if (ConversationType_CUSTOMERSERVICE == self.conversationType) {
    RCHandShakeMessage *__message = [[RCHandShakeMessage alloc] init];
    [[RCIMClient sharedRCIMClient] sendMessage:self.conversationType
        targetId:self.targetId
        content:__message
        pushContent:nil
        success:^(long messageId) {

        }
        error:^(RCErrorCode nErrorCode, long messageId){

        }];
  }

  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
      initWithImage:[UIImage imageNamed:@"Setting"]
              style:UIBarButtonItemStylePlain
             target:self
             action:@selector(rightBarButtonItemClicked:)];
  [self layoutBottomBarWithStatus:KBottomBarDefaultStatus];

  [[RCIMClient sharedRCIMClient] clearMessagesUnreadStatus:self.conversationType
                                                  targetId:self.targetId];
    
    if (self.conversationType == ConversationType_DISCUSSION) {
        [[RCIMClient sharedRCIMClient] getDiscussion:self.targetId success:^(RCDiscussion *discussion) {
            self.currentDiscussion = discussion;
        } error:^(RCErrorCode status) {
            
        }];
    }
    if ([RCIM sharedRCIM].enableReadReceipt && self.conversationType == ConversationType_PRIVATE) {
        long long lastReceiveMessageSendTime = 0;
        for (int i = 0; i < self.conversationDataRepository.count; i++) {
            RCMessage *rcMsg = [self.conversationDataRepository objectAtIndex:i];
            RCMessageModel *model = [[RCMessageModel alloc] initWithMessage:rcMsg];
            if (model.messageDirection == MessageDirection_RECEIVE ) {
                lastReceiveMessageSendTime = model.sentTime;//这里同一条消息竟然出现接收到的senttime 比对方发送者的sentime 要小？？serverbug
            }
        }
        //如果是单聊并且开启了已读回执，需要发送已读回执消息
        if(lastReceiveMessageSendTime != 0)
        {
            [[RCIMClient sharedRCIMClient]sendReadReceiptMessage:self.conversationType targetId:self.targetId time:lastReceiveMessageSendTime];
        }
    }
    if(ConversationType_APPSERVICE==self.conversationType || ConversationType_PUBLICSERVICE==self.conversationType)
    {
        RCPublicServiceProfile *profile = [[RCIMClient sharedRCIMClient] getPublicServiceProfile:(RCPublicServiceType)self.conversationType publicServiceId:self.targetId];
        if (profile.menu.menuItems) {
            [self.chatSessionInputBarControl setInputBarType:RCChatSessionInputBarControlPubType style:RC_CHAT_INPUT_BAR_STYLE_SWITCH_CONTAINER_EXTENTION];
            self.chatSessionInputBarControl.publicServiceMenu = profile.menu;
        }
        RCPublicServiceCommandMessage *entryCommond = [RCPublicServiceCommandMessage messageWithCommand:@"entry" data:nil];
        [self sendMessage:entryCommond pushContent:nil];
    }
}

- (void)loadErrorAlert:(NSString *)title {
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                  message:nil
                                                 delegate:nil
                                        cancelButtonTitle:nil
                                        otherButtonTitles:nil];
  [NSTimer scheduledTimerWithTimeInterval:1.0f
                                   target:self
                                 selector:@selector(cancelAlertAndGoBack:)
                                 userInfo:alert
                                  repeats:NO];
  [alert show];
}

- (void)cancelAlertAndGoBack:(NSTimer *)scheduledTimer {
  UIAlertView *alert = (UIAlertView *)(scheduledTimer.userInfo);
  [alert dismissWithClickedButtonIndex:0 animated:NO];
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)rightBarButtonItemClicked:(id)sender {
  if (ConversationType_APPSERVICE == self.conversationType ||
      ConversationType_PUBLICSERVICE == self.conversationType) {
    RCPublicServiceProfile *serviceProfile = [[RCIMClient sharedRCIMClient]
        getPublicServiceProfile:(RCPublicServiceType)self.conversationType
                publicServiceId:self.targetId];

    RCPublicServiceProfileViewController *infoVC =
        [[RCPublicServiceProfileViewController alloc] init];
    infoVC.serviceProfile = serviceProfile;
    infoVC.fromConversation = YES;
    [self.navigationController pushViewController:infoVC animated:YES];
  } else {
    RCSettingViewController *settingVC = [[RCSettingViewController alloc] init];
    settingVC.conversationType = self.conversationType;
    settingVC.targetId = self.targetId;
    [self.navigationController pushViewController:settingVC animated:YES];
  }
}

- (void)viewWillAppear:(BOOL)animated {
    _isClickEmojiButton = NO;
    _isClickAddButton = NO;
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(currentViewFrameChange:) name:UIApplicationWillChangeStatusBarFrameNotification object:nil];
    [self.chatSessionInputBarControl.emojiButton setImage:IMAGE_BY_NAMED(@"chatting_biaoqing_btn_normal") forState:UIControlStateNormal];
  [[RCSystemSoundPlayer defaultPlayer] setIgnoreConversationType:self.conversationType targetId:self.targetId];
    //NSLog(@"%ld",(unsigned long)self.conversationDataRepository.count);
    if (self.conversationDataRepository.count == 0 && _unReadButton !=nil) {
        [_unReadButton removeFromSuperview];
        _unReadMessage = 0;
    }
    self.scrollNum = 0;
  if(_unReadMessage > 10 && _unReadMessage <= 150 && self.enableUnreadMessageIcon == YES){
      [self p_setupUnReadMessageView];
   }
    // get and show
    NSString *draft =
    [[RCIMClient sharedRCIMClient] getTextMessageDraft:self.conversationType
                                              targetId:self.targetId];
    if (draft && draft.length > 0) {
        self.chatSessionInputBarControl.inputTextView.text = draft;
        // clear
//        [self changeTextViewHeight:draft]; //先设置内容，动画效果在viewDidAppear再显示
        [[RCIMClient sharedRCIMClient] saveTextMessageDraft:self.conversationType
                                                   targetId:self.targetId
                                                    content:nil];
    }
    [self.conversationMessageCollectionView reloadData];
    
}


-(void)currentViewFrameChange:(NSNotification *)notification
{
    CGRect newStatusBarFrame = [(NSValue*)[notification.userInfo objectForKey:UIApplicationStatusBarFrameUserInfoKey] CGRectValue];
    // 根据系统状态栏高判断热门栏的变动
    BOOL bPersonalHotspotConnected = (CGRectGetHeight(newStatusBarFrame)==(SYS_STATUSBAR_HEIGHT+HOTSPOT_STATUSBAR_HEIGHT)?YES:NO);
    if (bPersonalHotspotConnected) {
        [self animationLayoutBottomBarWithStatus:self.currentBottomBarStatus animated:YES];
    }
    else
    {
        [self animationLayoutBottomBarWithStatus:self.currentBottomBarStatus animated:YES];
    }
}

-(void)changeTextViewHeight:(NSString *)text
{
    if (self.chatSessionInputBarControl.menuContainerView==nil||self.chatSessionInputBarControl.menuContainerView.hidden==YES) {
        if (text.length!=0) {
            [self.chatSessionInputBarControl.inputTextView becomeFirstResponder];
            [self.chatSessionInputBarControl.inputTextView.delegate textViewDidChange:self.chatSessionInputBarControl.inputTextView];
        }
    }
    else
    {
        return;
    }
}
- (void)p_setupUnReadMessageView{
    if (_unReadButton !=nil) {
        [_unReadButton removeFromSuperview];
    }
    _unReadButton = [UIButton new];
    _unReadButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width-124,70,124, 36);
    [_unReadButton setBackgroundImage:[RCKitUtility imageNamed:@"up" ofBundle:@"RongCloud.bundle"] forState:UIControlStateNormal];
    self.unReadMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(10,0,0,self.unReadButton.frame.size.height)];
    NSString *stringUnread=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Right_unReadMessage",@"RongCloudKit",nil),(long)_unReadMessage];
    self.unReadMessageLabel.text = stringUnread;
    self.unReadMessageLabel.font=[UIFont systemFontOfSize:12.0];
    self.unReadMessageLabel.textColor=[UIColor colorWithRed:1/255.0f green:149/255.0f blue:255/255.0f alpha:1];
    self.unReadMessageLabel.textAlignment = NSTextAlignmentCenter;
    [_unReadButton addSubview:self.unReadMessageLabel];
    [_unReadButton addTarget:self action:@selector(didTipUnReadButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_unReadButton];
    [_unReadButton bringSubviewToFront:self.conversationMessageCollectionView];
    [self labelAdaptive:self.unReadMessageLabel];
}

- (void)labelAdaptive:(UILabel *)sender{
    CGRect rect = [sender.text boundingRectWithSize:CGSizeMake(2000,sender.frame.size.height) options:(NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.0f]} context:nil];
    CGRect temp = sender.frame;
    temp.size.width = rect.size.width;
    sender.frame = temp;
    CGRect temBut = self.unReadButton.frame;
    temBut.origin.x = self.view.frame.size.width-23-temp.size.width-10;
    temBut.size.width = temp.size.width + 5 + 10 + 23;
    self.unReadButton.frame = temBut;
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.unReadButton.frame)-23,13,11,CGRectGetHeight(_unReadButton.frame)-26)];
    imageView.image = [RCKitUtility imageNamed:@"arrow" ofBundle:@"RongCloud.bundle"];
    [self.unReadButton addSubview:imageView];
}


- (void)didTipUnReadButton:(UIButton *)sender{
    [sender removeFromSuperview];
    long lastMessageId = -1;
    if (self.conversationDataRepository.count > 0) {
        RCMessageModel *model = [self.conversationDataRepository objectAtIndex:0];
        lastMessageId = model.messageId;
    }
    NSArray *__messageArray =
    [[RCIMClient sharedRCIMClient] getHistoryMessages:_conversationType
                                             targetId:_targetId
                                      oldestMessageId:lastMessageId
                                                count:(int)self.unReadMessage - 10];
    for (int i = 0; i < __messageArray.count; i++) {
        RCMessage *rcMsg = [__messageArray objectAtIndex:i];
        RCMessageModel *model = [[RCMessageModel alloc] initWithMessage:rcMsg];
        [self pushOldMessageModel:model];
    }
    self.unReadMessage = 0;
    if (self.unReadButton != nil && self.enableUnreadMessageIcon) {
        RCOldMessageNotificationMessage *oldMessageTip=[[RCOldMessageNotificationMessage alloc] init];
        RCMessage *oldMessage = [[RCMessage alloc] initWithType:self.conversationType targetId:self.targetId direction:MessageDirection_SEND messageId:-1 content:oldMessageTip];
        RCMessageModel *model = [[RCMessageModel alloc] initWithMessage:oldMessage];
        RCMessageModel *lastMessageModel = [self.conversationDataRepository objectAtIndex:0];
        model.messageId = lastMessageModel.messageId;
        [self.conversationDataRepository insertObject:model atIndex:0];
        [self.unReadButton removeFromSuperview];
        self.unReadButton = nil;
    }

    [self figureOutAllConversationDataRepository];
    [self.conversationMessageCollectionView reloadData];
    [self.conversationMessageCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
    

}

- (void)viewDidAppear:(BOOL)animated {
  DebugLog(@"view=>%@", self.view);
  DebugLog(@"conversationMessageCollectionView=>%@",
           self.conversationMessageCollectionView);
  _isConversationAppear = YES;
  [[RCIMClient sharedRCIMClient] clearMessagesUnreadStatus:self.conversationType
                                                  targetId:self.targetId];
  //[self notifyUnReadMessageCount:[[RongIMClient
  // sharedClient]getTotalUnreadCount]];
  if (self.chatSessionInputBarControl.inputTextView.text
      && self.chatSessionInputBarControl.inputTextView.text.length > 0) {
    [self changeTextViewHeight:self.chatSessionInputBarControl.inputTextView.text];
  }
  self.navigationTitle = self.navigationItem.title;
  [[RCIMClient sharedRCIMClient]setRCTypingStatusDelegate:self];
}
- (void)viewWillDisappear:(BOOL)animated {
  [[RCSystemSoundPlayer defaultPlayer] resetIgnoreConversation];

  [[RCIMClient sharedRCIMClient] clearMessagesUnreadStatus:self.conversationType
                                                  targetId:self.targetId];

  [[NSNotificationCenter defaultCenter]
      postNotificationName:kNotificationStopVoicePlayer
                    object:nil];
  _isConversationAppear = NO;
    
   NSString *draft = [self.chatSessionInputBarControl.inputTextView.text
                       stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
   [[RCIMClient sharedRCIMClient] saveTextMessageDraft:self.conversationType
                                               targetId:self.targetId
                                                content:draft];
    
    //页面跳转之后输入框位置重新调整到初始位置
    CGRect chatInputBarRect = self.chatSessionInputBarControl.frame;
    CGRect collectionViewRect = self.conversationMessageCollectionView.frame;
    float bottomY = [self getBoardViewBottonOriginY];
  
    if (_emojiBoardView) {
        [self.emojiBoardView setHidden:YES];
    }
    if (_pluginBoardView) {
        [self.pluginBoardView setHidden:YES];
    }
    chatInputBarRect.origin.y =
    bottomY - self.chatSessionInputBarControl.bounds.size.height;
    _chatSessionInputBarControl.originalPositionY =
    self.view.bounds.size.height - (Height_ChatSessionInputBar);
    collectionViewRect.size.height =
    CGRectGetMinY(chatInputBarRect) - collectionViewRect.origin.y;
    [self.conversationMessageCollectionView setFrame:collectionViewRect];
    
    [self.chatSessionInputBarControl setFrame:chatInputBarRect];
    self.chatSessionInputBarControl.currentPositionY =
    self.chatSessionInputBarControl.frame.origin.y;

}
- (void)dealloc {
    [self quitConversationViewAndClear];
}

- (void)leftBarButtonItemPressed:(id)sender {
    [self quitConversationViewAndClear];
}

// 清理环境（退出讨论组、移除监听等）
- (void)quitConversationViewAndClear {
    if (!self.isClear) {
        if (self.conversationType == ConversationType_CHATROOM) {
            [[RCIMClient sharedRCIMClient] quitChatRoom:self.targetId
                                                success:^{
                                                    
                                                } error:^(RCErrorCode status) {
                                                    
                                                }];
        }
        if (self.conversationType == ConversationType_CUSTOMERSERVICE) {
            RCSuspendMessage *__message = [[RCSuspendMessage alloc] init];
            [[RCIMClient sharedRCIMClient] sendMessage:self.conversationType
                                              targetId:self.targetId
                                               content:__message
                                           pushContent:nil
                                               success:^(long messageId) {
                                                   
                                               } error:^(RCErrorCode nErrorCode, long messageId) {
                                                   
                                               }];
        }
        self.conversationMessageCollectionView.dataSource = nil;
        self.conversationMessageCollectionView.delegate = nil;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        self.isClear = YES;
        [[RCIMClient sharedRCIMClient]setRCTypingStatusDelegate:nil];
    }
}

- (void)initializedSubViews {
  // init collection view
  if (nil == self.conversationMessageCollectionView) {

    self.customFlowLayout = [[UICollectionViewFlowLayout alloc] init];
    _customFlowLayout.minimumLineSpacing = 0.0f;
    _customFlowLayout.sectionInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
    _customFlowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;

    self.view.backgroundColor = [UIColor whiteColor];
    CGRect _conversationViewFrame = self.view.bounds;

    CGFloat _conversationViewFrameY = 20.0f;
    if (self.navigationController &&
        self.navigationController.navigationBar.hidden == NO) {
      _conversationViewFrameY = 64.0f;
    }
      
      if (IOS_FSystenVersion < 7.0) {
          
          _conversationViewFrame.origin.y = 0;
      }else
      {
          _conversationViewFrame.origin.y = _conversationViewFrameY;
      }
      
    _conversationViewFrame.size.height = self.view.bounds.size.height -
                                         Height_ChatSessionInputBar -
                                         _conversationViewFrameY;

    self.conversationMessageCollectionView =
        [[UICollectionView alloc] initWithFrame:_conversationViewFrame
                           collectionViewLayout:self.customFlowLayout];
    [self.conversationMessageCollectionView
        setBackgroundColor:RGBCOLOR(235, 235, 235)];
    self.conversationMessageCollectionView.showsHorizontalScrollIndicator = NO;
    // self.conversationMessageCollectionView.showsVerticalScrollIndicator = NO;
    self.conversationMessageCollectionView.alwaysBounceVertical = YES;

    self.collectionViewHeader = [[RCConversationCollectionViewHeader alloc]
        initWithFrame:CGRectMake(0, -40, self.view.bounds.size.width, 40)];
    _collectionViewHeader.tag = 1999;
    [self.conversationMessageCollectionView addSubview:_collectionViewHeader];

    [self registerClass:[RCTextMessageCell class]
        forCellWithReuseIdentifier:rctextCellIndentifier];
    [self registerClass:[RCImageMessageCell class]
        forCellWithReuseIdentifier:rcimageCellIndentifier];
    [self registerClass:[RCVoiceMessageCell class]
        forCellWithReuseIdentifier:rcvoiceCellIndentifier];
    [self registerClass:[RCRichContentMessageCell class]
        forCellWithReuseIdentifier:rcrichCellIndentifier];
    [self registerClass:[RCLocationMessageCell class]
        forCellWithReuseIdentifier:rclocationCellIndentifier];
    [self registerClass:[RCTipMessageCell class]
        forCellWithReuseIdentifier:rcTipMessageCellIndentifier];
    // static NSString* const rcMPMsgCellIndentifier  =
    // @"rcMPMsgCellIndentifier";
    [self registerClass:[RCPublicServiceMultiImgTxtCell class]
        forCellWithReuseIdentifier:rcMPMsgCellIndentifier];
    [self registerClass:[RCPublicServiceImgTxtMsgCell class]
        forCellWithReuseIdentifier:rcMPSingleMsgCellIndentifier];
    [self registerClass:[RCUnknownMessageCell class]
        forCellWithReuseIdentifier:rcUnknownMessageCellIndentifier];
    [self registerClass:[RCOldMessageNotificationMessageCell class]
forCellWithReuseIdentifier:rcOldMessageNotificationMessageCellIndentifier];

    self.conversationMessageCollectionView.dataSource = self;
    self.conversationMessageCollectionView.delegate = self;

    [self.view addSubview:self.conversationMessageCollectionView];

    UITapGestureRecognizer *resetBottomTapGesture =
        [[UITapGestureRecognizer alloc]
            initWithTarget:self
                    action:@selector(tap4ResetDefaultBottomBarStatus:)];
    [resetBottomTapGesture setDelegate:self];
    [self.conversationMessageCollectionView
        addGestureRecognizer:resetBottomTapGesture];
  }
}

- (UIImageView *)unreadRightBottomIcon {
    if (!_unreadRightBottomIcon) {
        UIImage *msgCountIcon = [RCKitUtility imageNamed:@"conversation_item_unreadcount_icon" ofBundle:@"RongCloud.bundle"];
        
        _unreadRightBottomIcon = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, msgCountIcon.size.width, msgCountIcon.size.height)];
        _unreadRightBottomIcon.userInteractionEnabled = YES;
        _unreadRightBottomIcon.image = msgCountIcon;
        //        _unreadRightBottomIcon.translatesAutoresizingMaskIntoConstraints = NO;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tabRightBottomMsgCountIcon:)];
        [_unreadRightBottomIcon addGestureRecognizer:tap];
        _unreadRightBottomIcon.hidden = YES;
        [self.view addSubview:_unreadRightBottomIcon];
        _unreadRightBottomIcon.center = CGPointMake(self.view.frame.size.width - 25 - _unreadRightBottomIcon.frame.size.width/2, self.view.frame.size.height - Height_ChatSessionInputBar - _unreadRightBottomIcon.frame.size.height/2 - 8.0f);
    }
    return _unreadRightBottomIcon;
}

- (UILabel *)unReadNewMessageLabel {
    if (!_unReadNewMessageLabel) {
        _unReadNewMessageLabel = [[UILabel alloc]initWithFrame:_unreadRightBottomIcon.bounds];
        _unReadNewMessageLabel.backgroundColor = [UIColor clearColor];
        _unReadNewMessageLabel.font = [UIFont systemFontOfSize:12.0f];
        _unReadNewMessageLabel.textAlignment = NSTextAlignmentCenter;
        _unReadNewMessageLabel.textColor = [UIColor whiteColor];
        _unReadNewMessageLabel.center = CGPointMake(_unReadNewMessageLabel.frame.size.width/2, _unReadNewMessageLabel.frame.size.height/2 - 2 );
        [self.unreadRightBottomIcon addSubview:_unReadNewMessageLabel];
    }
    return _unReadNewMessageLabel;

}

- (RCChatSessionInputBarControl *)chatSessionInputBarControl {
    if (!_chatSessionInputBarControl) {
        RCChatSessionInputBarControlType inputBarType =
        RCChatSessionInputBarControlDefaultType;
        //        if (self.conversationType == ConversationType_APPSERVICE ||
        //            self.conversationType == ConversationType_PUBLICSERVICE) {
        //            inputBarType = RCChatSessionInputBarControlPubType;
        //        }
        
        _chatSessionInputBarControl = [[RCChatSessionInputBarControl alloc]
                                           initWithFrame:CGRectMake(0, self.view.bounds.size.height -
                                                                    Height_ChatSessionInputBar,
                                                                    self.view.bounds.size.width,
                                                                    Height_ChatSessionInputBar)
                                           withContextView:self.view
                                           type:inputBarType
                                           style:RC_CHAT_INPUT_BAR_STYLE_SWITCH_CONTAINER_EXTENTION];
        _chatSessionInputBarControl.delegate = self;
        _chatSessionInputBarControl.clientView = self.view;
        [self.view addSubview:_chatSessionInputBarControl];
        if (self.defaultInputType == RCChatSessionInputBarInputVoice) {
            _chatSessionInputBarControl.inputTextView.hidden = YES;
            _chatSessionInputBarControl.recordButton.hidden = NO;
        } else if (self.defaultInputType == RCChatSessionInputBarInputExtention) {
            [self layoutBottomBarWithStatus:KBottomBarPluginStatus];
        }
    }
    return _chatSessionInputBarControl;
}


- (RCEmojiBoardView *)emojiBoardView {
    if (!_emojiBoardView) {
        _emojiBoardView = [[RCEmojiBoardView alloc] initWithFrame:
                           CGRectMake(0, [self getBoardViewBottonOriginY],
                                      self.view.bounds.size.width, Height_EmojBoardView)];
         _emojiBoardView.hidden = YES;
        _emojiBoardView.delegate = self;
        [self.view addSubview:_emojiBoardView];
    }
    return _emojiBoardView;
}

- (RCPluginBoardView *)pluginBoardView {
    if (!_pluginBoardView) {
        _pluginBoardView = [[RCPluginBoardView alloc] initWithFrame:
                                CGRectMake(0, [self getBoardViewBottonOriginY],
                                           self.view.bounds.size.width, Height_PluginBoardView)];
        
        //添加底部多功能栏功能，可以根据需求自定义
        UIImage *imageCamera = [RCKitUtility imageNamed:@"actionbar_camera_icon"
                                               ofBundle:@"RongCloud.bundle"];
        UIImage *imagePic = [RCKitUtility imageNamed:@"actionbar_picture_icon"
                                            ofBundle:@"RongCloud.bundle"];
        UIImage *imageLocation = [RCKitUtility imageNamed:@"actionbar_location_icon"
                                                 ofBundle:@"RongCloud.bundle"];
#if RC_VOIP_ENABLE
        UIImage *imageVoIP = [RCKitUtility imageNamed:@"actionbar_call_icon"
                                             ofBundle:@"RongCloud.bundle"];
#endif
        
        [_pluginBoardView
         insertItemWithImage:imagePic
         title:NSLocalizedStringFromTable(@"Album",
                                          @"RongCloudKit", nil)
         atIndex:0
         tag:PLUGIN_BOARD_ITEM_ALBUM_TAG];
        [_pluginBoardView
         insertItemWithImage:imageCamera
         title:NSLocalizedStringFromTable(@"Photo",
                                          @"RongCloudKit", nil)
         atIndex:1
         tag:PLUGIN_BOARD_ITEM_CAMERA_TAG];
        [_pluginBoardView
         insertItemWithImage:imageLocation
         title:NSLocalizedStringFromTable(@"Location",
                                          @"RongCloudKit", nil)
         atIndex:2
         tag:PLUGIN_BOARD_ITEM_LOCATION_TAG];
#if RC_VOIP_ENABLE
        if (self.conversationType != ConversationType_GROUP &&
            self.conversationType != ConversationType_CUSTOMERSERVICE &&
            self.conversationType != ConversationType_DISCUSSION &&
            self.conversationType != ConversationType_APPSERVICE &&
            self.conversationType != ConversationType_PUBLICSERVICE &&
            self.conversationType != ConversationType_CHATROOM)
            [_pluginBoardView
             insertItemWithImage:imageVoIP
             title:NSLocalizedStringFromTable(@"Audio",
                                              @"RongCloudKit", nil)
             atIndex:3
             tag:PLUGIN_BOARD_ITEM_VOIP_TAG];
#endif
        _pluginBoardView.hidden = YES;
        _pluginBoardView.pluginBoardDelegate = self;
        [self.view addSubview:_pluginBoardView];
    }
    return _pluginBoardView;
}

- (float) getBoardViewBottonOriginY{
//    float gap = (IOS_FSystenVersion < 7.0) ? 64 : 0 ;
//    return [UIScreen mainScreen].bounds.size.height - gap;
        float gap = (IOS_FSystenVersion < 7.0) ? 64 : 0 ;
//        NSLog(@"%d",IS_HOTSPOT_CONNECTED);
        return IS_HOTSPOT_CONNECTED?[UIScreen mainScreen].bounds.size.height - gap-20:[UIScreen mainScreen].bounds.size.height - gap;
}

- (void)setDefaultInputType:(RCChatSessionInputBarInputType)defaultInputType {
  _defaultInputType = defaultInputType;
  if (defaultInputType == RCChatSessionInputBarInputVoice) {
    self.chatSessionInputBarControl.inputTextView.hidden = YES;
    self.chatSessionInputBarControl.recordButton.hidden = NO;
  } else if (self.defaultInputType == RCChatSessionInputBarInputExtention) {
    [self layoutBottomBarWithStatus:KBottomBarPluginStatus];
  }
}

//
- (void)updateUnreadMsgCountLabel
{
    if (self.unreadNewMsgCount == 0) {
        self.unreadRightBottomIcon.hidden = YES;
    }
    else
    {
        self.unreadRightBottomIcon.hidden = NO;
        self.unReadNewMessageLabel.text = (self.unreadNewMsgCount > 99) ?  @"99+" : [NSString stringWithFormat:@"%li", (long)self.unreadNewMsgCount];
    }
}

- (void) checkVisiableCell
{
    NSIndexPath *lastPath = [self getLastIndexPathForVisibleItems];
    
    if (lastPath.row >= self.conversationDataRepository.count - self.unreadNewMsgCount || lastPath == nil || [self isAtTheBottomOfTableView] ) {
        
        self.unreadNewMsgCount = 0;
        [self updateUnreadMsgCountLabel];
    }
}

- (NSIndexPath *)getLastIndexPathForVisibleItems
{
    NSArray *visiblePaths = [self.conversationMessageCollectionView indexPathsForVisibleItems];
    
    if (visiblePaths.count == 0) {
        return nil;
    }else if(visiblePaths.count == 1) {
        return (NSIndexPath *)[visiblePaths firstObject];
    }
    
    NSArray *sortedIndexPaths = [visiblePaths sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSIndexPath *path1 = (NSIndexPath *)obj1;
        NSIndexPath *path2 = (NSIndexPath *)obj2;
        return [path1 compare:path2];
    }];
    
   return (NSIndexPath *)[sortedIndexPaths lastObject];
}


#pragma mark -
#pragma mark RCLocationPickerViewControllerDelegate
/**
 *  选取位置后回调
 *
 *  @param locationPicker locationPicker description
 *  @param location       location description
 *  @param locationName   locationName description
 *  @param mapScreenShot  mapScreenShot description
 */
- (void)locationPicker:(RCLocationPickerViewController *)locationPicker
     didSelectLocation:(CLLocationCoordinate2D)location
          locationName:(NSString *)locationName
         mapScreenShot:(UIImage *)mapScreenShot {
  RCLocationMessage *locationMessage =
      [RCLocationMessage messageWithLocationImage:mapScreenShot
                                         location:location
                                     locationName:locationName];
  [self sendMessage:locationMessage pushContent:nil];
  [self.navigationController popViewControllerAnimated:YES];
}

/**
 *  打开相册
 *
 *  @param sender sender description
 */
- (void)openSystemAlbum:(id)sender {
  //    系统相册

  __block RCAlbumListViewController *albumListVC =
      [[RCAlbumListViewController alloc] init];
  albumListVC.delegate = self;
  UINavigationController *rootVC =
      [[UINavigationController alloc] initWithRootViewController:albumListVC];

  __weak typeof(&*self) weakself = self;
    
  RCAssetHelper *sharedAssetHelper = [RCAssetHelper shareAssetHelper];
  [sharedAssetHelper
      getGroupsWithALAssetsGroupType:ALAssetsGroupAll
                    resultCompletion:^(ALAssetsGroup *assetGroup) {
                      if (nil != assetGroup) {
                        NSString *groupName_ = [assetGroup
                            valueForProperty:ALAssetsGroupPropertyName];
                        NSLog(@"%@", groupName_);
                        [albumListVC.libraryList insertObject:assetGroup
                                                      atIndex:0];
                      } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                          [weakself.navigationController
                              presentViewController:rootVC
                                           animated:YES
                                         completion:^{

                                         }];
                        });
                      }
                    }];
}

/**
 *  打开相机
 *
 *  @param sender sender description
 */
- (void)openSystemCamera:(id)sender {
  UIImagePickerController *picker = [[UIImagePickerController alloc] init];
#if TARGET_IPHONE_SIMULATOR
  picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
#else
  picker.sourceType = UIImagePickerControllerSourceTypeCamera;

#endif
  self.curPicker = picker;
  self.curPicker.delegate = self;
  [self presentViewController:picker animated:YES completion:nil];
}

/**
 *  打开地理位置拾取器
 *
 *  @param sender sender description
 */
- (void)openLocationPicker:(id)sender {
  RCLocationPickerViewController *picker =
      [[RCLocationPickerViewController alloc] init];
  picker.delegate = self;
  //    picker.dataSource
  //    指定默认数据源，如有需求可以自定义数据源RCLocationPickerViewControllerDataSource
  [self.navigationController pushViewController:picker animated:YES];
}

/**
 *  打开语音通话功能界面
 *
 *  @param sender sender description
 */
#if RC_VOIP_ENABLE
- (void)openVoIP:(id)sender {
  [[RCIM sharedRCIM] startVoIPCallWithTargetId:self.targetId];
}
#endif

#pragma mark - UIImagePickerControllerDelegate method
//选择相册图片或者拍照回调
- (void)imagePickerController:(UIImagePickerController *)picker
        didFinishPickingImage:(UIImage *)image
                  editingInfo:(NSDictionary *)editingInfo {
  [picker dismissViewControllerAnimated:YES completion:nil];
  RCImageMessage *imageMessage = [RCImageMessage messageWithImage:image];

  _isTakeNewPhoto = YES;

  [self sendImageMessage:imageMessage pushContent:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark <UIScrollViewDelegate>
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  //[self resignKeyBoardAndResetCollectionViewFrame];
  if (_currentBottomBarStatus != KBottomBarDefaultStatus) {
    [self layoutBottomBarWithStatus:KBottomBarDefaultStatus];
  }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // 是否显示右下未读icon
    if (self.enableNewComingMessageIcon == YES || self.unreadNewMsgCount != 0) {
        [self checkVisiableCell];
    }
    
  if (scrollView.contentOffset.y < -5.0f) {
    [self.collectionViewHeader startAnimating];
  } else {
    //[h setBackgroundColor:[UIColor redColor]];
    [self.collectionViewHeader stopAnimating];
    _isLoading = NO;
  }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate {
  // DebugLog(@"===>scrollViewDidEndDragging ");

  // RCConversationTableHeaderView* h =
  // (RCConversationTableHeaderView*)[scrollView viewWithTag:1999];
  if (scrollView.contentOffset.y < -15.0f && !_isLoading) {
    _isLoading = YES;
    // DebugLog(@"===>load More...HistoryMessage ");

    [self performSelector:@selector(loadMoreHistoryMessage)
               withObject:nil
               afterDelay:0.4f];
    //[self loadMoreHistoryMessage];
  }
}
- (void)scrollToBottomAnimated:(BOOL)animated {

  if ([self.conversationMessageCollectionView numberOfSections] == 0) {
    return;
  }
  //[self.view layoutIfNeeded];

  // CGFloat collectionViewContentHeight =
  // [self.conversationMessageCollectionView.collectionViewLayout
  // collectionViewContentSize].height;

  //    if (self.conversationMessageCollectionView.bounds.size.height <
  //    collectionViewContentHeight) {
  //        self.automaticallyAdjustsScrollViewInsets = NO;
  //    }else
  //    {
  //        self.automaticallyAdjustsScrollViewInsets = YES;
  //    }
  //    BOOL isContentTooSmall = (collectionViewContentHeight <
  //    CGRectGetHeight(self.conversationMessageCollectionView.bounds));
  //
  //    if (isContentTooSmall) {
  //        //  workaround for the first few messages not scrolling
  //        //  when the collection view content size is too small,
  //        `scrollToItemAtIndexPath:` doesn't work properly
  //        //  this seems to be a UIKit bug, see #256 on GitHub
  //
  //        return;
  //    }

  //  workaround for really long messages not scrolling
  //  if last message is too long, use scroll position bottom for better
  //  appearance, else use top
  //  possibly a UIKit bug, see #480 on GitHub
  NSUInteger finalRow = MAX(
      0, [self.conversationMessageCollectionView numberOfItemsInSection:0] - 1);

  if (0 == finalRow) {
    return;
  }
  NSIndexPath *finalIndexPath =
      [NSIndexPath indexPathForItem:finalRow inSection:0];
  //[self.customFlowLayout layoutAttributesForItemAtIndexPath:finalIndexPath];

  [self.conversationMessageCollectionView
      scrollToItemAtIndexPath:finalIndexPath
             atScrollPosition:UICollectionViewScrollPositionBottom
                     animated:animated];
}

#pragma mark <UICollectionViewDataSource>
//定义展示的UICollectionViewCell的个数
- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
  return self.conversationDataRepository.count;
}

//每个UICollectionView展示的内容
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"path row is %d", indexPath.row);
  RCMessageModel *model =
      [self.conversationDataRepository objectAtIndex:indexPath.row];

  if (model.messageDirection == MessageDirection_RECEIVE) {
    model.isDisplayNickname = self.displayUserNameInCell;
  } else {
    model.isDisplayNickname = NO;
  }
  RCMessageContent *messageContent = model.content;
  RCMessageBaseCell *cell = nil;
  if ([messageContent isMemberOfClass:[RCTextMessage class]]) {
    RCMessageCell *__cell = [collectionView
        dequeueReusableCellWithReuseIdentifier:rctextCellIndentifier
                                  forIndexPath:indexPath];
    [__cell setDataModel:model];
    [__cell setDelegate:self];
    cell = __cell;
  } else if ([messageContent isMemberOfClass:[RCImageMessage class]]) {
    RCMessageCell *__cell = [collectionView
        dequeueReusableCellWithReuseIdentifier:rcimageCellIndentifier
                                  forIndexPath:indexPath];
    [__cell setDataModel:model];
    [__cell setDelegate:self];
    cell = __cell;
  } else if ([messageContent isMemberOfClass:[RCVoiceMessage class]]) {
    RCMessageCell *__cell = [collectionView
        dequeueReusableCellWithReuseIdentifier:rcvoiceCellIndentifier
                                  forIndexPath:indexPath];
    [__cell setDataModel:model];
    [__cell setDelegate:self];
    cell = __cell;
  } else if ([messageContent isMemberOfClass:[RCLocationMessage class]]) {
    RCMessageCell *__cell = [collectionView
        dequeueReusableCellWithReuseIdentifier:rclocationCellIndentifier
                                  forIndexPath:indexPath];
    [__cell setDataModel:model];
    [__cell setDelegate:self];
    cell = __cell;
  } else if ([messageContent isMemberOfClass:[RCRichContentMessage class]]) {
    RCMessageCell *__cell = [collectionView
        dequeueReusableCellWithReuseIdentifier:rcrichCellIndentifier
                                  forIndexPath:indexPath];
    [__cell setDataModel:model];
    [__cell setDelegate:self];
    cell = __cell;
  } else if ([messageContent
                 isMemberOfClass:[RCDiscussionNotificationMessage class]] ||
             [messageContent
                 isMemberOfClass:[RCInformationNotificationMessage class]]) {
    RCMessageCell *__cell = [collectionView
        dequeueReusableCellWithReuseIdentifier:rcTipMessageCellIndentifier
                                  forIndexPath:indexPath];
    [__cell setDataModel:model];
    [__cell setDelegate:self];
    cell = __cell;
  } else if ([messageContent
                 isMemberOfClass:
                     [RCPublicServiceMultiRichContentMessage class]]) {
    RCPublicServiceMultiImgTxtCell *__cell = [collectionView
        dequeueReusableCellWithReuseIdentifier:rcMPMsgCellIndentifier
                                  forIndexPath:indexPath];
    [__cell setDataModel:model];
    [__cell setPublicServiceDelegate:(id<RCPublicServiceMessageCellDelegate>)self];
    cell = __cell;
  } else if ([messageContent
                 isMemberOfClass:[RCPublicServiceRichContentMessage class]]) {
    RCPublicServiceImgTxtMsgCell *__cell = [collectionView
        dequeueReusableCellWithReuseIdentifier:rcMPSingleMsgCellIndentifier
                                  forIndexPath:indexPath];
    [__cell setDataModel:model];
    [__cell setPublicServiceDelegate:(id<RCPublicServiceMessageCellDelegate>)self];

    cell = __cell;
  } else if ([messageContent
            isMemberOfClass:[RCOldMessageNotificationMessage class]]) {
      RCMessageCell *__cell = [collectionView
                               dequeueReusableCellWithReuseIdentifier:rcOldMessageNotificationMessageCellIndentifier
                               forIndexPath:indexPath];
      [__cell setDataModel:model];
      cell = __cell;
  } else if (!messageContent && [RCIM sharedRCIM].showUnkownMessage) {
      cell = [self rcUnkownConversationCollectionView:collectionView
                               cellForItemAtIndexPath:indexPath];
      [cell setDelegate:self];
  } else {
    cell = [self rcConversationCollectionView:collectionView
                       cellForItemAtIndexPath:indexPath];
      [cell setDelegate:self];
  }

  if ([RCIM sharedRCIM].enableReadReceipt) {
      cell.isDisplayReadStatus = YES;
  }
  //接口向后兼容 [[++
  [self performSelector:@selector(willDisplayConversationTableCell:atIndexPath:) withObject:cell withObject:indexPath];
  //接口向后兼容 --]]
  [self willDisplayMessageCell:cell atIndexPath:indexPath];
  return cell;
}

#pragma mark <UICollectionViewDelegateFlowLayout>

//计算cell高度，未实现完成
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  // DebugLog(@"call for index %@", indexPath);
  RCMessageModel *model =
      [self.conversationDataRepository objectAtIndex:indexPath.row];
  if (model.cellSize.height > 0) {
    return model.cellSize;
  }
  RCMessageContent *messageContent = model.content;
  if ([messageContent isMemberOfClass:[RCTextMessage class]] ||
      [messageContent isMemberOfClass:[RCImageMessage class]] ||
      [messageContent isMemberOfClass:[RCVoiceMessage class]] ||
      [messageContent isMemberOfClass:[RCLocationMessage class]] ||
      [messageContent isMemberOfClass:[RCRichContentMessage class]]||
      [messageContent isMemberOfClass:[RCInformationNotificationMessage class]] ||
      [messageContent
          isMemberOfClass:[RCDiscussionNotificationMessage class]]) {

    // RCMessageCollectionViewFlowLayout *customCollectionViewLayout =
    // (RCMessageCollectionViewFlowLayout *)collectionViewLayout;
    // customCollectionViewLayout.messageContent = messageContent;
    model.cellSize = [self sizeForItem:collectionView atIndexPath:indexPath];
  } else if ([messageContent
                 isMemberOfClass:
                     [RCPublicServiceMultiRichContentMessage class]]) {
    CGFloat height = [RCPublicServiceMultiImgTxtCell
        getCellHeight:(RCPublicServiceMultiRichContentMessage *)messageContent
            withWidth:self.conversationMessageCollectionView.frame.size.width];

    if (model.isDisplayMessageTime) {
      height += 30;
    }
      height += 20;
    model.cellSize = CGSizeMake(collectionView.frame.size.width, height);
  } else if ([messageContent
                 isMemberOfClass:[RCPublicServiceRichContentMessage class]]) {
    CGFloat height = [RCPublicServiceImgTxtMsgCell
        getCellHeight:model
            withWidth:self.conversationMessageCollectionView.frame.size.width];

    if (model.isDisplayMessageTime) {
      height += 30;
    }
    model.cellSize = CGSizeMake(collectionView.frame.size.width, height);
  } else if ([messageContent
            isMemberOfClass:[RCOldMessageNotificationMessage class]]) {
      model.cellSize = CGSizeMake(collectionView.frame.size.width, 40);
  } else if (!messageContent && [RCIM sharedRCIM].showUnkownMessage) {
      CGSize _size = [self rcUnkownConversationCollectionView:collectionView
                                                       layout:collectionViewLayout
                                       sizeForItemAtIndexPath:indexPath];
      DebugLog(@"%@", NSStringFromCGSize(_size));
      
      if (model.isDisplayMessageTime) {
          _size.height += 30;
      }
      return _size;
  } else {
    CGSize _size = [self rcConversationCollectionView:collectionView
                                               layout:collectionViewLayout
                               sizeForItemAtIndexPath:indexPath];
    DebugLog(@"%@", NSStringFromCGSize(_size));

    if (model.isDisplayMessageTime) {
      _size.height += 30;
    }
    return _size;
  }
  return model.cellSize;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                             layout:
                                 (UICollectionViewLayout *)collectionViewLayout
    referenceSizeForHeaderInSection:(NSInteger)section {
  // show showLoadEarlierMessagesHeader
  return CGSizeZero;
}

#pragma mark <UICollectionViewDelegate>
// UICollectionView被选中时调用的方法
- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)figureOutAllConversationDataRepository {
  for (int i = 0; i < self.conversationDataRepository.count; i++) {
    RCMessageModel *model = [self.conversationDataRepository objectAtIndex:i];
    if (0 == i) {
      model.isDisplayMessageTime = YES;
    } else if (i > 0) {
      RCMessageModel *pre_model =
          [self.conversationDataRepository objectAtIndex:i - 1];
      RCMessageDirection pre_messageDirection = pre_model.messageDirection;
      long long previous_time = (pre_messageDirection == MessageDirection_SEND)
                                    ? pre_model.sentTime
                                    : pre_model.receivedTime;

      RCMessageDirection current_messageDirection = model.messageDirection;
      long long current_time =
          (current_messageDirection == MessageDirection_SEND)
              ? model.sentTime
              : model.receivedTime;

      long long interval = current_time - previous_time > 0
                               ? current_time - previous_time
                               : previous_time - current_time;
      if (interval / 1000 <= 60) {
          if (model.isDisplayMessageTime) {
              CGSize size = model.cellSize;
              size.height = model.cellSize.height-30;
              model.cellSize = size;
          }
        model.isDisplayMessageTime = NO;
      } else {
        model.isDisplayMessageTime = YES;
      }
    }
      if ([model.content isKindOfClass:[RCOldMessageNotificationMessage class]]) {
          model.isDisplayMessageTime = NO;
      }
  }
}
- (void)figureOutLatestModel:(RCMessageModel *)model;
{
  if (_conversationDataRepository.count > 0) {

    RCMessageModel *pre_model = [self.conversationDataRepository
        objectAtIndex:_conversationDataRepository.count - 1];
    RCMessageDirection pre_messageDirection = pre_model.messageDirection;
    long long previous_time = (pre_messageDirection == MessageDirection_SEND)
                                  ? pre_model.sentTime
                                  : pre_model.receivedTime;

    RCMessageDirection current_messageDirection = model.messageDirection;
    long long current_time = (current_messageDirection == MessageDirection_SEND)
                                 ? model.sentTime
                                 : model.receivedTime;

    long long interval = current_time - previous_time > 0
                             ? current_time - previous_time
                             : previous_time - current_time;
    if (interval / 1000 <= 60) {
      model.isDisplayMessageTime = NO;
    } else {
      model.isDisplayMessageTime = YES;
    }

  } else {
    model.isDisplayMessageTime = YES;
  }
}

- (void)appendAndDisplayMessage:(RCMessage *)rcMessage {
  if (!rcMessage) {
    return;
  }
  RCMessageModel *model = [[RCMessageModel alloc] initWithMessage:rcMessage];
  [self figureOutLatestModel:model];
  if ([self appendMessageModel:model]) {
    self.sendOrReciveMessageNum++;//记录新收到和自己新发送的消息数，用于计算加载历史消息时插入“以上是历史消息”cell 的位置
    NSIndexPath *indexPath =
        [NSIndexPath indexPathForItem:self.conversationDataRepository.count - 1
                            inSection:0];
    if ([self.conversationMessageCollectionView numberOfItemsInSection:0] !=
        self.conversationDataRepository.count - 1) {
      NSLog(@"Error, datasource and collectionview are inconsistent!!");
      [self.conversationMessageCollectionView reloadData];
      return;
    }
    [self.conversationMessageCollectionView
        insertItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
    //[self.conversationMessageCollectionView reloadData];
//    [self.conversationMessageCollectionView
//            .collectionViewLayout invalidateLayout];

      if ([self isAtTheBottomOfTableView] || self.isNeedScrollToButtom) {
         [self scrollToBottomAnimated:YES];
         self.isNeedScrollToButtom=NO;
    }
  }
}

- (BOOL)appendMessageModel:(RCMessageModel *)model {
  long newId = model.messageId;
  for (RCMessageModel *__item in self.conversationDataRepository) {

    /*
     * 当id为－1时，不检查是否重复，直接插入
     * 该场景用于插入临时提示。
     */
    if (newId == -1) {
      break;
    }
    if (newId == __item.messageId) {
      return NO;
    }
  }

  if (newId != -1
      && !(!model.content && model.messageId > 0 && [RCIM sharedRCIM].showUnkownMessage)
      && !([[model.content class] persistentFlag] & MessagePersistent_ISPERSISTED)) {
    return NO;
  }
  //    if ([model.content respondsToSelector:@selector(presentInConversation)])
  //    {
  //        if (![model.content
  //        performSelector:@selector(presentInConversation)])
  //            return NO;
  //    }
  if (model.messageDirection == MessageDirection_RECEIVE) {
    model.isDisplayNickname = self.displayUserNameInCell;
  } else {
    model.isDisplayNickname = NO;
  }
  [self.conversationDataRepository addObject:model];
  return YES;
}

- (void)pushOldMessageModel:(RCMessageModel *)model {
  if (!(!model.content && model.messageId > 0 && [RCIM sharedRCIM].showUnkownMessage)
      && !([[model.content class] persistentFlag] & MessagePersistent_ISPERSISTED)) {
    return;
  }
  //    if ([model.content respondsToSelector:@selector(presentInConversation)])
  //    {
  //        if (![model.content
  //        performSelector:@selector(presentInConversation)])
  //            return;
  //    }

  long ne_wId = model.messageId;
  for (RCMessageModel *__item in self.conversationDataRepository) {

    if (ne_wId == __item.messageId) {
      return;
    }
  }
  if (model.messageDirection == MessageDirection_RECEIVE) {
    model.isDisplayNickname = self.displayUserNameInCell;
  } else {
    model.isDisplayNickname = NO;
  }
  [self.conversationDataRepository insertObject:model atIndex:0];
}

- (void)loadLatestHistoryMessage {
  NSArray *__messageArray =
      [[RCIMClient sharedRCIMClient] getLatestMessages:self.conversationType
                                              targetId:self.targetId
                                                 count:10];
//  long long lastReceiveMessageSendTime = 0;
  for (int i = 0; i < __messageArray.count; i++) {
    RCMessage *rcMsg = [__messageArray objectAtIndex:i];
    RCMessageModel *model = [[RCMessageModel alloc] initWithMessage:rcMsg];
//      if (model.messageDirection == MessageDirection_RECEIVE && lastReceiveMessageSendTime ==0) {
//          lastReceiveMessageSendTime = model.sentTime;
//      }
    [self pushOldMessageModel:model];
  }

  [self figureOutAllConversationDataRepository];
  [self.conversationMessageCollectionView reloadData];
}
- (void)loadMoreHistoryMessage {
  long lastMessageId = -1;
  if (self.conversationDataRepository.count > 0) {
    RCMessageModel *model = [self.conversationDataRepository objectAtIndex:0];
    lastMessageId = model.messageId;
  }

  NSArray *__messageArray =
      [[RCIMClient sharedRCIMClient] getHistoryMessages:_conversationType
                                               targetId:_targetId
                                        oldestMessageId:lastMessageId
                                                  count:10];
  for (int i = 0; i < __messageArray.count; i++) {
    RCMessage *rcMsg = [__messageArray objectAtIndex:i];
    RCMessageModel *model = [[RCMessageModel alloc] initWithMessage:rcMsg];
    [self pushOldMessageModel:model];
  }

 
    self.scrollNum++;
    if (self.scrollNum * 10 + 10> self.unReadMessage) {
        
        if (self.unReadButton != nil && self.enableUnreadMessageIcon) {
            NSInteger index = self.conversationDataRepository.count - self.sendOrReciveMessageNum - self.unReadMessage ;
            
            if (self.conversationDataRepository.count>index) {
                RCOldMessageNotificationMessage *oldMessageTip=[[RCOldMessageNotificationMessage alloc] init];
                RCMessage *oldMessage = [[RCMessage alloc] initWithType:self.conversationType targetId:self.targetId direction:MessageDirection_SEND messageId:-1 content:oldMessageTip];
                RCMessageModel *model = [[RCMessageModel alloc] initWithMessage:oldMessage];
                RCMessageModel *lastMessageModel = [self.conversationDataRepository objectAtIndex:index];
                model.messageId = lastMessageModel.messageId;
                [self.conversationDataRepository insertObject:model atIndex:index];
            }
            
            [self.unReadButton removeFromSuperview];
            self.unReadButton = nil;
        }
        self.unReadMessage = 0;
        
    }
    [self figureOutAllConversationDataRepository];
    [self.conversationMessageCollectionView reloadData];
    
      if (_conversationDataRepository != nil &&
          _conversationDataRepository.count > 0 &&
          [self.conversationMessageCollectionView numberOfItemsInSection:0] >=
              __messageArray.count - 1) {
        NSIndexPath *indexPath =
            [NSIndexPath indexPathForRow:__messageArray.count - 1 inSection:0];
        [self.conversationMessageCollectionView
            scrollToItemAtIndexPath:indexPath
                   atScrollPosition:UICollectionViewScrollPositionTop
                           animated:NO];
      }
}

- (void)willDisplayMessageCell:(RCMessageBaseCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
}

//历史遗留接口
- (void)willDisplayConversationTableCell:(RCMessageBaseCell *)cell
                             atIndexPath:(NSIndexPath *)indexPath {
  //    if (indexPath.row %2 == 0) {
  //        cell.backgroundColor = [UIColor redColor];
  //    }
  //    else{
  //        cell.backgroundColor = [UIColor yellowColor];
  //    }
}

- (RCMessageBaseCell *)rcConversationCollectionView:
                           (UICollectionView *)collectionView
                             cellForItemAtIndexPath:(NSIndexPath *)indexPath {

  RCMessageModel *model =
      [self.conversationDataRepository objectAtIndex:indexPath.row];
  // RCMessageContent *messageContent = model.content;
  RCMessageCell *__cell = [collectionView
      dequeueReusableCellWithReuseIdentifier:rcUnknownMessageCellIndentifier
                                forIndexPath:indexPath];
  [__cell setDataModel:model];
  return __cell;
}

- (CGSize)
rcConversationCollectionView:(UICollectionView *)collectionView
                      layout:(UICollectionViewLayout *)collectionViewLayout
      sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  RCMessageModel *model =
      [self.conversationDataRepository objectAtIndex:indexPath.row];
  CGFloat __width = CGRectGetWidth(collectionView.frame);
  CGFloat __height = 0;
  CGFloat maxMessageLabelWidth = __width - 30 * 2;
  NSString *localizedMessage = NSLocalizedStringFromTable(
      @"unknown_message_cell_tip", @"RongCloudKit", nil);
  // ios 7
//  CGSize __textSize =
//      [localizedMessage
//          boundingRectWithSize:CGSizeMake(maxMessageLabelWidth, 2000)
//                       options:NSStringDrawingTruncatesLastVisibleLine |
//                               NSStringDrawingUsesLineFragmentOrigin |
//                               NSStringDrawingUsesFontLeadingbavi
//                    attributes:@{
//                      NSFontAttributeName : [UIFont systemFontOfSize:16]
//                    } context:nil]
//          .size;
//    CGSize __textSize = RC_MULTILINE_TEXTSIZE(localizedMessage, [UIFont systemFontOfSize:16], CGSizeMake(maxMessageLabelWidth, 2000), NSLineBreakByTruncatingTail);
    CGSize __textSize = CGSizeZero;
    if (IOS_FSystenVersion < 7.0) {
        __textSize = RC_MULTILINE_TEXTSIZE_LIOS7(localizedMessage, [UIFont systemFontOfSize:16], CGSizeMake(maxMessageLabelWidth, 2000), NSLineBreakByTruncatingTail);
    }else {
        __textSize = RC_MULTILINE_TEXTSIZE_GEIOS7(localizedMessage, [UIFont systemFontOfSize:16], CGSizeMake(maxMessageLabelWidth, 2000));
    }


    
  __textSize = CGSizeMake(ceilf(__textSize.width), ceilf(__textSize.height));
  CGSize __labelSize = CGSizeMake(__textSize.width + 5, __textSize.height + 5);

  //上边距
  __height = __height + 10;

  if (model.isDisplayMessageTime) {
    __height = __height + 20 + 10;
  }
  __height = __height + __labelSize.height;
  //下边距
  __height = __height + 10;

  return CGSizeMake(collectionView.bounds.size.width, 65);
}

- (RCMessageBaseCell *)rcUnkownConversationCollectionView:(UICollectionView *)collectionView
                             cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    RCMessageModel *model =
    [self.conversationDataRepository objectAtIndex:indexPath.row];
    // RCMessageContent *messageContent = model.content;
    RCMessageCell *__cell = [collectionView
                             dequeueReusableCellWithReuseIdentifier:rcUnknownMessageCellIndentifier
                             forIndexPath:indexPath];
    [__cell setDataModel:model];
    return __cell;
}

- (CGSize)rcUnkownConversationCollectionView:(UICollectionView *)collectionView
                                      layout:(UICollectionViewLayout *)collectionViewLayout
                      sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    RCMessageModel *model =
    [self.conversationDataRepository objectAtIndex:indexPath.row];
    CGFloat __width = CGRectGetWidth(collectionView.frame);
    CGFloat __height = 0;
    CGFloat maxMessageLabelWidth = __width - 30 * 2;
    NSString *localizedMessage = NSLocalizedStringFromTable(
                                                            @"unknown_message_cell_tip", @"RongCloudKit", nil);
    // ios 7
    //  CGSize __textSize =
    //      [localizedMessage
    //          boundingRectWithSize:CGSizeMake(maxMessageLabelWidth, 2000)
    //                       options:NSStringDrawingTruncatesLastVisibleLine |
    //                               NSStringDrawingUsesLineFragmentOrigin |
    //                               NSStringDrawingUsesFontLeadingbavi
    //                    attributes:@{
    //                      NSFontAttributeName : [UIFont systemFontOfSize:16]
    //                    } context:nil]
    //          .size;
    //    CGSize __textSize = RC_MULTILINE_TEXTSIZE(localizedMessage, [UIFont systemFontOfSize:16], CGSizeMake(maxMessageLabelWidth, 2000), NSLineBreakByTruncatingTail);
    CGSize __textSize = CGSizeZero;
    if (IOS_FSystenVersion < 7.0) {
        __textSize = RC_MULTILINE_TEXTSIZE_LIOS7(localizedMessage, [UIFont systemFontOfSize:16], CGSizeMake(maxMessageLabelWidth, 2000), NSLineBreakByTruncatingTail);
    }else {
        __textSize = RC_MULTILINE_TEXTSIZE_GEIOS7(localizedMessage, [UIFont systemFontOfSize:16], CGSizeMake(maxMessageLabelWidth, 2000));
    }
    
    
    
    __textSize = CGSizeMake(ceilf(__textSize.width), ceilf(__textSize.height));
    CGSize __labelSize = CGSizeMake(__textSize.width + 5, __textSize.height + 5);
    
    //上边距
    __height = __height + 10;
    
    if (model.isDisplayMessageTime) {
        __height = __height + 20 + 10;
    }
    __height = __height + __labelSize.height;
    //下边距
    __height = __height + 10;
    
    return CGSizeMake(collectionView.bounds.size.width, 65);
}

//点击cell
- (void)didTapMessageCell:(RCMessageModel *)model {
  DebugLog(@"%s", __FUNCTION__);
  if (nil == model) {
    return;
  }

  RCMessageContent *_messageContent = model.content;

  if ([_messageContent isMemberOfClass:[RCImageMessage class]]) {
    [self presentImagePreviewController:model];

  } else if ([_messageContent isMemberOfClass:[RCVoiceMessage class]]) {
    for (RCMessageModel *msg in self.conversationDataRepository) {
      if (model.messageId == msg.messageId) {
        msg.receivedStatus = ReceivedStatus_LISTENED;
        break;
      }
    }
  } else if ([_messageContent isMemberOfClass:[RCLocationMessage class]]) {
    // Show the location view controller
    RCLocationMessage *locationMessage = (RCLocationMessage *)(_messageContent);
    [self presentLocationViewController:locationMessage];
  } else if ([_messageContent isMemberOfClass:[RCTextMessage class]]) {
    // link

    // phoneNumber
  }
}

- (void)didTapUrlInMessageCell:(NSString *)url model:(RCMessageModel *)model {
  NSString *urlStr =
      [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr]];
    
    UIViewController *vc = [[RCIMClient sharedRCIMClient] getPublicServiceWebViewController:urlStr];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)didTapPhoneNumberInMessageCell:(NSString *)phoneNumber
                                 model:(RCMessageModel *)model {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
}

//点击头像
- (void)didTapCellPortrait:(NSString *)userId{
}
/**
 *  长按头像事件
 *
 *  @param userId 用户的ID
 */
- (void)didLongPressCellPortrait:(NSString *)userId {
}

//长按消息内容
- (void)didLongTouchMessageCell:(RCMessageModel *)model inView:(UIView *)view {
  self.chatSessionInputBarControl.inputTextView.disableActionMenu = YES;
  self.longPressSelectedModel = model;

  CGRect rect = [self.view convertRect:view.frame fromView:view.superview];

  UIMenuController *menu = [UIMenuController sharedMenuController];
  UIMenuItem *copyItem = [[UIMenuItem alloc]
      initWithTitle:NSLocalizedStringFromTable(@"Copy", @"RongCloudKit", nil)
             action:@selector(onCopyMessage:)];
  UIMenuItem *deleteItem = [[UIMenuItem alloc]
      initWithTitle:NSLocalizedStringFromTable(@"Delete", @"RongCloudKit", nil)
             action:@selector(onDeleteMessage:)];
  if ([model.content isMemberOfClass:[RCTextMessage class]]) {

    [menu setMenuItems:[NSArray arrayWithObjects:copyItem, deleteItem, nil]];
  } else {
    [menu setMenuItems:@[ deleteItem ]];
  }
  [menu setTargetRect:rect inView:self.view];
  [menu setMenuVisible:YES animated:YES];
}

/**
 *  UIResponder
 *
 *  @return
 */
- (BOOL)canBecomeFirstResponder {
  return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
  return [super canPerformAction:action withSender:sender];
}

- (NSInteger)findDataIndexFromMessageList:(RCMessageModel *)model {
  NSInteger index = 0;
  for (int i = 0; i < self.conversationDataRepository.count; i++) {
    RCMessageModel *msg = (self.conversationDataRepository)[i];
    if (msg.messageId == model.messageId &&  ![msg.content isKindOfClass:[RCOldMessageNotificationMessage class]]) {
      index = i;
      break;
    }
  }
  return index;
}
- (void)resendMessage:(RCMessageContent *)messageContent {
    if ([messageContent isMemberOfClass:RCImageMessage.class]) {
        RCImageMessage *imageMessage = (RCImageMessage *)messageContent;
        imageMessage.originalImage = [UIImage imageWithContentsOfFile:imageMessage.imageUrl];
        [self sendImageMessage:imageMessage pushContent:nil];
    } else {
        [self sendMessage:messageContent pushContent:nil];
    }
}

- (void)didTapmessageFailedStatusViewForResend:(RCMessageModel *)model {
  // resending message.
  DebugLog(@"%s", __FUNCTION__);

  RCMessageContent *content = model.content;
  long msgId = model.messageId;
  NSIndexPath *indexPath =
      [NSIndexPath indexPathForItem:[self findDataIndexFromMessageList:model]
                          inSection:0];
  [[RCIMClient sharedRCIMClient] deleteMessages:@[ @(msgId) ]];
  [self.conversationDataRepository removeObject:model];
  [self.conversationMessageCollectionView
      deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];

    self.isNeedScrollToButtom=YES;
  [self resendMessage:content];
}

/**
 *  打开大图。开发者可以重写，自己下载并且展示图片。默认使用内置controller
 *
 *  @param imageMessageContent 图片消息内容
 */
- (void)presentImagePreviewController:(RCMessageModel *)model;
{
  RCImagePreviewController *_imagePreviewVC =
      [[RCImagePreviewController alloc] init];
  _imagePreviewVC.messageModel = model;

  UINavigationController *nav = [[UINavigationController alloc]
      initWithRootViewController:_imagePreviewVC];

  if (self.navigationController) {
    //导航和原有的配色保持一直
    UIImage *image = [self.navigationController.navigationBar
        backgroundImageForBarMetrics:UIBarMetricsDefault];

    [nav.navigationBar setBackgroundImage:image
                            forBarMetrics:UIBarMetricsDefault];
  }

  [self presentViewController:nav animated:YES completion:nil];
}

/**
 *  打开地理位置。开发者可以重写，自己根据经纬度打开地图显示位置。默认使用内置地图
 *
 *  @param locationMessageCotent 位置消息
 */
- (void)presentLocationViewController:
    (RCLocationMessage *)locationMessageContent {
  //默认方法跳转
  RCLocationViewController *locationViewController =
      [[RCLocationViewController alloc] init];
  locationViewController.locationName = locationMessageContent.locationName;
  locationViewController.location = locationMessageContent.location;
  UINavigationController *navc = [[UINavigationController alloc]
      initWithRootViewController:locationViewController];
  if (self.navigationController) {
    //导航和原有的配色保持一直
    UIImage *image = [self.navigationController.navigationBar
        backgroundImageForBarMetrics:UIBarMetricsDefault];

    [navc.navigationBar setBackgroundImage:image
                             forBarMetrics:UIBarMetricsDefault];
  }
  [self presentViewController:navc animated:YES completion:NULL];
}

//- (void)postNotificationForSendingMessageWithStatus:(NSString *)status
// progress:(NSNumber *)progress withDebugText:(NSString *)debugText
// messageID:(long)messageId
//{
//    NSDictionary *_userInfo = nil;
//
//    if (nil == progress) {
//        _userInfo = @{NotificationType: status, @"DebugText":debugText,
//        @"messageid":@(messageId)};
//    }else{
//        _userInfo = @{NotificationType: status, ProgressValueKey:progress};
//    }
//
//
//    [[NSNotificationCenter
//    defaultCenter]postNotificationName:KNotificationMessageBaseCellUpdateSendingStatus
//    object:nil userInfo:_userInfo];
//}

///**
// *  发送消息
// *
// *  @param messageCotent 只支持imkit内置消息
// */
//static const NSUInteger RC_APNS_Fixed_Length = 38;
//static const NSUInteger RC_Max_Alert_Length = 48;
//static const NSUInteger RC_Max_Budge_Length = 3;
//
//- (NSString *)getPushContent:(RCMessageContent *)messageContent {
//    NSString *pushContent = @"";
//    @try {
//        NSString *showMessage = [RCKitUtility formatMessage:messageContent];
//        NSString *senderName = nil;
//        RCUserInfo *userInfo = [[RCUserInfoLoader sharedUserInfoLoader] loadUserInfo:[RCIMClient sharedRCIMClient].currentUserInfo.userId observer:nil];
//        if ((ConversationType_GROUP == self.conversationType)) {
////            RCGroup *group = [[RCGroupLoader shareInstance] loadGroupByGroupId:self.targetId observer:nil];
//            RCUserInfo *groupUserInfo = [[RCUserInfoLoader sharedUserInfoLoader] loadGroupUserInfo:[RCIMClient sharedRCIMClient].currentUserInfo.userId groupId:self.targetId observer:nil];
//            if (groupUserInfo.name.length) {
//                userInfo = groupUserInfo;
//            }
//            
////            NSString *abbrGroupName = group.groupName;
////            if (abbrGroupName.length > 15) {
////                abbrGroupName = [NSString stringWithFormat:@"%@...", [abbrGroupName substringToIndex:12]];
////            }
////            
////            if (userInfo.name.length && group.groupName.length) {
////                senderName = [NSString stringWithFormat:@"%@(%@)", userInfo.name, abbrGroupName];
////            } else if (userInfo.name.length) {
//                senderName = userInfo.name;
////            } else if (group.groupName.length) {
////                senderName = abbrGroupName;
////            }
//        } else if (ConversationType_DISCUSSION == self.conversationType) {
////            NSString *abbrDiscussionName = self.currentDiscussion.discussionName;
////            if (abbrDiscussionName.length > 15) {
////                abbrDiscussionName = [NSString stringWithFormat:@"%@...", [abbrDiscussionName substringToIndex:12]];
////            }
////            if (userInfo.name.length && self.currentDiscussion.discussionName.length) {
////                senderName = [NSString stringWithFormat:@"%@(%@)", userInfo.name, abbrDiscussionName];
////            } else if (userInfo.name.length) {
//                senderName = userInfo.name;
////            } else if (abbrDiscussionName) {
////                senderName = abbrDiscussionName;
////            }
//        } else if (ConversationType_PRIVATE == self.conversationType ||
//                   ConversationType_CUSTOMERSERVICE == self.conversationType ||
//                   ConversationType_APPSERVICE == self.conversationType ||
//                   ConversationType_PUBLICSERVICE == self.conversationType ||
//                   ConversationType_SYSTEM == self.conversationType){
//            
//            senderName = userInfo.name;
//        }
//        
//        if (senderName.length) {
//            NSDictionary *notificationDict = [RCKitUtility getNotificationUserInfoDictionary:self.conversationType
//                                                                                  fromUserId:[RCIMClient sharedRCIMClient].currentUserInfo.userId
//                                                                                    targetId:self.targetId
//                                                                              messageContent:messageContent];
//            NSData *data = [NSJSONSerialization dataWithJSONObject:notificationDict options:kNilOptions error:nil];
//            NSString *notificationString  = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//            
//            DebugLog(@"the notification string is %@", notificationString);
//            NSUInteger maxLength = 256 - RC_APNS_Fixed_Length - RC_Max_Alert_Length - RC_Max_Budge_Length - notificationString.length;
//            
//            if (senderName.length + showMessage.length + 1 > maxLength) {
//                if (maxLength - senderName.length > 11) {
//                    showMessage = [showMessage substringToIndex:(maxLength - senderName.length - 4)];
//                    pushContent = [NSString stringWithFormat:@"%@:%@...", senderName, showMessage];
//                } else if (maxLength > 7) {
//                    pushContent = @"你有一条新消息";
//                }
//            } else {
//                pushContent = [NSString stringWithFormat:@"%@:%@", senderName, showMessage];
//            }
//        }
//    }
//    @catch (NSException *exception) {
//        pushContent = @"";
//    }
//    return pushContent;
//}

- (void)updateForMessageSendOut:(RCMessage *)message {
    if ([message.content isKindOfClass:[RCImageMessage class]]) {
        RCImageMessage *img = (RCImageMessage *)message.content;
        img.originalImage = nil;
    }
    
    __weak typeof(&*self) __weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        RCMessage *tempMessage = [__weakself willAppendAndDisplayMessage:message];
        [__weakself appendAndDisplayMessage:tempMessage];
    });
}

- (void)updateForMessageSendProgress:(int)progress messageId:(long)messageId {
    RCMessageCellNotificationModel *notifyModel = [[RCMessageCellNotificationModel alloc] init];
    notifyModel.actionName = CONVERSATION_CELL_STATUS_SEND_PROGRESS;
    notifyModel.messageId = messageId;
    notifyModel.progress = progress;
    
    dispatch_async(dispatch_get_main_queue(),^{
        [[NSNotificationCenter defaultCenter] postNotificationName:KNotificationMessageBaseCellUpdateSendingStatus
                                                            object:notifyModel];
    });
}

- (void)updateForMessageSendSuccess:(long)messageId content:(RCMessageContent *)content{
    DebugLog(@"message<%ld> send succeeded ", messageId);
    
    RCMessageCellNotificationModel *notifyModel = [[RCMessageCellNotificationModel alloc] init];
    notifyModel.actionName = CONVERSATION_CELL_STATUS_SEND_SUCCESS;
    notifyModel.messageId = messageId;
    
    __weak typeof(&*self) __weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        for (RCMessageModel *model in __weakself.conversationDataRepository) {
            if (model.messageId == messageId) {
                model.sentStatus = SentStatus_SENT;
                model.sentTime = [[RCIMClient sharedRCIMClient]getMessageSendTime:model.messageId];
                break;
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:KNotificationMessageBaseCellUpdateSendingStatus
                                                            object:notifyModel];
        
        dispatch_after(
                       // 0.3s之后再刷新一遍，防止没有Cell绘制太慢
                       dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
                           [[NSNotificationCenter defaultCenter]
                            postNotificationName:KNotificationMessageBaseCellUpdateSendingStatus
                            object:notifyModel];
                       });
    });
    
    [self didSendMessage:0 content:content];
    if ([content isKindOfClass:[RCImageMessage class]]) {
        RCImageMessage *imageMessage = (RCImageMessage *)content;
        if (self.enableSaveNewPhotoToLocalSystem && _isTakeNewPhoto) {
            [self saveNewPhotoToLocalSystemAfterSendingSuccess:imageMessage.originalImage];
        }
    }
}

- (void)updateForMessageSendError:(RCErrorCode)nErrorCode
                        messageId:(long)messageId
                          content:(RCMessageContent *)content {
    DebugLog(@"message<%ld> send failed error code %d", messageId, (int)nErrorCode);
    
    RCMessageCellNotificationModel *notifyModel = [[RCMessageCellNotificationModel alloc] init];
    notifyModel.actionName = CONVERSATION_CELL_STATUS_SEND_FAILED;
    notifyModel.messageId = messageId;
    
    __weak typeof(&*self) __weakself = self;
    dispatch_after(
                   // 发送失败0.3s之后再刷新，防止没有Cell绘制太慢
                   dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.3f),
                   dispatch_get_main_queue(), ^{
                       for (RCMessageModel *model in __weakself.conversationDataRepository) {
                           if (model.messageId == messageId) {
                               model.sentStatus = SentStatus_FAILED;
                               break;
                           }
                       }
                       [[NSNotificationCenter defaultCenter]
                        postNotificationName:
                        KNotificationMessageBaseCellUpdateSendingStatus
                        object: notifyModel];
                   });
    
    [self didSendMessage:nErrorCode content:content];
    
    RCInformationNotificationMessage *informationNotifiMsg = nil;
    if (NOT_IN_DISCUSSION == nErrorCode) {
        informationNotifiMsg = [RCInformationNotificationMessage notificationWithMessage:
                                NSLocalizedStringFromTable(@"NOT_IN_DISCUSSION", @"RongCloudKit",nil)
                                                                                   extra:nil];
    } else if (NOT_IN_GROUP == nErrorCode) {
        informationNotifiMsg = [RCInformationNotificationMessage notificationWithMessage:
                                NSLocalizedStringFromTable(@"NOT_IN_GROUP", @"RongCloudKit", nil)
                                                                                   extra:nil];
    } else if (NOT_IN_CHATROOM == nErrorCode) {
        informationNotifiMsg = [RCInformationNotificationMessage notificationWithMessage:
                                NSLocalizedStringFromTable(@"NOT_IN_CHATROOM", @"RongCloudKit", nil)
                                                                                   extra:nil];
    } else if (REJECTED_BY_BLACKLIST == nErrorCode) {
        informationNotifiMsg = [RCInformationNotificationMessage notificationWithMessage:
                                NSLocalizedStringFromTable(@"Message rejected", @"RongCloudKit", nil)
                                                                                   extra:nil];
    } else if (FORBIDDEN_IN_GROUP == nErrorCode) {
        informationNotifiMsg = [RCInformationNotificationMessage notificationWithMessage:
                                NSLocalizedStringFromTable(@"FORBIDDEN_IN_GROUP", @"RongCloudKit", nil)
                                                                                   extra:nil];
    } else if (FORBIDDEN_IN_CHATROOM == nErrorCode) {
        informationNotifiMsg = [RCInformationNotificationMessage notificationWithMessage:NSLocalizedStringFromTable(@"ForbiddenInChatRoom", @"RongCloudKit", nil)
                                                                                   extra:nil];
    } else if (KICKED_FROM_CHATROOM == nErrorCode) {
        informationNotifiMsg = [RCInformationNotificationMessage notificationWithMessage:NSLocalizedStringFromTable(@"KickedFromChatRoom", @"RongCloudKit", nil)
                                                                                   extra:nil];
    }
    if (nil != informationNotifiMsg) {
        __block RCMessage *tempMessage = [[RCIMClient sharedRCIMClient]
                                  insertMessage: self.conversationType
                                  targetId: self.targetId
                                  senderUserId: nil
                                  sendStatus: SentStatus_SENT
                                  content: informationNotifiMsg];
        dispatch_async(dispatch_get_main_queue(), ^{
            tempMessage = [__weakself willAppendAndDisplayMessage:tempMessage];
            if (tempMessage) {
                [__weakself appendAndDisplayMessage:tempMessage];
            }
        });
    }
}

- (void)sendMessage:(RCMessageContent *)messageContent
        pushContent:(NSString *)pushContent {
    if (_targetId == nil) {
        return;
    }
    if ([RCIM sharedRCIM].enableMessageAttachUserInfo) {
        messageContent.senderUserInfo = [RCIM sharedRCIM].currentUserInfo;
    }
    
    messageContent = [self willSendMessage:messageContent];
    if (messageContent == nil) {
        return;
    }
    
    [[RCIM sharedRCIM] sendMessage:self.conversationType
                          targetId:self.targetId
                           content:messageContent
                       pushContent:pushContent
                          pushData:nil
                           success:^(long messageId) {
                               
                           } error:^(RCErrorCode nErrorCode, long messageId) {
                               
                           }];
}

- (void)uploadImage:(RCMessage *)message uploadListener:(RCUploadImageStatusListener *)uploadListener {
    uploadListener.errorBlock(-1);
    NSLog(@"error, App应该实现uploadImage函数用来上传图片");
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        int i = 0;
//        for (i = 0; i < 100; i++) {
//            uploadListener.updateBlock(i);
//            [NSThread sleepForTimeInterval:0.2];
//        }
//        uploadListener.successBlock(@"http://www.rongcloud.cn/images/newVersion/bannerInner.png?0717");
//    });
}

- (void)sendImageMessage:(RCImageMessage *)imageMessage pushContent:(NSString *)pushContent appUpload:(BOOL)appUpload {
    if (!appUpload) {
        [self sendImageMessage:imageMessage pushContent:pushContent];
        return;
    }
    
    __weak typeof(&*self) __weakself = self;
    
    RCMessage *rcMessage =
    [[RCIMClient sharedRCIMClient]
     sendImageMessage:self.conversationType
     targetId:self.targetId
     content:imageMessage
     pushContent:pushContent
     pushData:@""
     uploadPrepare:^(RCUploadImageStatusListener *uploadListener) {
         [__weakself uploadImage:uploadListener.currentMessage
                  uploadListener:uploadListener];
     } progress:^(int progress, long messageId) {
         NSDictionary *statusDic = @{@"targetId":self.targetId,
                                     @"conversationType":@(self.conversationType),
                                     @"messageId": @(messageId),
                                     @"sentStatus": @(SentStatus_SENDING),
                                     @"progress": @(progress)};
         [[NSNotificationCenter defaultCenter] postNotificationName:@"RCKitSendingMessageNotification"
                                                             object:nil
                                                           userInfo:statusDic];
     } success:^(long messageId) {
         NSDictionary *statusDic = @{@"targetId":self.targetId,
                                     @"conversationType":@(self.conversationType),
                                     @"messageId": @(messageId),
                                     @"sentStatus": @(SentStatus_SENT),
                                     @"content":imageMessage};
         [[NSNotificationCenter defaultCenter] postNotificationName:@"RCKitSendingMessageNotification"
                                                             object:nil
                                                           userInfo:statusDic];
         
     } error:^(RCErrorCode errorCode, long messageId) {
         NSDictionary *statusDic = @{@"targetId":self.targetId,
                                     @"conversationType":@(self.conversationType),
                                     @"messageId": @(messageId),
                                     @"sentStatus": @(SentStatus_FAILED),
                                     @"error": @(errorCode),
                                     @"content":imageMessage};
         [[NSNotificationCenter defaultCenter] postNotificationName:@"RCKitSendingMessageNotification"
                                                             object:nil
                                                           userInfo:statusDic];
         
     }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RCKitSendingMessageNotification"
                                                        object:rcMessage
                                                      userInfo:nil];
}

- (void)sendImageMessage:(RCImageMessage *)imageMessage
             pushContent:(NSString *)pushContent {
    if ([RCIM sharedRCIM].enableMessageAttachUserInfo) {
        imageMessage.senderUserInfo = [RCIM sharedRCIM].currentUserInfo;
    }
    
    imageMessage = (RCImageMessage *)[self willSendMessage:imageMessage];
    if (imageMessage == nil) {
        return;
    }
    
    [[RCIM sharedRCIM] sendImageMessage:self.conversationType
                               targetId:self.targetId
                                content:imageMessage
                            pushContent:pushContent
                               pushData:nil
                               progress:^(int progress, long messageId) {
                                   
                               } success:^(long messageId) {
                                   
                               } error:^(RCErrorCode errorCode, long messageId) {
                                   
                               }];
}

-(void)receiveMessageHasReadNotification:(NSNotification *)notification {
    NSNumber *ctype = [notification.userInfo objectForKey:@"cType"];
    NSNumber *time = [notification.userInfo objectForKey:@"messageTime"];
    NSString *targetId = [notification.userInfo objectForKey:@"tId"];
    if (ctype.intValue ==(int)self.conversationType && [targetId isEqualToString: self.targetId]) {
        //TODO:通知UI消息已读
        dispatch_async(dispatch_get_main_queue(), ^{
            for (RCMessageModel *model in self.conversationDataRepository) {
                if (model.sentTime > time.longLongValue) {
                    //                            model.sentTime = [[RCIMClient sharedRCIMClient]getMessageSendTime:model.messageId];
                }
                
                if (model.messageDirection == MessageDirection_SEND && model.sentTime  <=time.longLongValue && model.sentStatus == SentStatus_SENT) {
                    RCMessageCellNotificationModel *notifyModel =
                    [[RCMessageCellNotificationModel alloc] init];
                    notifyModel.actionName = CONVERSATION_CELL_STATUS_SEND_HASREAD;
                    model.sentStatus = SentStatus_READ;
                    notifyModel.messageId = model.messageId;
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:
                     KNotificationMessageBaseCellUpdateSendingStatus
                     object:notifyModel];
                }
            }
            
        });

    }
   
}

- (void)didReceiveMessageNotification:(NSNotification *)notification {
  __block RCMessage *rcMessage = notification.object;
  RCMessageModel *model = [[RCMessageModel alloc] initWithMessage:rcMessage];
#if RC_VOIP_ENABLE
    if ([rcMessage.content isMemberOfClass:[RCVoIPCallMessage class]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self animationLayoutBottomBarWithStatus:KBottomBarDefaultStatus animated:YES];
        });
    }
#endif
    NSDictionary *leftDic = notification.userInfo;
    //进入聊天室第一次拉取消息完成需要滑动到最下方
    if (self.conversationType == ConversationType_CHATROOM && !self.isChatRoomHistoryMessageLoaded) {
        
        if (leftDic && [leftDic[@"left"] isEqual:@(0)]) {
            self.isNeedScrollToButtom = YES;
            self.isChatRoomHistoryMessageLoaded = YES;
        }
    }

  if (model.conversationType == self.conversationType &&
      [model.targetId isEqual:self.targetId]) {

    if (self.isConversationAppear) {
      [[RCIMClient sharedRCIMClient]
          clearMessagesUnreadStatus:self.conversationType
                           targetId:self.targetId];
    }
      //如果开启消息回执，收到消息要发送已读消息，发送失败存入数据库
      if (leftDic && [leftDic[@"left"] isEqual:@(0)]) {
          if ([RCIM sharedRCIM].enableReadReceipt && [self.targetId isEqualToString: model.targetId]&& model.messageDirection == MessageDirection_RECEIVE && self.conversationType == ConversationType_PRIVATE &&[RCIMClient sharedRCIMClient].sdkRunningMode == RCSDKRunningMode_Foregroud) {
              Class messageContentClass = model.content.class;
              
              NSInteger persistentFlag = [messageContentClass persistentFlag];
              //对于需要显示的消息发送已读回执
              if (persistentFlag & MessagePersistent_ISPERSISTED) {
                  [[RCIMClient sharedRCIMClient]sendReadReceiptMessage:self.conversationType targetId:self.targetId time:model.sentTime];
              }
          }
      }

    __weak typeof(&*self) __blockSelf = self;

    dispatch_async(dispatch_get_main_queue(), ^{
        
        //数量不可能无限制的大，这里限制收到消息过多时，就对显示消息数量进行限制。
        //用户可以手动下拉更多消息，查看更多历史消息。
        if (self.conversationDataRepository.count>300) {
            NSRange range = NSMakeRange(0, 200);
            [self.conversationDataRepository removeObjectsInRange:range];
            [self.conversationMessageCollectionView reloadData];
        }
        rcMessage = [__blockSelf willAppendAndDisplayMessage:rcMessage];
        if (rcMessage) {
            [__blockSelf appendAndDisplayMessage:rcMessage];
            UIMenuController *menu = [UIMenuController sharedMenuController];
            menu.menuVisible=NO;
            // 是否显示右下未读消息数
            if (self.enableNewComingMessageIcon == YES) {
                if (![self isAtTheBottomOfTableView]) {
                    self.unreadNewMsgCount ++ ;
                    [self updateUnreadMsgCountLabel];
                }
            }
        }
      });
  } else {
    [self notifyUpdateUnreadMessageCount];
  }
   
}

- (void)didSendingMessageNotification:(NSNotification *)notification {
    RCMessage *rcMessage = notification.object;
    NSDictionary *statusDic = notification.userInfo;
    
    if (rcMessage) {
        // 插入消息
        if (rcMessage.conversationType == self.conversationType
            && [rcMessage.targetId isEqual:self.targetId]) {
            [self updateForMessageSendOut:rcMessage];
        }
    } else if (statusDic) {
        // 更新消息状态
        NSNumber *conversationType = statusDic[@"conversationType"];
        NSString *targetId = statusDic[@"targetId"];
        if (conversationType.intValue == self.conversationType
            && [targetId isEqual:self.targetId]) {
            NSNumber *messageId = statusDic[@"messageId"];
            NSNumber *sentStatus = statusDic[@"sentStatus"];
            if (sentStatus.intValue == SentStatus_SENDING) {
                NSNumber *progress = statusDic[@"progress"];
                [self updateForMessageSendProgress:progress.intValue messageId:messageId.longValue];
            } else if (sentStatus.intValue == SentStatus_SENT) {
                RCMessageContent *content = statusDic[@"content"];
                [self updateForMessageSendSuccess:messageId.longValue
                                          content:content];
            } else if (sentStatus.intValue == SentStatus_FAILED) {
                NSNumber *errorCode = statusDic[@"error"];
                RCMessageContent *content = statusDic[@"content"];
                [self updateForMessageSendError:errorCode.intValue
                                      messageId:messageId.longValue
                                        content:content];
            }
        }
    }
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (RCMessageContent *)willSendMessage:(RCMessageContent *)message {
  DebugLog(@"super %s", __FUNCTION__);
  return message;
}

- (RCMessage *)willAppendAndDisplayMessage:(RCMessage *)message {
  DebugLog(@"super %s", __FUNCTION__);
  return message;
}

- (void)didSendMessage:(NSInteger)stauts
               content:(RCMessageContent *)messageCotent {
  DebugLog(@"super %s, %@", __FUNCTION__, messageCotent);
}

#pragma mark <RCChatSessionInputBarControlDelegate>
- (void)keyboardWillShowWithFrame:(CGRect)keyboardFrame {
  DebugLog(@"%s", __FUNCTION__);

//  CGRect chatInputBarFrame = _chatSessionInputBarControl.frame;
//  chatInputBarFrame.origin.y =
//      self.view.bounds.size.height -
//      (Height_ChatSessionInputBar +
//       _chatSessionInputBarControl.inputTextview_height - 36) -
//      CGRectGetHeight(keyboardFrame);
//
//  _chatSessionInputBarControl.frame = chatInputBarFrame;
    if (self.chatSessionInputBarControl.inputTextView
        .isFirstResponder) //判断键盘打开
    {
      self.KeyboardFrame = keyboardFrame;
      [self animationLayoutBottomBarWithStatus:KBottomBarKeyboardStatus animated:YES];
    }
}

- (void)chatSessionInputBarControlContentSizeChanged:(CGRect)frame;
{
  //    [UIView beginAnimations:@"grow_bar" context:nil];
  //    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
  //    [UIView setAnimationDuration:0.1f];
  //    [UIView setAnimationDelegate:self];

  CGRect collectionViewRect = self.conversationMessageCollectionView.frame;
  collectionViewRect.size.height =
      CGRectGetMinY(frame) - collectionViewRect.origin.y;
  [self.conversationMessageCollectionView setFrame:collectionViewRect];
  [self scrollToBottomAnimated:NO];

  //[UIView commitAnimations];
}
- (void)keyboardWillHide {
  //_chatSessionInputBarControl.originalPositionY =
  // self.view.bounds.size.height - (Height_ChatSessionInputBar);
//  if (self.chatSessionInputBarControl.inputTextView
//          .isFirstResponder) //判断键盘打开  去掉这个判断，避免如搜狗类第三方输入法有关闭键盘功能不走以下逻辑
//  {
    [self.chatSessionInputBarControl.inputTextView resignFirstResponder];
    [self layoutBottomBarWithStatus:KBottomBarDefaultStatus];
//  }
}

- (void)didTouchPubSwitchButton:(BOOL)switched {
  if (_currentBottomBarStatus != KBottomBarDefaultStatus) {
    [self animationLayoutBottomBarWithStatus:KBottomBarDefaultStatus animated:YES];
  }
}

- (void)didTouchSwitchButton:(BOOL)switched {
    _isClickAddButton = NO;
    _isClickEmojiButton = NO;
  if (switched) {
    [self animationLayoutBottomBarWithStatus:KBottomBarDefaultStatus animated:YES];
    if (_currentBottomBarStatus != KBottomBarDefaultStatus) {
        [self.chatSessionInputBarControl.inputTextView resignFirstResponder];
    }
  }else{
      [self.chatSessionInputBarControl.inputTextView becomeFirstResponder];
  }
}

- (void)didTouchEmojiButton:(UIButton *)sender {
    _isClickAddButton = NO;
    if ([self.chatSessionInputBarControl.inputTextView isFirstResponder]) {
        _isClickEmojiButton = NO;
    }
    if (_isClickEmojiButton) {
        [self.chatSessionInputBarControl.inputTextView becomeFirstResponder];
        [sender setImage:IMAGE_BY_NAMED(@"chatting_biaoqing_btn_normal") forState:UIControlStateNormal];
        _isClickEmojiButton = NO;
    }else{
        _isClickEmojiButton = YES;
        [sender setImage:IMAGE_BY_NAMED(@"chat_setmode_key_btn_normal") forState:UIControlStateNormal];
        [self.chatSessionInputBarControl.inputTextView resignFirstResponder];
        [self animationLayoutBottomBarWithStatus:KBottomBarEmojiStatus animated:YES];
    }
    
}
- (void)didTouchAddtionalButton:(UIButton *)sender;
{
    _isClickEmojiButton = NO;
    if ([self.chatSessionInputBarControl.inputTextView isFirstResponder]) {
        _isClickAddButton = NO;
    }
    if (_isClickAddButton) {
        [self.chatSessionInputBarControl.inputTextView becomeFirstResponder];
        _isClickAddButton = NO;
    }else{
        [self.chatSessionInputBarControl.inputTextView resignFirstResponder];
        [self animationLayoutBottomBarWithStatus:KBottomBarPluginStatus animated:YES];
        _isClickAddButton = YES;
    }
}

- (void)didTouchKeyboardReturnKey:(RCChatSessionInputBarControl *)inputControl
                             text:(NSString *)text {
  RCTextMessage *rcTextMessage = [RCTextMessage messageWithContent:text];
  [self sendMessage:rcTextMessage pushContent:nil];
}

- (void)didTouchRecordButon:(UIButton *)sender event:(UIControlEvents)event {
  switch (event) {
  case UIControlEventTouchDown: {
    [self onBeginRecordEvent];
  } break;
  case UIControlEventTouchUpInside: {
    //[self onEndRecordEvent];
    //[self.voiceCaptureControl removeFromSuperview];
    [self performSelector:@selector(onEndRecordEvent)
               withObject:nil
               afterDelay:0.4];
  } break;
  case UIControlEventTouchDragExit: {
    [self dragExitRecordEvent];
  } break;
  case UIControlEventTouchUpOutside: {
    [self onCancelRecordEvent];
  } break;
  case UIControlEventTouchDragEnter: {
    [self dragEnterRecordEvent];
  } break;
  default:
    break;
  }
}

- (void)inputTextView:(UITextView *)inputTextView
    shouldChangeTextInRange:(NSRange)range
            replacementText:(NSString *)text {
    if ([RCIM sharedRCIM].enableTypingStatus) {
        [[RCIMClient sharedRCIMClient] sendTypingStatus:self.conversationType
                                               targetId:self.targetId
                                            contentType:[RCTextMessage getObjectName]];
    }
    
}
-(void)sendTypingStatusTimerFired{
    isCanSendTypingMessage = YES;
}

//语音消息开始录音
- (void)onBeginRecordEvent {
  [[NSNotificationCenter defaultCenter]
     postNotificationName:kNotificationStopVoicePlayer
     object:nil];
   self.voiceCaptureControl = [[RCVoiceCaptureControl alloc]
      initWithFrame:CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width,
                               [UIScreen mainScreen].bounds.size.height)];
   self.voiceCaptureControl.delegate = self;
   [self.voiceCaptureControl startRecord];
    if ([RCIM sharedRCIM].enableTypingStatus) {
       [[RCIMClient sharedRCIMClient] sendTypingStatus:self.conversationType
                                              targetId:self.targetId
                                           contentType:[RCVoiceMessage getObjectName]];
    }
}
//语音消息录音结束
- (void)onEndRecordEvent {
  NSData *recordData = [self.voiceCaptureControl stopRecord];
  if (self.voiceCaptureControl.duration > 1.0f && nil != recordData) {
    [self destoryVoiceCaptureControl];
    RCVoiceMessage *voiceMessage =
        [RCVoiceMessage messageWithAudio:recordData
                                duration:self.voiceCaptureControl.duration];
    [self sendMessage:voiceMessage pushContent:nil];

  } else {
    // message too short
    if (!self.isAudioRecoderTimeOut) {
      [self.voiceCaptureControl showMsgShortView];
      [self performSelector:@selector(destoryVoiceCaptureControl)
                 withObject:nil
                 afterDelay:1.0f];
    }
  }
}
- (void)destoryVoiceCaptureControl {
  [self.voiceCaptureControl removeFromSuperview];
  self.isAudioRecoderTimeOut = NO;
}
- (void)dragEnterRecordEvent {
  [self.voiceCaptureControl hideCancelView];
}
//滑出显示
- (void)dragExitRecordEvent {
  [self.voiceCaptureControl showCancelView];
}
- (void)onCancelRecordEvent {
  [self.voiceCaptureControl cancelRecord];
}

#pragma mark <RCVoiceCaptureControlDelegate>
- (void)RCVoiceCaptureControlTimeout:(double)duration {
  [self onEndRecordEvent];
  self.isAudioRecoderTimeOut = YES;
}

-(void)RCVoiceCaptureControlTimeUpdate:(double)duration{
//    if ([RCIM sharedRCIM].enableTypingStatus) {
//        [[RCIMClient sharedRCIMClient] sendTypingStatus:self.conversationType
//                                               targetId:self.targetId
//                                            contentType:[RCVoiceMessage getObjectName]];
//    }
}

#pragma mark <RCEmojiBoardViewDelegate>
- (void)didTouchEmojiView:(RCEmojiBoardView *)emojiView
             touchedEmoji:(NSString *)string {
  NSString *replaceString = self.chatSessionInputBarControl.inputTextView.text;

  if (nil == string) {
    [self.chatSessionInputBarControl.inputTextView deleteBackward];
  } else {

    replaceString = string;
    if (replaceString.length < 5000) {
      self.chatSessionInputBarControl.inputTextView.text =
          [self.chatSessionInputBarControl.inputTextView.text
              stringByAppendingString:replaceString];
      {
        CGFloat _inputTextview_height = 36.0f;
        if (_chatSessionInputBarControl.inputTextView.contentSize.height < 70 &&
            _chatSessionInputBarControl.inputTextView.contentSize.height >
                36.0f) {
          _inputTextview_height =
              _chatSessionInputBarControl.inputTextView.contentSize.height;
        }
        if (_chatSessionInputBarControl.inputTextView.contentSize.height >=
            70) {
          _inputTextview_height = 70;
        }
        CGRect intputTextRect = _chatSessionInputBarControl.inputTextView.frame;
        intputTextRect.size.height = _inputTextview_height;
        intputTextRect.origin.y = 7;
        [_chatSessionInputBarControl.inputTextView setFrame:intputTextRect];
        _chatSessionInputBarControl.inputTextview_height =
            _inputTextview_height;

        CGRect vRect = _chatSessionInputBarControl.frame;
        vRect.size.height =
            Height_ChatSessionInputBar + (_inputTextview_height - 36);
        vRect.origin.y = _chatSessionInputBarControl.originalPositionY -
                         (_inputTextview_height - 36);
        _chatSessionInputBarControl.frame = vRect;
        _chatSessionInputBarControl.currentPositionY = vRect.origin.y;

        [self chatSessionInputBarControlContentSizeChanged:vRect];
      }
    }
  }

  UITextView *textView = self.chatSessionInputBarControl.inputTextView;
  {
    CGRect line =
        [textView caretRectForPosition:textView.selectedTextRange.start];
    CGFloat overflow =
        line.origin.y + line.size.height -
        (textView.contentOffset.y + textView.bounds.size.height -
         textView.contentInset.bottom - textView.contentInset.top);
    if (overflow > 0) {
      // We are at the bottom of the visible text and introduced a line feed,
      // scroll down (iOS 7 does not do it)
      // Scroll caret to visible area
      CGPoint offset = textView.contentOffset;
      offset.y += overflow + 7; // leave 7 pixels margin
      // Cannot animate with setContentOffset:animated: or caret will not appear
      [UIView animateWithDuration:.2
                       animations:^{
                         [textView setContentOffset:offset];
                       }];
    }
  }
  if ([RCIM sharedRCIM].enableTypingStatus) {
       [[RCIMClient sharedRCIMClient] sendTypingStatus:self.conversationType
                                         targetId:self.targetId
                                      contentType:[RCTextMessage getObjectName]];
   }
}
- (void)didSendButtonEvent:(RCEmojiBoardView *)emojiView
                sendButton:(UIButton *)sendButton {
  NSString *_sendText = self.chatSessionInputBarControl.inputTextView.text;

  NSString *_formatString = [_sendText
      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

  if (0 == [_formatString length]) {
    UIAlertView *notAllowSendSpace = [[UIAlertView alloc]
            initWithTitle:nil
                  message:NSLocalizedStringFromTable(@"whiteSpaceMessage",
                                                     @"RongCloudKit", nil)
                 delegate:self
        cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"RongCloudKit",
                                                     nil)
        otherButtonTitles:nil, nil];
    [notAllowSendSpace show];
    return;
  }

  RCTextMessage *rcTextMessage = [RCTextMessage
      messageWithContent:self.chatSessionInputBarControl.inputTextView.text];
  [self sendMessage:rcTextMessage pushContent:nil];

  self.chatSessionInputBarControl.inputTextView.text = @"";
  {
    CGFloat _inputTextview_height = 36.0f;
    CGRect intputTextRect = _chatSessionInputBarControl.inputTextView.frame;
    intputTextRect.size.height = _inputTextview_height;
    intputTextRect.origin.y = 7;
    [_chatSessionInputBarControl.inputTextView setFrame:intputTextRect];
    intputTextRect.size.height = _inputTextview_height;
    CGRect vRect = _chatSessionInputBarControl.frame;
    vRect.size.height =
        Height_ChatSessionInputBar + (_inputTextview_height - 36);
    vRect.origin.y = _chatSessionInputBarControl.originalPositionY -
                     (_inputTextview_height - 36);
    _chatSessionInputBarControl.frame = vRect;
    _chatSessionInputBarControl.currentPositionY = vRect.origin.y;
    [self chatSessionInputBarControlContentSizeChanged:vRect];
  }
}

//
- (void)tabRightBottomMsgCountIcon:(UIGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        
        [self scrollToBottomAnimated:YES];
    }
}

- (void)tap4ResetDefaultBottomBarStatus:
    (UIGestureRecognizer *)gestureRecognizer {
  if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
    [self.chatSessionInputBarControl dismissPublicServiceMenuPopupView];
    if (_currentBottomBarStatus != KBottomBarDefaultStatus) {
      [self animationLayoutBottomBarWithStatus:KBottomBarDefaultStatus animated:YES];
    }
  }
}

-(void)setChatSessionInputBarStatus:(KBottomBarStatus)inputBarStatus animated:(BOOL)animated
{
    if (inputBarStatus == KBottomBarRecordStatus) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"switchToRecord" object:nil];
    }
    [self animationLayoutBottomBarWithStatus:inputBarStatus animated:animated];
}

- (void)animationLayoutBottomBarWithStatus:(KBottomBarStatus)bottomBarStatus animated:(BOOL)animated{
    if (bottomBarStatus == KBottomBarDefaultStatus) {
        _isClickEmojiButton = NO;
        _isClickAddButton = NO;
    }
    if (bottomBarStatus != KBottomBarEmojiStatus) {
        [self.chatSessionInputBarControl.emojiButton setImage:IMAGE_BY_NAMED(@"chatting_biaoqing_btn_normal") forState:UIControlStateNormal];
    }
    if (bottomBarStatus == KBottomBarEmojiStatus && !_emojiBoardView) {
        [self emojiBoardView];
    }
    if (bottomBarStatus == KBottomBarPluginStatus && !_pluginBoardView) {
        [self pluginBoardView];
    }
    if (animated == YES) {
        [UIView beginAnimations:@"Move_bar" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDuration:0.25f];
        [UIView setAnimationDelegate:self];
        [self layoutBottomBarWithStatus:bottomBarStatus];
        [UIView commitAnimations];
    }
    else
    {
        [self layoutBottomBarWithStatus:bottomBarStatus];
    }
}

- (void)layoutBottomBarWithStatus:(KBottomBarStatus)bottomBarStatus {
    if (bottomBarStatus != KBottomBarKeyboardStatus) {
        if (self.chatSessionInputBarControl.inputTextView.isFirstResponder) {
            [self.chatSessionInputBarControl.inputTextView resignFirstResponder];
        }
    }
    
    CGRect chatInputBarRect = self.chatSessionInputBarControl.frame;
    CGRect collectionViewRect = self.conversationMessageCollectionView.frame;
    float bottomY = [self getBoardViewBottonOriginY];
    
    switch (bottomBarStatus) {
        case KBottomBarDefaultStatus: {
            if (_emojiBoardView) {
                [self.emojiBoardView setHidden:YES];
            }
            if (_pluginBoardView) {
                [self.pluginBoardView setHidden:YES];
            }
            chatInputBarRect.origin.y =
            bottomY - self.chatSessionInputBarControl.bounds.size.height;
            _chatSessionInputBarControl.originalPositionY =
            self.view.bounds.size.height - (Height_ChatSessionInputBar);
        } break;
            
        case KBottomBarKeyboardStatus: {
            if (_emojiBoardView) {
                [self.emojiBoardView setHidden:YES];
            }
            if (_pluginBoardView) {
                [self.pluginBoardView setHidden:YES];
            }
            chatInputBarRect.origin.y = bottomY - (Height_ChatSessionInputBar + _chatSessionInputBarControl.inputTextview_height - 36) - CGRectGetHeight(self.KeyboardFrame);
            _chatSessionInputBarControl.originalPositionY =
            self.view.bounds.size.height -
            (Height_ChatSessionInputBar)-CGRectGetHeight(self.KeyboardFrame);
        } break;
            
        case KBottomBarPluginStatus: {
            if (_emojiBoardView) {
                [self.emojiBoardView setHidden:YES];
            }
            [self.pluginBoardView setHidden:NO];
            chatInputBarRect.origin.y =
            bottomY - self.chatSessionInputBarControl.bounds.size.height -
            self.pluginBoardView.bounds.size.height;
            _chatSessionInputBarControl.originalPositionY =
            self.view.bounds.size.height -
            (Height_ChatSessionInputBar)-Height_PluginBoardView;
             self.pluginBoardView.frame=CGRectMake(0, bottomY-Height_PluginBoardView, self.view.bounds.size.width, Height_PluginBoardView);
        } break;
            
        case KBottomBarEmojiStatus: {
            if (_pluginBoardView) {
                [self.pluginBoardView setHidden:YES];
            }
            [self.emojiBoardView setHidden:NO];
            chatInputBarRect.origin.y =
            bottomY - self.chatSessionInputBarControl.bounds.size.height -
            self.emojiBoardView.bounds.size.height;
            _chatSessionInputBarControl.originalPositionY =
            self.view.bounds.size.height -
            (Height_ChatSessionInputBar)-Height_EmojBoardView;
            self.emojiBoardView.frame=CGRectMake(0, bottomY-Height_EmojBoardView, self.view.bounds.size.width, Height_EmojBoardView);
        } break;
            
        case KBottomBarRecordStatus: {
            if (_emojiBoardView) {
                [self.emojiBoardView setHidden:YES];
            }
            if (_pluginBoardView) {
                [self.pluginBoardView setHidden:YES];
            }
            
            chatInputBarRect.origin.y =
            bottomY - self.chatSessionInputBarControl.bounds.size.height;
            _chatSessionInputBarControl.originalPositionY =
            self.view.bounds.size.height - (Height_ChatSessionInputBar);
        } break;

        default:
            break;
    }
    
    collectionViewRect.size.height =
    CGRectGetMinY(chatInputBarRect) - collectionViewRect.origin.y;
    [self.conversationMessageCollectionView setFrame:collectionViewRect];
    
    [self.chatSessionInputBarControl setFrame:chatInputBarRect];
    self.chatSessionInputBarControl.currentPositionY =
    self.chatSessionInputBarControl.frame.origin.y;
    _currentBottomBarStatus = bottomBarStatus;
    if ([self respondsToSelector:@selector(didTouchSwitchButton:)]) {
        [self scrollToBottomAnimated:YES];
    }

}

#pragma mark - RCPluginBoardViewDelegate
/**
 *  override to impletion
 *
 *  @param pluginBoardView pluginBoardView description
 *  @param index           index description
 */
- (void)pluginBoardView:(RCPluginBoardView *)pluginBoardView
     clickedItemWithTag:(NSInteger)tag {
  switch (tag) {
  case PLUGIN_BOARD_ITEM_ALBUM_TAG: {
    [self openSystemAlbum:nil];
  } break;
  case PLUGIN_BOARD_ITEM_CAMERA_TAG: {
    [self openSystemCamera:nil];
  } break;
  case PLUGIN_BOARD_ITEM_LOCATION_TAG: {
    [self openLocationPicker:nil];
  } break;
#if RC_VOIP_ENABLE
  case PLUGIN_BOARD_ITEM_VOIP_TAG: {
    [self openVoIP:nil];
  } break;
#endif
  default:
    break;
  }
}

- (CGSize)sizeForItem:(UICollectionView *)collectionView
          atIndexPath:(NSIndexPath *)indexPath {
  // the width of cell must less than the width of collection view minus the
  // left and right value of section inset.
  CGFloat __width = CGRectGetWidth(collectionView.frame);

  // RCCollectionCellAttributes *attributes = [self.customAttributes copy];
  RCMessageModel *model =
      [self.conversationDataRepository objectAtIndex:indexPath.row];
  RCMessageContent *messageContent = model.content;

  // CGSize _bubbleContentSize = CGSizeZero;
  CGFloat __height = 0.0f;

  if ([messageContent
          isMemberOfClass:[RCDiscussionNotificationMessage class]]) {
    RCDiscussionNotificationMessage *notification =
        (RCDiscussionNotificationMessage *)messageContent;
    NSString *localizedMessage = [RCKitUtility formatMessage:notification];
    CGFloat maxMessageLabelWidth = __width - 30 * 2;
    // ios 7
//    CGSize __textSize =
//        [localizedMessage
//            boundingRectWithSize:CGSizeMake(maxMessageLabelWidth, MAXFLOAT)
//                         options:NSStringDrawingTruncatesLastVisibleLine |
//                                 NSStringDrawingUsesLineFragmentOrigin |
//                                 NSStringDrawingUsesFontLeading
//                      attributes:@{
//                        NSFontAttributeName : [UIFont systemFontOfSize:12.5f]
//                      } context:nil]
//            .size;
//      CGSize __textSize = RC_MULTILINE_TEXTSIZE(localizedMessage, [UIFont systemFontOfSize:12.5f], CGSizeMake(maxMessageLabelWidth, MAXFLOAT), NSLineBreakByTruncatingTail);
      CGSize __textSize = CGSizeZero;
      if (IOS_FSystenVersion < 7.0) {
          __textSize = RC_MULTILINE_TEXTSIZE_LIOS7(localizedMessage, [UIFont systemFontOfSize:12.5f], CGSizeMake(maxMessageLabelWidth, MAXFLOAT), NSLineBreakByTruncatingTail);
      }else {
          __textSize = RC_MULTILINE_TEXTSIZE_GEIOS7(localizedMessage, [UIFont systemFontOfSize:12.5f], CGSizeMake(maxMessageLabelWidth, MAXFLOAT));
      }


    __textSize = CGSizeMake(ceilf(__textSize.width), ceilf(__textSize.height));
    CGSize __labelSize =
        CGSizeMake(__textSize.width + 5, __textSize.height + 5);

    //上边距
    __height = __height + 10;

    if (model.isDisplayMessageTime) {
      __height = __height + 20 + 10;
    }
    __height = __height + __labelSize.height;
    //下边距
    __height = __height + 10;
    return CGSizeMake(__width, __height);
  } else if ([messageContent
                 isMemberOfClass:[RCInformationNotificationMessage class]]) {
    RCInformationNotificationMessage *notification =
        (RCInformationNotificationMessage *)messageContent;
    NSString *localizedMessage = [RCKitUtility formatMessage:notification];
    CGFloat maxMessageLabelWidth = __width - 30 * 2;
    // ios 7
//    CGSize __textSize =
//        [localizedMessage
//            boundingRectWithSize:CGSizeMake(maxMessageLabelWidth, MAXFLOAT)
//                         options:NSStringDrawingTruncatesLastVisibleLine |
//                                 NSStringDrawingUsesLineFragmentOrigin |
//                                 NSStringDrawingUsesFontLeading
//                      attributes:@{
//                        NSFontAttributeName : [UIFont systemFontOfSize:12.5f]
//                      } context:nil]
//            .size;
//      CGSize __textSize = RC_MULTILINE_TEXTSIZE(localizedMessage, [UIFont systemFontOfSize:12.5f], CGSizeMake(maxMessageLabelWidth, MAXFLOAT), NSLineBreakByTruncatingTail);
      CGSize __textSize = CGSizeZero;
      if (IOS_FSystenVersion < 7.0) {
          __textSize = RC_MULTILINE_TEXTSIZE_LIOS7(localizedMessage, [UIFont systemFontOfSize:12.5f], CGSizeMake(maxMessageLabelWidth, MAXFLOAT), NSLineBreakByTruncatingTail);
      }else {
          __textSize = RC_MULTILINE_TEXTSIZE_GEIOS7(localizedMessage, [UIFont systemFontOfSize:12.5f], CGSizeMake(maxMessageLabelWidth, MAXFLOAT));
      }


    __textSize = CGSizeMake(ceilf(__textSize.width), ceilf(__textSize.height));
    CGSize __labelSize =
        CGSizeMake(__textSize.width + 5, __textSize.height + 5);
    //上边距
    __height = __height + 10;

    if (model.isDisplayMessageTime) {
      __height = __height + 20 + 10;
    }
    __height = __height + __labelSize.height;
    //下边距
    __height = __height + 10;

    return CGSizeMake(__width, __height);
  } else {

    CGFloat __messagecontentview_height = 0.0f;
    if ([messageContent isMemberOfClass:[RCTextMessage class]]) {

      RCTextMessage *_textMessage = (RCTextMessage *)messageContent;

//      CGSize _textMessageSize =
//          [_textMessage.content
//              boundingRectWithSize:
//                  CGSizeMake(
//                      __width -
//                          (10 +
//                           [RCIM sharedRCIM].globalMessagePortraitSize.width +
//                           10) *
//                              2 -
//                          35 - 5,
//                      8000)
//                           options:(NSStringDrawingTruncatesLastVisibleLine |
//                                    NSStringDrawingUsesLineFragmentOrigin |
//                                    NSStringDrawingUsesFontLeading)
//                        attributes:@{
//                          NSFontAttributeName :
//                              [UIFont systemFontOfSize:Text_Message_Font_Size]
//                        } context:nil]
//              .size;


        
//        CGSize _textMessageSize = RC_MULTILINE_TEXTSIZE(_textMessage.content, [UIFont systemFontOfSize:Text_Message_Font_Size], CGSizeMake( __width - (10 +[RCIM sharedRCIM].globalMessagePortraitSize.width +  10) *  2 - 35 - 5,  8000), NSLineBreakByTruncatingTail);
        CGSize _textMessageSize = CGSizeZero;
        if (IOS_FSystenVersion < 7.0) {
            _textMessageSize = RC_MULTILINE_TEXTSIZE_LIOS7(_textMessage.content, [UIFont systemFontOfSize:Text_Message_Font_Size], CGSizeMake( __width - (10 +[RCIM sharedRCIM].globalMessagePortraitSize.width +  10) *  2 - 35 - 5,  8000), NSLineBreakByTruncatingTail);
        }else {
            _textMessageSize = RC_MULTILINE_TEXTSIZE_GEIOS7(_textMessage.content, [UIFont systemFontOfSize:Text_Message_Font_Size], CGSizeMake( __width - (10 +[RCIM sharedRCIM].globalMessagePortraitSize.width +  10) *  2 - 35 - 5,  8000));
        }


        
      _textMessageSize = CGSizeMake(ceilf(_textMessageSize.width),
                                    ceilf(_textMessageSize.height));
      CGFloat __label_height = _textMessageSize.height + 5;
      //背景图的最小高度
      CGFloat __bubbleHeight =
          __label_height + 5 + 5 < 35 ? 35 : (__label_height + 5 + 5);

      __messagecontentview_height = __bubbleHeight;

    } else if ([messageContent isMemberOfClass:[RCImageMessage class]]) {
      RCImageMessage *_imageMessage = (RCImageMessage *)messageContent;

      CGSize imageSize = _imageMessage.thumbnailImage.size;
      //兼容240
      CGFloat imageWidth = 120;
      CGFloat imageHeight = 120;
      if (imageSize.width > 121 || imageHeight > 121) {
        imageWidth = imageSize.width / 2.0f;
        imageHeight = imageSize.height / 2.0f;
      } else {
        imageWidth = imageSize.width;
        imageHeight = imageSize.height;
      }
      //图片half
      imageSize = CGSizeMake(imageWidth, imageHeight);
      __messagecontentview_height = imageSize.height;

    } else if ([messageContent isMemberOfClass:[RCVoiceMessage class]]) {
      __messagecontentview_height = 36.0f;

    } else if ([messageContent isMemberOfClass:[RCLocationMessage class]]) {
      //写死尺寸 原来400 *230
      CGSize imageSize = CGSizeMake(360 / 2.0f, 207 / 2.0f);
      __messagecontentview_height = imageSize.height;

    } else if ([messageContent isMemberOfClass:[RCRichContentMessage class]]) {
      RCRichContentMessage *richContentMsg =
          (RCRichContentMessage *)messageContent;
//      CGSize _titleLabelSize =
//          [richContentMsg.title
//              boundingRectWithSize:CGSizeMake(200, MAXFLOAT)
//                           options:(NSStringDrawingTruncatesLastVisibleLine |
//                                    NSStringDrawingUsesLineFragmentOrigin |
//                                    NSStringDrawingUsesFontLeading)
//                        attributes:@{
//                          NSFontAttributeName : [UIFont
//                              systemFontOfSize:RichContent_Title_Font_Size]
//                        } context:nil]
//              .size;
        
//        CGSize _titleLabelSize = RC_MULTILINE_TEXTSIZE(richContentMsg.title, [UIFont systemFontOfSize:RichContent_Title_Font_Size], CGSizeMake(200, MAXFLOAT), NSLineBreakByTruncatingTail);
        CGSize _titleLabelSize = CGSizeZero;
        if (IOS_FSystenVersion < 7.0) {
            _titleLabelSize = RC_MULTILINE_TEXTSIZE_LIOS7(richContentMsg.title, [UIFont systemFontOfSize:RichContent_Title_Font_Size], CGSizeMake(200, MAXFLOAT), NSLineBreakByTruncatingTail);
        }else {
            _titleLabelSize = RC_MULTILINE_TEXTSIZE_GEIOS7(richContentMsg.title, [UIFont systemFontOfSize:RichContent_Title_Font_Size], CGSizeMake(200, MAXFLOAT));
        }

//
//      NSLog(@"_titleLabelSize width is %f   %f   %f", _titleLabelSize.height,
//            _titleLabelSize.width, __width);

//      CGSize _digestLabelSize =
//          [richContentMsg.digest
//              boundingRectWithSize:CGSizeMake(200, MAXFLOAT)
//                           options:(NSStringDrawingTruncatesLastVisibleLine |
//                                    NSStringDrawingUsesLineFragmentOrigin |
//                                    NSStringDrawingUsesFontLeading)
//                        attributes:@{
//                          NSFontAttributeName : [UIFont
//                              systemFontOfSize:RichContent_Message_Font_Size]
//                        } context:nil]
//              .size;
        
//        CGSize _digestLabelSize = RC_MULTILINE_TEXTSIZE(richContentMsg.digest, [UIFont systemFontOfSize:RichContent_Message_Font_Size], CGSizeMake(200, MAXFLOAT), NSLineBreakByTruncatingTail);
        CGSize _digestLabelSize = CGSizeZero;
        if (IOS_FSystenVersion < 7.0) {
            _digestLabelSize = RC_MULTILINE_TEXTSIZE_LIOS7(richContentMsg.digest, [UIFont systemFontOfSize:RichContent_Message_Font_Size], CGSizeMake(200, MAXFLOAT), NSLineBreakByTruncatingTail);
        }else {
            _digestLabelSize = RC_MULTILINE_TEXTSIZE_GEIOS7(richContentMsg.digest, [UIFont systemFontOfSize:RichContent_Message_Font_Size], CGSizeMake(200, MAXFLOAT));
        }


      //高度写死。避免高度过大或过小引起的显示问题
      _digestLabelSize.height = 60;
      __messagecontentview_height =
          _titleLabelSize.height + _digestLabelSize.height + 30;
      //__messagecontentview_height = _titleLabelSize.height +
      // RICH_CONTENT_THUMBNAIL_HIGHT + 30;
    }

    if (model.isDisplayNickname) {
      if (model.messageDirection == MessageDirection_RECEIVE) {
        __height = __messagecontentview_height + 17 + 3;
      } else {
        __height = __messagecontentview_height;
      }
    } else {
      __height = __messagecontentview_height;
    }

    if (__height < [RCIM sharedRCIM].globalMessagePortraitSize.height) {
      __height = [RCIM sharedRCIM].globalMessagePortraitSize.height;
    }

    //上边距
    __height = __height + 10;

    if (model.isDisplayMessageTime) {
      __height = __height + 20 + 10;
    }
    //下边距
    __height = __height + 10;
    // attributes.frame = CGRectMake(0, self.yOfItem, _width, _height);

    //[self.customAttributeDictionary setObject:attributes forKey:indexPath];

    // self.yOfItem += _height;

    return CGSizeMake(__width, __height);
  }
}

/**
 *  复制
 *
 *  @param sender
 */
- (void)onCopyMessage:(id)sender {
  // self.msgInputBar.msgColumnTextView.disableActionMenu = NO;
  self.chatSessionInputBarControl.inputTextView.disableActionMenu = NO;
  UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
  // RCMessageCell* cell = _RCMessageCell;
  //判断是否文本消息
  if ([_longPressSelectedModel.content isKindOfClass:[RCTextMessage class]]) {
    RCTextMessage *text = (RCTextMessage *)_longPressSelectedModel.content;
    [pasteboard setString:text.content];
  }
}
/**
 *  删除
 *
 *  @param sender
 */
- (void)onDeleteMessage:(id)sender {
  // self.msgInputBar.msgColumnTextView.disableActionMenu = NO;
  self.chatSessionInputBarControl.inputTextView.disableActionMenu = NO;
  // RCMessageCell* cell = _RCMessageCell;
  RCMessageModel *model = _longPressSelectedModel;
  // RCMessageContent *content = _longPressSelectedModel.content;
  
    //删除消息时如果是当前播放的消息就停止播放
    if ([RCVoicePlayer defaultPlayer].isPlaying && [RCVoicePlayer defaultPlayer].messageId != nil && [[RCVoicePlayer defaultPlayer].messageId isEqualToString:[NSString stringWithFormat:@"%ld",model.messageId]] ) {
        [[RCVoicePlayer defaultPlayer] stopPlayVoice];
    }
  [self deleteMessage:model];
}

- (void)deleteMessage:(RCMessageModel *)model {
  long msgId = model.messageId;
  NSIndexPath *indexPath =
      [NSIndexPath indexPathForItem:[self findDataIndexFromMessageList:model]
                          inSection:0];
  [[RCIMClient sharedRCIMClient] deleteMessages:@[ @(msgId) ]];
  
    
    [self.conversationDataRepository removeObject:model];
    [self.conversationMessageCollectionView
     deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
    
    
    for (int i = 0; i < self.conversationDataRepository.count; i++) {
        RCMessageModel *msg = (self.conversationDataRepository)[i];
        if ([msg.content isKindOfClass:[RCOldMessageNotificationMessage class]]) {
            //如果“以上是历史消息”RCOldMessageNotificationMessage 上面或者下面没有消息了，把RCOldMessageNotificationMessage也删除
            if (self.conversationDataRepository.count <=i+1|| (i==0&& self.scrollNum>0)) {
                 NSIndexPath *oldMsgIndexPath =[NSIndexPath indexPathForItem:i
                                    inSection:0];
                [self.conversationDataRepository removeObject:msg];
                [self.conversationMessageCollectionView
                 deleteItemsAtIndexPaths:[NSArray arrayWithObject:oldMsgIndexPath]];
                
                //删除“以上是历史消息”之后，会话的第一条消息显示时间，并且调整高度
                if(i==0 && self.conversationDataRepository.count>0){
                    RCMessageModel *topMsg = (self.conversationDataRepository)[0];
                    topMsg.isDisplayMessageTime =YES;
                    topMsg.cellSize =CGSizeMake(topMsg.cellSize.width, topMsg.cellSize.height+30);
                    RCMessageCell * __cell = (RCMessageCell *)[self.conversationMessageCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0
                                                                                                                                                 inSection:0]];
                    if (__cell) {
                        [__cell setDataModel:topMsg];
                    }
                    [self.conversationMessageCollectionView reloadData];
                }
            }
            
            break;
        }
    }
 
    
}

- (void)notifyUnReadMessageCount:(NSInteger)count {
}

/**
 *  设置头像样式
 *
 *  @param avatarStyle avatarStyle
 */
- (void)setMessageAvatarStyle:(RCUserAvatarStyle)avatarStyle {
  [RCIM sharedRCIM].globalMessageAvatarStyle = avatarStyle;
}
/**
 *  设置头像大小
 *
 *  @param size size
 */
- (void)setMessagePortraitSize:(CGSize)size {
  [RCIM sharedRCIM].globalMessagePortraitSize = size;
}

//发多张图片
//#pragma mark - RCImagePickerViewControllerDelegate
//- (void)imagePickerViewController:(RCImagePickerViewController
//*)imagePickerViewController
//                   selectedImages:(NSArray *)selectedImages {
//    //通过回传的controller 返回当前viewController
//    [imagePickerViewController.navigationController
//    popViewControllerAnimated:NO];
//
//    //耗时操作异步执行，以免阻塞主线程
//    __weak RCConversationViewController *weakSelf = self;
//
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,
//    0), ^{
//
//      for (int i = 0; i < selectedImages.count; i++) {
//          UIImage *image = [selectedImages objectAtIndex:i];
//
//          RCImageMessage *imagemsg = [RCImageMessage messageWithImage:image];
//
//          [weakSelf sendImageMessage:imagemsg pushContent:nil];
//          [NSThread sleepForTimeInterval:0.5];
//      }
//    });
//
//    [imagePickerViewController.navigationController
//    popViewControllerAnimated:YES];
//}

#pragma mark - RCAlbumListViewControllerDelegate
- (void)albumListViewController:
            (RCAlbumListViewController *)albumListViewController
                 selectedImages:(NSArray *)selectedImages isSendFullImage:(BOOL)enable{
  _isTakeNewPhoto = NO;
  //耗时操作异步执行，以免阻塞主线程
  __weak RCConversationViewController *weakSelf = self;

  dispatch_async(
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        for (int i = 0; i < selectedImages.count; i++) {
          UIImage *image = [selectedImages objectAtIndex:i];

          RCImageMessage *imagemsg = [RCImageMessage messageWithImage:image];
          imagemsg.full = enable;
          [weakSelf sendImageMessage:imagemsg pushContent:nil];
          [NSThread sleepForTimeInterval:0.5];
        }
      });
}
//- (NSArray *)displayConversationTypeArray
//{
//    if (!_displayConversationTypeArray) {
//        _displayConversationTypeArray = @[
//                                         @(ConversationType_PRIVATE),
//                                         @(ConversationType_DISCUSSION),
//                                         @(ConversationType_APPSERVICE),
//                                         @(ConversationType_PUBLICSERVICE),
//                                         @(ConversationType_GROUP)
//                                         ];
//    }
//    return _displayConversationTypeArray;
//}
- (void)notifyUpdateUnreadMessageCount {
  __weak typeof(&*self) __weakself = self;
  int count = 0;
  if (self.displayConversationTypeArray) {
    count = [[RCIMClient sharedRCIMClient]
        getUnreadCount:self.displayConversationTypeArray];
  }
  else {
    return;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    NSString *backString = nil;
    if (count > 0 && count < 1000) {
      backString =
          [NSString stringWithFormat:NSLocalizedStringFromTable(
                                         @"Back(%d)", @"RongCloudKit", nil),
                                     count];
    } else if (count >= 1000) {
      backString =
          NSLocalizedStringFromTable(@"Back(...)", @"RongCloudKit", nil);
    } else {
      backString = NSLocalizedStringFromTable(@"Back", @"RongCloudKit", nil);
    }
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(0, 6, 72, 23);
    UIImageView *backImg = [[UIImageView alloc]
        initWithImage:IMAGE_BY_NAMED(@"navigator_btn_back")];
    backImg.frame = CGRectMake(-10, 0, 22, 22);
    [backBtn addSubview:backImg];
    UILabel *backText =
        [[UILabel alloc] initWithFrame:CGRectMake(12, 0, 70, 22)];
    backText.text = backString; // NSLocalizedStringFromTable(@"Back",
                                // @"RongCloudKit", nil);
    backText.font = [UIFont systemFontOfSize:15];
    [backText setBackgroundColor:[UIColor clearColor]];
    [backText setTextColor:[UIColor whiteColor]];
    [backBtn addSubview:backText];
    [backBtn addTarget:__weakself
                  action:@selector(leftBarButtonItemPressed:)
        forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftButton =
        [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    [__weakself.navigationItem setLeftBarButtonItem:leftButton];
  });
}
- (void)saveNewPhotoToLocalSystemAfterSendingSuccess:(UIImage *)newImage {
}

- (BOOL)isAtTheBottomOfTableView {
    if (self.conversationMessageCollectionView.contentSize.height <= self.conversationMessageCollectionView.frame.size.height) {
        return YES;
    }
//    NSIndexPath *lastPath = [self getLastIndexPathForVisibleItems];
//    if (lastPath.row >= self.conversationDataRepository.count -3) {
//        return YES;
//    }else{
//        return NO;
//    }
    if(self.conversationMessageCollectionView.contentOffset.y +200 >= (self.conversationMessageCollectionView.contentSize.height - self.conversationMessageCollectionView.frame.size.height)) {
        return YES;
    }else{
        return NO;
    }
}


//修复ios7下不断下拉加载历史消息偶尔崩溃的bug
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

-(void)receivePlayVoiceFinishNotification:(NSNotification *)notification {
    if (self.enableContinuousReadUnreadVoice) {
        NSString *messageId = notification.object;
        int index =0;
        if (messageId) {
            RCMessageModel *rcMsg;
            for (int i = 0; i< self.conversationDataRepository.count; i++) {
                rcMsg = [self.conversationDataRepository objectAtIndex:i];
                if ([messageId longLongValue]<rcMsg.messageId && [rcMsg.content isMemberOfClass:[RCVoiceMessage class]]&&rcMsg.receivedStatus != ReceivedStatus_LISTENED && rcMsg.messageDirection == MessageDirection_RECEIVE) {
                    index = i;
                    break;
                }
            }
            if (index != 0) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0] ;
                //RCVoiceMessageCell *__cell = (RCVoiceMessageCell *)[self.conversationMessageCollectionView dequeueReusableCellWithReuseIdentifier:rcvoiceCellIndentifier forIndexPath:indexPath];
                RCVoiceMessageCell *__cell = (RCVoiceMessageCell *)[self.conversationMessageCollectionView cellForItemAtIndexPath:indexPath];
                //如果是空说明被回收了，重新dequeue一个cell
                if(__cell)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [__cell playVoice];
                    });
                }else{
                    __cell = (RCVoiceMessageCell *)[self.conversationMessageCollectionView dequeueReusableCellWithReuseIdentifier:rcvoiceCellIndentifier forIndexPath:indexPath];
                    [__cell setDataModel:rcMsg];
                    [__cell setDelegate:self];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [__cell playVoice];
                    });
                }
                
            }
            
        }
    }
    
}
- (void)onPublicServiceMenuItemSelected:(RCPublicServiceMenuItem *)selectedMenuItem {
    if (selectedMenuItem.type == RC_PUBLIC_SERVICE_MENU_ITEM_VIEW) {
        UIViewController *webviewController = [[RCIMClient sharedRCIMClient] getPublicServiceWebViewController:selectedMenuItem.url];
        [self.navigationController pushViewController:webviewController animated:YES];
    }
    
    RCPublicServiceCommandMessage *command = [RCPublicServiceCommandMessage messageFromMenuItem:selectedMenuItem];
    if (command) {
        [[RCIMClient sharedRCIMClient] sendMessage:self.conversationType targetId:self.targetId content:command pushContent:nil success:^(long messageId) {
            
        } error:^(RCErrorCode nErrorCode, long messageId) {
            
        }];
    }
}

- (void)didTapUrlInPublicServiceMessageCell:(NSString *)url model:(RCMessageModel *)model {
    UIViewController *webviewController = [[RCIMClient sharedRCIMClient] getPublicServiceWebViewController:url];
    [self didTapImageTxtMsgCell:url webViewController:webviewController];
}

#pragma mark override
- (void)didTapImageTxtMsgCell:(NSString *)tapedUrl webViewController:(UIViewController *)rcWebViewController {
    UINavigationController *navigationController =
    [[UIApplication sharedApplication] delegate].window.rootViewController.navigationController;
    
    UIWindow *window = [[UIApplication sharedApplication] delegate].window;
    navigationController = (UINavigationController *)window.rootViewController;
    
    [navigationController pushViewController:rcWebViewController animated:YES];
}


- (void)onTypingStatusChanged:(RCConversationType)conversationType
                     targetId:(NSString *)targetId
                       status:(NSArray *)userTypingStatusList {
    if (conversationType == self.conversationType
        && [targetId isEqualToString:self.targetId]&&[RCIM sharedRCIM].enableTypingStatus) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (userTypingStatusList == nil || userTypingStatusList.count == 0) {
                self.navigationItem.title = self.navigationTitle;
            } else {
                RCUserTypingStatus *typingStatus = (RCUserTypingStatus *)userTypingStatusList[0];
                if ([typingStatus.contentType isEqualToString:[RCTextMessage getObjectName]]) {
                    self.navigationItem.title = NSLocalizedStringFromTable(@"typing", @"RongCloudKit", nil);
                }else if ([typingStatus.contentType isEqualToString:[RCVoiceMessage getObjectName]]){
                    self.navigationItem.title = NSLocalizedStringFromTable(@"Speaking", @"RongCloudKit", nil);
                }
                
            }
        });
    }
}

-(void)handleAppResume{
    if ([RCIM sharedRCIM].enableReadReceipt && self.conversationType == ConversationType_PRIVATE) {
        long long lastReceiveMessageSendTime = 0;
        for (int i = 0; i < self.conversationDataRepository.count; i++) {
            RCMessage *rcMsg = [self.conversationDataRepository objectAtIndex:i];
            RCMessageModel *model = [[RCMessageModel alloc] initWithMessage:rcMsg];
            if (model.messageDirection == MessageDirection_RECEIVE ) {
                lastReceiveMessageSendTime = model.sentTime;//这里同一条消息竟然出现接收到的senttime 比对方发送者的sentime 要小？？serverbug
            }
        }
        //如果是单聊并且开启了已读回执，需要发送已读回执消息
        if(lastReceiveMessageSendTime != 0)
        {
            [[RCIMClient sharedRCIMClient]sendReadReceiptMessage:self.conversationType targetId:self.targetId time:lastReceiveMessageSendTime];
        }
    }
}
@end

