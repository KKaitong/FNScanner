/**
 * APICloud Modules
 * Copyright (c) 2014-2015 by APICloud, Inc. All Rights Reserved.
 * Licensed under the terms of the The MIT License (MIT).
 * Please see the license.html included with this distribution for details.
 */

#import "FNScannerViewController.h"

@interface FNScannerViewController ()

@end

@implementation FNScannerViewController

@synthesize reader = _reader;
@synthesize delegate;

#pragma mark -
#pragma mark lifeCycle
#pragma mark -

-(void)dealloc {
    if (_reader) {
        self.reader = nil;
    }
    if (delegate) {
        self.delegate = nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    self.reader = [ZBarReaderViewController new];
    _reader.readerDelegate = self;
    _reader.showsZBarControls = NO;
    _reader.wantsFullScreenLayout = NO;
    ZBarImageScanner *scanner = _reader.scanner;
    [scanner setSymbology: ZBAR_I25 config: ZBAR_CFG_ENABLE to: 0];
    [self presentModalViewController: _reader animated: NO];
}

- (void)imagePickerController:(UIImagePickerController *)reader didFinishPickingMediaWithInfo:(NSDictionary *)info {
    id<NSFastEnumeration> results =
    [info objectForKey: ZBarReaderControllerResults];
    ZBarSymbol *symbol = nil;
    for(symbol in results)
        break;
    UIImage *image = [info objectForKey: UIImagePickerControllerOriginalImage];
    NSString *text =  symbol.data ;
    [self.delegate didScnnerResult:text andImage:image];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
