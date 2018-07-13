//
//  ViewController.m
//  PlayerAVDemo
//
//  Created by wangjing on 2017/7/31.
//  Copyright © 2017年 wangjing. All rights reserved.
//

#import "ViewController.h"
#import "AGPlayerView.h"

#define MovieURL @"http://baobab.wdjcdn.com/1457546796853_5976_854x480.mp4"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *h5String = [NSString stringWithFormat:MovieURL];
    NSURL *url = [NSURL URLWithString:h5String];
    [self.playerView updatePlayerWithURL:url];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
