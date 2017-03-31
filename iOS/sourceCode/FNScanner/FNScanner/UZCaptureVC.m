/**
 * APICloud Modules
 * Copyright (c) 2014-2015 by APICloud, Inc. All Rights Reserved.
 * Licensed under the terms of the The MIT License (MIT).
 * Please see the license.html included with this distribution for details.
 */

#import "UZCaptureVC.h"

@interface UZCaptureVC ()
{
    BOOL getCodePicture;
    NSString *_resultStr;
    UIImageView *_background;
}
    @property (nonatomic ,strong) NSString *resultStr;
@end

@implementation UZCaptureVC

#pragma mark  lifeCycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    getCodePicture = NO;
    [self setupCamera];
    [self initView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _preview.frame = self.view.bounds;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma orintation

- (BOOL)shouldAutorotate {
    if (!self.autoFit) {
        return NO;
    }
    _preview.frame = self.view.bounds;
    switch (self.interfaceOrientation) {
        case UIInterfaceOrientationUnknown:
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown: {
            [self changeToPortrait];
            _preview.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        }
            break;
        case UIInterfaceOrientationLandscapeLeft: {
            [self changeToLeft];
            _preview.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
        }
            break;
        case UIInterfaceOrientationLandscapeRight:{
            [self changeToRight];
            _preview.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        }
            break;
        default: {
            _preview.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
            [self changeToPortrait];
        }
            break;
    }
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (self.autoFit) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

- (void)changeToRight {
    [self changedVertical];
}

- (void)changeToLeft {
    [self changedVertical];
}

- (void)changeToPortrait {
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

#pragma mark  btnClick

- (void)cancel:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(cancelScan)]) {
        [self.delegate cancelScan];
    }
}

- (void)openAlbum:(UIButton *)btn {//从相册读取图片解码
    if ([self.delegate respondsToSelector:@selector(openAlbum)]) {
        [self.delegate openAlbum];
    }
}

- (void) turnTorchOn:(UIButton *)btntemp {//闪光灯开关
    UIView *superView = [btntemp superview];
    UIButton *btnlight = (UIButton *)[superView viewWithTag:789];
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash]) {
            [device lockForConfiguration:nil];
            if (btnlight.isSelected) {
                [device setTorchMode:AVCaptureTorchModeOff];
                [device setFlashMode:AVCaptureFlashModeOff];
                [btnlight setSelected:NO];
                [btnlight setBackgroundImage:[self getImage:@"light"] forState:UIControlStateNormal];
            } else {
                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureFlashModeOn];
                [btnlight setSelected:YES];
                [btnlight setBackgroundImage:[self getImage:@"light_light"] forState:UIControlStateNormal];
            }
            [device unlockForConfiguration];
        }
    }
}

#pragma mark  initCamera

- (UIImage *)getImage:(NSString *)fileName {
    NSString *pathName = [NSString stringWithFormat:@"res_FNScanner/%@",fileName];
    NSString *path = [[NSBundle mainBundle] pathForResource:pathName ofType:@"png"];
    return [UIImage imageWithContentsOfFile:path];
}

- (void)initView {
    //背景图
    float width = [UIScreen mainScreen].bounds.size.width;
    float height = [UIScreen mainScreen].bounds.size.height;
    _background = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, width, height)];
    _background.image = [self getImage:@"background"];
    _background.userInteractionEnabled = YES;
    [self.view addSubview:_background];
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
}

- (void)setupCamera {
    // 获取摄像头
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // 创建输入流
    _input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    // 创建输出流
    _output = [[AVCaptureMetadataOutput alloc]init];
    //设置代理 在主线程里刷新
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    //获取扫码截图
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc]init];
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    [videoOutput setSampleBufferDelegate:self queue:queue];
    videoOutput.videoSettings =
    [NSDictionary dictionaryWithObject:
     [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    //扫码区域设定 x对应距离左上角的垂直距离，y对应距离左上角的水平距离,w、h情况类似
    _output.rectOfInterest = CGRectMake(0, 0, 1, 1);//处理区域是全屏
    //CGRectMake（y的起点/屏幕的高，x的起点/屏幕的宽，扫描的区域的高/屏幕的高，扫描的区域的宽/屏幕的宽）
    // 初始化链接对象
    _session = [[AVCaptureSession alloc]init];
    // 高质量采集率
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    if ([_session canAddInput:self.input]) {
        [_session addInput:self.input];
    }
    if ([_session canAddOutput:self.output]) {
        [_session addOutput:self.output];
    }
    if ([_session canAddOutput:videoOutput]) {
        [_session addOutput:videoOutput];
    }
    AVAuthorizationStatus  cameraStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (cameraStatus==AVAuthorizationStatusAuthorized || cameraStatus==AVAuthorizationStatusNotDetermined) {
        // 设置扫码支持的编码格式(如下设置条形码和二维码兼容) AVMetadataObjectTypeQRCode：二维码
        BOOL ios8 = [[[UIDevice currentDevice] systemVersion] floatValue]>=8.0?YES:NO;
        if (ios8) {
            _output.metadataObjectTypes =@[AVMetadataObjectTypeUPCECode, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode39Mod43Code, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeQRCode, AVMetadataObjectTypeAztecCode, AVMetadataObjectTypeInterleaved2of5Code, AVMetadataObjectTypeITF14Code, AVMetadataObjectTypeDataMatrixCode];
        } else {
            _output.metadataObjectTypes =@[AVMetadataObjectTypeUPCECode, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode39Mod43Code, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeQRCode, AVMetadataObjectTypeAztecCode];
        }
    }
    // Preview
    _preview =[AVCaptureVideoPreviewLayer layerWithSession:self.session];
    _preview.videoGravity = AVLayerVideoGravityResize;
    _preview.frame = self.view.bounds;
    [self.view.layer addSublayer:self.preview];
    
    // 开始捕获
    [_session startRunning];
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
        if ([self.delegate respondsToSelector:@selector(didScan:withResult:)]) {
            [self.delegate didScan:image withResult:self.resultStr];
        }
        getCodePicture = NO;
        [_session stopRunning];
        [self performSelectorOnMainThread:@selector(dissmissVC) withObject:nil waitUntilDone:NO];
    }
}

- (void)dissmissVC {
    NSLog(@"dismissModalViewControllerAnimated");
    [self dismissModalViewControllerAnimated:YES];
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
