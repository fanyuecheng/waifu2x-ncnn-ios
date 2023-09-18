//
//  GPUInfo.m
//  Waifu2x
//
//  Created by Fancy on 2023/9/15.
//

#import "GPUInfo.h"

@implementation GPUInfo

+ (instancetype)initWithName:(NSString *)name
                    deviceID:(uint32_t)deviceID
              physicalDevice:(VkPhysicalDevice)device {
    GPUInfo *info = [[GPUInfo alloc] init];
    if (info) {
        [info setName:name];
        [info setDeviceID:deviceID];
        [info setPhysicalDevice:device];
    }
    return info;
}

@end
