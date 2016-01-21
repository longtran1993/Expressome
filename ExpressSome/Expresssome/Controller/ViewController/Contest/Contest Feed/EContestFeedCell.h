//
//  EContestFeedCell.h
//  Expresssome
//
//  Created by Thai Nguyen on 6/12/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface EContestFeedCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UILabel *contestName;
@property (weak, nonatomic) IBOutlet UILabel *memberLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *joinLabel;

@property (strong, nonatomic) NSString *serverTime;

- (void)loadDataWithDict:(NSDictionary *)dict andTableTag:(NSInteger) tag;

@end
