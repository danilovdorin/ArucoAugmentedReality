#include <iostream>
#include <opencv2/opencv.hpp>
#include <math.h>
#include "CamPoseEstimator.h"



int main()
{
	CamPoseEstimator pose_estimator(960., 540., 3.);
	cv::VideoCapture cap("C:/Users/Vadim2/Source/Repos/VanillaNav/VanillaNav/test_sergiu.mp4");

	int count = 0;
	int frame = 0;
	while (cap.isOpened())
	{
		frame++;
		cv::Mat color_frame(cv::Size(1920, 1080), CV_8UC3);
		cap >> color_frame;

		if (color_frame.empty())
			break;

		//cv::imshow("Color Frame", color_frame);
		//cv::waitKey(1);

		std::vector<cv::Mat> transformations;
		std::vector<int> icon_ids;
		std::vector<cv::Point> square_centers;

		pose_estimator.get_cam_pose(color_frame, transformations, icon_ids, square_centers);
		for (auto center : square_centers)
		{
			count++;
			
			//std::cout << center << "   ";
		}
		std::cout << "frame: " << frame << "----count: " << count << std::endl;
	}
	
	return 0;
}
