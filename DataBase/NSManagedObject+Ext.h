//
//  NSManagedObject+Ext.h
//  CollaboQuest
//
//  Created by Shintaro Abe on 2013/10/07.
//  Copyright (c) 2013年 Collabo. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (Ext)
+ (id)insertObject;
+ (id)findObjectWithIdentifier:(id)identifier;
+ (id)createObjectWithDictionary:(NSDictionary*)parameters;
+ (NSArray*)objectsWithIdentifiers:(NSArray*)ids;
- (void)updateWithDictionary:(NSDictionary*)parameters;
- (NSData*)messagePack;
- (BOOL)upload;
- (NSString*)uploadKey;
- (NSDictionary*)prepareMessagePack;
@end
