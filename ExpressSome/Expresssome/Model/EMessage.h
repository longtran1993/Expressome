//
//  EMessage.h
//  Expressome
//
//  Created by Thai Nguyen on 6/26/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface EMessage : NSManagedObject

@property (nonatomic, retain) NSNumber * msgId;
@property (nonatomic, retain) NSNumber * userId;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * userImage;
@property (nonatomic, retain) NSString * userImageThumbnail;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSNumber * groupId;
@property (nonatomic, retain) NSString * groupName;
@property (nonatomic, retain) NSNumber * contestId;
@property (nonatomic, retain) NSString * contestName;
@property (nonatomic, retain) NSString * contestImage;
@property (nonatomic, retain) NSString * contestImageThumbnail;
@property (nonatomic, retain) NSNumber * status;

@end
