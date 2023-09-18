//
//  Waifu2xSettingView.m
//  Waifu2x
//
//  Created by Fancy on 2023/9/18.
//

#import "Waifu2xSettingView.h"

@implementation Waifu2xSettingView

- (instancetype)initWithName:(NSString *)name
                       items:(NSArray *)items {
    if (self = [super init]) {
        self.nameLabel = ({
            UILabel *nameLabel = [[UILabel alloc] init];
            nameLabel.textColor = UIColor.labelColor;
            nameLabel.text = name;
            [self addSubview:nameLabel];
            nameLabel;
        });
        
        self.control = ({
            UISegmentedControl *control = [[UISegmentedControl alloc] initWithItems:items];
            control.selectedSegmentIndex = 0;
            [self addSubview:control];
            control;
        });
    }
    return self;
}
 
- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat width = CGRectGetWidth(self.bounds);
    
    self.nameLabel.frame = CGRectMake(0, 0, 50, 30);
    self.control.frame = CGRectMake(60, 0, width - 60, 30);
}


@end
