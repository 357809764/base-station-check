//
//  MaskView.m
//  VPNDemo
//
//  Created by Yuanliang Fu on 2018/8/26.
//  Copyright © 2018年 sangfor. All rights reserved.
//

#import "MaskView.h"

@implementation MaskView



- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970] * 1000;
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self) {
        if (interval - _preTime < 500.0) {
            _count++;
            if (_count >= 9) {
                NSLog(@"count222 %d : %f %f", _count, _preTime, interval);
                self.superview.hidden = YES;
               _count = 0;
            }
        } else {
            _count = 0;
        }
        _preTime = interval;
        return nil;
    }
    return view;
}


@end
