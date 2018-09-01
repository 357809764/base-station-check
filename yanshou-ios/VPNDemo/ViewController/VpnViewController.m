//
//  VpnViewController.m
//  VPNDemo
//
//  Created by Yuanliang Fu on 2018/8/26.
//  Copyright © 2018年 sangfor. All rights reserved.
//

#import "VpnViewController.h"
#import "DLRadioButton.h"
#import "SDAutoLayout.h"
#import "AuthTableViewCell.h"
#import "SangforAuthManager.h"
#import "RandAlertView.h"
#import "NetworkViewController.h"
#import "MBProgressHUD.h"
#import "SmsAlertView.h"
#import "errheader.h"
#import <sys/utsname.h>

#define kVpnIp      @"vpnIp"       //VPN地址
#define kPort       @"vpnport"     //VPN端口号
#define kUser       @"vpnuser"     //VPN用户名
#define kPsw        @"vpnpsw"       //VPN密码
#define kVpnModel   @"vpnModel"     //VPN模式

@interface VpnViewController ()<UITableViewDelegate,UITableViewDataSource,SangforAuthDelegate>

///背景图
@property (nonatomic, strong)   UIImageView             *backgroundView;        //背景


//VPN登录
///单例的authManager
@property (nonatomic, retain)   SangforAuthManager      *sdkManager;
///VPN模式
@property (nonatomic, assign)   VPNMode                 mode;
///认证类型
@property (nonatomic, assign)   VPNAuthType             authType;

//图形校验码认证
///图形校验码视图
@property (nonatomic, strong)   RandAlertView           *randView;

//网络视图
///网络请求的ViewController
@property (nonatomic, strong)   NetworkViewController   *networkController;

@end

@implementation VpnViewController

#pragma mark - 生命周期
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    //初始化Sdk信息
    [self initSangforSdk];
    
    //创建点击收起键盘事件
    [self initViewTapAction];
    
    //获取保存的配置
    [self getUserConf];
    
    self.networkController = [[NetworkViewController alloc] initWithNibName:@"NetworkViewController" bundle:nil];
    [self.view addSubview:self.networkController.view];
    
    NSString *vpnIp = _ipTextField.text;
    NSString *userName = _userTextField.text;
    NSString *password = _pswTextField.text;
    if (vpnIp.length > 0 && userName.length > 0 && password.length > 0) {
        [self onLoginBtnPressed:nil];
    } else {
        self.networkController.view.hidden = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transformView:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // 初始化
    CGSize size = [UIScreen mainScreen].bounds.size;
    CGRect barRect = [[UIApplication sharedApplication] statusBarFrame];
    if ([self iSiPhoneX]) {
        CGRect rect = CGRectMake(0, barRect.size.height, size.width, size.height - barRect.size.height - 20);
        [self.setView setFrame:rect];
        [self.networkController.view setFrame:rect];
    } else {
        CGRect rect = CGRectMake(0, barRect.size.height, size.width, size.height - barRect.size.height);
        [self.setView setFrame:rect];
        [self.networkController.view setFrame:rect];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - sdk初始化
///初始化Sdk信息
- (void)initSangforSdk
{
    //默认VPN模式为L3VPN
    _mode = VPNModeL3VPN;
    
    //认证类型，默认为用户名密码
    _authType = VPNAuthTypePassword;
    
    //初始化AuthMangager
    _sdkManager = [SangforAuthManager getInstance];
    _sdkManager.delegate = self;
    
    //禁止越狱手机登录
    [_sdkManager disableCrackedPhoneAuth];
    
    //设置日志级别
    [_sdkManager setLogLevel:LogLevelDebug];
}

#pragma mark - UI
#pragma mark - keyboard event
///创建点击收起键盘事件
- (void)initViewTapAction
{
    UITapGestureRecognizer *tapAction = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    tapAction.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapAction];
}

///View点击处理
-(void)viewTapped:(UITapGestureRecognizer*)tapRecognizer
{
    [self.view endEditing:YES];
}

///键盘弹起消失
- (void)transformView:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSValue *value = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrame = [value CGRectValue];
    //CGRect rect = [_loginView convertRect:_loginView.bounds toView: [[UIApplication sharedApplication] keyWindow]];
    //    CGFloat y = CGRectGetMaxY(rect) - keyboardFrame.origin.y;
    //    if (y > 0) {
    //        CGRect ipRect = [_ipTextField convertRect:_ipTextField.bounds toView:[[UIApplication sharedApplication] keyWindow]];
    //        if (y > (ipRect.origin.y - 20)) {
    //            y = ipRect.origin.y - 20;
    //        }
    //        [UIView animateWithDuration:0.25f animations:^{
    //            [self.view setFrame:CGRectMake(self.view.left, self.view.top - y, self.view.width, self.view.height)];
    //        }];
    //    } else if(keyboardFrame.origin.y >= self.view.height) {
    //        [self.view setFrame:CGRectMake(self.view.left, 0,  self.view.width, self.view.height)];
    //    }
}

#pragma mark - 点击按钮事件
//点击登录按钮
- (IBAction)onLoginBtnPressed:(id)sender {
    //创建VPN的地址
    NSURL *vpnUrl = [NSURL URLWithString:_ipTextField.text];
    _authType = VPNAuthTypePassword;
    
    //密码认证
    NSString *username = _userTextField.text;
    NSString *password = _pswTextField.text;
    [_sdkManager startPasswordAuthLogin:_mode vpnAddress:vpnUrl username:username password:password];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}

///点击bypass模式按钮
- (void)onBypassBtnPressed:(id)sender
{
    [_sdkManager enableByPassMode];
}

- (IBAction)onSettingClicked:(id)sender {
    [_ipTextField setText:@"https://218.85.155.91:443"];
    [_userTextField setText:@"fjzhengxy"];
    [_pswTextField setText:@"aqgz.#2000GXB"];
}
- (IBAction)onGpsClicked:(id)sender {
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"auth_tableview_cell";
    AuthTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[AuthTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (tableView.tag == 0) {
        //用户名密码认证的Tableview
        if (indexPath.row == 0) {
            cell.image = [UIImage imageNamed:@"user.png"];
            cell.placeholder = @"用户名";
            [cell setTextSecurity:NO];
        } else {
            cell.image = [UIImage imageNamed:@"pwd.png"];
            cell.placeholder = @"密码";
            [cell setTextSecurity:YES];
        }
        
    } else if (tableView.tag == 1) {
        //证书认证的Tableview
        if (indexPath.row == 0) {
            cell.image = [UIImage imageNamed:@"user.png"];
            cell.placeholder = @"证书名称";
            [cell setTextSecurity:NO];
        } else {
            cell.image = [UIImage imageNamed:@"pwd.png"];
            cell.placeholder = @"证书密码";
            [cell setTextSecurity:YES];
        }
    }
    
    return cell;
}

#pragma mark - 组合认证显示提示框

///onLoginProcess返回的下一个认证类型为用户名密码认证
- (void)showUserPaswordAuthAlert
{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"用户名密码认证" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [ac addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"用户名";
    }];
    [ac addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"密码";
        textField.secureTextEntry = YES;
    }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        NSArray<UITextField *> *textFields = ac.textFields;
        UITextField *usrtxtField = textFields[0];
        UITextField *pwdTxtField = textFields[1];
        NSString *username = usrtxtField.text;
        NSString *password = pwdTxtField.text;
        [_sdkManager doPasswordAuth:username password:password];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [ac addAction:confirmAction];
    [ac addAction:cancelAction];
    [self presentViewController:ac animated:YES completion:nil];
}

///onLoginProcess返回的下一个认证类型为证书认证
- (void)showCertificateAuthAlert
{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"证书认证" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [ac addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"证书名称";
    }];
    [ac addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"密码";
        textField.secureTextEntry = YES;
    }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        NSArray<UITextField *> *textFields = ac.textFields;
        UITextField *cerPathTextField = textFields[0];
        UITextField *pwdTxtField = textFields[1];
        NSString *cerName = cerPathTextField.text;
        if(![cerName hasSuffix:@".p12"]) {
            cerName = [NSString stringWithFormat:@"%@.p12",cerName];
        }
        NSString *cerPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                  NSUserDomainMask, YES) objectAtIndex:0]
                             stringByAppendingPathComponent:cerName];
        NSString *password = pwdTxtField.text;
        [_sdkManager doCertificateAuth:cerPath password:password];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [ac addAction:confirmAction];
    [ac addAction:cancelAction];
    [self presentViewController:ac animated:YES completion:nil];
}

///onLoginProcess返回的下一个认证类型为短信认证
- (void)showSMSAuthAlert:(SmsMessage *)objc
{
    NSString *phoneNum = objc.phoneNum;
    int countDown = objc.countDown;
    BOOL valid = objc.stillValid;
    
    SmsAlertView *alerView = [[SmsAlertView alloc] initWithMessage:[NSString stringWithFormat:@"手机号:%@",phoneNum]];
    if (valid) {
        [alerView setButtonEnable:NO];
        [alerView setButtonTitle:@"验证码依然有效"];
    } else if(countDown > 0) {
        [alerView setButtonEnable:NO];
        [alerView startTimer:countDown];
        //开启定时器
    } else {
        [alerView setButtonEnable:YES];
        [alerView setButtonTitle:@"重新获取验证码"];
    }
    
    alerView.alerResult = ^(NSString *code) {
        [_sdkManager doSMSAuth:code];
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    };
    
    __block SmsAlertView *bAlertView = alerView;
    
    alerView.reacquireCode = ^{
        SmsMessage * smsmessge = [_sdkManager reacquireSmsCode];
        if (smsmessge.countDown > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [bAlertView startTimer:countDown];
            });
        }
    };
    
    [alerView showSmsAlertView];
}

///onLoginProcess返回的下一个认证类型为挑战认证
- (void)showRadiusAuthAlert:(ChallengeMessage *)objc
{
    NSString *message = objc.challengeMsg;
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"挑战认证" message:message preferredStyle:UIAlertControllerStyleAlert];
    [ac addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"答案";
    }];
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        NSArray<UITextField *> *textFields = ac.textFields;
        UITextField *replyTextField = textFields[0];
        NSString *reply = replyTextField.text;
        [_sdkManager doRadiusAuth:reply];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [ac addAction:confirmAction];
    [ac addAction:cancelAction];
    [self presentViewController:ac animated:YES completion:nil];
}

///onLoginProcess返回的下一个认证类型为动态令牌认证
- (void)showTokenAuthAlert
{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"动态令牌认证" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [ac addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"动态令牌";
    }];
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        NSArray<UITextField *> *textFields = ac.textFields;
        UITextField *tokenTextField = textFields[0];
        NSString *token = tokenTextField.text;
        [_sdkManager doTokenAuth:token];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [ac addAction:confirmAction];
    [ac addAction:cancelAction];
    [self presentViewController:ac animated:YES completion:nil];
}

///onLoginProcess返回的下一个认证类型为强制修改密码认证
- (void)showRenewPasswordAuthAlert:(ChangePswMessage *)ojbc
{
    NSString *message = ojbc.pswMsg;
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"修改密码" message:message preferredStyle:UIAlertControllerStyleAlert];
    [ac addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"新密码";
        textField.secureTextEntry = YES;
    }];
    [ac addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"确认新密码";
        textField.secureTextEntry = YES;
    }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSArray<UITextField *> *textFields = ac.textFields;
        UITextField *new1PwdTF = textFields[0];
        UITextField *new2PwdTF = textFields[1];
        NSString *new1Pwd = new1PwdTF.text;
        NSString *new2Pwd = new2PwdTF.text;
        
        if ([new1Pwd isEqualToString:new2Pwd]) {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [_sdkManager doRenewPasswordAuth:new1Pwd];
        } else {
            [self showAlertView:@"修改密码失败" message:@"两次新密码不同"];
        }
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [ac addAction:confirmAction];
    [ac addAction:cancelAction];
    [self presentViewController:ac animated:YES completion:nil];
}

///onLoginProcess返回的下一个认证类型为强制修改密码认证
- (void)showRenewPasswordAuthAlert2:(ChangePswMessage *)ojbc
{
    NSString *message = ojbc.pswMsg;
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"修改密码" message:message preferredStyle:UIAlertControllerStyleAlert];
    [ac addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"旧密码";
        textField.secureTextEntry = YES;
    }];
    [ac addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"新密码";
        textField.secureTextEntry = YES;
    }];
    [ac addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"确认新密码";
        textField.secureTextEntry = YES;
    }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSArray<UITextField *> *textFields = ac.textFields;
        UITextField *new1PwdTF = textFields[1];
        UITextField *new2PwdTF = textFields[2];
        NSString *new1Pwd = new1PwdTF.text;
        NSString *new2Pwd = new2PwdTF.text;
        NSString *oldPwd = textFields[0].text;
        
        if ([new1Pwd isEqualToString:new2Pwd]) {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [_sdkManager doRenewPasswordAuth:oldPwd newPassword:new1Pwd];
        } else {
            [self showAlertView:@"修改密码失败" message:@"两次新密码不同"];
        }
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [ac addAction:confirmAction];
    [ac addAction:cancelAction];
    [self presentViewController:ac animated:YES completion:nil];
}

///显示图形校验码的提示框
- (void)showRandCodeAlert:(NSData *)data
{
    if(!_randView) {
        _randView = [[RandAlertView alloc] initWithTitle:@"" message:@""];
    }
    if (data == nil) {
        [_sdkManager reacquireRandCode];
    } else {
        UIImage *image = [UIImage imageWithData:data];
        [_randView setRandImage:image];
    }
    
    [_randView showRandAlertView];
    __block SangforAuthManager *blockSdk = self.sdkManager;
    __block UIView *blockView = self.view;
    
    _randView.alerResult = ^(NSString *rand) {
        [MBProgressHUD showHUDAddedTo:blockView animated:YES];
        [blockSdk doRandCodeAuth:rand];
    };
    _randView.imageAction = ^{
        [blockSdk reacquireRandCode];
    };
}

#pragma mark - SangforAuthDelegate
/**
 认证失败
 
 @param error 错误信息
 */
- (void)onLoginFailed:(NSError *)error
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    if(error.code == SF_ERROR_CONNECT_VPN_FAILED && _authType == VPNAuthTypeTicket) {
        [self showTicketAlertView:@"认证失败" message:error.domain];
        
    } else {
        [self showAlertView:@"认证失败" message:[NSString stringWithFormat:@"%@,code=%ld",error.domain,(long)error.code]];
    }
}

/**
 认证过程回调
 
 @param nextAuthType 下个认证类型
 */
- (void)onLoginProcess:(VPNAuthType)nextAuthType message:(BaseMessage *)msg
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    switch (nextAuthType) {
        case VPNAuthTypeCertificate:
            [self showCertificateAuthAlert];
            break;
        case VPNAuthTypePassword:
            [self showUserPaswordAuthAlert];
            break;
        case VPNAuthTypeRenewPassword:
            [self showRenewPasswordAuthAlert:(ChangePswMessage *)msg];
            break;
        case VPNAuthTypeRenewPassword2:
            [self showRenewPasswordAuthAlert2:(ChangePswMessage *)msg];
            break;
        case VPNAuthTypeSms:
            [self showSMSAuthAlert:(SmsMessage *)msg];
            break;
        case VPNAuthTypeRand:
            [self showRandCodeAlert:nil];
            break;
        case VPNAuthTypeToken:
            [self showTokenAuthAlert];
            break;
        case VPNAuthTypeRadius:
            [self showRadiusAuthAlert:(ChallengeMessage *)msg];
            break;
        default:
            break;
    }
}

/**
 认证成功
 */
- (void)onLoginSuccess
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self saveUserConf];
    
//    if (!_networkController) {
//        self.networkController = [[NetworkViewController alloc] initWithNibName:@"NetworkViewController" bundle:nil];
//    }
//    [self.navigationController pushViewController:_networkController animated:YES];
    
    self.networkController.view.hidden = NO;
    [self.networkController load];
}

/**
 图形校验码回调
 @param data 图片信息
 */
- (void)onRndCodeCallback:(NSData *)data
{
    if(_randView) {
        UIImage *image = [UIImage imageWithData:data];
        [_randView setRandImage:image];
    }
}
#pragma mark - 保存数据

/**
 *  保存用户设置
 */
-(void)saveUserConf
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setValue:_ipTextField.text forKey:kVpnIp];
    [userDefault setValue:_userTextField.text forKey:kUser];
    [userDefault setValue:_pswTextField.text forKey:kPsw];
}

/**
 *  读取用户配置
 */
-(void)getUserConf{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSString *ip = [userDefault valueForKey:kVpnIp];
    NSString *userName = [userDefault valueForKey:kUser];
    NSString *password = [userDefault valueForKey:kPsw];
    if (ip.length > 0 && userName.length > 0 && password.length > 0) {
        [_ipTextField setText:ip];
        [_userTextField setText:userName];
        [_pswTextField setText:password];
    }
}

#pragma mark - alert View
- (void)showTicketAlertView:(NSString *)title message:(NSString *)msg
{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"重试" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([_sdkManager ticketAuthAvailable]) {
            _authType = VPNAuthTypeTicket;
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [_sdkManager startTicketAuthLogin:_mode];
        }
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [ac addAction:confirmAction];
    [ac addAction:cancelAction];
    [self presentViewController:ac animated:YES completion:nil];
}

- (void)showAlertView:(NSString *)title message:(NSString *)msg
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alert show];
}


/**
 判断是否是iPhoneX   add by 苏华锦 2017-11-03
 @see http://www.jianshu.com/p/b23016bb97af
 @return return value description
 */
- (BOOL)iSiPhoneX {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    if ([deviceString isEqualToString:@"iPhone10,3"]) {
        return YES; //国行(A1865)、日行(A1902)iPhone X
    } else if ([deviceString isEqualToString:@"iPhone10,6"]) {
        return YES; //美版(Global/A1901)iPhone X
    } else if ([deviceString isEqualToString:@"i386"] || [deviceString isEqualToString:@"x86_64"]) { // 模拟器
        CGFloat screenHeight = CGRectGetHeight([[UIScreen mainScreen] bounds]);
        CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]);
        if ((screenWidth == 375 && screenHeight == 812) || (screenWidth == 812 && screenHeight == 375)) { // 竖屏、横屏都要考虑
            return YES;
        }
    }
    return NO;
}

@end
