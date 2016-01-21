//
//  EMessageView.m
//  Expresssome
//
//  Created by Nguyen Thong Thai on 6/5/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import "EMessageView.h"
#import "ECommon.h"
#import "UIImageView+WebCache.h"

@implementation EMessageView

- (void)loadDataWithDict:(NSDictionary *)dict andType:(NSString *)type groupName:(NSString *)groupName
{
    messageDict = dict;
    _nameLabel.text = [dict valueForKey:@"username"];
    _groupLabel.text = groupName;
    
    _avatarImageView.layer.cornerRadius = _avatarImageView.frame.size.width / 2;
    _avatarImageView.clipsToBounds = YES;
    
    NSString *imageStr = [ECommon resetNullValueToString:[dict valueForKey:@"image"]];
    if (imageStr && imageStr.length > 0) {
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl1, imageStr];
        [_avatarImageView sd_setImageWithURL:[NSURL URLWithString:urlStr] placeholderImage:[UIImage imageNamed:@"avatar.png"] options:0];
    }
    
    if ([type isEqualToString:@"join"]) {
        if ([[dict valueForKey:@"user_id"] intValue] != [[[EUserData getInstance] objectForKey:USER_ID_UD_KEY] intValue]) {
            _inforView.frame = CGRectMake(0.0f, _inforView.frame.origin.y, _inforView.frame.size.width, _inforView.frame.size.height);
            _contentView.frame = CGRectMake(70.0f, _contentView.frame.origin.y, _contentView.frame.size.width, _contentView.frame.size.height);
        }
    }
    [self reloadTimeLabel];
}

- (void)reloadTimeLabel
{
    NSDate *createDate = [messageDict valueForKey:@"date"];
    if (createDate) {
        NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:createDate];
        int min = 60;
        int hour = 60*60;
        int day = 60*60*24;
        int month = 60*60*24*30;
        int year = 60*60*24*365;
        
        if (timeInterval >= year) {
            int value = timeInterval / year;
            if (value == 1) {
                _timeLabel.text = [NSString stringWithFormat:@"1 year ago"];
            } else {
                _timeLabel.text = [NSString stringWithFormat:@"%d years ago", value];
            }
        } else if (timeInterval >= month) {
            int value = timeInterval / month;
            if (value == 1) {
                _timeLabel.text = [NSString stringWithFormat:@"1 month ago"];
            } else {
                _timeLabel.text = [NSString stringWithFormat:@"%d months ago", value];
            }
        } if (timeInterval >= day) {
            int value = timeInterval / day;
            if (value == 1) {
                _timeLabel.text = [NSString stringWithFormat:@"1 day ago"];
            } else {
                _timeLabel.text = [NSString stringWithFormat:@"%d days ago", value];
            }
        } if (timeInterval >= hour) {
            int value = timeInterval / hour;
            if (value == 1) {
                _timeLabel.text = [NSString stringWithFormat:@"1 hour ago"];
            } else {
                _timeLabel.text = [NSString stringWithFormat:@"%d hours ago", value];
            }
        } else {
            int value = timeInterval / min;
            if (value <= 1) {
                _timeLabel.text = [NSString stringWithFormat:@"1 min ago"];
            } else {
                _timeLabel.text = [NSString stringWithFormat:@"%d minutes ago", value];
            }
        }
    }
}

@end
