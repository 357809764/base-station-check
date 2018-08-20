//
//  AuthTableViewCell.h
//  VPNDemo
//
//  Created by sangfor on 2017/8/24.
//  Copyright © 2017年 sangfor. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AuthTableViewCell : UITableViewCell

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) NSString *cellText;
@property (nonatomic, copy) NSString *placeholder;
-(void)setTextSecurity:(BOOL)security;
@end
