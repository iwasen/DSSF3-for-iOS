#import "AverageBuf.h"
#import "Common.h"

CAverageBuf::CAverageBuf()
{
	_pDataBuf = NULL;
	_pAverageBuf = NULL;
	_pRingBuf = NULL;
	_nSize = 0;
	_nAverageNum = 0;
}

CAverageBuf::~CAverageBuf()
{
	Free();
}

void CAverageBuf::Alloc(int nSize, int nAverageNum)
{
	Free();

	_pDataBuf = new float[nSize];

	if (nAverageNum != 0)
		_pAverageBuf = new float[nSize];

	if (nAverageNum > 0)
		_pRingBuf = new float[nSize * nAverageNum];

	_nSize = nSize;
	_nAverageNum = nAverageNum;

	Reset();
}

void CAverageBuf::Smoothing(const float *pBuf, float m1, float m2)
{
	int i;

	_pDataBuf[0] = 0;
	for (i = 1; i < _nSize; i++)
		_pDataBuf[i] = pBuf[i] * m1 + _pDataBuf[i] * m2;
}

void CAverageBuf::Averaging()
{
	int i;

	if (_nAverageNum != 0) {
		if (_nAverageNum > 0) {
			float *pRingBuf = &_pRingBuf[_nSize * _nAveragePos];

			if (_nAverageCnt >= _nAverageNum) {
				for (i = 0; i < _nSize; i++) {
					_pAverageBuf[i] -= pRingBuf[i];
				}
			}

			memcpy(pRingBuf, _pDataBuf, sizeof(float) * _nSize);
		}

		if (_nAverageNum > 0) {
			if (_nAverageCnt < _nAverageNum)
				_nAverageCnt++;

			if (++_nAveragePos >= _nAverageNum)
				_nAveragePos = 0;
		} else if (_nAverageNum == -1)
			_nAverageCnt++;

		for (i = 0; i < _nSize; i++) {
			_pAverageBuf[i] += _pDataBuf[i];
			_pDataBuf[i] = _pAverageBuf[i] / _nAverageCnt;
		}
	}
}

void CAverageBuf::Reset()
{
	_nAveragePos = 0;
	_nAverageCnt = 0;

	if (_pDataBuf != NULL)
		MEMCLEAR(_pDataBuf, _nSize);

	if (_pAverageBuf != NULL)
		MEMCLEAR(_pAverageBuf, _nSize);
}

void CAverageBuf::Free()
{
	if (_pDataBuf != NULL) {
		delete [] _pDataBuf;
		_pDataBuf = NULL;
	}

	if (_pAverageBuf != NULL) {
		delete [] _pAverageBuf;
		_pAverageBuf = NULL;
	}

	if (_pRingBuf != NULL) {
		delete [] _pRingBuf;
		_pRingBuf = NULL;
	}
}
