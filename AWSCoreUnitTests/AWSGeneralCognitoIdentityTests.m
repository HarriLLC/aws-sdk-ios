//
// Copyright 2010-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "OCMock.h"
#import "AWSTestUtility.h"
#import "AWSCognitoIdentityService.h"

static id mockNetworking = nil;

@interface AWSGeneralCognitoIdentityTests : XCTestCase

@end

@implementation AWSGeneralCognitoIdentityTests

- (void)setUp {
    [super setUp];
    [AWSTestUtility setupFakeCognitoCredentialsProvider];

    mockNetworking = OCMClassMock([AWSNetworking class]);
    AWSTask *errorTask = [AWSTask taskWithError:[NSError errorWithDomain:@"OCMockExpectedNetworkingError" code:8848 userInfo:nil]];
    OCMStub([mockNetworking sendRequest:[OCMArg isKindOfClass:[AWSNetworkingRequest class]]]).andReturn(errorTask);
}

- (void)tearDown {
    [super tearDown];
}

- (void)testConstructors {
    NSString *key = @"testCognitoIdentityConstructors";
    XCTAssertNotNil([AWSCognitoIdentity defaultCognitoIdentity]);
    XCTAssertEqual([[AWSCognitoIdentity defaultCognitoIdentity] class], [AWSCognitoIdentity class]);
    XCTAssertNil([AWSCognitoIdentity CognitoIdentityForKey:key]);

    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionSAEast1 credentialsProvider:[AWSServiceManager defaultServiceManager].defaultServiceConfiguration.credentialsProvider];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];
    XCTAssertNotNil([AWSCognitoIdentity CognitoIdentityForKey:key]);
    XCTAssertEqual([[AWSCognitoIdentity CognitoIdentityForKey:key] class], [AWSCognitoIdentity class]);
    XCTAssertEqual([AWSCognitoIdentity CognitoIdentityForKey:key].configuration.regionType, AWSRegionSAEast1);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
    XCTAssertNil([AWSCognitoIdentity CognitoIdentityForKey:key]);

}

- (void)testCreateIdentityPool {
    NSString *key = @"testCreateIdentityPool";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];
    [[[[AWSCognitoIdentity CognitoIdentityForKey:key] createIdentityPool:[AWSCognitoIdentityCreateIdentityPoolInput new]] continueWithBlock:^id(AWSTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", task.error.domain);
        XCTAssertEqual(8848, task.error.code);
        XCTAssertNil(task.result);
        return nil;
    }] waitUntilFinished];

    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testCreateIdentityPoolCompletionHandler {
    NSString *key = @"testCreateIdentityPool";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[[AWSCognitoIdentity CognitoIdentityForKey:key] createIdentityPool:[AWSCognitoIdentityCreateIdentityPoolInput new] completionHandler:^(AWSCognitoIdentityIdentityPool* _Nullable response, NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", error.domain);
        XCTAssertEqual(8848, error.code);
        XCTAssertNil(response);
        dispatch_semaphore_signal(semaphore);
    }];
	
 	dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int)(2.0 * NSEC_PER_SEC)));
    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testCreateIdentityPoolWithSuppliedHeaders {
    AWSServiceConfiguration *configuration = [AWSTestUtility getDefaultServiceConfiguration];
    configuration.headers = @{@"foo": @"bar"};
    id key = @"test-with-headers";
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];
    AWSCognitoIdentity *cognitoIdentity = [AWSCognitoIdentity CognitoIdentityForKey:key];
    NSDictionary *expected = @{@"foo": @"bar", @"Content-Type": @"application/x-amz-json-1.1"};
    XCTAssertEqualObjects(cognitoIdentity.configuration.headers, expected, @"expected provided headers to be included in configuration object");
}

- (void)testCreateIdentityPoolNoSuppliedHeaders {
    AWSServiceConfiguration *configuration = [AWSTestUtility getDefaultServiceConfiguration];
    id key = @"test-without-headers";
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];
    AWSCognitoIdentity *cognitoIdentity = [AWSCognitoIdentity CognitoIdentityForKey:key];
    NSDictionary *expected = @{@"Content-Type": @"application/x-amz-json-1.1"};
    XCTAssertEqualObjects(cognitoIdentity.configuration.headers, expected, @"expected Content-Type header to be included");
}

- (void)testDeleteIdentities {
    NSString *key = @"testDeleteIdentities";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];
    [[[[AWSCognitoIdentity CognitoIdentityForKey:key] deleteIdentities:[AWSCognitoIdentityDeleteIdentitiesInput new]] continueWithBlock:^id(AWSTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", task.error.domain);
        XCTAssertEqual(8848, task.error.code);
        XCTAssertNil(task.result);
        return nil;
    }] waitUntilFinished];

    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testDeleteIdentitiesCompletionHandler {
    NSString *key = @"testDeleteIdentities";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[[AWSCognitoIdentity CognitoIdentityForKey:key] deleteIdentities:[AWSCognitoIdentityDeleteIdentitiesInput new] completionHandler:^(AWSCognitoIdentityDeleteIdentitiesResponse* _Nullable response, NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", error.domain);
        XCTAssertEqual(8848, error.code);
        XCTAssertNil(response);
        dispatch_semaphore_signal(semaphore);
    }];
	
 	dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int)(2.0 * NSEC_PER_SEC)));
    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testDeleteIdentityPool {
    NSString *key = @"testDeleteIdentityPool";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];
    [[[[AWSCognitoIdentity CognitoIdentityForKey:key] deleteIdentityPool:[AWSCognitoIdentityDeleteIdentityPoolInput new]] continueWithBlock:^id(AWSTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", task.error.domain);
        XCTAssertEqual(8848, task.error.code);
        XCTAssertNil(task.result);
        return nil;
    }] waitUntilFinished];

    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testDeleteIdentityPoolCompletionHandler {
    NSString *key = @"testDeleteIdentityPool";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[[AWSCognitoIdentity CognitoIdentityForKey:key] deleteIdentityPool:[AWSCognitoIdentityDeleteIdentityPoolInput new] completionHandler:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", error.domain);
        XCTAssertEqual(8848, error.code);
        dispatch_semaphore_signal(semaphore);
    }];
	
 	dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int)(2.0 * NSEC_PER_SEC)));
    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testDescribeIdentity {
    NSString *key = @"testDescribeIdentity";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];
    [[[[AWSCognitoIdentity CognitoIdentityForKey:key] describeIdentity:[AWSCognitoIdentityDescribeIdentityInput new]] continueWithBlock:^id(AWSTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", task.error.domain);
        XCTAssertEqual(8848, task.error.code);
        XCTAssertNil(task.result);
        return nil;
    }] waitUntilFinished];

    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testDescribeIdentityCompletionHandler {
    NSString *key = @"testDescribeIdentity";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[[AWSCognitoIdentity CognitoIdentityForKey:key] describeIdentity:[AWSCognitoIdentityDescribeIdentityInput new] completionHandler:^(AWSCognitoIdentityIdentityDescription* _Nullable response, NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", error.domain);
        XCTAssertEqual(8848, error.code);
        XCTAssertNil(response);
        dispatch_semaphore_signal(semaphore);
    }];
	
 	dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int)(2.0 * NSEC_PER_SEC)));
    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testDescribeIdentityPool {
    NSString *key = @"testDescribeIdentityPool";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];
    [[[[AWSCognitoIdentity CognitoIdentityForKey:key] describeIdentityPool:[AWSCognitoIdentityDescribeIdentityPoolInput new]] continueWithBlock:^id(AWSTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", task.error.domain);
        XCTAssertEqual(8848, task.error.code);
        XCTAssertNil(task.result);
        return nil;
    }] waitUntilFinished];

    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testDescribeIdentityPoolCompletionHandler {
    NSString *key = @"testDescribeIdentityPool";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[[AWSCognitoIdentity CognitoIdentityForKey:key] describeIdentityPool:[AWSCognitoIdentityDescribeIdentityPoolInput new] completionHandler:^(AWSCognitoIdentityIdentityPool* _Nullable response, NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", error.domain);
        XCTAssertEqual(8848, error.code);
        XCTAssertNil(response);
        dispatch_semaphore_signal(semaphore);
    }];
	
 	dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int)(2.0 * NSEC_PER_SEC)));
    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testGetCredentialsForIdentity {
    NSString *key = @"testGetCredentialsForIdentity";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];
    [[[[AWSCognitoIdentity CognitoIdentityForKey:key] getCredentialsForIdentity:[AWSCognitoIdentityGetCredentialsForIdentityInput new]] continueWithBlock:^id(AWSTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", task.error.domain);
        XCTAssertEqual(8848, task.error.code);
        XCTAssertNil(task.result);
        return nil;
    }] waitUntilFinished];

    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testGetCredentialsForIdentityCompletionHandler {
    NSString *key = @"testGetCredentialsForIdentity";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[[AWSCognitoIdentity CognitoIdentityForKey:key] getCredentialsForIdentity:[AWSCognitoIdentityGetCredentialsForIdentityInput new] completionHandler:^(AWSCognitoIdentityGetCredentialsForIdentityResponse* _Nullable response, NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", error.domain);
        XCTAssertEqual(8848, error.code);
        XCTAssertNil(response);
        dispatch_semaphore_signal(semaphore);
    }];
	
 	dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int)(2.0 * NSEC_PER_SEC)));
    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testGetId {
    NSString *key = @"testGetId";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];
    [[[[AWSCognitoIdentity CognitoIdentityForKey:key] getId:[AWSCognitoIdentityGetIdInput new]] continueWithBlock:^id(AWSTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", task.error.domain);
        XCTAssertEqual(8848, task.error.code);
        XCTAssertNil(task.result);
        return nil;
    }] waitUntilFinished];

    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testGetIdCompletionHandler {
    NSString *key = @"testGetId";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[[AWSCognitoIdentity CognitoIdentityForKey:key] getId:[AWSCognitoIdentityGetIdInput new] completionHandler:^(AWSCognitoIdentityGetIdResponse* _Nullable response, NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", error.domain);
        XCTAssertEqual(8848, error.code);
        XCTAssertNil(response);
        dispatch_semaphore_signal(semaphore);
    }];
	
 	dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int)(2.0 * NSEC_PER_SEC)));
    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testGetIdentityPoolRoles {
    NSString *key = @"testGetIdentityPoolRoles";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];
    [[[[AWSCognitoIdentity CognitoIdentityForKey:key] getIdentityPoolRoles:[AWSCognitoIdentityGetIdentityPoolRolesInput new]] continueWithBlock:^id(AWSTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", task.error.domain);
        XCTAssertEqual(8848, task.error.code);
        XCTAssertNil(task.result);
        return nil;
    }] waitUntilFinished];

    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testGetIdentityPoolRolesCompletionHandler {
    NSString *key = @"testGetIdentityPoolRoles";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[[AWSCognitoIdentity CognitoIdentityForKey:key] getIdentityPoolRoles:[AWSCognitoIdentityGetIdentityPoolRolesInput new] completionHandler:^(AWSCognitoIdentityGetIdentityPoolRolesResponse* _Nullable response, NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", error.domain);
        XCTAssertEqual(8848, error.code);
        XCTAssertNil(response);
        dispatch_semaphore_signal(semaphore);
    }];
	
 	dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int)(2.0 * NSEC_PER_SEC)));
    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testGetOpenIdToken {
    NSString *key = @"testGetOpenIdToken";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];
    [[[[AWSCognitoIdentity CognitoIdentityForKey:key] getOpenIdToken:[AWSCognitoIdentityGetOpenIdTokenInput new]] continueWithBlock:^id(AWSTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", task.error.domain);
        XCTAssertEqual(8848, task.error.code);
        XCTAssertNil(task.result);
        return nil;
    }] waitUntilFinished];

    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testGetOpenIdTokenCompletionHandler {
    NSString *key = @"testGetOpenIdToken";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[[AWSCognitoIdentity CognitoIdentityForKey:key] getOpenIdToken:[AWSCognitoIdentityGetOpenIdTokenInput new] completionHandler:^(AWSCognitoIdentityGetOpenIdTokenResponse* _Nullable response, NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", error.domain);
        XCTAssertEqual(8848, error.code);
        XCTAssertNil(response);
        dispatch_semaphore_signal(semaphore);
    }];
	
 	dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int)(2.0 * NSEC_PER_SEC)));
    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testGetOpenIdTokenForDeveloperIdentity {
    NSString *key = @"testGetOpenIdTokenForDeveloperIdentity";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];
    [[[[AWSCognitoIdentity CognitoIdentityForKey:key] getOpenIdTokenForDeveloperIdentity:[AWSCognitoIdentityGetOpenIdTokenForDeveloperIdentityInput new]] continueWithBlock:^id(AWSTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", task.error.domain);
        XCTAssertEqual(8848, task.error.code);
        XCTAssertNil(task.result);
        return nil;
    }] waitUntilFinished];

    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testGetOpenIdTokenForDeveloperIdentityCompletionHandler {
    NSString *key = @"testGetOpenIdTokenForDeveloperIdentity";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[[AWSCognitoIdentity CognitoIdentityForKey:key] getOpenIdTokenForDeveloperIdentity:[AWSCognitoIdentityGetOpenIdTokenForDeveloperIdentityInput new] completionHandler:^(AWSCognitoIdentityGetOpenIdTokenForDeveloperIdentityResponse* _Nullable response, NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", error.domain);
        XCTAssertEqual(8848, error.code);
        XCTAssertNil(response);
        dispatch_semaphore_signal(semaphore);
    }];
	
 	dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int)(2.0 * NSEC_PER_SEC)));
    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testGetPrincipalTagAttributeMap {
    NSString *key = @"testGetPrincipalTagAttributeMap";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];
    [[[[AWSCognitoIdentity CognitoIdentityForKey:key] getPrincipalTagAttributeMap:[AWSCognitoIdentityGetPrincipalTagAttributeMapInput new]] continueWithBlock:^id(AWSTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", task.error.domain);
        XCTAssertEqual(8848, task.error.code);
        XCTAssertNil(task.result);
        return nil;
    }] waitUntilFinished];

    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testGetPrincipalTagAttributeMapCompletionHandler {
    NSString *key = @"testGetPrincipalTagAttributeMap";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[[AWSCognitoIdentity CognitoIdentityForKey:key] getPrincipalTagAttributeMap:[AWSCognitoIdentityGetPrincipalTagAttributeMapInput new] completionHandler:^(AWSCognitoIdentityGetPrincipalTagAttributeMapResponse* _Nullable response, NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", error.domain);
        XCTAssertEqual(8848, error.code);
        XCTAssertNil(response);
        dispatch_semaphore_signal(semaphore);
    }];
	
 	dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int)(2.0 * NSEC_PER_SEC)));
    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testListIdentities {
    NSString *key = @"testListIdentities";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];
    [[[[AWSCognitoIdentity CognitoIdentityForKey:key] listIdentities:[AWSCognitoIdentityListIdentitiesInput new]] continueWithBlock:^id(AWSTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", task.error.domain);
        XCTAssertEqual(8848, task.error.code);
        XCTAssertNil(task.result);
        return nil;
    }] waitUntilFinished];

    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testListIdentitiesCompletionHandler {
    NSString *key = @"testListIdentities";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[[AWSCognitoIdentity CognitoIdentityForKey:key] listIdentities:[AWSCognitoIdentityListIdentitiesInput new] completionHandler:^(AWSCognitoIdentityListIdentitiesResponse* _Nullable response, NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", error.domain);
        XCTAssertEqual(8848, error.code);
        XCTAssertNil(response);
        dispatch_semaphore_signal(semaphore);
    }];
	
 	dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int)(2.0 * NSEC_PER_SEC)));
    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testListIdentityPools {
    NSString *key = @"testListIdentityPools";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];
    [[[[AWSCognitoIdentity CognitoIdentityForKey:key] listIdentityPools:[AWSCognitoIdentityListIdentityPoolsInput new]] continueWithBlock:^id(AWSTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", task.error.domain);
        XCTAssertEqual(8848, task.error.code);
        XCTAssertNil(task.result);
        return nil;
    }] waitUntilFinished];

    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testListIdentityPoolsCompletionHandler {
    NSString *key = @"testListIdentityPools";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[[AWSCognitoIdentity CognitoIdentityForKey:key] listIdentityPools:[AWSCognitoIdentityListIdentityPoolsInput new] completionHandler:^(AWSCognitoIdentityListIdentityPoolsResponse* _Nullable response, NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", error.domain);
        XCTAssertEqual(8848, error.code);
        XCTAssertNil(response);
        dispatch_semaphore_signal(semaphore);
    }];
	
 	dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int)(2.0 * NSEC_PER_SEC)));
    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testListTagsForResource {
    NSString *key = @"testListTagsForResource";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];
    [[[[AWSCognitoIdentity CognitoIdentityForKey:key] listTagsForResource:[AWSCognitoIdentityListTagsForResourceInput new]] continueWithBlock:^id(AWSTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", task.error.domain);
        XCTAssertEqual(8848, task.error.code);
        XCTAssertNil(task.result);
        return nil;
    }] waitUntilFinished];

    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testListTagsForResourceCompletionHandler {
    NSString *key = @"testListTagsForResource";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[[AWSCognitoIdentity CognitoIdentityForKey:key] listTagsForResource:[AWSCognitoIdentityListTagsForResourceInput new] completionHandler:^(AWSCognitoIdentityListTagsForResourceResponse* _Nullable response, NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", error.domain);
        XCTAssertEqual(8848, error.code);
        XCTAssertNil(response);
        dispatch_semaphore_signal(semaphore);
    }];
	
 	dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int)(2.0 * NSEC_PER_SEC)));
    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testLookupDeveloperIdentity {
    NSString *key = @"testLookupDeveloperIdentity";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];
    [[[[AWSCognitoIdentity CognitoIdentityForKey:key] lookupDeveloperIdentity:[AWSCognitoIdentityLookupDeveloperIdentityInput new]] continueWithBlock:^id(AWSTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", task.error.domain);
        XCTAssertEqual(8848, task.error.code);
        XCTAssertNil(task.result);
        return nil;
    }] waitUntilFinished];

    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testLookupDeveloperIdentityCompletionHandler {
    NSString *key = @"testLookupDeveloperIdentity";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[[AWSCognitoIdentity CognitoIdentityForKey:key] lookupDeveloperIdentity:[AWSCognitoIdentityLookupDeveloperIdentityInput new] completionHandler:^(AWSCognitoIdentityLookupDeveloperIdentityResponse* _Nullable response, NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", error.domain);
        XCTAssertEqual(8848, error.code);
        XCTAssertNil(response);
        dispatch_semaphore_signal(semaphore);
    }];
	
 	dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int)(2.0 * NSEC_PER_SEC)));
    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testMergeDeveloperIdentities {
    NSString *key = @"testMergeDeveloperIdentities";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];
    [[[[AWSCognitoIdentity CognitoIdentityForKey:key] mergeDeveloperIdentities:[AWSCognitoIdentityMergeDeveloperIdentitiesInput new]] continueWithBlock:^id(AWSTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", task.error.domain);
        XCTAssertEqual(8848, task.error.code);
        XCTAssertNil(task.result);
        return nil;
    }] waitUntilFinished];

    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testMergeDeveloperIdentitiesCompletionHandler {
    NSString *key = @"testMergeDeveloperIdentities";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[[AWSCognitoIdentity CognitoIdentityForKey:key] mergeDeveloperIdentities:[AWSCognitoIdentityMergeDeveloperIdentitiesInput new] completionHandler:^(AWSCognitoIdentityMergeDeveloperIdentitiesResponse* _Nullable response, NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", error.domain);
        XCTAssertEqual(8848, error.code);
        XCTAssertNil(response);
        dispatch_semaphore_signal(semaphore);
    }];
	
 	dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int)(2.0 * NSEC_PER_SEC)));
    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testSetIdentityPoolRoles {
    NSString *key = @"testSetIdentityPoolRoles";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];
    [[[[AWSCognitoIdentity CognitoIdentityForKey:key] setIdentityPoolRoles:[AWSCognitoIdentitySetIdentityPoolRolesInput new]] continueWithBlock:^id(AWSTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", task.error.domain);
        XCTAssertEqual(8848, task.error.code);
        XCTAssertNil(task.result);
        return nil;
    }] waitUntilFinished];

    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testSetIdentityPoolRolesCompletionHandler {
    NSString *key = @"testSetIdentityPoolRoles";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[[AWSCognitoIdentity CognitoIdentityForKey:key] setIdentityPoolRoles:[AWSCognitoIdentitySetIdentityPoolRolesInput new] completionHandler:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", error.domain);
        XCTAssertEqual(8848, error.code);
        dispatch_semaphore_signal(semaphore);
    }];
	
 	dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int)(2.0 * NSEC_PER_SEC)));
    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testSetPrincipalTagAttributeMap {
    NSString *key = @"testSetPrincipalTagAttributeMap";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];
    [[[[AWSCognitoIdentity CognitoIdentityForKey:key] setPrincipalTagAttributeMap:[AWSCognitoIdentitySetPrincipalTagAttributeMapInput new]] continueWithBlock:^id(AWSTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", task.error.domain);
        XCTAssertEqual(8848, task.error.code);
        XCTAssertNil(task.result);
        return nil;
    }] waitUntilFinished];

    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testSetPrincipalTagAttributeMapCompletionHandler {
    NSString *key = @"testSetPrincipalTagAttributeMap";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[[AWSCognitoIdentity CognitoIdentityForKey:key] setPrincipalTagAttributeMap:[AWSCognitoIdentitySetPrincipalTagAttributeMapInput new] completionHandler:^(AWSCognitoIdentitySetPrincipalTagAttributeMapResponse* _Nullable response, NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", error.domain);
        XCTAssertEqual(8848, error.code);
        XCTAssertNil(response);
        dispatch_semaphore_signal(semaphore);
    }];
	
 	dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int)(2.0 * NSEC_PER_SEC)));
    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testTagResource {
    NSString *key = @"testTagResource";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];
    [[[[AWSCognitoIdentity CognitoIdentityForKey:key] tagResource:[AWSCognitoIdentityTagResourceInput new]] continueWithBlock:^id(AWSTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", task.error.domain);
        XCTAssertEqual(8848, task.error.code);
        XCTAssertNil(task.result);
        return nil;
    }] waitUntilFinished];

    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testTagResourceCompletionHandler {
    NSString *key = @"testTagResource";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[[AWSCognitoIdentity CognitoIdentityForKey:key] tagResource:[AWSCognitoIdentityTagResourceInput new] completionHandler:^(AWSCognitoIdentityTagResourceResponse* _Nullable response, NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", error.domain);
        XCTAssertEqual(8848, error.code);
        XCTAssertNil(response);
        dispatch_semaphore_signal(semaphore);
    }];
	
 	dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int)(2.0 * NSEC_PER_SEC)));
    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testUnlinkDeveloperIdentity {
    NSString *key = @"testUnlinkDeveloperIdentity";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];
    [[[[AWSCognitoIdentity CognitoIdentityForKey:key] unlinkDeveloperIdentity:[AWSCognitoIdentityUnlinkDeveloperIdentityInput new]] continueWithBlock:^id(AWSTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", task.error.domain);
        XCTAssertEqual(8848, task.error.code);
        XCTAssertNil(task.result);
        return nil;
    }] waitUntilFinished];

    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testUnlinkDeveloperIdentityCompletionHandler {
    NSString *key = @"testUnlinkDeveloperIdentity";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[[AWSCognitoIdentity CognitoIdentityForKey:key] unlinkDeveloperIdentity:[AWSCognitoIdentityUnlinkDeveloperIdentityInput new] completionHandler:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", error.domain);
        XCTAssertEqual(8848, error.code);
        dispatch_semaphore_signal(semaphore);
    }];
	
 	dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int)(2.0 * NSEC_PER_SEC)));
    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testUnlinkIdentity {
    NSString *key = @"testUnlinkIdentity";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];
    [[[[AWSCognitoIdentity CognitoIdentityForKey:key] unlinkIdentity:[AWSCognitoIdentityUnlinkIdentityInput new]] continueWithBlock:^id(AWSTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", task.error.domain);
        XCTAssertEqual(8848, task.error.code);
        XCTAssertNil(task.result);
        return nil;
    }] waitUntilFinished];

    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testUnlinkIdentityCompletionHandler {
    NSString *key = @"testUnlinkIdentity";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[[AWSCognitoIdentity CognitoIdentityForKey:key] unlinkIdentity:[AWSCognitoIdentityUnlinkIdentityInput new] completionHandler:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", error.domain);
        XCTAssertEqual(8848, error.code);
        dispatch_semaphore_signal(semaphore);
    }];
	
 	dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int)(2.0 * NSEC_PER_SEC)));
    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testUntagResource {
    NSString *key = @"testUntagResource";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];
    [[[[AWSCognitoIdentity CognitoIdentityForKey:key] untagResource:[AWSCognitoIdentityUntagResourceInput new]] continueWithBlock:^id(AWSTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", task.error.domain);
        XCTAssertEqual(8848, task.error.code);
        XCTAssertNil(task.result);
        return nil;
    }] waitUntilFinished];

    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testUntagResourceCompletionHandler {
    NSString *key = @"testUntagResource";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[[AWSCognitoIdentity CognitoIdentityForKey:key] untagResource:[AWSCognitoIdentityUntagResourceInput new] completionHandler:^(AWSCognitoIdentityUntagResourceResponse* _Nullable response, NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", error.domain);
        XCTAssertEqual(8848, error.code);
        XCTAssertNil(response);
        dispatch_semaphore_signal(semaphore);
    }];
	
 	dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int)(2.0 * NSEC_PER_SEC)));
    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testUpdateIdentityPool {
    NSString *key = @"testUpdateIdentityPool";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];
    [[[[AWSCognitoIdentity CognitoIdentityForKey:key] updateIdentityPool:[AWSCognitoIdentityIdentityPool new]] continueWithBlock:^id(AWSTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", task.error.domain);
        XCTAssertEqual(8848, task.error.code);
        XCTAssertNil(task.result);
        return nil;
    }] waitUntilFinished];

    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

- (void)testUpdateIdentityPoolCompletionHandler {
    NSString *key = @"testUpdateIdentityPool";
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:nil];
    [AWSCognitoIdentity registerCognitoIdentityWithConfiguration:configuration forKey:key];

    AWSCognitoIdentity *awsClient = [AWSCognitoIdentity CognitoIdentityForKey:key];
    XCTAssertNotNil(awsClient);
    XCTAssertNotNil(mockNetworking);
    [awsClient setValue:mockNetworking forKey:@"networking"];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[[AWSCognitoIdentity CognitoIdentityForKey:key] updateIdentityPool:[AWSCognitoIdentityIdentityPool new] completionHandler:^(AWSCognitoIdentityIdentityPool* _Nullable response, NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(@"OCMockExpectedNetworkingError", error.domain);
        XCTAssertEqual(8848, error.code);
        XCTAssertNil(response);
        dispatch_semaphore_signal(semaphore);
    }];
	
 	dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int)(2.0 * NSEC_PER_SEC)));
    OCMVerify([mockNetworking sendRequest:[OCMArg isNotNil]]);

    [AWSCognitoIdentity removeCognitoIdentityForKey:key];
}

@end
