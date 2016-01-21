//
//  EUserData.m
//  Expressome
//
//  Created by Dang Quan on 7/5/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import "EUserData.h"

@implementation EUserData
+ (instancetype)getInstance {
    
    static EUserData *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[EUserData alloc] init];
    });
    return _sharedInstance;
}

- (id)init {
    self = [super init];
    if(self) {
        _userDefault = [NSUserDefaults standardUserDefaults];
    }
    return self;
}

- (void)setObject:(id)data forKey:(NSString *)key {
    [_userDefault setObject:data forKey:key];
    [_userDefault synchronize];
}

- (id)objectForKey:(NSString *)key {
    return [_userDefault objectForKey:key];
}

- (void)removeObjectForKey:(NSString *)key {
    [_userDefault removeObjectForKey:key];
    [_userDefault synchronize];
}

- (void)setData:(id)data forKey:(NSString *)key {
    [self setObject:[NSKeyedArchiver archivedDataWithRootObject:data] forKey:key];
}

- (id)dataForKey:(NSString *)key {
    return [NSKeyedUnarchiver unarchiveObjectWithData:[self objectForKey:key]];
}

- (void)removeDataForKey:(NSString *)key {
    [self removeObjectForKey:key];
}

- (void)clear {
    [self removeObjectForKey:USER_ID_UD_KEY];
    [self removeObjectForKey:USER_NAME_UD_KEY];
    [self removeObjectForKey:EMAIL_UD_KEY];
    [self removeObjectForKey:PASSWORD_UD_KEY];
    [self removeObjectForKey:AUTH_TOKEN_UD_KEY];
    [self removeObjectForKey:DONT_SHOW_POPUP_UD_KEY];
    [self removeObjectForKey:GROUP_INFO_UD_KEY];
    [self removeObjectForKey:HAS_JUST_JOINED_GROUP_UD_KEY];
    [self removeObjectForKey:DONT_SHOW_POPUP_VOTING_ROUND_UD_KEY];
    [self removeObjectForKey:DONT_SHOW_POPUP_CHANGE_VOTE_UD_KEY];
}

@end
