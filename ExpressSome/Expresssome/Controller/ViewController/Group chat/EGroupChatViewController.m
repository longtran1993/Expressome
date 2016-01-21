//
//  EGroupChatViewController.m
//  Expresssome
//
//  Created by Thai Nguyen on 4/15/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import "EGroupChatViewController.h"
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
#import "EContestPageViewController.h"
#import "AppDelegate.h"
#import "EContestVoteViewController.h"

#define kEliminatedStatus 1
#define kAdvancingNextRoundStatus 2

@interface EGroupChatViewController ()
{
    NSDictionary *groupInfo;
    NSString *groupPageId;
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

@implementation EGroupChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
#ifndef BUG_LOGGING_ENABLE
    self.reportButton.hidden = YES;
#else
    [self.view addSubview:self.reportButton];
#endif
    
    // Reset variables
    currentPage = 1;
    totalPage = 1;
    firstTimeGetMessage = TRUE;
    
    // Hide navigation bar if _fromVotePage = TRUE
    if(_fromVotePage) {
        self.navigationController.navigationBarHidden = TRUE;
    }
    __typeof (self) __weak pSelf = self;
    // Initialize variables
    groupInfo = [[EUserData getInstance] dataForKey:GROUP_INFO_UD_KEY];
    firstTimeGetMessage = TRUE;
    self.messageGroupData = [[EMessageGroupData alloc] init];
    
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(globalQueue, ^{
        __typeof (pSelf) __strong mySelf = pSelf;
        _chatSocket = [[EChatSocket alloc] initWithGroupId:[groupInfo objectForKey:@"id"]];
        _chatSocket.delegate = mySelf;
    });
    
    
    // Add target for infoButton
    [self.infoButton addTarget:self action:@selector(infoButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    // Add refresh control to collection view
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(loadMoreMessages)
             forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:refreshControl];
    self.collectionView.alwaysBounceVertical = YES;
    
    
    // Set title
    self.titleLabel.text = [ECommon resetNullValueToString:[groupInfo valueForKey:@"name"]];

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

    // Play sound when the user has just joined group
    self.hasJustJoinedGroup = [[[EUserData getInstance] objectForKey:HAS_JUST_JOINED_GROUP_UD_KEY] boolValue];
    if(self.hasJustJoinedGroup) {
        //[JSQSystemSoundPlayer jsq_playMessageSentSound];
        [[EUserData getInstance] setObject:[NSNumber numberWithBool:FALSE] forKey:HAS_JUST_JOINED_GROUP_UD_KEY];
    }
    
   
}

- (void)viewWillAppear:(BOOL)animated
{
    __typeof (self) __weak pSelf = self;
    // Register notification events
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveMessageNotificaton:) name:kNotificationKeyReceiveMessage object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivePushJoinGroupNotificaton:) name:kNotificationKeyPushJoinGroup object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivePushInviteJoinContestNotificaton:) name:kNotificationKeyPushInviteJoinContest object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivePushJoinContest:) name:kNotificationKeyPushJoinContest object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivePushLeaveGroup:) name:kNotificationKeyPushLeaveGroup object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivePushCreateGroup:) name:kNotificationKeyPushCreateGroup object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivePushStartRound1:) name:kNotificationKeyPushStartContestRound1 object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivePushStartRound2:) name:kNotificationKeyPushStartContestRound2 object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivePushFinishContest:) name:kNotificationKeyPushFinishContest object:nil];
    
    // Add observer for application lifecycle
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appplicationDidActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterBackground:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];

    
    [super viewWillAppear:animated];
    //self.tabBarController.tabBar
    [self.tabBarController.tabBar setHidden:YES];
    self.extendedLayoutIncludesOpaqueBars = YES;
    

   // [self.collectionView setContentSize:CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height)];
    isDisplaying = TRUE;
    [self dismissKeyboard];
    
   [self loadLatestMessages];
    
    // Hide
    if([[QNetHelper getInstance] hasInternetConnection]) {
        if(![_chatSocket isConnected]) {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            
            dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            dispatch_async(globalQueue, ^{
                __typeof (pSelf) __strong mySelf = pSelf;
                _chatSocket.delegate = mySelf;
                [_chatSocket connect];
                
            });
            
        }
    }

    // Adjust badge number
//    [[QNotificationHelper getInstance] resetBadgeForType:[NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@", kCreateGroupNotificationType, kJoinGroupNotificationType, kLeaveGroupNotificationType, kMessageGroupChatNotificationType, kInviteGroupJoinContestNotificationType, kJoinContestNotificationType, kStartContestRound1NotificationType, kStartContestRound2NotificationType, kFinishContestNotificationType, kTestNotificationType]];

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    isDisplaying = FALSE;
    [self dismissKeyboard];
    // Remove observer
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Disconnect socket
    if(_chatSocket && [_chatSocket isConnected]) {
        
        dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(globalQueue, ^{
            
            [_chatSocket disconnect];
        });
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[SDImageCache sharedImageCache] clearMemory];
}


#pragma mark - UI Actions -
- (IBAction)backButtonTapped:(id)sender {
    // Clear input
//    self.inputToolbar.contentView.textView.text = @"";
//    [self.inputToolbar.contentView.textView resignFirstResponder];
//    // End editing
//    [self.view endEditing:YES];
    [self dismissKeyboard];
    
    if(self.fromVotePage) {
        // Custom animation as push action
        CATransition *transition = [CATransition animation];
        transition.duration = 0.3;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionPush;
        transition.subtype = kCATransitionFromLeft;
        [self.view.window.layer addAnimation:transition forKey:nil];
        
        // Go back
        [self dismissViewControllerAnimated:NO completion:nil];
    }
    else {
        // Show tab bar
        [self.tabBarController.tabBar setHidden:NO];
        [self.tabBarController setSelectedIndex:0];
    }
}

- (void)dismissKeyboard {
    self.inputToolbar.contentView.textView.text = @"";
    [self.inputToolbar.contentView.textView resignFirstResponder];
    [self.view endEditing:YES];
}

- (IBAction)infoButtonTapped:(id)sender {
    
    // End editing
    //[self.view endEditing:YES];
    
    [self dismissKeyboard];
    
    // Go to group detail
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    EGroupDetailViewController *groupDetailVC = (EGroupDetailViewController *)[sb instantiateViewControllerWithIdentifier:@"groupDetailVC"];
    groupDetailVC.groupInfo = [[EUserData getInstance] dataForKey:GROUP_INFO_UD_KEY];
    [self.navigationController pushViewController:groupDetailVC animated: NO];
}

- (IBAction)sendReportButtonHasTapped:(id)sender {
    if ([MFMailComposeViewController canSendMail]) {
        // Attach file to email
        NSArray *fileContents = [[QSystemHelper getInstance] dataContentsAtPath:@"logs" withExtension:@".json"];
        if([fileContents count] > 0) {
            // Show the composer
            MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
            controller.mailComposeDelegate = self;
            NSArray *toRecipients = [NSArray arrayWithObjects:@"quandt.prj@gmail.com", nil];
            [controller setToRecipients:toRecipients];
            [controller setSubject:@"Bug Reports"];
            [controller setMessageBody:@"Please view attach files to see detail log." isHTML:NO];
            
            NSFileManager *manager = [NSFileManager defaultManager];
            NSString *cacheDir = [[QSystemHelper getInstance] cacheDirectory];
            for (NSString *filePath in fileContents) {
                NSData *fileData = [manager contentsAtPath:[cacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"logs/%@", filePath]]];
                if(fileData) {
                    [controller addAttachmentData:fileData mimeType:@"application/json" fileName:[filePath lastPathComponent]];
                }
                else {
                    [[[UIAlertView alloc] initWithTitle:@"" message:[NSString stringWithFormat:@"Don't have attach : %@", filePath] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
                }
            }
            
            [self presentViewController:controller animated:YES completion:^{
                
            }];
            
        }
        
    } else {
        // Handle the error
        [[[UIAlertView alloc] initWithTitle:@"" message:@"Your device does not support email" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
    }
}

#pragma mark - Messages

- (void)loadLatestMessages{
    // Reset variables
    currentPage = 1;
    totalPage = 1;
    firstTimeGetMessage = TRUE;
    [self.messageGroupData.messages removeAllObjects];
    [self.collectionView reloadSections: [NSIndexSet indexSetWithIndex: 0]];
    //
    [self getMessageByPage:currentPage];
}

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
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl, kAPIGetGroupChatMessagesPath];
    
    // Fill params
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:[NSNumber numberWithInteger:page] forKey:kAPIParamPage];
    
    // Make a request
    QAPIManager *apiManager = [QAPIManager getInstance];
    apiManager.appendHeaderFields = [[NSMutableDictionary alloc] init];
    [apiManager.appendHeaderFields setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forKey:@"auth-token"];
    [apiManager GET:urlStr params:params completeWithBlock:^(id responseObject, NSError *error) {
        
//        NSError *jsonError;
//        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:responseObject
//                                                           options:NSJSONWritingPrettyPrinted
//                                                             error:&jsonError];
//        NSLog(@"GET_GROUP_CHAT_MESSAGES PAGE %ld %@", currentPage, [[NSString alloc] initWithData:jsonData
//                                                                                         encoding:NSUTF8StringEncoding]);
       // NSLog(@"GET_GROUP_CHAT_MESSAGES PAGE %@", responseObject);
         __typeof (pSelf) __strong mySelf = pSelf;
                                                                    
        // Hide progress
        [MBProgressHUD hideAllHUDsForView:mySelf.view animated:YES];
        isLoading = FALSE;
        if(!error && [EJSONHelper valueFromData:responseObject]) {
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
            [mySelf.collectionView reloadSections: [NSIndexSet indexSetWithIndex: 0]];
           // [mySelf.collectionView reloadData];
            [mySelf.collectionView performBatchUpdates:^{}
                                          completion:^(BOOL finished) {
                                              /// collection-view finished reload
                                              
                                              if(finished) {
                                                  // Scroll to bottom
                                                  if(firstTimeGetMessage == TRUE) {
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


- (BOOL)addMessageWithData:(NSDictionary *)messageData
{
    // Check existed message
    __typeof (self) __weak pSelf = self;
    BOOL isExisted = FALSE;
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
        
        [self.messageGroupData.avatars setObject:[JSQMessagesAvatarImage avatarImageWithPlaceholder:[UIImage imageNamed:@"avatar.png"]] forKey:[NSString stringWithFormat:@"%@", message.msgId]];
        
        if ([EJSONHelper valueFromData:[message.msgUser objectForKey:@"image"]]) {
            NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl1, [message.msgUser objectForKey:@"image"]];
            
            [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:urlStr] options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                
                 __typeof (pSelf) __strong mySelf = pSelf;
                if (image) {
                    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                    dispatch_async(globalQueue, ^{
                        JSQMessagesAvatarImage *avatarImage = [JSQMessagesAvatarImageFactory avatarImageWithImage:image diameter:kJSQMessagesCollectionViewAvatarSizeDefault];
                        [mySelf.messageGroupData.avatars setObject:avatarImage forKey:[NSString stringWithFormat:@"%@", message.msgId]];
                        
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
    }
    return isExisted;
}


- (BOOL)addMessageWithDataWithoutSort:(NSDictionary *)messageData
{
    // Check existed message
    __typeof (self) __weak pSelf = self;
    BOOL isExisted = FALSE;
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
        
        [self.messageGroupData.avatars setObject:[JSQMessagesAvatarImage avatarImageWithPlaceholder:[UIImage imageNamed:@"avatar.png"]] forKey:[NSString stringWithFormat:@"%@", message.msgId]];
        
        if ([EJSONHelper valueFromData:[message.msgUser objectForKey:@"image"]]) {
            NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl1, [message.msgUser objectForKey:@"image"]];
            
            [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:urlStr] options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                
                __typeof (pSelf) __strong mySelf = pSelf;
                if (image) {
                    
                    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                    dispatch_async(globalQueue, ^{
                        JSQMessagesAvatarImage *avatarImage = [JSQMessagesAvatarImageFactory avatarImageWithImage:image diameter:kJSQMessagesCollectionViewAvatarSizeDefault];
                        [mySelf.messageGroupData.avatars setObject:avatarImage forKey:[NSString stringWithFormat:@"%@", message.msgId]];
                        
                        dispatch_async (dispatch_get_main_queue(), ^{
                            [mySelf.collectionView.collectionViewLayout invalidateLayoutWithContext:[JSQMessagesCollectionViewFlowLayoutInvalidationContext context]];
                        });
                    });
                    
                    
                }
            }];
        }
        
        [self.messageGroupData.messages addObject:message];
        
    }
    return isExisted;
}

#pragma mark - Notification
- (void)appplicationDidActive:(NSNotification *)notification {
    //NSLog(@"Application Did Become Active");
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
    
    // Reconnect socket
    if(![_chatSocket isConnected]) {
        if([[QNetHelper getInstance] hasInternetConnection]) {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            
            dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            dispatch_async(globalQueue, ^{
                __typeof (pSelf) __strong mySelf = pSelf;
                _chatSocket.delegate = mySelf;
                [_chatSocket connect];
            });
            
        }
    }
    
    if(isDisplaying) {
       
        if(!isLoading) {
            // Reset variables
            currentPage = 1;
            totalPage = 1;
            firstTimeGetMessage = 1;
            [self getMessageByPage:currentPage];
        }
        
        // Adjust badge number
//        [[QNotificationHelper getInstance] resetBadgeForType:[NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@", kJoinGroupNotificationType, kLeaveGroupNotificationType, kMessageGroupChatNotificationType, kInviteGroupJoinContestNotificationType, kJoinContestNotificationType, kStartContestRound1NotificationType, kStartContestRound2NotificationType, kFinishContestNotificationType, kTestNotificationType]];
        
    }
}

- (void)applicationWillEnterBackground:(NSNotification *)notification {
   // NSLog(@"Application Will Enter Background");
    
    // Set false
    resendMessage = FALSE;
    
    // Hide unwanted progress UI
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    // Disconnect socket
    if(_chatSocket && [_chatSocket isConnected]) {
        
        dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(globalQueue, ^{
            
            [_chatSocket disconnect];
        });
        
    }
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

- (void)receivePushJoinGroupNotificaton:(NSNotification *)notification
{
    if(isDisplaying) {
        NSDictionary *data = notification.userInfo;
        if (data) {
            
            if(![self addMessageWithData:data]) {
#ifdef BUG_LOGGING_ENABLE
                if([EJSONHelper valueFromData:[data objectForKey:@"type"]]) {
                    if([[data objectForKey:@"type"] isEqualToString:kJoinGroupMsgType]) {
                        [EJSONHelper logJSON:data toFile:[NSString stringWithFormat:@"Notif_[%@]_Msg_%@.json", kJoinGroupMsgType, [QSystemHelper UTCStringFromDate:[NSDate date]]]];
                    }
                }
#endif
                // Play sound
                [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
                
                [self finishReceivingMessageAnimated:YES];
                
                // Reset current page
                currentPage = 1;
                totalPage = 1;
            }
            
        }
        
        // Adjust badge number
        [[QNotificationHelper getInstance] resetBadgeForType:kJoinGroupNotificationType];
    }
}

- (void)receivePushInviteJoinContestNotificaton:(NSNotification *)notification
{
    if(isDisplaying) {
        NSDictionary *data = notification.userInfo;
        if (data) {
            if(![self addMessageWithData:data]) {
#ifdef BUG_LOGGING_ENABLE
                if([EJSONHelper valueFromData:[data objectForKey:@"type"]]) {
                    if([[data objectForKey:@"type"] isEqualToString:kInviteGroupJoinContestMsgType]) {
                        [EJSONHelper logJSON:data toFile:[NSString stringWithFormat:@"Notif_[%@]_Msg_%@.json", kInviteGroupJoinContestMsgType, [QSystemHelper UTCStringFromDate:[NSDate date]]]];
                    }
                }
#endif
                // Play sound
                [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
                
                [self finishReceivingMessageAnimated:YES];
                
                // Reset current page
                currentPage = 1;
                totalPage = 1;
            }
            
        }
        
        // Adjust badge number
        [[QNotificationHelper getInstance] resetBadgeForType:kInviteGroupJoinContestNotificationType];
    }
}

- (void)receivePushCreateGroup:(NSNotification *)notification
{
    if(isDisplaying) {
        NSDictionary *data = notification.userInfo;
        if (data) {
            if(![self addMessageWithData:data]) {
#ifdef BUG_LOGGING_ENABLE
                if([EJSONHelper valueFromData:[data objectForKey:@"type"]]) {
                    if([[data objectForKey:@"type"] isEqualToString:kCreateGroupMsgType]) {
                        [EJSONHelper logJSON:data toFile:[NSString stringWithFormat:@"Notif_[%@]_Msg_%@.json", kCreateGroupMsgType, [QSystemHelper UTCStringFromDate:[NSDate date]]]];
                    }
                }
#endif
                // Play sound
                [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
                
                [self finishReceivingMessageAnimated:YES];
                
                // Reset current page
                currentPage = 1;
                totalPage = 1;
            }
            
        }
        
        // Adjust badge number
        [[QNotificationHelper getInstance] resetBadgeForType:kCreateGroupNotificationType];
    }
}

- (void)receivePushLeaveGroup:(NSNotification *)notification
{
    if(isDisplaying) {
        NSDictionary *data = notification.userInfo;
        if (data) {
            if(![self addMessageWithData:data]) {
#ifdef BUG_LOGGING_ENABLE
                if([EJSONHelper valueFromData:[data objectForKey:@"type"]]) {
                    if([[data objectForKey:@"type"] isEqualToString:kLeaveGroupMsgType]) {
                        [EJSONHelper logJSON:data toFile:[NSString stringWithFormat:@"Notif_[%@]_Msg_%@.json", kLeaveGroupMsgType, [QSystemHelper UTCStringFromDate:[NSDate date]]]];
                    }
                }
#endif
                // Play sound
                [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
                
                [self finishReceivingMessageAnimated:YES];
                
                // Reset current page
                currentPage = 1;
                totalPage = 1;
            }
        }
        
        // Adjust badge number
        [[QNotificationHelper getInstance] resetBadgeForType:kLeaveGroupNotificationType];
    }
}

- (void)receivePushJoinContest:(NSNotification *)notification
{
    if(isDisplaying) {
        NSDictionary *data = notification.userInfo;
        if (data) {
            if(![self addMessageWithData:data]) {
#ifdef BUG_LOGGING_ENABLE
                if([EJSONHelper valueFromData:[data objectForKey:@"type"]]) {
                    if([[data objectForKey:@"type"] isEqualToString:kLeaveGroupMsgType]) {
                        [EJSONHelper logJSON:data toFile:[NSString stringWithFormat:@"Notif_[%@]_Msg_%@.json", kLeaveGroupMsgType, [QSystemHelper UTCStringFromDate:[NSDate date]]]];
                    }
                }
#endif
                // Play sound
                [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
                
                [self finishReceivingMessageAnimated:YES];
                
                // Reset current page
                currentPage = 1;
                totalPage = 1;
            }
            
        }
        
        // Adjust badge number
        [[QNotificationHelper getInstance] resetBadgeForType:kJoinContestNotificationType];
    }
}

- (void)receivePushStartRound1:(NSNotification *)notification
{
    if(isDisplaying) {
        NSDictionary *data = notification.userInfo;
        if (data) {
            if(![self addMessageWithData:data]) {
#ifdef BUG_LOGGING_ENABLE
                if([EJSONHelper valueFromData:[data objectForKey:@"type"]]) {
                    if([[data objectForKey:@"type"] isEqualToString:kStartContestRound1MsgType]) {
                        [EJSONHelper logJSON:data toFile:[NSString stringWithFormat:@"Notif_[%@]_Msg_%@.json", kStartContestRound1MsgType, [QSystemHelper UTCStringFromDate:[NSDate date]]]];
                    }
                }
#endif
                // Play sound
                [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
                
                [self finishReceivingMessageAnimated:YES];
                
                // Reset current page
                currentPage = 1;
                totalPage = 1;
            }
            
        }
        
        // Adjust badge number
        [[QNotificationHelper getInstance] resetBadgeForType:kStartContestRound1NotificationType];
    }
}

- (void)receivePushStartRound2:(NSNotification *)notification
{
    if(isDisplaying) {
        NSDictionary *data = notification.userInfo;
        if (data) {
            if(![self addMessageWithData:data]) {
#ifdef BUG_LOGGING_ENABLE
                if([EJSONHelper valueFromData:[data objectForKey:@"type"]]) {
                    if([[data objectForKey:@"type"] isEqualToString:kStartContestRound2MsgType]) {
                        [EJSONHelper logJSON:data toFile:[NSString stringWithFormat:@"Notif_[%@]_Msg_%@.json", kStartContestRound2MsgType, [QSystemHelper UTCStringFromDate:[NSDate date]]]];
                    }
                }
#endif
                // Play sound
                [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
                
                [self finishReceivingMessageAnimated:YES];
                
                // Reset current page
                currentPage = 1;
                totalPage = 1;
            }
            
        }
        
        // Adjust badge number
        [[QNotificationHelper getInstance] resetBadgeForType:kStartContestRound2NotificationType];
    }
}

- (void)receivePushFinishContest:(NSNotification *)notification
{
    if(isDisplaying) {
        NSDictionary *data = notification.userInfo;
        if (data) {
            if(![self addMessageWithData:data]) {
#ifdef BUG_LOGGING_ENABLE
                if([EJSONHelper valueFromData:[data objectForKey:@"type"]]) {
                    if([[data objectForKey:@"type"] isEqualToString:kFinishContestMsgType]) {
                        [EJSONHelper logJSON:data toFile:[NSString stringWithFormat:@"Notif_[%@]_Msg_%@.json", kFinishContestMsgType, [QSystemHelper UTCStringFromDate:[NSDate date]]]];
                    }
                }
#endif
                // Play sound
                [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
                
                [self finishReceivingMessageAnimated:YES];
                
                // Reset current page
                currentPage = 1;
                totalPage = 1;
            }
            
        }
        
        // Adjust badge number
        [[QNotificationHelper getInstance] resetBadgeForType:kFinishContestNotificationType];
    }
}


- (void)receiveMessageNotificaton:(NSNotification *)notification
{
    NSDictionary *data = notification.userInfo;
    if (data) {
        if([[data objectForKey:@"type"] isEqualToString:kMessageGroupChatMsgType]) {
            if([EJSONHelper valueFromData:[data objectForKey:@"room"]]) {
                NSDictionary *roomInfo = [data objectForKey:@"room"];
                if([EJSONHelper valueFromData:[roomInfo objectForKey:@"type"]] && [[roomInfo objectForKey:@"type"] isEqualToString:kGroupChatRoomType]) {
                    if(![self addMessageWithData:data]) {
            #ifdef BUG_LOGGING_ENABLE
                        [EJSONHelper logJSON:data toFile:[NSString stringWithFormat:@"Socket_[%@]_Msg_%@.json", [data objectForKey:@"type"], [QSystemHelper UTCStringFromDate:[NSDate date]]]];
            #endif
                        // Play sound
                        // Thien
                        
                        NSDictionary *userInfo = (NSDictionary *)[data objectForKey:@"user"];
                        NSNumber *userID = (NSNumber *)[userInfo objectForKey:@"id"];
                        NSNumber *currentUserID = [[EUserData getInstance] objectForKey:USER_ID_UD_KEY];
                        if ([[userID stringValue] isEqualToString:[currentUserID stringValue]]) {
                            [JSQSystemSoundPlayer jsq_playMessageSentSound];
                        } else {
                            [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
                        }
                        
                        
                        [self finishReceivingMessageAnimated:YES];
                        
                        // Reset current page
                        currentPage = 1;
                        totalPage = 1;
                    }
                }
            }
        }
        
    }
    
    if(isDisplaying) {
        // Adjust badge number
        [[QNotificationHelper getInstance] resetBadgeForType:kMessageGroupChatNotificationType];
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
                [self sendMessage:text];
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
    
    if (IS_NOT_NULL(self.messageGroupData) && IS_NOT_NULL(self.messageGroupData.messages) && (indexPath.item < self.messageGroupData.messages.count)) {
        return [self.messageGroupData.messages objectAtIndex:indexPath.item];
    }
    
    return nil;
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    EMessageModel *message = nil;
    if (IS_NOT_NULL(self.messageGroupData) && IS_NOT_NULL(self.messageGroupData.messages) && (indexPath.item < self.messageGroupData.messages.count)) {
        message = [self.messageGroupData.messages objectAtIndex:indexPath.item];
    }
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.messageGroupData.outgoingBubbleImageData;
    }
    
    return self.messageGroupData.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    EMessageModel *message = nil;
    if (IS_NOT_NULL(self.messageGroupData) && IS_NOT_NULL(self.messageGroupData.messages) && (indexPath.item < self.messageGroupData.messages.count)) {
        message = [self.messageGroupData.messages objectAtIndex:indexPath.item];
    }
    return [self.messageGroupData.avatars objectForKey:[NSString stringWithFormat:@"%@", message.msgId] ];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    EMessageModel *message = nil;
    if (IS_NOT_NULL(self.messageGroupData) && IS_NOT_NULL(self.messageGroupData.messages) && (indexPath.item < self.messageGroupData.messages.count)) {
        message = [self.messageGroupData.messages objectAtIndex:indexPath.item];
    }
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
    EMessageModel *msg = nil;
    if (IS_NOT_NULL(self.messageGroupData) && IS_NOT_NULL(self.messageGroupData.messages) && (indexPath.item < self.messageGroupData.messages.count)) {
        msg = [self.messageGroupData.messages objectAtIndex:indexPath.item];
    }
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:msg.msgText];
    if([msg.msgType isEqual:kMessageGroupChatMsgType]) {
        if ([msg.senderId isEqualToString:self.senderId]) {
            [attributedString beginEditing];
            [attributedString addAttribute:NSFontAttributeName value:collectionView.collectionViewLayout.messageBubbleFont range:NSMakeRange(0, msg.text.length)];
            [attributedString addAttribute:NSForegroundColorAttributeName value:kWhiteColor range:NSMakeRange(0, msg.text.length)];
            [attributedString endEditing];
        }
        else {
            [attributedString beginEditing];
            [attributedString addAttribute:NSFontAttributeName value:collectionView.collectionViewLayout.messageBubbleFont range:NSMakeRange(0, msg.text.length)];
            [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor darkGrayColor] range:NSMakeRange(0, msg.text.length)];
            [attributedString endEditing];
        }
    }
    else {
        [attributedString beginEditing];
        [attributedString addAttribute:NSFontAttributeName value:collectionView.collectionViewLayout.messageBubbleFont range:NSMakeRange(0, msg.text.length)];
        [attributedString addAttribute:NSForegroundColorAttributeName value:kWhiteColor range:NSMakeRange(0, msg.text.length)];
        [attributedString endEditing];
        if([msg.msgType isEqualToString:kInviteGroupJoinContestMsgType] || [msg.msgType isEqualToString:kJoinContestMsgType] || [msg.msgType isEqualToString:kFinishContestMsgType] || [msg.msgType isEqualToString:kStartContestRound1MsgType] || [msg.msgType isEqualToString:kStartContestRound2MsgType]) {
            
            if([EJSONHelper valueFromData:[msg.msgData objectForKey:@"contestName"]]) {
                
                NSRange textRange = [[msg.text lowercaseString] rangeOfString:[[msg.msgData objectForKey:@"contestName"] lowercaseString] options:NSBackwardsSearch];
                
                // Set text's styles
                [attributedString beginEditing];
                [attributedString addAttribute:NSFontAttributeName value:collectionView.collectionViewLayout.messageBubbleFont range:NSMakeRange(0, textRange.location)];
                [attributedString addAttribute:NSForegroundColorAttributeName value:kWhiteColor range:textRange];
                [attributedString endEditing];
                
                // Highlight contest name
                [attributedString beginEditing];
                [attributedString addAttribute:NSFontAttributeName value:collectionView.collectionViewLayout.messageBubbleFont range:textRange];
                [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:textRange];
                [attributedString endEditing];
            }
            else {
                [attributedString beginEditing];
                [attributedString addAttribute:NSFontAttributeName value:collectionView.collectionViewLayout.messageBubbleFont range:NSMakeRange(0, msg.text.length)];
                [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0, msg.text.length)];
                [attributedString endEditing];
            }
        }
        else if([msg.msgType isEqualToString:kCreateGroupMsgType]) {
            [attributedString beginEditing];
            [attributedString addAttribute:NSFontAttributeName value:collectionView.collectionViewLayout.messageBubbleFont range:NSMakeRange(0, msg.text.length)];
            [attributedString addAttribute:NSForegroundColorAttributeName value:kWhiteColor range:NSMakeRange(0, msg.msgText.length)];
            [attributedString endEditing];
        }
        else {
            [attributedString beginEditing];
            [attributedString addAttribute:NSFontAttributeName value:collectionView.collectionViewLayout.messageBubbleFont range:NSMakeRange(0, msg.text.length)];
            [attributedString addAttribute:NSForegroundColorAttributeName value:kWhiteColor range:NSMakeRange(0, msg.text.length)];
            [attributedString endEditing];
        }
        
    }

    return attributedString;
}

#pragma mark - UICollectionView DataSource

-(NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    
    [collectionView.collectionViewLayout invalidateLayout];
    
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    [collectionView.collectionViewLayout invalidateLayout];
    if (IS_NOT_NULL(self.messageGroupData) && IS_NOT_NULL(self.messageGroupData.messages)) {
        return [self.messageGroupData.messages count];
    }
    
    
    
    return 0;
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
    
    EMessageModel *msg = nil;
    if (IS_NOT_NULL(self.messageGroupData) && IS_NOT_NULL(self.messageGroupData.messages) && (indexPath.item < self.messageGroupData.messages.count)) {
        msg = [self.messageGroupData.messages objectAtIndex:indexPath.item];
    }
    if (!msg.isMediaMessage) {
        if ([msg.senderId isEqualToString:self.senderId]) {
            JSQMessagesCollectionViewCellOutgoing *outGoingCell = (JSQMessagesCollectionViewCellOutgoing *)cell;
            outGoingCell.userNameLabel.text = msg.senderDisplayName;
            CGRect frame = outGoingCell.userNameLabel.frame;
           // frame.origin.x = -200;
           // outGoingCell.userNameLabel.frame = frame;
            if([EJSONHelper valueFromData:[msg.msgUser objectForKey:@"groupName"]]) {
                outGoingCell.groupNameLabel.text = [msg.msgUser objectForKey:@"groupName"];
            }
            outGoingCell.sendTimeLabel.text = [QSystemHelper timeAPMForDate:msg.date];
            
            if([msg.msgType isEqualToString:kMessageGroupChatMsgType]) {
                outGoingCell.sendTimeLabel.textColor = kWhiteColor;
                outGoingCell.groupNameLabel.textColor = kWhiteColor;
                outGoingCell.separateLineImageView.backgroundColor = kWhiteColor;
                outGoingCell.userNameLabel.textColor = kWhiteColor;
                [cell.messageBubbleContainerView setBackgroundColor:kPurpleColor];
            }
            else if([msg.msgType isEqualToString:kJoinContestMsgType] || [msg.msgType isEqualToString:kInviteGroupJoinContestMsgType] || [msg.msgType isEqualToString:kJoinGroupMsgType] || [msg.msgType isEqualToString:kLeaveGroupMsgType]) {
                outGoingCell.sendTimeLabel.textColor = kWhiteColor;
                outGoingCell.groupNameLabel.textColor = kWhiteColor;
                outGoingCell.separateLineImageView.backgroundColor = kWhiteColor;
                outGoingCell.userNameLabel.textColor = kWhiteColor;
                [cell.messageBubbleContainerView setBackgroundColor:kLightBlueColor];
            }
            else if([msg.msgType isEqualToString:kStartContestRound1MsgType]) {
                outGoingCell.sendTimeLabel.textColor = kWhiteColor;
                outGoingCell.groupNameLabel.textColor = kWhiteColor;
                outGoingCell.separateLineImageView.backgroundColor = kWhiteColor;
                outGoingCell.userNameLabel.textColor = kWhiteColor;
                [cell.messageBubbleContainerView setBackgroundColor:kGreenColor];
            }
            else if([msg.msgType isEqualToString:kStartContestRound2MsgType]) {
                outGoingCell.sendTimeLabel.textColor = kWhiteColor;
                outGoingCell.groupNameLabel.textColor = kWhiteColor;
                outGoingCell.separateLineImageView.backgroundColor = kWhiteColor;
                outGoingCell.userNameLabel.textColor = kWhiteColor;
                
                //outGoingCell.userNameLabel.text = [NSString stringWithFormat:@"%@. %@", [msg.msgData objectForKey:@"playerStatus"], outGoingCell.userNameLabel.text];
                if([EJSONHelper valueFromData:[msg.msgData objectForKey:@"playerStatus"]]) {
                    NSInteger status = [[msg.msgData objectForKey:@"playerStatus"] integerValue];
                    if(status == kEliminatedStatus) {
                        [cell.messageBubbleContainerView setBackgroundColor:kRedColor];
                    }
                    else if(status == kAdvancingNextRoundStatus) {
                        [cell.messageBubbleContainerView setBackgroundColor:kGreenColor];
                    }
                    else {
                        [cell.messageBubbleContainerView setBackgroundColor:kWhiteColor];
                    }
                }
            }
            else if([msg.msgType isEqualToString:kFinishContestMsgType]) {
                outGoingCell.sendTimeLabel.textColor = kWhiteColor;
                outGoingCell.groupNameLabel.textColor = kWhiteColor;
                outGoingCell.separateLineImageView.backgroundColor = kWhiteColor;
                outGoingCell.userNameLabel.textColor = kWhiteColor;
                [cell.messageBubbleContainerView setBackgroundColor:kGreenColor];
            }
            [outGoingCell.textView sizeToFit];
        }
        else {
            JSQMessagesCollectionViewCellIncoming *inComingCell = (JSQMessagesCollectionViewCellIncoming *)cell;
            inComingCell.userNameLabel.text = msg.senderDisplayName;
            CGRect frame = inComingCell.userNameLabel.frame;
           // frame.origin.x = -200;
            //inComingCell.userNameLabel.frame = frame;
            
            if([EJSONHelper valueFromData:[msg.msgUser objectForKey:@"groupName"]]) {
                inComingCell.groupNameLabel.text = [msg.msgUser objectForKey:@"groupName"];
            }
            inComingCell.sendTimeLabel.text = [QSystemHelper timeAPMForDate:msg.date];

            if([msg.msgType isEqualToString:kMessageGroupChatMsgType]) {
                inComingCell.groupNameLabel.textColor = kGrayColor;
                inComingCell.separateLineImageView.backgroundColor = kLightGrayColor;
                inComingCell.sendTimeLabel.textColor = kGrayColor;
                inComingCell.userNameLabel.textColor = kGrayColor;
                [cell.messageBubbleContainerView setBackgroundColor:kWhiteColor];
            }
            else if([msg.msgType isEqualToString:kJoinContestMsgType] || [msg.msgType isEqualToString:kInviteGroupJoinContestMsgType] || [msg.msgType isEqualToString:kJoinGroupMsgType] || [msg.msgType isEqualToString:kLeaveGroupMsgType]) {
                inComingCell.sendTimeLabel.textColor = kWhiteColor;
                inComingCell.groupNameLabel.textColor = kWhiteColor;
                inComingCell.separateLineImageView.backgroundColor = kWhiteColor;
                inComingCell.userNameLabel.textColor = kWhiteColor;
                [cell.messageBubbleContainerView setBackgroundColor:kLightBlueColor];
            }
            else if([msg.msgType isEqualToString:kStartContestRound1MsgType]) {
                inComingCell.sendTimeLabel.textColor = kWhiteColor;
                inComingCell.groupNameLabel.textColor = kWhiteColor;
                inComingCell.separateLineImageView.backgroundColor = kWhiteColor;
                inComingCell.userNameLabel.textColor = kWhiteColor;
                [cell.messageBubbleContainerView setBackgroundColor:kGreenColor];
            }
            else if([msg.msgType isEqualToString:kStartContestRound2MsgType]) {
                inComingCell.sendTimeLabel.textColor = kWhiteColor;
                inComingCell.groupNameLabel.textColor = kWhiteColor;
                inComingCell.separateLineImageView.backgroundColor = kWhiteColor;
                inComingCell.userNameLabel.textColor = kWhiteColor;
                //inComingCell.userNameLabel.text = [NSString stringWithFormat:@"%@. %@", [msg.msgData objectForKey:@"playerStatus"], inComingCell.userNameLabel.text];
                if([EJSONHelper valueFromData:[msg.msgData objectForKey:@"playerStatus"]]) {
                    NSInteger status = [[msg.msgData objectForKey:@"playerStatus"] integerValue];
                    if(status == kEliminatedStatus) {
                        [cell.messageBubbleContainerView setBackgroundColor:kRedColor];
                    }
                    else if(status == kAdvancingNextRoundStatus) {
                        [cell.messageBubbleContainerView setBackgroundColor:kGreenColor];
                    }
                    else {
                        [cell.messageBubbleContainerView setBackgroundColor:kWhiteColor];
                    }
                }
            }
            else if([msg.msgType isEqualToString:kFinishContestMsgType]) {
                inComingCell.sendTimeLabel.textColor = kWhiteColor;
                inComingCell.groupNameLabel.textColor = kWhiteColor;
                inComingCell.separateLineImageView.backgroundColor = kWhiteColor;
                inComingCell.userNameLabel.textColor = kWhiteColor;
                [cell.messageBubbleContainerView setBackgroundColor:kGreenColor];
            }
            [inComingCell.textView sizeToFit];
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
  //  NSLog(@"Custom action received! Sender: %@", sender);
    
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
    EMessageModel *message = nil;
    if (IS_NOT_NULL(self.messageGroupData) && IS_NOT_NULL(self.messageGroupData.messages) && (indexPath.item < self.messageGroupData.messages.count)) {
        message = [self.messageGroupData.messages objectAtIndex:indexPath.item];
    }
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
    EMessageModel *msg = nil;
    if (IS_NOT_NULL(self.messageGroupData) && IS_NOT_NULL(self.messageGroupData.messages) && (indexPath.item < self.messageGroupData.messages.count)) {
        msg = [self.messageGroupData.messages objectAtIndex:indexPath.item];
    }
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
        attributes:@{ NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue" size:13] }
        context:nil];
        CGSize userNameLabelSize = CGRectIntegral(userNameLabelRect).size;
        
        // Group Name Label Size
        CGRect groupNameLabelRect = [[msg.msgUser objectForKey:@"groupName"] boundingRectWithSize:CGSizeMake(220, CGFLOAT_MAX)
                                                                       options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                                    attributes:@{ NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue" size:11] }
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
   // NSLog(@"Load earlier messages!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
   // NSLog(@"Tapped message bubble! at indexpath. %d", indexPath.row);
    
    EMessageModel *msg = nil;
    if (IS_NOT_NULL(self.messageGroupData) && IS_NOT_NULL(self.messageGroupData.messages) && (indexPath.item < self.messageGroupData.messages.count)) {
        msg = [self.messageGroupData.messages objectAtIndex:indexPath.item];
    }
    
    NSDictionary *contestInfo = msg.msgData;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];//
    
    if ([msg.msgType isEqualToString: kInviteGroupJoinContestMsgType] || [msg.msgType isEqualToString: kJoinContestMsgType] || [msg.msgType isEqualToString: kUserWinContestMsgType]) {
        
        NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
        NSString *username = [[EUserData getInstance] objectForKey:USER_NAME_UD_KEY];//
        NSString *contestID = [contestInfo valueForKey:@"id"];
        if (!IS_NOT_NULL(contestID)) {
            contestID = [contestInfo objectForKey: @"contestId"];
        }
        
        NSString *key = [NSString stringWithFormat: @"%@_joined_%@", username, contestID];
        BOOL hasJoined = [df boolForKey: key];
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: contestInfo];
        [dict setObject: @(hasJoined)  forKey: @"joinedStatus"];
        EContestPageViewController *contestPageVC = (EContestPageViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"contestPageVC"];
        contestPageVC.contestInfo = dict;
        contestPageVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:contestPageVC animated:YES];
   
    } else if ([msg.msgType isEqualToString: kStartContestRound2MsgType] ) {
        
        NSMutableDictionary *contestDict = [NSMutableDictionary dictionaryWithDictionary: contestInfo];
        [contestDict setObject: @2 forKey: @"round"];
        EContestVoteViewController *contestVoteVC = (EContestVoteViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"contestVoteVC"];
        contestVoteVC.contestInfo = contestDict;
        contestVoteVC.contestType = kOnGoingContestType;
        contestVoteVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:contestVoteVC animated:YES];
    
    } else if ( [msg.msgType isEqualToString: kStartContestRound1MsgType] ) {
        
        NSMutableDictionary *contestDict = [NSMutableDictionary dictionaryWithDictionary: contestInfo];
        [contestDict setObject: @1 forKey: @"round"];
        EContestVoteViewController *contestVoteVC = (EContestVoteViewController *)[[QUIHelper getInstance] getViewControllerWithIdentifier:@"contestVoteVC"];
        contestVoteVC.contestInfo = contestDict;
        contestVoteVC.contestType = kOnGoingContestType;
        contestVoteVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:contestVoteVC animated:YES];
        
    } else if ( [msg.msgType isEqualToString: kUserVotePhotoMsgType] || [msg.msgType isEqualToString: kUserVoteImageMsgType]) {
        
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
    
    NSLog(@"socketDidConnect");
    
    __typeof (self) __weak pSelf = self;
    dispatch_async (dispatch_get_main_queue(), ^{
        __typeof (pSelf) __strong mySelf = pSelf;
        // Hide progress
        [MBProgressHUD hideAllHUDsForView:mySelf.view animated:YES];
        
    });
    
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(globalQueue, ^{
        __typeof (pSelf) __strong mySelf = pSelf;
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
    NSLog(@"socketDidDisconnectWithError  %s : %@", __func__, error);
    
    __typeof (self) __weak pSelf = self;
    
    dispatch_async (dispatch_get_main_queue(), ^{
        
        // Hide progress
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        __typeof (pSelf) __strong mySelf = pSelf;
        // Enable send button
        mySelf.inputToolbar.contentView.rightBarButtonItem.enabled = YES;
        
        
    });
    
    // Try to reconnect
    if(socket) {
        if(isDisplaying) {
            if([[QNetHelper getInstance] hasInternetConnection]) {
                
                dispatch_async (dispatch_get_main_queue(), ^{
                    
                    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                });
                
                dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                dispatch_async(globalQueue, ^{
                    __typeof (pSelf) __strong mySelf = pSelf;
                    _chatSocket.delegate = mySelf;
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
            _chatSocket = [[EChatSocket alloc] initWithGroupId:[groupInfo objectForKey:@"id"]];
            _chatSocket.delegate = mySelf;
            [_chatSocket connect];
        });
        
        //THIEN
       // [[QUIHelper getInstance] logoutDirectly];
        //[[QUIHelper getInstance] showAlertWithMessage:[response objectForKey:@"message"]];
    }
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


#pragma mark - MFMailComposeViewControllerDelegate -
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    if (result == MFMailComposeResultSent) {
        NSLog(@"Email is sent successfully");
        if(![[QSystemHelper getInstance] deleteAllFilesInPath:@"logs"]) {
            [[[UIAlertView alloc] initWithTitle:@"" message:@"Can't delete files in logs folder" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
        }
    }
    
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}
@end

