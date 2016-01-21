//
//  ESearchGroupViewController.h
//  Expresssome
//
//  Created by Thai Nguyen on 4/17/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TPKeyboardAvoidingTableView.h"

@interface ESearchGroupViewController : UIViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) NSString *groupName;
@property (weak, nonatomic) IBOutlet TPKeyboardAvoidingTableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *seachTextField;
@property (weak, nonatomic) IBOutlet UILabel *noResultLabel;

@property NSMutableArray *tableData;
@property NSInteger pageNumber;

@end
