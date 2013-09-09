// 2009 Shamus Young
// Modified 2013 by Patrick A Wallace. If you find any bugs, assume they are mine.
// Released under the GNU GPL v3. See file COPYING for details.

@class World;

@interface Sky : NSObject

@property (nonatomic, readonly) __weak World *world;

-(id)initWithWorld:(World*) world;
-(void) render;
-(void) clear;

@end

