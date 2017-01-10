#include "auto_calibration.h"

#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <assert.h>
#include <unistd.h>
#include <sys/time.h>
#include <sys/select.h>
#include <sys/stat.h>
#include <stdbool.h>

#ifdef __cplusplus
}
#endif

#include <opencv/cv.h>
#include <opencv/highgui.h>

void auto_calibration(PICAM360CAPTURE_T *state, FRAME_T *frame) {

	int margin = 32;
	int width = frame->width + 2 * margin;
	int height = frame->height + 2 * margin;
	int offset_x = frame->width * state->options.cam_offset_x[0];
	int offset_y = frame->height * state->options.cam_offset_y[0];

	CvMemStorage* storage = cvCreateMemStorage(0);
	CvSeq* contour = NULL;

	if (frame->custom_data == NULL) {
		frame->custom_data = (void*) cvCreateImage(cvSize(width, height),
				IPL_DEPTH_8U, 1);
	}
	IplImage *img = (IplImage*) frame->custom_data;
	IplImage *image_bin = cvCreateImage(cvSize(width, height), IPL_DEPTH_8U, 1);

	//binalize
	for (int y = 0; y < height; y++) {
		for (int x = 0; x < width; x++) {
			unsigned char val = 0;

			uint32_t _x = x - margin - offset_x;
			uint32_t _y = y - margin - offset_y;
			if (_x >= 0 && _x < frame->width && _y >= 0 && _y < frame->height) {
				val = (frame->img_buff + frame->width * 3 * _y)[_x * 3];
			}

			val = (val >= 32) ? 255 : 0;

			unsigned char _val = (img->imageData + img->widthStep * y)[x];

			(img->imageData + img->widthStep * y)[x] = MAX(_val, val);
		}
	}
	cvCopy(img, image_bin);
//	{
//		cv::Mat src = image_bin;
//		std::vector < cv::Vec3f > circles;
//		HoughCircles(src, circles, CV_HOUGH_GRADIENT, 2, src.rows / 4, 200,
//				100, src->rows / 3, src->rows / 2);
//		for (size_t i = 0; i < circles.size(); i++) {
//			cv::Point center(cvRound (circles[i][0]), cvRound (circles[i][1]));
//			int radius = cvRound(circles[i][2]);
//			cv::circle(src, center, radius, cv::Scalar(255, 255, 255), 3, 8,
//					0);
//			//printf("%lf,%lf,%lf\n", circles[i][0], circles[i][1], circles[i][2]);
//		}
//	}

//find countor
	cvErode(image_bin, image_bin, 0, 5);
	cvDilate(image_bin, image_bin, 0, 5);
	//cvSaveImage("debug.jpeg", image_bin);
	cvFindContours(image_bin, storage, &contour, sizeof(CvContour),
			CV_RETR_EXTERNAL, CV_CHAIN_APPROX_NONE, cvPoint(0, 0));

	// loop over all contours
	{
		CvBox2D box = { };
		//CvPoint2D32f box_point[4];
		CvBox2D tmp;
		double max_val = INT_MIN;
		CvSeq *cp = contour;
		while (cp != NULL) {
			double size;
			tmp = cvMinAreaRect2(cp, storage);
			size = tmp.size.width * tmp.size.height;
			if (size > max_val) {
				box = tmp;
				max_val = size;
			}
			cp = cp->h_next;
		}
		//printf("%lf,%lf\n", box.center.x, box.center.y);
		if (box.size.width > (float) frame->width * 0.8
				&& box.size.height > (float) frame->height * 0.8) {
			state->options.cam_offset_x[0] = box.center.x / width - 0.5;
			state->options.cam_offset_y[0] = box.center.y / height - 0.5;
		}
	}

	//Release
	if (storage != NULL) {
		cvReleaseMemStorage(&storage);
	}
	if (image_bin != NULL) {
		cvReleaseImage(&image_bin);
	}

}
