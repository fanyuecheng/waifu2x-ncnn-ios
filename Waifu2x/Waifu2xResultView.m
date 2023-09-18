//
//  Waifu2xResultView.m
//  Waifu2x
//
//  Created by Fancy on 2023/9/18.
//

#import "Waifu2xResultView.h"
#import "WMDragView.h"

@interface Waifu2xResultView ()

@property (nonatomic, strong) UIImage *original;
@property (nonatomic, strong) UIImage *result;

@property (nonatomic, strong) UIView *leftView;
@property (nonatomic, strong) UIView *rightView;
@property (nonatomic, strong) UIImageView *originalView;
@property (nonatomic, strong) UIImageView *resultView;
@property (nonatomic, strong) WMDragView *dragView;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, assign) CGFloat progress;

@end

@implementation Waifu2xResultView

- (instancetype)initWithOriginal:(UIImage *)original
                          result:(UIImage *)result {
    if (self = [super init]) {
        self.original = original;
        self.result = result;
        self.originalView = ({
            UIImageView *originalView = [[UIImageView alloc] initWithImage:original];
            originalView.contentMode = UIViewContentModeScaleAspectFill;
            originalView;
        });
        self.resultView = ({
            UIImageView *resultView = [[UIImageView alloc] initWithImage:result];
            resultView.contentMode = UIViewContentModeScaleAspectFill;
            resultView;
        });
        self.leftView = ({
            UIView *leftView = [[UIView alloc] init];
            leftView.clipsToBounds = YES;
            [leftView addSubview:self.originalView];
            [self addSubview:leftView];
            leftView;
        });
        self.rightView = ({
            UIView *rightView = [[UIView alloc] init];
            rightView.clipsToBounds = YES;
            [rightView addSubview:self.resultView];
            [self addSubview:rightView];
            rightView;
        });
        self.dragView = ({
            WMDragView *dragView = [[WMDragView alloc] init];
            dragView.dragDirection = WMDragDirectionHorizontal;
            __weak __typeof(self)weakSelf = self;
            dragView.duringDragBlock = ^(WMDragView *view) {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                if (CGRectGetMinX(view.frame) <= -20 || CGRectGetMaxX(view.frame) >= CGRectGetWidth(self.bounds) - 20) {
                    return;
                }
                [strongSelf setNeedsLayout];
                [strongSelf layoutIfNeeded];
            };
            
            dragView.backgroundColor = UIColor.clearColor;
            [self addSubview:dragView];
            dragView;
        });
        
        self.lineView = ({
            UIView *lineView = [[UIView alloc] init];
            lineView.backgroundColor = UIColor.systemBlueColor;
            [self.dragView addSubview:lineView];
            lineView;
        });
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);
    CGFloat imageHeight = width * self.original.size.height / self.original.size.width;
    CGFloat imageTop = (height - imageHeight) * 0.5;
    
    self.progress = self.dragView.center.x / width;
     
    self.leftView.frame = CGRectMake(0, imageTop, width * self.progress, imageHeight);
    self.rightView.frame = CGRectMake(width * self.progress, imageTop, width * (1 - self.progress), imageHeight);
    self.originalView.frame = CGRectMake(0, 0, width, imageHeight);
    self.resultView.frame = CGRectMake(-CGRectGetWidth(self.leftView.bounds), 0, width, imageHeight);
    if (CGRectEqualToRect(self.dragView.bounds, CGRectZero)) {
        self.dragView.frame = CGRectMake((width - 40) * 0.5, imageTop, 40, imageHeight);
        self.dragView.freeRect = CGRectMake(-20, imageTop, width + 40, imageHeight);
        self.lineView.frame = CGRectMake(19, 0, 2, imageHeight);
    }
}

@end
