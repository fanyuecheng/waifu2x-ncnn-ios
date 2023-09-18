//
//  Waifu2x.m
//  Waifu2x
//
//  Created by Fancy on 2023/9/15.
//

#import "Waifu2xios.h"
#import "waifu2x.h"
#import <unistd.h>
#import <algorithm>
#import <vector>
#import <queue>
#import <thread>

// image decoder and encoder with stb
#define STB_IMAGE_IMPLEMENTATION
#define STBI_NO_PSD
#define STBI_NO_TGA
#define STBI_NO_GIF
#define STBI_NO_HDR
#define STBI_NO_PIC
#include "stb_image.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

// ncnn
#include <ncnn/cpu.h>
#include <ncnn/gpu.h>
#include <ncnn/platform.h>
#include "filesystem_utils.h"

class Task
{
public:
    int id;

    path_t inpath;
    path_t outpath;
    bool save_file;

    ncnn::Mat inimage;
    ncnn::Mat outimage;
    uint64_t total;
};

class TaskQueue
{
public:
    TaskQueue()
    {
    }

    void put(const Task& v)
    {
        lock.lock();
        while (tasks.size() >= 8) // FIXME hardcode queue length
        {
            condition.wait(lock);
        }
        tasks.push(v);
        lock.unlock();
        condition.signal();
    }

    void get(Task& v)
    {
        lock.lock();
        while (tasks.size() == 0)
        {
            condition.wait(lock);
        }
        v = tasks.front();
        tasks.pop();
        lock.unlock();
        condition.signal();
    }

private:
    ncnn::Mutex lock;
    ncnn::ConditionVariable condition;
    std::queue<Task> tasks;
};

TaskQueue toproc;
TaskQueue tosave;

class ProcThreadParams
{
public:
    const Waifu2x *waifu2x;
};

void *proc(void *args)
{
    const ProcThreadParams *ptp = (const ProcThreadParams *)args;
    const Waifu2x *waifu2x = ptp->waifu2x;

    for (;;)
    {
        Task v;
        toproc.get(v);
        if (v.id == -233)
            break;
        waifu2x->process(v.inimage, v.outimage);
        tosave.put(v);
    }
    return 0;
}

class SaveThreadParams
{
public:
    int verbose;
    Waifu2xCompleteSingleBlock cb;
};
 
void *save(void *args)
{
    const SaveThreadParams *stp = (const SaveThreadParams *)args;
    const int verbose = stp->verbose;
    for (;;)
    {
        Task v;
        tosave.get(v);
        if (v.id == -233)
            break;
        if (stp->cb) {
            // most of the output are correct
            stp->cb(v.outimage, v.id, v.total);
        }
    }
    return 0;
}

@implementation Waifu2xios

+ (void)scaleImage:(UIImage *)image
             model:(Waifu2xModel)model
             noise:(Waifu2xNoise)noise
             scale:(Waifu2xScale)scale
          tileSize:(int)tileSize
             gpuId:(int)gpuId
           ttaMode:(BOOL)ttaMode
           loadJob:(int)jobs_load
           procJob:(int)jobs_proc
          finished:(Waifu2xCompleteSingleBlock)finished {
    if (!image) {
        NSLog(@"[ERROR] input is none");
        return;
    }
    if (tileSize < 32) {
        NSLog(@"[ERROR] tilesize should no less than 32");
        return;
    }
    
    if (jobs_proc <= 0) {
        jobs_proc = INT32_MAX;
    }
    
    if (jobs_load <= 0) {
        jobs_load = 1;
    }
    
    if (model != Waifu2xModelCunet && scale == Waifu2xScale1) {
        scale = Waifu2xScale2;
    }
 
    NSString *paramPath = nil;
    NSString *modelPath = nil;
    NSString *resourcePath = nil;
    NSBundle *modelBundle = [NSBundle bundleWithPath:[NSBundle.mainBundle pathForResource:@"waifu2x" ofType:@"bundle"]];
    NSString *modelType = nil;
    int prepadding = 0;
    if (model == Waifu2xModelCunet) {
        modelType = @"models-cunet";
        if (noise == Waifu2xNoiseNone) {
            prepadding = 18;
        } else if (scale == Waifu2xScale1) {
            prepadding = 28;
        } else if (scale == Waifu2xScale2) {
            prepadding = 18;
        }
    } else if (model == Waifu2xModelUpconv7Anime) {
        modelType = @"models-upconv_7_anime_style_art_rgb";
        prepadding = 7;
    } else {
        modelType = @"models-upconv_7_photo";
        prepadding = 7;
    }
    if (noise == Waifu2xNoiseNone) {
        resourcePath = [NSString stringWithFormat:@"%@/scale2.0x_model", modelType];
    } else if (scale == Waifu2xScale1) {
        resourcePath = [NSString stringWithFormat:@"%@/noise%d_model", modelType, noise];
    } else if (scale == Waifu2xScale2) {
        resourcePath = [NSString stringWithFormat:@"%@/noise%d_scale2.0x_model", modelType, noise];
    }

    paramPath = [modelBundle pathForResource:resourcePath ofType:@"param"];
    modelPath = [modelBundle pathForResource:resourcePath ofType:@"bin"];
    
    ncnn::create_gpu_instance();
    int cpu_count = std::max(1, ncnn::get_cpu_count());
    jobs_load = std::min(jobs_load, cpu_count);
    
    int gpu_count = ncnn::get_gpu_count();
    if (gpuId < 0 || gpuId >= gpu_count)
    {
        NSLog(@"[ERROR] Invalid gpu device");
        ncnn::destroy_gpu_instance();
        return;
    }
    
    int gpu_queue_count = ncnn::get_gpu_info(gpuId).compute_queue_count();
    const_cast<ncnn::GpuInfo&>(ncnn::get_gpu_info(gpuId)).buffer_offset_alignment();
    jobs_proc = std::min(jobs_proc, gpu_queue_count);
    
    {
        Waifu2x waifu2x(gpuId, ttaMode);
        waifu2x.load([paramPath UTF8String], [modelPath UTF8String]);
        waifu2x.noise = noise;
        waifu2x.scale = scale;
        waifu2x.tilesize = tileSize;
        waifu2x.prepadding = prepadding;
        
        {
            Task v;
            v.id = 1;
            
            CGImageRef imageRef = [image CGImage];
            NSUInteger width = CGImageGetWidth(imageRef);
            NSUInteger height = CGImageGetHeight(imageRef);
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            unsigned char *rawData = (unsigned char *)calloc(height * width * 4, sizeof(unsigned char));
            NSUInteger bytesPerPixel = 4;
            NSUInteger bytesPerRow = bytesPerPixel * width;
            NSUInteger bitsPerComponent = 8;
            CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
            CGColorSpaceRelease(colorSpace);
            CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
            CGContextRelease(context);

            v.inimage = ncnn::Mat((int)width, (int)height, (void *)rawData, (size_t)4, 4);
            v.outimage = ncnn::Mat((int)width * scale, (int)height * scale, (size_t)4u, 4);
            toproc.put(v);
            
            // waifu2x proc
            ProcThreadParams ptp;
            ptp.waifu2x = &waifu2x;

            std::vector<ncnn::Thread*> proc_threads(jobs_proc);
            for (int i = 0; i < jobs_proc; i++) {
                proc_threads[i] = new ncnn::Thread(proc, (void *)&ptp);
            }

            // save image
            SaveThreadParams stp;
            stp.verbose = 0;
            stp.cb = finished;
            
            std::vector<ncnn::Thread *> save_threads(1);
            save_threads[0] = new ncnn::Thread(save, (void *)&stp);
            Task end;
            end.id = -233;

            for (int i = 0; i < jobs_proc; i ++) {
                toproc.put(end);
            }
 
            for (int i = 0; i < jobs_proc; i ++) {
                proc_threads[i]->join();
                delete proc_threads[i];
            }
             
            for (int i = 0; i < 1; i ++) {
                tosave.put(end);
            }

            for (int i = 0; i < 1; i ++) {
                save_threads[i]->join();
                delete save_threads[i];
            }
            free(rawData);
        }
    }
        
    ncnn::destroy_gpu_instance();
}

@end

