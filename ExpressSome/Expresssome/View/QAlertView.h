#import <UIKit/UIKit.h>

@class QAlertView;
@protocol QAlertViewDelegate  <NSObject>

- (void)alertView:(QAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

@end

@interface QAlertView : UIView

@property (strong, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic) IBOutlet UIButton *okButton;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) id<QAlertViewDelegate> delegate;

+(QAlertView *)initWithMessage:(NSString *)message delegate:(id<QAlertViewDelegate>)delegate okButtonTitle:(NSString *)okButtonTitle cancelButtonTitle:(NSString *) cancelButtonTitle;
-(void)show;
-(void)dismiss;
@end
