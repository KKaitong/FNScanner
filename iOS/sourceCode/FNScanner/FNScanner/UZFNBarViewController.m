/**
 * APICloud Modules
 * Copyright (c) 2014-2018 by APICloud, Inc. All Rights Reserved.
 * Licensed under the terms of the The MIT License (MIT).
 * Please see the license.html included with this distribution for details.
 */

#import "UZFNBarViewController.h"

@interface UZFNBarViewController ()

@end

@implementation UZFNBarViewController
@synthesize orDelegate;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarOrientationChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation NS_DEPRECATED_IOS(2_0, 6_0) {
    return NO;
}

- (void)statusBarOrientationChange:(NSNotification *)notification {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    switch (orientation) {
        case UIInterfaceOrientationUnknown:
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown: {
            if ([self.orDelegate respondsToSelector:@selector(changeToPortrait:)]) {
                [self.orDelegate changeToPortrait:self];
            }
        }
            break;
            
        case UIInterfaceOrientationLandscapeLeft: {
            if ([self.orDelegate respondsToSelector:@selector(changeToPortrait:)]) {
                [self.orDelegate changeToLeft:self];
            }
        }
            break;
            
        case UIInterfaceOrientationLandscapeRight:{
            if ([self.orDelegate respondsToSelector:@selector(changeToPortrait:)]) {
                [self.orDelegate changeToRight:self];
            }
        }
            break;
            
        default: {
            if ([self.orDelegate respondsToSelector:@selector(changeToPortrait:)]) {
                [self.orDelegate changeToPortrait:self];
            }
            
        }
            break;
    }
    
}

- (BOOL)shouldAutorotate {
    return NO;
    switch (self.interfaceOrientation) {
        case UIInterfaceOrientationUnknown:
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown: {
            if ([self.orDelegate respondsToSelector:@selector(changeToPortrait:)]) {
                [self.orDelegate changeToPortrait:self];
            }
        }
            break;
            
        case UIInterfaceOrientationLandscapeLeft: {
            if ([self.orDelegate respondsToSelector:@selector(changeToPortrait:)]) {
                [self.orDelegate changeToLeft:self];
            }
        }
            break;
            
        case UIInterfaceOrientationLandscapeRight:{
            if ([self.orDelegate respondsToSelector:@selector(changeToPortrait:)]) {
                [self.orDelegate changeToRight:self];
            }
        }
            break;
            
        default: {
            if ([self.orDelegate respondsToSelector:@selector(changeToPortrait:)]) {
                [self.orDelegate changeToPortrait:self];
            }
            
        }
            break;
    }
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

@end
