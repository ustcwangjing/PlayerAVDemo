//
//  AGPlayerView.m
//  PlayerAVDemo
//
//  Created by wangjing on 2017/7/31.
//  Copyright © 2017年 wangjing. All rights reserved.
//

#import "AGPlayerView.h"
#import "NSString+time.h"
#import "RotationScreen.h"
#import "Masonry.h"



#define RGBColor(r,g,b) [UIColor colorWithRed: r / 255.0 green: g / 255.0 blue: b / 255.0 alpha:1.0]


@interface AGPlayerView ()
{
    BOOL _isIntoBackground; // 是否在后台
    BOOL _isShowToolbar; // 是否显示工具条
    BOOL _isSliding; // 是否正在滑动
    AVPlayerItem *_playerItem;
    AVPlayerLayer *_playerLayer;
    NSTimer *_timer;
    id _playTimeObserver; // 观察者
}


@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (strong, nonatomic) IBOutlet UIView *playerView;

@property (strong, nonatomic) IBOutlet UIView *topView;
@property (strong, nonatomic) IBOutlet UIButton *moreButton;

@property (strong, nonatomic) IBOutlet UIView *downView;
@property (strong, nonatomic) IBOutlet UIButton *playButton;
@property (strong, nonatomic) IBOutlet UILabel *beginLabel;
@property (strong, nonatomic) IBOutlet UILabel *endLabel;
@property (strong, nonatomic) IBOutlet UISlider *playProgress;
@property (strong, nonatomic) IBOutlet UIProgressView *loadedProgress; // 缓冲进度条
@property (strong, nonatomic) IBOutlet UIButton *rotationButton;

@property (strong, nonatomic) IBOutlet UIButton *playerButton;
@property (strong, nonatomic) IBOutlet UIButton *playerFullScreenButton;

@property (strong, nonatomic) IBOutlet UIView *inspectorView; // 继续播放/暂停播放
@property (strong, nonatomic) IBOutlet UILabel *inspectorLabel; //

// 约束动画
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *topViewTop;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *downViewBottom;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *inspectorViewHeight;


@end


@implementation AGPlayerView

-(void) awakeFromNib
{
    [super awakeFromNib];
    //UISlide
    self.playProgress.value = 0.0;
    [self.playProgress setThumbImage:[UIImage imageNamed:@"icmpv_thumb_light"] forState:UIControlStateNormal];
    
    //设置进度条
    self.loadedProgress.progress = 0.0;
    self.inspectorView.backgroundColor = [RGBColor(203, 201, 204) colorWithAlphaComponent:0.5];

}


-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        //加载xib文件
        self.mainView = [[[NSBundle mainBundle] loadNibNamed:@"AGPlayerView" owner:self options:nil] lastObject];
        [self  addSubview:self.mainView];
        
        //设置播放器
        self.player = [[AVPlayer alloc] init]; //播放器控制类
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];  //播放器View类
        [self.playerView.layer addSublayer:_playerLayer]; //添加View视图框架中
        
        //播放器控制栏前置
        [self.playerView bringSubviewToFront:self.topView];
        [self.playerView bringSubviewToFront:self.downView];
        [self.playerView bringSubviewToFront:self.playerButton];
        [self.playerView bringSubviewToFront:self.playerFullScreenButton];
        
        //后置
        [self.playerView sendSubviewToBack:self.inspectorView];
        
        
        [self setProtraitLayout];
        
        NSLog(@"%d %.2f %.2f", __LINE__, self.playerView.bounds.size.width, self.playerView.bounds.size.height);
    }
    return self;
}


-(void) layoutSubviews
{
    [super layoutSubviews];
    _playerLayer.frame = self.bounds;

}

// 传入视频地址
- (void)updatePlayerWithURL:(NSURL *)url
{
    _playerItem = [AVPlayerItem playerItemWithURL:url];  //create item
    [_player replaceCurrentItemWithPlayerItem:_playerItem];  //replaceCurrentItem
    [self addObserverAndNotification];
}

/**
 *  添加观察者 、通知 、监听播放进度
 */
- (void)addObserverAndNotification {
    
    [_playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil]; // 观察status属性， 一共有三种属性
    [_playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil]; //观察缓存进度

    [self monitoringPlayback:_playerItem]; // 监听播放
    [self addNotification]; // 添加通知
}

//观察播放进度
- (void) monitoringPlayback:(AVPlayerItem*) item
{
    __weak typeof(self) WeakSelf = self;
    
    _playTimeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 30.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        if (_touchMode != TouchPlayerViewModeHorizontal)
        {
            float currentPlayTime = (double)item.currentTime.value / item.currentTime.timescale;
            if (_isSliding == NO)
            {
                [WeakSelf updateVideoSlider:currentPlayTime];
            }
        }
        else
        {
            return ;
        }
    }];
   
}

// 更新滑动条
- (void)updateVideoSlider:(float)currentTime {
    self.playProgress.value = currentTime;
    self.beginLabel.text = [NSString convertTime:currentTime];
}

- (void) addNotification
{
    //播放结束
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    //前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterForegroundNotification) name:UIApplicationWillEnterForegroundNotification object:nil];
    //后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackgroundNotification) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
}


- (void) playbackFinished:(NSNotification*) notification
{
     NSLog(@"视频播放完成通知");
     _playerItem = [notification object];
    [_playerItem seekToTime:kCMTimeZero];
}

// 移除通知
- (void)removeObserveAndNOtification
{
    [_player replaceCurrentItemWithPlayerItem:nil];
    [_playerItem removeObserver:self  forKeyPath:@"status"];
    [_playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [_player removeTimeObserver:_playTimeObserver];
    _playTimeObserver = nil;
    [[NSNotificationCenter defaultCenter ] removeObserver:self];
}

// 切换为横屏
- (void)setLandscapeLayout
{
    //暂时未实现
}

// 切换为竖屏
- (void)setProtraitLayout
{
    self.isLandscape = NO;
    
    //不隐藏工具条
    [self portraitShow];
    //hideInspector
    self.inspectorViewHeight.constant = 0.0f;
    [self layoutIfNeeded];
    
}

- (void)portraitShow
{
    _isShowToolbar = YES;
    
    //约束动画
    self.topViewTop.constant = 0;
    self.downViewBottom.constant = 0;
    [UIView animateWithDuration:0.1 animations:^{
        [self layoutIfNeeded];
        self.topView.alpha = self.downView.alpha = 1;
        self.playerButton.alpha = self.playerFullScreenButton.alpha = 1;
    } completion:^(BOOL finished) {
        //do nothing
    }];
    
    //现实状态条
    [[UIApplication sharedApplication] setStatusBarHidden:NO animated:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
}


- (void)portraitHide
{
    _isShowToolbar = NO;
    //约束动画
    self.topViewTop.constant = -(self.topView.frame.size.height);
    self.downViewBottom.constant = -(self.downView.frame.size.height);
    [UIView animateWithDuration:0.1 animations:^{
        [self layoutIfNeeded];
        self.topView.alpha = self.downView.alpha = 0;
        self.playerButton.alpha = self.playerFullScreenButton.alpha = 0;
    } completion:^(BOOL finished) {
        //do nothing
    }];
    
    //隐藏状态条
    [[UIApplication sharedApplication] setStatusBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
}


- (void) inspectorViewShow
{
    [self.inspectorView.layer removeAllAnimations];
    if(_isPlaying)
    {
        self.inspectorLabel.text = @"继续播放";
    }
    else
    {
        self.inspectorLabel.text = @"暂停播放";
    }
    
    self.inspectorViewHeight.constant = 20.0f;
    [UIView animateWithDuration:0.3 animations:^{
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self performSelector:@selector(inspectorViewHide) withObject:nil afterDelay:1];
    }];

}

- (void)inspectorViewHide
{
    self.inspectorViewHeight.constant = 0.0f;
    [UIView animateWithDuration:0.3 animations:^{
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        
    }];
}

// 播放
- (void)play
{
    _isPlaying = YES;
    [_player play];
    [self.playButton setImage:[UIImage imageNamed:@"Stop"] forState:(UIControlStateNormal)];
    [self.playerButton setImage:[UIImage imageNamed:@"player_pause_iphone_window"] forState:(UIControlStateNormal)];
    [self.playerFullScreenButton setImage:[UIImage imageNamed:@"player_pause_iphone_fullscreen"] forState:(UIControlStateNormal)];
    
}

// 暂停
- (void)pause
{
    _isPlaying = NO;
    [_player pause];
    
    [self.playButton setImage:[UIImage imageNamed:@"Play"] forState:UIControlStateNormal];
    [self.playerButton setImage:[UIImage imageNamed:@"player_start_iphone_window"] forState:UIControlStateNormal];
    [self.playerFullScreenButton setImage:[UIImage imageNamed:@"player_start_iphone_fullscreen"] forState:UIControlStateNormal];
    
}


#pragma mark -  横竖屏切换
- (IBAction)rotationAction:(id)sender
{
    if ([RotationScreen isOrientationLandscape]) //如果是横屏
    {
        [RotationScreen forceOrientation:UIInterfaceOrientationPortrait];
    }
    else
    {
        [RotationScreen forceOrientation:UIInterfaceOrientationLandscapeRight];
    }
    
}




#pragma mark - KVO status
-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    AVPlayerItem *item = (AVPlayerItem*)object;
    if([keyPath isEqualToString:@"status"])
    {
        if (_isIntoBackground)
        {
            return;
        }
        else
        {
            AVPlayerStatus status = [[change  objectForKey:@"new"] intValue];
            if (status == AVPlayerStatusReadyToPlay)
            {
                NSLog(@"准备播放");
                CMTime duration = item.duration;
                NSLog(@"%.2f",CMTimeGetSeconds(duration));
                // 设置视频时间
                [self setMaxDuration:CMTimeGetSeconds(duration)];
                // 播放
                [self play];  
            }
            else if (status == AVPlayerStatusFailed)
            {
                 NSLog(@"AVPlayerStatusFailed");
            }
            else
            {
                 NSLog(@"AVPlayerStatusUnknown");
            }
        }
    }
    else if([keyPath isEqualToString:@"loadedTimeRanges"])
    {
        NSTimeInterval timeInterval = [self availableDurationRanges]; // 缓冲时间
        CGFloat totalDuration = CMTimeGetSeconds(_playerItem.duration); // 总时间
        [self.loadedProgress setProgress:timeInterval / totalDuration animated:YES];
    }

}

// 设置最大时间
- (void)setMaxDuration:(CGFloat)duration {
    self.playProgress.maximumValue = duration;       // maxValue = CMGetSecond(item.duration)
    self.endLabel.text = [NSString convertTime:duration];
}

// 已缓冲进度
- (NSTimeInterval)availableDurationRanges
{
    NSArray *loadedTimeRanges = [_playerItem loadedTimeRanges]; // 获取item的缓冲数组
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue]; // 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds; // 计算总缓冲时间 = start + duration
    return result;
}



- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    // 横竖屏切换时重新添加约束
    CGRect bounds = [UIScreen mainScreen].bounds;
    [_mainView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(@(0));
        make.width.equalTo(@(bounds.size.width));
        make.height.equalTo(@(bounds.size.height));
    }];
    if (self.traitCollection.verticalSizeClass != UIUserInterfaceSizeClassCompact)
    {
        //竖屏
        self.topView.backgroundColor = self.downView.backgroundColor = [UIColor clearColor];
        [self.rotationButton setImage:[UIImage imageNamed:@"player_fullScreen_iphone"] forState:(UIControlStateNormal)];
    }
    else //横屏
    {
        self.downView.backgroundColor = self.topView.backgroundColor = RGBColor(89, 87, 90);
        [self.rotationButton setImage:[UIImage imageNamed:@"player_window_iphone"] forState:(UIControlStateNormal)];
    }


}

#pragma mark - 处理点击事件
- (void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    _touchMode = TouchPlayerViewModeNone;
}

-(void) touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    // donothing
}

-(void) touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if(_touchMode == TouchPlayerViewModeNone)
    {
        if(_isLandscape)  //NO
        {
            
        }
        else
        {
            //竖屏
            if (_isShowToolbar)
            {
                [self portraitHide];
            }
            else
            {
                [self portraitShow];
            }
        }
    }

}


- (IBAction)playOrStopAction:(id)sender {
    if (_isPlaying) {
        [self pause];
    } else {
        [self play];
    }
    
    // inspectorAnimation
    [self inspectorViewShow];
}

- (IBAction)playerSliderTouchDown:(id)sender {
    [self pause];
}

// 不要拖拽的时候改变， 手指抬起来后缓冲完成再改变
- (IBAction)playerSliderValueChanged:(id)sender {
    _isSliding = YES;
    [self pause];
    // 跳转到拖拽秒处
    // self.playProgress.maxValue = value / timeScale
    // value = progress.value * timeScale
    // CMTimemake(value, timeScale) =  (progress.value, 1.0)
    CMTime changedTime = CMTimeMakeWithSeconds(self.playProgress.value, 1.0);
    NSLog(@"%.2f", self.playProgress.value);
    [_playerItem seekToTime:changedTime completionHandler:^(BOOL finished) {
        // 跳转完成后做某事
    }];
}

- (IBAction)playerSliderTouchUpInside:(id)sender {
    _isSliding = NO; // 滑动结束
    [self play];
}



-(void)dealloc
{
     [self removeObserveAndNOtification];

}



@end
