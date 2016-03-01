//
//  RCConversationListViewController.m
//  RongIMKit
//
//  Created by xugang on 15/1/22.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCConversationListViewController.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCConversationCell.h"
#import "RCIM.h"
#import "RCConversationViewController.h"
#import "RCNetworkIndicatorView.h"
#import "RCPublicServiceChatViewController.h"

static NSString *cellReuseIndex = @"rc.conversationList.cellReuseIndex";

extern dispatch_queue_t __rc__conversationList_refresh_queue;

@interface RCConversationListViewController () <UITableViewDataSource, UITableViewDelegate, RCConversationCellDelegate>

@property(nonatomic) BOOL isConverstaionListAppear;
@property(nonatomic) BOOL isDisplayNetworkIndicatorView;
@property(nonatomic) BOOL needRefreshAfterAllMessageReceived;
//在NavigatorBar中显示连接中的View
@property(nonatomic, strong) UIView *connectionStatusView;
@property(nonatomic, strong) UIView *navigationTitleView;

- (void)getConversationListFromDataBase;
- (void)sortConversationListDataSource;
//- (void)showEmptyConversationView;

/**
 *  接收消息通知
 *
 *  @param notification 包含消息的通知
 */
- (void)didReceiveMessageNotification:(NSNotification *)notification;

- (void)updateTableCellWithReceivedMessage:(RCMessage *)receivedMessage;
@end

@implementation RCConversationListViewController

- (id)initWithDisplayConversationTypes:(NSArray *)conversationTypeArray1
            collectionConversationType:(NSArray *)conversationTypeArray2 {
    self = [super init];
    if (self) {
        [self rcinit];
        self.displayConversationTypeArray = conversationTypeArray1;
        self.collectionConversationTypeArray = conversationTypeArray2;
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
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self rcinit];
    }
    return self;
}

- (void)rcinit {
    // self.isNeedToShowNetworkIndicator    = NO;
    self.isConverstaionListAppear = NO;
    self.conversationListTableView = nil;
    self.conversationListDataSource = nil;
    self.displayConversationTypeArray = nil;
    self.collectionConversationTypeArray = nil;
    self.isDisplayNetworkIndicatorView = NO;
    self.isEnteredToCollectionViewController = NO;
    self.isShowNetworkIndicatorView=YES;
    self.cellBackgroundColor=[UIColor whiteColor];
    self.topCellBackgroundColor=[[UIColor alloc] initWithRed:0xf2 / 255.f
                                                       green:0xfa / 255.f
                                                        blue:0xff / 255.f
                                                       alpha:1];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveMessageNotification:)
                                                 name:RCKitDispatchMessageNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onConnectionStatusChangedNotification:)
                                                 name:RCKitDispatchConnectionStatusChangedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                             selector:@selector(receiveMessageHasReadNotification:)
                                                 name:RCLibDispatchReadReceiptNotification
                                                 object:nil];

}
- (void)updateNetworkIndicator:(BOOL)reloadTable {
    RCConnectionStatus __status = [[RCIMClient sharedRCIMClient] getConnectionStatus];
    
    if (ConnectionStatus_NETWORK_UNAVAILABLE == __status || ConnectionStatus_UNKNOWN == __status ||
        ConnectionStatus_Unconnected == __status) {

        self.isDisplayNetworkIndicatorView = YES;
        if (reloadTable) {
            [self.conversationListTableView reloadData];
        }
    } else if (ConnectionStatus_Connecting == __status) {

    } else {
        [_networkIndicatorView removeFromSuperview];
        self.isDisplayNetworkIndicatorView = NO;
        if (reloadTable) {
            [self.conversationListTableView reloadData];
        }
    }
}

- (void)updateConnectionStatusView {
    if (self.isEnteredToCollectionViewController || !self.showConnectingStatusOnNavigatorBar) {
        return;
    }
    RCConnectionStatus __status = [[RCIMClient sharedRCIMClient] getConnectionStatus];
    
    if (ConnectionStatus_Connecting == __status) {
        [self showConnectingView];
    } else {
        [self hideConnectingView];
    }
    
    //接口向后兼容 [[++
    [self performSelector:@selector(updateConnectionStatusOnNavigatorBar)];
    //接口向后兼容 --]]
}

- (void)onConnectionStatusChangedNotification:(NSNotification *)status {
    __weak typeof(&*self) __blockSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [__blockSelf updateConnectionStatusView];
        [__blockSelf updateNetworkIndicator:YES];
    });
}

- (void)showConnectingView {
    UINavigationItem *visibleNavigationItem = nil;
    if (self.tabBarController) {
        visibleNavigationItem = self.tabBarController.navigationItem;
    } else if (self.navigationItem) {
        visibleNavigationItem = self.navigationItem;
    }
    
    if (visibleNavigationItem) {
        if (![visibleNavigationItem.titleView isEqual:self.connectionStatusView]) {
            self.navigationTitleView = visibleNavigationItem.titleView;
            visibleNavigationItem.titleView = self.connectionStatusView;
        }
    }
}

- (void)hideConnectingView {
    UINavigationItem *visibleNavigationItem = nil;
    if (self.tabBarController) {
        visibleNavigationItem = self.tabBarController.navigationItem;
    } else if (self.navigationItem) {
        visibleNavigationItem = self.navigationItem;
    }
    
    if (visibleNavigationItem) {
        if ([visibleNavigationItem.titleView isEqual:self.connectionStatusView]) {
            visibleNavigationItem.titleView = self.navigationTitleView;
        } else {
            self.navigationTitleView = visibleNavigationItem.titleView;
        }
    }

    //接口向后兼容 [[++
    [self performSelector:@selector(setNavigationItemTitleView)];
    //接口向后兼容 --]]
}

- (UIView *)connectionStatusView {
    if (!_connectionStatusView) {
        _connectionStatusView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
        
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] init];
        [indicatorView startAnimating];
        [_connectionStatusView addSubview:indicatorView];
        
        NSString *loading = NSLocalizedStringFromTable(@"Connecting...", @"RongCloudKit", nil);
        CGSize textSize = CGSizeZero;
        if (IOS_FSystenVersion < 7.0) {
            textSize = RC_MULTILINE_TEXTSIZE_LIOS7(loading, [UIFont systemFontOfSize:16], CGSizeMake(_connectionStatusView.frame.size.width, 2000), NSLineBreakByTruncatingTail);
        }else {
            textSize = RC_MULTILINE_TEXTSIZE_GEIOS7(loading, [UIFont systemFontOfSize:16], CGSizeMake(_connectionStatusView.frame.size.width, 2000));
        }
        
        CGRect frame = CGRectMake((_connectionStatusView.frame.size.width - (indicatorView.frame.size.width + textSize.width + 3))/2, (_connectionStatusView.frame.size.height - indicatorView.frame.size.height)/2, indicatorView.frame.size.width, indicatorView.frame.size.height);
        indicatorView.frame = frame;
        frame = CGRectMake(indicatorView.frame.origin.x + 14 + indicatorView.frame.size.width, (_connectionStatusView.frame.size.height - textSize.height)/2, textSize.width, textSize.height);
        UILabel *label = [[UILabel alloc] initWithFrame:frame];
        [label setFont:[UIFont systemFontOfSize:16]];
        [label setText:loading];
        [label setTextColor:[UIColor whiteColor]];
        [_connectionStatusView addSubview:label];
    }
    
    return _connectionStatusView;
}

//历史遗留接口
- (void)updateConnectionStatusOnNavigatorBar {
    
}

//历史遗留接口
- (void)setNavigationItemTitleView {
    
}

- (void)setDisplayConversationTypes:(NSArray *)conversationTypeArray {
    self.displayConversationTypeArray = conversationTypeArray;
}

- (void)setCollectionConversationType:(NSArray *)conversationTypeArray {
    self.collectionConversationTypeArray = conversationTypeArray;
}

- (void)refreshConversationTableViewIfNeeded {
    __weak typeof(&*self) __bloackself = self;
    self.needRefreshAfterAllMessageReceived = NO;
    dispatch_async(__rc__conversationList_refresh_queue, ^{
      [__bloackself getConversationListFromDataBase];
    });
}

- (void)getConversationListFromDataBase
{
    RCConnectionStatus status = [[RCIMClient sharedRCIMClient] getConnectionStatus];
    self.needRefreshAfterAllMessageReceived = NO;
    if (nil == self.displayConversationTypeArray || self.displayConversationTypeArray.count == 0) {
        return;
    }
    //[self.conversationListaDataSource removeAllObjects];
    NSMutableArray *__dataSource = [[NSMutableArray alloc] init];

    if (status != ConnectionStatus_SignUp) {
        NSArray *__tempArray = [[RCIMClient sharedRCIMClient] getConversationList:self.displayConversationTypeArray];

        for (int i = 0; i < __tempArray.count; i++) {
            RCConversation *conversation = [__tempArray objectAtIndex:i];

            RCConversationModelType modelType;
            
            //筛选请求添加好友的系统消息，用于生成自定义会话类型的cell
            if(conversation.conversationType == ConversationType_SYSTEM && [conversation.lastestMessage isMemberOfClass:[RCContactNotificationMessage class]])
            {
                modelType = RC_CONVERSATION_MODEL_TYPE_CUSTOMIZATION;
            }else{
                modelType = RC_CONVERSATION_MODEL_TYPE_NORMAL;
            }
            
            if (conversation.conversationType == ConversationType_APPSERVICE ||
                conversation.conversationType == ConversationType_PUBLICSERVICE) {
                modelType = RC_CONVERSATION_MODEL_TYPE_PUBLIC_SERVICE;
            }
            RCConversationModel *model = [[RCConversationModel alloc] init:modelType conversation:conversation extend:nil];
            [__dataSource addObject:model];
        }
    }
    __dataSource = [self willReloadTableData:__dataSource];
    
    __weak typeof(&*self) __bloackself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
         __bloackself.conversationListDataSource = __dataSource;
        [__bloackself sortConversationListDataSource];
      if (0 == self.conversationListDataSource.count) {
          [self showEmptyConversationView];
      } else {
          [self hideEmptyConversationView];
      }
      [__bloackself.conversationListTableView reloadData];
    });
}

//筛选，聚合数据源.
- (void)sortConversationListDataSource {
    if (nil == self.collectionConversationTypeArray) {
        return;
    }

    for (NSInteger i = 0; i < self.collectionConversationTypeArray.count; i++) {
        NSNumber *collectionTypeNumber = [self.collectionConversationTypeArray objectAtIndex:i];
        RCConversationType collectionConversationType = collectionTypeNumber.intValue;
        RCConversationModel *lastModel = nil;
        NSInteger lastModelIndex = -1;

        NSInteger unreadMsgCount = 0;
        BOOL isTop = NO;
        for (NSInteger j = self.conversationListDataSource.count - 1; j >= 0; j--) {
            RCConversationModel *tempModel = [self.conversationListDataSource objectAtIndex:j];
            if (tempModel.conversationType == collectionConversationType) {
                lastModel = tempModel;
                lastModelIndex = j;
                [self.conversationListDataSource removeObjectAtIndex:j];
                unreadMsgCount += tempModel.unreadMessageCount;
                isTop |= tempModel.isTop;
            }
        }
        if (-1 != lastModelIndex) {
            lastModel.conversationModelType = RC_CONVERSATION_MODEL_TYPE_COLLECTION;
            lastModel.unreadMessageCount = unreadMsgCount;
            lastModel.isTop = isTop;
            [self.conversationListDataSource insertObject:lastModel atIndex:lastModelIndex];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (IOS_FSystenVersion>=7.0)
    {
        self.extendedLayoutIncludesOpaqueBars = YES;
    }
    
    self.conversationListDataSource = [[NSMutableArray alloc] init];
    // set UITableViewDataSource & UITableViewDelegate for this class

    self.conversationListTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.conversationListTableView.dataSource = self;
    self.conversationListTableView.delegate = self;
    self.conversationListTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;

    [self.view addSubview:self.conversationListTableView];

    _networkIndicatorView = [[RCNetworkIndicatorView alloc]
        initWithText:NSLocalizedStringFromTable(@"ConnectionIsNotReachable", @"RongCloudKit", nil)];
    _networkIndicatorView.backgroundColor = HEXCOLOR(0xfbe8e8);
    [_networkIndicatorView setFrame:CGRectMake(0, 0, self.view.bounds.size.width, 40)];
    
    RCNetworkStatus stauts = [[RCIMClient sharedRCIMClient] getCurrentNetworkStatus];

    if (RC_NotReachable == stauts) {
        self.isDisplayNetworkIndicatorView = YES;
    } else {
        self.isDisplayNetworkIndicatorView = NO;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.isConverstaionListAppear = YES;
    [self updateNetworkIndicator:NO];
    [self refreshConversationTableViewIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateConnectionStatusView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.isConverstaionListAppear = NO;
    [self.conversationListTableView setEditing:NO];
    [self hideEmptyConversationView];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@synthesize emptyConversationView=_emptyConversationView;

-(UIView *)emptyConversationView {
    if (!_emptyConversationView) {
        _emptyConversationView = [[UIImageView alloc] initWithImage:IMAGE_BY_NAMED(@"no_message_img")];
        CGRect emptyRect = _emptyConversationView.frame;
        emptyRect.origin.x = (self.view.frame.size.width - emptyRect.size.width) / 2;
        emptyRect.origin.y = (self.view.frame.size.width - emptyRect.size.height) / 2;
        [_emptyConversationView setFrame:emptyRect];
        [self.view addSubview:_emptyConversationView];
    }
    return _emptyConversationView;
}

-(void)setEmptyConversationView:(UIView *)emptyConversationView {
    if (_emptyConversationView) {
        [_emptyConversationView removeFromSuperview];
    }
    _emptyConversationView = emptyConversationView;
    [self.view addSubview:_emptyConversationView];
}

- (void)showEmptyConversationView {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.emptyConversationView.hidden = NO;
    });
}

- (void)hideEmptyConversationView {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_emptyConversationView) {
            self.emptyConversationView.hidden = YES;
        }
    });
}

// 该接口已经废弃，仅保留用于SDK旧版本兼容，避免用户使用接口报错
- (void)resetConversationListBackgroundViewIfNeeded {
}

#pragma mark <UITableViewDataSource>
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // default value, sub class must to override
    return [self.conversationListDataSource count];
}

/**
 * returned this value from sub class if this function is override, otherwise,
 * returned from this super class
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellReuseIndex = @"rc.conversationList.cellReuseIndex";

    RCConversationModel *model = nil;
    if (self.conversationListDataSource && [self.conversationListDataSource count]) {
        model = [self.conversationListDataSource objectAtIndex:indexPath.row];
    }

    if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_CUSTOMIZATION) {
        RCConversationBaseCell *userCustomCell =
            [self rcConversationListTableView:tableView cellForRowAtIndexPath:indexPath];
        [self willDisplayConversationTableCell:userCustomCell atIndexPath:indexPath];
        userCustomCell.selectionStyle = UITableViewCellSelectionStyleDefault;
        return userCustomCell;
    }

    RCConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIndex];
    
    if (!cell) {
        cell = [[RCConversationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellReuseIndex];
    }
    cell.delegate = self;
    cell.isShowNotificationNumber = YES;
    if (model.conversationType == ConversationType_APPSERVICE ||
        model.conversationType == ConversationType_PUBLICSERVICE) {
        RCPublicServiceProfile *serviceProfile = [[RCIMClient sharedRCIMClient] getPublicServiceProfile:(RCPublicServiceType)model.conversationType publicServiceId:model.targetId];
        if (![serviceProfile.publicServiceId isEqualToString:@""] && !serviceProfile.publicServiceType == 0) {
            [[RCIMClient sharedRCIMClient] getConversationNotificationStatus:model.conversationType
                                                                    targetId:model.targetId
                                                                     success:^(RCConversationNotificationStatus nStatus) {
                                                                         if (DO_NOT_DISTURB == nStatus) {
                                                                             cell.enableNotification = NO;
                                                                         } else if (NOTIFY == nStatus) {
                                                                             cell.enableNotification = YES;
                                                                         }
                                                                     }
                                                                       error:^(RCErrorCode status){
                                                                           
                                                                       }];

        }
    }else{

    // getConversationNotificationStatus, and set the indicator icon
        [[RCIMClient sharedRCIMClient] getConversationNotificationStatus:model.conversationType
            targetId:model.targetId
            success:^(RCConversationNotificationStatus nStatus) {
              if (DO_NOT_DISTURB == nStatus) {
                  cell.enableNotification = NO;
              } else if (NOTIFY == nStatus) {
                  cell.enableNotification = YES;
              }
            }
            error:^(RCErrorCode status){

            }];
    }
    cell.topCellBackgroundColor = self.topCellBackgroundColor;
    cell.cellBackgroundColor = self.cellBackgroundColor;
    [cell setDataModel:model];
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    [self willDisplayConversationTableCell:cell atIndexPath:indexPath];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCConversationModel *model = nil;

    if ([self.conversationListDataSource count]) {
        model = [self.conversationListDataSource objectAtIndex:indexPath.row];
        if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_CUSTOMIZATION) {
            return [self rcConversationListTableView:tableView heightForRowAtIndexPath:indexPath];
        }
    }

    // defined by RongIMKit SDK
    CGFloat margin = 21.0f;
    return ([RCIM sharedRCIM].globalConversationPortraitSize.height + margin);
}
- (void)setConversationAvatarStyle:(RCUserAvatarStyle)avatarStyle {
    [RCIM sharedRCIM].globalConversationAvatarStyle = avatarStyle;
}
- (void)setConversationPortraitSize:(CGSize)size {
    [RCIM sharedRCIM].globalConversationPortraitSize = size;
}

#pragma mark <UITableViewDelegate>
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (0 != self.conversationListDataSource.count) {
        RCConversationModel *model = [self.conversationListDataSource objectAtIndex:indexPath.row];
        if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_PUBLIC_SERVICE) {
            NSLog(@"从2.3.0版本开始，公众号会话点击处理放到demo中处理，请参考RCDChatListViewController文件中的onSelectedTableRow函数");
        }
        [self onSelectedTableRow:model.conversationModelType conversationModel:model atIndexPath:indexPath];
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    DebugLog(@"%s", __FUNCTION__);
    //    if (self.isNeedToShowNetworkIndicator) {
    //        return 30;
    //    }
    if (_isShowNetworkIndicatorView) {
        if (self.isDisplayNetworkIndicatorView) {
            return 40.0f;
        } else {
            return 0;
        }
    }else
    {
        return 0;
    }
    
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (_isShowNetworkIndicatorView) {
        if (self.isDisplayNetworkIndicatorView) {
            return _networkIndicatorView;
        }else
        {
            return nil;
        }
    }
    else {
        return nil;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        DebugLog(@"[RongIMKit]: Start to delete");
        RCConversationModel *model = [self.conversationListDataSource objectAtIndex:indexPath.row];
        if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_NORMAL ||
            model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_PUBLIC_SERVICE) {
            [[RCIMClient sharedRCIMClient] removeConversation:model.conversationType targetId:model.targetId];
            [self.conversationListDataSource removeObjectAtIndex:indexPath.row];
            [self.conversationListTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                                  withRowAnimation:UITableViewRowAnimationFade];

        } else if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_COLLECTION) {

            [[RCIMClient sharedRCIMClient]
                clearConversations:[NSArray arrayWithObject:[NSNumber numberWithInteger:model.conversationType]]];
            [self.conversationListDataSource removeObjectAtIndex:indexPath.row];
            [self.conversationListTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                                  withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [self rcConversationListTableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath];
        }
        [self didDeleteConversationCell:model];

        if (0 == self.conversationListDataSource.count) {
            if (self.isEnteredToCollectionViewController) {
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                [self showEmptyConversationView];
            }
        }
        [self notifyUpdateUnreadMessageCount];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        DebugLog(@"UITableViewCellEditingStyleInsert");
    }
}

- (void)didDeleteConversationCell:(RCConversationModel *)model {

}

- (void)rcConversationListTableView:(UITableView *)tableView
                 commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
                  forRowAtIndexPath:(NSIndexPath *)indexPath {
}

//继承需要重写的方法
#pragma mark override
- (void)onSelectedTableRow:(RCConversationModelType)conversationModelType
         conversationModel:(RCConversationModel *)model
               atIndexPath:(NSIndexPath *)indexPath {
}

- (NSMutableArray *)willReloadTableData:(NSMutableArray *)dataSource {
    return dataSource;
}

- (void)willDisplayConversationTableCell:(RCConversationBaseCell *)cell atIndexPath:(NSIndexPath *)indexPath {
}

/**
 * returned this value from sub class if this function is override, otherwise,
 * returned from this super class
 */
- (RCConversationBaseCell *)rcConversationListTableView:(UITableView *)tableView
                                  cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (CGFloat)rcConversationListTableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64.5f;
}

//点击头像
- (void)didTapCellPortrait:(RCConversationModel *)model {
}

- (void)didLongPressCellPortrait:(RCConversationModel *)model
{
    
}

- (void)didReceiveMessageNotification:(NSNotification *)notification {
//    if (!message.conversationType == ConversationType_CUSTOMERSERVICE) {
//
    
        if (self.isConverstaionListAppear) {
            RCMessage *receivedMsg_ = notification.object;
            
            if (nil != self.displayConversationTypeArray && [self.displayConversationTypeArray count] > 0) {
                for (int i=0; i<[self.displayConversationTypeArray count]; i++) {
                    if (receivedMsg_.conversationType == (RCConversationType)[self.displayConversationTypeArray[i] integerValue]) {
                        NSNumber *left = [notification.userInfo objectForKey:@"left"];
                        if (0 == left.integerValue) {
                            if (self.needRefreshAfterAllMessageReceived) {
                                [self refreshConversationTableViewIfNeeded];
                            } else {
                                if ((!receivedMsg_.content && receivedMsg_.messageId > 0 && [RCIM sharedRCIM].showUnkownMessage)
                                    || ([[receivedMsg_.content class] persistentFlag] & MessagePersistent_ISPERSISTED)) {
                                    [self updateTableCellWithReceivedMessage:receivedMsg_];
                                    [self hideEmptyConversationView];
                                }
                            }
                            [self notifyUpdateUnreadMessageCount];
                        } else {
                            self.needRefreshAfterAllMessageReceived = YES;
                        }
                    }
                }
                
                
            }
        } else {
            //Notify update unread message count
            NSNumber *left = [notification.userInfo objectForKey:@"left"];
            if (0 == left.integerValue) {
                [self notifyUpdateUnreadMessageCount];
            }
        }
//    }
}
-(void)receiveMessageHasReadNotification:(NSNotification *)notification {
    if ([RCIM sharedRCIM].enableReadReceipt) {
        [self refreshConversationTableViewIfNeeded];
    }
}
#pragma mark - private
- (void)updateTableCellWithReceivedMessage:(RCMessage *)receivedMessage {

    RCConversationModel *newReceivedConversationModel_ = nil;
    //获取接受到会话
    RCConversation *receivedConversation_ =
        [[RCIMClient sharedRCIMClient] getConversation:receivedMessage.conversationType targetId:receivedMessage.targetId];

    if (!receivedConversation_) {
        return;
    }
    RCConversationModelType modelType = RC_CONVERSATION_MODEL_TYPE_NORMAL;
    if (receivedConversation_.conversationType == ConversationType_APPSERVICE ||
        receivedConversation_.conversationType == ConversationType_PUBLICSERVICE) {
        modelType = RC_CONVERSATION_MODEL_TYPE_PUBLIC_SERVICE;
        RCPublicServiceProfile *serviceProfile = [[RCIMClient sharedRCIMClient] getPublicServiceProfile:(RCPublicServiceType)receivedMessage.conversationType publicServiceId:receivedMessage.targetId];
        if ([serviceProfile.publicServiceId isEqualToString:@""] && serviceProfile.publicServiceType == 0) {
            return;
        }
    }

    //转换新会话为新会话模型
    newReceivedConversationModel_ =
        [[RCConversationModel alloc] init:modelType conversation:receivedConversation_ extend:nil];

    [self refreshConversationTableViewWithConversationModel:newReceivedConversationModel_];
}

- (void)refreshConversationTableViewWithConversationModel:(RCConversationModel *)conversationModel {
    __weak typeof(&*self) blockSelf_ = self;
    __block BOOL isCollected = NO;
    __block RCConversationModel *newReceivedConversationModel_ = nil;

    newReceivedConversationModel_ = conversationModel;

    /**
     *  当开发者已经设置了需要聚合的类型时，遍历需要聚合的类型数组
     */
    [self.collectionConversationTypeArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

      NSNumber *needed_collectionType = (NSNumber *)obj;

      //如果新消息会话类型等于需要聚合的会话类型, 则该消息需要聚合
      if (newReceivedConversationModel_.conversationType == (RCConversationType)[needed_collectionType integerValue]) {
          *stop = YES;

          //当新消息聚合类型与设置的聚合类型一致是，则该消息需要聚合
          isCollected = YES;

          //把需要聚合的新消息会话与当前数据源比对，如果当前数据源为空，则直接插入一条新聚合Cell
          if (nil != blockSelf_.conversationListDataSource && [blockSelf_.conversationListDataSource count] == 0) {
              *stop = YES;
              newReceivedConversationModel_.conversationModelType = RC_CONVERSATION_MODEL_TYPE_COLLECTION;
              [blockSelf_ insertRowsForReceivedMessageWithConversationModel:newReceivedConversationModel_];
              return;
          }

          //如果当前数据源不为空，则开始遍历
          [blockSelf_.conversationListDataSource enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            RCConversationModel *conversation_enumObj = (RCConversationModel *)obj;

            //如果当前数据源中有聚合类型数据，则判断会话类型是否与新会话类型一致
            if (conversation_enumObj.conversationModelType == RC_CONVERSATION_MODEL_TYPE_COLLECTION) {

                
                //如果一致，则reloadww
                if (conversation_enumObj.conversationType == newReceivedConversationModel_.conversationType) {
                    *stop = YES;
                    //聚合类型更新targetid
                    conversation_enumObj.targetId=newReceivedConversationModel_.targetId;

                    conversation_enumObj.lastestMessage = newReceivedConversationModel_.lastestMessage;

                    //获取当前聚合类型下所有会话的未读消息数
                    conversation_enumObj.unreadMessageCount =
                        [blockSelf_ getUnreadMsgCountFromDataBaseWithConversationType:newReceivedConversationModel_
                                                                                          .conversationType];
                    conversation_enumObj.sentTime = newReceivedConversationModel_.sentTime;
                    [blockSelf_ reloadRowsForReceivedMessage:idx withConversationModel:conversation_enumObj];
                    return;
                }
                //当遍历完成时没有查找到，则新消息为一条新的需要聚合的会话
                if (idx == (blockSelf_.conversationListDataSource.count - 1)) {
                    *stop = YES;
                    newReceivedConversationModel_.conversationModelType = RC_CONVERSATION_MODEL_TYPE_COLLECTION;
                    [blockSelf_ insertRowsForReceivedMessageWithConversationModel:newReceivedConversationModel_];
                    return;
                }
            }

            //当遍历完成时没有查找到，则新消息为一条新的需要聚合的会话
            if (idx == (blockSelf_.conversationListDataSource.count - 1)) {
                *stop = YES;
                newReceivedConversationModel_.conversationModelType = RC_CONVERSATION_MODEL_TYPE_COLLECTION;
                [blockSelf_ insertRowsForReceivedMessageWithConversationModel:newReceivedConversationModel_];
            }
          }];
      }
    }];

    /**
     *  开发者没有设置任何聚合类型，或者新消息的会话类型与需要设置的聚合会话类型全部不一致时，则新消息为普通会话类型消息，判断是否存在当前数据源，如果存在则reload,如果不存在则insert
     */
    if (!isCollected) {

        //把新消息会话与当前数据源比对，如果当前数据源为空，则直接插入一条新Cell
        if (nil != self.conversationListDataSource && [self.conversationListDataSource count] == 0) {
            
            [self insertRowsForReceivedMessageWithConversationModel:newReceivedConversationModel_];
            return;
        }

        //如果当前数据源不为空，则开始遍历
        [self.conversationListDataSource enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
          RCConversationModel *conversation_enumObj = (RCConversationModel *)obj;

          //如果当前数据源中存在与新消息一致的会话类型时，则替换新消息属性，并更新tableview
          if (newReceivedConversationModel_.conversationType == conversation_enumObj.conversationType) {
              if ([conversation_enumObj.targetId isEqualToString:newReceivedConversationModel_.targetId]) {
                  *stop = YES;
                  [blockSelf_ reloadRowsForReceivedMessage:idx withConversationModel:newReceivedConversationModel_];
                  return;
              }

              //当遍历完成时没有查找到，则新消息为一条新的会话
              if (idx == (blockSelf_.conversationListDataSource.count - 1)) {
                  *stop = YES;
                  [blockSelf_ insertRowsForReceivedMessageWithConversationModel:newReceivedConversationModel_];
                  return;
              }
              return;
          }

          if (!blockSelf_.isEnteredToCollectionViewController) {
              //当遍历完成时没有查找到，则新消息为一条新的会话
              if (idx == (blockSelf_.conversationListDataSource.count - 1)) {
                  *stop = YES;
                  [blockSelf_ insertRowsForReceivedMessageWithConversationModel:newReceivedConversationModel_];
              }
          }
        }];
    }
}

- (NSUInteger)getUnreadMsgCountFromDataBaseWithConversationType:(RCConversationType)conversationType {
    __block NSUInteger msgCount_ = 0;

    NSArray *conversationData_ = [[RCIMClient sharedRCIMClient] getConversationList:@[ @(conversationType) ]];
    [conversationData_ enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      RCConversation *indexConversation_ = (RCConversation *)obj;
      msgCount_ += indexConversation_.unreadMessageCount;
    }];

    return msgCount_;
}
- (void)reloadRowsForReceivedMessage:(NSInteger)index withConversationModel:(RCConversationModel *)conversationModel {
    __weak typeof(&*self) __blockSelf = self;

    //更新tableview
    dispatch_async(dispatch_get_main_queue(), ^{
      NSUInteger pos = 0;
      /*
       * 如果收到消息的会话是置顶的，则设置插入位置为0.
       * 否者则插入到第一个非置顶的位置
       */
      if (!conversationModel.isTop) {
          //查找第一个非置顶位置
          for (; pos < self.conversationListDataSource.count; pos++) {
              RCConversationModel *model = self.conversationListDataSource[pos];
              if (!model.isTop) {
                break;
              }
          }
          if (pos > self.conversationListDataSource.count) {
              pos = self.conversationListDataSource.count;
          }
      }

      NSIndexPath *_indexPath = [NSIndexPath indexPathForRow:index inSection:0];
      NSIndexPath *toIndexPath_ = [NSIndexPath indexPathForRow:pos inSection:0];
      [__blockSelf.conversationListTableView moveRowAtIndexPath:_indexPath toIndexPath:toIndexPath_];
      //更新整理后的数据到当前数据源
      // id movedObj_ = [self.conversationListDataSource objectAtIndex:index];
      [self.conversationListDataSource removeObjectAtIndex:index];
      [self.conversationListDataSource insertObject:conversationModel atIndex:pos];

      [__blockSelf.conversationListTableView beginUpdates];
      if (index == pos) {
        [__blockSelf.conversationListTableView reloadRowsAtIndexPaths:@[ toIndexPath_ ]
                                                    withRowAnimation:UITableViewRowAnimationNone];
      } else {
        [__blockSelf.conversationListTableView reloadRowsAtIndexPaths:@[ toIndexPath_ ]
                                                     withRowAnimation:UITableViewRowAnimationAutomatic];
      }

      [__blockSelf.conversationListTableView endUpdates];
    });
}

- (void)insertRowsForReceivedMessageWithConversationModel:(RCConversationModel *)conversationModel {
    __weak typeof(&*self) __blockSelf = self;


    //更新tableview
    dispatch_async(dispatch_get_main_queue(), ^{
      NSUInteger pos = 0;
      /*
       * 如果收到消息的会话是置顶的，则设置插入位置为0.
       * 否者则插入到第一个非置顶的位置
       */
      if (!conversationModel.isTop) {
        //查找第一个非置顶位置
        for (; pos < self.conversationListDataSource.count; pos++) {
          RCConversationModel *model = self.conversationListDataSource[pos];
          if (!model.isTop) {
              break;
          }
        }
        if (pos > self.conversationListDataSource.count) {
          pos = self.conversationListDataSource.count;
        }
      }
      [self.conversationListDataSource insertObject:conversationModel atIndex:pos];
      NSIndexPath *_indexPath = [NSIndexPath indexPathForRow:pos inSection:0];

      [__blockSelf.conversationListTableView beginUpdates];
      [__blockSelf.conversationListTableView insertRowsAtIndexPaths:@[ _indexPath ]
                                                   withRowAnimation:UITableViewRowAnimationAutomatic];
      [__blockSelf.conversationListTableView endUpdates];
    });
}

- (void)notifyUpdateUnreadMessageCount {
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RCKitDispatchMessageNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:RCKitDispatchConnectionStatusChangedNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:RCLibDispatchReadReceiptNotification
                                                  object:nil];
}

@end
