//
//  ESelectContestPhotoViewController.h
//  Expresssome
//
//  Created by Thai Nguyen on 6/12/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ESelectContestPhotoViewController : UIViewController <UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *enterContestButton;
@property (weak, nonatomic) IBOutlet UILabel *selectPhotoLabel;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;

@property (strong, nonatomic) NSDictionary *contestInfo;

@end
