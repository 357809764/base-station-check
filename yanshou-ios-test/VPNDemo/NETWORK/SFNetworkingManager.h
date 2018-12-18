//
//  SFNetworkingManager.h
//  WebViewDemo
//
//  Created by fgg on 16/3/15.
//  Copyright © 2016年 fgg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"

#define bUse_MKNetworkKit_VERSION_2 1

typedef void (^SFURLRequestCompletionHandler)(NSURLResponse *response, id responseObj, NSError *error);

@interface SFNetworkingManager : NSObject

@property (nonatomic, strong) UIWebView *webview;

@property (readonly, nonatomic, strong) NSArray *registedClasses;

@property (readonly, nonatomic, strong) NSMutableDictionary *mutableURLRequestMehtodsKeyedByClass;

@property (readonly, nonatomic, strong) NSURL *url;

@property (readonly, nonatomic, strong) NSMutableURLRequest *request;

@property (nonatomic, copy) SFURLRequestCompletionHandler completionHandler;

+ (instancetype)sharedInstance;
- (NSArray *)registedMethodsForClass:(id)class;
- (void)setUrlString:(NSString *)url;
- (void)registURLRequestClass:(Class)class withSelector:(SEL)selector;

@end
