/***********************************************************
	mrnd.c -- M系列乱数
 ***********************************************************/
#import "Mrnd.h"

static int jrnd;
static unsigned int x[521];

static void rnd521()
{
    int i;
    
    for (i =  0; i <  32; i++) x[i] ^= x[i + 489];
    for (i = 32; i < 521; i++) x[i] ^= x[i -  32];
}

void init_rnd(unsigned int seed)
{
    int i, j;
    unsigned int u;
    
    u = 0;
    for (i = 0; i <= 16; i++) {
        for (j = 0; j < 32; j++) {
            seed = seed * 1566083941UL + 1;
            u = (u >> 1) | (seed & (1UL << 31));
        }
        x[i] = u;
    }
    x[16] = (x[16] << 23) ^ (x[0] >> 9) ^ x[15];
    for (i = 17; i <= 520; i++)
        x[i] = (x[i-17] << 23) ^ (x[i-16] >> 9) ^ x[i-1];
    rnd521();  rnd521();  rnd521();  /* warm up */
    jrnd = 520;
}

unsigned int irnd(void)
{
    if (++jrnd >= 521) {  rnd521();  jrnd = 0;  }
    return x[jrnd];
}

float rnd(void)  /* 0 <= rnd() < 1 */
{
    return (1.0 / (0xffffffffU + 1.0)) * irnd();
}

float rnd2(void)  /* -1 <= rnd2() < 1 */
{
    return (2.0 / (0xffffffffU + 1.0)) * irnd() - 1;
}

float nrnd1(void)  /* 正規分布 1 */
{
    return rnd() + rnd() + rnd() + rnd() + rnd() + rnd()
    + rnd() + rnd() + rnd() + rnd() + rnd() + rnd() - 6;
}
