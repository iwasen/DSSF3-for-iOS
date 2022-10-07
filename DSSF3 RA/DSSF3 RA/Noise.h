#import <UIKit/UIKit.h>

class CNoise
{
public:
	CNoise();

	void GenerateWhiteNoise(float *pData, int nSize, float fLevel);
	void GeneratePinkNoise(float *pData, int nSize, float fLevel);
	void GenerateBrownNoise(float *pData, int nSize, float fLevel);

protected:
	float GeneratePinkNoiseSub();

	float m_aPinkBuf[7];
	float m_fBrownBuf;
};
