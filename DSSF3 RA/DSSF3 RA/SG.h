#import "Spline.h"
#import "Noise.h"
#import "Common.h"
#import "AudioCommon.h"

#define	SG_SPB		2048
#define ENABLE_WAVEFORM	0

class CSG
{
public:
	CSG();
	~CSG();

	void Init();
	int SetWaveData(AudioData *pAudioData);
	void ResetToneFreq();

	int m_nBitsPerSample;

protected:
	struct SWorkData {
		float fAngle;
		float fFreq;
		float fPrevAngle;
		float fModAngle;
		float fModFreq;
	};

	int WaveOutTone(AudioData *pAudioData);
	void GenerateTone(float *pWaveBuf, int nWaveForm, float fFreq, int nLevel, SWorkData &oWorkData);
#if ENABLE_WAVEFORM
	float GetUserWaveForm(int nUserWaveForm, SWorkData &oWorkData);
	float GetUserWaveFormManual(const WaveFormManual *pWaveForm, SWorkData &oWorkData);
	float GetUserWaveFormFM(const WaveFormFM *pWaveForm, SWorkData &oWorkData);
#endif
	int WaveOutNoise(AudioData *pAudioData);
	void SetRingBuf(const float *pBuf);
	void GetRingBuf(float *pBuf, int nOffset, float fLevel);
	int WaveOutSweep(AudioData *pAudioData);
	int WaveOutPulse(AudioData *pAudioData);
	int WaveOutSynth(AudioData *pAudioData);
	int WaveOutScale(AudioData *pAudioData);
	void GenerateWhiteNoise(float *pData);
	void GeneratePinkNoise(float *pData, float b[]);
	float GeneratePinkNoiseSub(float b[]);
	void GenerateBrownNoise(float *pData, float &c);
	//int WaveOutWave(CAudioData *pAudioData);

	SWorkData m_aWorkData[N_SG_COMPONENT];
	float m_fSweepFreq;
	float m_fSweepLevel;
	int m_nSweepCount;
	int m_nPulseCycleCount;
	int m_nPulseWidthCount;
	float m_fPulseCycleTime;
	float m_fPulseSamplingTime;
	float *m_pRingBuf;
	int m_nRingBufPtr;
	int m_nRingBufSize;
	CSpline m_oSpline;
	BOOL m_bInitSpline;
	CNoise m_oNoiseLeft;
	CNoise m_oNoiseRight;
};
