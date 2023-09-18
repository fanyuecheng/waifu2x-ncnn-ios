//
//  Waifu2x.h
//  Waifu2x
//
//  Created by Fancy on 2023/9/15.
//

#import <UIKit/UIKit.h>
#import <ncnn/mat.h>
#import "GPUInfo.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, Waifu2xModel) {
    Waifu2xModelCunet,
    Waifu2xModelUpconv7Anime,
    Waifu2xModelUpconv7Photo
};

typedef NS_ENUM(int, Waifu2xNoise) {
    Waifu2xNoiseNone = -1,
    Waifu2xNoise0 = 0,
    Waifu2xNoise1 = 1,
    Waifu2xNoise2 = 2,
    Waifu2xNoise3 = 3
};

typedef NS_ENUM(int, Waifu2xScale) {
    Waifu2xScale1 = 1,
    Waifu2xScale2 = 2
};
 
typedef void (^Waifu2xCompleteSingleBlock)(ncnn::Mat& frame, int current, uint64_t total);

@interface Waifu2xios : NSObject

+ (void)scaleImage:(UIImage *)image
             model:(Waifu2xModel)model
             noise:(Waifu2xNoise)noise
             scale:(Waifu2xScale)scale
          tileSize:(int)tileSize
             gpuId:(int)gpuId
           ttaMode:(BOOL)ttaMode
           loadJob:(int)loadJob
           procJob:(int)procJob
          finished:(Waifu2xCompleteSingleBlock)finished;

@end

NS_ASSUME_NONNULL_END
