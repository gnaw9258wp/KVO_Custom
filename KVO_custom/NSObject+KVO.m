//
//  NSObject+KVO.m
//  自定义KVO
//
//  Created by wp on 2019/1/15.
//  Copyright © 2019年 wp. All rights reserved.
//

#import "NSObject+KVO.h"
#import <objc/message.h>

static const char*WPKVOKey = "WPKVOKey";

@interface WPInfo :NSObject
@property (nonatomic,weak)NSObject *observer;
@property (nonatomic,strong)NSString *keypath;
@property (nonatomic,copy)WPKVOBlock block;
@end

@implementation WPInfo

- (instancetype)initWithObserver:(NSObject *)observer
                         keypath:(NSString *)keypath
                           block:(WPKVOBlock)block{
    if (self = [super init]) {
        self.observer = observer;
        self.keypath = keypath;
        self.block = block;
    }
    return self;
}

@end

@implementation NSObject (KVO)

- (void)wp_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath block:(WPKVOBlock )block
{
    //动态创建一个子类
    Class newCLass= [self creatClass:keyPath];
    //修改isa指向
    object_setClass(self, newCLass);
    //信息保存
    WPInfo *info = [[WPInfo alloc]initWithObserver:observer keypath:keyPath block:block];
    NSMutableArray *array = objc_getAssociatedObject(self, WPKVOKey);
    if (!array) {
        array = [NSMutableArray array];
        objc_setAssociatedObject(self, WPKVOKey, array, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [array addObject:info];
}

- (void)wp_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context
{
    //动态创建一个子类
    Class newCLass= [self creatClass:keyPath];
    //修改isa指向
    object_setClass(self, newCLass);
    //关联方法
    objc_setAssociatedObject(self, (__bridge void *)@"objc", observer, OBJC_ASSOCIATION_ASSIGN);
    

}

- (void)wp_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(nullable void *)context
{
    
    Class superClass = class_getSuperclass(object_getClass(self));
    object_setClass(self, superClass);
}

//NSKVONotifying_PPerson
- (Class)creatClass:(NSString *)keyPath{
    //动态添加方法(setter class)

    //拼接自子类
    NSString *oldName = NSStringFromClass([self class]);
    NSString *newName = [[NSString alloc]initWithFormat:@"NSKVONotifying_%@",oldName];
    //创建并注册类
    Class newClass = NSClassFromString(newName);
    if (!newClass) {
        newClass = objc_allocateClassPair([self class], newName.UTF8String, 0);
        objc_registerClassPair(newClass);
        //添加一些方法
        //class
        Method classMethod = class_getInstanceMethod([self class], @selector(class));
        const char* classTypes = method_getTypeEncoding(classMethod);
        class_addMethod(newClass, @selector(class), (IMP)wp_class, classTypes);
        //setter方法
        NSString *setterMethodName = setterForGeter(keyPath);
        SEL setterSEL = NSSelectorFromString(setterMethodName);
        Method setterMethod = class_getInstanceMethod([self class], setterSEL);
        const char* setterTypes = method_getTypeEncoding(setterMethod);
        class_addMethod(newClass, setterSEL, (IMP)wp_setter, setterTypes);
        
        
        //添加析构方法
//        SEL deallocSEL = NSSelectorFromString(@"dealloc");
//        Method deallocMethod = class_getInstanceMethod([self class], deallocSEL);
//        const char* deallocTypes = method_getTypeEncoding(deallocMethod);
//        class_addMethod(newClass, deallocSEL, (IMP)my_dealloc, deallocTypes);
        
        //hook dealloc 在dealloc的时候自动销毁
//        [self hookDealloc];
    }
    return newClass;
}

- (void)hookDealloc{
    Method m1 = class_getInstanceMethod(object_getClass(self), NSSelectorFromString(@"delloc"));
    Method m2 = class_getInstanceMethod(object_getClass(self), @selector(wp_delloc));
    method_exchangeImplementations(m1, m2);
}

void my_dealloc(id self,SEL _cmd){
    Class class = object_getClass(self);
    Class superClass = class_getSuperclass(class);
    object_setClass(self, superClass);
}

- (void)wp_delloc{
    [self wp_delloc];
    Class superClass = class_getSuperclass(object_getClass(self));
    object_setClass(self, superClass);
}

#pragma mark -c 函数

static void wp_setter(id self,SEL _cmd,id newValue){
    NSLog(@"%s", __func__);
    
    struct objc_super superStruct = {
        self,
        class_getSuperclass(object_getClass(self))
    };
    
    /*
      不使用block
      //改变父类的值
     objc_msgSendSuper(&superStruct, _cmd, newValue);此时Person类中的setter方法打印了
     
     // 通知观察者， 值发生改变了
     // 观察者
     id observer = objc_getAssociatedObject(self, (__bridge void *)@"objc");
     NSString* setterName = NSStringFromSelector(_cmd);
     NSString* key = getterForSetter(setterName);
     objc_msgSend(observer, @selector(observeValueForKeyPath:ofObject:change:context:), key, self, @{key:newValue}, nil);
     objc_msgSend(observer, @selector(observeValueForKeyPath:ofObject:change:context:), key, self, @{key:newValue}, nil);
     */

     //使用block
    NSString *keyPath = getterForSetter(NSStringFromSelector(_cmd));
    //获取旧值
    id oldValue = objc_msgSendSuper(&superStruct, NSSelectorFromString(keyPath)); //kvc getter方法
    //改变父类的值
    objc_msgSendSuper(&superStruct, _cmd, newValue);//此时使用的Person中的setter方法打印了
    NSMutableArray *array = objc_getAssociatedObject(self, WPKVOKey);
    if (!array) {
        return;
    }
    for (WPInfo *info in array) {
        if ([info.keypath isEqualToString:keyPath] && info.block) {
            info.block(info.observer, keyPath, oldValue, newValue);
            return;
        }
    }
    
}

Class wp_class(id self,SEL _cmd){
    return class_getSuperclass(object_getClass(self));
}

#pragma mark - 从get方法获取set方法的名称 key ===>>> setKey:
static NSString *setterForGeter(NSString *getter){
    if (getter.length < 0) {
        return nil;
    }
    NSString *firstString = [[getter substringToIndex:1] uppercaseString];
    NSString *leavestring = [getter substringFromIndex:1];
    return [NSString stringWithFormat:@"set%@%@:",firstString,leavestring];
}

#pragma mark - 从set方法获取getter方法的名称 set<Key>:===> Key
static NSString * getterForSetter(NSString *setter){
    
    if (setter.length <= 0 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"]) { return nil;}
    
    NSRange range = NSMakeRange(3, setter.length-4);
    NSString *getter = [setter substringWithRange:range];
    NSString *firstString = [[getter substringToIndex:1] lowercaseString];
    getter = [getter stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstString];
    
    return getter;
}
@end
