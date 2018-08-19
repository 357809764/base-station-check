//
//  RandAlertView.h
//  VPNDemo
//
//  Created by sangfor on 2017/8/25.
//  Copyright © 2017年 sangfor. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RandAlertView : UIView

typedef void(^AlertResult)(NSString *rand);
typedef void(^imageAction)(void);

@property (nonatomic,copy) AlertResult alerResult;

@property (nonatomic,copy) imageAction imageAction;

- (id)initWithTitle:(NSString *)title message:(NSString *)message;

- (void)showRandAlertView;

- (void)setRandImage:(UIImage *)image;
@end
