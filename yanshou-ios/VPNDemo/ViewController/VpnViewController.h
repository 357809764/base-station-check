//
//  VpnViewController.h
//  VPNDemo
//
//  Created by Yuanliang Fu on 2018/8/26.
//  Copyright © 2018年 sangfor. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VpnViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *setView;
@property (weak, nonatomic) IBOutlet UITextField *ipTextField;
@property (weak, nonatomic) IBOutlet UITextField *userTextField;
@property (weak, nonatomic) IBOutlet UITextField *pswTextField;

@property (strong, atomic) NSString *vpnIp;
@property (strong, atomic) NSString *userName;
@property (strong, atomic) NSString *password;

@end
