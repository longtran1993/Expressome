//
//  EContestPageViewController.h
//  Expresssome
//
//  Created by Thai Nguyen on 6/11/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EContestPageViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *screenTitleLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *contestPhotoImageView;
@property (weak, nonatomic) IBOutlet UIImageView *onwerPhotoImageView;
@property (weak, nonatomic) IBOutlet UILabel *groupNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *ownerLabel;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet UIView *imageHolderView;
@property (weak, nonatomic) IBOutlet UIView *infoHolderView;
@property (weak, nonatomic) IBOutlet UIView *descriptionHolderView;
@property (weak, nonatomic) IBOutlet UIView *memberView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIButton *enterContestButton;

@property (strong, nonatomic) NSDictionary *contestInfo;

@end
