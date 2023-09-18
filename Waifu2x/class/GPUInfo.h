//
//  GPUInfo.h
//  Waifu2x
//
//  Created by Fancy on 2023/9/15.
//

#import <Foundation/Foundation.h>
#import <vulkan/vulkan.h>

NS_ASSUME_NONNULL_BEGIN

@interface GPUInfo : NSObject

@property (nonatomic, copy)   NSString *name;
@property (nonatomic, assign) uint32_t deviceID;
@property (nonatomic, assign) VkPhysicalDevice physicalDevice;

+ (instancetype)initWithName:(NSString *)name
                    deviceID:(uint32_t)deviceID
              physicalDevice:(VkPhysicalDevice)device;
 
@end

NS_ASSUME_NONNULL_END
