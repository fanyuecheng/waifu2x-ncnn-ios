//
//  Waifu2xResultViewController.m
//  Waifu2x
//
//  Created by Fancy on 2023/9/18.
//

#import "Waifu2xResultViewController.h"
#import "Waifu2xResultView.h"

@interface Waifu2xResultViewController ()

@property (nonatomic, strong) Waifu2xResultView *resultView;

@end

@implementation Waifu2xResultViewController

- (instancetype)initWithOriginal:(UIImage *)original
                          result:(UIImage *)result {
    if (self = [super init]) {
        self.resultView = ({
            Waifu2xResultView *resultView = [[Waifu2xResultView alloc] initWithOriginal:original result:result];
            resultView;
        });
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    
    [self.view addSubview:self.resultView];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose target:self action:@selector(closeAction:)];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.resultView.frame = self.view.bounds;
}

#pragma mark - Action
- (void)closeAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
