
#define WRAP(x,y) (unsigned(x) % y)

template <class T> inline const T& CLAMP(const T& a, const T& b, const T& c) { return (a < b ? b : (a > c ? c : a)); }

// ABS is a macro in Objective-C
#if !defined(ABS)
template <class T> inline const T& ABS (const T& x) { return (((x) < 0 ? (-x) : (x))); }
#endif

template <class T> inline const T& SMALLEST(const T& x, const T& y) { return (ABS(x) < ABS(y)) ? 0 : x; }
template <class T> float POW(T& x, T& y) { return float(pow(x,y)); }

template <class T> inline int SIGN(const T& x)
{
    return (x > 0) ? 1
                   : (x < 0) ? -1
                             : 0;
}

//#define SWAP(a,b)                 {int temp = a;a = b; b = temp;}
//#define MIN(x,y)                  ((x) < (y) ? x : y)                
//#define MAX(x,y)                  ((x) > (y) ? x : y)                

typedef unsigned char  BYTE;
typedef unsigned short WORD;

inline BYTE GetRValue(unsigned long rgb) { return BYTE(rgb); }
inline BYTE GetGValue(unsigned long rgb) { return BYTE(WORD(rgb) >> 8 ); }
inline BYTE GetBValue(unsigned long rgb) { return BYTE(WORD(rgb) >> 16); }

