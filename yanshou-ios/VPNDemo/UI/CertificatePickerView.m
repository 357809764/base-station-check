//
//  CertificatePickerView.m
//  aWork
//
//  Created by fgg on 2017/2/16.
//  Copyright © 2017年 sangfor. All rights reserved.
//

#import "CertificatePickerView.h"
#import "Common.h"
@interface CertificatePickerView ()

@property (nonatomic, strong) UIButton *certPickBtn;    //证书选择按钮

@end

@implementation CertificatePickerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupCustomUI];
    }
    
    return self;
}

///设置证书选择器的UI
- (void)setupCustomUI {    
    _certPickBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.contentView addSubview:_certPickBtn];
    _certPickBtn.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_certPickBtn setTitle:NSLocalizedString(@"select_cert",@"选择登录凭证") forState:UIControlStateNormal];
    _certPickBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [_certPickBtn addTarget:self action:@selector(btnPressed:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - event
///点击“选择证书按钮”响应事件
- (void)btnPressed:(id)sender {
    if (self.indicatorBlock) {
        self.indicatorBlock();
    }
}

///设置点击事件，对外接口
- (void)setClickBlock:(CertificatePickerViewClickBlock)clickBlock {
    _clickBlock = clickBlock;
    self.indicatorBlock = clickBlock;
}

///设置显示的证书名字
- (void)setCertificate:(NSString *)certificate {
    [_certPickBtn setTitle:certificate forState:UIControlStateNormal];
}

///获取证书
- (NSString *)certificate {
    return _certPickBtn.titleLabel.text;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
