//
//  ESocket.h
//  Expresssome
//
//  Created by QuanDT on 6/18/15.
//  Copyright (c) 2015 QuanDT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SocketIO.h"

#define kContestChatAPIPath @"/api/message/contestchat"
#define kSendGroupChatMessageAPIPath @"/chat/grouppage/message"
#define kSendContestChatMessageAPIPath @"/chat/contest/message"
#define kChatAuthenticateAPIPath @"/chat/authenticate/join"
#define kJoinContestChatAPIPath @"/chat/contest/join"

@protocol EChatSocketDelegate <NSObject>

@optional
- (void)socketDidConnect;
- (void)socketDidDisconnectWithError:(NSError *)error;
- (void)socketDidJoinContest;
- (void)socketFailedToJoinContestWithError:(NSString *)error;
- (void)socketDidSendMessageWithResponse:(id)response;

@end

typedef enum {
    GROUP_CHAT_SOCKET = 0,
    CONTEST_CHAT_SOCKET
} EChatSocketType;

@interface EChatSocket : NSObject <SocketIODelegate>

@property (weak, nonatomic) id<EChatSocketDelegate> delegate;
@property (assign, nonatomic) EChatSocketType socketType;
@property (strong, nonatomic) NSString *contestId;
@property (strong, nonatomic) NSString *groupPageId;
@property (strong, nonatomic) SocketIO *socketIO;
@property (assign, nonatomic) BOOL isAuthen;
@property (assign, nonatomic) BOOL isJoinedContest;

- (instancetype)initWithGroupId:(NSString *)groupId;
- (instancetype)initWithContestId:(NSString *)contestId;

- (void)connect;
- (void)authen;
- (void)join;
- (BOOL)isJoinedContest;
- (BOOL)isAuthen;
- (void)disconnect;
- (BOOL)isConnected;
- (void)sendMessage:(NSString *)message;

@end
