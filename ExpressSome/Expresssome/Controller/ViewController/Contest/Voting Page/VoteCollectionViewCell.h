//
//  VoteCollectionViewCell.h
//  Expressome
//
//  Created by Mr Lazy on 7/14/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VoteCollectionViewCell : UICollectionViewCell

@property(weak, nonatomic)IBOutlet UIView *infoView;
@property(weak, nonatomic)IBOutlet UIImageView *imageView;
@property(weak, nonatomic)IBOutlet UIImageView *userImageView;
@property(weak, nonatomic)IBOutlet UILabel *userNameLabel;
@property(weak, nonatomic)IBOutlet UILabel *groupNameLabel;
@property(weak, nonatomic)IBOutlet UIButton *voteButton;
@property(weak, nonatomic)IBOutlet UILabel *voteNumberLabel;
@property(weak, nonatomic)IBOutlet UILabel *alreadyVotedLabel;

@end
