//
//  EMessageModel.h
//  Expressome
//
//  Created by Quan DT on 7/9/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import "JSQMessage.h"

@interface EMessageModel : NSObject <JSQMessageData>
// Message
@property (nonatomic, strong) NSNumber * msgId;
@property (nonatomic, strong) NSString * msgType;
@property (nonatomic, strong) NSDate * msgSentDate;
@property (nonatomic, strong) NSString * msgText;

// Room
@property (nonatomic, strong) NSDictionary *msgRoom;

// User
@property (nonatomic, strong) NSDictionary *msgUser;

// Data
@property (nonatomic, strong) NSDictionary *msgData;

@property (nonatomic, assign) BOOL isMediaMessage;
@property (strong, nonatomic) id<JSQMessageMediaData> media;


- (instancetype)initWithData:(NSDictionary *)data;
@end
