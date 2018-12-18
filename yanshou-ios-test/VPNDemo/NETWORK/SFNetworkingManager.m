//
//  SFNetworkingManager.m
//  WebViewDemo
//
//  Created by fgg on 16/3/15.
//  Copyright © 2016年 fgg. All rights reserved.
//

#import "SFNetworkingManager.h"
#import <UIKit/UIKit.h>
#import "AFNetworking.h"
#import "ASIHttpRequest.h"
#import <arpa/inet.h>
#import <netdb.h>
#include "err.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>

// socket回调函数，同客户端
static void TCPClientConnectCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    const char *httpRequeset =  "GET %s HTTP/1.0\r\n"
    "Accept: application/xaml+xml\r\n"
    "Accept-Language: zh-cn\r\n"
    "Accept-Encoding: deflate\r\n"
    "User-Agent: Mozilla/4.0\r\n"
    "Host: %s\r\n"
    "Connection: close\r\n\r\n";
    
    SFNetworkingManager *mgr = (__bridge SFNetworkingManager *)info;
    NSString *path = (mgr.url.path && ![mgr.url.path isEqualToString:@""]) ? mgr.url.path : @"/";
    char buffer[4096] = {0};
    snprintf(buffer, sizeof(buffer) - 1, httpRequeset, path.UTF8String, mgr.url.host.UTF8String);
    
    ssize_t ret = send(CFSocketGetNative(socket), buffer, strlen(buffer), 0);
    if (ret < 0) {
        return;
    }
    ret = recv(CFSocketGetNative(socket), buffer, sizeof(buffer)-1, 0);
    if (ret < 0) {
        return;
    }
    
    if (mgr.completionHandler) {
        NSData *data = [[NSData alloc] initWithBytes:buffer length:strlen(buffer)];
        mgr.completionHandler(nil, data, nil);
    }
}

#pragma mark -

@interface BSDSocket : NSObject

@end

@implementation BSDSocket

@end

#pragma mark -

@interface CFSocket : NSObject

@end

@implementation CFSocket

@end

#pragma mark -

@interface SFNetworkingManager () <NSURLConnectionDelegate, NSURLConnectionDataDelegate, NSURLSessionDelegate,NSURLSessionDataDelegate>

@property (readwrite, nonatomic, strong) NSMutableDictionary *mutableURLRequestMehtodsKeyedByClass;
@property (readwrite, nonatomic, strong) NSMutableURLRequest *request;
@property (readwrite, nonatomic, strong) NSArray *registedClasses;
@property (readwrite, nonatomic, strong) NSURL *url;
@property (nonatomic, assign) BOOL finished;

@end

@implementation SFNetworkingManager

+ (instancetype)sharedInstance {
    static dispatch_once_t predicate;
    static SFNetworkingManager *instance;
    dispatch_once(&predicate, ^{
        instance = [[SFNetworkingManager alloc] init];
        [instance registURLRequest];
    });
    
    return instance;
}

/**
 *  添加注册网络访问接口
 */
- (void)registURLRequest {
    [self registURLRequestClass:UIWebView.class withSelector:@selector(doWebviewLoad)];
    //    [self registURLRequestClass:UIWebView.class withSelector:@selector(doWebviewFileLoad)];
    [self registURLRequestClass:NSURLConnection.class withSelector:@selector(doNSURLConnectionGet)];
    [self registURLRequestClass:NSURLConnection.class withSelector:@selector(doNSURLConnectionPost)];
    [self registURLRequestClass:NSURLConnection.class withSelector:@selector(doNSURLConnectionGetHttps)];
    [self registURLRequestClass:NSURLSessionTask.class withSelector:@selector(doNSURLSessionDataTaskGet)];
    [self registURLRequestClass:NSURLSessionTask.class withSelector:@selector(doNSURLSessionDataTaskPost)];
    [self registURLRequestClass:NSURLSessionTask.class withSelector:@selector(doNSURLSessionDataTaskGetHttps)];
    [self registURLRequestClass:AFURLSessionManager.class withSelector:@selector(doAFNetworkingGet)];
    [self registURLRequestClass:AFURLSessionManager.class withSelector:@selector(doAFNetworkingPost)];
    [self registURLRequestClass:AFURLSessionManager.class withSelector:@selector(doAFNetworkingBackgroundGet)];
    [self registURLRequestClass:ASIHTTPRequest.class withSelector:@selector(doASIHttpRequestGet)];
    [self registURLRequestClass:ASIHTTPRequest.class withSelector:@selector(doASIHttpRequestPost)];
    [self registURLRequestClass:BSDSocket.class withSelector:@selector(doBSDSocketGet)];
    [self registURLRequestClass:BSDSocket.class withSelector:@selector(doBSDSocketPost)];
    [self registURLRequestClass:BSDSocket.class withSelector:@selector(testIPV6)];
    [self registURLRequestClass:CFSocket.class withSelector:@selector(doCFSocketGet)];
    //    [self registURLRequestClass:CFSocket.class withSelector:@selector(doCFSocketPost)];
}

- (void)registURLRequestClass:(Class)class withSelector:(SEL)selector {
    assert(class && selector);
    if (self.mutableURLRequestMehtodsKeyedByClass == nil) {
        self.mutableURLRequestMehtodsKeyedByClass = [NSMutableDictionary dictionary];
    }
    
    NSString *classString = NSStringFromClass(class);
    NSString *selectorString = NSStringFromSelector(selector);
    NSMutableArray *selectors = self.mutableURLRequestMehtodsKeyedByClass[classString];
    if (selectors == nil) {
        selectors = [NSMutableArray array];
    }
    
    [selectors addObject:selectorString];
    [self.mutableURLRequestMehtodsKeyedByClass setObject:selectors forKey:classString];
}

- (NSArray *)registedMethodsForClass:(id)class {
    return self.mutableURLRequestMehtodsKeyedByClass[class];
}

- (void)setUrlString:(NSString *)urlString {
    self.url = [[NSURL alloc] initWithString:urlString];
    self.request = [NSMutableURLRequest requestWithURL:self.url];
}

- (NSArray *)registedClasses {
    return self.mutableURLRequestMehtodsKeyedByClass.allKeys;
}

#pragma mark -
#pragma mark UIWebView
- (void)doWebviewLoad {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.webview.hidden = NO;
        [self.webview loadRequest:self.request];
    });
}

- (void)doWebviewFileLoad {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.webview.hidden = NO;
        NSString *path = [[NSBundle mainBundle] pathForResource:@"index.html" ofType:nil inDirectory:@"client"];
        NSURL *url = [NSURL fileURLWithPath:path];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [self.webview loadRequest:request];
    });
}

#pragma mark -
#pragma mark NSURLConnection
- (void)doNSURLConnectionGet {
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:self.request returningResponse:&response error:&error];
    
    if (self.completionHandler) {
        self.completionHandler(response, data, error);
    }
}

- (void)doNSURLConnectionPost {
    NSString *postStr = @"<?xml version=\"1.0\" encoding=\"utf-8\"?><soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\"><soap12:Body><GetMobileMisVersion xmlns=\"http://tempuri.org/\"><type>2</type></GetMobileMisVersion></soap12:Body></soap12:Envelope>";
    
    [self.request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)postStr.length] forHTTPHeaderField:@"Content-Length"];
    [self.request setHTTPMethod:@"POST"];
    [self.request setHTTPBody:[postStr dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:self.request returningResponse:&response error:&error];
    
    if (self.completionHandler) {
        self.completionHandler(response, data, error);
    }
}

- (void)doNSURLConnectionGetHttps {
    self.finished = NO;
    
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:self.request delegate:self];
    
    //堵塞线程，等待结束
    
    while(!self.finished) {
        
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        
    }
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"%@", error);
    self.finished = YES;
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection {
    return NO;
}

//- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
//    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
//    {
//        NSLog(@"Trust Challenge");
//        SecTrustResultType trustResultType;
//        OSStatus err = SecTrustEvaluate(challenge.protectionSpace.serverTrust, &trustResultType);
//
//        NSLog(@"SecTrustResult %u %d",trustResultType, (int)err);
//
//        if (trustResultType == kSecTrustResultProceed || trustResultType == kSecTrustResultConfirm || trustResultType == kSecTrustResultUnspecified) {
//            [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
//        }
//        else{
//            [challenge.sender cancelAuthenticationChallenge:challenge];
//        }
//
//    }
//}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSLog(@"didReceiveAuthenticationChallenge %@ %zd", [[challenge protectionSpace] authenticationMethod], (ssize_t) [challenge previousFailureCount]);
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]){
        [[challenge sender] useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
        [[challenge sender] continueWithoutCredentialForAuthenticationChallenge: challenge];
    }
    
    //    if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
    //        NSURLCredential *cre = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    //         调用block
    ////        [[challenge sender] useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    //        completionHandler(NSURLSessionAuthChallengeUseCredential,cre);
    //    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (self.completionHandler) {
        self.completionHandler(nil, data, nil);
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    self.finished = YES;
}

#pragma mark -
#pragma mark NSURLSessionTask
- (void)doNSURLSessionDataTaskGet {
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:self.request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (self.completionHandler) {
            self.completionHandler(response, data, error);
        }
    }];
    
    [task resume];
}

- (void)doNSURLSessionDataTaskPost {
    NSString *postStr = @"<?xml version=\"1.0\" encoding=\"utf-8\"?><soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\"><soap12:Body><GetMobileMisVersion xmlns=\"http://tempuri.org/\"><type>2</type></GetMobileMisVersion></soap12:Body></soap12:Envelope>";
    
    [self.request setHTTPMethod:@"POST"];
    [self.request setHTTPBody:[postStr dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:self.request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (self.completionHandler) {
            self.completionHandler(response, data, error);
        }
    }];
    
    [task resume];
}

- (void)doNSURLSessionDataTaskGetHttps {
    NSURLSessionConfiguration * config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:self.request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (self.completionHandler) {
            self.completionHandler(response, data, error);
        }
    }];
    
    [task resume];
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * __nullable credential))completionHandler {
    NSLog(@"%@",challenge.protectionSpace);
    // 如果是请求证书信任，我们再来处理，其他的不需要处理
    if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
        NSURLCredential *cre = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        // 调用block
        completionHandler(NSURLSessionAuthChallengeUseCredential,cre);
    }
}

/**
 *  有block的话不调这里来
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    NSLog(@"%@",[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
}

#pragma mark -
#pragma mark AFNetworking
- (void)doAFNetworkingGet {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
    manager.securityPolicy.allowInvalidCertificates = YES;
    [manager.securityPolicy setValidatesDomainName:NO];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/javascript", @"application/x-javascript", nil]];
    
    [manager GET:[self.url description] parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
        if (self.completionHandler) {
            self.completionHandler(nil, responseObject, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (self.completionHandler) {
            self.completionHandler(nil, nil, error);
        }
    }];
    
}

- (void)doAFNetworkingPost {
    NSString *postStr = @"<?xml version=\"1.0\" encoding=\"utf-8\"?><soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\"><soap12:Body><GetMobileMisVersion xmlns=\"http://tempuri.org/\"><type>2</type></GetMobileMisVersion></soap12:Body></soap12:Envelope>";
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/javascript", @"application/x-javascript", nil]];
    
    [self.request setHTTPMethod:@"POST"];
    [self.request setHTTPBody:[postStr dataUsingEncoding:NSUTF8StringEncoding]];
    
    [manager POST:[self.url description] parameters:postStr progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
        if (self.completionHandler) {
            self.completionHandler(nil, responseObject, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (self.completionHandler) {
            self.completionHandler(nil, nil, error);
        }
    }];
    
}

/**
 * 后台任务
 */
- (void)doAFNetworkingBackgroundGet {
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[[NSDate date] description]];
    configuration.networkServiceType = NSURLNetworkServiceTypeBackground;
    
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
    manager.securityPolicy.allowInvalidCertificates = YES;
    [manager.securityPolicy setValidatesDomainName:NO];
    manager.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/javascript", @"application/x-javascript", nil]];
    
    
    [manager GET:[self.url description] parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (self.completionHandler) {
            self.completionHandler(nil, responseObject, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (self.completionHandler) {
            self.completionHandler(nil, nil, error);
        }
    }];
    
}

#pragma mark -
#pragma mark ASIHttpRequest
- (void)doASIHttpRequestGet {
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:self.url];
    [request setRequestMethod: @"GET"];
    [request setShouldPresentCredentialsBeforeChallenge:YES];
    [request setShouldPresentAuthenticationDialog:YES];
    [request setUseKeychainPersistence:YES];
    [request setValidatesSecureCertificate:NO];
    [request startSynchronous];
    
    if (self.completionHandler) {
        self.completionHandler(nil, request.responseData, request.error);
    }
}

- (void)doASIHttpRequestPost {
    NSString *postStr = @"<?xml version=\"1.0\" encoding=\"utf-8\"?><soap12:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap12=\"http://www.w3.org/2003/05/soap-envelope\"><soap12:Body><GetMobileMisVersion xmlns=\"http://tempuri.org/\"><type>2</type></GetMobileMisVersion></soap12:Body></soap12:Envelope>";
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:self.url];
    [request setRequestMethod:@"POST"];
    [request setShouldPresentCredentialsBeforeChallenge:YES];
    [request setShouldPresentAuthenticationDialog:YES];
    [request setUseKeychainPersistence:YES];
    [request setValidatesSecureCertificate:NO];
    NSMutableData *data = [NSMutableData dataWithData:[postStr dataUsingEncoding:NSUTF8StringEncoding]];
    [request setPostBody:data];
    [request startSynchronous];
    
    if (self.completionHandler) {
        self.completionHandler(nil, request.responseData, request.error);
    }
}

#pragma mark -
#pragma mark BSDSocket
- (void)doBSDSocketGet {
    const char *httpRequeset = "GET %s HTTP/1.0\r\n"
    "Accept: application/xaml+xml\r\n"
    "Accept-Language: zh-cn\r\n"
    "Accept-Encoding: deflate\r\n"
    "User-Agent: Mozilla/4.0\r\n"
    "Host: %s\r\n"
    "Connection: close\r\n\r\n";
    
    int sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd == -1) {
        NSLog(@"socket failed int httpRequest!");
        return;
    }
    
    int port = self.url.port ? self.url.port.intValue : 80;
    NSString *path = (self.url.path && ![self.url.path isEqualToString:@""]) ? self.url.path : @"/";
    char buffer[4096];
    struct sockaddr_in addr = {0};
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    in_addr_t inaddr = INADDR_NONE;
    
    if ((inaddr = inet_addr(self.url.host.UTF8String)) != INADDR_NONE) {
        addr.sin_addr.s_addr = inaddr;
        
        
        struct addrinfo hints, *res, *res0;
        int err = getaddrinfo(self.url.host.UTF8String, "http", &hints, &res0);
        if (err) {
            gai_strerror(err);
            NSLog(@"getaddrinfo fail<%@>", self.url.host);
            goto failed;
        }
        
        for (res = res0; res; res = res->ai_next) {
            if (res->ai_socktype != SOCK_STREAM) {
                continue;
            }
            sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
            if (connect(sockfd, res->ai_addr, res->ai_addrlen) < 0) {
                NSLog(@"connect socket failed!");
                continue;
            }
            
            NSLog(@"socket family:%d socktype:%d protocol:%d",res->ai_family, res->ai_socktype, res->ai_protocol);
            
            char ipv6[100];
            struct sockaddr_in6 sock = *(struct sockaddr_in6 *)(res->ai_addr);
            const char *ipv6_str = inet_ntop(PF_INET6, (void *)&sock.sin6_addr, ipv6, 100);
            printf("%s", ipv6_str);
            goto ipv6;
        }
    } else {
        struct addrinfo hints, *res, *res0;
        memset(&hints, 0, sizeof(hints));
        hints.ai_family = PF_UNSPEC;
        hints.ai_socktype = SOCK_STREAM;
        int err = getaddrinfo(self.url.host.UTF8String, "http", &hints, &res0);
        if (err) {
            NSLog(@"getaddrinfo fail<%@>", self.url.host);
            goto failed;
        }
        
        for (res = res0; res; res = res->ai_next) {
            sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
            if (connect(sockfd, res->ai_addr, res->ai_addrlen) < 0) {
                NSLog(@"connect socket failed!");
                continue;
            }
            
            goto ipv6;
        }
    }
    
    if (connect(sockfd, (struct sockaddr *)&addr ,sizeof(struct sockaddr_in)) < 0) {
        NSLog(@"connect socket failed!");
        goto failed;
    }
ipv6:
    snprintf(buffer, sizeof(buffer) - 1, httpRequeset, path.UTF8String, self.url.host.UTF8String);
    buffer[sizeof(buffer) - 1] = 0;
    
    if (write(sockfd, buffer, strlen(buffer)) < 0) {
        NSLog(@"write failed");
        goto failed;
    }
    
    if (recv(sockfd, buffer, sizeof(buffer) - 1, 0) < 0) {
        NSLog(@"recv failed, %d %s", errno, strerror(errno));
        goto failed;
    }
    
    
    if (self.completionHandler) {
        NSString *responseStr = [[NSString alloc] initWithUTF8String:buffer];
        self.completionHandler(nil, responseStr, nil);
    }
    
failed:
    if (sockfd != -1) {
        close(sockfd);
    }
}

- (void)doBSDSocketPost {
    const char *httpRequeset = "POST %s HTTP/1.0\r\n"
    "Accept: application/xaml+xml\r\n"
    "Accept-Language: zh-cn\r\n"
    "Accept-Encoding: deflate\r\n"
    "User-Agent: Mozilla/4.0\r\n"
    "Host: %s\r\n"
    "Connection: close\r\n\r\n";
    
    int sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd == -1) {
        NSLog(@"socket failed int httpRequest!");
        return;
    }
    
    int port = self.url.port ? self.url.port.intValue : 80;
    NSString *path = (self.url.path && ![self.url.path isEqualToString:@""]) ? self.url.path : @"/";
    char buffer[4096];
    struct sockaddr_in addr = {0};
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    in_addr_t inaddr = INADDR_NONE;
    
    if ((inaddr = inet_addr(self.url.host.UTF8String)) != INADDR_NONE) {
        addr.sin_addr.s_addr = inaddr;
    } else {
        //        struct hostent *hostent = gethostbyname(self.url.host.UTF8String);
        //        if (hostent != NULL)  {
        //            if ((hostent->h_addrtype == AF_INET) &&
        //                (hostent->h_addr_list != NULL)) {
        //                inaddr = *((uint32_t *)(hostent->h_addr_list[0]));
        //            }
        //        }
        //
        //        if (inaddr == INADDR_NONE) {
        //            NSLog(@"gethostbyname failed<%@>", self.url.host);
        //            goto failed;
        //        } else {
        //            addr.sin_addr.s_addr = inaddr;
        //        }
        struct addrinfo hints, *res, *res0;
        memset(&hints, 0, sizeof(hints));
        hints.ai_family = PF_UNSPEC;
        hints.ai_socktype = SOCK_STREAM;
        int err = getaddrinfo(self.url.host.UTF8String, "http", &hints, &res0);
        if (err) {
            NSLog(@"getaddrinfo fail<%@>", self.url.host);
            goto failed;
        }
        
        for (res = res0; res; res = res->ai_next) {
            sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
            if (connect(sockfd, res->ai_addr, res->ai_addrlen) < 0) {
                NSLog(@"connect socket failed!");
                continue;
            }
            
            goto ipv6;
        }
    }
    
    if (connect(sockfd, (struct sockaddr *)&addr ,sizeof(struct sockaddr_in)) < 0) {
        NSLog(@"connect socket failed!");
        goto failed;
    }
ipv6:
    snprintf(buffer, sizeof(buffer) - 1, httpRequeset, path.UTF8String, self.url.host.UTF8String);
    buffer[sizeof(buffer) - 1] = 0;
    
    if (write(sockfd, buffer, strlen(buffer)) < 0) {
        NSLog(@"write failed");
        goto failed;
    }
    
    if (recv(sockfd, buffer, sizeof(buffer) - 1, 0) < 0) {
        NSLog(@"recv failed");
        goto failed;
    }
    
    
    if (self.completionHandler) {
        NSString *responseStr = [[NSString alloc] initWithUTF8String:buffer];
        self.completionHandler(nil, responseStr, nil);
    }
    
failed:
    if (sockfd != -1) {
        close(sockfd);
    }
}

char* getIPAddress()
{
    
    char *address = NULL;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            //            if(temp_addr->ifa_addr->sa_family == AF_INET) {
            // Check if interface is en0 which is the wifi connection on the iPhone
            if(!strcmp(temp_addr->ifa_name, "en0")) {
                // Get NSString from C String
                //                address = inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr);
                char ip[200] = {0};
                if (temp_addr->ifa_addr->sa_family == AF_INET) {
                    inet_ntop(temp_addr->ifa_addr->sa_family, temp_addr->ifa_addr->sa_data+2, ip, 200);
                } else if (temp_addr->ifa_addr->sa_family == AF_INET6) {
                    inet_ntop(temp_addr->ifa_addr->sa_family, temp_addr->ifa_addr->sa_data+6, ip, 200);
                } else {
                    temp_addr = temp_addr->ifa_next;
                    continue;
                }
                printf("ip: %s\n", ip);
            }
            //            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

- (void)testIPV6 {
    char *ipAddr = getIPAddress();
    
    
    
    uint8_t ipv4[4] = {200, 200, 0, 17};
    struct addrinfo hints, *res, *res0;
    int error, s;
    const char *cause = NULL;
    
    char ipv4_str_buf[INET_ADDRSTRLEN] = { 0 };
    const char *ipv4_str = inet_ntop(AF_INET, &ipv4, ipv4_str_buf, sizeof(ipv4_str_buf));
    
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = PF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    //    hints.ai_flags = AI_NUMERICSERV;
    error = getaddrinfo("200.200.72.229", "http", &hints, &res0);
    if (error) {
        errx(1, "%s", gai_strerror(error));
        /*NOTREACHED*/
    }
    s = -1;
    for (res = res0; res; res = res->ai_next) {
        s = socket(res->ai_family, res->ai_socktype,
                   res->ai_protocol);
        if (s < 0) {
            cause = "socket";
            continue;
        }
        
        if (connect(s, res->ai_addr, res->ai_addrlen) < 0) {
            cause = "connect";
            close(s);
            s = -1;
            continue;
        }
        char ipv6[100];
        struct sockaddr_in6 sock = *(struct sockaddr_in6 *)(res->ai_addr);
        const char *ipv6_str = inet_ntop(PF_INET6, (void *)&sock.sin6_addr, ipv6, 100);
        printf("%s", ipv6_str);
        
        
        //        char ip[] = "192.168.0.74";
        //        struct in_addr addr;
        //
        //        int ret = inet_pton(AF_INET, ip, (void *)&addr);   //IP字符串 ——》网络字节流
        //        if(0 == ret){
        //            printf("inet_pton error, return 0/n");
        //        }else{
        //            printf("inet_pton ip: %u/n", addr.s_addr);
        //            printf("inet_pton ip: 0x%x/n", addr.s_addr);
        //        }
        //
        //        const char *pstr = inet_ntop(AF_INET, (void *)&addr, ip, 128);  //网络字节流 ——》IP字符串
        //        if(NULL == pstr){
        //            printf("inet_ntop error, return NULL/n");
        //        }else{
        //            printf("inet_ntop ip: %s/n", ip);
        //        }
        
        
        
        
        break;  /* okay we got one */
    }
    if (s < 0) {
        //        err(1, "%s", cause);
        /*NOTREACHED*/
    }
    freeaddrinfo(res0);
}

#pragma mark -
#pragma mark CFSocket
- (void)doCFSocketGet
{
    CFSocketContext context = {
        0, NULL, NULL, NULL, NULL
    };
    context.info = (__bridge void *)(self);
    CFSocketRef _socket = CFSocketCreate(kCFAllocatorDefault,
                                         PF_INET,
                                         SOCK_STREAM,
                                         IPPROTO_TCP,
                                         kCFSocketConnectCallBack,
                                         TCPClientConnectCallBack,
                                         &context);
    if(_socket != NULL) {
        int port = self.url.port ? self.url.port.intValue : 80;
        struct sockaddr_in addr;   // IPV4
        memset(&addr, 0, sizeof(addr));
        addr.sin_len = sizeof(addr);
        addr.sin_family = AF_INET;
        addr.sin_port = htons(port);
        addr.sin_addr.s_addr = inet_addr([self.url.host UTF8String]);  // 把字符串的地址转换为机器可识别的网络地址
        
        // 把sockaddr_in结构体中的地址转换为Data
        CFDataRef address = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&addr, sizeof(addr));
        CFSocketError err = CFSocketConnectToAddress(_socket, // 连接的socket
                                                     address, // CFDataRef类型的包含上面socket的远程地址的对象
                                                     -1      // 连接超时时间，如果为负，则不尝试连接，而是把连接放在后台进行，如果_socket消息类型
                                                     // 为kCFSocketConnectCallBack，将会在连接成功或失败的时候在后台触发回调函数
                                                     );
        
        if (err == kCFSocketError) {
            NSLog(@"Connect error.");
        } else {
            NSLog(@"connect ok");
        }
        
        CFRunLoopRef cRunRef = CFRunLoopGetCurrent();    // 获取当前线程的循环
        // 创建一个循环，但并没有真正加如到循环中，需要调用CFRunLoopAddSource
        CFRunLoopSourceRef sourceRef = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socket, 0);
        CFRunLoopAddSource(cRunRef, // 运行循环
                           sourceRef,  // 增加的运行循环源, 它会被retain一次
                           kCFRunLoopCommonModes  // 增加的运行循环源的模式
                           );
        CFRelease(sourceRef);
        
        while (YES) {
            CFRunLoopRun();
            break;
        }
        
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), sourceRef, kCFRunLoopCommonModes);
        CFRelease(sourceRef);
    }
    
    
}
@end

