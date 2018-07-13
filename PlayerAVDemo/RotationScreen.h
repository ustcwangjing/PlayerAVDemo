//
//  RotationScreen.h
//  PlayerAVDemo
//
//  Created by wangjing on 2017/8/1.
//  Copyright © 2017年 wangjing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface RotationScreen : NSObject


/**
 *  切换横竖屏
 *
 *  @param orientation UIInterfaceOrientation
 */
+ (void)forceOrientation:(UIInterfaceOrientation)orientation;

/**
 *  是否是横屏
 *
 *  @return 是 返回yes
 */
+ (BOOL)isOrientationLandscape;



@end
