//
//  NSObject+KVO.h
//  自定义KVO
//
//  Created by wp on 2019/1/15.
//  Copyright © 2019年 wp. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


typedef void(^WPKVOBlock)(id observer,NSString *keyPath,id oldValue,id newValue);

@interface NSObject (KVO)

- (void)wp_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath block:(WPKVOBlock )block;

- (void)wp_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context;

- (void)wp_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(nullable void *)context;
@end

NS_ASSUME_NONNULL_END
