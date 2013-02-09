/*-----------------------------------------------------------------------------
									               r a n d o m
-----------------------------------------------------------------------------*/

#include <memory.h>
#include "random.h"

/*-----------------------------------------------------------------------------
  The Mersenne Twister by Matsumoto and Nishimura <matumoto@math.keio.ac.jp>.
  It sets new standards for the period, quality and speed of random number
  generators. The incredible period is 2^19937 - 1, a number with about 6000
  digits; the 32-bit random numbers exhibit best possible equidistribution
  properties in dimensions up to 623; and it's fast, very fast. 
-----------------------------------------------------------------------------*/

static const int M = 397, N = 624;

static const unsigned long LOWER_MASK = 0x7fffffff, UPPER_MASK = 0x80000000;
static const unsigned long TEMPERING_MASK_B   =   0x9d2c5680, TEMPERING_MASK_C   =   0xefc60000;
static const unsigned long MATRIX_A           =   0x9908b0df;

inline unsigned long TEMPERING_SHIFT_L(unsigned long y) { return (y >> 18); }
inline unsigned long TEMPERING_SHIFT_S(unsigned long y) { return (y << 7 ); }
inline unsigned long TEMPERING_SHIFT_T(unsigned long y) { return (y << 15); }
inline unsigned long TEMPERING_SHIFT_U(unsigned long y) { return (y >> 11); }

static int              k = 1;
static unsigned long    mag01[2] = {0x0, MATRIX_A};
static unsigned long    ptgfsr[N];

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

unsigned long RandomLong(void)
{
  int		     kk;
  unsigned long	 y;
  
  if (k == N) {
    for (kk = 0; kk < N - M; kk++) {
      y = (ptgfsr[kk] & UPPER_MASK) | (ptgfsr[kk + 1] & LOWER_MASK);
      ptgfsr[kk] = ptgfsr[kk + M] ^ (y >> 1) ^ mag01[y & 0x1];
      }
    for (; kk < N - 1; kk++) {
      y = (ptgfsr[kk] & UPPER_MASK) | (ptgfsr[kk + 1] & LOWER_MASK);
      ptgfsr[kk] = ptgfsr[kk + (M - N)] ^ (y >> 1) ^ mag01[y & 0x1];
      }
    y = (ptgfsr[N - 1] & UPPER_MASK) | (ptgfsr[0] & LOWER_MASK);
    ptgfsr[N - 1] = ptgfsr[M - 1] ^ (y >> 1) ^ mag01[y & 0x1];
    k = 0;
    }
  y = ptgfsr[k++];
  y ^= TEMPERING_SHIFT_U (y);
  y ^= TEMPERING_SHIFT_S (y) & TEMPERING_MASK_B;
  y ^= TEMPERING_SHIFT_T (y) & TEMPERING_MASK_C;
  return y ^= TEMPERING_SHIFT_L (y);

}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

unsigned long RandomLong(long range)
{
  return range ? (RandomLong() % range) : 0;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void RandomInit (unsigned long seed)
{
  ptgfsr[0] = seed;
  for (k = 1; k < N; k++)
    ptgfsr[k] = 69069 * ptgfsr[k - 1];
  k = 1;
}

unsigned int RandomInt(int range)
{
    return unsigned(RandomLong(range));
}

unsigned int RandomInt(void)
{
    return unsigned(RandomLong());
}



