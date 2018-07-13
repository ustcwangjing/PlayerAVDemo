//
//  NSString+time.h
//  PlayerAVDemo
//
//  Created by wangjing on 2017/8/1.
//  Copyright © 2017年 wangjing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface NSString (time)


// 播放器时间转换
+ (NSString *)convertTime:(CGFloat)second;

@end
