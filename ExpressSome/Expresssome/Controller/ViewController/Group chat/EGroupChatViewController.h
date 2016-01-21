//
//  EGroupChatViewController.h
//  Expresssome
//
//  Created by Thai Nguyen on 4/15/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "JSQMessage.h"
#import "EMessageModel.h"
#import "EMessageGroupData.h"
#import "CoreData+MagicalRecord.h"
#import "EChatSocket.h"
#import "JSQMessagesViewController.h"

@interface EGroupChatViewController : JSQMessagesViewController <NSFetchedResultsControllerDelegate, EChatSocketDelegate, UIScrollViewDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) EChatSocket *chatSocket;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) EMessageGroupData *messageGroupData;
@property (assign, nonatomic) BOOL hasJustJoinedGroup;
@property (assign, nonatomic) BOOL fromVotePage;

@property (weak, nonatomic) IBOutlet UIButton *reportButton;

@end
