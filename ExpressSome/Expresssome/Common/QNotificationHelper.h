//
//  QNotificationHelper.h
//  Expressome
//
//  Created by Quan DT on 7/11/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kCreateGroupNotificationType            @"create_group"
#define kJoinGroupNotificationType              @"join_group"
#define kLeaveGroupNotificationType             @"leave_group"
#define kInviteGroupJoinContestNotificationType @"invite_join_contest"
#define kJoinContestNotificationType            @"join_contest"
#define kStartContestRound1NotificationType     @"contest_start_round1"
#define kStartContestRound2NotificationType     @"contest_start_round2"
#define kFinishContestNotificationType          @"contest_has_finished"
#define kMessageGroupChatNotificationType       @"chat_message"
#define kTestNotificationType                   @"test_apns"

@interface QNotificationHelper : NSObject
+ (instancetype)getInstance;

- (NSInteger)getBadgeNumber;
- (void)setBadgeNumber:(NSInteger)number;
- (void)descreaseBadgeNumberBy:(NSInteger)number;
- (void)resetBadgeForType:(NSString *) type;
- (void)playNotificationSound;
@end
