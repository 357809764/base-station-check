//
//  AuthViewController.m
//  VPNDemo
//
//  Created by sangfor on 2017/8/23.
//  Copyright © 2017年 sangfor. All rights reserved.
//

#import "AuthViewController.h"
#import "DLRadioButton.h"
#import "SDAutoLayout.h"
#import "AuthTableViewCell.h"
#import "SangforAuthManager.h"
#import "RandAlertView.h"
#import "NetworkViewController.h"
#import "MBProgressHUD.h"
#import "SmsAlertView.h"
#import "errheader.h"

#define kVpnIp      @"vpnIp"       //VPN地址
#define kPort       @"vpnport"     //VPN端口号
#define kVpnModel   @"vpnModel"     //VPN模式

@interface AuthViewController ()<UITableViewDelegate,UITableViewDataSource,SangforAuthDelegate>

///背景图
@property (nonatomic, strong)   UIImageView             *backgroundView;        //背景

//VPN地址相关控件
///VPN地址的输入框
@property (strong, nonatomic)   UITextField             *vpnIpTextField;

//VPN登录相关控件
///登录的View，包含其它子View
@property (strong, nonatomic)   UIView                  *loginView;
///用户名密码表单
@property (nonatomic, strong)   UITableView             *userNameTableView;
///证书表单
@property (nonatomic, strong)   UITableView             *cerTableView;

//分段相关控件
///分段控制器
@property (nonatomic, strong)   UISegmentedControl      *segmentedControl;
///分段控制器的选中下划线
@property (nonatomic, strong)   UILabel                 *selectedSegmentLabel;

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

///BYPASS按钮
@property (nonatomic, strong) UIButton                  *bypassBtn;
@end

@implementation AuthViewController

#pragma mark - 生命周期
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    //初始化Sdk信息
    [self initSangforSdk];
    
    //创建点击收起键盘事件
    [self initViewTapAction];
    
    //增加VPN类型UI
    [self setupVpnTypeSegment];
    
    //增加VPN地址UI
    [self setupVpnAddrView];
    
    //增加VPN登录UI
    [self setupLoginView];
    
    //设置bypass按钮
    [self setupBypassButton];
    
    //设置免密登录按钮
    [self setupTicketButton];
    
    //获取保存的配置
    [self getUserConf];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transformView:) name:UIKeyboardWillChangeFrameNotification object:nil];
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

///设置VPN类型UI
- (void)setupVpnTypeSegment
{
    //VPN模式的Label
    UILabel *vpnTypeLabel = [UILabel new];
    vpnTypeLabel.text = @"L3VPN模式";
    vpnTypeLabel.font = [UIFont boldSystemFontOfSize:18];
    vpnTypeLabel.textAlignment = NSTextAlignmentCenter;
    vpnTypeLabel.textColor = [UIColor blackColor];
    [self.view addSubview:vpnTypeLabel];
    vpnTypeLabel.sd_layout
    .centerXEqualToView(self.view)
    .topSpaceToView(self.view, 50)
    .heightIs(20)
    .widthIs(150);
}

///添加VPN地址UI
- (void)setupVpnAddrView
{
    //VPN地址的Label
    UILabel *vpnAddrLabel = [UILabel new];
    vpnAddrLabel.text = @"VPN地址";
    vpnAddrLabel.font = [UIFont systemFontOfSize:18];
    vpnAddrLabel.textAlignment = NSTextAlignmentLeft;
    vpnAddrLabel.textColor = [UIColor blackColor];
    [self.view addSubview:vpnAddrLabel];
    vpnAddrLabel.sd_layout
    .topSpaceToView(self.view, 90)
    .leftSpaceToView(self.view, 20)
    .heightIs(20)
    .widthIs(80);
    
    //VPN地址的TextField
    self.vpnIpTextField = [UITextField new];
    _vpnIpTextField.backgroundColor = [UIColor whiteColor];
    _vpnIpTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _vpnIpTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _vpnIpTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    _vpnIpTextField.textColor = [UIColor blackColor];
    _vpnIpTextField.layer.borderWidth = 1;
    _vpnIpTextField.layer.cornerRadius = 5;
    _vpnIpTextField.layer.masksToBounds = YES;
    _vpnIpTextField.layer.borderColor = [UIColor colorWithRed:106.0/255 green:149.0/255 blue:179.0/255 alpha:1].CGColor;
    _vpnIpTextField.placeholder = @"IP地址";
    [self.view addSubview:_vpnIpTextField];
    _vpnIpTextField.sd_layout
    .leftEqualToView(vpnAddrLabel)
    .topSpaceToView(vpnAddrLabel, 10)
    .widthRatioToView(self.view, 0.9)
    .heightIs(30);
    
    _vpnIpTextField.text = @"https://218.85.155.91:443";
}

///设置登录需要的UI
- (void)setupLoginView
{
    self.loginView = [UIView new];
    [self.view addSubview:_loginView];
    _loginView.sd_layout
    .topSpaceToView(_vpnIpTextField, 30)
    .widthRatioToView(self.view, 1)
    .heightIs(266);
    
    //添加分段控制器
    [self setupLoginTypeSegment];
    
    //添加用户名密码登录和证书登录界面
    [self setupTableView];
    
    //添加登录按钮
    UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [loginButton setBackgroundColor:[UIColor colorWithRed:2.0/255 green:154.0/255 blue:255.0/255 alpha:1]];
    [loginButton setTitle:@"登录" forState:UIControlStateNormal];
    [loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [loginButton setTitleColor:[UIColor grayColor] forState:UIControlStateSelected];
    [loginButton.layer setCornerRadius:5.0];
    [loginButton.layer setMasksToBounds:YES];
    [loginButton addTarget:self action:@selector(onLoginBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_loginView addSubview:loginButton];
    loginButton.sd_layout
    .bottomSpaceToView(_loginView, 10)
    .centerXEqualToView(_loginView)
    .heightIs(50)
    .widthRatioToView(_loginView, 0.9);
}

///添加分段控制器
- (void)setupLoginTypeSegment
{
    NSArray *items = @[@"账号", @"证书"];
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:items];
    _segmentedControl.selectedSegmentIndex = 0;
    _segmentedControl.backgroundColor = [UIColor clearColor];
    _segmentedControl.tintColor = [UIColor clearColor];
    //设置正常状态和选中状态的文字颜色和字体
    [_segmentedControl setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16],NSForegroundColorAttributeName:[UIColor colorWithRed:184.0/255 green:202.0/255 blue:211.0/255 alpha:1]} forState:UIControlStateNormal];
    [_segmentedControl setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:18],NSForegroundColorAttributeName:[UIColor colorWithRed:0/255 green:121.0/255 blue:191.0/255 alpha:1]} forState:UIControlStateSelected];
    [_segmentedControl addTarget:self action:@selector(onSegmentedControlClick:) forControlEvents:UIControlEventValueChanged];
    [_loginView addSubview:_segmentedControl];
    _segmentedControl.sd_layout
    .widthRatioToView(_loginView, 1)
    .heightIs(50);
    
    //添加背景底线
    UILabel *bottomLine =[UILabel new];
    bottomLine.layer.borderWidth = 1.0;
    bottomLine.clipsToBounds = NO;
    bottomLine.layer.borderColor = [UIColor colorWithRed:184.0/255 green:202.0/255 blue:211.0/255 alpha:0.6].CGColor;
    [_segmentedControl addSubview:bottomLine];
    bottomLine.sd_layout
    .bottomSpaceToView(_segmentedControl, 2)
    .heightIs(2)
    .widthRatioToView(_segmentedControl, 1);
    
    //选中的底线
    _selectedSegmentLabel = [UILabel new];
    _selectedSegmentLabel.layer.borderWidth = 1.0;
    _selectedSegmentLabel.clipsToBounds = NO;
    _selectedSegmentLabel.layer.borderColor = [UIColor colorWithRed:184.0/255 green:202.0/255 blue:211.0/255 alpha:1].CGColor;
    [_segmentedControl addSubview:_selectedSegmentLabel];
    _selectedSegmentLabel.sd_layout
    .bottomSpaceToView(_segmentedControl, 2)
    .widthRatioToView(_segmentedControl, 0.4)
    .centerXIs(self.view.center.x/2)
    .heightIs(2);
}

///添加用户名密码登录和证书登录的TableView
- (void)setupTableView
{
    //用户名的tableview
    self.userNameTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _userNameTableView.delegate = self;
    _userNameTableView.dataSource = self;
    _userNameTableView.tag = 0;
    _userNameTableView.backgroundColor = [UIColor whiteColor];
    [_userNameTableView setScrollEnabled:NO];
    [_loginView addSubview:_userNameTableView];
    _userNameTableView.sd_layout
    .topSpaceToView(_segmentedControl, 17)
    .centerXEqualToView(_loginView)
    .widthRatioToView(_loginView, 0.9)
    .heightIs(100);
    
    //证书的tableview
    self.cerTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _cerTableView.delegate = self;
    _cerTableView.dataSource = self;
    _cerTableView.tag = 1;
    _cerTableView.backgroundColor = [UIColor whiteColor];
    [_cerTableView setScrollEnabled:NO];
    [_loginView addSubview:_cerTableView];
    _cerTableView.sd_layout
    .topEqualToView(_userNameTableView)
    .leftSpaceToView(_userNameTableView, 0.1 * self.view.width)
    .widthRatioToView(_userNameTableView, 1)
    .heightRatioToView(_userNameTableView, 1);
}

///设置bypass模式的按钮
- (void)setupBypassButton
{
    self.bypassBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_bypassBtn setBackgroundColor:[UIColor colorWithRed:2.0/255 green:154.0/255 blue:255.0/255 alpha:1]];
    [_bypassBtn setTitle:@"进入BYPASS模式(最先调用，重启无效)" forState:UIControlStateNormal];
    [_bypassBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_bypassBtn setTitleColor:[UIColor grayColor] forState:UIControlStateSelected];
    [_bypassBtn.layer setCornerRadius:5.0];
    [_bypassBtn.layer setMasksToBounds:YES];
    [_bypassBtn addTarget:self action:@selector(onBypassBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_bypassBtn];
    
    _bypassBtn.sd_layout
    .topSpaceToView(_loginView, 10)
    .centerXEqualToView(self.view)
    .heightIs(50)
    .widthRatioToView(self.view, 0.9);
}

///免密认证按钮
- (void)setupTicketButton
{
    UIButton *ticketBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [ticketBtn setBackgroundColor:[UIColor colorWithRed:2.0/255 green:154.0/255 blue:255.0/255 alpha:1]];
    [ticketBtn setTitle:@"免密认证（需要VPN设备7.6.1）" forState:UIControlStateNormal];
    [ticketBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [ticketBtn setTitleColor:[UIColor grayColor] forState:UIControlStateSelected];
    [ticketBtn.layer setCornerRadius:5.0];
    [ticketBtn.layer setMasksToBounds:YES];
    [ticketBtn addTarget:self action:@selector(onTicketBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:ticketBtn];
    
    ticketBtn.sd_layout
    .topSpaceToView(_bypassBtn, 10)
    .centerXEqualToView(self.view)
    .heightIs(50)
    .widthRatioToView(self.view, 0.9);
}

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
    CGRect rect = [_loginView convertRect:_loginView.bounds toView: [[UIApplication sharedApplication] keyWindow]];
    CGFloat y = CGRectGetMaxY(rect) - keyboardFrame.origin.y;
    if (y > 0) {
        CGRect ipRect = [_vpnIpTextField convertRect:_vpnIpTextField.bounds toView:[[UIApplication sharedApplication] keyWindow]];
        if (y > (ipRect.origin.y - 20)) {
            y = ipRect.origin.y - 20;
        }
        [UIView animateWithDuration:0.25f animations:^{
            [self.view setFrame:CGRectMake(self.view.left, self.view.top - y, self.view.width, self.view.height)];
        }];
    } else if(keyboardFrame.origin.y >= self.view.height) {
        [self.view setFrame:CGRectMake(self.view.left, 0,  self.view.width, self.view.height)];
    }
}

#pragma mark - 点击按钮事件
///登录类型的切换点击事件
- (void)onSegmentedControlClick:(id)sender
{
    [UIView animateWithDuration:0.25 animations:^{
        CGPoint center = _selectedSegmentLabel.center;
        center.x = (_segmentedControl.selectedSegmentIndex == 0) ? _segmentedControl.center.x * 0.5 : _segmentedControl.center.x * 1.5;
        _selectedSegmentLabel.center = center;
    }];
    
    if (_segmentedControl.selectedSegmentIndex == 0) {
        _authType = VPNAuthTypePassword;
        [UIView animateWithDuration:0.25 animations:^{
            CGRect frame = _cerTableView.frame;
            frame.origin.x += (self.view.width);
            _cerTableView.frame = frame;
            _cerTableView.hidden = YES;
            _userNameTableView.hidden = NO;
            frame.origin.x -= self.view.width;
            _userNameTableView.frame = frame;
        }];
    } else if (_segmentedControl.selectedSegmentIndex == 1) {
        _authType = VPNAuthTypeCertificate;
        [UIView animateWithDuration:0.25 animations:^{
            CGRect frame = _userNameTableView.frame;
            frame.origin.x -= (self.view.width);
            _userNameTableView.frame = frame;
            _userNameTableView.hidden = YES;
            _cerTableView.hidden = NO;
            frame.origin.x += self.view.width;
            _cerTableView.frame = frame;
        }];
    }
}

///点击登录按钮
- (void)onLoginBtnPressed:(id)sender
{
    //创建VPN的地址
    NSURL *vpnUrl = [NSURL URLWithString:_vpnIpTextField.text];
    if (_segmentedControl.selectedSegmentIndex == 0) {
        _authType = VPNAuthTypePassword;
    } else {
        _authType = VPNAuthTypeCertificate;
    }
    
    //根据设置的首次认证类型，设置认证参数
    //TODO: 这里都没有对参数进行判断
    if (_authType == VPNAuthTypePassword) {
        //密码认证
        NSString *username = @"fjzhengxy";// [(AuthTableViewCell *)[_userNameTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] cellText];
        NSString *password = @"aqgz.#2000GXB";//[(AuthTableViewCell *)[_userNameTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] cellText];
        [_sdkManager startPasswordAuthLogin:_mode vpnAddress:vpnUrl
                                   username:username password:password];
    } else if (_authType == VPNAuthTypeCertificate) {
        //证书认证
        NSString *cerName = [(AuthTableViewCell *)[_cerTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] cellText];
        if(![cerName hasSuffix:@".p12"]) {
            cerName = [NSString stringWithFormat:@"%@.p12",cerName];
        }
        NSString *password = [(AuthTableViewCell *)[_cerTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] cellText];
        NSString *cerPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                  NSUserDomainMask, YES) objectAtIndex:0]
                             stringByAppendingPathComponent:cerName];
        
        [_sdkManager startCertificateAuthLogin:_mode vpnAddress:vpnUrl
                               certificatePath:cerPath certificatePassword:password];
    }
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}

///点击bypass模式按钮
- (void)onBypassBtnPressed:(id)sender
{
    [_sdkManager enableByPassMode];
}

///免密认证按钮
- (void)onTicketBtnPressed:(id)sender
{
    if ([_sdkManager ticketAuthAvailable]) {
        _authType = VPNAuthTypeTicket;
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [_sdkManager startTicketAuthLogin:_mode];
    } else {
        [self showAlertView:@"提示" message:@"当前不支持免密认证"];
    }
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
    
    if (!_networkController) {
        self.networkController = [[NetworkViewController alloc] initWithNibName:@"NetworkViewController" bundle:nil];
    }
    
    [self.navigationController pushViewController:_networkController animated:YES];
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
    
    if (_vpnIpTextField.text.length > 0) {
        [userDefault setValue:_vpnIpTextField.text forKey:kVpnIp];
    }
    
    [userDefault setInteger:_mode forKey:kVpnModel];
}

/**
 *  读取用户配置
 */
-(void)getUserConf
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    
    if ([userDefault valueForKey:kVpnIp]) {
        [_vpnIpTextField setText:[userDefault valueForKey:kVpnIp]];
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
@end
