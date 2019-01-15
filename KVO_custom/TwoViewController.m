//
//  TwoViewController.m
//  自定义KVO
//
//  Created by wp on 2019/1/15.
//  Copyright © 2019年 wp. All rights reserved.
//

#import "TwoViewController.h"
#import "NSObject+KVO.h"
#import "Person.h"
#import <objc/message.h>
@interface TwoViewController ()
@property (nonatomic,strong)Person *person;

@end

@implementation TwoViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    Person *person = [Person new];
    self.person = person;
    
//    [self.person wp_addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
    
    [self.person wp_addObserver:self forKeyPath:@"name" block:^(id  _Nonnull observer, NSString * _Nonnull keyPath, id  _Nonnull oldValue, id  _Nonnull newValue) {
        NSLog(@"oldValue= %@ newValue= %@ keyPath= %@",oldValue,newValue,keyPath);
    }];
    [self printClasses:[Person class]];
}

- (void)dealloc
{
    [self.person wp_removeObserver:self forKeyPath:@"name" context:nil];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.person.name = @"1213";
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"%@", change);
}

// 打印对应的类及子类
- (void) printClasses:(Class) cls {
    
    /// 注册类的总数
    int count = objc_getClassList(NULL, 0);
    
    /// 创建一个数组， 其中包含给定对象
    NSMutableArray* array = [NSMutableArray arrayWithObject:cls];
    
    /// 获取所有已注册的类
    Class* classes = (Class*)malloc(sizeof(Class)*count);
    objc_getClassList(classes, count);
    
    /// 遍历s
    for (int i = 0; i < count; i++) {
        if (cls == class_getSuperclass(classes[i])) {
            [array addObject:classes[i]];
        }
    }
    
    free(classes);
    
    NSLog(@"classes = %@", array);
}
@end
