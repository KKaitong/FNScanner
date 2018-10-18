/**
  * APICloud Modules
  * Copyright (c) 2014-2018 by APICloud, Inc. All Rights Reserved.
  * Licensed under the terms of the The MIT License (MIT).
  * Please see the license.html included with this distribution for details.
  */

#import "UZCaptureView.h"

@interface UZCaptureView ()
{
    NSString *_resultStr;
}
    @property (nonatomic ,strong) NSString *resultStr;
@end

@implementation UZCaptureView
@synthesize getCodePicture;
@synthesize autoFit;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"willRotateToInterfaceOrientationNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"viewWillTransitionToSizeWithTransitionCoordinatorNotification" object:nil];
}

- (id)init {
    self = [super init];
    if (self != nil) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willRotateToInterfaceOrientationNotification:) name:@"willRotateToInterfaceOrientationNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewWillTransitionToSizeWithTransitionCoordinatorNotification:) name:@"viewWillTransitionToSizeWithTransitionCoordinatorNotification" object:nil];
    }
    return self;
}

- (void)willRotateToInterfaceOrientationNotification:(id)info {
    [self autorotate];
}

- (void)viewWillTransitionToSizeWithTransitionCoordinatorNotification:(id)info {
    [self autorotate];
}
- (void)autorotate {
    if (!self.autoFit) {
        return;
    }
    
    UIInterfaceOrientation orientation = (UIInterfaceOrientation)[UIDevice currentDevice].orientation;
    switch (orientation) {
        case UIInterfaceOrientationUnknown:
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown: {
            _preview.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        }
            break;
            
        case UIInterfaceOrientationLandscapeLeft: {
            _preview.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
        }
            break;
            
        case UIInterfaceOrientationLandscapeRight:{
            _preview.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        }
            break;
            
        default: {
            _preview.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        }
            break;
    }
}

- (void)drawRect:(CGRect)rect {
    if (!self.session) {
        [self setupCamera];
    }
    self.preview.frame = self.bounds;
    float h = self.preview.frame.size.height;
    float w = self.preview.frame.size.width;
    float interesty = _interestRect.origin.y;
    float interestx = _interestRect.origin.x;
    float interestw = _interestRect.size.width;
    float interesth = _interestRect.size.height;
    //CGRect newRect = [self.preview metadataOutputRectOfInterestForRect:_interestRect];
    self.output.rectOfInterest = CGRectMake(interesty/h, interestx/w, interesth/h, interestw/w);
    
    [self autorotateStatusBar];
}

- (void)setupCamera {
    // 获取摄像头
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // 创建输入流
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    // 创建输出流
    self.output = [[AVCaptureMetadataOutput alloc]init];
    //设置代理 在主线程里刷新
    [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    //获取扫码截图
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc]init];
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    [videoOutput setSampleBufferDelegate:self queue:queue];
    videoOutput.videoSettings = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    // 初始化链接对象
    self.session = [[AVCaptureSession alloc]init];
    // 高质量采集率
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    if ([self.session canAddInput:self.input]) {
        [self.session addInput:self.input];
    }
    if ([self.session canAddOutput:self.output]) {
        [self.session addOutput:self.output];
    }
    if ([self.session canAddOutput:videoOutput]) {
        [self.session addOutput:videoOutput];
    }   AVAuthorizationStatus  cameraStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (cameraStatus == AVAuthorizationStatusAuthorized || cameraStatus==AVAuthorizationStatusNotDetermined) {
        // 设置扫码支持的编码格式(如下设置条形码和二维码兼容) AVMetadataObjectTypeQRCode：二维码
        BOOL ios8 = [[[UIDevice currentDevice] systemVersion] floatValue]>=8.0?YES:NO;
        if (ios8) {
            self.output.metadataObjectTypes =@[AVMetadataObjectTypeUPCECode, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode39Mod43Code, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeQRCode, AVMetadataObjectTypeAztecCode, AVMetadataObjectTypeInterleaved2of5Code, AVMetadataObjectTypeITF14Code, AVMetadataObjectTypeDataMatrixCode];
        } else {
            self.output.metadataObjectTypes =@[AVMetadataObjectTypeUPCECode, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode39Mod43Code, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeQRCode, AVMetadataObjectTypeAztecCode];
        }
    }
    
    // Preview
    self.preview =[AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.layer addSublayer:self.preview];
    [self.session startRunning];
}

- (void)autorotateStatusBar {
    if (!self.autoFit) {
        return;
    }
    UIInterfaceOrientation orientation =  [UIApplication sharedApplication].statusBarOrientation;
    switch (orientation) {
        case UIInterfaceOrientationUnknown:
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown: {
            _preview.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        }
            break;
        case UIInterfaceOrientationLandscapeLeft: {
            _preview.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
        }
            break;
        case UIInterfaceOrientationLandscapeRight:{
            _preview.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        }
            break;
        default: {
            _preview.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        }
            break;
    }
}

#pragma mark  AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    getCodePicture = YES;
    if ([metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex:0];
        self.resultStr = metadataObject.stringValue;
    }
}

#pragma mark  AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (getCodePicture) {
        // 通过抽样缓存数据创建一个UIImage对象
        UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
        [self.delegate didViewScan:image withResult:self.resultStr];
        getCodePicture = NO;
    }
}

#pragma mark  getImage

- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {// 通过抽样缓存数据创建一个UIImage对象
    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // 锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    // 得到pixel buffer的基地址
    void  *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    // 得到pixel buffer的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到pixel buffer的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    // 创建一个依赖于设备的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    
    // 根据这个位图context中的像素数据创建一个Quartz image对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    // 释放context和颜色空间
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    // 用Quartz image创建一个UIImage对象image
    UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1.0f orientation:UIImageOrientationRight];
    // 释放Quartz image对象
    CGImageRelease(quartzImage);
    return (image);
}

@end
