//
//  ESearchGroupCell.m
//  Expresssome
//
//  Created by Nguyen Thong Thai on 4/17/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import "ESearchGroupCell.h"
#import "ECommon.h"
#import "EConstant.h"
#import "UIImageView+WebCache.h"

@implementation ESearchGroupCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)loadDataWithDict:(NSDictionary *)dict andSearchedKey:(NSString *)key
{
    _groupNameLabel.text = [ECommon resetNullValueToString:[dict valueForKey:@"name"]];
    
    NSMutableAttributedString* string = [[NSMutableAttributedString alloc]initWithString:_groupNameLabel.text];
    [string addAttribute:NSBackgroundColorAttributeName value:[UIColor colorWithRed:189.0f/255.0f green:231.0f/255.0f blue:240.0f/255.0f alpha:1.0f] range:[[_groupNameLabel.text lowercaseString] rangeOfString:[key lowercaseString]]];
    _groupNameLabel.attributedText = string;
    
    _avatarImageView.layer.cornerRadius = _avatarImageView.frame.size.width / 2;
    _avatarImageView.clipsToBounds = YES;
    
    NSString *imageStr = [ECommon resetNullValueToString:[dict valueForKey:@"image"]];
    if (imageStr && imageStr.length > 0) {
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl1, imageStr];
        [_avatarImageView sd_setImageWithURL:[NSURL URLWithString:urlStr] placeholderImage:[UIImage imageNamed:@"group_defaul_icon.png"] options:0];
    } else {
        [_avatarImageView setImage:[UIImage imageNamed:@"group_defaul_icon.png"]];
    }
}

@end
