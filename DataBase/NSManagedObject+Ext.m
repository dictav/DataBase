//
//  NSManagedObject+Ext.m
//  CollaboQuest
//
//  Created by Shintaro Abe on 2013/10/07.
//  Copyright (c) 2013年 Collabo. All rights reserved.
//

#import "NSManagedObject+Ext.h"
#import "DataBase.h"
#import <MessagePack.h>
#import <Redis.h>

NSDate * dateFromString(id dateString)
{
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [NSDateFormatter new];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
    });
    
    if ([dateString isKindOfClass:[NSString class]]) {
        return [formatter dateFromString:dateString];
    }
    else if ([dateString isEqual:[NSDate class]]) {
        return dateString;
    }
    else {
        return nil;
    }
}

@implementation NSManagedObject (Ext)
+ (NSString*)identifierKey
{
    return @"id";
}

+ (NSString*)entityName
{
    return NSStringFromClass([self class]);
}

+ (id)insertObject
{
    return [[DataBase sharedDB] insertNewObjectForEntityForName:[self entityName]];
}

+ (id)findObjectWithIdentifier:(id)identifier
{
    NSString *key = [self identifierKey];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", key, identifier];
    
    return [[DataBase sharedDB] findObjectsForEntityForName:[self entityName]
                                              withPredicate:predicate].firstObject;
}

+ (id)createObjectWithDictionary:(NSDictionary*)parameters
{
    NSAssert(parameters, @"require parameters");
    
    // find by id
    NSNumber *_id = parameters[[self identifierKey]];
    NSManagedObject *object;
    if (_id && [_id isKindOfClass:[NSNumber class]]) {
        object = [self findObjectWithIdentifier:_id];
    }
    
    // insert object
    if (object == nil) {
        object = [self insertObject];
    }
    
    // set parameters
    [object updateWithDictionary:parameters];
    
    return object;
}

+ (NSArray*)objectsWithIdentifiers:(NSArray *)ids
{
    NSString *key = [self identifierKey];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%@ IN %@", key, ids];
    
    return [[DataBase sharedDB] findObjectsForEntityForName:[self entityName]
                                              withPredicate:predicate];
}

- (NSDictionary*)prepareMessagePack
{
    NSMutableDictionary *data = [NSMutableDictionary new];
    for (NSString *key in self.entity.attributesByName.allKeys) {
        id val = [self valueForKey:key];
        if (val == nil) {
            continue;
        }
        else if ([val isKindOfClass:[NSDate class]]) {
            val = [val description];
        }
        data[key] = val;
    }
    
    for (NSString *key in self.entity.relationshipsByName.allKeys) {
        id val = [self valueForKey:key];
        if (val && [val isKindOfClass:[NSManagedObject class]]) {
            data[key] = [val prepareMessagePack];
        }
    }
    
    return data;
}

- (NSData*)messagePack
{
    return [[self prepareMessagePack] messagePack];
}

#ifdef DEBUG
- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    NSLog(@"!!! %@\n key:%@, val:%@", [self class], key,value);
}
#endif

- (void)updateWithDictionary:(NSDictionary *)parameters
{
    [self.managedObjectContext performBlockAndWait:^{
        
        for (NSString *key in parameters) {
            id val = parameters[key];
            
            // convert id to numeric value
            if ([key isEqualToString:@"id"] && ![val isKindOfClass:[NSNumber class]]) {
                val = @([val integerValue]);
            }
            // convert dateString to NSDate
            else if ([key hasSuffix:@"Date"] && [val isKindOfClass:[NSString class]]) {
                val = dateFromString(val);
            }
            // convert relashonship
            else if ([self.entity.relationshipsByName.allKeys containsObject:key]) {
                Class cls = NSClassFromString([key capitalizedString]);
                if (cls) {
                    val = [cls createObjectWithDictionary:val];
                }
            }
            
            [self setValue:val forKey:key];
        }
    }];
}

- (NSString*)uploadKey
{
    NSAssert(NO, @"please override %@", NSStringFromSelector(_cmd));
    return nil;
}

- (BOOL)isList
{
    return NO;
}

- (NSNumber*)uploadIndex
{
    return nil;
}

- (void)updateIndex:(NSNumber*)index
{
    NSAssert(NO, @"please override %@", NSStringFromSelector(_cmd));
}


- (BOOL)concealUpload
{
    // prepare data
    NSData *data = [self messagePack];
    NSString *key = [self uploadKey];
    NSNumber *idx = [self uploadIndex];
    
    Redis *redis = [Redis sharedRedis];
    id ret;
    if ([self isList]) {
        if (idx) {
            ret = [redis setValue:data
                           forKey:key
                          atIndex:[idx integerValue]];
        }
        else {
            ret = [redis pushValue:data forKey:key];
            [self updateIndex:@([ret integerValue] - 1)];
        }
    }
    else {
        ret = [redis setValue:data forKey:[self uploadKey]];
    }
    return (ret != nil);
}


- (BOOL)upload
{
    // check validation
    if (![self validateForUpdate:NULL]) {
        return NO;
    }
    
    return [self concealUpload];
}
@end
