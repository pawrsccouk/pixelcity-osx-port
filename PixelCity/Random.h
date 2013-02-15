
#ifdef __cplusplus
extern "C" {
#endif

    void RandomInit (unsigned long seed);
    
    unsigned long RandomLongR(long range);
    unsigned long RandomLong(void);
    
    unsigned int  RandomIntR(int range);
    unsigned int  RandomInt (void);


#ifdef __cplusplus
}
#endif

    // Returns TRUE or FALSE decided randomly.
    inline bool COIN_FLIP(void) { return (RandomIntR(2) == 0); }
