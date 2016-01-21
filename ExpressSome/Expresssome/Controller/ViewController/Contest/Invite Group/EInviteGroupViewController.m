//
//  EInviteGroupViewController.m
//  Expresssome
//
//  Created by Thai Nguyen on 6/9/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import "EInviteGroupViewController.h"
#import "AFNetworking.h"
#import "ECommon.h"
#import "EConstant.h"
#import "SVPullToRefresh.h"
#import "SDImageCache.h"

@interface EInviteGroupViewController ()
{
    AFHTTPRequestOperation *post;
    BOOL isLoading;
    BOOL keyboardShown;
    CGFloat keyboardOverlap;
    BOOL displaySelectedGroup;
    NSString *_lastSearchKeyword;
    NSInteger _totalPage;
}

@property (weak, nonatomic) IBOutlet UILabel *lblGroupName;
@end

@implementation EInviteGroupViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    
   
    _tableData = [[NSMutableArray alloc] init];
    _lastSearchKeyword = @"";
    _totalPage = 1;
    _pageNumber = 0;
    
    NSString *currentGroupName = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentGroupName"];
    if ([currentGroupName length]) {
        self.lblGroupName.text = currentGroupName;
    }
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
//    self.tableView.layer.borderWidth = 2.0;
//    self.tableView.layer.borderColor = [UIColor redColor].CGColor;
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) { // Fix #375
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGRect newFrame = self.tableView.frame;
        newFrame.size.height = screenRect.size.height - newFrame.origin.y - 64;
        self.tableView.frame = newFrame;
    }
    
    _noResultLabel.hidden = YES;
    displaySelectedGroup = YES;
    _numberLabel.text = [NSString stringWithFormat:@"%lu/%d", (unsigned long)_listGroup.count, kMaxInvitingGroupNumber];
     
//    [self.tableView addPullToRefreshWithActionHandler:^{
//        __typeof (pSelf) __strong mySelf = pSelf;
//        [mySelf searchGroupWithKey:_seachBar.text];
//        [mySelf.tableView.pullToRefreshView stopAnimating];
//        mySelf.tableView.showsInfiniteScrolling = YES;
//    }];
//    
//
//
    __weak typeof(self) weakSelf = self;

    [self.tableView addInfiniteScrollingWithActionHandler:^{
        [weakSelf searchGroupWithKey:_seachBar.text];
    }];
    
    
    
    
    // Set state for UI elements
    _tableView.showsInfiniteScrolling = NO;
    _tableView.showsPullToRefresh = NO;
    self.doneButton.hidden = TRUE;
    
    // Custom clear button
    UIButton *clearButton = [self.seachBar valueForKey:@"_clearButton"];
    [clearButton setImage:[UIImage imageNamed:@"search-clear-btn"] forState:UIControlStateNormal];
}

//- (UIStatusBarStyle)preferredStatusBarStyle{
//    //return UIStat
//}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
     [[SDImageCache sharedImageCache] clearMemory];
    [[SDImageCache sharedImageCache] cleanDisk];
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
}

- (void)viewDidDisappear:(BOOL)animated {
    
    [super viewDidDisappear: animated];
    [[SDImageCache sharedImageCache] clearMemory];
}

- (void)keyboardWillShow:(NSNotification *)aNotification
{
    if (keyboardShown) return;
    
    keyboardShown = YES;
    
    // Get the keyboard size
    UIScrollView *tableView;
    if ([self.tableView.superview isKindOfClass:[UIScrollView class]]) {
        tableView = (UIScrollView *)self.tableView.superview;
    } else {
        tableView = self.tableView;
    }
    NSDictionary *userInfo = [aNotification userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [tableView.superview convertRect:[aValue CGRectValue] fromView:nil];
    
    // Get the keyboard's animation details
    NSTimeInterval animationDuration;
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    UIViewAnimationCurve animationCurve;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    
    // Determine how much overlap exists between tableView and the keyboard
    CGRect tableFrame = tableView.frame;
    CGFloat tableLowerYCoord = tableFrame.origin.y + tableFrame.size.height;
    keyboardOverlap = tableLowerYCoord - keyboardRect.origin.y;
    if (self.inputAccessoryView && keyboardOverlap>0) {
        CGFloat accessoryHeight = self.inputAccessoryView.frame.size.height;
        keyboardOverlap -= accessoryHeight;
        
        tableView.contentInset = UIEdgeInsetsMake(0, 0, accessoryHeight, 0);
        tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, accessoryHeight, 0);
    }
    
    if (keyboardOverlap < 0) {
        keyboardOverlap = 0;
    }
    
    if (keyboardOverlap != 0) {
        tableFrame.size.height -= keyboardOverlap;
        
        NSTimeInterval delay = 0;
        if(keyboardRect.size.height)
        {
            delay = (1 - keyboardOverlap/keyboardRect.size.height)*animationDuration;
            animationDuration = animationDuration * keyboardOverlap/keyboardRect.size.height;
        }
        
        [UIView animateWithDuration:animationDuration delay:delay
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{ tableView.frame = tableFrame; }
                         completion:^(BOOL finished){}];
    }
}

- (void)keyboardWillHide:(NSNotification *)aNotification
{
    if (!keyboardShown) return;
    
    keyboardShown = NO;
    
    UIScrollView *tableView;
    if ([self.tableView.superview isKindOfClass:[UIScrollView class]]) {
        tableView = (UIScrollView *)self.tableView.superview;
    } else {
        tableView = self.tableView;
    }
    
    if (self.inputAccessoryView) {
        tableView.contentInset = UIEdgeInsetsZero;
        tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
    }
    
    if (keyboardOverlap == 0) return;
    
    // Get the size & animation details of the keyboard
    NSDictionary *userInfo = [aNotification userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [tableView.superview convertRect:[aValue CGRectValue] fromView:nil];
    
    NSTimeInterval animationDuration;
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    UIViewAnimationCurve animationCurve;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    
    CGRect tableFrame = tableView.frame;
    tableFrame.size.height += keyboardOverlap;
    
    if(keyboardRect.size.height) {
        animationDuration = animationDuration * keyboardOverlap/keyboardRect.size.height;
    }
    
    [UIView animateWithDuration:animationDuration delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{ tableView.frame = tableFrame; }
                     completion:nil];
}

#pragma mark - Action

- (IBAction)doneButtonTapped:(id)sender {
    if (_deleagte && [_deleagte respondsToSelector:@selector(inviteGroupDidSelectGroups:)]) {
        [_deleagte inviteGroupDidSelectGroups:_listGroup];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)backButtonTapped:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Send request

- (void)searchGroupWithKey:(NSString *)key
{
    
    if (post) {
        [post cancel];
        post = nil;
    }
    __typeof (self) __weak pSelf = self;
    
    if ([ECommon isStringEmpty:key]) {
        [_tableData removeAllObjects];
        displaySelectedGroup = YES;
        _noResultLabel.hidden = YES;
        [_tableView reloadData];
        self.tableView.showsInfiniteScrolling = NO;
        _lastSearchKeyword = key;
        [[SDImageCache sharedImageCache] clearMemory];
        return;
    }
    
    if (![ECommon isNetworkAvailable]) return;
    
    // Stop request when reach greater total page
    if(_pageNumber > _totalPage) {
        [self.tableView.infiniteScrollingView stopAnimating];
        self.tableView.showsInfiniteScrolling = NO;
        
        if (![key isEqualToString:_lastSearchKeyword]) {
            _pageNumber = 0;
            _totalPage = 1;
            [_tableData removeAllObjects];
            [_tableView reloadData];
        }
        return;
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:[[EUserData getInstance] objectForKey:AUTH_TOKEN_UD_KEY] forHTTPHeaderField:@"auth-token"];
    
    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kAPIBaseUrl, kAPISearchGroupPath];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:key forKey:@"name"];
    [params setValue:[NSNumber numberWithInteger:_pageNumber] forKey:@"page"];
    
    isLoading = YES;
    post = [manager POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        isLoading = NO;
        [[SDImageCache sharedImageCache] clearMemory];
        NSString *status = [responseObject valueForKey:kAPIResponseStatus];
        if ([status isEqualToString:kAPIResponseStatusSuccess]) {
            NSDictionary *data = [responseObject valueForKey:kAPIResponseData];
            NSArray *list = [data valueForKey:@"list"];
            
            displaySelectedGroup = NO;
            //__typeof (pSelf) __strong mySelf = pSelf;
            NSDictionary *paginateDict = [data valueForKey:@"paginate"];
            _totalPage  = [[paginateDict valueForKey:@"totalPage"] integerValue];
            _pageNumber = [[paginateDict valueForKey:@"currentPage"] integerValue];
            if (_pageNumber < _totalPage) {
                _tableView.showsInfiniteScrolling = YES;
                
            } else {

                _tableView.showsInfiniteScrolling = NO;
            }
            
            _pageNumber++;
            
            if (![key isEqualToString:_lastSearchKeyword]) {
                _pageNumber = 0;
                _totalPage = 1;
                [_tableData removeAllObjects];
                [_tableView reloadData];
            }
            
            if (list && list.count > 0) {
                //NSInteger currentRow = [_tableData count];
                for(NSDictionary *groupDict in list) {
                    NSInteger idValue = [[groupDict objectForKey:@"id"] integerValue];
                    BOOL isExisted = FALSE;
                    for(NSDictionary *groupDict2 in _tableData) {
                        NSInteger idValue2 = [[groupDict2 objectForKey:@"id"] integerValue];
                        if(idValue == idValue2) {
                            isExisted = TRUE;
                            break;
                        }
                    }
                    if(!isExisted) {
                        [_tableData addObject:groupDict];
                    }
                }
                //[_tableData addObjectsFromArray:list];
                _noResultLabel.hidden = YES;
                //[self reloadTableView:currentRow];
                [_tableView reloadData];
                [pSelf.tableView.infiniteScrollingView stopAnimating];
            } else {
                
                if([_tableData count] <= 0) {
                    _noResultLabel.hidden = NO;
                }
            }
            
        } else {
            if([EJSONHelper valueFromData:[responseObject objectForKey:kAPIResponseCode]]) {
                NSInteger codeStatus = [[responseObject objectForKey:kAPIResponseCode] integerValue];
                if(codeStatus == kAPI403ErrorCode) {
                    [[QUIHelper getInstance] showAlertLogoutMessage];
                }
                else if([EJSONHelper valueFromData:[responseObject objectForKey:kAPIResponseMessage]]) {
                    [[QUIHelper getInstance] showAlertWithMessage:[responseObject valueForKey:kAPIResponseMessage]];
                }
            }
            else if([EJSONHelper valueFromData:[responseObject objectForKey:kAPIResponseMessage]]) {
                [[QUIHelper getInstance] showAlertWithMessage:[responseObject valueForKey:kAPIResponseMessage]];
            }
        }
        _lastSearchKeyword = key;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        [[SDImageCache sharedImageCache] clearMemory];
        isLoading = NO;
        DLog_Error(@"Error: %@", error);
        _lastSearchKeyword = key;
    }];
}

- (void)reloadTableView:(NSInteger)startingRow;
{
    // the last row after added new items
    NSInteger endingRow = [_tableData count];
    
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (; startingRow < endingRow; startingRow++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:startingRow inSection:0]];
    }
    
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    _pageNumber = 1;
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (newString.length > 0) {
        _numberLabel.hidden = YES;
    } else {
        _numberLabel.hidden = NO;
    }
    
    [self searchGroupWithKey:newString];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.view endEditing:YES];
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    if (post) {
        [post cancel];
        post = nil;
    }
    
    self.tableView.showsInfiniteScrolling = NO;
    displaySelectedGroup = YES;
    _noResultLabel.hidden = YES;
    [_tableData removeAllObjects];
    [_tableView reloadData];
    _numberLabel.text = [NSString stringWithFormat:@"%lu/%d", (unsigned long)_listGroup.count, kMaxInvitingGroupNumber];
    _numberLabel.hidden = NO;
    _lastSearchKeyword = @"";
    [[SDImageCache sharedImageCache] clearMemory];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    _numberLabel.hidden = NO;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField.text.length > 0) {
        _numberLabel.hidden = YES;
    } else {
        _numberLabel.hidden = NO;
    }
    [[SDImageCache sharedImageCache] clearMemory];
    return YES;
}

#pragma mark - UITableViewDelegate, UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65.0f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (displaySelectedGroup) {
        return _listGroup.count;
    }
    return [_tableData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"inviteGroupCell";
    
    EInviteGroupCell *cell = (EInviteGroupCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[EInviteGroupCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *selectedDict = nil;
    if (displaySelectedGroup) {
        selectedDict = [_listGroup objectAtIndex:indexPath.row];
        [cell loadDataWithDict:selectedDict];
    } else {
        selectedDict = [_tableData objectAtIndex:indexPath.row];
        [cell loadDataWithDict:selectedDict andSearchedKey:_seachBar.text];
    }
    cell.delegate = self;
    
    BOOL isFound = NO;
    for (NSDictionary *dict in _listGroup) {
        if ([[selectedDict valueForKey:@"id"] integerValue] == [[dict valueForKey:@"id"] integerValue]) {
            isFound = YES;
            break;
        }
    }
    if (isFound) {
        [cell.selectButton setImage:[UIImage imageNamed:@"member_contest_enable.png"] forState:UIControlStateNormal];
        cell.isSelected = YES;
    } else {
        [cell.selectButton setImage:[UIImage imageNamed:@"member_contest.png"] forState:UIControlStateNormal];
        cell.isSelected = NO;
    }
    
    if (_listGroup.count >= kMaxInvitingGroupNumber) {
        cell.isAbleToSelect = NO;
    } else {
        cell.isAbleToSelect = YES;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.view endEditing:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    EInviteGroupCell *cell = (EInviteGroupCell *)[tableView cellForRowAtIndexPath:indexPath];
    [cell selectButtonTapped:nil];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
}

- (void)dealloc {
    
    [[SDImageCache sharedImageCache] clearMemory];
    
}

#pragma mark - EInviteGroupCellDelegate

- (void)inviteGroupCellDidSelect:(NSDictionary *)dict isSelected:(BOOL)isSelected
{
    if (isSelected) {
        [_listGroup addObject:dict];
        [_tableView reloadData];
    } else {
        for (NSDictionary *d in _listGroup) {
            if ([[d valueForKey:@"id"] integerValue] == [[dict valueForKey:@"id"] integerValue]) {
                [_listGroup removeObject:dict];
                [_tableView reloadData];
                break;
            }
        }
    }
    _numberLabel.text = [NSString stringWithFormat:@"%lu/%d", (unsigned long)_listGroup.count, kMaxInvitingGroupNumber];
    
    // Show/hide done button
    if([_listGroup count] > 1) {
        self.doneButton.hidden = NO;
    }
    else {
        self.doneButton.hidden = YES;
    }
}

#pragma mark - UIStatusBar

//- (UIStatusBarStyle)preferredStatusBarStyle {
//    return UIStatusBarStyleLightContent;
//}

@end
