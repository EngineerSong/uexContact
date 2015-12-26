#import "NSDictionary-MutableDeepCopy.h"

@implementation NSDictionary(MutableDeepCopy)

- (NSMutableDictionary *) mutableDeepCopy {
    NSMutableDictionary * returnDict = [[[NSMutableDictionary alloc]
									   initWithCapacity:[self count]] autorelease];
    NSArray * keys = [self allKeys];
    for (id key in keys) {
        id oneValue = [self valueForKey:key];
        id oneCopy = nil;
        BOOL needRelease = YES;
        
        if ([oneValue respondsToSelector:@selector(mutableDeepCopy)]){
            needRelease = NO;
            oneCopy = [oneValue mutableDeepCopy];
        }else if ([oneValue respondsToSelector:@selector(mutableCopy)]){
            oneCopy = [oneValue mutableCopy];
        }
        if (oneCopy == nil){
            needRelease = YES;
            oneCopy = [oneValue copy];
        }
        [returnDict setValue:oneCopy forKey:key];
        if (needRelease) {
            [oneCopy release];
        }
    }
    return returnDict;
}
@end
