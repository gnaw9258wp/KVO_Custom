//
//  ViewController.m
//  KVO_custom
//
//  Created by wp on 2019/1/15.
//  Copyright © 2019年 wp. All rights reserved.
//

#import "ViewController.h"
#import "TwoViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    TwoViewController *vc = [TwoViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
