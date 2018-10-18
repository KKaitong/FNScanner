/**
 * APICloud Modules
 * Copyright (c) 2014-2018 by APICloud, Inc. All Rights Reserved.
 * Licensed under the terms of the The MIT License (MIT).
 * Please see the license.html included with this distribution for details.
 */

#import <UIKit/UIKit.h>
#import "ZBarSDK.h"

@protocol ScannerControllerDelegate ;

@interface FNScannerViewController : UIViewController
< ZBarReaderDelegate>
{
    ZBarReaderViewController *_reader;
}

@property (nonatomic, strong) ZBarReaderViewController *reader;
@property (nonatomic, assign) id <ScannerControllerDelegate>delegate;

@end

@protocol ScannerControllerDelegate <NSObject>

- (void)didScnnerResult:(NSString *)result andImage:(UIImage*)image;

@end
