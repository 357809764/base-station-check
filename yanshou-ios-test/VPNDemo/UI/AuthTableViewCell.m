//
//  AuthTableViewCell.m
//  VPNDemo
//
//  Created by sangfor on 2017/8/24.
//  Copyright © 2017年 sangfor. All rights reserved.
//

#import "AuthTableViewCell.h"
#import "SDAutoLayout.h"

@interface AuthTableViewCell ()

///图标视图
@property (nonatomic, strong) UIImageView   *logoView;
///输入视图
@property (nonatomic, strong) UITextField   *inputView;

@end

@implementation AuthTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        [self initSubviews];
    }
    
    return self;
}

///设置输入框是否需要加密
-(void)setTextSecurity:(BOOL)security
{
    if (security) {
        _inputView.secureTextEntry = YES;
    } else {
        _inputView.secureTextEntry = NO;
    }
}

/**
 初始化子视图
 */
- (void)initSubviews
{
    //添加logo
    [self setupLogoView];
    
    //添加输入栏
    [self setupInputView];
    
    //添加边框
    [self setupBorder];
}


///添加logo视图
- (void)setupLogoView
{
    //创建
    self.logoView = [UIImageView new];
    _logoView.contentMode = UIViewContentModeCenter;
    [self.contentView addSubview:_logoView];
    
    //设置frame
    _logoView.sd_layout
    .widthIs(self.contentView.height)
    .heightEqualToWidth();
}

///添加输入视图
- (void)setupInputView
{
    //创建
    self.inputView = [UITextField new];
    _inputView.textColor = [UIColor blackColor];
    _inputView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _inputView.clearButtonMode = UITextFieldViewModeWhileEditing;
    _inputView.autocorrectionType = UITextAutocorrectionTypeNo;
    [self.contentView addSubview:_inputView];
    
    //设置frame
    _inputView.sd_layout
    .leftSpaceToView(_logoView, 0)
    .centerYEqualToView(self.contentView)
    .rightSpaceToView(self.contentView, 0)
    .heightRatioToView(self.contentView, 1);
    //self.inputView.frame = CGRectMake(self.logoView.width, 0, self.contentView.width - self.logoView.width, self.contentView.height);
}

///添加边框
- (void)setupBorder
{
    self.layer.borderWidth = 1;
    self.layer.masksToBounds = YES;
    self.layer.borderColor = [UIColor colorWithRed:106.0/255 green:149.0/255 blue:179.0/255 alpha:1].CGColor;
}

///设置logo
- (void)setImage:(UIImage *)image {
    _logoView.image = image;
    _logoView.contentMode = UIViewContentModeCenter;
}

///设置文本内容
- (void)setCellText:(NSString *)cellText {
    _inputView.text = cellText;
}

///获取文本内容
- (NSString *)cellText {
    return _inputView.text;
}

///设置提示框内容
- (void)setPlaceholder:(NSString *)placeholder {
    _inputView.placeholder = placeholder;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}
@end
