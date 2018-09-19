//
//  OpenCVWrapper.m
//  ARKitBasics
//
//  Created by Nat Wales on 9/25/17.
//  Copyright © 2017 Apple. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/core.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/imgproc/imgproc.hpp>
#include "aruco.hpp"
#include "dictionary.hpp"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>

#include  "OpenCVWrapper.h"

using namespace std;

@implementation OpenCVWrapper


+(UIImage*) getMarkerForId:(int)id {
    cv::Mat markerImage;
    cv::Ptr<cv::aruco::Dictionary> dictionary = cv::aruco::getPredefinedDictionary(cv::aruco::DICT_6X6_250);
    cv::aruco::drawMarker(dictionary, id, 400, markerImage);
    UIImage *finalImage = MatToUIImage(markerImage);
    return finalImage;
}

+(TransformModel *) arucoTransformMatrixFromPixelBuffer:(CVPixelBufferRef)pixelBuffer; {
    cv::Mat intrinMat(3,3,cv::DataType<double>::type);
    
    //From ARKit (ARFrame camera.intrinsics) - iphone 6s plus
    intrinMat.at<double>(0,0) = 1662.49;
    intrinMat.at<double>(0,1) = 0.0;
    intrinMat.at<double>(0,2) = 0.0;
    intrinMat.at<double>(1,0) = 0.0;
    intrinMat.at<double>(1,1) = 1662.49;
    intrinMat.at<double>(1,2) = 0.0;
    intrinMat.at<double>(2,0) = 960.0 / 2;
    intrinMat.at<double>(2,1) = 540.0 / 2;
    intrinMat.at<double>(2,2) = 0.0;
    
    double marker_dim = 3;
    cv::Ptr<cv::aruco::Dictionary> dictionary = cv::aruco::getPredefinedDictionary(cv::aruco::DICT_6X6_250);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *baseaddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    CGFloat width = CVPixelBufferGetWidth(pixelBuffer);
    CGFloat height = CVPixelBufferGetHeight(pixelBuffer);
    cv::Mat mat(height, width, CV_8UC1, baseaddress, 0); //CV_8UC1
    
    cv::rotate(mat, mat, cv::ROTATE_90_CLOCKWISE);
    
    std::vector<int> ids;
    std::vector<std::vector<cv::Point2f>> corners;
    
    cv::aruco::detectMarkers(mat,dictionary,corners,ids);
    
    if(ids.size() > 0) {
        cv::Mat colorMat;
        cv::cvtColor(mat, colorMat, CV_GRAY2RGB);
        cv::aruco::drawDetectedMarkers(colorMat, corners, ids, cv::Scalar(0,255,24));
        
        cv::Mat distCoeffs = cv::Mat::zeros(8, 1, cv::DataType<double>::type); //zero out distortion for now
        
       //MARK: Aruco detection
//        std::vector<cv::Vec3d> rvecs, tvecs;
//        cv::aruco::estimatePoseSingleMarkers(corners, marker_dim, intrinMat, distCoeffs, rvecs, tvecs);
//        cv::aruco::drawAxis(colorMat, intrinMat, distCoeffs, rvecs[0], tvecs[0], marker_dim);

//        //MARK: solvepnp
        std::vector<cv::Point3f> object_points;
        object_points = {cv::Point3f(-marker_dim , marker_dim , 0),
                        cv::Point3f(marker_dim , marker_dim , 0),
                        cv::Point3f(marker_dim , -marker_dim , 0),
                        cv::Point3f(-marker_dim , -marker_dim , 0)};
  

        std::vector<cv::Point_<float>> image_points = std::vector<cv::Point2f>{corners[0][0], corners[0][1], corners[0][2], corners[0][3]};

        std::cout << "object points: " << object_points << std::endl;
        std::cout << "image points: " << image_points << std::endl;
        
        cv::Mat rvec, tvec;
        cv::solvePnP(object_points, image_points, intrinMat, distCoeffs, rvec, tvec);
        cv::aruco::drawAxis(colorMat, intrinMat, distCoeffs, rvec, tvec, 3);
    
        
        cv::Mat rotation, transform_matrix;
        
        cv::Mat RotX(3, 3, cv::DataType<double>::type);
        cv::setIdentity(RotX);
        RotX.at<double>(4) = -1; //cos(180) = -1
        RotX.at<double>(8) = -1;
        cv::Mat R;
        cv::Rodrigues(rvec, R);
        std::cout << "rvecs: " << rvec << std::endl;
        std::cout << "cv::Rodrigues(rvecs, R);: " << R << std::endl;
        R = R.t();  // rotation of inverse
        std::cout << "R = R.t() : " << R << std::endl;
        cv::Mat rvecConverted;
        Rodrigues(R, rvecConverted); //
        std::cout << "rvec in world coords:\n" << rvecConverted << std::endl;
        rvecConverted = RotX * rvecConverted;
        std::cout << "rvec scenekit :\n" << rvecConverted << std::endl;
        Rodrigues(rvecConverted, rotation);
        
        std::cout << "-R: " << -R << std::endl;
        std::cout << "tvec: " << tvec << std::endl;
        cv::Mat tvecConverted = -R * tvec;
        std::cout << "tvec in world coords:\n" << tvecConverted << std::endl;
        tvecConverted = RotX * tvecConverted;
        std::cout << "tvec scenekit :\n" << tvecConverted << std::endl;
        
        SCNVector4 rotationVector = SCNVector4Make(rvecConverted.at<double>(0), rvecConverted.at<double>(1), rvecConverted.at<double>(2), norm(rvecConverted));
        SCNVector3 translationVector = SCNVector3Make(tvecConverted.at<double>(0), tvecConverted.at<double>(1), tvecConverted.at<double>(2));
        
        std::cout << "rotation :\n" << rotation << std::endl;
        transform_matrix.create(4, 4, CV_64FC1);
        transform_matrix( cv::Range(0,3), cv::Range(0,3) ) = rotation * 1;
        
        transform_matrix.at<double>(0, 3) = tvecConverted.at<double>(0,0);
        transform_matrix.at<double>(1, 3) = tvecConverted.at<double>(1,0);
        transform_matrix.at<double>(2, 3) = tvecConverted.at<double>(2,0);
        transform_matrix.at<double>(3, 3) = 1;
        
        UIImage *finalImage = MatToUIImage(colorMat);
        TransformModel *model = [TransformModel new];
        model.image = finalImage;
        
        model.transform = [OpenCVWrapper transformToSceneKitMatrix:transform_matrix];
        
        model.rotationVector = rotationVector;
        model.translationVector = translationVector;
        return model;
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    return NULL;
}

+(SCNMatrix4) transformToSceneKitMatrix:(cv::Mat&) openCVTransformation {
    
    SCNMatrix4 mat = SCNMatrix4Identity;
    
    mat.m11 = (float) openCVTransformation.at<double>(0, 0);
    mat.m12 = (float) openCVTransformation.at<double>(1, 0);
    mat.m13 = (float) openCVTransformation.at<double>(2, 0);
    mat.m14 = (float) openCVTransformation.at<double>(3, 0);

    mat.m21 = (float)openCVTransformation.at<double>(0, 1);
    mat.m22 = (float)openCVTransformation.at<double>(1, 1);
    mat.m23 = (float)openCVTransformation.at<double>(2, 1);
    mat.m24 = (float)openCVTransformation.at<double>(3, 1);

    mat.m31 = (float)openCVTransformation.at<double>(0, 2);
    mat.m32 = (float)openCVTransformation.at<double>(1, 2);
    mat.m33 = (float)openCVTransformation.at<double>(2, 2);
    mat.m34 = (float)openCVTransformation.at<double>(3, 2);


    //copy the translation row
    mat.m41 = (float)openCVTransformation.at<double>(0, 3);
    mat.m42 = (float)openCVTransformation.at<double>(1, 3);
    mat.m43 = (float)openCVTransformation.at<double>(2, 3);
    mat.m44 = (float)openCVTransformation.at<double>(3, 3);

    return mat;
}

@end
