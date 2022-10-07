#import <UIKit/UIKit.h>

class CSpline {
public:
	CSpline();
	~CSpline();

	void MakeTable(const float x[], const float y[], int n);
	float Spline(float t);

protected:
	void FreeBuffers();

	float *m_x, *m_y, *m_z;
	int m_n;
};
