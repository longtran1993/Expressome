//
//  EInviteGroupCell.h
//  Expresssome
//
//  Created by Thai Nguyen on 6/10/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EInviteGroupCellDelegate <NSObject>

- (void)inviteGroupCellDidSelect:(NSDictionary *)dict isSelected:(BOOL)isSelected;

@end

@interface EInviteGroupCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *selectButton;
@property (assign, nonatomic) BOOL isSelected;
@property (assign, nonatomic) BOOL isAbleToSelect;

@property (assign, nonatomic) id <EInviteGroupCellDelegate> delegate;

- (void)loadDataWithDict:(NSDictionary *)dict andSearchedKey:(NSString *)key;
- (void)loadDataWithDict:(NSDictionary *)dict;
- (IBAction)selectButtonTapped:(id)sender;

@end
