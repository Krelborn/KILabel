/***********************************************************************************
 *
 * The MIT License (MIT)
 *
 * Copyright (c) 2013 Matthew Styles
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 ***********************************************************************************/

#import <XCTest/XCTest.h>

#import "KILabel.h"


@interface KILabelClassifierTests : XCTestCase
{
    KILabel *label;
}
@end

@implementation KILabelClassifierTests

- (void)setUp
{
    [super setUp];

    label = [[KILabel alloc] initWithFrame:CGRectMake(0, 0, 256, 23)];
}

- (void)tearDown
{
    label = nil;
    
    [super tearDown];
}

- (void)testLinkClassifierWithTag_tagIs0_returnsNil
{
    KILabelLinkClassifier *classifier = [label linkClassifierWithTag:0];
    XCTAssertNil(classifier);
}

- (void)testLinkClassifierWithTag_tagIs0_returnsClassifier
{
    KILabelLinkClassifier *classifier = [[KILabelLinkClassifier alloc] init];
    [label addLinkClassifier:classifier];
    XCTAssertEqual([label linkClassifierWithTag:0], classifier);
}

- (void)testLinkClassifierWithTag_tagIs0_classifierHasTag1_returnsNil
{
    KILabelLinkClassifier *classifier = [[KILabelLinkClassifier alloc] init];
    [label addLinkClassifier:classifier];
    XCTAssertNil([label linkClassifierWithTag:1]);
}

- (void)testLinkClassifierWithTag_tagIs1_classifierHasTag1AddedThenRemoved_returnsNil
{
    KILabelLinkClassifier *classifier = [[KILabelLinkClassifier alloc] init];
    classifier.tag = 1;
    [label addLinkClassifier:classifier];
    XCTAssertEqual([label linkClassifierWithTag:1], classifier);
    
    [label removeLinkClassifier:classifier];
    XCTAssertNil([label linkClassifierWithTag:1]);
}


@end
