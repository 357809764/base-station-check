//
//  NetworkViewController.h
//  SdkDemo
//
//  Created by sangfor on 2016/11/16.
//  Copyright © 2016年 sangfor. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NetworkViewController : UIViewController<UIPickerViewDelegate, UIPickerViewDataSource,UIWebViewDelegate>
{
    __weak IBOutlet UIWebView *mWebView;
    __weak IBOutlet UITextView *mLogView;
    __weak IBOutlet UIPickerView *mPickView;
    __weak IBOutlet UITextField *mUrlTf;
}
@end
