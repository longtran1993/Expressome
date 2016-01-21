//
//  OKAlert.m
//  Expressome
//
//  Created by Staff on 10/6/15.
//  Copyright (c) 2015 Quan DT. All rights reserved.
//

#import "OKAlert.h"

@implementation OKAlert

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (instancetype)initWithDelegate:(id<OKAlertDelegate>) dlg {
    
    // Load the top-level objects from the custom cell XIB.
    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"OKAlert" owner:self options:nil];
    //    // Grab a pointer to the first object (presumably the custom cell, as that's all the XIB should contain).
    OKAlert *okView = [topLevelObjects objectAtIndex:0];
    okView.delegate = dlg;
    okView.cView.layer.cornerRadius = 5;
    _cView.alpha = 1.0;
    _cView.opaque = YES;
    
    return okView;
}

- (void)showInView:(UIView *)parentView {
    
    _cView.alpha = 1.0;
    _cView.opaque = YES;
    
    [parentView addSubview: self];
    [parentView bringSubviewToFront: self];
}

- (void)dismiss {
    
    [self removeFromSuperview];
    
}
- (IBAction)ibaOKTapped:(id)sender {
    
    [self removeFromSuperview];
    
    if(_delegate && [_delegate respondsToSelector: @selector( userDidTappedOK)]) {
        
        [_delegate userDidTappedOK];
    }
    
    
}

@end
