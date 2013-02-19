/*-----------------------------------------------------------------------------
									               r a n d o m
-----------------------------------------------------------------------------*/
#import "Model.h"
#import <memory.h>

/*-----------------------------------------------------------------------------
  The Mersenne Twister by Matsumoto and Nishimura <matumoto@math.keio.ac.jp>.
  It sets new standards for the period, quality and speed of random number
  generators. The incredible period is 2^19937 - 1, a number with about 6000
  digits; the 32-bit random numbers exhibit best possible equidistribution
  properties in dimensions up to 623; and it's fast, very fast. 
-----------------------------------------------------------------------------*/

static const int M = 397, N = 624;

static const GLulong LOWER_MASK = 0x7fffffff, UPPER_MASK = 0x80000000;
static const GLulong TEMPERING_MASK_B   =   0x9d2c5680, TEMPERING_MASK_C   =   0xefc60000;
static const GLulong MATRIX_A           =   0x9908b0df;

inline GLulong TEMPERING_SHIFT_L(GLulong y) { return (y >> 18); }
inline GLulong TEMPERING_SHIFT_S(GLulong y) { return (y << 7 ); }
inline GLulong TEMPERING_SHIFT_T(GLulong y) { return (y << 15); }
inline GLulong TEMPERING_SHIFT_U(GLulong y) { return (y >> 11); }

static int              k = 1;
static GLulong    mag01[2] = {0x0, MATRIX_A};
static GLulong    ptgfsr[N];

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

GLulong RandomLong(void)
{
  int		     kk;
  GLulong	 y;
  
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

GLulong RandomLongR(GLlong range)
{
  return range ? (RandomLong() % range) : 0;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void RandomInit (GLulong seed)
{
  ptgfsr[0] = seed;
  for (k = 1; k < N; k++)
    ptgfsr[k] = 69069 * ptgfsr[k - 1];
  k = 1;
}

GLuint RandomIntR(int range)
{
    return unsigned(RandomLongR(range));
}

GLuint RandomInt(void)
{
    return unsigned(RandomLong());
}



