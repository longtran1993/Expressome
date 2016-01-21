//
//  EMessageView.h
//  Expresssome
//
//  Created by Nguyen Thong Thai on 6/5/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EMessageView : UIView
{
    NSDictionary *messageDict;
}

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIView *inforView;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *groupLabel;

- (void)loadDataWithDict:(NSDictionary *)dict andType:(NSString *)type groupName:(NSString *)groupName;
- (void)reloadTimeLabel;

@end
