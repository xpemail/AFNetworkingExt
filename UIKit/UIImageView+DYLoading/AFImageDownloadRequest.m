//
//

#import "AFImageDownloadRequest.h"


@implementation AFImageDownloadRequest
@synthesize  url,filePath; 
 
-(id)initWithURL:(NSString *)_url{
    if(self=[super init]){
        self.url=_url; 
        self.responseType=ResponseProtocolTypeFile;
        
    }
    return self;
} 

- (void)prepareRequest {
    

    
     [self buildGetRequest:url];
}

-(AFHTTPResponseSerializer *)getAFHTTPResponseSerializer{ 
    
    return [AFImageResponseSerializer serializer];
}

-(void)processFile:(NSString *)_filePath{
    if(![self isHttpSuccess]){
        NSFileManager *manager=[NSFileManager defaultManager];
        if([manager fileExistsAtPath:_filePath]){
            NSError *error;
            [manager removeItemAtPath:_filePath error:&error];
            if(error){
                NSLog(@"%@",error);
            }
        }
        return;
    }
            NSFileManager *manager=[NSFileManager defaultManager];
            if([manager fileExistsAtPath:_filePath]){
                NSError *error;
                [manager moveItemAtPath:_filePath toPath:self.filePath error:&error];
                if(error){
                    NSLog(@"%@",error);
                }
            }
}

@end
