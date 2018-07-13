//
//  NSString+time.m
//  PlayerAVDemo
//
//  Created by wangjing on 2017/8/1.
//  Copyright © 2017年 wangjing. All rights reserved.
//

#import "NSString+time.h"

@implementation NSString (time)


+ (NSString *)convertTime:(CGFloat)second {
    // 相对格林时间
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:second];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    if (second / 3600 >= 1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    } else {
        [formatter setDateFormat:@"mm:ss"];
    }
    
    NSString *showTimeNew = [formatter stringFromDate:date];
    return showTimeNew;
}

@end
