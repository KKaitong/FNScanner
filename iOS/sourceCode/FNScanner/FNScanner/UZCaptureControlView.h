//
//  UZCaptureControlView.h
//  FNScanner
//
//  Created by 郑连乐 on 2018/2/24.
//  Copyright © 2018年 apicloud. All rights reserved.
//

#import <UIKit/UIKit.h>

#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height

@interface UZCaptureControlView : UIView

/** 返回按钮 */
@property (nonatomic, weak) UIButton * backButton;
/** 相册按钮 */
@property (nonatomic, weak) UIButton * albumButton;
/** 闪光灯开启按钮 */
@property (nonatomic, weak) UIButton * lightOnButton;
/** 闪光灯关闭按钮 */
@property (nonatomic, weak) UIButton * lightCloseButton;

- (void)changeToPortrait;
- (void)changedVertical;
- (void)startScanAnimation;
- (void)removeScanAnimation;

@end
