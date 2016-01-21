//
//  EMemberView.m
//  Expresssome
//
//  Created by Thai Nguyen on 5/29/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import "EMemberView.h"
#import "ECommon.h"
#import "UIImageView+WebCache.h"

@implementation EMemberView

- (void)loadDataWithDict:(NSDictionary *)dict adminId:(int)adminId
{
    _label.text = [dict valueForKey:@"username"];
    
    _imageView.layer.cornerRadius = _imageView.frame.size.width / 2;
    _imageView.clipsToBounds = YES;
    
    NSString *imageStr = [ECommon resetNullValueToString:[dict valueForKey:@"image"]];
    if (imageStr && imageStr.length > 0) {
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl1, imageStr];
        [_imageView sd_setImageWithURL:[NSURL URLWithString:urlStr] placeholderImage:[UIImage imageNamed:@"group_defaul_icon.png"] options:0];
    }
    
    if ([[dict valueForKey:@"id"] intValue] == adminId) {
        _adminImageView.hidden = NO;
    } else {
        _adminImageView.hidden = YES;
    }
}

- (void)loadGroupDetailWithDict:(NSDictionary *)dict adminId:(int)adminId
{
    _imageView.layer.cornerRadius = _imageView.frame.size.width / 2;
    _imageView.clipsToBounds = YES;
    
    NSString *imageStr = [ECommon resetNullValueToString:[dict valueForKey:@"image"]];
    if (imageStr && imageStr.length > 0) {
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl1, imageStr];
        [_imageView sd_setImageWithURL:[NSURL URLWithString:urlStr] placeholderImage:[UIImage imageNamed:@"group_defaul_icon.png"] options:0];
    }
    
    if ([[dict valueForKey:@"id"] intValue] == adminId) {
        _adminImageView.hidden = NO;
    } else {
        _adminImageView.hidden = YES;
    }
}

- (void)loadContestMemberDataWithDict:(NSDictionary *)dict
{
    _label.text = [dict valueForKey:@"username"];
    
    _imageView.layer.cornerRadius = _imageView.frame.size.width / 2;
    _imageView.clipsToBounds = YES;
    
    NSString *imageStr = [ECommon resetNullValueToString:[dict valueForKey:@"userImage"]];
    if (imageStr && imageStr.length > 0) {
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl1, imageStr];
        [_imageView sd_setImageWithURL:[NSURL URLWithString:urlStr] placeholderImage:[UIImage imageNamed:@"group_defaul_icon.png"] options:0];
    }
    
//    if ([[dict valueForKey:@"id"] intValue] == adminId) {
//        _adminImageView.hidden = NO;
//    } else {
        _adminImageView.hidden = YES;
//    }
}
@end
