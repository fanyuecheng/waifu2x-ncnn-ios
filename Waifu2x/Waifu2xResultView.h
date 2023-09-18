//
//  Waifu2xResultView.h
//  Waifu2x
//
//  Created by Fancy on 2023/9/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Waifu2xResultView : UIView

- (instancetype)initWithOriginal:(UIImage *)original
                          result:(UIImage *)result;

@end

NS_ASSUME_NONNULL_END
