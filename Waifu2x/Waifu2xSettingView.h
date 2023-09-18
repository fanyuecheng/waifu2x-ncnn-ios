//
//  Waifu2xSettingView.h
//  Waifu2x
//
//  Created by Fancy on 2023/9/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Waifu2xSettingView : UIView

@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UISegmentedControl *control;

- (instancetype)initWithName:(NSString *)name
                       items:(NSArray *)items;

@end

NS_ASSUME_NONNULL_END
