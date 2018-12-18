//
//  ViewController.m
//  WebViewRefresh
//
//  Created by Yuanliang Fu on 2018/11/28.
//  Copyright © 2018年 Yuanliang Fu. All rights reserved.
//

#import "ViewController.h"
#include "NetworkViewController.h"

@interface ViewController ()
@property (nonatomic, strong)   NetworkViewController   *networkController;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)onConnectBtnClicked:(id)sender {
    if (!_networkController) {
        self.networkController = [[NetworkViewController alloc] initWithNibName:@"NetworkViewController" bundle:nil];
    }
    
    [self.navigationController pushViewController:_networkController animated:NO];
    
//    [self presentModalViewController:self.networkController animated:NO]
    
//    self.watiTheacherViewController.transitioningDelegate = self;
//    [self presentViewController:self.watiTheacherViewController animated:YES completion:nil];
    [self presentViewController:self.networkController animated:NO completion:nil];
}

@end
