//
//  NetworkViewController.m
//  SdkDemo
//
//  Created by sangfor on 2016/11/16.
//  Copyright © 2016年 sangfor. All rights reserved.
//

#import "NetworkViewController.h"
#import "SFNetworkingManager.h"
#import "SangforAuthManager.h"
#import "SangforAuthHeader.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreImage/CoreImage.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface NetworkViewController ()<UIWebViewDelegate>
@property (nonatomic, strong) CLLocationManager *manager;

@end

#define UIPickerView_Width      ([UIScreen mainScreen].bounds.size.width/2)
#define UIPickerView_Row_Height 30

@implementation NetworkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *tapAction = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    tapAction.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapAction];
    
    [mPickView setDelegate:self];
    [mPickView setDataSource:self];
    [mWebView setDelegate:self];
    
    SFNetworkingManager *mgr = [SFNetworkingManager sharedInstance];
    mgr.webview = mWebView;
    [mgr setCompletionHandler:^(NSURLResponse *response, id responseObj, NSError *error) {
        if (error) {
            [self logResponse:response withObject:error];
        } else {
            [self logResponse:response withObject:responseObj];
        }
    }];
    
    // Do any additional setup after loading the view from its nib.
    
    mLogView.layer.borderWidth = 1;
    mWebView.layer.borderWidth = 1;
    
    // 定位
    _manager = [CLLocationManager new];
    [_manager requestWhenInUseAuthorization];
    
    // webView 大小
    CGRect barRect = [[UIApplication sharedApplication] statusBarFrame];
    CGSize size = [UIScreen mainScreen].bounds.size;
    mWebView.frame = CGRectMake(0, barRect.size.height, size.width, size.height - barRect.size.height);
    mWebView.layer.borderColor = [[UIColor clearColor] CGColor];
    
    //注册两个通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloginFailed:) name:VPNReloginFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(vpnStatusChange:) name:VPNStatusDidChangeNotification object:nil];
}



- (void)viewWillUnload
{    //反注册通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)load {
    [self doLoad:@"http://120.36.56.152:3694/?ys_ver=i1"];
    //    [self doLoad:@"http://134.129.112.108:3694/?ys_ver=i1"];
}

/**
 *  收起键盘
 *
 *  @param tapRecognizer tapRecognizer description
 */
-(void)viewTapped:(UITapGestureRecognizer*)tapRecognizer
{
    [self.view endEditing:YES];
}

- (IBAction)logoutAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
    [[SangforAuthManager getInstance] vpnLogout];
}

- (IBAction)backAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)logResponse:(NSURLResponse *)response withObject:(id)obj {
    if ([obj isKindOfClass:NSData.class]) {
        obj = [[NSString alloc] initWithData:obj encoding:NSUTF8StringEncoding];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [mLogView scrollsToTop];
        NSString *log = [NSString stringWithFormat:@"===================header==================\n%@\n==================response=================\n%@", response, obj];
        if (response == nil) {
            log = [NSString stringWithFormat:@"===================header==================\nignore header(%@)\n==================response=================\n%@", [NSDate date], obj];
        }
        mLogView.text = log;
        mWebView.hidden = YES;
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)requestAction:(id)sender {    
    NSString *urlStr = [mUrlTf text];
    [self doLoad:urlStr];
#if 0
    if (!urlStr || urlStr.length == 0) {
        return;
    }
    
    SFNetworkingManager *mgr = [SFNetworkingManager sharedInstance];
    [mgr setUrlString:urlStr];
    
    NSInteger row = [mPickView selectedRowInComponent:0];
    id classString = mgr.registedClasses[row];
    row = [mPickView selectedRowInComponent:1];
    NSArray *selectors = [mgr registedMethodsForClass:classString];
    NSString *selectorString = selectors[row];
    SEL selector = NSSelectorFromString(selectorString);
    if (selector) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [mgr performSelectorInBackground:selector withObject:nil];
#pragma clang diagnostic pop
    }
#endif
}


- (void)doLoad:(NSString *)urlStr
{
    if (!urlStr || urlStr.length == 0) {
        return;
    }
    
    SFNetworkingManager *mgr = [SFNetworkingManager sharedInstance];
    [mgr setUrlString:urlStr];
    
    SEL selector = NSSelectorFromString(@"doWebviewLoad");
    [mgr performSelectorInBackground:selector withObject:nil];
}

#pragma mark -
#pragma mark UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    NSInteger count = 0;
    SFNetworkingManager *mgr = [SFNetworkingManager sharedInstance];
    
    if (component == 0) {
        count = mgr.registedClasses.count;
    } else if (component == 1) {
        NSInteger selectedRow = [pickerView selectedRowInComponent:0];
        id key = mgr.registedClasses[selectedRow];
        NSArray *selectors = [mgr registedMethodsForClass:key];
        count = selectors.count;
    }
    return count;
}

#pragma mark -
#pragma mark UIPickerViewDelegate
- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSString *title;
    SFNetworkingManager *mgr = [SFNetworkingManager sharedInstance];
    if (component == 0) {
        title = mgr.registedClasses[row];
    } else if (component == 1) {
        NSInteger selectedRow = [pickerView selectedRowInComponent:0];
        id key = mgr.registedClasses[selectedRow];
        NSArray *selectors = [mgr registedMethodsForClass:key];
        title = selectors[row];
    }
    
    return title;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (component == 0) {
        [pickerView reloadComponent:1];
    }
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return UIPickerView_Width;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return UIPickerView_Row_Height;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel* pickerLabel = (UILabel*)view;
    if (!pickerLabel) {
        pickerLabel = [[UILabel alloc] init];
        CGFloat width = [self pickerView:pickerView widthForComponent:component];
        CGFloat height = [self pickerView:pickerView rowHeightForComponent:component];
        pickerLabel.frame = CGRectMake(0, 0, width, height);
        pickerLabel.adjustsFontSizeToFitWidth = YES;
        [pickerLabel setTextAlignment:NSTextAlignmentCenter];
        [pickerLabel setBackgroundColor:[UIColor clearColor]];
        [pickerLabel setFont:[UIFont boldSystemFontOfSize:20]];
    }
    
    pickerLabel.text= [self pickerView:pickerView titleForRow:row forComponent:component];
    return pickerLabel;
}

#pragma mark - NSNotification
- (void)reloginFailed:(id)notification
{
    NSError *error = (NSError *)[(NSNotification *)notification object];
    NSLog(@"reloginFailed,error:%@.",error);
}

- (void)vpnStatusChange:(id)notification
{
    StatusChangeMessage *meeage = (StatusChangeMessage *)[(NSNotification *)notification object];
    NSLog(@"vpnStatusChange,curStatus:%lu.",meeage.status);
}

#pragma mark -
#pragma mark UIWebViewDelegate
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (error != nil) {
        NSLog(@"加载失败");
    }
}

//////////////////////////
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    JSContext *context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    
    // 调用系统相机 iOSCamera 就是你自定义的一个js函数名
    /*
     举个例子
     定义一个js函数在控制台打印一句话这样写
     context[@"js函数名"] = ^(){
     NSLog(@"在控制台打印一句话");
     };
     */
    context[@"iOSCamera"] = ^(){
        // 调用系统相机的类
        UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
        
        // 设置选取的照片是否可编辑
        pickerController.allowsEditing = YES;
        // 设置相册呈现的样式
        pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        // 选择完成图片或者点击取消按钮都是通过代理来操作我们所需要的逻辑过程
        pickerController.delegate = self;
        
        // 使用模态呈现相机 getCurrentViewController这个方法是用来拿到添加了这个View的控制器
        [[self getCurrentViewController] presentViewController:pickerController animated:YES completion:nil];
        
        return @"调用相机";
    };
    
    
    context[@"iOSPhotosAlbum"] = ^(){
        
        // 调用系统相册的类
        UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
        
        // 设置选取的照片是否可编辑
        pickerController.allowsEditing = YES;
        // 设置相册呈现的样式
        pickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        // 选择完成图片或者点击取消按钮都是通过代理来操作我们所需要的逻辑过程
        pickerController.delegate = self;
        
        // 使用模态呈现相册
        [[self getCurrentViewController] presentViewController:pickerController animated:YES completion:nil];
        
        return @"调用相册";
        
    };
    
//    if ([self.delegate respondsToSelector:@selector(zszWebViewDidFinishLoad:)]) {
//        [self.delegate zszWebViewDidFinishLoad:webView];
//    }
    
}


/** 获取当前View的控制器对象 */
-(UIViewController *)getCurrentViewController{
    UIResponder *next = [self nextResponder];
    do {
        if ([next isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)next;
        }
        next = [next nextResponder];
    } while (next != nil);
    return nil;
}




@end
