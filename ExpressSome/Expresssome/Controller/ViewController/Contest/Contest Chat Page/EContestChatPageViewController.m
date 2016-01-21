//
//  EGroupChatViewController.m
//  Expresssome
//
//  Created by Thai Nguyen on 4/15/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import "EContestChatPageViewController.h"
#import "EMessageView.h"
#import "EGroupDetailViewController.h"
#import "AFNetworking.h"
#import "EConstant.h"
#import "SDWebImageManager.h"
#import "ECommon.h"
#import "EMessage.h"
#import "Reachability.h"
#import "JSQMessagesAvatarImage.h"
#import "JSQMessagesAvatarImageFactory.h"
#import "JSQSystemSoundPlayer.h"
#import "AppDelegate.h"
#import "EContestPageViewController.h"
#import "EContestVoteViewController.h"

@interface EContestChatPageViewController ()
{
    BOOL resendMessage;
    NSString *lastMessage;
    BOOL isDisplaying;
    UIRefreshControl *refreshControl;
    NSInteger currentPage;
    NSInteger totalPage;
    BOOL scrollDirectionDetermined;
    BOOL firstTimeGetMessage;
    BOOL isLoading;
}

@end

@implementation EContestChatPageViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    __typeof (self) __weak pSelf = self;
    // Initialize variables
    firstTimeGetMessage = TRUE;
    self.messageGroupData = [[EMessageGroupData alloc] init];
    
    
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(globalQueue, ^{
        __typeof (pSelf) __strong mySelf = pSelf;
        
        if (IS_NOT_NULL([_contestInfo objectForKey:@"id"])) {
            _chatSocket = [[EChatSocket alloc] initWithContestId:[_contestInfo objectForKey:@"id"]];
        } else {
            _chatSocket = [[EChatSocket alloc] initWithContestId:[_contestInfo objectForKey: @"contestId"]];
            
        }
        
        
        _chatSocket.delegate = mySelf;
        
    });
    
    
    // Hide info button
    self.infoButton.hidden = YES;
    
    
    // Add refresh control to collection view
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(loadMoreMessages)
             forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:refreshControl];
    self.collectionView.alwaysBounceVertical = YES;
    
    // Set title
    
    if (IS_NOT_NULL([_contestInfo objectForKey:@"name"])) {
        self.titleLabel.text = [_contestInfo objectForKey:@"name"];//[_contestInfo objectForKey:@"contestName"];
    } else {
        self.titleLabel.text = [_contestInfo objectForKey:@"contestName"];
    }
    
    // Set sender display name
    self.senderId = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%ld", (long)[[[EUserData getInstance] objectForKey:USER_ID_UD_KEY] integerValue]]];
    self.senderDisplayName = kJSQDemoAvatarDisplayNameSquires;
    
    
    // Custom input chat view
    UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [sendButton setFrame:CGRectMake(262.0f, 465.0f, 53.0f, 30.0f)];
    [sendButton setBackgroundImage:[UIImage imageNamed:@"btn_send_chat.png"] forState:UIControlStateNormal];
    [sendButton setTitle:@"Send" forState:UIControlStateNormal];
    self.inputToolbar.contentView.rightBarButtonItem = sendButton;
    self.inputToolbar.sendButtonOnRight = YES;
    self.inputToolbar.contentView.leftBarButtonItem = nil;
    
    // Get new message in case have internet connection after lost connection
    [[QNetHelper getInstance] setStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        __typeof (pSelf) __strong mySelf = pSelf;
        if(status == AFNetworkReachabilityStatusReachableViaWWAN || status == AFNetworkReachabilityStatusReachableViaWiFi) {
            // Reset variables
            currentPage = 1;
            totalPage = 1;
            firstTimeGetMessage = TRUE;
            [mySelf getMessageByPage:currentPage];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    __typeof (self) __weak pSelf = self;
    // Add observer for application lifecycle
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveMessageNotificaton:) name:kNotificationKeyReceiveMessage object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appplicationDidActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterBackground:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    
    [super viewWillAppear:animated];
    [self.tabBarController.tabBar setHidden:YES];
    
    isDisplaying = TRUE;
    
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(globalQueue, ^{
        
        __typeof (pSelf) __strong mySelf = pSelf;
        // Hide
        if([[QNetHelper getInstance] hasInternetConnection]) {
            if(![_chatSocket isConnected]) {
                //[MBProgressHUD showHUDAddedTo:self.view animated:YES];
                _chatSocket.delegate = mySelf;
                [_chatSocket connect];
            }
            else {
                if(![_chatSocket isAuthen]) {
                    [_chatSocket authen];
                }
                else {
                    if(![_chatSocket isJoinedContest]) {
                        [_chatSocket join];
                    }
                }
            }
        }
        
    });
    
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    isDisplaying = FALSE;
    
    // Remove observer
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(globalQueue, ^{
        
        // Disconnect socket
        if(_chatSocket && [_chatSocket isConnected]) {
            [_chatSocket disconnect];
        }
        
    });
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
     [[SDImageCache sharedImageCache] clearMemory];
}



#pragma mark - UI Actions -
- (IBAction)backButtonTapped:(id)sender {
    
    NSLog(@"backButtonTapped:");
    // Clear input
    self.inputToolbar.contentView.textView.text = @"";
    
    // End editing
    [self.view endEditing:YES];
    
    // Go back
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Messages
- (void)loadMoreMessages {
    
    if(currentPage <= totalPage) {
        [self getMessageByPage:currentPage];
    }
    else {
        [refreshControl endRefreshing];
    }
}

- (void)getMessageByPage:(NSInteger)page {
    // Check internet connection
    if(![[QNetHelper getInstance] hasInternetConnection]) {
        return;
    }
    
    if(firstTimeGetMessage) {
        // Show progress
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
    
    isLoading = TRUE;
    __typeof (self) __weak pSelf = self;
    
    // API url
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl, kAPIGetContestChatMessagesPath];
    
    // Fill params
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:[NSNumber numberWithInteger:page] forKey:kAPIParamPage];
    if (IS_NOT_NULL([_contestInfo objectForKey:@"id"])) {
        [params setObject:[_contestInfo objectForKey:@"id"] forKey:kAPIParamContestID];
    } else {
        
        [params setObject:[_contestInfo objectForKey:@"contestId"] forKey:kAPIParamContestID];
    }
    
    
    // Make a request
    QAPIManager *apiManager = [QAPIManager getInstance];
    apiManager.appendHeaderFields = [[NSMutableDictionary alloc] init];
    [apiManager.appendHeaderFields setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forKey:@"auth-token"];
    [apiManager GET:urlStr params:params completeWithBlock:^(id responseObject, NSError *error) {
        //NSLog(@"GET_CONTEST_CHAT_MESSAGES PAGE %ld %@", currentPage, responseObject);
        __typeof (pSelf) __strong mySelf = pSelf;
        isLoading = FALSE;
        if(!error) {
            NSDictionary *dataDict = [responseObject objectForKey:kAPIResponseData];
            NSDictionary *paginatorDict = [dataDict objectForKey:@"paginate"];
            totalPage = [[paginatorDict objectForKey:@"totalPage"] integerValue];
            NSArray *messageList = [dataDict objectForKey:@"list"];//[[NSMutableArray alloc] initWithArray:[dataDict objectForKey:@"list"]];
            
            // Access message in messageList
            for(NSDictionary *messageDict in messageList) {
                [mySelf addMessageWithDataWithoutSort:messageDict];
            }
            
            // Sort result
            [mySelf.messageGroupData.messages sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                EMessageModel *msg1 = (EMessageModel *)obj1;
                EMessageModel *msg2 = (EMessageModel *)obj2;
                return [msg1.date compare:msg2.date];
            }];
            
            // Reload data
            [self.collectionView reloadSections: [NSIndexSet indexSetWithIndex: 0]];
           
            [self.collectionView performBatchUpdates:^{}
                                          completion:^(BOOL finished) {
                                              /// collection-view finished reload
                                              __typeof (pSelf) __strong mySelf = pSelf;
                                              if(finished) {
                                                  // Scroll to bottom
                                                  if(firstTimeGetMessage == TRUE) {
                                                      // Hide progress
                                                      [MBProgressHUD hideAllHUDsForView:mySelf.view animated:YES];
                                                      firstTimeGetMessage = FALSE;
                                                      [mySelf finishReceivingMessageAnimated:YES];
                                                  }
                                              }
                                          }];
            // Increase page number
            currentPage++;
            
            // Stop refreshing
            [refreshControl endRefreshing];
        }
        else {
            if(firstTimeGetMessage == TRUE) {
                // Hide progress
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            }
            
            if([EJSONHelper valueFromData:[responseObject objectForKey:kAPIResponseCode]]) {
                NSInteger codeStatus = [[responseObject objectForKey:kAPIResponseCode] integerValue];
                if(codeStatus == kAPI403ErrorCode) {
                    [[QUIHelper getInstance] showAlertLogoutMessage];
                }
                else if([EJSONHelper valueFromData:[responseObject objectForKey:kAPIResponseMessage]]) {
                    [[QUIHelper getInstance] showAlertWithMessage:[responseObject valueForKey:kAPIResponseMessage]];
                }
            }
            else if([EJSONHelper valueFromData:[responseObject objectForKey:kAPIResponseMessage]]) {
                [[QUIHelper getInstance] showAlertWithMessage:[responseObject valueForKey:kAPIResponseMessage]];
            }
        }
    }];
}

- (EMessageModel *)addMessageWithData:(NSDictionary *)messageData
{
    // Check existed message
    BOOL isExisted = FALSE;
    __typeof (self) __weak pSelf = self;
    if(self.messageGroupData.messages.count > 0) {
        for(EMessageModel *msg in self.messageGroupData.messages) {
            if([msg.msgId isEqual:[messageData objectForKey:@"id"]]) {
                isExisted = TRUE;
                break;
            }
        }
    }
    
    if(!isExisted) {
        EMessageModel *message = [[EMessageModel alloc] initWithData:messageData];
        
        [self.messageGroupData.avatars setObject:[JSQMessagesAvatarImage avatarImageWithPlaceholder:[UIImage imageNamed:@"avatar.png"]] forKey:[NSString stringWithFormat:@"%@", [message.msgUser objectForKey:@"id"]]];
        
        if ([EJSONHelper valueFromData:[message.msgUser objectForKey:@"image"]]) {
            NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl1, [message.msgUser objectForKey:@"image"]];
            [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:urlStr] options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                __typeof (pSelf) __strong mySelf = pSelf;
                if (image) {
                    
                    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                    dispatch_async(globalQueue, ^{
                        JSQMessagesAvatarImage *avatarImage = [JSQMessagesAvatarImageFactory avatarImageWithImage:image diameter:kJSQMessagesCollectionViewAvatarSizeDefault];
                        [mySelf.messageGroupData.avatars setObject:avatarImage forKey:[NSString stringWithFormat:@"%@", [message.msgUser objectForKey:@"id"]]];
                        
                        dispatch_async (dispatch_get_main_queue(), ^{
                            [mySelf.collectionView.collectionViewLayout invalidateLayoutWithContext:[JSQMessagesCollectionViewFlowLayoutInvalidationContext context]];
                            [mySelf.collectionView reloadSections: [NSIndexSet indexSetWithIndex: 0]];

                        });
                    });
                    
                    
                                    }
            }];
        }
        
        [self.messageGroupData.messages addObject:message];
        // Sort result
        [self.messageGroupData.messages sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            EMessageModel *msg1 = (EMessageModel *)obj1;
            EMessageModel *msg2 = (EMessageModel *)obj2;
            return [msg1.date compare:msg2.date];
        }];
        
        return  message;
    }
    return nil;
}



- (EMessageModel *)addMessageWithDataWithoutSort:(NSDictionary *)messageData
{
    // Check existed message
    BOOL isExisted = FALSE;
    __typeof (self) __weak pSelf = self;
    if(self.messageGroupData.messages.count > 0) {
        for(EMessageModel *msg in self.messageGroupData.messages) {
            if([msg.msgId isEqual:[messageData objectForKey:@"id"]]) {
                isExisted = TRUE;
                break;
            }
        }
    }
    
    if(!isExisted) {
        EMessageModel *message = [[EMessageModel alloc] initWithData:messageData];
        
        [self.messageGroupData.avatars setObject:[JSQMessagesAvatarImage avatarImageWithPlaceholder:[UIImage imageNamed:@"avatar.png"]] forKey:[NSString stringWithFormat:@"%@", [message.msgUser objectForKey:@"id"]]];
        
        if ([EJSONHelper valueFromData:[message.msgUser objectForKey:@"image"]]) {
            NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl1, [message.msgUser objectForKey:@"image"]];
            [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:urlStr] options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                __typeof (pSelf) __strong mySelf = pSelf;
                if (image) {
                    
                    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                    dispatch_async(globalQueue, ^{
                        JSQMessagesAvatarImage *avatarImage = [JSQMessagesAvatarImageFactory avatarImageWithImage:image diameter:kJSQMessagesCollectionViewAvatarSizeDefault];
                        [mySelf.messageGroupData.avatars setObject:avatarImage forKey:[NSString stringWithFormat:@"%@", [message.msgUser objectForKey:@"id"]]];
                        
                        dispatch_async (dispatch_get_main_queue(), ^{
                            [mySelf.collectionView.collectionViewLayout invalidateLayoutWithContext:[JSQMessagesCollectionViewFlowLayoutInvalidationContext context]];
                            
                        });
                    });
                    
                    
                }
            }];
        }
        
        [self.messageGroupData.messages addObject:message];
        
        
        return  message;
    }
    return nil;
}

#pragma mark - Notification
- (void)appplicationDidActive:(NSNotification *)notification {
    NSLog(@"Application Did Become Active");
    __typeof (self) __weak pSelf = self;
    // Set false
    resendMessage = FALSE;
    
    // Check content of textView
    NSString *trimmedString = [self.inputToolbar.contentView.textView.text stringByTrimmingCharactersInSet:
                               [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if(trimmedString.length > 0) {
        // Disable send button
        self.inputToolbar.contentView.rightBarButtonItem.enabled = YES;
    }
    else {
        // Disable send button
        self.inputToolbar.contentView.rightBarButtonItem.enabled = NO;
    }
    
    // Hide unwanted progress UI
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(globalQueue, ^{
        __typeof (pSelf) __strong mySelf = pSelf;
        // Reconnect socket
        if(![_chatSocket isConnected]) {
            if([[QNetHelper getInstance] hasInternetConnection]) {
                
                dispatch_async (dispatch_get_main_queue(), ^{
                    
                    [MBProgressHUD showHUDAddedTo:mySelf.view animated:YES];
                });
                
                _chatSocket.delegate = mySelf;
                [_chatSocket connect];
            }
        }
        else {
            if(![_chatSocket isAuthen]) {
                [_chatSocket authen];
            }
            else {
                if(![_chatSocket isJoinedContest]) {
                    [_chatSocket join];
                }
            }
        }
        
    });
    
    
    
    if(isDisplaying) {
        if(!isLoading) {
            // Reset variables
            currentPage = 1;
            totalPage = 1;
            firstTimeGetMessage = 1;
            [self getMessageByPage:currentPage];
        }
    }
}

- (void)applicationWillEnterBackground:(NSNotification *)notification {
    NSLog(@"Application Will Enter Background");
    
    // Set false
    resendMessage = FALSE;
    
    [self.view endEditing:YES];
    
    // Hide unwanted progress UI
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(globalQueue, ^{
        
        // Disconnect socket
        if(_chatSocket && [_chatSocket isConnected]) {
            [_chatSocket disconnect];
        }
    });
    
}

- (void)sendMessage:(NSString *)msg {
    //[JSQSystemSoundPlayer jsq_playMessageSentSound];
    [_chatSocket sendMessage:msg];
}


- (void)finishSendingMessageWithoutClearInput {
    UITextView *textView = self.inputToolbar.contentView.textView;
    
    [self.inputToolbar toggleSendButtonEnabled];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:textView];
    
    [self.collectionView.collectionViewLayout invalidateLayoutWithContext:[JSQMessagesCollectionViewFlowLayoutInvalidationContext context]];
    [self.collectionView reloadSections: [NSIndexSet indexSetWithIndex: 0]];
    
    
    //    if (self.automaticallyScrollsToMostRecentMessage) {
    //        [self scrollToBottomAnimated:YES];
    //    }
}

- (void)receiveMessageNotificaton:(NSNotification *)notification
{
    NSDictionary *data = notification.userInfo;
    if (data) {
        if([EJSONHelper valueFromData:[data objectForKey:@"type"]]) {
            if([[data objectForKey:@"type"] isEqualToString:kMessageGroupChatMsgType]) {
                if([EJSONHelper valueFromData:[data objectForKey:@"room"]]) {
                    NSDictionary *roomInfo = [data objectForKey:@"room"];
                    if([EJSONHelper valueFromData:[roomInfo objectForKey:@"type"]] && [EJSONHelper valueFromData:[roomInfo objectForKey:@"recordId"]]) {
                        if([[roomInfo objectForKey:@"type"] isEqualToString:kContestChatRoomType] && [[roomInfo objectForKey:@"recordId"] integerValue] == [[_contestInfo objectForKey:@"id"] integerValue]) {
                            // Play sound
                            [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
                            
                            // Add message
                            [self addMessageWithData:data];
                            [self finishReceivingMessageAnimated:YES];
                            
                            // Reset current page
                            currentPage = 1;
                            totalPage = 1;
                        } else if([[roomInfo objectForKey:@"type"] isEqualToString:kContestChatRoomType] && [[roomInfo objectForKey:@"recordId"] integerValue] == [[_contestInfo objectForKey:@"contestId"] integerValue]) {
                            // Play sound
                            [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
                            
                            // Add message
                            [self addMessageWithData:data];
                            [self finishReceivingMessageAnimated:YES];
                            
                            // Reset current page
                            currentPage = 1;
                            totalPage = 1;
                        }
                    }
                }
            }
        }
    }
}


#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    NSString *trimmedString = [self.inputToolbar.contentView.textView.text stringByTrimmingCharactersInSet:
                               [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if(trimmedString.length > 0) {
        if([[QNetHelper getInstance] isNetworkAvailable]) {
            // Disable send button
            self.inputToolbar.contentView.rightBarButtonItem.enabled = NO;
            if([_chatSocket isConnected]) {
                if([_chatSocket isAuthen] && [_chatSocket isJoinedContest]) {
                    [self sendMessage:text];
                }
                else {
                    // Set variables
                    lastMessage = text;
                    resendMessage = TRUE;
                    
                    if(![_chatSocket isAuthen]) {
                        [_chatSocket authen];
                    }
                    else {
                        if(![_chatSocket isJoinedContest]) {
                            [_chatSocket join];
                        }
                    }
                }
            }
            else {
                // Show progress
                [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                
                // Reconnect socket
                _chatSocket.delegate = self;
                [_chatSocket connect];
                
                // Set variables
                lastMessage = text;
                resendMessage = TRUE;
            }
        }
    }
    
}

#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.messageGroupData.messages objectAtIndex:indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    EMessageModel *message = [self.messageGroupData.messages objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.messageGroupData.outgoingBubbleImageData;
    }
    
    return self.messageGroupData.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    EMessageModel *message = [self.messageGroupData.messages objectAtIndex:indexPath.item];
    return [self.messageGroupData.avatars objectForKey:message.senderId];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    EMessageModel *message = [self.messageGroupData.messages objectAtIndex:indexPath.item];
    NSAttributedString *result = nil;
    if(message.date) {
        if (indexPath.item == 0)
        {
            result = [[NSAttributedString alloc] initWithString:[[JSQMessagesTimestampFormatter sharedFormatter] relativeDateForDate:message.date]];
        }
        else {
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"yyyy-MM-dd"];
            EMessageModel *beforeMessage = [self.messageGroupData.messages objectAtIndex:indexPath.item - 1];
            NSDate *lastDate = beforeMessage.date;
            if(lastDate) {
                if (![[dateFormat stringFromDate:lastDate] isEqualToString:[dateFormat stringFromDate:message.date]]) {
                    result = [[NSAttributedString alloc] initWithString:[[JSQMessagesTimestampFormatter sharedFormatter] relativeDateForDate:message.date]];
                }
            }
        }
    }
    return result;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    //    EMessageModel *message = [self.messageGroupData.messages objectAtIndex:indexPath.item];
    //
    //    /**
    //     *  iOS7-style sender name labels
    //     */
    //    if ([message.senderId isEqualToString:self.senderId]) {
    //        return nil;
    //    }
    //
    //    if (indexPath.item - 1 > 0) {
    //        EMessageModel *previousMessage = [self.messageGroupData.messages objectAtIndex:indexPath.item - 1];
    //        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
    //            return nil;
    //        }
    //    }
    //
    //    /**
    //     *  Don't specify attributes to use the defaults.
    //     */
    //    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForTextViewAtIndexPath:(NSIndexPath *)indexPath {
    EMessageModel *msg = [self.messageGroupData.messages objectAtIndex:indexPath.item];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:msg.msgText];
    if ([msg.senderId isEqualToString:self.senderId]) {
        [attributedString beginEditing];
        [attributedString addAttribute:NSFontAttributeName value:collectionView.collectionViewLayout.messageBubbleFont range:NSMakeRange(0, msg.text.length)];
        [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, msg.text.length)];
        [attributedString endEditing];
    }
    else {
        [attributedString beginEditing];
        [attributedString addAttribute:NSFontAttributeName value:collectionView.collectionViewLayout.messageBubbleFont range:NSMakeRange(0, msg.text.length)];
        [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor darkGrayColor] range:NSMakeRange(0, msg.text.length)];
        [attributedString endEditing];
    }
    
    return attributedString;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.messageGroupData.messages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Override point for customizing cells
     */
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    /**
     *  Configure almost *anything* on the cell
     *
     *  Text colors, label text, label colors, etc.
     *
     *
     *  DO NOT set `cell.textView.font` !
     *  Instead, you need to set `self.collectionView.collectionViewLayout.messageBubbleFont` to the font you want in `viewDidLoad`
     *
     *
     *  DO NOT manipulate cell layout information!
     *  Instead, override the properties you want on `self.collectionView.collectionViewLayout` from `viewDidLoad`
     */
    // Notification color
    //[UIColor colorWithRed:155./255 green:202./255 blue:229./255 alpha:1]
    
    EMessageModel *msg = [self.messageGroupData.messages objectAtIndex:indexPath.item];
    if (!msg.isMediaMessage) {
        if ([msg.senderId isEqualToString:self.senderId]) {
            JSQMessagesCollectionViewCellOutgoing *outGoingCell = (JSQMessagesCollectionViewCellOutgoing *)cell;
            
            outGoingCell.userNameLabel.text = msg.senderDisplayName;
            outGoingCell.userNameLabel.textColor = [UIColor whiteColor];
            if([EJSONHelper valueFromData:[msg.msgUser objectForKey:@"groupName"]]) {
                outGoingCell.groupNameLabel.text = [msg.msgUser objectForKey:@"groupName"];
            }
            outGoingCell.groupNameLabel.textColor = [UIColor whiteColor];
            outGoingCell.separateLineImageView.backgroundColor = [UIColor whiteColor];
            // Display time label
            outGoingCell.sendTimeLabel.text = [QSystemHelper timeAPMForDate:msg.date];
            outGoingCell.sendTimeLabel.textColor = [UIColor whiteColor];
            [cell.messageBubbleContainerView setBackgroundColor:[UIColor colorWithRed:139./255 green:123./255 blue:158./255 alpha:1]];
            //cell.textView.textColor = [UIColor whiteColor];
        }
        else {
            JSQMessagesCollectionViewCellIncoming *inComingCell = (JSQMessagesCollectionViewCellIncoming *)cell;
            inComingCell.userNameLabel.text = msg.senderDisplayName;
            inComingCell.userNameLabel.textColor = [UIColor grayColor];
            if([EJSONHelper valueFromData:[msg.msgUser objectForKey:@"groupName"]]) {
                inComingCell.groupNameLabel.text = [msg.msgUser objectForKey:@"groupName"];
            }
            inComingCell.groupNameLabel.textColor = [UIColor grayColor];
            inComingCell.separateLineImageView.backgroundColor = [UIColor lightGrayColor];
            // Display time label
            inComingCell.sendTimeLabel.text = [QSystemHelper timeAPMForDate:msg.date];
            inComingCell.sendTimeLabel.textColor = [UIColor grayColor];
            //cell.textView.textColor = [UIColor darkGrayColor];
            [cell.messageBubbleContainerView setBackgroundColor:[UIColor whiteColor]];
        }
        
        // Clear label
        cell.messageBubbleTopLabel.text = @"";
        
        // Clear default bubble image
        cell.messageBubbleImageView.image = nil;
        cell.messageBubbleImageView.highlightedImage = nil;
        
        // Round corner container view
        cell.messageBubbleContainerView.layer.cornerRadius = 20;
        
        //
        //cell.textView.contentInset = UIEdgeInsetsMake(-8,0,-11,0);
    }
    
    return cell;
}



#pragma mark - UICollectionView Delegate

#pragma mark - Custom menu items

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(customAction:)) {
        return YES;
    }
    
    return [super collectionView:collectionView canPerformAction:action forItemAtIndexPath:indexPath withSender:sender];
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(customAction:)) {
        [self customAction:sender];
        return;
    }
    
    [super collectionView:collectionView performAction:action forItemAtIndexPath:indexPath withSender:sender];
}

- (void)customAction:(id)sender
{
    NSLog(@"Custom action received! Sender: %@", sender);
    
    [[[UIAlertView alloc] initWithTitle:@"Custom Action"
                                message:nil
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil]
     show];
}



#pragma mark - JSQMessages collection view flow layout delegate

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat newHeight = 0.0f;
    EMessageModel *message = [self.messageGroupData.messages objectAtIndex:indexPath.item];
    if(message.date) {
        if (indexPath.item == 0)
        {
            newHeight = kJSQMessagesCollectionViewCellLabelHeightDefault;
        }
        else {
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"yyyy-MM-dd"];
            EMessageModel *beforeMessage = [self.messageGroupData.messages objectAtIndex:indexPath.item - 1];
            NSDate *lastDate = beforeMessage.date;
            if(lastDate) {
                if (![[dateFormat stringFromDate:lastDate] isEqualToString:[dateFormat stringFromDate:message.date]]) {
                    newHeight = kJSQMessagesCollectionViewCellLabelHeightDefault;
                }
            }
        }
    }
    
    return newHeight;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  iOS7-style sender name labels
     */
    //    EMessageModel *currentMessage = [self.messageGroupData.messages objectAtIndex:indexPath.item];
    //    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
    //        return 0.0f;
    //    }
    //
    //    if (indexPath.item - 1 > 0) {
    //        EMessageModel *previousMessage = [self.messageGroupData.messages objectAtIndex:indexPath.item - 1];
    //        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
    //            return 0.0f;
    //        }
    //    }
    //
    //    return kJSQMessagesCollectionViewCellLabelHeightDefault;
    return 16.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
}

- (CGSize)collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout messageBubbleSizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize finalSize = CGSizeZero;
    EMessageModel *msg = [self.messageGroupData.messages objectAtIndex:indexPath.item];
    if ([msg isMediaMessage]) {
        finalSize = [[msg media] mediaViewDisplaySize];
    }
    else {
        
        CGFloat maximumTextWidth = 230;
        
        CGRect stringRect = [msg.msgText boundingRectWithSize:CGSizeMake(maximumTextWidth, CGFLOAT_MAX)
                                                      options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                   attributes:@{ NSFontAttributeName : collectionViewLayout.messageBubbleFont }
                                                      context:nil];
        
        CGSize stringSize = CGRectIntegral(stringRect).size;
        
        CGFloat verticalFrameInsets = collectionViewLayout.messageBubbleTextViewFrameInsets.top + collectionViewLayout.messageBubbleTextViewFrameInsets.bottom;
        
        // Username Label Size
        CGRect userNameLabelRect = [msg.senderDisplayName boundingRectWithSize:CGSizeMake(220, CGFLOAT_MAX)
                                                                       options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                                    attributes:@{ NSFontAttributeName : [UIFont boldSystemFontOfSize:13] }
                                                                       context:nil];
        CGSize userNameLabelSize = CGRectIntegral(userNameLabelRect).size;
        
        // Group Name Label Size
        CGRect groupNameLabelRect = [[msg.msgUser objectForKey:@"groupName"] boundingRectWithSize:CGSizeMake(220, CGFLOAT_MAX)
                                                                                          options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                                                       attributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:11] }
                                                                                          context:nil];
        CGSize groupNameLabelSize = CGRectIntegral(groupNameLabelRect).size;
        CGFloat maxWidth = MAX(userNameLabelSize.width, groupNameLabelSize.width)+2.0;
        
        //  same as above, an extra 2 points of magix
        CGFloat finalWidth = MAX(maxWidth, stringSize.width)+2.0;
        CGFloat paddingWidth = 64;
        CGFloat newMaxWidth = 230;
        if(maxWidth >= stringSize.width) {
            paddingWidth = 70;
        }
        
        if (finalWidth >= maximumTextWidth) {
            finalWidth = maximumTextWidth;
        }
        
        // Recalculate with new width
        CGRect textRect = [msg.msgText boundingRectWithSize:CGSizeMake(finalWidth, CGFLOAT_MAX)
                                                    options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                 attributes:@{ NSFontAttributeName : collectionViewLayout.messageBubbleFont }
                                                    context:nil];
        
        CGSize textSize = CGRectIntegral(textRect).size;
        
        finalSize = CGSizeMake(finalWidth+paddingWidth, textSize.height + 36 + 13 + 2.0); // @quandt
    }
    
    return finalSize;
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
    NSLog(@"Load earlier messages!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"Tapped message bubble!");
    EMessageModel *msg = nil;
    if (IS_NOT_NULL(self.messageGroupData) && IS_NOT_NULL(self.messageGroupData.messages) && (indexPath.item < self.messageGroupData.messages.count)) {
        msg = [self.messageGroupData.messages objectAtIndex:indexPath.item];
    }
    
    NSDictionary *contestInfo = msg.msgData;
   // AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];//
    
    if ([msg.msgType isEqualToString: kInviteGroupJoinContestMsgType] || [msg.msgType isEqualToString: kJoinContestMsgType] || [msg.msgType isEqualToString: kUserWinContestMsgType]) {
        
        //ETabBarController *tabBar = (ETabBarController *) appDelegate.window.rootViewController;
        // UINavigationController *navController = (UINavigationController*)tabBar.selectedViewController;
        
        EContestPageViewController *contestPageVC = (EContestPageViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"contestPageVC"];
        contestPageVC.contestInfo = contestInfo;
        contestPageVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:contestPageVC animated:YES];
        
    } else if ([msg.msgType isEqualToString: kStartContestRound2MsgType] || [msg.msgType isEqualToString: kStartContestRound1MsgType] || [msg.msgType isEqualToString: kUserVotePhotoMsgType]) {
        
        EContestVoteViewController *contestVoteVC = (EContestVoteViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"contestVoteVC"];
        contestVoteVC.contestInfo = contestInfo;
        contestVoteVC.contestType = kOnGoingContestType;
        contestVoteVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:contestVoteVC animated:YES];
        
    } else if ([msg.msgType isEqualToString: kFinishContestMsgType]){
        
        EContestVoteViewController *contestVoteVC = (EContestVoteViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"contestVoteVC"];
        contestVoteVC.contestInfo = contestInfo;
        contestVoteVC.contestType = kResultContestType;
        contestVoteVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:contestVoteVC animated:YES];
        
    }
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
}

#pragma mark - UIStatusBar

//- (UIStatusBarStyle)preferredStatusBarStyle {
//    return UIStatusBarStyleLightContent;
//}

#pragma mark - Socket Delegate -
- (void)socketDidConnect {
    __typeof (self) __weak pSelf = self;
    dispatch_async (dispatch_get_main_queue(), ^{
        __typeof (pSelf) __strong mySelf = pSelf;
        // Hide progress
        [MBProgressHUD hideAllHUDsForView:mySelf.view animated:YES];
        
    });
    
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(globalQueue, ^{
        [_chatSocket join];
    });
    
    
//    // Reset message if need
//    if(resendMessage == TRUE) {
//        if(lastMessage) {
//            [self sendMessage:lastMessage];
//            resendMessage = FALSE;
//            lastMessage = nil;
//        }
//    }
}

- (void)socketDidJoinContest {
    
    __typeof (self) __weak pSelf = self;
    dispatch_async (dispatch_get_main_queue(), ^{
        __typeof (pSelf) __strong mySelf = pSelf;
        
        // Reset variables
        currentPage = 1;
        totalPage = 1;
        firstTimeGetMessage = 1;
        [mySelf getMessageByPage:currentPage];
        
        // Reset message if need
        if(resendMessage == TRUE) {
            if(lastMessage) {
                [mySelf sendMessage:lastMessage];
                resendMessage = FALSE;
                lastMessage = nil;
            }
        }
        
    });
    

}

- (void)socketDidDisconnectWithError:(NSError *)error
{
    NSLog(@"%s : %@", __func__, error);
    // Hide progress
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    // Enable send button
    self.inputToolbar.contentView.rightBarButtonItem.enabled = YES;
    
    // Try to reconnect
    if(socket) {
        if(isDisplaying) {
            if([[QNetHelper getInstance] hasInternetConnection]) {
                [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                _chatSocket.delegate = self;
                dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                dispatch_async(globalQueue, ^{
                    
                    [_chatSocket connect];
                });
                
            }
        }
    }
}

- (void)socketDidSendMessageWithResponse:(id)response {
    // Enable send button
    self.inputToolbar.contentView.rightBarButtonItem.enabled = YES;
    
    NSString *status = [response valueForKey:kAPIResponseStatus];
    if ([status isEqualToString:kAPIResponseStatusSuccess]) {
        // Play sound
        //[JSQSystemSoundPlayer jsq_playMessageSentSound];
        
        // Get data
        NSDictionary *data = [response valueForKey:kAPIResponseData];
        [self addMessageWithData:data];
        [self finishSendingMessageAnimated:YES];
        
        // Reset current page
        currentPage = 1;
        totalPage = 1;
    }
    else {
        
        __typeof (self) __weak pSelf = self;
        dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(globalQueue, ^{
            __typeof (pSelf) __strong mySelf = pSelf;
            [_chatSocket disconnect];
            if (IS_NOT_NULL([_contestInfo objectForKey:@"id"])) {
                _chatSocket = [[EChatSocket alloc] initWithContestId:[_contestInfo objectForKey:@"id"]];
            } else {
                _chatSocket = [[EChatSocket alloc] initWithContestId:[_contestInfo objectForKey: @"contestId"]];
                
            }
            
            // Hide
            if([[QNetHelper getInstance] hasInternetConnection]) {
                if(![_chatSocket isConnected]) {
                    //[MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    _chatSocket.delegate = mySelf;
                    [_chatSocket connect];
                }
                else {
                    if(![_chatSocket isAuthen]) {
                        [_chatSocket authen];
                    }
                    else {
                        if(![_chatSocket isJoinedContest]) {
                            [_chatSocket join];
                        }
                    }
                }
            }
        });
        
        //THIEN
       // [[QUIHelper getInstance] logoutDirectly];
       // [[QUIHelper getInstance] showAlertWithMessage:[response objectForKey:@"message"]];
    }
}

- (void)hideKeyboard:(NSNotification *)noti {
    
    [self.view endEditing:YES];
}

#pragma mark - Scroll View Delegate -
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(scrollDirectionDetermined) {
        CGPoint translation = [scrollView.panGestureRecognizer translationInView:self.view];
        if(translation.y > 0) { // Detect scrolling down
            scrollDirectionDetermined = FALSE;
            [self.inputToolbar.contentView.textView resignFirstResponder];
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    scrollDirectionDetermined = FALSE;
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    scrollDirectionDetermined = TRUE;
}

@end


