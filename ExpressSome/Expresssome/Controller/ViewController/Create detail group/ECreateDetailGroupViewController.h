//
//  ECreateDetailGroupViewController.h
//  Expresssome
//
//  Created by Thai Nguyen on 4/17/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EProfilePhotoViewController.h"
#import "IQTextView.h"

@interface ECreateDetailGroupViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UIButton *createButton;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UIImageView *textViewBgrImageView;
@property (weak, nonatomic) IBOutlet IQTextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet UIImageView *bgrImageView;
@property (weak, nonatomic) IBOutlet UITextField *placeHolderTextField;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *selectPhotoLabel;
@property (weak, nonatomic) IBOutlet UIView *inputHolderView;


@end
