//
//  SmsAlertView.h
//  VPNDemo
//
//  Created by sangfor on 2017/9/5.
//  Copyright © 2017年 sangfor. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SmsAlertView : UIView

typedef void(^AlertResult)(NSString *code);

typedef void(^ReacquireCode)(void);

@property (nonatomic,copy) AlertResult alerResult;

@property (nonatomic,copy) ReacquireCode reacquireCode;

- (void)showSmsAlertView;

- (id)initWithMessage:(NSString *)message;

- (void)setButtonTitle:(NSString *)title;

- (void)setButtonEnable:(BOOL)enable;

- (void)startTimer:(int)time;

@end
