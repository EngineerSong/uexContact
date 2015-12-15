//
//  Contact.h
//  AppCan
//
//  Created by AppCan on 11-9-7.
//  Copyright 2011 AppCan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBookUI/AddressBookUI.h>


@class EUExContact;

@interface Contact : NSObject <ABPeoplePickerNavigationControllerDelegate>{
	ABPeoplePickerNavigationController *_peoplePicker;
	EUExContact * euexObj;
	NSMutableDictionary * resultDict;
	
}
-(void)openItemWithUEx:(EUExContact *)euexObj_;
-(BOOL)addItem:(NSString *)name phoneNum:(NSString *)num  phoneEmail:(NSString *)email;
-(BOOL)addItemWithVCard:(NSString *)vcCardStr;
-(BOOL)deleteItem:(NSString *)inName;
-(NSMutableArray *)searchItem_all;
-(NSString *)searchItem:(NSString *)inName resultNum:(NSInteger)resultNum;
-(BOOL)modifyItem:(NSString *)inName phoneNum: (NSString *)inNum phoneEmail:(NSString *) ineMail;
-(BOOL )modifyMulti:(NSMutableArray *)inArguments;
@end
