/**
 * APICloud Modules
 * Copyright (c) 2014-2018 by APICloud, Inc. All Rights Reserved.
 * Licensed under the terms of the The MIT License (MIT).
 * Please see the license.html included with this distribution for details.
 */

#import "ZBarReaderViewController.h"

@protocol OrentationChangedDelegate;

@interface UZFNBarViewController : ZBarReaderViewController

@property (nonatomic, assign) id <OrentationChangedDelegate> orDelegate;

@end

@protocol OrentationChangedDelegate <NSObject>

- (void)changeToLeft:(UZFNBarViewController *)reader;
- (void)changeToRight:(UZFNBarViewController *)reader;
- (void)changeToPortrait:(UZFNBarViewController *)reader;

@end
