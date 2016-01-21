//
//  EMessageModel.m
//  Expressome
//
//  Created by Quan DT on 7/9/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import "EMessageModel.h"

@implementation EMessageModel

- (instancetype)initWithData:(NSDictionary *)data
{
    self = [super init];
    if(self) {
        // Main info
        self.msgId = [NSNumber numberWithInteger:[[data objectForKey:@"id"] integerValue]];
        self.msgText = [data objectForKey:@"message"];
        self.msgSentDate = [QSystemHelper localDateFromUTCString:[data objectForKey:@"sentAt"]];
        self.msgType = [data objectForKey:@"type"];
        self.msgRoom = [data objectForKey:@"room"];
        self.msgUser = [data objectForKey:@"user"];
        self.msgData = [data objectForKey:@"data"];
        self.isMediaMessage = NO;
    }
    return self;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    EMessageModel *aMessage = (EMessageModel *)object;
    
    if (self.isMediaMessage != aMessage.isMediaMessage) {
        return NO;
    }
    
    BOOL hasEqualContent = self.isMediaMessage ? [self.media isEqual:aMessage.media] : [self.text isEqualToString:aMessage.text];
    
    return [self.senderId isEqualToString:aMessage.senderId]
    && [self.senderDisplayName isEqualToString:aMessage.senderDisplayName]
    && ([self.date compare:aMessage.date] == NSOrderedSame)
    && hasEqualContent;
}

#pragma mark - JSQMessageData -
- (NSString *)senderId {
    return [NSString stringWithFormat:@"%@",[self.msgUser objectForKey:@"id"]];
}

- (NSString *)senderDisplayName {
    return [self.msgUser objectForKey:@"username"];
}

- (NSString *)text {
    return self.msgText;
}

- (NSString *)groupName {
    return [self.msgUser objectForKey:@"groupName"];
}

- (NSDate *)date {
    return self.msgSentDate;
}

- (NSUInteger)messageHash {
    return self.hash;
}

- (BOOL)isMediaMessage {
    return _isMediaMessage;
}

- (NSUInteger)hash
{
    NSUInteger contentHash = self.isMediaMessage ? [self.media mediaHash] : self.text.hash;
    return self.senderId.hash ^ self.date.hash ^ contentHash;
}
@end
