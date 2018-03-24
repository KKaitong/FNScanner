/**
 * APICloud Modules
 * Copyright (c) 2014-2015 by APICloud, Inc. All Rights Reserved.
 * Licensed under the terms of the The MIT License (MIT).
 * Please see the license.html included with this distribution for details.
 */

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol CaptureDelegate <NSObject>

- (void)didScan:(UIImage *)image withResult:(NSString *)result;
- (void)openAlbum;
- (void)cancelScan;

@end

@interface UZCaptureVC : UIViewController
<AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (strong, nonatomic) AVCaptureDevice *device;
@property (strong, nonatomic) AVCaptureDeviceInput *input;
@property (strong, nonatomic) AVCaptureMetadataOutput *output;
@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *preview;
@property (nonatomic, assign) id <CaptureDelegate> delegate;
@property (nonatomic, assign) BOOL autoFit;

- (void)cancel:(UIButton *)sender;
- (void)openAlbum:(UIButton *)btn;
- (void)setupCamera;

@end
