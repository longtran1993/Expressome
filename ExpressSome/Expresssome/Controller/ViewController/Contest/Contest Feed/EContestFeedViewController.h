//
//  EContestFeedViewController.h
//  Expresssome
//
//  Created by Thai Nguyen on 6/8/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EContestFeedViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UISegmentedControl *segment;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property NSMutableArray *tableData;
@property NSInteger pageNumber;
@property NSInteger totalPage;

@end
