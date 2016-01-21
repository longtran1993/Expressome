//
//  EMemberView.h
//  Expresssome
//
//  Created by Thai Nguyen on 5/29/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EMemberView : UIView

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIImageView *adminImageView;

- (void)loadDataWithDict:(NSDictionary *)dict adminId:(int)adminId;
- (void)loadGroupDetailWithDict:(NSDictionary *)dict adminId:(int)adminId;
- (void)loadContestMemberDataWithDict:(NSDictionary *)dict;

@end
