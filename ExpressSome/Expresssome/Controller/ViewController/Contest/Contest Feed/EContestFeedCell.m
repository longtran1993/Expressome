//
//  EContestFeedCell.m
//  Expresssome
//
//  Created by Thai Nguyen on 6/12/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import "EContestFeedCell.h"
#import "UIImageView+WebCache.h"
#import "ECommon.h"

@implementation EContestFeedCell
{
    NSDictionary *contestInfo;
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)loadDataWithDict:(NSDictionary *)dict andTableTag:(NSInteger) tag
{
    contestInfo = dict;
    
    _photoImageView.layer.cornerRadius = _photoImageView.frame.size.width / 2;
    _photoImageView.clipsToBounds = YES;
    
    NSString *imageStr = [EJSONHelper valueFromData:[dict valueForKey:@"image"]];
    if (imageStr && imageStr.length > 0) {
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl1, imageStr];
        [_photoImageView sd_setImageWithURL:[NSURL URLWithString:urlStr] placeholderImage:[UIImage imageNamed:@"group_defaul_icon.png"] options:0];
    } else {
        [_photoImageView setImage:[UIImage imageNamed:@"group_defaul_icon.png"]];
    }
    
    _contestName.text = [dict valueForKey:@"name"];
    
    NSInteger numberOfPlayer = [[dict valueForKey:@"amountFriends"] integerValue];
    if (numberOfPlayer > 1) {
        _memberLabel.text = [NSString stringWithFormat:@"(%ld Friends Competing)", (long)numberOfPlayer];
    } else if (numberOfPlayer == 1) {
        _memberLabel.text = @"(1 Friend Competing)";
    } else {
        _memberLabel.text = @"(No Friends Competing)";
    }
    
    NSString *startDateStr = nil;
    NSString *expiredDateStr = nil;
    if(tag == kResultsContestTableViewTag) {
        startDateStr = [EJSONHelper valueFromData:[dict valueForKey:@"expiredDate"]];
        expiredDateStr = [EJSONHelper valueFromData:_serverTime];
    }
    else {
        startDateStr = [EJSONHelper valueFromData:_serverTime];
        expiredDateStr = [EJSONHelper valueFromData:[dict valueForKey:@"expiredDate"]];
    }
    
    if (startDateStr && startDateStr.length > 0 && expiredDateStr && expiredDateStr.length > 0) {
        NSDate *startDate = [QSystemHelper localDateFromUTCString:startDateStr];
        NSDate *expiredDate = [QSystemHelper localDateFromUTCString:expiredDateStr];
        NSTimeInterval timeInterval = [expiredDate timeIntervalSinceDate:startDate];
        int min = 60;
        int hour = 60*60;
        int day = 60*60*24;
        int month = 60*60*24*30;
        int year = 60*60*24*365;
        
        if (timeInterval >= year) { // years
            long value = lroundf(timeInterval / year);
            if (value == 1) {
                _timeLabel.text = [NSString stringWithFormat:@"1year"];
            } else {
                _timeLabel.text = [NSString stringWithFormat:@"%ldyears", value];
            }
        } else if (timeInterval >= month && timeInterval < year) { // months
            long value = lroundf(timeInterval / month);
            if (value == 1) {
                _timeLabel.text = [NSString stringWithFormat:@"1month"];
            } else {
                _timeLabel.text = [NSString stringWithFormat:@"%ldmonths", value];
            }
        } if (timeInterval >= day && timeInterval < month) { // days
            long value = lroundf(timeInterval / day);
            if (value == 1) {
                _timeLabel.text = [NSString stringWithFormat:@"1day"];
            } else {
                _timeLabel.text = [NSString stringWithFormat:@"%lddays", value];
            }
        } if (timeInterval >= hour && timeInterval < day) { // hours
            long value = lroundf(timeInterval / hour);
            if (value == 1) {
                _timeLabel.text = [NSString stringWithFormat:@"1hr"];
            } else {
                _timeLabel.text = [NSString stringWithFormat:@"%ldhrs", value];
            }
        } else if(timeInterval < hour){ // minutes
            long value = lroundf(timeInterval / min);
            if (value <= 1) {
                _timeLabel.text = [NSString stringWithFormat:@"1min"];
            } else {
                _timeLabel.text = [NSString stringWithFormat:@"%ldmins", value];
            }
        }
        
        if(tag == kResultsContestTableViewTag) {
            _timeLabel.text = [_timeLabel.text stringByAppendingString:@" ago"];
        }
    }   
    
}

@end
