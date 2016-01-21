//
//  TopVoteCollectionViewCell.h
//  Expressome
//
//  Created by Mr Lazy on 7/17/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TopVoteCollectionViewCell : UICollectionViewCell

@property(weak, nonatomic) IBOutlet UIImageView *contestOwerImageView;
@property(weak, nonatomic) IBOutlet UILabel *contestOwerLabel;
@property(weak, nonatomic) IBOutlet UILabel *groupNameLabel;
@property(weak, nonatomic) IBOutlet UITextView *contestDescriptionTV;
@property(weak, nonatomic) IBOutlet UIButton *expandDescriptionButton;
@property (weak, nonatomic) IBOutlet UIImageView *separator;

@end
