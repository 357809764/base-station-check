
//
//  RandAlertView.m
//  VPNDemo
//
//  Created by sangfor on 2017/8/25.
//  Copyright © 2017年 sangfor. All rights reserved.
//

#import "RandAlertView.h"
#import "SDAutoLayout.h"

#define UIColorFromRGBValue(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface RandAlertView()
///提示框视图
@property (nonatomic,retain)   UIView       *alertView;

///输入框视图
@property (nonatomic, strong)  UITextField  *textField;

///随机图视图
@property (nonatomic, strong)  UIImageView  *randImgView;

///确认按钮视图
@property (nonatomic, strong)  UIButton     *confirmButton;

///标题视图
@property (nonatomic, strong)  UILabel      *titleLabel;

@end

@implementation RandAlertView

- (id)initWithTitle:(NSString *)title message:(NSString *)message
{
    self = [super init];
    
    if (self) {
        self.frame = [UIScreen mainScreen].bounds;
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];

        [self initSubViews];
    }
    
    return self;
}

#pragma mark - UI View
///初始化视图
- (void)initSubViews
{
    //设置提示框视图
    [self setupAlertView];
    
    //设置标题视图
    [self setupTitleView];
    
    //设置输入框视图
    [self setupInputView];

    //设置图形校验码视图
    [self setupRndImageView];

    //设置确认按钮视图
    [self setupConfirmButton];

    //设置取消按钮视图
    [self setupCancelButton];

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
    .heightIs(165);
}

///设置标题视图
- (void)setupTitleView
{
    self.titleLabel = [UILabel new];
    _titleLabel.font = [UIFont systemFontOfSize:18];
    _titleLabel.textColor = [UIColor darkTextColor];
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.text = @"图形校验码认证";
    [_alertView addSubview:_titleLabel];
    
    _titleLabel.sd_layout
    .centerXEqualToView(_alertView)
    .topSpaceToView(_alertView, 15)
    .widthRatioToView(_alertView, 0.8)
    .heightIs(20);
}

///设置输入视图
- (void)setupInputView
{
    self.textField = [UITextField new];
    _textField.placeholder = @"点击图片重新获取";
    _textField.autocorrectionType = UITextAutocorrectionTypeNo;
    [_textField setBorderStyle:UITextBorderStyleRoundedRect];
    [_textField setTextAlignment:NSTextAlignmentLeft];
    [_alertView addSubview:_textField];
    
    _textField.sd_layout
    .leftSpaceToView(_alertView, 10)
    .widthRatioToView(_alertView, 0.55)
    .heightIs(40)
    .topSpaceToView(_titleLabel, 20);
}

///设置图形校验码视图
- (void)setupRndImageView
{
    self.randImgView = [UIImageView new];
    _randImgView.contentMode = UIViewContentModeScaleToFill;
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewAction)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    _randImgView.userInteractionEnabled = YES;
    [_randImgView addGestureRecognizer:tapGestureRecognizer];
    [_alertView addSubview:_randImgView];
    
    _randImgView.sd_layout
    .rightSpaceToView(_alertView, 10)
    .widthRatioToView(_alertView, 0.3)
    .heightIs(40)
    .centerYEqualToView(_textField);
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
    .bottomSpaceToView(_alertView, 0)
    .leftEqualToView(_alertView)
    .widthRatioToView(_alertView, 0.5)
    .heightIs(40);
}

///设置取消按钮视图
- (void)setupCancelButton
{
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    [cancelBtn setTitleColor:UIColorFromRGBValue(0x157efa) forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
    [_alertView addSubview:cancelBtn];
    
    cancelBtn.sd_layout
    .topEqualToView(_confirmButton)
    .rightEqualToView(_alertView)
    .widthRatioToView(_alertView, 0.5)
    .heightRatioToView(_confirmButton, 1);
}

///设置分割线视图
- (void)setupSplitLineView
{
    UILabel *label1 = [UILabel new];
    label1.layer.borderWidth = 1;
    label1.layer.borderColor = [UIColor colorWithRed:217/255.0 green:217/255.0 blue:217/255.0 alpha:1.0].CGColor;
    [_alertView addSubview:label1];
    label1.sd_layout
    .centerXEqualToView(_alertView)
    .widthIs(1)
    .heightRatioToView(_confirmButton, 1)
    .topEqualToView(_confirmButton);
    
    UILabel *label2 = [UILabel new];
    label2.layer.borderWidth = 1;
    label2.layer.borderColor = [UIColor colorWithRed:217/255.0 green:217/255.0 blue:217/255.0 alpha:1.0].CGColor;
    [_alertView addSubview:label2];
    label2.sd_layout
    .centerXEqualToView(_alertView)
    .widthRatioToView(_alertView, 1)
    .heightIs(1)
    .bottomSpaceToView(_confirmButton, 1);
}

#pragma mark - Action
///取消事件
- (void)cancelAction:(id)sender
{
    [self removeFromSuperview];
    _textField.text = @"";
}

///确认事件
- (void)confirmAction:(id)sender
{
    if (self.alerResult) {
        self.alerResult(_textField.text);
    }
    
    [self removeFromSuperview];
    _textField.text = @"";
}

///校验码点击事件
- (void)imageViewAction
{
    if (self.imageAction) {
        self.imageAction();
    }
}

#pragma mark - 视图显示
- (void)showRandAlertView
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

- (void)setRandImage:(UIImage *)image
{
    if (image) {
        _randImgView.image = image;
    }
}
@end
