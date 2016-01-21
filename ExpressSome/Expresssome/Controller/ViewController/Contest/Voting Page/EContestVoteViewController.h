//
//  EContestVoteViewController.h
//  Expressome
//
//  Created by Mr Lazy on 7/14/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EContestVoteViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *screenTitleLabel;
//@property (weak, nonatomic) IBOutlet UIView *popupView;
// Popup used for alert when leave screen.
@property (weak, nonatomic) IBOutlet UIView *popupView2;
@property (weak, nonatomic) IBOutlet UIButton *stickButton;
@property (weak, nonatomic) IBOutlet UIButton *stickButton2;
@property (weak, nonatomic) IBOutlet UIButton *chatButton;
@property (strong, nonatomic) NSDictionary *contestInfo;
@property (weak, nonatomic) IBOutlet UIButton *btnBack;
@property (assign, nonatomic) NSInteger contestType;
@property (assign, nonatomic) BOOL openFromPush;


@end
