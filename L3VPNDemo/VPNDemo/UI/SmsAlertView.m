//
//  SmsAlertView.m
//  VPNDemo
//
//  Created by sangfor on 2017/9/5.
//  Copyright © 2017年 sangfor. All rights reserved.
//

#import "SmsAlertView.h"
#import "SDAutoLayout.h"

#define UIColorFromRGBValue(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface SmsAlertView()

///提示框视图
@property (nonatomic,retain)   UIView       *alertView;

///信息视图
@property (nonatomic, strong)  UILabel      *messageLabel;

///输入框视图
@property (nonatomic, strong)  UITextField  *textField;

///确认按钮视图
@property (nonatomic, strong)  UIButton     *confirmButton;

///取消按钮视图
@property (nonatomic, strong) UIButton      *cancelButton;

///重新获取短信校验码视图
@property (nonatomic, strong)  UIButton     *reacquireButton;

///标题视图
@property (nonatomic, strong)  UILabel      *titleLabel;

///信息
@property (nonatomic, strong)  NSString     *message;

///计时器
@property (nonatomic, strong)  NSTimer      *timer;

@end

@implementation SmsAlertView

- (id)initWithMessage:(NSString *)message
{
    self = [super init];
    
    if (self) {
        self.frame = [UIScreen mainScreen].bounds;
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
        _message = message;
        [self initSubViews];
    }
    
    return self;
}

#pragma mark - UI View

///初始化子视图
- (void)initSubViews
{
    //设置提示框视图
    [self setupAlertView];
    
    //设置标题视图
    [self setupTitleView];
    
    //设置信息视图
    [self setupMessageView];
    
    //设置输入视图
    [self setupInputView];
    
    //设置取消按钮视图
    [self setupCancelButton];
    
    //设置确认按钮视图
    [self setupConfirmButton];
    
    //设置重新获取短信按钮视图
    [self setupRequireButton];

    //设置分割线视图
    [self setupSplitLineView];
}

///设置提示框视图
- (void)setupAlertView
{
    self.alertView = [[UIView alloc] init];
    _alertView.backgroundColor = [UIColor whiteColor];
    _alertView.layer.cornerRadius = 15.0;
    [self addSubview:_alertView];

    _alertView.sd_layout
    .centerXEqualToView(self)
    .centerYIs(0.4 * self.height)
    .widthIs(280)
    .heightIs(240);
}

///设置标题视图
- (void)setupTitleView
{
    self.titleLabel = [UILabel new];
    _titleLabel.text = @"短信认证";
    _titleLabel.font = [UIFont systemFontOfSize:18];
    _titleLabel.textColor = [UIColor darkTextColor];
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    [_alertView addSubview:_titleLabel];

    _titleLabel.sd_layout
    .centerXEqualToView(_alertView)
    .topSpaceToView(_alertView, 15)
    .widthRatioToView(_alertView, 0.8)
    .heightIs(20);
}

///设置信息视图
- (void)setupMessageView
{
    self.messageLabel = [UILabel new];
    _messageLabel.text = _message;
    _messageLabel.textAlignment = NSTextAlignmentCenter;
    _messageLabel.font = [UIFont systemFontOfSize:13];
    _messageLabel.textColor = [UIColor darkTextColor];
    [_alertView addSubview:_messageLabel];
    
    _messageLabel.sd_layout
    .centerXEqualToView(_alertView)
    .widthRatioToView(_alertView, 0.9)
    .heightIs(20)
    .topSpaceToView(_titleLabel, 10);
}

///设置输入视图
- (void)setupInputView
{
    self.textField = [UITextField new];
    _textField.placeholder = @"验证码";
    [_textField setBorderStyle:UITextBorderStyleRoundedRect];
    [_textField setTextAlignment:NSTextAlignmentLeft];
    _textField.autocorrectionType = UITextAutocorrectionTypeNo;
    [_alertView addSubview:_textField];
    
    _textField.sd_layout
    .centerXEqualToView(_alertView)
    .widthRatioToView(_messageLabel, 0.8)
    .heightIs(30)
    .topSpaceToView(_messageLabel, 10);
}

///设置确认按钮视图
- (void)setupConfirmButton
{
    self.confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_confirmButton setTitle:@"确定" forState:UIControlStateNormal];
    [_confirmButton setTitleColor:UIColorFromRGBValue(0x157efa) forState:UIControlStateNormal];
    [_confirmButton addTarget:self action:@selector(confirmAction:) forControlEvents:UIControlEventTouchUpInside];
    [_alertView addSubview:_confirmButton];
    
    _confirmButton.sd_layout
    .bottomSpaceToView(_cancelButton, 1)
    .centerXEqualToView(_alertView)
    .widthRatioToView(_alertView, 0.7)
    .heightIs(40);
}

///设置取消按钮视图
- (void)setupCancelButton
{
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [_cancelButton setTitleColor:UIColorFromRGBValue(0x157efa) forState:UIControlStateNormal];
    [_cancelButton addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
    [_alertView addSubview:_cancelButton];

    _cancelButton.sd_layout
    .bottomSpaceToView(_alertView, 0)
    .centerXEqualToView(_alertView)
    .widthRatioToView(_alertView, 0.5)
    .heightIs(40);
}

///设置重新获取短信按钮视图
- (void)setupRequireButton
{
    self.reacquireButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_reacquireButton setTitle:@"重新获取" forState:UIControlStateNormal];
    [_reacquireButton setTitleColor:UIColorFromRGBValue(0x157efa) forState:UIControlStateNormal];
    [_reacquireButton addTarget:self action:@selector(reacquireAction:) forControlEvents:UIControlEventTouchUpInside];
    [_alertView addSubview:_reacquireButton];

    _reacquireButton.sd_layout
    .bottomSpaceToView(_confirmButton, 1)
    .centerXEqualToView(_alertView)
    .widthRatioToView(_alertView, 0.7)
    .heightIs(40);
}

///设置分割线视图
- (void)setupSplitLineView
{
    UILabel *label0 = [UILabel new];
    label0.layer.borderWidth = 1;
    label0.layer.borderColor = [UIColor colorWithRed:217/255.0 green:217/255.0 blue:217/255.0 alpha:1.0].CGColor;
    [_alertView addSubview:label0];
    label0.sd_layout
    .bottomSpaceToView(_reacquireButton, 0)
    .widthRatioToView(_alertView, 1)
    .heightIs(1);
    
    UILabel *label1 = [UILabel new];
    label1.layer.borderWidth = 1;
    label1.layer.borderColor = [UIColor colorWithRed:217/255.0 green:217/255.0 blue:217/255.0 alpha:1.0].CGColor;
    [_alertView addSubview:label1];
    label1.sd_layout
    .bottomSpaceToView(_confirmButton, 0)
    .widthRatioToView(_alertView, 1)
    .heightIs(1);
    
    UILabel *label2 = [UILabel new];
    label2.layer.borderWidth = 1;
    label2.layer.borderColor = [UIColor colorWithRed:217/255.0 green:217/255.0 blue:217/255.0 alpha:1.0].CGColor;
    [_alertView addSubview:label2];
    label2.sd_layout
    .bottomSpaceToView(_cancelButton, 0)
    .widthRatioToView(_alertView, 1)
    .heightIs(1);
}

#pragma mark - property

- (void)setButtonTitle:(NSString *)title
{
    [_reacquireButton setTitle:title forState:UIControlStateNormal];
}

- (void)setButtonEnable:(BOOL)enable
{
    [_reacquireButton setEnabled:enable];
    if (enable) {
        [_reacquireButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    } else {
        [_reacquireButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];

    }
}

static int mTime = 0;
- (void)startTimer:(int)time
{
    [self setButtonEnable:NO];
    mTime = time;
    if (!_timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(doTimerAction) userInfo:nil repeats:YES];
    }
}

- (void)doTimerAction
{
    [_reacquireButton setTitle:[NSString stringWithFormat:@"倒计时:%d",mTime--] forState:UIControlStateNormal];
    if (mTime == 0) {
        [self setButtonEnable:YES];
        [self setButtonTitle:@"重新发送验证码"];
        [_timer invalidate];
        self.timer = nil;
    }
}

- (void)showSmsAlertView
{
    UIWindow *rootWindow = [UIApplication sharedApplication].keyWindow;
    [rootWindow addSubview:self];
    [self creatShowAnimation];
}

- (void)creatShowAnimation
{
    self.alertView.layer.position = self.center;
    self.alertView.transform = CGAffineTransformMakeScale(0.90, 0.90);
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:1 options:UIViewAnimationOptionCurveLinear animations:^{
        self.alertView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    } completion:^(BOOL finished) {
        [_textField becomeFirstResponder];
    }];
}

#pragma mark - Action

- (void)cancelAction:(id)sender
{
    [self removeFromSuperview];
    _textField.text = @"";
    
    if (_timer && [_timer isValid]) {
        [_timer invalidate];
        self.timer = nil;
    }
}

- (void)confirmAction:(id)sender
{
    if (self.alerResult) {
        self.alerResult(_textField.text);
    }
    
    [self removeFromSuperview];
    _textField.text = @"";
    if (_timer && [_timer isValid]) {
        [_timer invalidate];
        self.timer = nil;
    }
}

- (void)reacquireAction:(id)sender
{
    if (self.reacquireCode) {
        self.reacquireCode();
    }
}
@end
