//
//  EFeedBackViewController.h
//  Expressome
//
//  Created by Quan DT on 7/30/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EFeedBackViewController : UIViewController <UITextViewDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *contentTextView;
@property (weak, nonatomic) IBOutlet UILabel *numberLabel;
@property (weak, nonatomic) IBOutlet UILabel *questionLabel;
@end
