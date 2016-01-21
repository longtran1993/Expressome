//
//  EConstant.h
//  Expresssome
//
//  Created by Thai Nguyen on 4/17/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>

//#define BUG_LOGGING_ENABLE 1
#define CRASH_REPORT_ENABLE 1

//#define kAPIBaseUrl                     @"http://exp.hypertech.com.vn:1337/api/"
//#define kAPIBaseUrl1                    @"http://exp.hypertech.com.vn:1337"

//#define kAPIBaseUrl                     @"http://45.55.30.123:1337/api/"
//#define kAPIBaseUrl1                    @"http://45.55.30.123:1337"

//#define kAPIBaseUrl                    @"http://14.161.35.34:1337/api/"
//#define kAPIBaseUrl1                   @"http://14.161.35.34:1337"

//#define kAPIBaseUrl                    @"http://rubyspace.net:2020/api/"
//#define kAPIBaseUrl1                   @"http://rubyspace.net:2020"
//#define kSocketHostAddress   @"rubyspace.net"
//#define kSocketPort 2020

// Server KH
#define kAPIBaseUrl                  @"http://45.55.30.123:2020/api/"
#define kAPIBaseUrl1                 @"http://45.55.30.123:2020"
#define kSocketHostAddress   @"45.55.30.123"
#define kSocketPort 2020

//#define kAPIBaseUrl         @"http://localhost:2020/api/"//         @"http://45.55.30.123:2020/api/"
//#define kAPIBaseUrl1        @"http://localhost:2020"//          @"http://45.55.30.123:2020"
//#define kSocketHostAddress  @"localhost"// @"45.55.30.123"
//#define kSocketPort 2020 //1337


//#define kAPIBaseUrl         @"http://localhost:1337/api/"//         @"http://45.55.30.123:2020/api/"
//#define kAPIBaseUrl1        @"http://localhost:1337"//          @"http://45.55.30.123:2020"
//#define kSocketHostAddress  @"localhost"// @"45.55.30.123"
//#define kSocketPort 1337 //1337

//#define kAPIBaseUrl                     @"http://10.0.0.9:1337/api/"
//#define kAPIBaseUrl1                    @"http://10.0.0.9:1337"


//#define kSocketHostAddress @"exp.hypertech.com.vn"
//#define kSocketHostAddress @"45.55.30.123" // Customer's server
//#define kSocketHostAddress   @"rubyspace.net" //@"14.161.35.34" // SS's server  @"rubyspace.net" rubyspace.net:2020
//#define kSocketHostAddress   @"45.55.30.123"  //@"14.161.35.34"
//#define kSocketHostAddress @"10.0.0.9:1337"
//#define kSocketPort 2020
//#define kSocketPort 80  //1337

#define kPhotoSize      450.0
#define kPhotoTypeUser                  0
#define kPhotoTypeGroup                 1

#define kNewContestType 0
#define kOnGoingContestType 1
#define kResultContestType 2

#define kRound1ContestType 1
#define kRound2ContestType 2

#define kDescriptionMaxLength           300
#define kMaxInvitingGroupNumber         20

#define kAvatarImagePath @"avatar_photos"

#define kNotificationKeyReceiveMessage          @"chat_message_notification"
#define kNotificationKeyPushCreateGroup         @"create_group_notification"
#define kNotificationKeyPushJoinGroup           @"join_group_notification"
#define kNotificationKeyPushInviteJoinContest   @"invite_join_contest_notification"
#define kNotificationKeyPushLeaveGroup          @"leave_group_notification"
#define kNotificationKeyPushJoinContest         @"join_contest_notification"
#define kNotificationKeyPushStartContestRound1  @"contest_start_round1_notification"
#define kNotificationKeyPushStartContestRound2  @"contest_start_round2_notification"
#define kNotificationKeyPushFinishContest       @"contest_has_finished_notification"


#define kCreateGroupMsgType             @"create_group"
#define kJoinGroupMsgType               @"join_group"
#define kLeaveGroupMsgType              @"leave_group"
#define kInviteGroupJoinContestMsgType  @"invite_join_contest"
#define kJoinContestMsgType             @"join_contest"
#define kStartContestRound1MsgType      @"contest_start_round1"
#define kStartContestRound2MsgType      @"contest_start_round2"
#define kFinishContestMsgType           @"contest_has_finished"
#define kMessageGroupChatMsgType        @"chat_message"
#define kUserVotePhotoMsgType           @"user_vote_photo"
#define kUserWinContestMsgType          @"user_win_contest"
#define kUserVoteImageMsgType           @"vote_image"
#define kUserWinnerContestMsgType       @"contest_winner"

#define kGroupChatRoomType @"grouppage"
#define kContestChatRoomType @"contestchat"
#define kApp_Badge_Count        @"kApp_Badge_Count"
#define kHandlePushNotification     @"kHandlePushNotification"

#define kMessageStatusLocal     1
#define kMessageStatusSending   2
#define kMessageStatusSent      3
#define kMessageStatusReceived  4

#define kNewContestTableViewTag 0
#define kOnGoingContestTableViewTag 1
#define kResultsContestTableViewTag 2

#define kMessageContentCreateGroup @"Congratulations on your new group! Competing is better together. Share your group name with your friends so that they can join you in the competition."
#define kMessageContentJoinGroup @"Has joined your Group!"
#define kMessageContentInviteToJoinContest @"Invited your Group to the contest"
#define kMessageContentFinishContest @"The final round of %@ has ended. Go see where your group ranked!"
#define kMessageContentAdvanceToNextRoundInContest @"Was eliminated from %@ in %@"

#define kPurpleColor [UIColor colorWithRed:139./255 green:123./255 blue:158./255 alpha:1]
#define kLightBlueColor [UIColor colorWithRed:155./255 green:202./255 blue:229./255 alpha:1]
#define kRedColor [UIColor colorWithRed:234./255 green:108./255 blue:112./255 alpha:1]
#define kGreenColor [UIColor colorWithRed:133./255 green:190./255 blue:155./255 alpha:1]
#define kWhiteColor [UIColor whiteColor]
#define kLightGrayColor [UIColor lightGrayColor]
#define kGrayColor [UIColor grayColor]

#define kApplication_did_enter_background    @"application_did_enter_background"


// Send Grid
#define kSendGridUserName @"duynt"
#define kSendGridPassword @"duynt150388"
#define kSendGridAPIKey @"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"
