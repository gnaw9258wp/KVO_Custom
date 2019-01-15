//
//  Person.m
//  自定义KVO
//
//  Created by wp on 2019/1/15.
//  Copyright © 2019年 wp. All rights reserved.
//

#import "Person.h"

@implementation Person
- (void)setName:(NSString *)name
{
    _name = name;
    NSLog(@"%s",__func__);
}

-(void)dealloc{
    NSLog(@"%s",__func__);
}
@end
