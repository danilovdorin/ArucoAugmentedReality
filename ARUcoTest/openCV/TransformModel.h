//
//  TransformModel.h
//  ARUcoTest
//
//  Created by Dorin Danilov on 28/08/2018.
//  Copyright © 2018 HHCC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <SceneKit/SceneKit.h>

@interface TransformModel : NSObject

@property SCNMatrix4 transform;
@property NSInteger markerID;
@property UIImage * image;
@property SCNMatrix4 projectionMatrix;
@property SCNVector4 rotationVector;
@property SCNVector3 translationVector;

@end
