//
//  AFNetworkingBaseRequest.h 
//

#import <Foundation/Foundation.h>

#import "AFNetworkingHttpContants.h"
 
#import "AFNetworking.h"

#import "UIKit+AFNetworking.h"

#import "AFNetworkActivityLogger.h"

#import "Ono.h"

#import "ONOXMLDocument.h"

#import "AFOnoResponseSerializer.h"

#import "NSData+Godzippa.h"

#import "AFgzipRequestSerializer.h"

#import "AFNetworkingBaseRequest.h"

#import "AFTextResponseSerializer.h"

#import "AFDownloadRequestOperation.h"

#import "AFDownloadRequestOperationManager.h"

#import "AFNetworkingHttpQueueManager.h"

#import "AFCustomRequestOperation.h"

@class AFNetworkingBaseRequest;
@class AFHTTPRequestOperation;

typedef void(^AFNetworkingCompletionBlock)(AFNetworkingBaseRequest *request, NSInteger statusCode);

typedef void(^AFNetworkingDownloadBlock)(long long totalBytesRead, long long totalBytesExpectedToRead);
typedef void(^AFNetworkingUploadBlock)(long long  totalBytesWritten, long long totalBytesExpectedToWrite);
 

@interface AFNetworkingBaseRequest : NSObject{

    AFCustomRequestOperation *operation;
}
@property (nonatomic,assign,readonly) NSInteger requestId;
@property (nonatomic,strong,readonly) NSString *managerKey;

@property (nonatomic,assign) ResponseProtocolType responseType;  //响应协议类型 
 

-(void)completionBlock:(AFNetworkingCompletionBlock)completionBlock;
-(void)downloadBlock:(AFNetworkingDownloadBlock)downloadBlock;
-(void)uploadBlock:(AFNetworkingUploadBlock)uploadBlock;

-(void)executeSync;

-(void)executeAsync:(NSInteger)queueId;
-(void)executeAsyncWithQueueKey:(NSString *)key;

-(void)buildPostRequest:(NSString *)urlString body:(NSData *)body;        //直接提交body数据

-(void)buildPostRequest:(NSString *)urlString form:(NSDictionary *)form;       //提交表单数据：NSString,NSData,NSURL(Local File)
-(void)buildPostFileRequest:(NSString *)urlString files:(NSDictionary *)files;     //多个文件上传(multipart)

-(void)buildPostFileRequest:(NSString *)urlString files:(NSDictionary *)files form:(NSDictionary *)form;  //混合数据上传

-(void)buildGetRequest:(NSString *)urlString form:(NSDictionary *)form;
-(void)buildGetRequest:(NSString *)urlString;                                      //GET请求

-(void)buildDeleteRequest:(NSString *)urlString;
 
-(void)cancel;
-(BOOL)isCanceled;
-(BOOL)isHttpSuccess;

#pragma mark

#pragma mark  can overrided

-(AFHTTPResponseSerializer *)getAFHTTPResponseSerializer;

#pragma mark  need overrided

- (void)prepareRequest;

- (void)processFile:(NSString *)filePath;
- (void)processDictionary:(id)dictionary; //NSArray or NSDictionary
- (void)processString:(NSString *)str; 

@end
