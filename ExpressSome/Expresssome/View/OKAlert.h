//
//  OKAlert.h
//  Expressome
//
//  Created by Staff on 10/6/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OKAlertDelegate <NSObject>

- (void)userDidTappedOK;

@end

@interface OKAlert : UIView

@property (nonatomic, weak) id<OKAlertDelegate> delegate;

@property (nonatomic, weak) IBOutlet UIView *cView;
@property (nonatomic, weak) IBOutlet UILabel *lblMessage;

- (instancetype)initWithDelegate:(id<OKAlertDelegate>) dlg;

- (void)showInView:(UIView *)parentView;
- (void)dismiss;


@end
