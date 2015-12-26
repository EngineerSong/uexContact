//
//  Contact.m
//  WebKitCorePlam
//
//  Created by AppCan on 11-9-7.
//  Copyright 2011 AppCan. All rights reserved.
//

#import "Contact.h"
#import "EUExContact.h"
#import "JSON.h"
#import "EUtility.h"
#import "EUExBaseDefine.h"

@implementation Contact
// Called after a value has been selected by the user.
// Return YES if you want default action to be performed.
// Return NO to do nothing (the delegate is responsible for dismissing the peoplePicker).
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier{
    return YES;
}

//设置返回字典数据
-(void)setDataDict:(ABRecordRef)person withInDict:(NSMutableDictionary*)dict{
    //姓名
    NSString *nameStr = (NSString *)ABRecordCopyCompositeName(person);
    if (nameStr) {
        [nameStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [dict setObject:nameStr forKey:UEX_JKNAME];
    }
    [nameStr release];
    //电话
    ABMultiValueRef phone = (ABMultiValueRef)ABRecordCopyValue(person, kABPersonPhoneProperty);
    NSString *personPhone = nil;
    NSArray *phoneArray = nil;
    if (ABMultiValueGetCount(phone) > 0) {
        personPhone = (NSString*)ABMultiValueCopyValueAtIndex(phone,0);
        phoneArray = (NSArray *)ABMultiValueCopyArrayOfAllValues(phone);
    }
    CFRelease(phone);
    if (personPhone) {
        [dict setObject:personPhone forKey:UEX_JKNUM];
        [dict setObject:phoneArray forKey:UEX_JKNUM];
        
    }else {
        [dict setObject:@"" forKey:UEX_JKNUM];
    }
    [personPhone release];
    //email
    ABMultiValueRef emails = (ABMultiValueRef)ABRecordCopyValue(person, kABPersonEmailProperty);
    NSString * emailStr = nil;
    if (ABMultiValueGetCount(emails) > 0) {
        emailStr = (NSString*)ABMultiValueCopyValueAtIndex(emails, 0);
    }
    CFRelease(emails);
    if (emailStr != nil) {
        [dict setObject:emailStr forKey:UEX_JKEMAIL];
    }else {
        [dict setObject:@"" forKey:UEX_JKEMAIL];
    }
    [emailStr release];
    //address
    ABMultiValueRef addresses = (ABMultiValueRef)ABRecordCopyValue(person, kABPersonAddressProperty);
    NSDictionary *addressDict = nil;
    if (ABMultiValueGetCount(addresses)>0) {
        addressDict = (NSDictionary*)ABMultiValueCopyValueAtIndex(addresses, 0);
    }
    CFRelease(addresses);
    if (addressDict != nil) {
        [dict setObject:addressDict forKey:UEX_JKADR];
    }else {
        [dict setObject:@"" forKey:UEX_JKADR];
    }
    [addressDict release];
    //company
    NSString *companyStr = (NSString*)ABRecordCopyValue(person, kABPersonOrganizationProperty);
    if (companyStr != nil) {
        [dict setObject:companyStr forKey:UEX_JKORG];
    }else {
        [dict setObject:@"" forKey:UEX_JKORG];
    }
    [companyStr release];
    //title
    NSString * titleStr = (NSString*)ABRecordCopyValue(person, kABPersonJobTitleProperty);
    if (titleStr != nil) {
        [dict setObject:titleStr forKey:UEX_JKTITLE];
    }else {
        [dict setObject:@"" forKey:UEX_JKTITLE];
    }
    [titleStr release];
    //url
    ABMultiValueRef urls = (ABMultiValueRef)ABRecordCopyValue(person, kABPersonURLProperty);
    NSString * urlStr = nil;
    if (ABMultiValueGetCount(urls) > 0) {
        urlStr = (NSString*)ABMultiValueCopyValueAtIndex(urls, 0);
    }
    CFRelease(urls);
    if (urlStr != nil) {
        [dict setObject:urlStr forKey:UEX_JKURL];
    } else {
        [dict setObject:@"" forKey:UEX_JKURL];
    }
    [urlStr release];
    
    //note
    NSString * noteStr = (NSString*)ABRecordCopyValue(person, kABPersonNoteProperty);
    if (noteStr != nil) {
        [dict setObject:noteStr forKey:UEX_JKNOTE];
    }else {
        [dict setObject:@"" forKey:UEX_JKNOTE];
    }
    [noteStr release];
}
//iOS8--
-(BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
    //返回数据
    [self setDataDict:person withInDict:dict];
    
    NSString *JSONStr = [dict JSONFragment];
    [euexObj uexOpenSuccessWithOpId:0 dataType:UEX_CALLBACK_DATATYPE_JSON data:JSONStr];
    [peoplePicker dismissModalViewControllerAnimated:YES];
    return NO;
}
//iOS8++
- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController*)peoplePicker didSelectPerson:(ABRecordRef)person{
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
    //返回数据
    [self setDataDict:person withInDict:dict];
    NSString *JSONStr = [dict JSONFragment];
    [euexObj uexOpenSuccessWithOpId:0 dataType:UEX_CALLBACK_DATATYPE_JSON data:JSONStr];
    [peoplePicker dismissModalViewControllerAnimated:YES];
}

-(void)openItemWithUEx:(EUExContact *)euexObj_ {
    euexObj = euexObj_;
    if (!_peoplePicker) {
        _peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
        _peoplePicker.peoplePickerDelegate = self;
    }
    [EUtility brwView:euexObj.meBrwView presentModalViewController:(UIViewController *)_peoplePicker animated:YES];
    
}

-(BOOL)addPhone:(ABRecordRef)person phone:(NSString*)phone
{
    NSArray *numArray = [phone componentsSeparatedByString:@";"];
    
    ABMutableMultiValueRef multi = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    CFErrorRef anError = NULL;
    ABMultiValueIdentifier multivalueIdentifier;
    
    if (numArray != nil && [numArray count] > 1) {
        for(NSInteger i = 0;i <numArray.count  ;i++){
            if (i==0) {
                ABMultiValueAddValueAndLabel(multi, (CFStringRef)[numArray objectAtIndex:i], kABPersonPhoneMainLabel, &multivalueIdentifier);
            }else if(i == 1){
                ABMultiValueAddValueAndLabel(multi, (CFStringRef)[numArray objectAtIndex:i], kABPersonPhoneMobileLabel, &multivalueIdentifier);
            }else{
                ABMultiValueAddValueAndLabel(multi, (CFStringRef)[numArray objectAtIndex:i], kABPersonPhoneHomeFAXLabel, &multivalueIdentifier);
            }
        }
    }else{
        ABMultiValueAddValueAndLabel(multi, (CFStringRef)phone, kABPersonPhoneMainLabel, &multivalueIdentifier);
    }
    
    //    if (!ABMultiValueAddValueAndLabel(multi, (CFStringRef)phone, kABPersonPhoneMainLabel, &multivalueIdentifier)){
    //        CFRelease(multi);
    //        return NO;
    //    }
    
    if (!ABRecordSetValue(person, kABPersonPhoneProperty, multi, &anError)){
        CFRelease(multi);
        return NO;
    }
    
    CFRelease(multi);
    return YES;
}

-(BOOL)addEmail:(ABRecordRef)person email:(NSString*)email
{
    ABMultiValueRef multi = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    CFErrorRef anError = NULL;
    ABMultiValueAddValueAndLabel(multi,email,kABOtherLabel,NULL);
    if (!ABRecordSetValue(person, kABPersonEmailProperty, multi, &anError)){
        CFRelease(multi);
        return NO;
    }
    CFRelease(multi);
    return YES;
}

/******************************************************************************************
 ADR 类型定义
 目的：是一个组合，用来表示一个地址信息，值类型是一个用分号分开的文本值
 例子：ADR;TYPE=dom,home,postal,parcel:;;123 Main Street;Any Town;CA;91921-1234;A
 ADR;HOME;POSTAL;PARCEL:;;街道地址;深圳;广东;444444;中国
 组合由一下部分顺序的组成：
 the post office box;
 the extended address;
 the street address;
 the locality (e.g., city);
 the region (e.g., state or province);
 the postal code;
 the country name
 七个部分组成，如果，其他的一个部分没有，必须用分号分开
 ******************************************************************************************/
-(BOOL)addAddress:(ABRecordRef)person address:(NSDictionary*)address
{
    ABMultiValueRef multi = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    CFErrorRef anError = NULL;
    ABMultiValueAddValueAndLabel(multi,address,kABWorkLabel,NULL);
    if (!ABRecordSetValue(person, kABPersonAddressProperty, multi, &anError)){
        CFRelease(multi);
        return NO;
    }
    CFRelease(multi);
    return YES;
}

-(BOOL)addCompany:(ABRecordRef)person company:(NSString*)company
{
    CFErrorRef error = NULL;
    BOOL success = ABRecordSetValue(person, kABPersonOrganizationProperty, company, &error);
    if (!success) {
        //
    }
    return success;
}

-(BOOL)addTitle:(ABRecordRef)person title:(NSString*)title
{
    CFErrorRef error = NULL;
    BOOL success = ABRecordSetValue(person, kABPersonJobTitleProperty, title, &error);
    if (!success) {
        //
    }
    return success;
}

-(BOOL)addURL:(ABRecordRef)person url:(NSString*)url
{
    ABMultiValueRef multi = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    CFErrorRef anError = NULL;
    ABMultiValueAddValueAndLabel(multi,url,kABPersonHomePageLabel,NULL);
    if (!ABRecordSetValue(person, kABPersonURLProperty, multi, &anError)){
        CFRelease(multi);
        return NO;
    }
    CFRelease(multi);
    return YES;
}

-(BOOL)addNote:(ABRecordRef)person note:(NSString*)note
{
    CFErrorRef error = NULL;
    BOOL success=ABRecordSetValue(person, kABPersonNoteProperty, note, &error);
    if (!success) {
        //
    }
    return success;
}

-(BOOL)addItem:(NSString *)name phoneNum:(NSString *)num  phoneEmail:(NSString *)email {
    ABAddressBookRef addressBook = nil;
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0){
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        //等待同意后向下执行
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
                                                 {
                                                     dispatch_semaphore_signal(sema);
                                                 });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        dispatch_release(sema);
    } else {
        addressBook = ABAddressBookCreate();
    }
    if (addressBook) {
        CFErrorRef error = NULL;
        ABRecordRef person = ABPersonCreate();
        ABRecordSetValue(person, kABPersonFirstNameProperty, (CFStringRef)name, &error) &&
        [self addPhone:person phone:num] &&
        [self addEmail:person email:email];
        ABAddressBookAddRecord(addressBook, person, &error);
        BOOL backBool=ABAddressBookSave(addressBook, &error);
        CFRelease(addressBook);
        CFRelease(person);
        return backBool;
    }
    return NO;
}

-(BOOL)addItemWithVCard:(NSString *)vcCardStr{
    ABAddressBookRef addressBook = nil;
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0){
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        //等待同意后向下执行
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
                                                 {
                                                     dispatch_semaphore_signal(sema);
                                                 });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        dispatch_release(sema);
    } else {
        addressBook = ABAddressBookCreate();
    }
    
    BOOL result = NO;
    if (addressBook) {
        CFErrorRef error = NULL;
        ABRecordRef person = ABPersonCreate();
        NSString * str_TEL = @"";
        NSString * str_EMAIL = @"";
        NSString * str_ORG = @"";
        NSString * str_TITLE = @"";
        NSString * str_URL = @"";
        NSString * str_NOTE = @"";
        
        NSArray * lines = [vcCardStr componentsSeparatedByString:@"\n"];
        for(NSString * line in lines) {
            if ([line hasPrefix:@"BEGIN"]) {
                //
            } else if ([line hasPrefix:@"END"]) {
                if (person!=nil) {
                    ABAddressBookAddRecord(addressBook,person, &error);
                    ABAddressBookSave(addressBook, &error);
                }
            } else if ([line hasPrefix:@"N:"] || [line hasPrefix:@"N;"]) { //N:姓;名
                NSArray * upperComponents = [line componentsSeparatedByString:@":"];
                if (upperComponents != nil && [upperComponents count] > 1) {
                    NSArray * components = [[upperComponents objectAtIndex:1] componentsSeparatedByString:@";"];
                    if ([components count] >= 2)
                        for (int i = 0; i < 2; i ++) {
                            if (i == 0) {
                                result = ABRecordSetValue(person, kABPersonLastNameProperty, (CFStringRef)[components objectAtIndex:i], &error);
                            } else {
                                result = ABRecordSetValue(person, kABPersonFirstNameProperty, (CFStringRef)[components objectAtIndex:i], &error);
                            }
                        }
                } else {
                    //姓名为空
                    break;
                }
            } else if ([line hasPrefix:@"TEL:"] || [line hasPrefix:@"TEL;"]) {
                NSArray *upperComponents = [line componentsSeparatedByString:@":"];
                if (upperComponents != nil && [upperComponents count] > 1) {
                    str_TEL = [upperComponents objectAtIndex:1];
                    [self addPhone:person phone:str_TEL];
                } else {
                    //电话为空
                }
            } else if ([line hasPrefix:@"EMAIL:"] || [line hasPrefix:@"EMAIL;"]) {
                NSArray * upperComponents = [line componentsSeparatedByString:@":"];
                if (upperComponents != nil && [upperComponents count] > 1) {
                    str_EMAIL = [upperComponents objectAtIndex:1];
                    [self addEmail:person email:str_EMAIL];
                } else {
                    //邮箱为空
                }
            } else if ([line hasPrefix:@"ADR:"] || [line hasPrefix:@"ADR;"]) {
                NSArray *upperComponents = [line componentsSeparatedByString:@":"];
                if (upperComponents != nil && [upperComponents count] > 1) {
                    NSArray * components = [[upperComponents objectAtIndex:1] componentsSeparatedByString:@";"];
                    if ([components count] >= 6) {
                        NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithCapacity:3];
                        for (int i = 0; i < [components count]; i ++) {
                            if (i == 2) { //the street address;
                                if ([[components objectAtIndex:i] length] > 0) {
                                    [dict setObject:[components objectAtIndex:i] forKey:(NSString*)kABPersonAddressStreetKey];
                                }
                            } else if (i == 3){ // the locality (e.g., city);
                                if ([[components objectAtIndex:i] length] > 0) {
                                    [dict setObject:[components objectAtIndex:i] forKey:(NSString*)kABPersonAddressCityKey];
                                }
                            } else if (i == 4){ //the region (e.g., state or province);
                                if ([[components objectAtIndex:i] length] > 0) {
                                    [dict setObject:[components objectAtIndex:i] forKey:(NSString*)kABPersonAddressStateKey];
                                }
                            } else if (i == 5){ //the postal code;
                                if ([[components objectAtIndex:i] length] > 0) {
                                    [dict setObject:[components objectAtIndex:i] forKey:(NSString*)kABPersonAddressZIPKey];
                                }
                            }
                        }
                        [self addAddress:person address:dict];
                    }
                }else{
                    //地址为空
                }
            } else if ([line hasPrefix:@"ORG:"] || [line hasPrefix:@"ORG;"]) {
                NSArray * upperComponents = [line componentsSeparatedByString:@":"];
                if (upperComponents != nil && [upperComponents count] > 1) {
                    str_ORG = [upperComponents objectAtIndex:1];
                    [self addCompany:person company:str_ORG];
                } else {
                    //公司为空
                }
            } else if ([line hasPrefix:@"TITLE:"] || [line hasPrefix:@"TITLE;"]) {
                NSArray * upperComponents = [line componentsSeparatedByString:@":"];
                if (upperComponents != nil && [upperComponents count] > 1) {
                    str_TITLE = [upperComponents objectAtIndex:1];
                    [self addTitle:person title:str_TITLE];
                } else {
                    //职位为空
                }
            } else if ([line hasPrefix:@"URL:"] || [line hasPrefix:@"URL;"]) {
                NSArray * upperComponents = [line componentsSeparatedByString:@":"];
                if (upperComponents != nil && [upperComponents count] > 1) {
                    str_URL = [upperComponents objectAtIndex:1];
                    [self addURL:person url:str_URL];
                } else {
                    //url为空
                }
            } else if ([line hasPrefix:@"NOTE:"] || [line hasPrefix:@"NOTE;"]) {
                NSArray * upperComponents = [line componentsSeparatedByString:@":"];
                if (upperComponents != nil && [upperComponents count] > 1) {
                    str_NOTE = [upperComponents objectAtIndex:1];
                    [self addNote:person note:str_NOTE];
                } else {
                    //备注为空
                }
            }
        }
        if (nil != person) {
            CFRelease(person);
        }
        CFRelease(addressBook);
    }
    return result;
}


-(BOOL)deleteItem:(NSString *)inName {
    NSString * opName = [inName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    //ABAddressBookRef addressBook = ABAddressBookCreate();
    ABAddressBookRef addressBook = nil;
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0){
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        //等待同意后向下执行
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
                                                 {
                                                     dispatch_semaphore_signal(sema);
                                                 });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        dispatch_release(sema);
    } else {
        addressBook = ABAddressBookCreate();
    }
    
    BOOL result = NO;
    if (addressBook) {
        CFErrorRef error = NULL;
        NSArray *people = [(NSArray *)ABAddressBookCopyPeopleWithName(addressBook,(CFStringRef)opName) autorelease];
        if (people != nil && [people count] > 0) {
            ABRecordRef person = (ABRecordRef)[people objectAtIndex:0];
            result = ABAddressBookRemoveRecord(addressBook, person, &error);
            if (result == YES) {
                //
            }else {
                //
            }
            ABAddressBookSave(addressBook, nil);
            CFRelease(addressBook);
        }else {
            CFRelease(addressBook);
            return NO;
        }
    }
    return result;
}

-(NSMutableArray *)searchItem_all{
    NSMutableArray* dataArray = [NSMutableArray arrayWithCapacity:3];
    //ABAddressBookRef addressBook = ABAddressBookCreate();
    ABAddressBookRef addressBook = nil;
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0) {
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        //等待同意后向下执行
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
                                                 {
                                                     dispatch_semaphore_signal(sema);
                                                 });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        dispatch_release(sema);
    } else {
        addressBook = ABAddressBookCreate();
    }
    
    if (addressBook) {
        NSArray * people = (NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
        if (people != nil && [people count] > 0) {
            for (int i = 0; i < [people count]; i ++) {
                NSMutableDictionary * dataDict = [NSMutableDictionary dictionaryWithCapacity:3];
                ABRecordRef person = (ABRecordRef)[people objectAtIndex:i];
                //返回数据
                [self setDataDict:person withInDict:dataDict];
                //添加进入数组
                [dataArray addObject:dataDict];
            }
        }
        [people release];
        CFRelease(addressBook);
        return dataArray;
    } else {
        return nil;
    }
}

-(NSString *)searchItem:(NSString *)inName resultNum:(NSInteger)resultNum{
    NSMutableArray * dataArray=[NSMutableArray arrayWithCapacity:3];
    //ABAddressBookRef addressBook = ABAddressBookCreate();
    ABAddressBookRef addressBook = nil;
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0){
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        //等待同意后向下执行
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
                                                 {
                                                     dispatch_semaphore_signal(sema);
                                                 });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        dispatch_release(sema);
    } else {
        addressBook = ABAddressBookCreate();
    }
    
    if (addressBook) {
        NSArray * people = [(NSArray *)ABAddressBookCopyPeopleWithName(addressBook,(CFStringRef)inName) autorelease];

        if (people != nil && [people count] > 0) {
            int count = (int)[people count];
            NSInteger resultNumber;
            if (resultNum >=0 && resultNum<count) {
                resultNumber=resultNum;
            }
            else if (resultNum == -1 || resultNum >=count) {
                resultNumber=count;
            }
            else{
                return @"";
            }
            for (int i = 0; i < resultNumber; i ++) {
                NSMutableDictionary * dataDict = [NSMutableDictionary dictionaryWithCapacity:3];
                ABRecordRef person = (ABRecordRef)[people objectAtIndex:i];
                //返回数据
                [self setDataDict:person withInDict:dataDict];
                //添加进入数组
                [dataArray addObject:dataDict];
            }
        }
        CFRelease(addressBook);
        return [dataArray JSONFragment];
    }
    return @"";
}

-(BOOL)modifyItem:(NSString *)inName phoneNum:(NSString *)inNum phoneEmail:(NSString *) ineMail{
    BOOL result=NO;
    CFErrorRef error = NULL;
    //ABAddressBookRef addressBook = ABAddressBookCreate();
    ABAddressBookRef addressBook = nil;
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0){
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        //等待同意后向下执行
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
                                                 {
                                                     dispatch_semaphore_signal(sema);
                                                 });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        dispatch_release(sema);
    } else {
        addressBook = ABAddressBookCreate();
    }
    
    if (addressBook) {
        NSLog(@"addressBook");
        NSArray * people = [(NSArray *)ABAddressBookCopyPeopleWithName(addressBook,(CFStringRef)inName) autorelease];
        
        if (people != nil && [people count] > 0) {
            ABRecordRef person = (ABRecordRef)[people objectAtIndex:0];
            if (person) {
                ABAddressBookRemoveRecord(addressBook, person, nil);
            } else {
                CFRelease(addressBook);
                return NO;
            }
            ABRecordRef newPerson = ABPersonCreate();
            //name
            ABRecordSetValue(newPerson, kABPersonFirstNameProperty, (CFStringRef)inName, nil);
            //phone
            ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
            ABMultiValueAddValueAndLabel(multiPhone,inNum, kABPersonPhoneMainLabel, NULL);
            ABRecordSetValue(newPerson, kABPersonPhoneProperty, multiPhone,&error);
            CFRelease(multiPhone);
            
            //email
            ABMutableMultiValueRef multiEmail = ABMultiValueCreateMutable(kABMultiStringPropertyType);
            ABMultiValueAddValueAndLabel(multiEmail, ineMail, kABWorkLabel, NULL);
            ABRecordSetValue(newPerson, kABPersonEmailProperty, multiEmail, &error);
            CFRelease(multiEmail);
            ABAddressBookAddRecord(addressBook, newPerson, nil);
            result = ABAddressBookSave(addressBook, nil);
            CFRelease(newPerson);
            CFRelease(addressBook);
        }else {
            CFRelease(addressBook);
            return NO;
        }
    }else{
    }
    
    return result;
}

-(BOOL )modifyMulti:(NSArray *)inArguments{
    NSString *inName = nil ; NSString *inNum = nil;NSString *ineMail = nil;NSString *index = nil;
    if (inArguments .count == 4) {
        inName = [inArguments objectAtIndex:0];
        inNum = [inArguments objectAtIndex:1];
        ineMail = [inArguments objectAtIndex:2];
        index = [inArguments objectAtIndex:3];
    }
    BOOL result=NO;
    CFErrorRef error = NULL;
    //ABAddressBookRef addressBook = ABAddressBookCreate();
    ABAddressBookRef addressBook = nil;
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0){
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        //等待同意后向下执行
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
                                                 {
                                                     dispatch_semaphore_signal(sema);
                                                 });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        dispatch_release(sema);
    } else {
        addressBook = ABAddressBookCreate();
    }
    if (addressBook) {
        NSLog(@"addressBook");
        NSArray * people = [(NSArray *)ABAddressBookCopyPeopleWithName(addressBook,(CFStringRef)inName) autorelease];
        if (people != nil && [people count] > 0) {
            NSDictionary *dict = [[[self searchItem:inName] JSONValue] objectAtIndex:0] ;
            NSMutableArray *oldNum = [dict objectForKey:@"num"];
            if( [index integerValue] < oldNum.count ){
                [oldNum setObject:inNum atIndexedSubscript:[index integerValue]];
                ABRecordRef person = (ABRecordRef)[people objectAtIndex:0];
                if (person) {
                    //                ABAddressBookRemoveRecord(addressBook, person, nil);
                    //修改电话
                    ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                    for(NSInteger i = 0;i <oldNum.count  ;i++){
                        if (i==0) {
                            ABMultiValueAddValueAndLabel(multiPhone, (CFStringRef)[oldNum objectAtIndex:i], kABPersonPhoneMainLabel, NULL);
                        }else if(i == 1){
                            ABMultiValueAddValueAndLabel(multiPhone, (CFStringRef)[oldNum objectAtIndex:i], kABPersonPhoneMobileLabel, NULL);
                        }else{
                            ABMultiValueAddValueAndLabel(multiPhone, (CFStringRef)[oldNum objectAtIndex:i], kABPersonPhoneHomeFAXLabel, NULL);
                        }
                    }
                    ABRecordSetValue(person, kABPersonPhoneProperty, multiPhone,&error);
                    CFRelease(multiPhone);
                    
                    //修改Email
                    //email
                    ABMutableMultiValueRef multiEmail = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                    ABMultiValueAddValueAndLabel(multiEmail, ineMail, kABWorkLabel, NULL);
                    ABRecordSetValue(person, kABPersonEmailProperty, multiEmail, &error);
                    CFRelease(multiEmail);
                    
                    ABAddressBookAddRecord(addressBook, person, nil);
                    result = ABAddressBookSave(addressBook, nil);
                    CFRelease(addressBook);
                }else{
                    CFRelease(addressBook);
                    return NO;
                }
            } else {
                CFRelease(addressBook);
                return NO;
            }
            //            ABRecordRef newPerson = ABPersonCreate();
            //            //name
            //            ABRecordSetValue(newPerson, kABPersonFirstNameProperty, (CFStringRef)inName, nil);
            //            //phone
            //            ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
            //            ABMultiValueAddValueAndLabel(multiPhone,inNum, kABPersonPhoneMainLabel, NULL);
            //            ABRecordSetValue(newPerson, kABPersonPhoneProperty, multiPhone,&error);
            //            CFRelease(multiPhone);
            //
            //            //email
            //            ABMutableMultiValueRef multiEmail = ABMultiValueCreateMutable(kABMultiStringPropertyType);
            //            ABMultiValueAddValueAndLabel(multiEmail, ineMail, kABWorkLabel, NULL);
            //            ABRecordSetValue(newPerson, kABPersonEmailProperty, multiEmail, &error);
            //            CFRelease(multiEmail);
            //            ABAddressBookAddRecord(addressBook, newPerson, nil);
            //            result = ABAddressBookSave(addressBook, nil);
            //            CFRelease(newPerson);
            //            CFRelease(addressBook);
        }else {
            CFRelease(addressBook);
            return NO;
        }
    }else{
    }
    
    return result;
    
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)picker
{
    [picker dismissModalViewControllerAnimated:YES];
}
-(void)dealloc{
    if (resultDict) {
        [resultDict release];
    }
    if (_peoplePicker) {
        [_peoplePicker release];
    }
    [super dealloc];
}
@end
