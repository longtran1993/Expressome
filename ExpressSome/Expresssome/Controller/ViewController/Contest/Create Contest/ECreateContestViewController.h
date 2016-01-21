//
//  ECreateContestViewController.h
//  Expresssome
//
//  Created by Thai Nguyen on 6/9/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EInviteGroupViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "IQTextView.h"

@interface ECreateContestViewController : UIViewController <UITextViewDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, EInviteGroupViewControllerDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UITextField *descriptionTextField;
@property (weak, nonatomic) IBOutlet IQTextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet UITextField *inviteTextField;
@property (weak, nonatomic) IBOutlet UIButton *createButton;
@property (weak, nonatomic) IBOutlet UIImageView *inviteImageView;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;
@property (weak, nonatomic) IBOutlet UIButton *inviteButton;
@property (weak, nonatomic) IBOutlet UILabel *selectPhotoLabel;
@property (weak, nonatomic) IBOutlet UIView *inputHolderView;

@end
