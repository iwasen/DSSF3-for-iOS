#import "SG.h"

/////////////////////////////////////////////////////////////////////////////
// CSG

CSG::CSG()
{
	m_pRingBuf = NULL;
}

CSG::~CSG()
{
	if (m_pRingBuf != NULL)
		delete [] m_pRingBuf;
}


/////////////////////////////////////////////////////////////////////////////
// CSG メッセージ ハンドラ

int CSG::SetWaveData(AudioData *pAudioData)
{
	int size = 0;

	m_bInitSpline = NO;

	switch (g_oSetData.Sg.nMode) {
	case SG_MODE_TONE:
		size = WaveOutTone(pAudioData);
		break;
	case SG_MODE_NOISE:
		size = WaveOutNoise(pAudioData);
		break;
	case SG_MODE_SWEEP:
		size = WaveOutSweep(pAudioData);
		break;
	case SG_MODE_PULSE:
		size = WaveOutPulse(pAudioData);
		break;
	case SG_MODE_SYNTH:
		size = WaveOutSynth(pAudioData);
		break;
	case SG_MODE_SCALE:
		size = WaveOutScale(pAudioData);
		break;
/*
	case SG_MODE_WAVE:
		size = WaveOutWave(pAudioData);
		break;
*/
	}

	return size;
}

int CSG::WaveOutTone(AudioData *pAudioData)
{
	SWorkData &oWorkDataLeft = m_aWorkData[0];
	SWorkData &oWorkDataRight = m_aWorkData[1];

	if (g_oSetData.Sg.bRendouF && oWorkDataLeft.fFreq == oWorkDataRight.fFreq) {
		oWorkDataRight.fAngle = oWorkDataLeft.fAngle + (360 - g_oSetData.Sg.nPhase) / 360.0;
		while (oWorkDataRight.fAngle >= 1.0)
			oWorkDataRight.fAngle -= 1.0;
	}

	GenerateTone(pAudioData->pLeftData, g_oSetData.Sg.nToneWave, g_oSetData.Sg.fFreqL, g_oSetData.Sg.nLevelL, oWorkDataLeft);
    GenerateTone(pAudioData->pRightData, g_oSetData.Sg.nToneWave, g_oSetData.Sg.fFreqR, g_oSetData.Sg.nLevelR, oWorkDataRight);

	return SG_SPB;
}

void CSG::GenerateTone(float *pWaveBuf, int nWaveForm, float fFreq, int nLevel, SWorkData &oWorkData)
{
	float fFreqStep;
	int i;

	if (oWorkData.fFreq == 0)
		oWorkData.fFreq = fFreq;

	if (oWorkData.fFreq == fFreq)
		fFreqStep = 1;
	else
		fFreqStep = pow(fFreq / oWorkData.fFreq, 1 / (float)SG_SPB);

	float fLevel = (float)nLevel / 100;

	for (i = 0; i < SG_SPB; i++) {
		switch (nWaveForm) {
		case WAVE_SIN:
			*pWaveBuf = sin(2 * M_PI * oWorkData.fAngle) * fLevel;
			break;
		case WAVE_TRIANGLE:
			if (oWorkData.fAngle < 0.5)
				*pWaveBuf = (oWorkData.fAngle - 0.25) * 4 * fLevel;
			else
				*pWaveBuf = (0.75 - oWorkData.fAngle) * 4 * fLevel;
			break;
		case WAVE_SQUARE:
			if (oWorkData.fAngle < 0.5)
				*pWaveBuf = fLevel;
			else
				*pWaveBuf = -fLevel;
			break;
		case WAVE_SAW:
			*pWaveBuf = (oWorkData.fAngle - 0.5) * 2 * fLevel;
			break;
		default:
#if ENABLE_WAVEFORM
			*pWaveBuf = GetUserWaveForm(nWaveForm - WAVE_USER, oWorkData) * fLevel;
#endif
			break;
		}

		pWaveBuf++;

		oWorkData.fAngle += oWorkData.fFreq / g_oSetData.Sg.nSampleRate;
		while (oWorkData.fAngle >= 1.0)
			oWorkData.fAngle -= 1.0;

		oWorkData.fFreq *= fFreqStep;
	}

	oWorkData.fFreq = fFreq;
}

void CSG::ResetToneFreq()
{
	m_aWorkData[0].fFreq = 0;
	m_aWorkData[1].fFreq = 0;
}

#if ENABLE_WAVEFORM
float CSG::GetUserWaveForm(int nUserWaveForm, SWorkData &oWorkData)
{
	WaveForm *pWaveForm = g_oWaveForm.ReadWaveForm(nUserWaveForm);

	switch (pWaveForm->nDataType) {
	case WAVEFORM_FM:
		return GetUserWaveFormFM((WaveFormFM *)pWaveForm, oWorkData);
	default:
		return GetUserWaveFormManual((WaveFormManual *)pWaveForm, oWorkData);
	}
}

float CSG::GetUserWaveFormManual(const WaveFormManual *pWaveForm, SWorkData &oWorkData)
{
	int i;

	if (pWaveForm->bSmoothing) {
		if (!m_bInitSpline) {
			m_bInitSpline = YES;

			int nPoint = pWaveForm->nDataNum;
			CSpline spl;
			float *xp = new float[nPoint];
			float *yp = new float[nPoint];

			for (i = 0; i < nPoint; i++) {
				xp[i] = pWaveForm->vertex[i].x;
				yp[i] = pWaveForm->vertex[i].y;
			}

			m_oSpline.MakeTable(xp, yp, nPoint);

			delete [] yp;
			delete [] xp;
		}

		return m_oSpline.Spline(oWorkData.fAngle);
	} else {
		for (i = pWaveForm->nDataNum - 1; i >= 0; i--) {
			if (oWorkData.fAngle >= pWaveForm->vertex[i].x)
				break;
		}

		float x = pWaveForm->vertex[i].x;
		float y = pWaveForm->vertex[i].y;
		float dx = pWaveForm->vertex[i + 1].x - x;
		float dy = pWaveForm->vertex[i + 1].y - y;

		return y + (oWorkData.fAngle - x) / dx * dy;
	}
}

float CSG::GetUserWaveFormFM(const WaveFormFM *pWaveForm, SWorkData &oWorkData)
{
	float fDiff = oWorkData.fAngle - oWorkData.fPrevAngle;
	oWorkData.fPrevAngle = oWorkData.fAngle;
	if (fDiff < 0)
		fDiff += 1.0;
	if (oWorkData.fModFreq == pWaveForm->fModFreq)
		oWorkData.fModAngle += fDiff * pWaveForm->fModFreq;
	else {
		oWorkData.fModAngle = oWorkData.fAngle * pWaveForm->fModFreq;
		oWorkData.fModFreq = pWaveForm->fModFreq;
	}
	if (oWorkData.fModAngle >= 1.0)
		oWorkData.fModAngle -= 1.0;

	return sin(2 * M_PI * oWorkData.fAngle + pWaveForm->fModAmp * sin(2 * M_PI * oWorkData.fModAngle));
}
#endif

int CSG::WaveOutNoise(AudioData *pAudioData)
{
	int nRingBufPtr;
	float buf[SG_SPB];
	float fLevelL = (float)g_oSetData.Sg.nLevelL / 100;
	float fLevelR = (float)g_oSetData.Sg.nLevelR / 100;

	switch (g_oSetData.Sg.nNoiseMode) {
	case NOISE_MODE_INVERSE:
		fLevelL = -fLevelL;
		fLevelR = -fLevelR;
		// no break
	case NOISE_MODE_MONO:
		switch (g_oSetData.Sg.nNoiseType) {
		case NOISE_WHITE:
			m_oNoiseLeft.GenerateWhiteNoise(buf, SG_SPB, 1.0);
			break;
		case NOISE_PINK:
			m_oNoiseLeft.GeneratePinkNoise(buf, SG_SPB, 1.0);
			break;
		case NOISE_BROWN:
			m_oNoiseLeft.GenerateBrownNoise(buf, SG_SPB, 1.0);
			break;
		}

		nRingBufPtr = m_nRingBufPtr;
		SetRingBuf(buf);

		if (g_oSetData.Sg.fTimeDiff >= 0) {
			GetRingBuf(pAudioData->pRightData, nRingBufPtr, fLevelL);
			GetRingBuf(pAudioData->pLeftData, (nRingBufPtr + m_nRingBufSize - (int)(g_oSetData.Sg.nSampleRate * (g_oSetData.Sg.fTimeDiff / 1000))) % m_nRingBufSize, fLevelR);
		} else {
			GetRingBuf(pAudioData->pLeftData, nRingBufPtr, fLevelL);
			GetRingBuf(pAudioData->pRightData, (nRingBufPtr + m_nRingBufSize - (int)(g_oSetData.Sg.nSampleRate * (-g_oSetData.Sg.fTimeDiff / 1000))) % m_nRingBufSize, fLevelR);
		}
		break;
	case NOISE_MODE_STEREO:
		switch (g_oSetData.Sg.nNoiseType) {
		case NOISE_WHITE:
			m_oNoiseLeft.GenerateWhiteNoise(pAudioData->pLeftData, SG_SPB, fLevelL);
			m_oNoiseRight.GenerateWhiteNoise(pAudioData->pRightData, SG_SPB, fLevelR);
			break;
		case NOISE_PINK:
			m_oNoiseLeft.GeneratePinkNoise(pAudioData->pLeftData, SG_SPB, fLevelL);
			m_oNoiseRight.GeneratePinkNoise(pAudioData->pRightData, SG_SPB, fLevelR);
			break;
		case NOISE_BROWN:
			m_oNoiseLeft.GenerateBrownNoise(pAudioData->pLeftData, SG_SPB, fLevelL);
			m_oNoiseRight.GenerateBrownNoise(pAudioData->pRightData, SG_SPB, fLevelR);
			break;
		}
		break;
	}

	return SG_SPB;
}

void CSG::SetRingBuf(const float *pBuf)
{
	for (int i = 0; i < SG_SPB; i++) {
		m_pRingBuf[m_nRingBufPtr] = *pBuf++;

		if (++m_nRingBufPtr >= m_nRingBufSize)
			m_nRingBufPtr = 0;
	}
}

void CSG::GetRingBuf(float *pBuf, int nOffset, float fLevel)
{
	for (int i = 0; i < SG_SPB; i++) {
		*pBuf++ = m_pRingBuf[nOffset] * fLevel;

		if (++nOffset >= m_nRingBufSize)
			nOffset = 0;
	}
}

int CSG::WaveOutSweep(AudioData *pAudioData)
{
	int i;
    float fData = 0;
	SWorkData &oWorkData = m_aWorkData[0];

	int nSweepSamples = (int)(g_oSetData.Sg.nSampleRate * g_oSetData.Sg.fSweepTime);

	float fSample = 1 / (g_oSetData.Sg.nSampleRate * g_oSetData.Sg.fSweepTime);
	float fFreqStep = pow(g_oSetData.Sg.fEndFreq / g_oSetData.Sg.fStartFreq, fSample);
	float fLevelStep = pow(pow(10.0, (g_oSetData.Sg.fStartLevel - g_oSetData.Sg.fEndLevel) / 20), fSample);

	for (i = 0; i < SG_SPB; i++) {
		if (m_nSweepCount >= nSweepSamples) {
			if (g_oSetData.Sg.bSweepLoop)
				Init();
			else
				break;
		}

		switch (g_oSetData.Sg.nSweepWave) {
		case WAVE_SIN:
			fData = sin(2 * M_PI * oWorkData.fAngle);
			break;
		case WAVE_TRIANGLE:
			if (oWorkData.fAngle < 0.5)
				fData = (oWorkData.fAngle - 0.25) * 4;
			else
				fData = (0.75 - oWorkData.fAngle) * 4;
			break;
		case WAVE_SQUARE:
			if (oWorkData.fAngle < 0.5)
				fData = 1.0;
			else
				fData = -1.0;
			break;
		case WAVE_SAW:
			fData = (oWorkData.fAngle - 0.5) * 2;
			break;
		default:
#if ENABLE_WAVEFORM
			fData = GetUserWaveForm(g_oSetData.Sg.nSweepWave - WAVE_USER, oWorkData);
#endif
			break;
		}

		float fLevelL = (float)g_oSetData.Sg.nLevelL / 100 * m_fSweepLevel;
		float fLevelR = (float)g_oSetData.Sg.nLevelR / 100 * m_fSweepLevel;

		pAudioData->pLeftData[i] = fData * fLevelL;
		pAudioData->pRightData[i] = fData * fLevelR;

		oWorkData.fAngle += m_fSweepFreq / g_oSetData.Sg.nSampleRate;
		while (oWorkData.fAngle >= 1)
			oWorkData.fAngle -= 1;

		m_fSweepFreq *= fFreqStep;
		m_fSweepLevel *= fLevelStep;
		m_nSweepCount++;
	}

	return i;
}

int CSG::WaveOutPulse(AudioData *pAudioData)
{
	int i;
	float fData = 0;

	for (i = 0; i < SG_SPB; i++) {
		m_fPulseCycleTime += m_fPulseSamplingTime;
		if (m_fPulseCycleTime >= g_oSetData.Sg.fPulseCycle) {
			if (!g_oSetData.Sg.bPulseContinue && m_nPulseCycleCount >= g_oSetData.Sg.nPulseNum)
				break;
			m_nPulseWidthCount = 1;
			m_nPulseCycleCount++;
			m_fPulseCycleTime -= g_oSetData.Sg.fPulseCycle;
		}

		if (m_nPulseWidthCount != 0) {
			switch (g_oSetData.Sg.nPulsePolarity) {
			case 0:
				fData = 1.0;
				break;
			case 1:
				fData = -1.0;
				break;
			case 2:
				fData = ((m_nPulseCycleCount % 2) ? 1.0 : -1.0);
				break;
			}

			pAudioData->pLeftData[i] = fData * g_oSetData.Sg.nLevelL / 100;
			pAudioData->pRightData[i] = fData * g_oSetData.Sg.nLevelR / 100;

			if (++m_nPulseWidthCount > g_oSetData.Sg.nPulseWidth)
				m_nPulseWidthCount = 0;
		} else {
			pAudioData->pLeftData[i] = 0;
			pAudioData->pRightData[i] = 0;
		}
	}

	return i;
}

int CSG::WaveOutSynth(AudioData *pAudioData)
{
	int i, j;
	float buf[SG_SPB];
	float waveBuf[SG_SPB];
	float freq;
	int level;


	memset(waveBuf, 0, sizeof(waveBuf));

	for (i = 0; i < N_SG_COMPONENT; i++) {
		switch (i) {
			case 0:
				freq = g_oSetData.Sg.fCompFreq1;
				level = g_oSetData.Sg.nCompLevel1;
				break;
			case 1:
				freq = g_oSetData.Sg.fCompFreq2;
				level = g_oSetData.Sg.nCompLevel2;
				break;
			case 2:
				freq = g_oSetData.Sg.fCompFreq3;
				level = g_oSetData.Sg.nCompLevel3;
				break;
			case 3:
				freq = g_oSetData.Sg.fCompFreq4;
				level = g_oSetData.Sg.nCompLevel4;
				break;
			case 4:
				freq = g_oSetData.Sg.fCompFreq5;
				level = g_oSetData.Sg.nCompLevel5;
				break;
			case 5:
				freq = g_oSetData.Sg.fCompFreq6;
				level = g_oSetData.Sg.nCompLevel6;
				break;
			case 6:
				freq = g_oSetData.Sg.fCompFreq7;
				level = g_oSetData.Sg.nCompLevel7;
				break;
			case 7:
				freq = g_oSetData.Sg.fCompFreq8;
				level = g_oSetData.Sg.nCompLevel8;
				break;
			default:
				freq = 0;
				level = 0;
				break;
		}
		if (freq != 0 && level != 0) {
			float fFreq = g_oSetData.Sg.fSynthFreq * freq;
			if (fFreq < g_oSetData.Sg.nSampleRate / 2) {
				GenerateTone(buf, g_oSetData.Sg.nSynthWave, fFreq, 100, m_aWorkData[i]);
				for (j = 0; j < SG_SPB; j++)
					waveBuf[j] = waveBuf[j] + buf[j] * level / 100;
			}
		}
	}

	float fMax = GetMaxData(waveBuf, SG_SPB);
	for (i = 0; i < SG_SPB; i++) {
		pAudioData->pLeftData[i] = (fMax > 1.0 ? waveBuf[i] / fMax : waveBuf[i]) * g_oSetData.Sg.nLevelL / 100;
		pAudioData->pRightData[i] = (fMax > 1.0 ? waveBuf[i] / fMax : waveBuf[i]) * g_oSetData.Sg.nLevelR / 100;
	}

	return SG_SPB;
}

int CSG::WaveOutScale(AudioData *pAudioData)
{
	float fFreq;
	SWorkData &oWorkData = m_aWorkData[0];
	float buf[SG_SPB];

	int nPitch = (g_oSetData.Sg.nOctave - 4) * 12 + (g_oSetData.Sg.nScale - 9);
	fFreq = g_oSetData.Sg.fReferencePitch * pow(2.0, (float)nPitch / 12);

	oWorkData.fFreq = 0;

	GenerateTone(buf, g_oSetData.Sg.nScaleWave, fFreq, 100, oWorkData);

	for (int i = 0; i < SG_SPB; i++) {
		pAudioData->pLeftData[i] = buf[i] * g_oSetData.Sg.nLevelL / 100;
		pAudioData->pRightData[i] = buf[i] * g_oSetData.Sg.nLevelR / 100;
	}

	return SG_SPB;
}

void CSG::Init()
{
	memset(m_aWorkData, 0, sizeof(m_aWorkData));

	switch (g_oSetData.Sg.nMode) {
	case SG_MODE_TONE:
		break;
	case SG_MODE_NOISE:
		if (m_pRingBuf != NULL)
			delete [] m_pRingBuf;
		m_nRingBufSize = SG_SPB + g_oSetData.Sg.nSampleRate + 1;
		m_pRingBuf = new float[m_nRingBufSize];
		MEMCLEAR(m_pRingBuf, m_nRingBufSize);
		m_nRingBufPtr = 0;
		break;
	case SG_MODE_SWEEP:
		m_fSweepFreq = g_oSetData.Sg.fStartFreq;
		m_fSweepLevel = pow(10.0, -g_oSetData.Sg.fStartLevel / 20);
		m_nSweepCount = 0;
		break;
	case SG_MODE_PULSE:
		m_nPulseCycleCount = 0;
		m_nPulseWidthCount = 0;
		m_fPulseCycleTime = 0;
		m_fPulseSamplingTime = 1000.0 / (float)g_oSetData.Sg.nSampleRate;
		break;
	case SG_MODE_SYNTH:
		break;
	}
}
/*
int CSG::WaveOutWave(CAudioData *pAudioData)
{
	float *pWaveBuf = pAudioData->_pLeftData;
	SWorkData &oWorkData = m_aWorkData[0];

	oWorkData.fFreq = 0;

	GenerateTone(pWaveBuf, WAVE_USER + g_oSetData.Sg.nWaveFormNo, g_oSetData.Sg.fWaveFreq, oWorkData);

	return SG_SPB;
}
*/