//
//  QSMDQueryWrapper.h
//  QSSpotlightPlugIn
//
//  Created by Nicholas Jitkoff on 4/1/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

@interface QSMDQueryWrapper : NSObject {
	
	NSString *query;
	NSString *path;
	NSMutableArray *results;
	BOOL keepalive;
	NSTask *task;
	NSMutableString *resultPaths;
}
+ findWrapperWithQuery:(NSString *)aQuery path:(NSString *)aPath keepalive:(BOOL)keepAlive;
- (void)startQuery;
- (NSMutableArray *)results;
@end
