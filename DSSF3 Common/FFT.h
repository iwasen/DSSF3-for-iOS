#import <Foundation/Foundation.h>

class CRFFT
{
public:
	CRFFT();
	~CRFFT();

	void fft(int n, float *fp);
	void ifft(int n, float *fp);

private:
	void fft_sub(int n, float *fp, int isgn);
	void alloc_work(int n);

	int last_n;
	float *a;
	float *w;
	int *ip;
};
