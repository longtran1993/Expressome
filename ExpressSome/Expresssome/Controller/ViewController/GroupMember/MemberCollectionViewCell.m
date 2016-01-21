//
//  MemberCollectionViewCell.m
//  Expresssome
//
//  Created by Thai Nguyen on 5/29/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import "MemberCollectionViewCell.h"
#import "UIImageView+WebCache.h"
#import "ECommon.h"

@implementation MemberCollectionViewCell

- (void)setDataWithDict:(NSDictionary *)dict adminId:(int)adminId;
{
    _nameLabel.text = [dict valueForKey:@"username"];
    
    _imageView.layer.cornerRadius = _imageView.frame.size.width / 2;
    _imageView.clipsToBounds = YES;
    
    NSString *imageStr = [ECommon resetNullValueToString:[dict valueForKey:@"image"]];
    if (imageStr && imageStr.length > 0) {
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl1, imageStr];
        [_imageView sd_setImageWithURL:[NSURL URLWithString:urlStr] placeholderImage:[UIImage imageNamed:@"avatar.png"] options:0];
    } else {
        [_imageView setImage:[UIImage imageNamed:@"avatar.png"]];
    }
    
    if ([[dict valueForKey:@"id"] intValue] == adminId) {
        _adminimageView.hidden = NO;
    } else {
        _adminimageView.hidden = YES;
    }
}

- (void)setContestMemberDataWithDict:(NSDictionary *)dict;
{
    _nameLabel.text = [dict valueForKey:@"username"];
    
    _imageView.layer.cornerRadius = _imageView.frame.size.width / 2;
    _imageView.clipsToBounds = YES;
    
    NSString *imageStr = [ECommon resetNullValueToString:[dict valueForKey:@"userImage"]];
    if (imageStr && imageStr.length > 0) {
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl1, imageStr];
        [_imageView sd_setImageWithURL:[NSURL URLWithString:urlStr] placeholderImage:[UIImage imageNamed:@"avatar.png"] options:0];
    } else {
        [_imageView setImage:[UIImage imageNamed:@"avatar.png"]];
    }
    
//    if ([[dict valueForKey:@"id"] intValue] == adminId) {
//        _adminimageView.hidden = NO;
//    } else {
        _adminimageView.hidden = YES;
//    }
}

@end
