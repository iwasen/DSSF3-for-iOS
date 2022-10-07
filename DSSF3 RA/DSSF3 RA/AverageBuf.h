#import <UIKit/UIKit.h>

class CAverageBuf
{
public:
	CAverageBuf();
	~CAverageBuf();
	void Alloc(int nSize, int nAverageNum);
	void Smoothing(const float *pBuf, float m1, float m2);
	void Averaging();
	void Reset();
	float *GetBuf() { return _pDataBuf; }
	int GetBufSize() { return _nSize; }

protected:
	void Free();

	float *_pDataBuf;
	float *_pAverageBuf;
	float *_pRingBuf;
	int _nSize;
	int _nAverageNum;
	int _nAveragePos;
	int _nAverageCnt;
};
