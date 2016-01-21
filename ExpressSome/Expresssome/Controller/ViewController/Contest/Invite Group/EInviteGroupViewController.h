//
//  EInviteGroupViewController.h
//  Expresssome
//
//  Created by Thai Nguyen on 6/9/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EInviteGroupCell.h"
#import "TPKeyboardAvoidingTableView.h"

@protocol EInviteGroupViewControllerDelegate <NSObject>

- (void)inviteGroupDidSelectGroups:(NSArray *)groups;

@end

@interface EInviteGroupViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, EInviteGroupCellDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *seachBar;
@property (weak, nonatomic) IBOutlet TPKeyboardAvoidingTableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *noResultLabel;
@property (weak, nonatomic) IBOutlet UILabel *numberLabel;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@property NSMutableArray *tableData;
@property NSInteger pageNumber;

@property (strong, nonatomic) NSMutableArray *listGroup;
@property (weak, nonatomic) id <EInviteGroupViewControllerDelegate> deleagte;

@end
