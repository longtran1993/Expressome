#import "QAlertView.h"
#import <QuartzCore/QuartzCore.h>


#define kOkButtonTag 0
#define kCancelButtonTag 1

@interface QAlertView() {
    
}
@end

@implementation QAlertView

- (id)initWithFrame:(CGRect)frame nibName:(NSString*)nibName
{
    self = [super initWithFrame:frame];
    if (self)
    {
    }
    return self;
}

+ (QAlertView *)initWithMessage:(NSString *)message delegate:(id<QAlertViewDelegate>)delegate okButtonTitle:(NSString *)okButtonTitle cancelButtonTitle:(NSString *) cancelButtonTitle {
    QAlertView *alertView = (QAlertView *)[[[NSBundle mainBundle] loadNibNamed:@"QAlertView" owner:self options:nil]objectAtIndex:0];
    // Set title & text for elements
    alertView.messageLabel.text = message;
    [alertView.okButton setTitle:okButtonTitle forState:UIControlStateNormal];
    [alertView.cancelButton setTitle:cancelButtonTitle forState:UIControlStateNormal];
    
    // Set tag for buttons
    alertView.okButton.tag = kOkButtonTag;
    alertView.cancelButton.tag = kCancelButtonTag;
    
    // Set delegate
    alertView.delegate = delegate;
    
    // Add target for buttons
    [alertView.okButton addTarget:alertView action:@selector(buttonHasTapped:) forControlEvents:UIControlEventTouchUpInside];
    [alertView.cancelButton addTarget:alertView action:@selector(buttonHasTapped:) forControlEvents:UIControlEventTouchUpInside];
    return alertView;
}

- (void)buttonHasTapped:(id)sender {
    if(_delegate && [_delegate respondsToSelector:@selector(alertView:clickedButtonAtIndex:)]) {
        [_delegate alertView:self clickedButtonAtIndex:((UIButton *)sender).tag];
    }
}

- (void)show {
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    self.hidden = YES;
    [UIView animateWithDuration:0.5f animations:^{
        self.hidden = NO;
    } completion:nil];
}

- (void)dismiss {
    [UIView animateWithDuration:0.5f animations:^{
        self.hidden = YES;
    } completion:^(BOOL finished) {
        if(finished) {
            [self removeFromSuperview];
        }
    }];
}
@end
