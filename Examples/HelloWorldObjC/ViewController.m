//
//  ViewController.m
//  HelloWorldObjC
//
//  Created by Mladjan Antic on 19.6.23..
//

#import "ViewController.h"
@import Aptabase;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[Aptabase shared] trackEvent:@"test" with:@{@"name":@"works"}];

}


@end
