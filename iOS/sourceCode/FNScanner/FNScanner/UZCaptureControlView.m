//
//  UZCaptureControlView.m
//  FNScanner
//
//  Created by 郑连乐 on 2018/2/24.
//  Copyright © 2018年 apicloud. All rights reserved.
//

#import "UZCaptureControlView.h"

#define iPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)
#define ScanAnimationDuration 2.0

static NSString * const kUZCaptureControlViewAnimationScan = @"kUZCaptureControlViewAnimationScan";

@interface UZCaptureControlView()

@property (nonatomic, weak) UIView * upView;
@property (nonatomic, weak) UIView * downView;
@property (nonatomic, weak) UIView * leftView;
@property (nonatomic, weak) UIView * rightView;
@property (nonatomic, weak) UIImageView * imageView;

@end 

@implementation UZCaptureControlView

#pragma mark - override

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        [self setUpSubview];
    }
    return self;
}

#pragma mark - interface

- (void)startScanAnimation
{
    CGFloat upViewHeight = 156 * ScreenHeight / 667;
    CGFloat downViewHeight = 214 * ScreenHeight / 667;
    
    [self startScanAnimationWithFromValue:@(upViewHeight) toValue:@(ScreenHeight - downViewHeight)];
}

- (void)removeScanAnimation
{
    if ([self.imageView.layer animationForKey:kUZCaptureControlViewAnimationScan]) {
        [self.imageView.layer removeAnimationForKey:kUZCaptureControlViewAnimationScan];
    }
}

- (void)changeToPortrait
{
    CGFloat width = ScreenWidth;
    CGFloat height = ScreenHeight;
    if (width > height) {
        width = ScreenHeight;
        height = ScreenWidth;
    }
    
    // 上
    CGFloat upViewHeight = 156 * height / 667;
    self.upView.frame = CGRectMake(0, 0, width, upViewHeight);
    
    // 下
    CGFloat downViewHeight = 214 * height / 667;
    self.downView.frame = CGRectMake(0, height - downViewHeight, width, downViewHeight);
    
    // 左
    CGFloat leftViewWidth = 45 * width / 375;
    self.leftView.frame = CGRectMake(0, upViewHeight, leftViewWidth, height - upViewHeight - downViewHeight);
    
    // 右
    self.rightView.frame = CGRectMake(width - leftViewWidth, upViewHeight, leftViewWidth, height - upViewHeight - downViewHeight);
    
    // 四个角
    CGFloat marginH = width - leftViewWidth * 2 - 18;
    CGFloat marginV = height - upViewHeight - downViewHeight - 18;
    for (int i = 0; i < 4; i++) {
        UIImageView * imageView = (UIImageView *)[self viewWithTag:i + 100];
        imageView.frame = CGRectMake(leftViewWidth + (i % 2) * marginH, upViewHeight + (i / 2) * marginV, 18, 18);
    }
    
    // 返回按钮
    self.backButton.frame =  iPhoneX ? CGRectMake(0, 29 + 24, 40, 40) : CGRectMake(0, 29, 40, 40);
    
    // 相册按钮
    self.albumButton.frame = iPhoneX ? CGRectMake(width - 8.5 - 40, 29.5 + 24, 40, 40) : CGRectMake(width - 8.5 - 40, 29.5, 40, 40);
    
    // 打开闪光灯
    UIView * lightOnView = [self viewWithTag:105];
    lightOnView.frame = CGRectMake(width * 0.5 -28, height - downViewHeight - 10 - 52, 56, 52);
    
    // 关闭闪光灯
//    UIView * lightCloseView = [self viewWithTag:104];
//    lightCloseView.frame = CGRectMake(CGRectGetMaxX(lightOnView.frame) + 20, CGRectGetMinY(lightOnView.frame), 56, 52);
    
    // 文字提示
    UILabel * tipLabel = [self viewWithTag:106];
    tipLabel.frame = CGRectMake(0,height - downViewHeight + 20, width, 15);
    
    // 重置扫描条动画
    [self removeScanAnimation];
    self.imageView.frame = CGRectMake(leftViewWidth + 5, upViewHeight, width - leftViewWidth * 2 - 5 * 2, 3);
    self.imageView.image = [self getImage:@"saomiao"];
    [self startScanAnimationWithFromValue:@(upViewHeight) toValue:@(height - downViewHeight)];
}

- (void)changedVertical
{
    CGFloat width = ScreenWidth;
    CGFloat height = ScreenHeight;
    if (width < height) {
        width = ScreenHeight;
        height = ScreenWidth;
    }
    
    // 上
    CGFloat upViewHeight = 45 * height / 375;
    self.upView.frame = CGRectMake(0, 0, width, upViewHeight);
    
    // 下
    self.downView.frame = CGRectMake(0, height - upViewHeight, width, upViewHeight);
    
    // 左
    CGFloat leftViewWidth = 120 * width / 667;
    self.leftView.frame = CGRectMake(0, upViewHeight, leftViewWidth, height - upViewHeight * 2);
    
    // 右
    self.rightView.frame = CGRectMake(width - leftViewWidth, upViewHeight, leftViewWidth, height - upViewHeight * 2);
    
    // 四个角
    CGFloat marginH = width - leftViewWidth * 2 - 18;
    CGFloat marginV = height - upViewHeight * 2 - 18;
    for (int i = 0; i < 4; i++) {
        UIImageView * imageView = (UIImageView *)[self viewWithTag:i + 100];
        imageView.frame = CGRectMake(leftViewWidth + (i % 2) * marginH, upViewHeight + (i / 2) * marginV, 18, 18);
    }
    
    // 返回按钮
    self.backButton.frame =  iPhoneX ? CGRectMake(44, 29, 40, 40) : CGRectMake(0, 29, 40, 40);
    
    // 相册按钮
    self.albumButton.frame = iPhoneX ? CGRectMake(width - 8.5 - 40 - 44, 29.5, 40, 40) : CGRectMake(width - 8.5 - 40, 29.5, 40, 40);
    
    // 打开闪光灯
    UIView * lightOnView = [self viewWithTag:105];
    lightOnView.frame = CGRectMake(width * 0.5 -28, height - upViewHeight - 10 - 52, 56, 52);
    
    // 关闭闪光灯
//    UIView * lightCloseView = [self viewWithTag:104];
//    lightCloseView.frame = CGRectMake(CGRectGetMaxX(lightOnView.frame) + 20, CGRectGetMinY(lightOnView.frame), 56, 52);
    
    // 文字提示
    UILabel * tipLabel = [self viewWithTag:106];
    tipLabel.frame = CGRectMake(0,height - upViewHeight + 20, width, 15);
    
    // 重置扫描条动画
    [self removeScanAnimation];
    self.imageView.frame = CGRectMake(leftViewWidth + 5, upViewHeight, width - leftViewWidth * 2 - 5 * 2, 3);
    self.imageView.image = [self getImage:@"saomiaov"];
    [self startScanAnimationWithFromValue:@(upViewHeight) toValue:@(height - upViewHeight)];
}

#pragma mark - private

- (void)setUpSubview
{
    // 上
    CGFloat upViewHeight = 156 * ScreenHeight / 667;
    UIView * upView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, upViewHeight)];
    upView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
    [self addSubview:upView];
    self.upView = upView;
    
    // 下
    CGFloat downViewHeight = 214 * ScreenHeight / 667;
    UIView * downView = [[UIView alloc] initWithFrame:CGRectMake(0, ScreenHeight - downViewHeight, ScreenWidth, downViewHeight)];
    downView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
    [self addSubview:downView];
    self.downView = downView;
    
    // 左
    CGFloat leftViewWidth = 45 * ScreenWidth / 375;
    UIView * leftView = [[UIView alloc] initWithFrame:CGRectMake(0, upViewHeight, leftViewWidth, ScreenHeight - upViewHeight - downViewHeight)];
    leftView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
    [self addSubview:leftView];
    self.leftView = leftView;
    
    // 右
    UIView * rightView = [[UIView alloc] initWithFrame:CGRectMake(ScreenWidth - leftViewWidth, upViewHeight, leftViewWidth, ScreenHeight - upViewHeight - downViewHeight)];
    rightView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
    [self addSubview:rightView];
    self.rightView = rightView;
    
    // 返回按钮
    UIButton * backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setImage:[self getImage:@"back"] forState:UIControlStateNormal];
    backButton.frame =  iPhoneX ? CGRectMake(0, 29 + 24, 40, 40) : CGRectMake(0, 29, 40, 40);
    [self addSubview:backButton];
    self.backButton = backButton;
    
    // 相册按钮
    UIButton * albumButton = [UIButton buttonWithType:UIButtonTypeCustom];
    albumButton.frame = iPhoneX ? CGRectMake(ScreenWidth - 8.5 - 40, 29.5 + 24, 40, 40) : CGRectMake(ScreenWidth - 8.5 - 40, 29.5, 40, 40);
    [albumButton setTitle:@"相册" forState:UIControlStateNormal];
    [albumButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    albumButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
    [self addSubview:albumButton];
    self.albumButton = albumButton;
    
    // 打开闪光灯
    UIView * lightOnView = [[UIView alloc] initWithFrame:CGRectMake(ScreenWidth * 0.5 -28, ScreenHeight - downViewHeight - 10 - 52, 56, 52)];
    [self addSubview:lightOnView];
    lightOnView.tag = 105;
    
    UIButton * lightOnButton = [UIButton buttonWithType:UIButtonTypeCustom];
    lightOnButton.frame = CGRectMake(8, 0, 40, 38);
    [lightOnButton setImage:[self getImage:@"lighton"] forState:UIControlStateNormal];
    [lightOnButton setImage:[self getImage:@"lightno"] forState:UIControlStateSelected];
    [lightOnView addSubview:lightOnButton];
    self.lightOnButton = lightOnButton;
    
    UILabel * lightOnLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 38, 56, 14)];
    lightOnLabel.text = @"轻触照亮";
    lightOnLabel.textAlignment = NSTextAlignmentCenter;
    lightOnLabel.textColor = [UIColor whiteColor];
    lightOnLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
    [lightOnView addSubview:lightOnLabel];
    lightOnLabel.tag = 110;
    
    // 关闭闪光灯
//    UIView * lightCloseView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(lightOnView.frame) + 20, CGRectGetMinY(lightOnView.frame), 56, 52)];
//    [self addSubview:lightCloseView];
//    lightCloseView.tag = 104;
//
//    UIButton * lightCloseButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    lightCloseButton.frame = CGRectMake(8, 0, 40, 38);
//    [lightCloseButton setImage:[self getImage:@"lightno"] forState:UIControlStateNormal];
//    [lightCloseView addSubview:lightCloseButton];
//    self.lightCloseButton = lightCloseButton;
//
//    UILabel * lightCloseLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 38, 56, 14)];
//    lightCloseLabel.text = @"轻触关闭";
//    lightCloseLabel.textAlignment = NSTextAlignmentCenter;
//    lightCloseLabel.textColor = [UIColor whiteColor];
//    lightCloseLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
//    [lightCloseView addSubview:lightCloseLabel];
    
    // 文字提示
    UILabel * tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,ScreenHeight - downViewHeight + 20, ScreenWidth, 15)];
    tipLabel.text = @"对准条形码/二维码，即可自动扫描";
    tipLabel.textColor = [UIColor whiteColor];
    tipLabel.textAlignment = NSTextAlignmentCenter;
    tipLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
    [self addSubview:tipLabel];
    tipLabel.tag = 106;
    
    // 四个角
    NSArray * imageArr = @[@"leftup",@"rightup",@"leftdown",@"rightdown"];
    CGFloat marginH = ScreenWidth - leftViewWidth * 2 - 18;
    CGFloat marginV = ScreenHeight - upViewHeight - downViewHeight - 18;
    for (int i = 0; i < 4; i++) {
        UIImageView * imageView = [[UIImageView alloc] init];
        imageView.image = [self getImage:imageArr[i]];
        imageView.frame = CGRectMake(leftViewWidth + (i % 2) * marginH, upViewHeight + (i / 2) * marginV, 18, 18);
        imageView.userInteractionEnabled = YES;
        imageView.tag = i + 100;
        [self addSubview:imageView];
    }
    
    // 扫描条
    UIImageView * imageView = [[UIImageView alloc] init];
    imageView.image = [self getImage:@"saomiao"];
    imageView.frame = CGRectMake(leftViewWidth + 5, upViewHeight, ScreenWidth - leftViewWidth * 2 - 5 * 2, 3);
    [self addSubview:imageView];
    self.imageView = imageView;
}

- (void)startScanAnimationWithFromValue:(id)fromValue toValue:(id)toValue
{
    CABasicAnimation * basicAnimation = [CABasicAnimation animation];
    basicAnimation.keyPath = @"position.y";
    basicAnimation.fromValue = fromValue;
    basicAnimation.toValue = toValue;
    basicAnimation.removedOnCompletion = NO;
    basicAnimation.duration = ScanAnimationDuration;
    basicAnimation.repeatCount = MAXFLOAT;
    [self.imageView.layer addAnimation:basicAnimation forKey:kUZCaptureControlViewAnimationScan];
}

- (UIImage *)getImage:(NSString *)fileName
{
    NSString *pathName = [NSString stringWithFormat:@"res_FNScanner/%@",fileName];
    NSString *path = [[NSBundle mainBundle] pathForResource:pathName ofType:@"png"];
    return [UIImage imageWithContentsOfFile:path];
}

@end
