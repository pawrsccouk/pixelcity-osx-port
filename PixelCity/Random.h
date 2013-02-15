
#ifdef __cplusplus
extern "C" {
#endif
    


void RandomInit (unsigned long seed);

unsigned long RandomLongR(long range);
unsigned long RandomLong(void);

unsigned int  RandomIntR(int range);
unsigned int  RandomInt (void);

//#define COIN_FLIP     (RandomVal (2) == 0)
    // Returns TRUE or FALSE decided randomly.
int COIN_FLIP(void);

#ifdef __cplusplus
}
#endif
