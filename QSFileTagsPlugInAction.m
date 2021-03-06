//
//  QSFileTagsPlugInAction.m
//  QSFileTagsPlugIn
//
//  Created by Nicholas Jitkoff on 5/3/05.
//  Copyright __MyCompanyName__ 2005. All rights reserved.
//

#import "QSMDTagsQueryManager.h"
#import "QSFileTagsPlugInAction.h"

#define kQSFileTagsPlugInAction @"QSFileTagsPlugInAction"

@implementation QSFileTagsPlugInAction

#pragma mark - Quicksilver Actions

- (QSObject *)addTagsForFile:(QSObject *)dObject tags:(QSObject *)iObject {
	NSArray *newTags = [[iObject stringValue] componentsSeparatedByString:@" "];
	newTags = [[QSMDTagsQueryManager sharedInstance] performSelector:@selector(stringByAddingTagPrefix:) onObjectsInArray:newTags returnValues:YES];
	[self tagFiles:[dObject validPaths] add:newTags remove:nil set:nil];
	return nil;
}

- (QSObject *)removeTagsForFile:(QSObject *)dObject tags:(QSObject *)iObject {
	NSArray *newTags = [[iObject stringValue] componentsSeparatedByString:@" "];
	newTags = [[QSMDTagsQueryManager sharedInstance] performSelector:@selector(stringByAddingTagPrefix:) onObjectsInArray:newTags returnValues:YES];
	[self tagFiles:[dObject validPaths] add:nil remove:newTags set:nil];
	return nil;
}

- (QSObject *)setTagsForFile:(QSObject *)dObject tags:(QSObject *)iObject {
	NSArray *newTags = [[iObject stringValue] componentsSeparatedByString:@" "];
	newTags = [[QSMDTagsQueryManager sharedInstance] performSelector:@selector(stringByAddingTagPrefix:) onObjectsInArray:newTags returnValues:YES];
	[self tagFiles:[dObject validPaths] add:nil remove:nil set:newTags];
	return nil;
}

- (QSObject *)showWindowForTag:(QSObject *)dObject {
//	NSString *string = [dObject stringValue];
	
	return nil;
}

- (QSObject *)showTags:(QSObject *)dObject {
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	NSString *comment = [ws commentForFile:[dObject singleFilePath]];
	NSArray *tags = [self tagsFromString:comment];
	NSMutableArray *tagObjects = [self performSelector:@selector(objectForTag:) onObjectsInArray:tags returnValues:YES];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:tagObjects, kQSResultArrayKey, nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"QSSourceArrayCreated" object:self userInfo:userInfo];
	return nil;
}

- (QSObject *)showTaggedFilesInFinder:(QSObject *)dObject {
	NSString *string = [[QSMDTagsQueryManager sharedInstance] stringByAddingTagPrefix:[dObject stringValue]];
	
	NSArray *slices = [NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Othr", @"FXSliceKind", @"kMDItemFinderComment", @"FXAttribute", string, @"Value", @"S:**", @"Operator", nil]];
	NSString *name = [NSString stringWithFormat:@" {%@} ", string];
	NSString *query = [NSString stringWithFormat:@"(kMDItemFinderComment = '%@'cdw) ", string];
	//	NSLog(@"SPURL: %@ - %@", scheme, query);
	
	[self runQuery:query withName:name slices:slices];
	return nil; 	
}

- (QSObject *)setCommentForFile:(QSObject *)dObject to:(QSObject *)iObject{
	NSString *newComment, *path, *oldComment;
	NSArray *tags;
	for (QSObject *targetFile in [dObject splitObjects]) {
		path = [targetFile objectForType:QSFilePathType];
		oldComment = [[NSWorkspace sharedWorkspace] commentForFile:path];
		tags = [self tagsFromString:oldComment];
		newComment = [self string:[iObject stringValue] byAddingTags:nil removingTags:nil settingTags:tags];
		[[NSWorkspace sharedWorkspace] setComment:newComment forFile:path];
	}
	return nil;
}

#pragma mark - Quicksilver Validation

- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject {
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	NSString *comment = [ws commentForFile:[dObject singleFilePath]];
	QSObject *textObject = nil;
	if ([action isEqualToString:@"QSAddFileTagsAction"]) {
		textObject = [QSObject textProxyObjectWithDefaultValue:@""];
	} else if ([action isEqualToString:@"QSSetFileCommentAction"]) {
		NSString *comment = [self commentFromString:[[NSWorkspace sharedWorkspace] commentForFile:[dObject singleFilePath]]];
		return [NSArray arrayWithObject:[QSObject textProxyObjectWithDefaultValue:comment?comment:@""]];
	} else {
		NSArray *tags = [self tagsFromString:comment];
		tags = [[QSMDTagsQueryManager sharedInstance] performSelector:@selector(stringByRemovingTagPrefix:) onObjectsInArray:tags returnValues:YES];
		
		textObject = [QSObject textProxyObjectWithDefaultValue:[tags componentsJoinedByString:@" "]];
	}
	return [NSArray arrayWithObject:textObject]; //[QSLibarrayForType:NSFilenamesPboardType];
}

#pragma mark - Helper Methods

- (NSArray *)tagsFromString:(NSString *)string {
	NSArray *tags = [string componentsSeparatedByString:@" "];
	NSMutableSet *realTags = [NSMutableSet set];
	for (NSString *tag in tags) {
        if ([[QSMDTagsQueryManager sharedInstance] stringByRemovingTagPrefix:tag]) {
			[realTags addObject:tag];
		}
	}
	return [realTags allObjects];
}

- (NSString *)commentFromString:(NSString *)string
{
	return [self string:string byAddingTags:nil removingTags:[self tagsFromString:string] settingTags:nil];
}

- (NSString *)string:(NSString *)string byAddingTags:(NSArray *)add removingTags:(NSArray *)remove settingTags:(NSArray *)setTags {
	
	NSMutableArray *words = [NSMutableArray array];
	NSMutableSet *tags;
	// process the existing Spotlight comment
	if ([string length]) {
		NSArray *array = [string componentsSeparatedByString:@" "];
		// split words from tags in the existing comment (preserving order and duplicates)
		for (NSString *component in array) {
			if (![[QSMDTagsQueryManager sharedInstance] stringByRemovingTagPrefix:component]) {
				[words addObject:component];
			}
		}
	}
	if ([setTags count]) {
		// overwrite exisitng tags
		tags = [NSMutableSet setWithArray:setTags];
	} else {
		// build a list of tags
		tags = [NSMutableSet setWithArray:[self tagsFromString:string]];
		NSSet *removeTags = [NSSet setWithArray:remove];
		NSSet *addTags = [NSSet setWithArray:add];
		[tags minusSet:removeTags];
		[tags unionSet:addTags];
	}
	[words addObjectsFromArray:[tags allObjects]];
    NSString *result = [words componentsJoinedByString:@" "];
	return result;
}

- (void)tagFiles:(NSArray *)paths add:(NSArray *)add remove:(NSArray *)remove set:(NSArray *)set {
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	for (NSString *path in paths) {
		NSString *comment = [ws commentForFile:path];
		comment = [self string:comment byAddingTags:add removingTags:remove settingTags:set];
		//	NSLog(@"newcomm %@", comment);
		[ws setComment:comment forFile:path];
	}
	return;
	
}

- (QSObject *)objectForTag:(NSString *)tag {
	return [QSObject objectWithType:QSFileTagType value:tag name:[[QSMDTagsQueryManager sharedInstance] stringByRemovingTagPrefix:tag]]; 	
}

- (void)runQuery:(NSString *)query withName:(NSString *)name slices:(NSArray *)slices {
	NSString *trueQuery = query;
	if ([trueQuery rangeOfString:@"kMD"] .location == NSNotFound) {
		trueQuery = [NSString stringWithFormat:@"((kMDItemFSName = '%@*'cd) || kMDItemTextContent = '%@*'cd) && (kMDItemContentType != com.apple.mail.emlx) && (kMDItemContentType != public.vcard) ", query, query];
	}
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"ToolbarVisible"]
			 forKey:@"ViewOptions"];
	[dict setObject:[NSNumber numberWithInt:0]
			 forKey:@"CompatibleVersion"];
	[dict setObject:trueQuery
			 forKey:@"RawQuery"];
    
	if ([NSApplication isLeopard]) {
		// Saved searches seem to now require an array of paths to search.  Current code uses root as the path.
		[dict setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                         //query, @"AnyAttributeContains",
                         [NSArray arrayWithObjects:@"/", nil], @"FXScopeArrayOfPaths",
                         slices, @"FXCriteriaSlices",
                         nil]
                 forKey:@"SearchCriteria"]; 	
	} else {
		[dict setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                         //query, @"AnyAttributeContains",
                         slices,
                         @"FXCriteriaSlices",
                         nil]
                 forKey:@"SearchCriteria"]; 	
	}
	
	NSMutableString *filename = [[name mutableCopy] autorelease];
	if (!filename) {
		filename = [[query mutableCopy] autorelease];
		[filename replaceOccurrencesOfString:@"/" withString:@"_" options:0 range:NSMakeRange(0, [filename length])];
		if ([filename length] > 242)
			filename = [[[filename substringToIndex:242] mutableCopy] autorelease];
	}
	[filename appendString:@".savedSearch"];
	filename = (NSMutableString*)[NSTemporaryDirectory() stringByAppendingPathComponent:filename];
	[dict writeToFile:filename atomically:NO];
	[[NSFileManager defaultManager] setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:
                                                          NSFileExtensionHidden] ofItemAtPath:filename error:nil];
	[[NSWorkspace sharedWorkspace] openFile:filename];
}

@end
