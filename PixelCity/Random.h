
void RandomInit (unsigned long seed);

unsigned long RandomLong(long range);
unsigned long RandomLong(void);
unsigned int  RandomInt (int range);
unsigned int  RandomInt (void);

//#define COIN_FLIP     (RandomVal (2) == 0)
inline bool COIN_FLIP(void) { return RandomInt(2) == 0; }
