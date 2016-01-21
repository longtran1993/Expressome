//
//  EUserData.h
//  Expressome
//
//  Created by Dang Quan on 7/5/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DID_INIT_APP_UD_KEY @"userdefault_did_init_app"
#define USER_NAME_UD_KEY @"userdefault_username"
#define PASSWORD_UD_KEY @"userdefault_password"
#define EMAIL_UD_KEY @"userdefault_email"
#define USER_ID_UD_KEY @"userdefault_userId"
#define DEVICE_TOKEN_UD_KEY @"userdefault_device_token"
#define DID_GET_DEVICE_TOKEN_UD_KEY @"userdefault_did_get_device_token"
#define DEVICE_ID_UD_KEY @"userdefault_device_id"
#define AUTH_TOKEN_UD_KEY @"userdefault_auth_token"
#define AVATAR_PATH_UD_KEY @"userdefault_avatar_path"
#define DONT_SHOW_POPUP_UD_KEY @"userdefault_dont_show_popup"
#define GROUP_INFO_UD_KEY @"userdefault_group_info"
#define HAS_JUST_JOINED_GROUP_UD_KEY @"has_just_joined_group"
#define DONT_SHOW_POPUP_VOTING_ROUND_UD_KEY @"userdefault_dont_show_popup_voting_round"
#define DONT_SHOW_POPUP_CHANGE_VOTE_UD_KEY  @"userdefault_dont_show_popup_change_vote"

@interface EUserData : NSObject
{
    NSUserDefaults *_userDefault;
}

+ (instancetype)getInstance;

- (void)setObject:(id)data forKey:(NSString *)key;
- (id)objectForKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;

- (void)setData:(id)data forKey:(NSString *)key;
- (id)dataForKey:(NSString *)key;
- (void)removeDataForKey:(NSString *)key;
- (void)clear;

@end
