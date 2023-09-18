//
//  ViewController.m
//  Waifu2x
//
//  Created by Fancy on 2023/9/18.
//

#import "ViewController.h"
#import "Waifu2xios.h"
#import "GPUInfo.h"
#import "Waifu2xSettingView.h"
#import "Waifu2xResultViewController.h"
#import <PhotosUI/PhotosUI.h>

@interface ViewController () <PHPickerViewControllerDelegate>
{
    VkInstance gpuInstance;
}

@property (strong)    NSArray<GPUInfo *> * gpus;
@property (nonatomic) uint32_t currentGPUID;
@property (nonatomic, strong) NSTimer *vramStaticticsTimer;

@property (nonatomic, strong) UILabel *gupLabel;
@property (nonatomic, strong) UILabel *usageLabel;
@property (nonatomic, strong) Waifu2xSettingView *modelView;
@property (nonatomic, strong) Waifu2xSettingView *noiseView;
@property (nonatomic, strong) Waifu2xSettingView *scaleView;
@property (nonatomic, strong) Waifu2xSettingView *ttaView;
@property (nonatomic, strong) Waifu2xSettingView *tileView;
@property (nonatomic, strong) UIButton *selectButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
     
    [self initUI];
    
    [self createGPUInstance];
     
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGFloat width = CGRectGetWidth(self.view.bounds);
    
    self.gupLabel.frame = CGRectMake(20, 100, width - 40, 30);
    self.usageLabel.frame = CGRectMake(20, 140, width - 40, 30);
    self.modelView.frame = CGRectMake(20, 180, width - 40, 30);
    self.noiseView.frame = CGRectMake(20, 220, width - 40, 30);
    self.scaleView.frame = CGRectMake(20, 260, width - 40, 30);
    self.ttaView.frame = CGRectMake(20, 300, width - 40, 30);
    self.tileView.frame = CGRectMake(20, 340, width - 40, 30);
    self.selectButton.frame = CGRectMake(20, 410, width - 40, 30);
}

#pragma mark - Method
- (void)initUI {
    self.gupLabel = ({
        UILabel *gupLabel = [[UILabel alloc] init];
        gupLabel.textColor = UIColor.labelColor;
        [self.view addSubview:gupLabel];
        gupLabel;
    });
    
    self.usageLabel = ({
        UILabel *usageLabel = [[UILabel alloc] init];
        usageLabel.textColor = UIColor.labelColor;
        [self.view addSubview:usageLabel];
        usageLabel;
    });
    
    self.modelView = ({
        Waifu2xSettingView *modelView = [[Waifu2xSettingView alloc] initWithName:@"Model" items:@[@"cunet", @"anime", @"photo"]];
        [self.view addSubview:modelView];
        modelView;
    });
    
    self.noiseView = ({
        Waifu2xSettingView *noiseView = [[Waifu2xSettingView alloc] initWithName:@"Noise" items:@[@"none", @"0", @"1", @"2", @"3"]];
        [self.view addSubview:noiseView];
        noiseView;
    });
 
    self.scaleView = ({
        Waifu2xSettingView *scaleView = [[Waifu2xSettingView alloc] initWithName:@"Scale" items:@[@"1", @"2"]];
        [self.view addSubview:scaleView];
        scaleView;
    });
    
    self.ttaView = ({
        Waifu2xSettingView *ttaView = [[Waifu2xSettingView alloc] initWithName:@"TTA" items:@[@"on", @"off"]];
        [self.view addSubview:ttaView];
        ttaView;
    });
  
    self.tileView = ({
        Waifu2xSettingView *tileView = [[Waifu2xSettingView alloc] initWithName:@"Tile" items:@[@"100", @"200",  @"400"]];
        [self.view addSubview:tileView];
        tileView;
    });
    
    self.selectButton = ({
        UIButton *selectButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        selectButton.titleLabel.font = [UIFont boldSystemFontOfSize:25];
        [selectButton setTitle:@"select image" forState:UIControlStateNormal];
        [selectButton addTarget:self action:@selector(selectAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:selectButton];
        selectButton;
    });
}

- (BOOL)createGPUInstance {
    // copied from Tencent/ncnn/gpu.cpp with minor changes
    // https://github.com/Tencent/ncnn/blob/master/src/gpu.cpp
    VkResult ret;

    std::vector<const char *> enabledLayers;
    std::vector<const char *> enabledExtensions;
    
    uint32_t instanceExtensionPropertyCount;
    ret = vkEnumerateInstanceExtensionProperties(NULL, &instanceExtensionPropertyCount, NULL);
    if (ret != VK_SUCCESS) {
        fprintf(stderr, "vkEnumerateInstanceExtensionProperties failed %d\n", ret);
        return NO;
    }

    std::vector<VkExtensionProperties> instanceExtensionProperties(instanceExtensionPropertyCount);
    ret = vkEnumerateInstanceExtensionProperties(NULL, &instanceExtensionPropertyCount, instanceExtensionProperties.data());
    if (ret != VK_SUCCESS) {
        fprintf(stderr, "vkEnumerateInstanceExtensionProperties failed %d\n", ret);
        return NO;
    }

    static int support_VK_KHR_get_physical_device_properties2 = 0;
    for (uint32_t j=0; j<instanceExtensionPropertyCount; j++) {
        const VkExtensionProperties& exp = instanceExtensionProperties[j];
        if (strcmp(exp.extensionName, "VK_KHR_get_physical_device_properties2") == 0) {
            support_VK_KHR_get_physical_device_properties2 = exp.specVersion;
        }
    }
    if (support_VK_KHR_get_physical_device_properties2) {
        enabledExtensions.push_back("VK_KHR_get_physical_device_properties2");
    }
        
    VkApplicationInfo applicationInfo;
    applicationInfo.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    applicationInfo.pNext = 0;
    applicationInfo.pApplicationName = "Image Super Resolution macOS";
    applicationInfo.applicationVersion = 0;
    applicationInfo.pEngineName = "isrmacos";
    applicationInfo.engineVersion = 20201210;
    applicationInfo.apiVersion = VK_MAKE_VERSION(1, 0, 0);

    VkInstanceCreateInfo instanceCreateInfo;
    instanceCreateInfo.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    instanceCreateInfo.pNext = 0;
    instanceCreateInfo.flags = 0;
    instanceCreateInfo.pApplicationInfo = &applicationInfo;
    instanceCreateInfo.enabledLayerCount = (uint32_t)enabledLayers.size();
    instanceCreateInfo.ppEnabledLayerNames = enabledLayers.data();
    instanceCreateInfo.enabledExtensionCount = (uint32_t)enabledExtensions.size();
    instanceCreateInfo.ppEnabledExtensionNames = enabledExtensions.data();

    ret = vkCreateInstance(&instanceCreateInfo, 0, &self->gpuInstance);
    if (ret != VK_SUCCESS) {
        fprintf(stderr, "vkCreateInstance failed %d\n", ret);
        return NO;
    }
    
    uint32_t physicalDeviceCount = 0;
    ret = vkEnumeratePhysicalDevices(self->gpuInstance, &physicalDeviceCount, 0);
    if (ret != VK_SUCCESS) {
        fprintf(stderr, "vkEnumeratePhysicalDevices failed %d\n", ret);
    }
    
    std::vector<VkPhysicalDevice> physicalDevices(physicalDeviceCount);
    ret = vkEnumeratePhysicalDevices(self->gpuInstance, &physicalDeviceCount, physicalDevices.data());
    if (ret != VK_SUCCESS) {
        fprintf(stderr, "vkEnumeratePhysicalDevices failed %d\n", ret);
    }
    
    NSMutableArray<GPUInfo *> * gpus = [NSMutableArray arrayWithCapacity:physicalDeviceCount];
    for (uint32_t i=0; i<physicalDeviceCount; i++) {
        const VkPhysicalDevice& physicalDevice = physicalDevices[i];
        VkPhysicalDeviceProperties physicalDeviceProperties;
        vkGetPhysicalDeviceProperties(physicalDevice, &physicalDeviceProperties);
        
        GPUInfo * info = [GPUInfo initWithName:[NSString stringWithFormat:@"%s", physicalDeviceProperties.deviceName] deviceID:i physicalDevice:physicalDevice];
        [gpus addObject:info];
    }
    
    self.gpus = [gpus sortedArrayUsingComparator:^NSComparisonResult(GPUInfo *  _Nonnull obj1, GPUInfo *  _Nonnull obj2) {
        if (obj1.deviceID < obj2.deviceID) {
            return NSOrderedAscending;
        } else{
            return NSOrderedDescending;
        };
    }];
    for (int i = 0; i < self.gpus.count; i++) {
        NSString *gpuName = [NSString stringWithFormat:@"GPU: [%u] %@", self.gpus[i].deviceID, self.gpus[i].name];
        NSLog(@"Found %@", gpuName);
        self.gupLabel.text = gpuName;
    }
    self.currentGPUID = 0;

    [self updateVRAMStaticticsWithTimeInterval:1.0];
    
    return YES;
}

- (void)updateVRAMStaticticsWithTimeInterval:(NSTimeInterval)interval {
    if (self.vramStaticticsTimer) {
        [self.vramStaticticsTimer setFireDate:[NSDate distantFuture]];
        [self.vramStaticticsTimer invalidate];
        self.vramStaticticsTimer = nil;
    }
    self.vramStaticticsTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(updateCurrentGPUVRAMStatictics) userInfo:nil repeats:YES];
    [self.vramStaticticsTimer setFireDate:[NSDate date]];
    [self.vramStaticticsTimer fire];
}

- (void)updateCurrentGPUVRAMStatictics {
    const auto& device = self.gpus[self.currentGPUID].physicalDevice;
    VkPhysicalDeviceProperties deviceProperties;
    vkGetPhysicalDeviceProperties(device, &deviceProperties);
    
    VkPhysicalDeviceMemoryProperties deviceMemoryProperties;
    VkPhysicalDeviceMemoryBudgetPropertiesEXT budget = {
        .sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_BUDGET_PROPERTIES_EXT
    };
    
    VkPhysicalDeviceMemoryProperties2 props = {
        .sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_PROPERTIES_2,
        .pNext = &budget,
        .memoryProperties = deviceMemoryProperties,
    };
    vkGetPhysicalDeviceMemoryProperties2(device, &props);
    
    double total = budget.heapBudget[0];
    double used = budget.heapUsage[0];
    total += used;
    
    total /= 1024.0 * 1024.0;
    used /= 1024.0 * 1024.0;
    self.usageLabel.text = [NSString stringWithFormat:@"VRAM: %.02lf/%.02lf MB", used, total];
}

- (void)scaleImage:(UIImage *)input {
    Waifu2xModel model = Waifu2xModelCunet;
    switch (self.modelView.control.selectedSegmentIndex) {
        case 0:
            model = Waifu2xModelCunet;
            break;
        case 1:
            model = Waifu2xModelUpconv7Anime;
            break;
        default:
            model = Waifu2xModelUpconv7Photo;
            break;
    }
    
    Waifu2xNoise noise = Waifu2xNoiseNone;
    switch (self.noiseView.control.selectedSegmentIndex) {
        case 0:
            noise = Waifu2xNoiseNone;
            break;
        case 1:
            noise = Waifu2xNoise0;
            break;
        case 2:
            noise = Waifu2xNoise1;
            break;
        case 3:
            noise = Waifu2xNoise2;
            break;
        default:
            noise = Waifu2xNoise3;
            break;
    }
    
    Waifu2xScale scale = Waifu2xScale1;
    switch (self.scaleView.control.selectedSegmentIndex) {
        case 0:
            scale = Waifu2xScale1;
            break;
        default:
            scale = Waifu2xScale2;
            break;
    }
    
    BOOL tta = YES;
    switch (self.ttaView.control.selectedSegmentIndex) {
        case 0:
            tta = YES;
            break;
        default:
            tta = NO;
            break;
    }
    
    int tileSize = 0;
    switch (self.tileView.control.selectedSegmentIndex) {
        case 0:
            tileSize = 100;
            break;
        case 1:
            tileSize = 200;
            break;
        default:
            tileSize = 400;
            break;
    }
    
    UIAlertController *loading = [UIAlertController alertControllerWithTitle:@"loading..." message:nil preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:loading animated:1 completion:nil];
    
    [Waifu2xios scaleImage:input
                     model:model
                     noise:noise
                     scale:scale
                  tileSize:tileSize
                     gpuId:self.currentGPUID
                   ttaMode:tta
                   loadJob:10
                   procJob:8
                  finished:^(ncnn::Mat &frame, int current, uint64_t total) {
        NSData *data = [NSData dataWithBytes:frame.data length:frame.total() * 4];
        CGColorSpaceRef colorSpace;
        CGBitmapInfo bitmapInfo;

        colorSpace = CGColorSpaceCreateDeviceRGB();
        bitmapInfo = kCGBitmapByteOrder32Little;
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);

        CGImageRef imageRef = CGImageCreate(frame.w,                         // width
                                            frame.h,                         // height
                                            8,                                      // bits per component
                                            8 * 4,              // bits per pixel
                                            frame.w * 4, // bytesPerRow
            colorSpace,                 // colorspace
            bitmapInfo,                 // bitmap info
            provider,                   // CGDataProviderRef
            NULL,                       // decode
            false,                      // should interpolate
            kCGRenderingIntentDefault   // intent
        );
        UIImage *result = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorSpace);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [loading dismissViewControllerAnimated:YES completion:^{
                Waifu2xResultViewController *resultController = [[Waifu2xResultViewController alloc] initWithOriginal:input result:result];
                UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:resultController];
                [self presentViewController:navigation animated:YES completion:nil];
            }];
        });
    }];
}

#pragma mark - Action
- (void)selectAction:(UIButton *)sender {
    PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
    config.selectionLimit = 1;
    config.filter = [PHPickerFilter imagesFilter];

    PHPickerViewController *pickerViewController = [[PHPickerViewController alloc] initWithConfiguration:config];
    pickerViewController.delegate = self;
     
    [self presentViewController:pickerViewController animated:YES completion:nil];
}

#pragma mark - PHPickerViewControllerDelegate
- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:^{
        for (PHPickerResult *result in results) {
            [result.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(__kindof id<NSItemProviderReading>  _Nullable object, NSError * _Nullable error) {
                if ([object isKindOfClass:[UIImage class]]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self scaleImage:object];
                    });
                }
            }];
        }
    }];
}

@end
