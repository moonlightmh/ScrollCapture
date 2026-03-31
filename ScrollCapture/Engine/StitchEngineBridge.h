#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface StitchResultBridge : NSObject

@property (nonatomic, assign) CGImageRef _Nullable imageRef;
@property (nonatomic, assign) double confidence;
@property (nonatomic, assign) int overlapPixels;
@property (nonatomic, assign) BOOL success;
@property (nonatomic, assign) int errorCode; // 0=none, 1=noOverlap, 2=lowConfidence, 3=imageTooLarge, 4=memoryExceeded

@end

@interface StitchEngineBridge : NSObject

- (instancetype)initWithTemplateHeight:(int)templateHeight
                        matchThreshold:(double)threshold
                       maxResultHeight:(int)maxHeight;

- (StitchResultBridge *)stitchBaseImage:(CGImageRef)baseImage
                             withNewImage:(CGImageRef)newImage;

- (void)reset;

@end

NS_ASSUME_NONNULL_END