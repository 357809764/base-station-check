//
//  NetworkViewController.h
//  SdkDemo
//
//  Created by sangfor on 2016/11/16.
//  Copyright © 2016年 sangfor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "MaskView.h"

@interface NetworkViewController : UIViewController<UIPickerViewDelegate, UIWebViewDelegate, CLLocationManagerDelegate>
{
    __weak IBOutlet UIWebView *mWebView;
    __weak IBOutlet UITextView *mLogView;
    __weak IBOutlet UIPickerView *mPickView;
    __weak IBOutlet UITextField *mUrlTf;
    __weak IBOutlet UILabel *mNetErrorLabel;
}
@property (strong, atomic) JSContext *jsContext;
@property (weak, nonatomic) IBOutlet MaskView *maskView;
@property (strong, atomic) CLLocationManager *locationManager;
@property (strong, atomic) NSString *url;
- (void)load;
- (void)reload;

@end
