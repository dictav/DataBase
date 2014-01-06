//
//  DataBase.m
//  CollaboQuest
//
//  Created by Shintaro Abe on 2013/10/05.
//  Copyright (c) 2013年 Collabo. All rights reserved.
//

#import "DataBase.h"

#ifndef Log
#define Log(__FORMAT__, ...) NSLog((@"%s [Line %d] " __FORMAT__), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#endif

#ifndef ModelName
#define ModelName @"DataBase"
#endif

#ifdef TEST
#define StoreName ModelName @"Test.sqlite"
#else
#define StoreName ModelName @".sqlite"
#endif

#define SORT_FETCH_LIMIT 50


@interface DataBase ()
@property (nonatomic) NSManagedObjectContext *parentContext;
@property (nonatomic) NSManagedObjectContext *childContext;
@property (nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@end

@implementation DataBase

static DataBase *sharedDB;
+ (DataBase*)sharedDB
{
    @synchronized(self){
        if (sharedDB == nil) {
            sharedDB= [self new];
        }
    }
    
    return sharedDB;
}

+ (void)flushDB
{
    sharedDB.persistentStoreCoordinator = nil;
    sharedDB = nil;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    NSString *path = [[self storeURL] path];
    [fm removeItemAtPath:path error:&error];
    if (error) {
        Log(@"FlushDB error: %@", error);
    }
}

#pragma mark - 

- (id)init
{
    self = [super init];
    if (self) {
        _parentContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _parentContext.persistentStoreCoordinator = [self persistentStoreCoordinator];
        _childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _childContext.parentContext = _parentContext;
    }
    return self;
}

- (NSInteger) countForEntityForName:(NSString *)entityName withPredicate:(NSPredicate *)predicate
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entityName];
    request.predicate = predicate;
    __block NSInteger count = 0;
    [[DataBase sharedDB].parentContext performBlockAndWait:^{
        NSError *error;
        count = [[DataBase sharedDB].parentContext countForFetchRequest:request error:&error];
        if (error) {
            Log(@"count predicate error: %@", error);
        }
    }];
    
    return count;
}

- (NSInteger) countForEntityForName:(NSString*)entityName byIDs:(NSArray*)ids
{
    return [self countForEntityForName:entityName
                         withPredicate:[NSPredicate predicateWithFormat:@"id IN %@", ids]];
}

- (NSArray*) findObjectsForEntityForName:(NSString *)entityName withPredicate:(NSPredicate *)predicate
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entityName];
    request.predicate = predicate;
    __block NSArray *objects;
    [_parentContext performBlockAndWait:^{
        NSError *error;
        objects = [[DataBase sharedDB].parentContext executeFetchRequest:request error:&error];
        if (error) {
            Log(@"find objects error: %@", error);
        }
    }];
    
    return objects;
}

- (NSArray*) findObjectsForEntityForName:(NSString*)entityName byIDs:(NSArray*)ids
{
    return [self findObjectsForEntityForName:entityName
                               withPredicate:[NSPredicate predicateWithFormat:@"id IN %@", ids]];
}

- (NSArray*) findObjectsForEntityForName:(NSString *)entityName withSortDescriptors:(NSArray *)sortDescriptors
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entityName];
    request.sortDescriptors = sortDescriptors;
    request.fetchLimit = SORT_FETCH_LIMIT;
    __block NSArray *objects;
    [_parentContext performBlockAndWait:^{
        NSError *error;
        objects = [[DataBase sharedDB].parentContext executeFetchRequest:request error:&error];
        if (error) {
            Log(@"find objects error: %@", error);
        }
    }];
    
    return objects;
}

- (NSFetchedResultsController*)excuteFetchRequest:(NSFetchRequest*)fetchRequest
                               sectionNameKeyPath:(NSString*)keyPath
                                        cacheName:(NSString*)cacheName
                                            error:(NSError**)error
{
    __block NSFetchedResultsController *controller;
    [_parentContext performBlockAndWait:^{
        controller = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                         managedObjectContext:self.parentContext
                                                           sectionNameKeyPath:keyPath
                                                                    cacheName:cacheName];
        if (![controller performFetch:error]) {
            controller = nil;
            NSLog(@"fetched controller fetch error: %@", *error);
        }
    }];
    
    return controller;
}

- (NSManagedObject*)objectWithID:(NSManagedObjectID *)objectID
{
    __block NSManagedObject *object;
    [_parentContext performBlockAndWait:^{
        object = [_parentContext objectWithID:objectID];
    }];
    
    return object;
}

- (NSManagedObject*)insertNewObjectForEntityForName:(NSString *)entityName
{
    __block NSManagedObject *object;
    [_parentContext performBlockAndWait:^{
        object =  [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                inManagedObjectContext:_parentContext];
    }];
    
    return object;
}

- (BOOL)save
{
    if (![_parentContext hasChanges]) {
        return YES;
    }
    
    __block BOOL isSaved = NO;
    [_parentContext performBlockAndWait:^{
        NSError *error;
        isSaved = [_parentContext save:&error];
        if (error) {
            Log(@"parent context save error: %@", error);
        }
    }];
    
    return isSaved;
}

#pragma mark - Core Data stack

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator == nil) {
        NSURL *modelURL = [[NSBundle bundleForClass:[self class]] URLForResource:ModelName withExtension:@"momd"];
        NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        
        NSError *error = nil;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                       configuration:nil
                                                                 URL:[self.class storeURL]
                                                             options:nil
                                                               error:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
             @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
             
             Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
             
             */
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtURL:[self.class storeURL] error:&error];
            if (!error) {
                _persistentStoreCoordinator = [self persistentStoreCoordinator];
            }
        }
    };
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
+ (NSURL *)storeURL
{
    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    return [url URLByAppendingPathComponent:StoreName];
}


@end
