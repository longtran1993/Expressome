//
//  EInviteGroupCell.m
//  Expresssome
//
//  Created by Thai Nguyen on 6/10/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import "EInviteGroupCell.h"
#import "ECommon.h"
#import "EConstant.h"
#import "UIImageView+WebCache.h"

@interface EInviteGroupCell ()
//@property(nonatomic, strong) SDWebImageManager *manager;
@end

@implementation EInviteGroupCell
{
    NSDictionary *dataDict;
}

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
    //_manager = [SDWebImageManager sharedManager];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)loadDataWithDict:(NSDictionary *)dict andSearchedKey:(NSString *)key
{
    dataDict = nil;
    dataDict = [[NSDictionary alloc] initWithDictionary:dict];
    
    _nameLabel.text = [ECommon resetNullValueToString:[dict valueForKey:@"name"]];
    
    NSMutableAttributedString* string = [[NSMutableAttributedString alloc]initWithString:_nameLabel.text];
    [string addAttribute:NSBackgroundColorAttributeName
                   value:[UIColor lightGrayColor]
                   //value:[UIColor colorWithRed:73.0f/255.0f green:77.0f/255.0f blue:12.0f/255.0f alpha:1.0f]
                   range:[[_nameLabel.text lowercaseString]
                          rangeOfString:[key lowercaseString]]];
    _nameLabel.attributedText = string;
    
    _photoImageView.layer.cornerRadius = _photoImageView.frame.size.width / 2;
    _photoImageView.clipsToBounds = YES;
    
    NSString *imageStr = [ECommon resetNullValueToString:[dict valueForKey:@"image"]];
    [self setAvatarWithImageSource:imageStr ?: @""];
//    if (imageStr && imageStr.length > 0) {
//        NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl1, imageStr];
//        
//        @autoreleasepool {
//            
//            [_photoImageView sd_setImageWithURL:[NSURL URLWithString:urlStr] placeholderImage:[UIImage imageNamed:@"group_defaul_icon.png"] options:0];
//
////            [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:urlStr] options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
////                if (image) {
////                    
////                    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
////                    dispatch_async(globalQueue, ^{
////                        
////                        @autoreleasepool {
////                             dispatch_async (dispatch_get_main_queue(), ^{
////                                [_photoImageView setImage: image];
////
////                            });
////                        }
////                    });
////                    
////                } else {
////                    [_photoImageView setImage:[UIImage imageNamed:@"group_defaul_icon.png"]];
////                }
////            }];
//            
//        }
//    } else {
//        [_photoImageView setImage:[UIImage imageNamed:@"group_defaul_icon.png"]];
//    }
}

- (void)dealloc {
    
   [[SDImageCache sharedImageCache] clearMemory];
}

- (void)loadDataWithDict:(NSDictionary *)dict
{
    dataDict = nil;
    dataDict = [[NSDictionary alloc] initWithDictionary:dict];
    
    _nameLabel.text = [ECommon resetNullValueToString:[dict valueForKey:@"name"]];
    
    _photoImageView.layer.cornerRadius = _photoImageView.frame.size.width / 2;
    _photoImageView.clipsToBounds = YES;
    
    NSString *imageStr = [ECommon resetNullValueToString:[dict valueForKey:@"image"]];
    [self setAvatarWithImageSource:imageStr ?: @""];
}

- (void)setAvatarWithImageSource:(NSString *)imageSrc {
    if (imageSrc && imageSrc.length > 0) {
       
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl1, imageSrc];
       
        //@autoreleasepool {
            [_photoImageView sd_setImageWithURL:[NSURL URLWithString:urlStr]
                               placeholderImage:[UIImage imageNamed:@"group_defaul_icon.png"]
                                        options:0];
//            SDWebImageManager *manager = [SDWebImageManager sharedManager];
//            [[manager imageCache] clearMemory];
//            [manager imageDownloader].maxConcurrentDownloads = 3;
//            
//            [manager downloadImageWithURL:[NSURL URLWithString:urlStr]
//                                  options:0
//                                 progress:nil
//                                completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
//                                    if (image && finished) {
//                                        dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//                                        dispatch_async(globalQueue, ^{
//                                            @autoreleasepool {
//                                                dispatch_async (dispatch_get_main_queue(), ^{
//                                                    [_photoImageView setImage: image];
//                                                });
//                                            }
//                                        });
//                                    } else {
//                                        [_photoImageView setImage:[UIImage imageNamed:@"group_defaul_icon.png"]];
//                                    }
//                                }];
            
        //}
        

    } else {
        [_photoImageView setImage:[UIImage imageNamed:@"group_defaul_icon.png"]];
    }

}

#pragma mark - Action

- (IBAction)selectButtonTapped:(id)sender {
    _isSelected = !_isSelected;
    if (_isSelected) {
        if (_isAbleToSelect) {
            [_selectButton setImage:[UIImage imageNamed:@"member_contest_enable.png"] forState:UIControlStateNormal];
            if (_delegate && [_delegate respondsToSelector:@selector(inviteGroupCellDidSelect:isSelected:)]) {
                [_delegate inviteGroupCellDidSelect:dataDict isSelected:YES];
            }
        } else {
            _isSelected = NO;
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"20 maximum group invites allowed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
        }
    } else {
        NSDictionary *currentGroupInfo = [[EUserData getInstance] dataForKey:GROUP_INFO_UD_KEY];
        if ([[currentGroupInfo valueForKey:@"id"] integerValue] != [[dataDict valueForKey:@"id"] integerValue]) {
            [_selectButton setImage:[UIImage imageNamed:@"member_contest.png"] forState:UIControlStateNormal];
            if (_delegate && [_delegate respondsToSelector:@selector(inviteGroupCellDidSelect:isSelected:)]) {
                [_delegate inviteGroupCellDidSelect:dataDict isSelected:NO];
            }
        } else {
            _isSelected = YES;
        }
    }
}

@end
