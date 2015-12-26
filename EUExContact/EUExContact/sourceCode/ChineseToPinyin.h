//
//  ChineseToPinyin.h
//  AppCan
//
//  Created by AppCan on 12-5-30.
//  Copyright 2012 AppCan. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString(ChinesePinyin)

-(NSString *) ChinesePinyin;
- (char) ChinesePinyinHeadLetter;
@end
