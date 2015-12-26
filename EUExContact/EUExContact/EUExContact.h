//
//  EUEXContact.h
//  AppCan
//
//  Created by AppCan on 11-9-20.
//  Copyright 2011 AppCan. All rights reserved.
//

#import "EUExBase.h"
@class Contact;

#define UEX_JKNAME			@"name"
#define UEX_JKNUM			@"num"
#define UEX_JKEMAIL			@"email"

//add
#define UEX_JKADR			@"address"
#define UEX_JKORG			@"company"
#define UEX_JKTITLE			@"title"
#define UEX_JKURL			@"url"
#define UEX_JKNOTE			@"note"

@interface EUExContact : EUExBase <UIAlertViewDelegate>{
	Contact * contact;
	NSArray * actionArray;
}
-(void)uexOpenSuccessWithOpId:(int)inOpId dataType:(int)inDataType data:(NSString *)inData;
@end
