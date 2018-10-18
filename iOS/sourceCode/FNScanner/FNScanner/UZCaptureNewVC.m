/**
  * APICloud Modules
  * Copyright (c) 2014-2018 by APICloud, Inc. All Rights Reserved.
  * Licensed under the terms of the The MIT License (MIT).
  * Please see the license.html included with this distribution for details.
  */

#import "UZCaptureNewVC.h"
#import "UZCaptureControlView.h"

#define iPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)

@interface UZCaptureNewVC ()

@property (nonatomic,weak) UZCaptureControlView * controlView;

@end

@implementation UZCaptureNewVC

#pragma mark - lazy

- (UZCaptureControlView *)controlView
{
    if (!_controlView) {
        UZCaptureControlView * controlView = [[UZCaptureControlView alloc] init];
        [self.view addSubview:controlView];
        controlView.hintText = self.hintText;
        controlView.verticalLineColor = self.verticalLineColor;
        controlView.landscapeLineColor = self.landscapeLineColor;
        _controlView = controlView;
    }
    return _controlView;
}

#pragma mark - override

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.controlView startScanAnimation];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.controlView removeScanAnimation];
}

- (void)initView
{
    self.controlView.frame = self.view.bounds;
    
    [self.controlView.backButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    [self.controlView.albumButton addTarget:self action:@selector(openAlbum:) forControlEvents:UIControlEventTouchUpInside];
    [self.controlView.lightOnButton addTarget:self action:@selector(light:) forControlEvents:UIControlEventTouchUpInside];
//    [self.controlView.lightCloseButton addTarget:self action:@selector(light:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupCamera
{
    [super setupCamera];
    
    CGFloat downViewHeight = 214 * ScreenHeight / 667;
    CGFloat arrowX = 45 * ScreenWidth / 375;
    CGFloat arrowY = 156 * ScreenHeight / 667;
    CGFloat arrowW = ScreenWidth - arrowX * 2;
    CGFloat arrowH = ScreenHeight - arrowY - downViewHeight;
    self.output.rectOfInterest = CGRectMake(arrowY/ScreenHeight, arrowX/ScreenWidth, arrowH/ScreenHeight, arrowW/ScreenWidth);
}

- (void)changeToPortrait
{
    CGFloat width = ScreenWidth;
    CGFloat height = ScreenHeight;
    if (width > height) {
        width = ScreenHeight;
        height = ScreenWidth;
    }
    
    CGFloat downViewHeight = 214 * height / 667;
    CGFloat arrowX = 45 * width / 375;
    CGFloat arrowY = 156 * height / 667;
    CGFloat arrowW = width - arrowX * 2;
    CGFloat arrowH = height - arrowY - downViewHeight;
    self.output.rectOfInterest = CGRectMake(arrowY/height, arrowX/width, arrowH/height, arrowW/width);
    
    self.controlView.frame = CGRectMake(0, 0, width, height);
    [self.controlView changeToPortrait];
}

- (void)changedVertical
{
    CGFloat width = ScreenWidth;
    CGFloat height = ScreenHeight;
    if (width < height) {
        width = ScreenHeight;
        height = ScreenWidth;
    }
    
    CGFloat arrowX = 120 * width / 667;
    CGFloat arrowY = 45 * height / 375;
    CGFloat arrowW = width - arrowX * 2;
    CGFloat arrowH = height - arrowY * 2;
    self.output.rectOfInterest = CGRectMake(arrowY/height, arrowX/width, arrowH/height, arrowW/width);
    
    self.controlView.frame = CGRectMake(0, 0, width, height);
    [self.controlView changedVertical];
}

#pragma mark - private

- (void)light:(UIButton *)button
{
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash]) {
            [device lockForConfiguration:nil];
            UILabel * label = (UILabel *)[button.superview viewWithTag:110];
            if (button.isSelected) { // 关闭闪光灯
                [device setTorchMode:AVCaptureTorchModeOff];
                [device setFlashMode:AVCaptureFlashModeOff];
                label.text = @"轻触照亮";
            } else { // 打开闪光灯
                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureFlashModeOn];
                label.text = @"轻触关闭";
            }
            button.selected = !button.isSelected;
            [device unlockForConfiguration];
        }
    }
}

@end
