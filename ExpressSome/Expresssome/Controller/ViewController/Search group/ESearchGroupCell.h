//
//  ESearchGroupCell.h
//  Expresssome
//
//  Created by Nguyen Thong Thai on 4/17/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ESearchGroupCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *groupNameLabel;

- (void)loadDataWithDict:(NSDictionary *)dict andSearchedKey:(NSString *)key;

@end
