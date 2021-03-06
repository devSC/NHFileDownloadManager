//
//  NHFileDownloadOperation.m
//  NHFileDownloadManager-demo
//
//  Created by Wilson Yuan on 15/11/17.
//  Copyright © 2015年 Wilson-Yuan. All rights reserved.
//

#import "NHFileDownloadSession.h"
#import "NSString+MD5.h"

@interface NHFileDownloadSession ()

@property (strong, nonatomic) NSURLRequest *urlRequest;

@property (strong, nonatomic) AFURLSessionManager *manager;

@property (strong, nonatomic) NSURLResponse *response;

@property (strong, nonatomic) NSURLSessionDownloadTask *downloadTask;

@property (copy, nonatomic) SuccessBlock completionHandler;

@property (copy, nonatomic) FailureBlock failureHandler;

@property (copy, nonatomic) ProgressBlock progressHandler;


@end

static NSString *NHFileDownloadProgressKeyPath = @"fractionCompleted";
static NSInteger const kNHFileDownloadRequestTimeOutInterver = 15;

@implementation NHFileDownloadSession
- (void)dealloc
{

}
@synthesize urlRequest = _urlRequest;
@synthesize manager = _manager;
@synthesize downloadTask = _downloadTask;
@synthesize response = _response;

- (instancetype)init
{
    return [self initWithSessionConfiguration:nil];
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration {
    self = [super init];
    if (!self) {
        return nil;
    }
    if (!configuration) {
        configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.timeoutIntervalForRequest = kNHFileDownloadRequestTimeOutInterver;
        configuration.allowsCellularAccess = YES;
    }
    self.manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    return self;
    
}
- (NSURLSessionDownloadTask *)downloadFileWithRequest:(NSURLRequest *)requset
                                       distinationUrl:(NSURL *)path
                                             progress:(ProgressBlock)progressHandler
                                           completion:(SuccessBlock)completionHanlder
                                              failure:(FailureBlock)failureHandler {
    
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:1];
    
    self.progressHandler = [progressHandler copy];
    self.urlRequest = requset;
    
    self.downloadTask = [self.manager downloadTaskWithRequest:requset progress:&progress destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        return [path URLByAppendingPathComponent:[[requset.URL.absoluteString md5] stringByAppendingPathExtension:response.suggestedFilename.pathExtension]];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        self.response = response;
        
        if (error && failureHandler) {
            failureHandler(error);
        }
        else if (completionHanlder) {
            completionHanlder(filePath);
        }
    }];
    
    [self.downloadTask resume];
    
    [progress addObserver:self forKeyPath:NHFileDownloadProgressKeyPath options:NSKeyValueObservingOptionNew context:NULL];

    return self.downloadTask;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NHFileDownloadProgressKeyPath] && self.progressHandler) {
        CGFloat progress = [change[@"new"] floatValue];
        self.progressHandler(progress);
        if (progress == 1) {
            @try {
                [object removeObserver:self forKeyPath:NHFileDownloadProgressKeyPath];
            }
            @catch (NSException *exception) {
                NSLog(@"%@", exception);
            }
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
@end
