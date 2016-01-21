//
//  EGroupMemberViewController.h
//  Expresssome
//
//  Created by Thai Nguyen on 5/29/15.
//  Copyright (c) 2015 Thai Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EGroupMemberViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (strong, nonatomic) NSMutableArray *listMember;
@property (strong, nonatomic) NSDictionary *groupInfo;
@property (strong, nonatomic) NSDictionary *contestInfo;
@property (assign, nonatomic) BOOL isContestMember;

@end
