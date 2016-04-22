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
@property (nonatomic, strong) NSString  *isSearchEmail;
@property (nonatomic, strong) NSString  *isSearchNum;
@property (nonatomic, strong) NSString  *isSearchAddress;
@property (nonatomic, strong) NSString  *isSearchCompany;
@property (nonatomic, strong) NSString  *isSearchTitle;
@property (nonatomic, strong) NSString  *isSearchNote;
@property (nonatomic, strong) NSString  *isSearchUrl;
-(void)openItemWithUEx:(EUExContact *)euexObj_;
-(BOOL)addItem:(NSString *)name phoneNum:(NSString *)num  phoneEmail:(NSString *)email;
-(BOOL)addItemWithVCard:(NSString *)vcCardStr;
-(BOOL)deleteItem:(NSString *)inName;
-(BOOL)deleteItemWithId:(int)ids;
-(NSMutableArray *)searchItem_all;
-(NSString *)searchItem:(NSString *)inName resultNum:(NSInteger)resultNum;
-(NSString *)search:(int)ids;
-(BOOL)modifyItem:(NSString *)inName phoneNum: (NSString *)inNum phoneEmail:(NSString *) ineMail;
-(BOOL)modifyItemWithId:(int)ids  Name:(NSString *)inName phoneNum: (NSString *)inNum phoneEmail:(NSString *) ineMail;
-(BOOL )modifyMulti:(NSMutableArray *)inArguments;
@end
