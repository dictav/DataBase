//
//  DataBaseTests.m
//  DataBaseTests
//
//  Created by Shintaro Abe on 1/6/14.
//  Copyright (c) 2014 dictav. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "DataBase.h"

@interface DataBaseTests : XCTestCase

@end

@implementation DataBaseTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSharedDatabase
{
    DataBase *db = [DataBase sharedDB];
    XCTAssertNotNil(db);
}

@end
