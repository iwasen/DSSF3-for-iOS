#import <Foundation/Foundation.h>

extern float Regress1(const float *pData, int nData, float start, float step);
extern void Regress2(const float *pData, int nData, float start, float step, float *reg0, float *reg1);
extern void Regress2x(const float *pData0, const float *pData1, int nData, float *reg0, float *reg1);
