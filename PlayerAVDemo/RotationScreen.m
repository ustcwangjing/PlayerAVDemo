//
//  RotationScreen.m
//  PlayerAVDemo
//
//  Created by wangjing on 2017/8/1.
//  Copyright © 2017年 wangjing. All rights reserved.
//

#import "RotationScreen.h"

@implementation RotationScreen


//
+ (void)forceOrientation:(UIInterfaceOrientation)orientation {
    // setOrientation: 私有方法强制横屏
    if( [[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)])
    {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = orientation;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}

//
+ (BOOL)isOrientationLandscape {
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
    {
        return YES;
    }
    else
    {
        return NO;
    }
}



@end
