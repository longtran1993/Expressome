//
//  EGroupDetailViewController.h
//  Expresssome
//
//  Created by Thai Nguyen on 4/15/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EGroupDetailViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *groupPhotoImageView;
@property (weak, nonatomic) IBOutlet UILabel *memberLabel;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet UIButton *joinButton;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIView *infoView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *leaveGroupView;
@property (weak, nonatomic) IBOutlet UIButton *stickButton;
@property (weak, nonatomic) IBOutlet UIView *menuView;
@property (weak, nonatomic) IBOutlet UIButton *menuButton;

@property (strong, nonatomic) NSDictionary *groupInfo;

@end
