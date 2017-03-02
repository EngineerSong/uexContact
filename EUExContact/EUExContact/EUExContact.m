/**
 *
 *	@file   	: EUExContact.m  in EUExContact
 *
 *	@author 	: CeriNo
 *
 *	@date   	: 2017/2/27
 *
 *	@copyright 	: 2017 The AppCan Open Source Project.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import "EUExContact.h"
#import "PeopleContactViewController.h"
#import <objc/runtime.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <AppCanKit/ACEXTScope.h>

#define AUTH_ERROR (uexErrorMake(1,@"访问通讯录权限受限!"))

#define UexPropertyDefine(__class,__name)\
    property (nonatomic, strong, setter=set__##__name:, getter=__##__name) __class __name;

#define UexPropertySynthesize(__class,__name) \
    dynamic __name;\
    \
    - (__class)metamacro_concat(__,__name){\
        return objc_getAssociatedObject(self,_cmd);\
    }\
    \
    - (void)metamacro_concat(set__,__name):(__class)__name{\
        objc_setAssociatedObject(self, @selector(metamacro_concat(__,__name)), __name, OBJC_ASSOCIATION_RETAIN_NONATOMIC);\
    }

static NSString *const kUexContactPersonInfoNameKey         = @"name";
static NSString *const kUexContactPersonInfoPhoneNumberKey  = @"num";
static NSString *const kUexContactPersonInfoEmailKey        = @"email";
static NSString *const kUexContactPersonInfoAddressKey      = @"address";
static NSString *const kUexContactPersonInfoCompanyKey      = @"company";
static NSString *const kUexContactPersonInfoJobTitleKey     = @"title";
static NSString *const kUexContactPersonInfoNoteKey         = @"note";
static NSString *const kUexContactPersonInfoURLKey          = @"url";
static NSString *const kUexContactPersonInfoContactIDKey    = @"contactId";

typedef void (^uexContactActionBlock)();

typedef NS_OPTIONS(NSInteger, UexContactPersonSearchOptions) {
    UexContactPersonSearchDefault       = 0,
    UexContactPersonSearchEmail         = 1 << 0,
    UexContactPersonSearchPhoneNumber   = 1 << 1,
    UexContactPersonSearchAddress       = 1 << 2,
    UexContactPersonSearchCompany       = 1 << 3,
    UexContactPersonSearchJobTitle      = 1 << 4,
    UexContactPersonSearchNote          = 1 << 5,
    UexContactPersonSearchURL           = 1 << 6,
    UexContactPersonSearchAll           = NSIntegerMax,
};




@interface UIAlertView (uexContact)
@UexPropertyDefine(uexContactActionBlock,uexContact_confirmAction)
@UexPropertyDefine(uexContactActionBlock,uexContact_cancelAction)
@end

@implementation UIAlertView (uexContact)
@UexPropertySynthesize(uexContactActionBlock,uexContact_confirmAction)
@UexPropertySynthesize(uexContactActionBlock,uexContact_cancelAction)
@end
















@interface EUExContact()<UIAlertViewDelegate,ABPeoplePickerNavigationControllerDelegate>
@property(nonatomic,strong)ACJSFunctionRef*fun;

@property (nonatomic,strong)NSString *searchName;
@property (nonatomic,strong)Contact *contact;
@property (nonatomic,strong)NSArray *actionArray;
@property (nonatomic,assign)int32_t recordID;
@property (nonatomic,strong)ACJSFunctionRef *openCallback;
@property (nonatomic,strong)ABPeoplePickerNavigationController *openController;
@end

@implementation EUExContact

#pragma mark - Life Cycle

- (instancetype)initWithWebViewEngine:(id<AppCanWebViewEngineObject>)engine{
    if (self = [super initWithWebViewEngine:engine]) {

    }
    return self;
}

- (void)dealloc {

    _contact = nil;
    _actionArray = nil;

}








#pragma mark - UIAlertViewDelegate


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        if (alertView.uexContact_cancelAction) {
            alertView.uexContact_cancelAction();
        }
    }
    if (buttonIndex == 1) {
        if (alertView.uexContact_confirmAction) {
            alertView.uexContact_confirmAction();
        }
    }
    
    
    
}

#pragma mark - ABPeoplePickerNavigationControllerDelegate

// Called after a person has been selected by the user.
- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController*)peoplePicker didSelectPerson:(ABRecordRef)person{
    
    NSDictionary *result = ABPersonParseWithOptions(person, UexContactPersonSearchAll);
    [peoplePicker dismissViewControllerAnimated:YES completion:^{
        self.openController = nil;
        [self.openCallback executeWithArguments:ACArgsPack(kUexNoError,result)];
        self.openCallback = nil;
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbOpen" arguments:ACArgsPack(@0,@1,result.ac_JSONFragment)];
    }];
    
}

// Called after the user has pressed cancel.
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker{
    [peoplePicker dismissViewControllerAnimated:YES completion:^{
        self.openController = nil;
        [self.openCallback executeWithArguments:ACArgsPack(uexErrorMake(-1,@"用户取消选择"))];
    }];
}




#pragma mark - Private Helper

/// Check Authorization
- (void)checkAuthorizationSuccess:(uexContactActionBlock)success failure:(void (^)(uexContactActionBlock showAlert))failure{
    uexContactActionBlock showAlert = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"当前应用无访问通讯录权限\n 请在 设置->隐私->通讯录 中开启访问权限！" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
        });
    };
    
    void (^completion)(BOOL) = ^(BOOL isAuthorized){
        if (isAuthorized) {
            if (success) {
                success();
            }
        }else{
            if (failure) {
                failure(showAlert);
            }
        }
    };
    
    ABAddressBookRef book = ABAddressBookCreateWithOptions(NULL, NULL);
    ABAuthorizationStatus addressAccessStatus = ABAddressBookGetAuthorizationStatus();
    switch (addressAccessStatus) {
        case kABAuthorizationStatusAuthorized:
            completion(YES);
            break;
        case kABAuthorizationStatusNotDetermined:{
            ABAddressBookRequestAccessWithCompletion(book, ^(bool granted, CFErrorRef error) {
                completion(granted);
            });
        }
            break;
        default:
            completion(NO);
            break;
    }
    if (book) {
        CFRelease(book);
    }
    
    
}

/// Show Alert
- (void)showAlertViewWithMessage:(NSString *)message confirmAction:(uexContactActionBlock)confirmAction cancalAction:(uexContactActionBlock)cancelAction{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:message delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定",nil];
        alert.uexContact_confirmAction = confirmAction;
        alert.uexContact_cancelAction = cancelAction;
        alert.delegate = self;
        [alert show];
    });
}


//


- (UexContactPersonSearchOptions)optionsFromDict:(NSDictionary *)dict{
    __block UexContactPersonSearchOptions options = UexContactPersonSearchDefault;
    NSDictionary<NSString *,NSNumber *> *map = @{
                          @"isSearchNum": @(UexContactPersonSearchPhoneNumber),
                          @"isSearchEmail": @(UexContactPersonSearchEmail),
                          @"isSearchAddress": @(UexContactPersonSearchAddress),
                          @"isSearchCompany": @(UexContactPersonSearchCompany),
                          @"isSearchTitle": @(UexContactPersonSearchJobTitle),
                          @"isSearchNote": @(UexContactPersonSearchNote),
                          @"isSearchUrl":   @(UexContactPersonSearchURL)
                          };
    [map enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        NSNumber *ret = numberArg(dict[key]);
        if (!ret || ret.boolValue) {
            options |= obj.integerValue;
        }
    }];
    
    return options;
    
}



#pragma mark - AddressBook Utility

/// Parse ABRecordRef
static NSDictionary *ABPersonParseWithOptions(ABRecordRef person,UexContactPersonSearchOptions options){
    
    
    
    //ABMultiValueRef parser
    NSString * _Nullable(^multiValueParser)(ABPropertyID) = ^NSString * _Nullable(ABPropertyID property){
        ABMultiValueRef multiValue = ABRecordCopyValue(person, property);
        NSString *result = nil;
        if (multiValue) {
            if (ABMultiValueGetCount(multiValue) > 0) {
                result = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(multiValue, 0);
            }
            CFRelease(multiValue);
        }
        return result;
        
    };
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [dict setValue:(__bridge_transfer NSString *)ABRecordCopyCompositeName(person) forKey:kUexContactPersonInfoNameKey];
    [dict setValue:@(ABRecordGetRecordID(person)).stringValue forKey:kUexContactPersonInfoContactIDKey];
    
    if (options & UexContactPersonSearchPhoneNumber) {
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
        if (phoneNumbers) {
            [dict setValue:(__bridge_transfer NSArray *)ABMultiValueCopyArrayOfAllValues(phoneNumbers) forKey:kUexContactPersonInfoPhoneNumberKey];
            CFRelease(phoneNumbers);
        }
    }
    if (options & UexContactPersonSearchEmail) {
        [dict setValue:multiValueParser(kABPersonEmailProperty) forKey:kUexContactPersonInfoEmailKey];
    }
    if (options & UexContactPersonSearchAddress) {
        [dict setValue:multiValueParser(kABPersonAddressProperty) forKey:kUexContactPersonInfoAddressKey];
    }
    if (options & UexContactPersonSearchCompany) {
        [dict setValue:(__bridge_transfer NSString *)ABRecordCopyValue(person,kABPersonOrganizationProperty) forKey:kUexContactPersonInfoCompanyKey];
    }
    if (options & UexContactPersonSearchJobTitle) {
        [dict setValue:(__bridge_transfer NSString *)ABRecordCopyValue(person,kABPersonJobTitleProperty) forKey:kUexContactPersonInfoJobTitleKey];
    }
    if (options & UexContactPersonSearchURL) {
        [dict setValue:multiValueParser(kABPersonURLProperty) forKey:kUexContactPersonInfoURLKey];
    }
    if (options & UexContactPersonSearchNote) {
        [dict setValue:(__bridge_transfer NSString *)ABRecordCopyValue(person,kABPersonNoteProperty) forKey:kUexContactPersonInfoNoteKey];
    }
    return [dict copy];
};

///Set Item

static BOOL ABPersonSetPhoneNumber(ABRecordRef person,NSString *phoneNumberString){
    NSArray *numbers = [phoneNumberString componentsSeparatedByString:@";"];
    ABMutableMultiValueRef numberRef = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    if (!numberRef) {
        return NO;
    }
    @onExit{
        CFRelease(numberRef);
    };
    
    ABMultiValueIdentifier identidier;
    for(NSInteger i = 0; i < numbers.count; i++){
        switch (i) {
            case 0:
                ABMultiValueAddValueAndLabel(numberRef, (__bridge CFStringRef)numbers[i], kABPersonPhoneMainLabel, &identidier);
                break;
            case 1:
                ABMultiValueAddValueAndLabel(numberRef, (__bridge CFStringRef)numbers[i], kABPersonPhoneMobileLabel, &identidier);
                break;
            default:
                ABMultiValueAddValueAndLabel(numberRef, (__bridge CFStringRef)numbers[i], kABPersonPhoneHomeFAXLabel, &identidier);
                break;
        }
    }
    return ABRecordSetValue(person, kABPersonPhoneProperty, numberRef, NULL);
}


static BOOL ABPersonSetEmail(ABRecordRef person,NSString *email){

    ABMutableMultiValueRef emailRef = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    if (!emailRef) {
        return NO;
    }
    @onExit{
        CFRelease(emailRef);
    };
    ABMultiValueAddValueAndLabel(emailRef, (__bridge CFStringRef)email, kABOtherLabel, NULL);
    return ABRecordSetValue(person, kABPersonEmailProperty, emailRef, NULL);
}

/*
static BOOL ABPersonSetAddress(ABRecordRef person,NSString *address){
    
    ABMutableMultiValueRef addressRef = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    if (!addressRef) {
        return NO;
    }
    @onExit{
        CFRelease(addressRef);
    };
    ABMultiValueAddValueAndLabel(addressRef, (__bridge CFStringRef)address, kABWorkLabel, NULL);
    return ABRecordSetValue(person, kABPersonAddressProperty, addressRef, NULL);
}


static BOOL ABPersonSetURL(ABRecordRef person,NSString *url){
    
    ABMutableMultiValueRef urlRef = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    if (!urlRef) {
        return NO;
    }
    @onExit{
        CFRelease(urlRef);
    };
    ABMultiValueAddValueAndLabel(urlRef, (__bridge CFStringRef)url, kABPersonHomePageLabel, NULL);
    return ABRecordSetValue(person, kABPersonURLProperty, urlRef, NULL);
}

static BOOL ABPersonSetCompany(ABRecordRef person,NSString *company){
    return ABRecordSetValue(person, kABPersonOrganizationProperty, (__bridge CFStringRef)company, NULL);
}

static BOOL ABPersonSetJobTitle(ABRecordRef person,NSString *jobTitle){
    return ABRecordSetValue(person, kABPersonJobTitleProperty, (__bridge CFStringRef)jobTitle, NULL);
}
static BOOL ABPersonSetNote(ABRecordRef person,NSString *note){
    return ABRecordSetValue(person, kABPersonNoteProperty, (__bridge CFStringRef)note, NULL);
}





*/


#pragma mark - Public API

- (void)open:(NSMutableArray *)inArguments {
    
    ACArgsUnpack(ACJSFunctionRef *callback) = inArguments;
    UEX_PARAM_GUARD_NOT_NIL(callback);
    [self checkAuthorizationSuccess:^{
        self.openCallback = callback;
        if (!self.openController) {
            self.openController = [[ABPeoplePickerNavigationController alloc] init];
            self.openController.peoplePickerDelegate = self;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self.webViewEngine viewController] presentViewController:self.openController animated:YES completion:nil];
        });
    } failure:^(uexContactActionBlock showAlert) {
        [callback executeWithArguments:ACArgsPack(AUTH_ERROR)];
        showAlert();
    }];
    
    

}











- (void)addItem:(NSMutableArray *)inArguments {
    ACArgsUnpack(NSString *name,NSString *phoneNumber,NSString *email,NSDictionary *options) = inArguments;
    ACJSFunctionRef *callback = JSFunctionArg(inArguments.lastObject);
    UEX_PARAM_GUARD_NOT_NIL(name);
    BOOL isNeedShowAlert = numberArg(options[@"isNeedAlertDialog"]).boolValue;
    void (^execCallback)(UEX_ERROR) = ^(UEX_ERROR error){
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbAddItem" arguments:ACArgsPack(@0,@2,(error.integerValue == 0) ? @0 : @1)];
        [callback executeWithArguments:ACArgsPack(error)];
    };
    
    uexContactActionBlock addItem = ^{
        __block BOOL ret = NO;
        @onExit{
            execCallback(ret ? kUexNoError : uexErrorMake(1));
        };
        
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        if (!addressBook) {
            return;
        }
        ABRecordRef person = ABPersonCreate();
        ABRecordSetValue(person, kABPersonFirstNameProperty, (__bridge CFStringRef)name, NULL);
        ABPersonSetPhoneNumber(person, phoneNumber);
        ABPersonSetEmail(person, email);
        ret = ABAddressBookAddRecord(addressBook, person, NULL) && ABAddressBookSave(addressBook, NULL);
        CFRelease(person);
        CFRelease(addressBook);
    };
    
    [self checkAuthorizationSuccess:^{
        if (isNeedShowAlert) {
            [self showAlertViewWithMessage:@"应用程序需要添加联系人信息，是否确认添加？" confirmAction:addItem cancalAction:^{
                execCallback(uexErrorMake(-1));
            }];
        }else{
            addItem();
        }

    } failure:^(uexContactActionBlock showAlert) {
        execCallback(uexErrorMake(1));
        showAlert();
    }];
    

}

- (void)addItemWithVCard:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSString *vCardStr,NSNumber *type) = inArguments;
    ACJSFunctionRef *callback = JSFunctionArg(inArguments.lastObject);
    BOOL isNeedShowAlert = type.integerValue != 1;
    void (^execCallback)(UEX_ERROR) = ^(UEX_ERROR error){
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbAddItem" arguments:ACArgsPack(@0,@2,(error.integerValue == 0) ? @0 : @1)];
        [callback executeWithArguments:ACArgsPack(error)];
    };
    uexContactActionBlock addItem = ^{
        __block BOOL ret = NO;
        @onExit{
            execCallback(ret ? kUexNoError : uexErrorMake(1));
        };
        
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        if (!addressBook) {
            return;
        }
        
        CFDataRef vCardData = (__bridge CFDataRef)[vCardStr dataUsingEncoding:NSUTF8StringEncoding];
        ABRecordRef defaultSource = ABAddressBookCopyDefaultSource(addressBook);
        CFArrayRef vCardPeople = ABPersonCreatePeopleInSourceWithVCardRepresentation(defaultSource, vCardData);
        for (CFIndex index = 0; index < CFArrayGetCount(vCardPeople); index++) {
            ABRecordRef person = CFArrayGetValueAtIndex(vCardPeople, index);
            ABAddressBookAddRecord(addressBook, person, NULL);
            CFRelease(person);
        }
        ret = ABAddressBookSave(addressBook, NULL);
        CFRelease(addressBook);
    };
    
    [self checkAuthorizationSuccess:^{
        if (isNeedShowAlert) {
            [self showAlertViewWithMessage:@"应用程序需要添加联系人信息，是否确认添加？" confirmAction:addItem cancalAction:^{
                execCallback(uexErrorMake(-1));
            }];
        }else{
            addItem();
        }
        
    } failure:^(uexContactActionBlock showAlert) {
        execCallback(uexErrorMake(1));
        showAlert();
    }];
}


- (void)deleteItem:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSString *name,ACJSFunctionRef *callback) = inArguments;
    
    void (^execCallback)(UEX_ERROR) = ^(UEX_ERROR error){
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbDeleteItem" arguments:ACArgsPack(@0,@2,(error.integerValue == 0) ? @0 : @1)];
        [callback executeWithArguments:ACArgsPack(error)];
    };
    uexContactActionBlock deleteItem = ^{
        __block BOOL ret = NO;
        @onExit{
            execCallback(ret ? kUexNoError : uexErrorMake(1));
        };
        
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        if (!addressBook) {
            return;
        }
        CFArrayRef people = ABAddressBookCopyPeopleWithName(addressBook,(__bridge CFStringRef)name);
        if (CFArrayGetCount(people) > 0) {
            ABRecordRef person = CFArrayGetValueAtIndex(people, 0);
            ret = ABAddressBookRemoveRecord(addressBook, person, NULL) && ABAddressBookSave(addressBook, NULL);
        }
        CFRelease(people);
        CFRelease(addressBook);
    };
    
    [self checkAuthorizationSuccess:^{
            [self showAlertViewWithMessage:@"应用程序需要删除联系人信息，是否确认删除？" confirmAction:deleteItem cancalAction:^{
                execCallback(uexErrorMake(-1));
            }];

    } failure:^(uexContactActionBlock showAlert) {
        execCallback(uexErrorMake(1));
        showAlert();
    }];

}

- (void)deleteWithId:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *callback) = inArguments;
    NSString *contactId = stringArg(info[@"contactId"]);
    UEX_PARAM_GUARD_NOT_NIL(contactId);
    
    void (^execCallback)(UEX_ERROR) = ^(UEX_ERROR error){
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbDeleteItem" arguments:ACArgsPack(@0,@2,(error.integerValue == 0) ? @0 : @1)];
        [callback executeWithArguments:ACArgsPack(error)];
    };
    uexContactActionBlock deleteItem = ^{
        __block BOOL ret = NO;
        @onExit{
            execCallback(ret ? kUexNoError : uexErrorMake(1));
        };
        
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        if (!addressBook) {
            return;
        }
        ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook, contactId.intValue);
        ret = ABAddressBookRemoveRecord(addressBook, person, NULL) && ABAddressBookSave(addressBook, NULL);
        CFRelease(addressBook);
    };
    
    [self checkAuthorizationSuccess:^{
        [self showAlertViewWithMessage:@"应用程序需要删除联系人信息，是否确认删除？" confirmAction:deleteItem cancalAction:^{
            execCallback(uexErrorMake(-1));
        }];
        
    } failure:^(uexContactActionBlock showAlert) {
        execCallback(uexErrorMake(1));
        showAlert();
    }];

}


- (void)searchItem:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSString *name,NSDictionary *info) = inArguments;
    ACJSFunctionRef *callback = JSFunctionArg(inArguments.lastObject);
    
    void (^execCallback)(UEX_ERROR,NSArray *) = ^(UEX_ERROR error, NSArray *result){
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbSearchItem" arguments:ACArgsPack(@0,@1,(error.integerValue == 0) ? result.ac_JSONFragment : @"")];
        [callback executeWithArguments:ACArgsPack(error,result)];
    };
    uexContactActionBlock searchItem = ^{
        __block UEX_ERROR error = kUexNoError;
        NSMutableArray *result = [NSMutableArray array];
        @onExit{
            execCallback(error,result);
        };
        
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        if (!addressBook) {
            error = uexErrorMake(1);
            return;
        }
        NSInteger count = [numberArg(info[@"resultNum"]) integerValue];
        count = count > 0 ? count : 50;
        CFArrayRef items;
        if (name.length > 0) {
            items = ABAddressBookCopyPeopleWithName(addressBook, (__bridge CFStringRef)name);
        }else{
            items = ABAddressBookCopyArrayOfAllPeople(addressBook);
        }
        count = MIN(count, CFArrayGetCount(items));
        UexContactPersonSearchOptions options = [self optionsFromDict:info];
        for (NSInteger i = 0; i < count; i++) {
            ABRecordRef person = CFArrayGetValueAtIndex(items, i);
            [result addObject:ABPersonParseWithOptions(person, options)];
        }
        CFRelease(items);
        CFRelease(addressBook);
    };
    
    [self checkAuthorizationSuccess:searchItem
                            failure:^(uexContactActionBlock showAlert) {
        execCallback(uexErrorMake(1),nil);
        showAlert();
    }];
    
}

- (void)search:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info) = inArguments;
    ACJSFunctionRef *callback = JSFunctionArg(inArguments.lastObject);
    
    void (^execCallback)(UEX_ERROR,NSArray *) = ^(UEX_ERROR error, NSArray *result){
        NSMutableDictionary *cbSearch = [NSMutableDictionary dictionary];
        [cbSearch setValue:error forKey:@"result"];
        [cbSearch setValue:result forKey:@"contactList"];
        
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbSearch" arguments:ACArgsPack(cbSearch.ac_JSONFragment)];
        [callback executeWithArguments:ACArgsPack(error,result)];
    };
    uexContactActionBlock searchItem = ^{
        __block UEX_ERROR error = kUexNoError;
        NSMutableArray *result = [NSMutableArray array];
        @onExit{
            execCallback(error,result);
        };
        
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        if (!addressBook) {
            error = uexErrorMake(1);
            return;
        }
        @onExit{
            CFRelease(addressBook);
        };
        
        NSString *contactId = stringArg(info[@"contactId"]);
        NSString *name = stringArg(info[@"searchName"]);
        UexContactPersonSearchOptions options = [self optionsFromDict:info];
        NSInteger count = [numberArg(info[@"resultNum"]) integerValue];
        count = count > 0 ? count : 50;
        
        if (contactId.length > 0) {
            ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook, contactId.intValue);
            if (person) {
                [result addObject:ABPersonParseWithOptions(person, options)];
            }
            return;
        }
        
        
        CFArrayRef items;
        if (name.length > 0) {
            items = ABAddressBookCopyPeopleWithName(items, (__bridge CFStringRef)name);
        }else{
            items = ABAddressBookCopyArrayOfAllPeople(addressBook);
        }
        count = MIN(count, CFArrayGetCount(items));
        
        for (NSInteger i = 0; i < count; i++) {
            ABRecordRef person = CFArrayGetValueAtIndex(items, i);
            [result addObject:ABPersonParseWithOptions(person, options)];
        }
        CFRelease(items);
        
    };
    
    [self checkAuthorizationSuccess:searchItem
                            failure:^(uexContactActionBlock showAlert) {
                                execCallback(uexErrorMake(1),nil);
                                showAlert();
                            }];
}



- (void)modifyWithId:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info,ACJSFunctionRef *callback) = inArguments;
    NSString *contactId = stringArg(info[@"contactId"]);
    UEX_PARAM_GUARD_NOT_NIL(contactId);
    
    void (^execCallback)(UEX_ERROR) = ^(UEX_ERROR error){
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbModifyWithId" arguments:ACArgsPack(@0,@2,(error.integerValue == 0) ? @0 : @1)];
        [callback executeWithArguments:ACArgsPack(error)];
    };
    uexContactActionBlock modifyItem = ^{
        __block BOOL ret = NO;
        @onExit{
            execCallback(ret ? kUexNoError : uexErrorMake(1));
        };
        
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        if (!addressBook) {
            return;
        }
        ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook, contactId.intValue);
        if (!person) {
            return;
        }
        NSString *name = stringArg(info[@"name"]);
        NSString *phoneNumber = stringArg(info[@"number"]);
        NSString *email = stringArg(info[@"email"]);
        
        ABRecordSetValue(person, kABPersonFirstNameProperty, (__bridge CFStringRef)name, NULL);
        ABPersonSetPhoneNumber(person, phoneNumber);
        ABPersonSetEmail(person, email);
        ret = ABAddressBookAddRecord(addressBook, person, NULL) && ABAddressBookSave(addressBook, NULL);
        CFRelease(addressBook);
    };
    
    [self checkAuthorizationSuccess:^{
        [self showAlertViewWithMessage:@"应用程序需要修改联系人信息，是否确认修改？" confirmAction:modifyItem cancalAction:^{
            execCallback(uexErrorMake(-1));
        }];
        
    } failure:^(uexContactActionBlock showAlert) {
        execCallback(uexErrorMake(1));
        showAlert();
    }];
}


- (void)modifyItem:(NSMutableArray *)inArguments{

    ACArgsUnpack(NSString *name,NSString *phoneNumber,NSString *email) = inArguments;
    ACJSFunctionRef *callback = JSFunctionArg(inArguments.lastObject);

    UEX_PARAM_GUARD_NOT_NIL(name);
    
    void (^execCallback)(UEX_ERROR) = ^(UEX_ERROR error){
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbModifyItem" arguments:ACArgsPack(@0,@2,(error.integerValue == 0) ? @0 : @1)];
        [callback executeWithArguments:ACArgsPack(error)];
    };
    uexContactActionBlock modifyItem = ^{
        __block BOOL ret = NO;
        @onExit{
            execCallback(ret ? kUexNoError : uexErrorMake(1));
        };
        
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        if (!addressBook) {
            return;
        }

        
        CFArrayRef items = ABAddressBookCopyPeopleWithName(addressBook, (__bridge CFStringRef)name);
        if (!items || CFArrayGetCount(items) == 0) {
            return;
        }
        ABRecordRef person = CFArrayGetValueAtIndex(items, 0);
        ABPersonSetPhoneNumber(person, phoneNumber);
        ABPersonSetEmail(person, email);
        ret = ABAddressBookAddRecord(addressBook, person, NULL) && ABAddressBookSave(addressBook, NULL);
        CFRelease(addressBook);
    };
    
    [self checkAuthorizationSuccess:^{
        [self showAlertViewWithMessage:@"应用程序需要修改联系人信息，是否确认修改？" confirmAction:modifyItem cancalAction:^{
            execCallback(uexErrorMake(-1));
        }];
        
    } failure:^(uexContactActionBlock showAlert) {
        execCallback(uexErrorMake(1));
        showAlert();
    }];
}

- (void)modifyMultiItem:(NSMutableArray *)inArguments{
    ACLogError(@"uexContact.modifyMultiItem() is obsoleted!");
}


- (void)multiOpen:(NSMutableArray*)inArguments{
    ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
    
    [self checkAuthorizationSuccess:^{
        PeopleContactViewController *contactView = [[PeopleContactViewController alloc] init];
        contactView.callBack = self;
        contactView.func = func;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:contactView];
        [[self.webViewEngine viewController] presentViewController:nav animated:YES completion:nil];

    } failure:^(uexContactActionBlock showAlert) {
        showAlert();
    }];

}

 
@end
