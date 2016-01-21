//
//  ESocket.m
//  Expresssome
//
//  Created by QuanDT on 6/18/15.
//  Copyright (c) 2015 QuanDT. All rights reserved.
//

#import "EChatSocket.h"
#import "SocketIO+SailsIO.h"
#import "AFNetworking.h"
#import "ECommon.h"
#import "SocketIOPacket.h"
#import "JSQMessages.h"

@implementation EChatSocket

- (instancetype)initWithGroupId:(NSString *)groupId
{
    self = [super init];
    if (self) {
        self.socketType = GROUP_CHAT_SOCKET;
        self.groupPageId = groupId;
        [self connect];
    }
    
    return self;
}

- (instancetype)initWithContestId:(NSString *)contestId
{
    self = [super init];
    if (self) {
        self.socketType = CONTEST_CHAT_SOCKET;
        self.contestId = contestId;
        [self connect];
    }
    
    return self;
}



- (void)connect
{
    if (_socketIO) {
        _socketIO = nil;
    }
    _socketIO = [[SocketIO alloc] initWithDelegate:self];
    [_socketIO connectToHost:kSocketHostAddress onPort:kSocketPort];
}

- (void)disconnect
{
    if(_socketIO) {
        [_socketIO disconnect];
    }
}

- (void)sendMessage:(NSString *)message
{
    NSString *socketPath = kSendGroupChatMessageAPIPath;
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:message, @"message", _groupPageId, @"groupId", nil];
    if(self.socketType == CONTEST_CHAT_SOCKET) {
        socketPath = kSendContestChatMessageAPIPath;
        params = [NSDictionary dictionaryWithObjectsAndKeys:message, @"message", _contestId, @"contestId", nil];
    }
    
    [_socketIO post:socketPath withData:params callback:^(id response) {
        if(_delegate && [_delegate respondsToSelector:@selector(socketDidSendMessageWithResponse:)]) {
            [_delegate socketDidSendMessageWithResponse:response];
        }
    }];
}

- (void)authen
{
    NSString *socketPath = kChatAuthenticateAPIPath;
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY], @"authToken", nil];
    [_socketIO post:socketPath withData:params callback:^(id response) {
        NSString *status = [response valueForKey:kAPIResponseStatus];
        if ([status isEqualToString:kAPIResponseStatusSuccess]) {
            _isAuthen = TRUE;
            if(_delegate && [_delegate respondsToSelector:@selector(socketDidConnect)]) {
                [_delegate socketDidConnect];
            }
        }
        else {
            _isAuthen = FALSE;
        }
    }];
}

- (void)join {
    NSString *socketPath = kJoinContestChatAPIPath;
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: _contestId, @"contestId", nil];
    [_socketIO post:socketPath withData:params callback:^(id response) {
        NSString *status = [response valueForKey:kAPIResponseStatus];
        if ([status isEqualToString:kAPIResponseStatusSuccess]) {
            _isJoinedContest = TRUE;
            if(_delegate && [_delegate respondsToSelector:@selector(socketDidConnect)]) {
                [_delegate socketDidJoinContest];
            }
        }
        else {
            _isJoinedContest = FALSE;
            if(_delegate && [_delegate respondsToSelector:@selector(socketFailedToJoinContestWithError:)]) {
                [_delegate socketFailedToJoinContestWithError:[response objectForKey:@"message"]];
            }
        }
    }];
}

- (BOOL)isConnected
{
    return _socketIO.isConnected;
}

- (BOOL)isAuthen {
    return _isAuthen;
}

- (BOOL)isJoinedContest {
    return _isJoinedContest;
}

#pragma marrk - SocketIODelegate

- (void) socketIODidConnect:(SocketIO *)socket
{
    [self authen];
}

- (void) socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error
{
    _isAuthen = FALSE;
    _isJoinedContest = FALSE;
    if(_delegate && [_delegate respondsToSelector:@selector(socketDidDisconnectWithError:)]) {
        [_delegate socketDidDisconnectWithError:error];
    }
}

- (void) socketIO:(SocketIO *)socket didReceiveMessage:(SocketIOPacket *)packet
{
    
}

- (void) socketIO:(SocketIO *)socket didReceiveJSON:(SocketIOPacket *)packet
{
    
}

- (void) socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet
{
    if ([packet.name isEqualToString:@"message"]) {
        NSData *data = [packet.data dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dict = [[[NSJSONSerialization JSONObjectWithData:data options:0 error:nil] valueForKey:@"args"] objectAtIndex:0];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKeyReceiveMessage object:nil userInfo:dict];
    }
}

- (void) socketIO:(SocketIO *)socket didSendMessage:(SocketIOPacket *)packet
{
    
}

- (void) socketIO:(SocketIO *)socket onError:(NSError *)error
{
    if(error) {
        _isAuthen = FALSE;
        _isJoinedContest = FALSE;
    }
}

// TODO: deprecated -> to be removed
- (void) socketIO:(SocketIO *)socket failedToConnectWithError:(NSError *)error __attribute__((deprecated))
{
    if(error) {
        _isAuthen = FALSE;
        _isJoinedContest = FALSE;
    }
}

- (void) socketIOHandshakeFailed:(SocketIO *)socket __attribute__((deprecated))
{
    
}

@end
