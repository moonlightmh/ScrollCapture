// Fix OpenCV/Apple macro conflict - must be before any Apple includes
#ifndef NO
#define NO 0
#endif

#import "StitchEngineBridge.h"

// Only include needed OpenCV headers (avoid stitching module which conflicts with Apple NO macro)
#import <opencv2/core.hpp>
#import <opencv2/imgproc.hpp>
#import <opencv2/imgcodecs.hpp>
#import <opencv2/features2d.hpp>
#import <opencv2/calib3d.hpp>
#import <opencv2/flann.hpp>

// Restore NO macro for Apple
#undef NO
#define NO ((BOOL)0)

@interface StitchResultBridge ()
@end

@implementation StitchResultBridge
@end

@interface StitchEngineBridge () {
    int _templateHeight;
    double _matchThreshold;
    int _maxResultHeight;
    std::vector<int> _overlapHistory;
}

@end

@implementation StitchEngineBridge

- (instancetype)initWithTemplateHeight:(int)templateHeight
                        matchThreshold:(double)threshold
                       maxResultHeight:(int)maxHeight {
    self = [super init];
    if (self) {
        _templateHeight = templateHeight;
        _matchThreshold = threshold;
        _maxResultHeight = maxHeight;
    }
    return self;
}

- (StitchResultBridge *)stitchBaseImage:(CGImageRef)baseImage
                             withNewImage:(CGImageRef)newImage {
    StitchResultBridge *result = [[StitchResultBridge alloc] init];
    result.success = NO;
    result.errorCode = 0;
    result.confidence = 0;
    result.overlapPixels = 0;

    if (!baseImage || !newImage) {
        result.errorCode = 1; // noOverlap
        return result;
    }

    // Convert to cv::Mat
    cv::Mat baseMat = [self matFromCGImage:baseImage];
    cv::Mat newMat = [self matFromCGImage:newImage];

    if (baseMat.empty() || newMat.empty()) {
        result.errorCode = 1;
        return result;
    }

    // Check if result would be too large
    int estimatedHeight = baseMat.rows + newMat.rows - _templateHeight;
    if (estimatedHeight > _maxResultHeight) {
        result.errorCode = 3; // imageTooLarge
        return result;
    }

    // Perform template matching
    auto stitchResult = [self matchAndStitch:baseMat withNew:newMat];

    result.confidence = std::get<0>(stitchResult);
    result.overlapPixels = std::get<1>(stitchResult);
    cv::Mat resultMat = std::get<2>(stitchResult);

    if (result.confidence < _matchThreshold) {
        result.errorCode = 2; // lowConfidence
        // Still produce result using estimated overlap
        int estimatedOverlap = [self getEstimatedOverlap];
        resultMat = [self stitchWithOverlap:baseMat newMat:newMat overlap:estimatedOverlap];
        result.overlapPixels = estimatedOverlap;
    }

    if (!resultMat.empty()) {
        result.imageRef = [self cgImageFromMat:resultMat];
        result.success = (result.imageRef != nil);
    }

    // Record overlap for learning
    if (result.success && result.overlapPixels > 0) {
        _overlapHistory.push_back(result.overlapPixels);
    }

    return result;
}

- (std::tuple<double, int, cv::Mat>)matchAndStitch:(const cv::Mat&)baseMat
                                            withNew:(const cv::Mat&)newMat {
    // Extract template from base (bottom N rows)
    int templateRows = std::min(_templateHeight, baseMat.rows);
    cv::Rect templateRect(0, baseMat.rows - templateRows, baseMat.cols, templateRows);
    cv::Mat templateMat(baseMat, templateRect);

    // Search region in new image (top 2*templateHeight rows)
    int searchRows = std::min(templateRows * 2, newMat.rows);
    cv::Rect searchRect(0, 0, newMat.cols, searchRows);
    cv::Mat searchMat(newMat, searchRect);

    // Template matching
    cv::Mat resultMat;
    cv::matchTemplate(searchMat, templateMat, resultMat, cv::TM_CCOEFF_NORMED);

    // Find best match
    double minVal, maxVal;
    cv::Point minLoc, maxLoc;
    cv::minMaxLoc(resultMat, &minVal, &maxVal, &minLoc, &maxLoc);

    // maxLoc.y is where template top was found in search region
    // Overlap = templateRows - maxLoc.y
    int overlap = templateRows - maxLoc.y;
    overlap = std::max(0, std::min(overlap, templateRows * 2)); // Clamp

    // Stitch
    cv::Mat stitched = [self stitchWithOverlap:baseMat newMat:newMat overlap:overlap];

    return std::make_tuple(maxVal, overlap, stitched);
}

- (cv::Mat)stitchWithOverlap:(const cv::Mat&)baseMat
                     newMat:(const cv::Mat&)newMat
                     overlap:(int)overlap {
    if (overlap <= 0) {
        // No overlap - add gap
        overlap = 50; // Default gap
    }

    int newContentHeight = newMat.rows - overlap;
    if (newContentHeight <= 0) {
        return baseMat.clone();
    }

    // Create result image
    int resultHeight = baseMat.rows + newContentHeight;
    cv::Mat result(resultHeight, baseMat.cols, baseMat.type());

    // Copy base
    baseMat.copyTo(result(cv::Rect(0, 0, baseMat.cols, baseMat.rows)));

    // Copy new content (below overlap)
    cv::Rect newContentRect(0, overlap, newMat.cols, newContentHeight);
    cv::Mat newContent(newMat, newContentRect);
    newContent.copyTo(result(cv::Rect(0, baseMat.rows, newMat.cols, newContentHeight)));

    return result;
}

- (int)getEstimatedOverlap {
    if (_overlapHistory.empty()) {
        return _templateHeight;
    }
    int sum = 0;
    for (int o : _overlapHistory) {
        sum += o;
    }
    return sum / (int)_overlapHistory.size();
}

- (void)reset {
    _overlapHistory.clear();
}

// Helper: CGImage -> cv::Mat
- (cv::Mat)matFromCGImage:(CGImageRef)image {
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);

    cv::Mat mat((int)height, (int)width, CV_8UC4);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(
        mat.data,
        width,
        height,
        8,
        mat.step1(),
        colorSpace,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault
    );
    CGColorSpaceRelease(colorSpace);

    if (context) {
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
        CGContextRelease(context);
    }

    cv::Mat bgrMat;
    cv::cvtColor(mat, bgrMat, cv::COLOR_BGRA2BGR);

    return bgrMat;
}

// Helper: cv::Mat -> CGImage
- (CGImageRef)cgImageFromMat:(const cv::Mat&)mat {
    if (mat.empty()) return nil;

    cv::Mat bgraMat;
    cv::cvtColor(mat, bgraMat, cv::COLOR_BGR2BGRA);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(
        bgraMat.data,
        bgraMat.cols,
        bgraMat.rows,
        8,
        bgraMat.step1(),
        colorSpace,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault
    );
    CGColorSpaceRelease(colorSpace);

    CGImageRef image = nil;
    if (context) {
        image = CGBitmapContextCreateImage(context);
        CGContextRelease(context);
    }

    return image;
}

@end