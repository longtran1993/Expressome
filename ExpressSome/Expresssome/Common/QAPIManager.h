//
//  QAPIManager.h
//
//  Created by Dang Quan on 7/4/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

#define kAPILoginPath                   @"authenticate/login"
#define kAPILogoutPath                  @"authenticate/logout"
#define kAPIRegisterPath                @"authenticate/registry"
#define kAPIUploadImagePath             @"imagemanage/upload"
#define kAPIUpdateDeviceTokenPath       @"authenticate/setmachinecode"
#define kAPISearchGroupPath             @"groupinfo/search"
#define kAPIGetGroupMemberPath          @"groupinfo/members"
#define kAPIJoinGroupPath               @"groupinfo/join"
#define kAPILeaveGroupPath              @"groupinfo/leave"
#define kAPIDetailGroupPath             @"groupinfo/detail"
#define kAPIDownloadImagePath           @"imagemanage/download"
#define kAPICreateGroupPath             @"groupinfo/create"
#define kAPICreateContestPath           @"contestinfo/create"
#define kAPIInviteToContestPath         @"contestinfo/invite"
#define kAPIGetNewContestsContestPath   @"contestinfo/listnew"
#define kAPIGetOnGoingContestPath       @"contestinfo/listongoing"
#define kAPIGetListPlayerRound1         @"contestplayer/listplayerround1"
#define kAPIGetListPlayerRound2         @"contestplayer/listplayerround2"
#define kAPIContestVoteRound1           @"contestplayer/voteround1"
#define kAPIContestVoteRound2           @"contestplayer/voteround2"
#define kAPIContestVoteResult           @"contestplayer/getTopWinner"
#define kAPIGetResultsContestPath       @"contestinfo/listdone"
#define kAPIMemberOfContestPath         @"contestinfo/players"
#define kAPIJoinContestPath             @"contestinfo/join"
#define kAPIGetContestDetailPath        @"contestinfo/detail"
#define KSocketAuthen                   @"chat/authenticate/join"
#define kAPIResetBadgePath              @"notification/resetbadge"
#define kAPIGetGroupChatMessagesPath    @"message/grouppage"
#define kAPIGetContestChatMessagesPath  @"message/contestchat"
#define kAPIChangePasswordPath          @"authenticate/changepassword"
#define kAPIRequestPasswordPath         @"authenticate/resetpassword"
#define kAPISetPasswordPath             @"authenticate/setpassword"
#define kAPISendFeedBack                @"feedback/sent"

#pragma mark - API params

#define kAPIParamGroupID               @"id"
#define kAPIParamUsername               @"username"
#define kAPIParamPassword               @"password"
#define kAPIParamEmail                  @"email"
#define kAPIParamDeviceName             @"deviceName"
#define kAPIParamDeviceId               @"udid"
#define kAPIParamMachineCode            @"machineCode"
#define kAPIParamPage                   @"page"
#define kAPIParamContestID              @"contestId"
#define kAPIParamContent                @"content"

#pragma mark - API response

#define kAPIResponseStatus              @"status"
#define kAPIResponseStatusSuccess       @"success"
#define kAPIResponseStatusFail          @"fail"
#define kAPIResponseMessage             @"message"
#define kAPIResponseData                @"data"
#define kAPIResponseCode                @"code"

#define kAPI403ErrorCode                403
#define kAPI718ErrorCode                718

#define kAPIImageTypeUserAvatar         @"user-avatar"
#define kAPIImageTypeGroupCover         @"group-cover"
#define kAPIImageTypeContestCover       @"contest-cover"
#define kAPIImageTypeContestPhoto       @"player-image"

typedef void (^QAPIResponseBlock)(id responseObject, NSError *error);

@interface QAPIManager : NSObject

@property (nonatomic, strong) NSDictionary *appendHeaderFields;

+ (instancetype)getInstance;

- (AFHTTPRequestOperation *)operationWithURL:(NSString *)URLString
                                      method:(NSString *)methodName
                                  parameters:(id)parameters
                                     success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                     failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
- (void)GET:(NSString *)apiURL params:(NSDictionary *)params completeWithBlock:(QAPIResponseBlock)block;
- (void)POST:(NSString *)apiURL params:(NSDictionary *)params completeWithBlock:(QAPIResponseBlock)block;
- (void)PUT:(NSString *)apiURL params:(NSDictionary *)params completeWithBlock:(QAPIResponseBlock)block;
- (void)DELETE:(NSString *)apiURL params:(NSDictionary *)params completeWithBlock:(QAPIResponseBlock)block;

- (void)cancelAll;
@end
