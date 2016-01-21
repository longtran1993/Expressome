//
//  EContestChatPageViewController.h
//  Expresssome
//
//  Created by QuanDT on 07/15/15.
//  Copyright (c) 2015 QuanDT. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSQMessage.h"
#import "EMessageModel.h"
#import "EMessageGroupData.h"
#import "EChatSocket.h"
#import "JSQMessagesViewController.h"

@interface EContestChatPageViewController : JSQMessagesViewController <EChatSocketDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) EChatSocket *chatSocket;
@property (strong, nonatomic) EMessageGroupData *messageGroupData;
@property (strong, nonatomic) NSDictionary *contestInfo;
@end
