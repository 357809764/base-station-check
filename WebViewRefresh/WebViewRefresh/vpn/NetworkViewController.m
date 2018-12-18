//
//  NetworkViewController.m
//  SdkDemo
//
//  Created by sangfor on 2016/11/16.
//  Copyright © 2016年 sangfor. All rights reserved.
//

#import "NetworkViewController.h"
#import <CoreImage/CoreImage.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <MJRefresh.h>

static CLLocation *sLocation;

@interface NetworkViewController ()<UIWebViewDelegate>


@property (strong, nonatomic) NSURLConnection * theConnection;
@property (strong, nonatomic) NSURLSessionDataTask *task;

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
    
    mWebView.opaque = NO;
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        NSLog(@"下拉刷新");
        [self reload];
    }];
    
    header.stateLabel.hidden = YES;
    header.lastUpdatedTimeLabel.hidden = YES;
    header.arrowView.image = nil;
    mWebView.scrollView.mj_header = header;
    
    // Do any additional setup after loading the view from its nib.
    
    mLogView.layer.borderWidth = 1;
    mWebView.layer.borderWidth = 1;
    
    mWebView.layer.borderColor = [[UIColor clearColor] CGColor];
    
    [self startLocation];
    

    self.url = @"https://www.baidu.com/";
    [self load:self.url];
}

#pragma mark - 结束下拉刷新和上拉加载
- (void)endRefresh{
    dispatch_async(dispatch_get_main_queue(), ^{
        [mWebView.scrollView.mj_header endRefreshing];
    });
}


- (void)viewWillUnload
{    //反注册通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)load:(NSString *)url {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10];
    
    [mWebView loadRequest:request];
    mNetErrorLabel.hidden = YES;
}

- (void)reload {
    mNetErrorLabel.hidden = YES;
    NSURLRequest *request = [mWebView request];
    NSString *url = request.URL.absoluteString;
    if ([url isEqualToString:@"about:blank"]) {
        [self load:self.url];
    } else {
        [mWebView reload];
    }
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

}
#pragma mark -
#pragma mark UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    NSInteger count = 0;
    return 1;
}

#pragma mark -
#pragma mark UIPickerViewDelegate
- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return @"";
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

}

#pragma mark -
#pragma mark UIWebViewDelegate
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {

}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *url = request.URL.absoluteString;
    if (![url isEqualToString:@"about:blank"]) {
        NSURLSession *session = [NSURLSession sharedSession];
        if (_task != nil) {
            [_task cancel];
            _task = nil;
        }
        _task = [session dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSLog(@"response code = %ld", error.code);
            if (error.code == -1005 || error.code == -1009) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self load:@"about:blank"];
                    mNetErrorLabel.hidden = NO;
                });
            }
            [self endRefresh];
            _task = nil;
        }];
        [_task resume];
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    _jsContext = [mWebView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    _jsContext[@"YanShouInterface"][@"getLocation"] =  ^(){
        if (sLocation == nil) {
            return @"{}";
        }
        CLLocationCoordinate2D coordinate = sLocation.coordinate;
        NSLog(@"纬度:%f 经度:%f", coordinate.latitude, coordinate.longitude);
        return [NSString stringWithFormat:@"{\"latitude\":%f,\"longitude\":%f}", coordinate.latitude, coordinate.longitude];
    };
     [self endRefresh];
}

#pragma mark -
#pragma mark GPS
- (void)startLocation
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    /** 由于IOS8中定位的授权机制改变 需要进行手动授权
     * 获取授权认证，两个方法：
     * [self.locationManager requestWhenInUseAuthorization];
     * [self.locationManager requestAlwaysAuthorization];
     */
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        //[self.locationManager requestWhenInUseAuthorization];
        [self.locationManager requestAlwaysAuthorization];
    }
    
    //开始定位，不断调用其代理方法
    [self.locationManager startUpdatingLocation];
    NSLog(@"start gps");
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    // 1.获取用户位置的对象
    sLocation = [locations lastObject];
    CLLocationCoordinate2D coordinate = sLocation.coordinate;
    
    // 2.停止定位
    //[manager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    if (error.code == kCLErrorDenied) {
        // 提示用户出错原因，可按住Option键点击 KCLErrorDenied的查看更多出错信息，可打印error.code值查找原因所在
    }
}

- (IBAction)btnLinkClicked:(id)sender {
    NSString *url = @"http://120.36.56.152:3694/?ys_ver=i1";
    [mWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
}

@end
