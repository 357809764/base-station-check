//
//  CertificatePickerView.h
//  aWork
//
//  Created by fgg on 2017/2/16.
//  Copyright © 2017年 sangfor. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void (^CertificatePickerViewClickBlock)();

@interface CertificatePickerView : UIView

@property (nonatomic, copy) CertificatePickerViewClickBlock clickBlock; //证书选择按钮的回调
@property (nonatomic, copy) NSString *certificate;      //显示的证书名

@end
