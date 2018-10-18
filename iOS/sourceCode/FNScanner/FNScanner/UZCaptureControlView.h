/**
  * APICloud Modules
  * Copyright (c) 2014-2018 by APICloud, Inc. All Rights Reserved.
  * Licensed under the terms of the The MIT License (MIT).
  * Please see the license.html included with this distribution for details.
  */

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

@property (nonatomic, copy) NSString *verticalLineColor;
@property (nonatomic, copy) NSString *landscapeLineColor;
@property (nonatomic, copy) NSString *hintText;
- (void)changeToPortrait;
- (void)changedVertical;
- (void)startScanAnimation;
- (void)removeScanAnimation;

@end
