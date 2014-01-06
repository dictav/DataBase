//
//  DataBase.h
//  CollaboQuest
//
//  Created by Shintaro Abe on 2013/10/05.
//  Copyright (c) 2013年 Collabo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface DataBase : NSObject
+ (DataBase*)sharedDB;
+ (void)flushDB;

- (NSInteger) countForEntityForName:(NSString*)entityName withPredicate:(NSPredicate*)predidate;
- (NSInteger) countForEntityForName:(NSString*)entityName byIDs:(NSArray*)ids;
- (NSArray*) findObjectsForEntityForName:(NSString*)entityName withPredicate:(NSPredicate*)predidate;
- (NSArray*) findObjectsForEntityForName:(NSString*)entityName byIDs:(NSArray*)ids;
- (NSArray*) findObjectsForEntityForName:(NSString*)entityName withSortDescriptors:(NSArray*)sortDescriptors;
- (NSFetchedResultsController*)excuteFetchRequest:(NSFetchRequest*)fetchRequest
                               sectionNameKeyPath:(NSString*)keyPath
                                        cacheName:(NSString*)cacheName
                                            error:(NSError**)error;
- (NSManagedObject*)objectWithID:(NSManagedObjectID*)objectID;
- (NSManagedObject*)insertNewObjectForEntityForName:(NSString*)entityName;
- (BOOL)save;
@end
