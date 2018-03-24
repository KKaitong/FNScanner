/**
  * APICloud Modules
  * Copyright (c) 2014-2015 by APICloud, Inc. All Rights Reserved.
  * Licensed under the terms of the The MIT License (MIT).
  * Please see the license.html included with this distribution for details.
  */

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol CaptureViewDelegate <NSObject>

- (void)didViewScan:(UIImage *)image withResult:(NSString *)result;

@end

@interface UZCaptureView : UIView
<AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (strong, nonatomic) AVCaptureDevice *device;
@property (strong, nonatomic) AVCaptureDeviceInput *input;
@property (strong, nonatomic) AVCaptureMetadataOutput *output;
@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *preview;
@property (nonatomic, assign) id <CaptureViewDelegate> delegate;
@property (nonatomic, assign) BOOL getCodePicture;
@property (nonatomic, assign) BOOL autoFit;
@property (nonatomic, assign) CGRect interestRect;

@end
