//
//  OpenCVWrapper.h
//  ARKitBasics
//
//  Created by Nat Wales on 9/25/17.
//  Copyright © 2017 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import "TransformModel.h"

@interface OpenCVWrapper : NSObject
+(TransformModel *) arucoTransformMatrixFromPixelBuffer:(CVPixelBufferRef)pixelBuffer;
+(UIImage*) getMarkerForId:(int)id;
@end
