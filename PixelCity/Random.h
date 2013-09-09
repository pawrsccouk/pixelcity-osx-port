
#ifdef __cplusplus
extern "C" {
#endif

    void RandomInit (GLulong seed);
    
    GLulong RandomLongR(GLlong range);
    GLulong RandomLong(void);
    
    GLuint  RandomIntR(int range);
    GLuint  RandomInt (void);


#ifdef __cplusplus
}
#endif

    // Returns TRUE or FALSE decided randomly.
inline bool COIN_FLIP(void) { return (RandomIntR(2) == 0); }
