//
//  MemberCollectionViewCell.h
//  Expresssome
//
//  Created by Thai Nguyen on 5/29/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MemberCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *adminimageView;

- (void)setDataWithDict:(NSDictionary *)dict adminId:(int)adminId;
- (void)setContestMemberDataWithDict:(NSDictionary *)dict;
@end
