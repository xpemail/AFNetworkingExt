//
//  UIImageBatchLoadingManager.m 
//

#import "AFUIImageBatchLoadingManager.h"
#import "AFImageDownloadRequest.h"
#import "AFNetworkingHttpQueueManager.h"
#import "UIImageView+AddLoadingPath.h"


NSString *const kAFDYUIImageViewLoadedImageNotification       = @"kDYUIImageViewLoadedImageNotification";


@implementation AFUIImageLoadedEntry

@synthesize imagePath,image;

@end

@interface AFUIImageBatchLoadEntry : NSObject
@property (nonatomic,strong) NSString *loadKey;    //请求标识，url
@property (nonatomic,strong) NSMutableSet *imagesTokens;   //待处理图片标识
@property (nonatomic,strong) NSMutableSet *waitTokens;   //待处理图片标识
@property (nonatomic,assign) NSInteger queueId;
@property (nonatomic,assign) NSInteger requestId;

@end

@implementation AFUIImageBatchLoadEntry

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.imagesTokens =[[NSMutableSet alloc] init];
        self.waitTokens=[[NSMutableSet alloc] init];
    }
    return self;
}

@end

@interface AFUIImageBatchLoadingManager(){

    dispatch_queue_t  image_process_queue;
}
@property (nonatomic,strong) NSMutableDictionary *poolDictionary;

@end

@implementation AFUIImageBatchLoadingManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.poolDictionary=[[NSMutableDictionary alloc] init];
        image_process_queue =dispatch_queue_create("UIImageBatchLoadingManager_IMAGE_PROCESS_QUEUE", NULL);
    }
    return self;
}
static long long number =0;
+(NSString *)loadingToken{
    NSString *token = nil;
    @synchronized(lock){
        token =[NSString stringWithFormat:@"%lld",number];
        number++;
    }
    return token;
}

static NSObject *lock;
+(AFUIImageBatchLoadingManager *)shareInstance{
    static AFUIImageBatchLoadingManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AFUIImageBatchLoadingManager alloc] init];
        lock = [[NSObject alloc] init];
    });
    return sharedInstance;
}

+(void)addWaitPath:(NSString *)path token:(NSString *)token{
    @synchronized(lock){
        AFUIImageBatchLoadingManager *imageLoadManager=[AFUIImageBatchLoadingManager shareInstance];
        AFUIImageBatchLoadEntry *entry=[imageLoadManager.poolDictionary objectForKey:path];
        if(entry==nil){
            entry = [[AFUIImageBatchLoadEntry alloc] init];
            [imageLoadManager.poolDictionary setObject:entry forKey:path];
        }
        [entry.waitTokens addObject:token];
    }
    
}

+ (BOOL)isWaiting:(NSString *)path{
    BOOL result = NO;
    @synchronized(lock){
        AFUIImageBatchLoadingManager *imageLoadManager=[AFUIImageBatchLoadingManager shareInstance];
        AFUIImageBatchLoadEntry *entry=[imageLoadManager.poolDictionary objectForKey:path];
        if(entry){
            result = entry.waitTokens.count>0;
        }
    }
    return result;
}

+(void)removeWait:(NSString *)path token:(NSString *)token{
    @synchronized(lock){
        AFUIImageBatchLoadingManager *imageLoadManager=[AFUIImageBatchLoadingManager shareInstance];
        AFUIImageBatchLoadEntry *entry=[imageLoadManager.poolDictionary objectForKey:path];
        if(entry!=nil){
            [entry.waitTokens removeObject:token];
        }
    }
    
}

+(void)addLoadPath:(NSString *)path token:(NSString *)token{
    @synchronized(lock){
        AFUIImageBatchLoadingManager *imageLoadManager=[AFUIImageBatchLoadingManager shareInstance];
        AFUIImageBatchLoadEntry *entry=[imageLoadManager.poolDictionary objectForKey:path];
        if(entry==nil){
            entry = [[AFUIImageBatchLoadEntry alloc] init];
            [imageLoadManager.poolDictionary setObject:entry forKey:path];
        }
        [entry.imagesTokens addObject:token];
    }

}

+ (BOOL)isDownloading:(NSString *)path{
    BOOL result = NO;
    @synchronized(lock){
        AFUIImageBatchLoadingManager *imageLoadManager=[AFUIImageBatchLoadingManager shareInstance];
        AFUIImageBatchLoadEntry *entry=[imageLoadManager.poolDictionary objectForKey:path];
        if(entry){
            result =  entry.imagesTokens.count>0;
        }
    }
    return result;
}

+(void)addLoadPath:(NSString *)path  token:(NSString *)token queue:(NSInteger)queueId requestId:(NSInteger)requestId{
    @synchronized(lock){
        AFUIImageBatchLoadingManager *imageLoadManager=[AFUIImageBatchLoadingManager shareInstance];
        AFUIImageBatchLoadEntry *entry=[imageLoadManager.poolDictionary objectForKey:path];
        if(entry==nil){
            entry = [[AFUIImageBatchLoadEntry alloc] init];
            [imageLoadManager.poolDictionary setObject:entry forKey:path];
        }
        entry.requestId =requestId;
        entry.queueId   =queueId;
        [entry.imagesTokens addObject:token];
    }
    
}

+(void)removeLoadPath:(NSString *)path token:(NSString *)token{
    @synchronized(lock){
        AFUIImageBatchLoadingManager *imageLoadManager=[AFUIImageBatchLoadingManager shareInstance];
        AFUIImageBatchLoadEntry *entry=[imageLoadManager.poolDictionary objectForKey:path];
        if(entry!=nil){
            [entry.imagesTokens removeObject:token];
            
            if(entry.imagesTokens.count==0&&entry.queueId>0&&entry.requestId>0){
                [AFNetworkHttpRequestManager cancelQueue:entry.queueId requestId:entry.requestId];
            }
            [imageLoadManager.poolDictionary removeObjectForKey:path];
        }
    }
    
}

+ (void)removeAllLoad:(NSString *)path{
    @synchronized(lock){
        AFUIImageBatchLoadingManager *imageLoadManager=[AFUIImageBatchLoadingManager shareInstance];
        [imageLoadManager.poolDictionary removeObjectForKey:path];
    }
}


-(void)startLoad:(NSString *)resourcePath token:(NSString *)token url:(NSString *)url cacheKey:(NSString *)cacheKey queueId:(NSInteger)queueId isLocal:(BOOL)local{
    
    __block NSString *blockResourcePath = resourcePath;
    __block NSString *blockToken = token;
    __block NSString *blockURL = url;
    __block NSString *blockCacheKey = cacheKey;
    __block NSInteger blockQueueId = queueId;
    __block BOOL      blockLocal = local;
    
    __block AFUIImageBatchLoadingManager *weakSelf = self;
    
    [AFUIImageBatchLoadingManager addWaitPath:blockResourcePath token:blockToken];
    
    dispatch_async(image_process_queue, ^{
        @autoreleasepool {
            @try {
                
                if(![AFUIImageBatchLoadingManager isWaiting:blockResourcePath]){
                    return;
                }
                
                
                [AFUIImageBatchLoadingManager removeWait:blockResourcePath token:blockToken];
                
                if(blockLocal){
                    // TODO: 处理本地图片，
                    [weakSelf processLocalImage:blockResourcePath cacheKey:blockCacheKey];
                    
                }else{
                    
                    
                    //TODO 检查队列
                    if([AFUIImageBatchLoadingManager isDownloading:blockResourcePath]){
                        [AFUIImageBatchLoadingManager addLoadPath:blockResourcePath token:blockToken];
                        return;
                    }
                    
                    //删除错误图片
                    
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    BOOL existed = [fileManager fileExistsAtPath:blockResourcePath];
                    if(existed){
                        UIImage *image=[[UIImage alloc]  initWithContentsOfFile:blockResourcePath];
                        if(image){
                            // TODO: 处理本地图片，
                            [weakSelf processLocalImage:blockResourcePath cacheKey:blockCacheKey];
                        
                            return;
                        }else{
                            [fileManager removeItemAtPath:blockResourcePath error:NULL];
                        }
                    }
                     
                    
                    AFImageDownloadRequest *downloadRequest=[[AFImageDownloadRequest alloc] initWithURL:blockURL];
                    downloadRequest.filePath=blockResourcePath;
                    
#if DEBUG
                    NSLog(@"url requestId:%d imageUrl:%@",(int)downloadRequest.requestId,url);
                    
#endif
                    //添加到队列中
                    [AFUIImageBatchLoadingManager addLoadPath:blockResourcePath  token:blockToken queue:blockQueueId requestId:downloadRequest.requestId];
                    
                    //            LOG_DEBUG(@"-----self:%@ ",self);
                    
                    [downloadRequest completionBlock:^(AFNetworkingBaseRequest *request, NSInteger statusCode) {
                        
                        @try {
                            if(statusCode==200){
                                //                        LOG_DEBUG(@"resourcePath:%@",entry.resourcePath);
                                
                                // TODO: 处理本地图片，
                                [weakSelf processLocalImage:blockResourcePath cacheKey:blockCacheKey];
                                
                            }
                            else if(statusCode == 404){
#if DEBUG
                                NSLog(@"404:%@",blockResourcePath);
#endif
                            }
                        }@catch (NSException *exception) {
#if DEBUG
                            NSLog(@"%@",[[exception callStackSymbols] componentsJoinedByString:@"\n"]);
#endif
                        }@finally {
                            [AFUIImageBatchLoadingManager removeAllLoad:blockResourcePath];
                        }
                    }];
                    
                    [downloadRequest executeAsync:blockQueueId];
                }
                
            }@catch (NSException *exception) {
#if DEBUG
                NSLog(@"%@",[[exception callStackSymbols] componentsJoinedByString:@"\n"]);
#endif
            }
        }
    });
}
-(UIImage *)processImage:(UIImage *)image{
    CGRect rect = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
    UIGraphicsBeginImageContext(rect.size);
    [image drawInRect:rect];  // scales image to rect
    UIImage *resImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resImage;
}
-(void)processLocalImage:(NSString *)imagePath cacheKey:(NSString *)cacheKey{
    @autoreleasepool {
        @try {
            
            UIImage *image = [UIImageView loadImage:cacheKey secondKey:imagePath];
            
            if(image){
                //TODO notication
                //                dispatch_manager_load_image_main_sync_undeadlock_fun(^{
                AFUIImageLoadedEntry *loadedEntry =[[AFUIImageLoadedEntry alloc] init];
                loadedEntry.imagePath =[[NSString alloc] initWithString:imagePath];
                loadedEntry.image =image;
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kAFDYUIImageViewLoadedImageNotification object:loadedEntry];
                //                });
                
                
            }else{
                image=[[UIImage alloc] initWithContentsOfFile:imagePath];
                
                if(image){
                    UIImage *showImage=[self processImage:image];
                    
                    if(image&&[UIImageView supportCache:image]){
                        [UIImageView loadImage:cacheKey secondKey:imagePath image:showImage];
                    }
                    //TODO notication
                    //                    dispatch_manager_load_image_main_sync_undeadlock_fun(^{
                    AFUIImageLoadedEntry *loadedEntry =[[AFUIImageLoadedEntry alloc] init];
                    loadedEntry.imagePath =[[NSString alloc] initWithString:imagePath];
                    loadedEntry.image =showImage;
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:kAFDYUIImageViewLoadedImageNotification object:loadedEntry];
                    //                    });
                }
            }
        }
        @catch (NSException *exception) {
#if DEBUG
            NSLog(@"%@",[[exception callStackSymbols] componentsJoinedByString:@"\n"]);
#endif
        }
    }
    
}

-(void)stopLoad:(NSString *)resourcePath token:(NSString *)token{
    [AFUIImageBatchLoadingManager removeWait:resourcePath token:token];
    [AFUIImageBatchLoadingManager removeLoadPath:resourcePath token:token];
}

@end
