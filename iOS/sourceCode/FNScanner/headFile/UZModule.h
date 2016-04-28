//
//  UZModule.h
//  UZEngine
//
//  Created by broad on 13-11-6.
//  Copyright (c) 2013年 APICloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum _KUZModuleErrorType {
    kUZModuleErrorTypeNormal = 0,
} KUZModuleErrorType;

typedef enum _KUZStringType {
    kUZStringType_JSON = 0,
    kUZStringType_TEXT,
} KUZStringType;

@class UZWebView;

@interface UZModule : NSObject

@property (nonatomic, readonly, weak) UZWebView *uzWebView;
@property (nonatomic, readonly, weak) UIViewController *viewController;

#pragma mark - lifeCycle
- (id)initWithUZWebView:(UZWebView *)webView;
- (void)dispose;

#pragma mark - ret event
- (void)sendResultEventWithCallbackId:(NSInteger)cbId dataDict:(NSDictionary *)dataDict errDict:(NSDictionary *)errDict doDelete:(BOOL)doDelete;
- (void)sendResultEventWithCallbackId:(NSInteger)cbId dataString:(NSString *)dataString stringType:(KUZStringType)strType errDict:(NSDictionary *)errDict doDelete:(BOOL)doDelete;
- (void)deleteCallback:(NSInteger)cbId;
- (void)evalJs:(NSString *)js;

#pragma mark - utility methods
/*
 返回绝对路径，urlStr可能包含APICloud自定义协议路径，如'fs://', 'widget://', 'cache://'等
 */
- (NSString *)getPathWithUZSchemeURL:(NSString *)urlStr;

/*
 获取指定窗口，未找到指定name窗口时，返回主窗口
 */
- (UIWebView *)getViewByName:(NSString *)name;

/*
 在指定窗口上面添加视图，fixed为YES时表示视图镶嵌在窗口里面，跟随窗口内容移动
 */
- (void)addSubview:(UIView *)view fixedOn:(NSString *)fixedOn fixed:(BOOL)fixed;

/*
 从加密的key.xml文件中获取解密后的数据
 */
- (NSString *)securityValueForKey:(NSString *)key;

@end
