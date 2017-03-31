/**
 * APICloud Modules
 * Copyright (c) 2014-2015 by APICloud, Inc. All Rights Reserved.
 * Licensed under the terms of the The MIT License (MIT).
 * Please see the license.html included with this distribution for details.
 */

#import "UZFNScanner.h"
#import "NSDictionaryUtils.h"
#import "UZAppUtils.h"
#import "NKDEAN13Barcode.h"
#import "UIImage-NKDBarcode.h"
#import "QRCodeGenerator.h"
#import "FNScannerViewController.h"
#import "UZFNBarViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "AssetsLibrary/AssetsLibrary.h"
#import "UZCaptureVC.h"
#import "UZCaptureView.h"

#define ZBarOrientationMaskNormal \
(ZBarOrientationMask(UIInterfaceOrientationPortrait) | \
ZBarOrientationMask(UIInterfaceOrientationLandscapeLeft) | \
ZBarOrientationMask(UIInterfaceOrientationLandscapeRight))

@interface UZFNScanner ()
<ScannerControllerDelegate, ZBarReaderDelegate, ZBarReaderViewDelegate, OrentationChangedDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CaptureDelegate, CaptureViewDelegate> {
    NSInteger callOpenId, callViewBackID, callBackDecode, callBackFail;
    BOOL isImageRead, isDecodeImg, openSaveToAlbum, diySaveToAlbum;
    SystemSoundID soundID;
    UIView *_customView;
    UIImageView *_background;
} 
@property (nonatomic, strong) NSDictionary *diySaveInfo, *openSaveInfo;
@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, strong) FNScannerViewController *scanner;
@property (nonatomic, strong) UIView *customView;
@property (nonatomic, strong) NSString *openSound, *diySound, *decodeSound;
@property (nonatomic, strong) UIImageView *background;
@property (nonatomic, strong) UZCaptureView *captureView;

@end

@implementation UZFNScanner
@synthesize scanner;
@synthesize customView = _customView;
@synthesize diySound, openSound, decodeSound;
@synthesize popoverController;
@synthesize diySaveInfo, openSaveInfo;
@synthesize background = _background;
@synthesize captureView;

#pragma mark-
#pragma mark lifeCycle
#pragma mark-

- (void)dispose {
    [self closeView:nil];
    if (popoverController) {
        self.popoverController = nil;
    }
    if (openSaveInfo) {
        self.openSaveInfo = nil;
    }
    if (openSound) {
        self.openSound = nil;
    }
    if (decodeSound) {
        self.decodeSound = nil;
    }
    if (_background) {
        [_background removeFromSuperview];
        self.background = nil;
    }
    if (captureView) {
        [captureView removeFromSuperview];
        captureView.delegate = nil;
        self.captureView = nil;
    }
}

- (id)initWithUZWebView:(UZWebView *)webView_ {
    self = [super initWithUZWebView:webView_];
    if (self != nil) {
        callViewBackID = -1;
        callOpenId = -1;
        callBackDecode = -1;
        callBackFail = -1;
        isImageRead = NO;
        isDecodeImg = NO;
        self.openSound = nil;
        self.diySound = nil;
        self.decodeSound = nil;
        self.openSaveInfo = @{};
    }
    return self;
}

#pragma mark-
#pragma mark interface
#pragma mark-

- (void)openScanner:(NSDictionary *)paramsDict_ {
    self.openSaveInfo = [paramsDict_ dictValueForKey:@"saveImg" defaultValue:@{}];
    callOpenId = [paramsDict_ integerValueForKey:@"cbId" defaultValue:-1];
    callBackFail = callOpenId;
    NSString *soundStr = [paramsDict_ stringValueForKey:@"sound" defaultValue:nil];
    if ([soundStr isKindOfClass:[NSString class]] && soundStr.length>0) {
        self.openSound = [self getPathWithUZSchemeURL:soundStr];
    }
    BOOL autoLight = NO;
    BOOL autorotaion = [paramsDict_ boolValueForKey:@"autorotation" defaultValue:NO];
    openSaveToAlbum = [paramsDict_ boolValueForKey:@"saveToAlbum" defaultValue:NO];
    if (isIOS7) {
        UZCaptureVC *capture = [[UZCaptureVC alloc]init];
        capture.delegate = self;
        capture.autoFit = autorotaion;
        [self.viewController presentViewController:capture animated:YES completion:^(){
            NSMutableDictionary *sendDict = [NSMutableDictionary dictionaryWithCapacity:1];
            [sendDict setObject:@"show" forKey:@"eventType"];
            [self sendResultEventWithCallbackId:callOpenId dataDict:sendDict errDict:nil doDelete:NO];
        }];
        return;
    }
    UZFNBarViewController *reader = [[UZFNBarViewController alloc]init];
    reader.readerDelegate = self;
    reader.showsZBarControls = NO;
    if (!autoLight) {
        reader.readerView.torchMode = 0;
    }
    reader.orDelegate = self;
    reader.wantsFullScreenLayout = NO;
    //背景图
    float width = [UIScreen mainScreen].bounds.size.width;
    float height = [UIScreen mainScreen].bounds.size.height;
    if (width > height) {
        width = [UIScreen mainScreen].bounds.size.height;
        height = [UIScreen mainScreen].bounds.size.width;
    }
    _background = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, width, height)];
    _background.image = [self getImage:@"background"];
    _background.userInteractionEnabled = YES;
    [reader.view addSubview:_background];
    //中间游标
    float arrowx = 48 * width/320;
    float arrowy = 148 * height/568;
    float arrowWidth = 221 * width/320;
    float arrowHeight = 261 * height/568;
    UIImageView *arrow = [[UIImageView alloc]initWithFrame:CGRectMake(arrowx,arrowy,arrowWidth,arrowHeight)];
    arrow.image = [self getImage:@"arrow"];
    arrow.tag = 1000;
    [_background addSubview:arrow];
    //返回按钮
    UIButton *butt = [UIButton buttonWithType:UIButtonTypeCustom];
    [butt setFrame:CGRectMake(20, 40, 10.5, 16.5)];
    [_background addSubview:butt];
    UIButton *cancelButton12 = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton12 setFrame:CGRectMake(10, 30, 40, 40)];
    [butt setBackgroundImage:[self getImage:@"back_img"] forState:UIControlStateNormal];
    [cancelButton12 addTarget:self action:@selector(cancel:)forControlEvents:UIControlEventTouchUpInside];
    [_background addSubview:cancelButton12];
    //开关闪光灯操作的button
    UIButton *cancelButton1 = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton1 setFrame:CGRectMake(width-40, 37,15, 22)];
    [cancelButton1 setBackgroundImage:[self getImage:@"light"] forState:UIControlStateNormal];
    cancelButton1.tag = 789;
    [_background addSubview:cancelButton1];
    UIButton *cancelButton123 = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton123 setFrame:CGRectMake(width-60, 30,45, 42)];
    cancelButton123.tag = 788;
    [cancelButton123 addTarget:self action:@selector(turnTorchOn:)forControlEvents:UIControlEventTouchUpInside];
    [_background addSubview:cancelButton123];
    //开关相册
    UIButton *aubumButton1 = [UIButton buttonWithType:UIButtonTypeCustom];
    [aubumButton1 setFrame:CGRectMake(width/2-20, 40,19.5, 14)];
    aubumButton1.tag = 689;
    [aubumButton1 setBackgroundImage:[self getImage:@"album"] forState:UIControlStateNormal];
    [_background addSubview:aubumButton1];
    UIButton *aubumButton12 = [UIButton buttonWithType:UIButtonTypeCustom];
    [aubumButton12 setFrame:CGRectMake(width/2-30, 30,45, 42)];
    [aubumButton12 addTarget:self action:@selector(openAlbum:)forControlEvents:UIControlEventTouchUpInside];
    [_background addSubview:aubumButton12];
    aubumButton12.tag = 688;
    reader.supportedOrientationsMask = ZBarOrientationMask(UIInterfaceOrientationPortrait);
    ZBarImageScanner *scanners = reader.scanner;
    [scanners setSymbology: ZBAR_I25 config: ZBAR_CFG_ENABLE to: 0];
    [self.viewController presentModalViewController: reader animated: YES];
    
    NSMutableDictionary *sendDict = [NSMutableDictionary dictionaryWithCapacity:1];
    [sendDict setObject:@"show" forKey:@"eventType"];
    [self sendResultEventWithCallbackId:callOpenId dataDict:sendDict errDict:nil doDelete:NO];
}

- (void)setFrame:(NSDictionary *)paramsDict_ {
    float beforX = self.captureView.frame.origin.x;
    float beforY = self.captureView.frame.origin.y;
    float beforW = self.captureView.frame.size.width;
    float beforH = self.captureView.frame.size.height;
    float x = [paramsDict_ floatValueForKey:@"x" defaultValue:beforX];
    float y = [paramsDict_ floatValueForKey:@"y" defaultValue:beforY];
    float w = [paramsDict_ floatValueForKey:@"w" defaultValue:beforW];
    float h = [paramsDict_ floatValueForKey:@"h" defaultValue:beforH];
    CGRect newRect = CGRectMake(x, y, w, h);
    if (isIOS7) {
        self.captureView.frame = newRect;
        [self.captureView setNeedsDisplay];
    } else {
        [scanner.reader.view removeFromSuperview];
        _customView.frame = newRect;
        [_customView addSubview:scanner.reader.view];
    }
}

- (void)openView:(NSDictionary *)paramsDict_ {
    if (_customView || self.captureView) {
        [[_customView superview] bringSubviewToFront:_customView];
        _customView.hidden = NO;
        [[self.captureView superview] bringSubviewToFront:self.captureView];
        self.captureView.hidden = NO;
        return;
    }
    callViewBackID = [paramsDict_ integerValueForKey:@"cbId" defaultValue:-1];
    callBackFail = callViewBackID;
    self.diySaveInfo = @{};
    if ([paramsDict_ objectForKey:@"saveImg"]) {
        self.diySaveInfo = [paramsDict_ dictValueForKey:@"saveImg" defaultValue:@{}];
    }
    NSString *fixedOn = [paramsDict_ stringValueForKey:@"fixedOn" defaultValue:nil];
    UIView *superView = [self getViewByName:fixedOn];
    float defaultW = superView.bounds.size.width;
    float defaultH = superView.bounds.size.height;
    NSDictionary *rectInfo = [paramsDict_ dictValueForKey:@"rect" defaultValue:@{}];
    float x = [rectInfo floatValueForKey:@"x" defaultValue:0];
    float y = [rectInfo floatValueForKey:@"y" defaultValue:0];
    float w = [rectInfo floatValueForKey:@"w" defaultValue:defaultW];
    float h = [rectInfo floatValueForKey:@"h" defaultValue:defaultH];
 
    NSString *soundStr = [paramsDict_ stringValueForKey:@"sound" defaultValue:nil];
    if ([soundStr isKindOfClass:[NSString class]] && soundStr.length>0) {
        self.diySound = [self getPathWithUZSchemeURL:soundStr];
    }
    BOOL autorotation = [paramsDict_ boolValueForKey:@"autorotation" defaultValue:NO];
    BOOL autoLight = NO;
    BOOL fixed = [paramsDict_ boolValueForKey:@"fixed" defaultValue:YES];
    diySaveToAlbum = [paramsDict_ boolValueForKey:@"saveToAlbum" defaultValue:NO];

    if (isIOS7) {
        self.captureView = [[UZCaptureView alloc]init];
        self.captureView.frame = CGRectMake(x, y, w, h);
        self.captureView.delegate = self;
        self.captureView.autoFit = autorotation;
        [self addSubview:captureView fixedOn:fixedOn fixed:fixed];
        //回调
        NSMutableDictionary *sendDict = [NSMutableDictionary dictionaryWithCapacity:1];
        [sendDict setObject:@"show" forKey:@"eventType"];
        [self sendResultEventWithCallbackId:callViewBackID dataDict:sendDict errDict:nil doDelete:NO];
        return;
    }
    //打开扫码视图
    self.scanner = [[FNScannerViewController alloc]init];
    scanner.delegate = self;
    [scanner viewDidAppear:YES];
    scanner.reader.tracksSymbols = NO;//是否显示扫描绿框
    if (!autoLight) {
        scanner.reader.readerView.torchMode = 0;//是否根据当前环境自动打开闪关灯
    }
    _customView = [[UIView alloc]initWithFrame:CGRectMake(x, y, w, h)];
    _customView.clipsToBounds = YES;
    [self addSubview:_customView fixedOn:fixedOn fixed:fixed];
    [_customView addSubview:scanner.reader.view];
    //回调
    NSMutableDictionary *sendDict = [NSMutableDictionary dictionaryWithCapacity:1];
    [sendDict setObject:@"show" forKey:@"eventType"];
    [self sendResultEventWithCallbackId:callViewBackID dataDict:sendDict errDict:nil doDelete:NO];
}

- (void)closeView:(NSDictionary *)paramDict_ {
    if (callViewBackID!=-1) {
        [self deleteCallback:callViewBackID];
    }
    if (scanner) {
        scanner.delegate = nil;
        [scanner.reader.view removeFromSuperview];
        self.scanner = nil;
    }
    if (_customView) {
        [_customView removeFromSuperview];
        self.customView = nil;
    }
    if (diySound) {
        self.diySound = nil;
    }
    if (self.diySaveInfo) {
        self.diySaveInfo = nil;
    }
    if (captureView) {
        [captureView removeFromSuperview];
        captureView.delegate = nil;
        self.captureView = nil;
    }
}

- (void)decodeImg:(NSDictionary *)paramDict_ {//图片码解码
    callBackDecode = [paramDict_ integerValueForKey:@"cbId" defaultValue:-1];
    callBackFail = callBackDecode;
    NSString *sound = [paramDict_ stringValueForKey:@"sound" defaultValue:nil];
    if ([sound isKindOfClass:[NSString class]] && sound.length>0) {
        self.decodeSound = [self getPathWithUZSchemeURL:sound];
    }
    NSString *imagePath = [paramDict_ stringValueForKey:@"path" defaultValue:nil];
    if ([imagePath isKindOfClass:[NSString class]] && imagePath.length>0) {
        NSString *realImg = [self getPathWithUZSchemeURL:imagePath];
        UIImage *image = [UIImage imageWithContentsOfFile:realImg];
        [self decodeFromImage:image];
    } else {
        isDecodeImg = YES;
        [self presentImagePicker];
    }
}

- (void)encodeImg:(NSDictionary *)paramsDict_ {//编码成图片
    NSInteger cbid = [paramsDict_ integerValueForKey:@"cbId" defaultValue:-1];
    NSString *type = [paramsDict_ stringValueForKey:@"type" defaultValue:nil];
    if (![type isKindOfClass:[NSString class]] || type.length<=0) {
        type = @"qr_image";
    }
    BOOL saveToAlbum = [paramsDict_ boolValueForKey:@"saveToAlbum" defaultValue:NO];
    NSDictionary *saveInfo = [paramsDict_ dictValueForKey:@"saveImg" defaultValue:@{}];
    NSString *targetStr = [paramsDict_ stringValueForKey:@"content" defaultValue:nil];
    if (![targetStr isKindOfClass:[NSString class]] && targetStr.length<=0) {
        return;
    }
    float width = [saveInfo floatValueForKey:@"w" defaultValue:200];
    float height = [saveInfo floatValueForKey:@"h" defaultValue:200];
    UIImage *image = nil;
    if ([type isEqualToString:@"qr_image"]) {
        image = [QRCodeGenerator qrImageForString:targetStr imageSize:width];
    } else {
        CGRect rect = CGRectMake(0, 0, width, height);
        image = [UIImage imageFromBarcode:[[NKDEAN13Barcode alloc] initWithContent:targetStr] inRect:rect];
    }
    if (!image) {
        [self sendResultEventWithCallbackId:cbid dataDict:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"status"] errDict:nil doDelete:YES];
        return;
    }
    //保存图片到指定文件夹
    NSString *realPath = nil;
    if (saveInfo.count > 0) {
        realPath = [saveInfo stringValueForKey:@"path" defaultValue:nil];
        realPath = [self getPathWithUZSchemeURL:realPath];
        CGSize imgSize = CGSizeMake(width, height);
        UIImage *sclImg = [self imageByScalingToSize:imgSize image:image];
        [self writeImage:sclImg toFileAtPath:realPath];
    }
    //保存图片到相册
    if (saveToAlbum) {
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:^(NSURL *assetURL, NSError *error){
            if (error) {
                NSLog(@"Turbo FNScanner save image error");
            }
            NSString *imgUrl = [assetURL absoluteString];
            NSMutableDictionary *sendDict = [NSMutableDictionary dictionaryWithCapacity:2];
            [sendDict setObject:[NSNumber numberWithBool:YES] forKey:@"status"];
            if ([realPath isKindOfClass:[NSString class]] && realPath.length>0) {
                [sendDict setObject:realPath forKey:@"imgPath"];
            }
            if ([imgUrl isKindOfClass:[NSString class]] && imgUrl.length>0) {
                [sendDict setObject:imgUrl forKey:@"albumPath"];
            }
            [self sendResultEventWithCallbackId:cbid dataDict:sendDict errDict:nil doDelete:YES];
        }];
    } else {
        NSMutableDictionary *sendDict = [NSMutableDictionary dictionaryWithCapacity:2];
        [sendDict setObject:[NSNumber numberWithBool:YES] forKey:@"status"];
        if ([realPath isKindOfClass:[NSString class]] && realPath.length>0) {
            [sendDict setObject:realPath forKey:@"imgPath"];
        }
        [self sendResultEventWithCallbackId:cbid dataDict:sendDict errDict:nil doDelete:YES];
    }

}

- (void)switchLight:(NSDictionary *)paramsDcit_ {
    NSString *turnOn = [paramsDcit_ stringValueForKey:@"status" defaultValue:@"off"];
    if (![turnOn isKindOfClass:[NSString class]] || turnOn.length==0) {
        turnOn = @"off";
    }
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil){
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash]){
            [device lockForConfiguration:nil];
            if ([turnOn isEqualToString:@"on"]){
                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureFlashModeOn];
            } else {
                [device setTorchMode:AVCaptureTorchModeOff];
                [device setFlashMode:AVCaptureFlashModeOff];
            }
            [device unlockForConfiguration];
        }
    }
}

#pragma mark-
#pragma mark  CaptureViewDelegate
#pragma mark-
#pragma mark iOS7以后版本上打开的扫描view，扫描成功后的回调扫描的图片
- (void)didViewScan:(UIImage *)image withResult:(NSString *)result {
    if (![result isKindOfClass:[NSString class]] || result.length==0) {
        NSMutableDictionary *sendDict = [NSMutableDictionary dictionaryWithCapacity:1];
        [sendDict setObject:@"fail" forKey:@"eventType"];
        [self sendResultEventWithCallbackId:callViewBackID dataDict:sendDict errDict:nil doDelete:NO];
        return;
    }
    if ([result canBeConvertedToEncoding:NSShiftJISStringEncoding]){
        result = [NSString stringWithCString:[result cStringUsingEncoding:NSShiftJISStringEncoding] encoding:NSUTF8StringEncoding];
    }
    //播放声音
    if(self.diySound.length>0){
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.diySound]) {
            AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:self.diySound], &soundID);
            AudioServicesPlaySystemSound (soundID);
        }
    }
    //保存图片到指定文件夹
    NSString *realPath = nil;
    if (self.diySaveInfo.count > 0) {
        float width = [self.diySaveInfo floatValueForKey:@"w" defaultValue:200];
        float height = [self.diySaveInfo floatValueForKey:@"h" defaultValue:200];
        realPath = [self.diySaveInfo stringValueForKey:@"path" defaultValue:nil];
        realPath = [self getPathWithUZSchemeURL:realPath];
        CGSize imgSize = CGSizeMake(width, height);
        UIImage *sclImg = [self imageByScalingToSize:imgSize image:image];
        [self writeImage:sclImg toFileAtPath:realPath];
    }
    
    //保存图片到相册
    if (diySaveToAlbum) {
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:^(NSURL *assetURL, NSError *error){
            if (error) {
                NSLog(@"Turbo FNScanner save diyscanner image error");
            }
            NSString *imgUrl = [assetURL absoluteString];
            //diy扫码成功的回调
            if ([result isKindOfClass:[NSString class]] && result.length>0) {
                NSMutableDictionary *sendDict = [NSMutableDictionary dictionaryWithCapacity:2];
                [sendDict setObject:result forKey:@"content"];
                if ([realPath isKindOfClass:[NSString class]] && realPath.length>0) {
                    [sendDict setObject:realPath forKey:@"imgPath"];
                }
                if ([imgUrl isKindOfClass:[NSString class]] && imgUrl.length>0) {
                    [sendDict setObject:imgUrl forKey:@"albumPath"];
                }
                [sendDict setObject:@"success" forKey:@"eventType"];
                [self sendResultEventWithCallbackId:callViewBackID dataDict:sendDict errDict:nil doDelete:NO];
            }
        }];
    } else {
        //diy扫码成功的回调
        if ([result isKindOfClass:[NSString class]] && result.length>0) {
            NSMutableDictionary *sendDict = [NSMutableDictionary dictionaryWithCapacity:2];
            [sendDict setObject:result forKey:@"content"];
            [sendDict setObject:@"success" forKey:@"eventType"];
            if ([realPath isKindOfClass:[NSString class]] && realPath.length>0) {
                [sendDict setObject:realPath forKey:@"imgPath"];
            }
            [self sendResultEventWithCallbackId:callViewBackID dataDict:sendDict errDict:nil doDelete:NO];
        }
    }
    [self.captureView.session stopRunning];
    [self performSelectorOnMainThread:@selector(restart) withObject:nil waitUntilDone:NO];
}
#pragma mark ios7以后的系统版本上打开的扫描view 扫描成功后刷新摄像头再开始进行扫描
- (void)restart {
  [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(startScann) userInfo:nil repeats:NO];
}

- (void)startScann {
    [self.captureView.session startRunning];
}

#pragma mark-
#pragma mark  CaptureDelegate
#pragma mark-
#pragma mark iOS7以后版本上打开默认扫描器，扫描成功后的回调扫描的图片
- (void)didScan:(UIImage *)image withResult:(NSString *)result {
    //播放声音,支持wav、aiff、caf格式
    if(self.openSound.length>0){
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.openSound]) {
            AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:self.openSound], &soundID);
            AudioServicesPlaySystemSound (soundID);
        }
    }
    //保存图片到指定文件夹
    NSString *realPath = nil;
    if (self.openSaveInfo.count > 0) {
        float width = [self.openSaveInfo floatValueForKey:@"w" defaultValue:200];
        float height = [self.openSaveInfo floatValueForKey:@"h" defaultValue:200];
        realPath = [self.openSaveInfo stringValueForKey:@"path" defaultValue:nil];
        realPath = [self getPathWithUZSchemeURL:realPath];
        CGSize imgSize = CGSizeMake(width, height);
        UIImage *sclImg = [self imageByScalingToSize:imgSize image:image];
        [self writeImage:sclImg toFileAtPath:realPath];
    }
    //保存图片到相册
    if (openSaveToAlbum) {
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:^(NSURL *assetURL, NSError *error){
            if (error) {
                NSLog(@"Turbo FNScanner save image error");
            }
            NSString *imgUrl = [assetURL absoluteString];
            //open扫码成功的回调
            if ([result isKindOfClass:[NSString class]] && result.length>0) {//open的回调
                NSMutableDictionary *sendDict = [NSMutableDictionary dictionaryWithCapacity:2];
                [sendDict setObject:@"success" forKey:@"eventType"];
                [sendDict setObject:result forKey:@"content"];
                if ([realPath isKindOfClass:[NSString class]] && realPath.length>0) {
                    [sendDict setObject:realPath forKey:@"imgPath"];
                }
                if ([imgUrl isKindOfClass:[NSString class]] && imgUrl.length>0) {
                    [sendDict setObject:imgUrl forKey:@"albumPath"];
                }
                [self sendResultEventWithCallbackId:callOpenId dataDict:sendDict errDict:nil doDelete:YES];
            }
        }];
    } else {
        //open扫码成功的回调
        if ([result isKindOfClass:[NSString class]] && result.length>0) {//open的回调
            NSMutableDictionary *sendDict = [NSMutableDictionary dictionaryWithCapacity:2];
            [sendDict setObject:@"success" forKey:@"eventType"];
            [sendDict setObject:result forKey:@"content"];
            if ([realPath isKindOfClass:[NSString class]] && realPath.length>0) {
                [sendDict setObject:realPath forKey:@"imgPath"];
            }
            [self sendResultEventWithCallbackId:callOpenId dataDict:sendDict errDict:nil doDelete:YES];
        }
    }
}
#pragma mark iOS7以后版本上打开的扫描view，打开本地相册识别图片
- (void)openAlbum {
    [self openAlbum:nil];
}
#pragma mark iOS7以后版本上打开的扫描view，取消扫描
- (void)cancelScan {
    [self cancel:nil];
}
#pragma mark-
#pragma mark open imageDelegate
#pragma mark-
#pragma mark iOS6、7、8、9、10 用zbar识别图片失败的回调
- (void)readerControllerDidFailToRead:(ZBarReaderController *)reader withRetry:(BOOL)retry {
    if(retry){
        //retry == 1 选择图片为非二维码。
        NSMutableDictionary *sendDict = [NSMutableDictionary dictionaryWithCapacity:2];//open的回调
        [sendDict setObject:@"fail" forKey:@"eventType"];
        [sendDict setObject:@"非法图片" forKey:@"content"];
        [self sendResultEventWithCallbackId:callBackFail dataDict:sendDict errDict:nil doDelete:YES];
        return;
    }
}
#pragma mark iOS6、7、8、9、10取消从相册选择图片识别
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissModalViewControllerAnimated:YES];
    isImageRead = NO;
    isDecodeImg = NO;
}

#pragma mark-
#pragma mark openScanner Delegate
#pragma mark-
#pragma mark iOS6、7、8、9、10从相册选择图片识别/////iOS7以下zbar扫码回调
- (void)imagePickerController:(UIImagePickerController *)reader didFinishPickingMediaWithInfo:(NSDictionary *)info {//从相册/扫描器获取图片
    /*openAlbum 从相册读取*/
    if (isImageRead) {
        UIImage *image = [info objectForKey:@"UIImagePickerControllerEditedImage"];
        if (UI_USER_INTERFACE_IDIOM() ==UIUserInterfaceIdiomPad){
            [self.popoverController dismissPopoverAnimated:YES];
            [self decodeFromAlbumImage:image];
        } else {
            [reader dismissViewControllerAnimated:YES completion:^{[self decodeFromAlbumImage:image];}];
        }
        isImageRead = NO;
        return;
    }
    /*isDecodeImg 解码图片*/
    if (isDecodeImg) {
        UIImage *image = [info objectForKey:@"UIImagePickerControllerEditedImage"];
        if (UI_USER_INTERFACE_IDIOM() ==UIUserInterfaceIdiomPad){
            [self.popoverController dismissPopoverAnimated:YES];
            [self decodeFromImage:image];
        } else {
            [reader dismissViewControllerAnimated:YES completion:^{[self decodeFromImage:image];}];
        }
        isDecodeImg = NO;
        return;
    }
    //播放声音,支持wav、aiff、caf格式
    if(self.openSound.length>0){
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.openSound]) {
            AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:self.openSound], &soundID);
            AudioServicesPlaySystemSound (soundID);
        }
    }
    id<NSFastEnumeration> results = [info objectForKey: ZBarReaderControllerResults];
    ZBarSymbol *symbol = nil;
    for(symbol in results)
        break;
    NSString *text = nil;
    if ([symbol.data canBeConvertedToEncoding:NSShiftJISStringEncoding]){
        text = [NSString stringWithCString:[symbol.data cStringUsingEncoding:NSShiftJISStringEncoding] encoding:NSUTF8StringEncoding];
    } else {
        text =  symbol.data;
    }
    [reader dismissModalViewControllerAnimated:YES];
    UIImage *image = [info objectForKey: UIImagePickerControllerOriginalImage];
    
    //保存图片到指定文件夹
    NSString *realPath = nil;
    if (self.openSaveInfo.count > 0) {
        float width = [self.openSaveInfo floatValueForKey:@"w" defaultValue:200];
        float height = [self.openSaveInfo floatValueForKey:@"h" defaultValue:200];
        realPath = [self.openSaveInfo stringValueForKey:@"path" defaultValue:nil];
        realPath = [self getPathWithUZSchemeURL:realPath];
        CGSize imgSize = CGSizeMake(width, height);
        UIImage *sclImg = [self imageByScalingToSize:imgSize image:image];
        [self writeImage:sclImg toFileAtPath:realPath];
    }
    
    //保存图片到相册
    if (openSaveToAlbum) {
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:^(NSURL *assetURL, NSError *error){
            if (error) {
                NSLog(@"Turbo FNScanner save image error");
            }
            NSString *imgUrl = [assetURL absoluteString];
            //open扫码成功的回调
            if ([text isKindOfClass:[NSString class]] && text.length>0) {//open的回调
                NSMutableDictionary *sendDict = [NSMutableDictionary dictionaryWithCapacity:2];
                [sendDict setObject:@"success" forKey:@"eventType"];
                [sendDict setObject:text forKey:@"content"];
                if ([realPath isKindOfClass:[NSString class]] && realPath.length>0) {
                    [sendDict setObject:realPath forKey:@"imgPath"];
                }
                if ([imgUrl isKindOfClass:[NSString class]] && imgUrl.length>0) {
                    [sendDict setObject:imgUrl forKey:@"albumPath"];
                }
                [self sendResultEventWithCallbackId:callOpenId dataDict:sendDict errDict:nil doDelete:YES];
            }
        }];
    } else {
        //open扫码成功的回调
        if ([text isKindOfClass:[NSString class]] && text.length>0) {//open的回调
            NSMutableDictionary *sendDict = [NSMutableDictionary dictionaryWithCapacity:2];
            [sendDict setObject:@"success" forKey:@"eventType"];
            [sendDict setObject:text forKey:@"content"];
            if ([realPath isKindOfClass:[NSString class]] && realPath.length>0) {
                [sendDict setObject:realPath forKey:@"imgPath"];
            }
            [self sendResultEventWithCallbackId:callOpenId dataDict:sendDict errDict:nil doDelete:YES];
        }
    }
}

#pragma mark-
#pragma mark Scanner OrentationChangedDelegate
#pragma mark-
#pragma mark 右横屏
- (void)changeToRight:(UZFNBarViewController *)reader {
    [self changedVertical];
}
#pragma mark 左横屏
- (void)changeToLeft:(UZFNBarViewController *)reader {
    [self changedVertical];
}
#pragma mark 竖屏
- (void)changeToPortrait:(UZFNBarViewController *)reader {
    float width = [UIScreen mainScreen].bounds.size.width;
    float height = [UIScreen mainScreen].bounds.size.height;
    if (width > height) {
        width = [UIScreen mainScreen].bounds.size.height;
        height = [UIScreen mainScreen].bounds.size.width;
    }
    _background.frame = CGRectMake(0, 0, width, height);
    _background.image = [self getImage:@"background"];
    //中间游标
    UIImageView *arrow = (UIImageView *)[_background viewWithTag:1000];
    arrow.hidden = NO;
    [_background addSubview:arrow];
    //开关闪光灯操作的button
    UIButton *cancelButton1 = (UIButton *)[_background viewWithTag:789];
    [cancelButton1 setFrame:CGRectMake(width-40, 37,15, 22)];
    UIButton *cancelButton123 = (UIButton *)[_background viewWithTag:788];
    [cancelButton123 setFrame:CGRectMake(width-60, 30,45, 42)];
    //开关相册
    UIButton *aubumButton1 = (UIButton *)[_background viewWithTag:689];
    [aubumButton1 setFrame:CGRectMake(width/2-20, 40,19.5, 14)];
    UIButton *aubumButton12 = (UIButton *)[_background viewWithTag:688];
    [aubumButton12 setFrame:CGRectMake(width/2-30, 30,45, 42)];
}
#pragma mark 横屏
- (void)changedVertical {
    float width = [UIScreen mainScreen].bounds.size.width;
    float height = [UIScreen mainScreen].bounds.size.height;
    if (width < height) {
        width = [UIScreen mainScreen].bounds.size.height;
        height = [UIScreen mainScreen].bounds.size.width;
    }
    _background.frame = CGRectMake(0, 0, width, 64);
    _background.image = [self getImage:@"FNS_nvg_bg"];
    //中间游标
    UIImageView *arrow = (UIImageView *)[_background viewWithTag:1000];
    arrow.hidden = YES;
    //开关闪光灯操作的button
    UIButton *cancelButton1 = (UIButton *)[_background viewWithTag:789];
    [cancelButton1 setFrame:CGRectMake(width-40, 37,15, 22)];
    UIButton *cancelButton123 = (UIButton *)[_background viewWithTag:788];
    [cancelButton123 setFrame:CGRectMake(width-60, 30,45, 42)];
    //开关相册
    UIButton *aubumButton1 = (UIButton *)[_background viewWithTag:689];
    [aubumButton1 setFrame:CGRectMake(width/2-20, 40,19.5, 14)];
    UIButton *aubumButton12 = (UIButton *)[_background viewWithTag:688];
    [aubumButton12 setFrame:CGRectMake(width/2-30, 30,45, 42)];
}

#pragma mark-
#pragma mark diyScanner scannerDelegate
#pragma mark-

- (void) readerView:(ZBarReaderView *)readerView didReadSymbols:(ZBarSymbolSet *)symbols fromImage:(UIImage *)image { // 得到扫描的条码内容
    const zbar_symbol_t *symbol = zbar_symbol_set_first_symbol(symbols.zbarSymbolSet);
    if (zbar_symbol_get_type(symbol) == ZBAR_QRCODE) { // 是否QR二维码
        //NSLog(@"readerView didReadSymbols:%@",symbolStr);
    }
}

#pragma mark-
#pragma mark diyScanner scannerDelegate
#pragma mark-

- (void)didScnnerResult:(NSString *)result andImage:(UIImage *)image {//diyScanner delegate
    if (![result isKindOfClass:[NSString class]] || result.length==0) {
        NSMutableDictionary *sendDict = [NSMutableDictionary dictionaryWithCapacity:1];
        [sendDict setObject:@"fail" forKey:@"eventType"];
        [self sendResultEventWithCallbackId:callViewBackID dataDict:sendDict errDict:nil doDelete:NO];
        return;
    }
    if ([result canBeConvertedToEncoding:NSShiftJISStringEncoding]){
        result = [NSString stringWithCString:[result cStringUsingEncoding:NSShiftJISStringEncoding] encoding:NSUTF8StringEncoding];
    }
    //播放声音
    if(self.diySound.length>0){
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.diySound]) {
            AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:self.diySound], &soundID);
            AudioServicesPlaySystemSound (soundID);
        }
    }
    //保存图片到指定文件夹
    NSString *realPath = nil;
    if (self.diySaveInfo.count > 0) {
        float width = [self.diySaveInfo floatValueForKey:@"w" defaultValue:200];
        float height = [self.diySaveInfo floatValueForKey:@"h" defaultValue:200];
        realPath = [self.diySaveInfo stringValueForKey:@"path" defaultValue:nil];
        realPath = [self getPathWithUZSchemeURL:realPath];
        CGSize imgSize = CGSizeMake(width, height);
        UIImage *sclImg = [self imageByScalingToSize:imgSize image:image];
        [self writeImage:sclImg toFileAtPath:realPath];
    }
    
    //保存图片到相册
    if (diySaveToAlbum) {
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:^(NSURL *assetURL, NSError *error){
            if (error) {
                NSLog(@"Turbo FNScanner save diyscanner image error");
            }
            NSString *imgUrl = [assetURL absoluteString];
            //diy扫码成功的回调
            if ([result isKindOfClass:[NSString class]] && result.length>0) {
                NSMutableDictionary *sendDict = [NSMutableDictionary dictionaryWithCapacity:2];
                [sendDict setObject:result forKey:@"content"];
                if ([realPath isKindOfClass:[NSString class]] && realPath.length>0) {
                    [sendDict setObject:realPath forKey:@"imgPath"];
                }
                if ([imgUrl isKindOfClass:[NSString class]] && imgUrl.length>0) {
                    [sendDict setObject:imgUrl forKey:@"albumPath"];
                }
                [sendDict setObject:@"success" forKey:@"eventType"];
                [self sendResultEventWithCallbackId:callViewBackID dataDict:sendDict errDict:nil doDelete:NO];
            }
        }];
    } else {
        //diy扫码成功的回调
        if ([result isKindOfClass:[NSString class]] && result.length>0) {
            NSMutableDictionary *sendDict = [NSMutableDictionary dictionaryWithCapacity:2];
            [sendDict setObject:result forKey:@"content"];
            [sendDict setObject:@"success" forKey:@"eventType"];
            if ([realPath isKindOfClass:[NSString class]] && realPath.length>0) {
                [sendDict setObject:realPath forKey:@"imgPath"];
            }
            [self sendResultEventWithCallbackId:callViewBackID dataDict:sendDict errDict:nil doDelete:NO];
        }
    }
}

#pragma mark-
#pragma mark helper
#pragma mark -
#pragma mark取消
- (void)cancel:(UIButton *)sender {
    [self.viewController dismissModalViewControllerAnimated:YES];
    NSDictionary *sendDict = [NSDictionary dictionaryWithObject:@"cancel" forKey:@"eventType"];
    [self sendResultEventWithCallbackId:callOpenId dataDict:sendDict errDict:nil doDelete:YES];
}
#pragma mark从相册读取图片解码
- (void)openAlbum:(UIButton *)btn {//从相册读取图片解码
    [self.viewController dismissModalViewControllerAnimated:NO];
    NSDictionary *sendDict = [NSDictionary dictionaryWithObject:@"selectImage" forKey:@"eventType"];
    [self sendResultEventWithCallbackId:callOpenId dataDict:sendDict errDict:nil doDelete:NO];
    isImageRead = YES;
    [self presentImagePicker];
}
#pragma mark工具函数
- (UIImage *)getImage:(NSString *)fileName {
    NSString *pathName = [NSString stringWithFormat:@"res_FNScanner/%@",fileName];
    NSString *path = [[NSBundle mainBundle] pathForResource:pathName ofType:@"png"];
    return [UIImage imageWithContentsOfFile:path];
}
#pragma mark 闪光灯开关
- (void) turnTorchOn:(UIButton *)btntemp {
    UIView *superView = [btntemp superview];
    UIButton *btnlight = (UIButton *)[superView viewWithTag:789];
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash]) {
            [device lockForConfiguration:nil];
            if (btnlight.isSelected) {
                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureFlashModeOn];
                [btnlight setSelected:NO];
                [btnlight setBackgroundImage:[self getImage:@"light_light"] forState:UIControlStateNormal];
            } else {
                [device setTorchMode:AVCaptureTorchModeOff];
                [device setFlashMode:AVCaptureFlashModeOff];
                [btnlight setSelected:YES];
                [btnlight setBackgroundImage:[self getImage:@"light"] forState:UIControlStateNormal];
            }
            [device unlockForConfiguration];
        }
    }
}

- (void)presentImagePicker {
    if (UI_USER_INTERFACE_IDIOM() ==UIUserInterfaceIdiomPad) {
        UIImagePickerController *m_imagePicker = [[UIImagePickerController alloc] init];
        if ([UIImagePickerController isSourceTypeAvailable:
             UIImagePickerControllerSourceTypePhotoLibrary]) {
            m_imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            m_imagePicker.delegate = self;
            m_imagePicker.allowsEditing = YES;
            UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:m_imagePicker];
            self.popoverController = popover;
            [popoverController presentPopoverFromRect:CGRectMake([UIScreen mainScreen].bounds.size.width/4+80, 0,[ UIScreen mainScreen].bounds.size.width/2, 70) inView:self.viewController.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    } else {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.allowsEditing = YES;
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self.viewController presentModalViewController:picker animated:YES];
    }
}

- (void)decodeFromAlbumImage:(UIImage *)image {//解码相册里选取的图片
    //播放声音
    if(self.openSound.length>0){
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.openSound]) {
            AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:self.openSound], &soundID);
            AudioServicesPlaySystemSound (soundID);
        }
    }
    ZBarReaderController *read = [ZBarReaderController new];
    read.readerDelegate = self;
    CGImageRef cgImageRef = image.CGImage;
    ZBarSymbol *symbol = nil;
    for(symbol in [read scanImage:cgImageRef]) break;
    NSString *text = nil;
    if ([symbol.data canBeConvertedToEncoding:NSShiftJISStringEncoding]){
        text = [NSString stringWithCString:[symbol.data cStringUsingEncoding:NSShiftJISStringEncoding] encoding:NSUTF8StringEncoding];
    } else {
        text =  symbol.data;
    }
    if ([text isKindOfClass:[NSString class]] && text.length>0) {
        NSMutableDictionary *sendDict = [NSMutableDictionary dictionaryWithCapacity:2];//open的回调
        [sendDict setObject:@"success" forKey:@"eventType"];
        [sendDict setObject:text forKey:@"content"];
        [self sendResultEventWithCallbackId:callOpenId dataDict:sendDict errDict:nil doDelete:YES];
    } else {//open的回调
        NSMutableDictionary *sendDict = [NSMutableDictionary dictionaryWithCapacity:2];//open的回调
        [sendDict setObject:@"fail" forKey:@"eventType"];
        [sendDict setObject:@"非法图片" forKey:@"content"];
        [self sendResultEventWithCallbackId:callOpenId dataDict:sendDict errDict:nil doDelete:YES];
    }
}

- (void)decodeFromImage:(UIImage *)image {//解码图片
    //播放声音
    if(self.decodeSound.length>0){
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.decodeSound]) {
            AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:self.decodeSound], &soundID);
            AudioServicesPlaySystemSound (soundID);
        }
    }
    ZBarReaderController *read = [ZBarReaderController new];
    read.readerDelegate = self;
    CGImageRef cgImageRef = image.CGImage;
    ZBarSymbol *symbol = nil;
    for(symbol in [read scanImage:cgImageRef]) break;
    NSString *text = nil;
    if ([symbol.data canBeConvertedToEncoding:NSShiftJISStringEncoding]){
        text = [NSString stringWithCString:[symbol.data cStringUsingEncoding:NSShiftJISStringEncoding] encoding:NSUTF8StringEncoding];
    } else {
        text =  symbol.data;
    }
    if ([text isKindOfClass:[NSString class]] && text.length>0) {
        NSMutableDictionary *sendDict = [NSMutableDictionary dictionaryWithCapacity:2];//decode的回调
        [sendDict setObject:[NSNumber numberWithBool:YES] forKey:@"status"];
        [sendDict setObject:text forKey:@"content"];
        [self sendResultEventWithCallbackId:callBackDecode dataDict:sendDict errDict:nil doDelete:YES];
    } else {//decode的回调
        NSMutableDictionary *sendDict = [NSMutableDictionary dictionaryWithCapacity:2];//decode的回调
        [sendDict setObject:[NSNumber numberWithBool:false] forKey:@"status"];
        [sendDict setObject:@"非法图片" forKey:@"content"];
        [self sendResultEventWithCallbackId:callBackDecode dataDict:sendDict errDict:nil doDelete:YES];
    }
}
#pragma mark 保存图片到指定路径
- (BOOL)writeImage:(UIImage*)image toFileAtPath:(NSString*)aPath {//保存图片到指定路径
    if ((image == nil) || (aPath == nil) || ([aPath isEqualToString:@""])) {
        return NO;
    }
    @try {
        
        NSData *imageData = nil;
        NSString *ext = [aPath pathExtension];
        if ([ext isEqualToString:@"png"]) {
            imageData = UIImagePNGRepresentation(image);
        } else {
            imageData = UIImageJPEGRepresentation(image, 1);
        }
        if ((imageData == nil) || ([imageData length] <= 0)) {
            return NO;
        }
        NSArray *array = [aPath componentsSeparatedByString:@"/"];
        NSString *imgName = [array lastObject];
        NSRange range = [aPath rangeOfString:imgName];
        NSString *sufPath = [aPath substringToIndex:range.location-1];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:sufPath]) {
            [fileManager removeItemAtPath:sufPath error:nil];
        }
        [fileManager createDirectoryAtPath:sufPath withIntermediateDirectories:YES attributes:nil error:nil];
        [fileManager createFileAtPath:aPath contents:imageData attributes:nil];
        return YES;
    } @catch (NSException *e) {
        NSLog(@"Turbo NFScanner save image to path fail.");
    }
    return NO;
}
#pragma mark 调整图片大小
- (UIImage *)imageByScalingToSize:(CGSize)targetSize image:(UIImage *)sourceImage {
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        if (widthFactor < heightFactor)
            scaleFactor = widthFactor;
        else
            scaleFactor = heightFactor;
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        // center the image
        if (widthFactor < heightFactor) {
            
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        } else if (widthFactor > heightFactor) {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    // this is actually the interesting part:
    UIGraphicsBeginImageContext(targetSize);
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    [sourceImage drawInRect:thumbnailRect];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    if(newImage == nil) {
        NSLog(@"Turbo FNScanner could not scale image");
        newImage = sourceImage;
    }
    return newImage ;
}

@end
