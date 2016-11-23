
//
//  EUEXContact.m
//  AppCan
//
//  Created by AppCan on 11-9-20.
//  Copyright 2011 AppCan. All rights reserved.
//

#import "EUExContact.h"
#import "Contact.h"
#import "EUtility.h"
#import "EUExBaseDefine.h"
#import "PeopleContactViewController.h"


@interface EUExContact()
@property(nonatomic,strong)ACJSFunctionRef*fun;
@end
@implementation EUExContact

//-(id)initWithBrwView:(EBrowserView *) eInBrwView {
//    if (self = [super initWithBrwView:eInBrwView]) {
//        contact = [[Contact alloc] init];
//    }
//    return self;
//}
-(id)initWithWebViewEngine:(id<AppCanWebViewEngineObject>)engine{
    if (self = [super initWithWebViewEngine:engine]) {
        contact = [[Contact alloc] init];
    }
    return self;
}

-(void)dealloc {
    if (contact) {
        //[contact release];
        contact = nil;
    }
    contact = nil;
    if (actionArray) {
        //[actionArray release];
        actionArray = nil;
    }
    //[super dealloc];
}

-(BOOL)check_Authorization {
    __block BOOL resultBool = NO;
    float fOSVersion = [[UIDevice currentDevice].systemVersion floatValue];
    if (fOSVersion > 5.9f) {
        ABAddressBookRef book = ABAddressBookCreateWithOptions(NULL, NULL);
        ABAuthorizationStatus addressAccessStatus = ABAddressBookGetAuthorizationStatus();
        switch (addressAccessStatus) {
            case kABAuthorizationStatusAuthorized:
                resultBool = YES;
                break;
            case kABAuthorizationStatusNotDetermined:
                ABAddressBookRequestAccessWithCompletion(book, ^(bool granted, CFErrorRef error) {
                    if (granted) {
                        resultBool = YES;
                    }
                });
                break;
            case kABAuthorizationStatusRestricted:
                break;
            case kABAuthorizationStatusDenied:
                break;
            default:
                break;
        }
        if (book) {
            CFRelease(book);
        }
    } else {
        resultBool = YES;
    }
    return resultBool;
}

-(void)showAlertViewMessage {
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"当前应用无访问通讯录权限\n 请在 设置->隐私->通讯录 中开启访问权限！" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alert show];
    //[alert release];
}

-(void)open:(NSMutableArray *)inArguments {
    ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
    self.fun = func;
    if ([self check_Authorization]) {
        //打开通讯录
        [contact openItemWithUEx:self];
    }else{
        [self showAlertViewMessage];
    }
}

-(void)showAlertView:(NSString *)message alertID:(int)ID{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:message delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定",nil];
    alert.tag = ID;
    [alert show];
    //[alert release];
}

-(void)addItem:(NSMutableArray *)inArguments {
    ACArgsUnpack(NSString *name,NSString *num,NSString *email,NSDictionary *isNeedAlert) = inArguments;
    ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
    self.fun = func;
    if ([self check_Authorization]) {
        actionArray = [[NSArray alloc] initWithArray:inArguments];
        BOOL isNeedAlertDialog=YES;
        if(inArguments.count>4){
           // NSDictionary *isNeedAlert=[inArguments[3] ac_JSONValue];
            if(isNeedAlert){
                isNeedAlertDialog=[[isNeedAlert objectForKey:@"isNeedAlertDialog"] boolValue];
            }
        }
        if(isNeedAlertDialog){
            [self showAlertView:@"应用程序需要添加联系人信息，是否确认添加？" alertID:111];
        }
        else{
            [self addItemWithName:name phoneNum:num phoneEmail:email];
        }
    }else{
        [self showAlertViewMessage];
    }
}

-(void)addItemWithName:(NSString *)inName phoneNum:(NSString *)inNum  phoneEmail:(NSString *)inEmail {
    BOOL result = [contact addItem:inName phoneNum:inNum phoneEmail:inEmail];
    if (result == NO){
        //失败
        //[self jsSuccessWithName:@"uexContact.cbAddItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CFAILED];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbAddItem" arguments:ACArgsPack(@0,@2,@1)];
        [self.fun executeWithArguments:ACArgsPack(@(1))];
    } else {
        //[self jsSuccessWithName:@"uexContact.cbAddItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CSUCCESS];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbAddItem" arguments:ACArgsPack(@0,@2,@0)];
        [self.fun executeWithArguments:ACArgsPack(@(0))];
    }
        self.fun = nil;
}

-(void)addItemWithVCard:(NSMutableArray *)inArguments {
    ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
    self.fun = func;
    if ([self check_Authorization]) {
        if (inArguments && [inArguments count] > 0) {
            if (2 == [inArguments count]) {
                actionArray = [[NSArray alloc] initWithArray:inArguments];
            } else if(3 == [inArguments count]){
                NSArray * array = [inArguments subarrayWithRange:NSMakeRange(0, 1)];
                actionArray = [[NSArray alloc] initWithArray:array];
                NSString * isShowAV = [inArguments objectAtIndex:1];
                if (1 == [isShowAV intValue]) {
                    [self addItemWithVCard_String:[inArguments objectAtIndex:0]];
                    if (actionArray) {
                        actionArray = nil;
                    }
                } else {
                    [self showAlertView:@"应用程序需要添加联系人信息，是否确认添加？" alertID:112];
                }
            }
        }
    } else {
        [self showAlertViewMessage];
    }
}

-(void)addItemWithVCard_String:(NSString *)vcCardStr {
    BOOL result = [contact addItemWithVCard:vcCardStr];
    
    if (result == NO){
        //失败
        //[self jsSuccessWithName:@"uexContact.cbAddItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CFAILED];
         [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbAddItem" arguments:ACArgsPack(@0,@2,@1)];
        [self.fun executeWithArguments:ACArgsPack(@(1))];
        self.fun = nil;
    } else {
        //[self jsSuccessWithName:@"uexContact.cbAddItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CSUCCESS];
         [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbAddItem" arguments:ACArgsPack(@0,@2,@0)];
        [self.fun executeWithArguments:ACArgsPack(@(0))];
        self.fun = nil;
    }
}

-(void)deleteItem:(NSMutableArray *)inArguments {
    ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
    self.fun = func;
    if ([self check_Authorization]) {
        actionArray = [[NSArray alloc] initWithArray:inArguments];
        [self showAlertView:@"应用程序需要删除联系人信息，是否确认删除？" alertID:222];
    } else {
        [self showAlertViewMessage];
    }
}

-(void)deleteItemWithName:(NSString *)inName {
    BOOL result = [contact deleteItem:inName];
    if (result == NO){
        //失败
        //[self jsSuccessWithName:@"uexContact.cbDeleteItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CFAILED];
         [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbDeleteItem" arguments:ACArgsPack(@0,@2,@1)];
        [self.fun executeWithArguments:ACArgsPack(@(1))];
        
    } else {
        //[self jsSuccessWithName:@"uexContact.cbDeleteItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CSUCCESS];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbDeleteItem" arguments:ACArgsPack(@0,@2,@0)];
        [self.fun executeWithArguments:ACArgsPack(@(0))];
        
    }
        self.fun = nil;
}

// 通过ID删除联系人
-(void)deleteWithId:(NSMutableArray *)inArguments{
    ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
    self.fun = func;
    if ([self check_Authorization]) {
        //NSDictionary *dic = [[inArguments objectAtIndex:0] ac_JSONValue];
        ACArgsUnpack(NSDictionary *dic) = inArguments;
        recordID = [[NSString stringWithFormat:@"%@",[dic objectForKey:@"contactId"]] intValue];
        [self showAlertView:@"应用程序需要删除联系人信息，是否确认删除？" alertID:555];
    }
    else
    {
        [self showAlertViewMessage];
    }
}
- (void)deleteItemWithID:(int)ids
{
    BOOL result = [contact deleteItemWithId:ids];
    if (result == NO){
        //失败
        //[self jsSuccessWithName:@"uexContact.cbDeleteWithId" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CFAILED];
         [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbDeleteWithId" arguments:ACArgsPack(@0,@2,@1)];
         [self.fun executeWithArguments:ACArgsPack(@(1))];
        
    } else {
        //[self jsSuccessWithName:@"uexContact.cbDeleteWithId" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CSUCCESS];
         [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbDeleteWithId" arguments:ACArgsPack(@0,@2,@0)];
         [self.fun executeWithArguments:ACArgsPack(@(0))];
    }
    self.fun = nil;
    recordID = 0;
}



-(void)searchItem:(NSMutableArray *)inArguments {
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    ACArgsUnpack(NSString*nameKey,NSDictionary*option) = inArguments;
    ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
    if ([self check_Authorization]) {
        NSString * inName = nameKey;//[inArguments objectAtIndex:0];
        int resultNum=50;
        if(inArguments.count>1){
           // NSDictionary *option=[[inArguments objectAtIndex:1] ac_JSONValue];
            if(option){
                resultNum=[[option objectForKey:@"resultNum"] intValue];
                if ([option objectForKey:@"isSearchAddress"] != nil) {
                    contact.isSearchAddress = [NSString stringWithFormat:@"%d",[[option objectForKey:@"isSearchAddress"]boolValue]];
                }
                if ([option objectForKey:@"isSearchCompany"] != nil) {
                    contact.isSearchCompany = [NSString stringWithFormat:@"%d",[[option objectForKey:@"isSearchCompany"]boolValue]]; 
                }
                if ([option objectForKey:@"isSearchEmail"] != nil) {
                    contact.isSearchEmail = [NSString stringWithFormat:@"%d",[[option objectForKey:@"isSearchEmail"]boolValue]];
                }
                if ([option objectForKey:@"isSearchNote"] != nil) {
                    contact.isSearchNote = [NSString stringWithFormat:@"%d",[[option objectForKey:@"isSearchNote"]boolValue]];
                }
                if ([option objectForKey:@"isSearchNum"] != nil) {
                    contact.isSearchNum = [NSString stringWithFormat:@"%d",[[option objectForKey:@"isSearchNum"]boolValue]];
                }
                if ([option objectForKey:@"isSearchTitle"] != nil) {
                    contact.isSearchTitle = [NSString stringWithFormat:@"%d",[[option objectForKey:@"isSearchTitle"]boolValue]];
                }
                if ([option objectForKey:@"isSearchUrl"] != nil) {
                    contact.isSearchUrl = [NSString stringWithFormat:@"%d",[[option objectForKey:@"isSearchUrl"]boolValue]];
                }
            }
        }
        if (0 == [inName length]) {//传入名字为空时，就查找所有联系人
            NSMutableArray * array = [contact searchItem_all];
            if ([array isKindOfClass:[NSMutableArray class]] && [array count] > 0) {
                int count = (int)[array count];
                NSRange range;
                if (resultNum >0) {
                    range = NSMakeRange(0, resultNum);
                }
                else if (resultNum == -1) {
                    range = NSMakeRange(0, count);
                }
                else{
                    range = NSMakeRange(0, 50);
                }
                NSArray * subArray = [array subarrayWithRange:range];
                if ([subArray isKindOfClass:[NSArray class]] && [subArray count] > 0) {
                    NSString * jsonResult = [subArray ac_JSONFragment];
                    if ([jsonResult isKindOfClass:[NSString class]] && jsonResult.length>0) {
                        //处理换行符；
                        //jsonResult=[jsonResult stringByReplacingOccurrencesOfString:@"\\n" withString:@" "];
                    //[self jsSuccessWithName:@"uexContact.cbSearchItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:jsonResult];
                    [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbSearchItem" arguments:ACArgsPack(@0,@1,jsonResult)];
                    [func executeWithArguments:ACArgsPack(@(0),[jsonResult ac_JSONValue])];
                    func = nil;
                    } else {
                        //[self jsSuccessWithName:@"uexContact.cbSearchItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:@""];
                        [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbSearchItem" arguments:ACArgsPack(@0,@1,@"")];
                        [func executeWithArguments:ACArgsPack(@(1),@"")];
                        func = nil;
                    }
                    user = nil;
                }
            }
        } else {
            NSString * jsonResult = [contact searchItem:inName resultNum:resultNum];
            if ([jsonResult isKindOfClass:[NSString class]] && jsonResult.length>0) {
                //[self jsSuccessWithName:@"uexContact.cbSearchItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:jsonResult];
                [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbSearchItem" arguments:ACArgsPack(@0,@1,jsonResult)];
                [func executeWithArguments:ACArgsPack(@(0),[jsonResult ac_JSONValue])];
                func = nil;
            } else {
                //[self jsSuccessWithName:@"uexContact.cbSearchItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:@""];
                [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbSearchItem" arguments:ACArgsPack(@0,@1,@"")];
                [func executeWithArguments:ACArgsPack(@(1),@"")];
                func = nil;
            }
            user = nil;
        }
    } else {
        [self showAlertViewMessage];
    }
}
// 通过ID查询
-(void)search:(NSMutableArray *)inArguments
{
    ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
    
    if ([self check_Authorization]) {
        //NSDictionary *option = [[inArguments objectAtIndex:0] ac_JSONValue];
        ACArgsUnpack(NSDictionary *option) = inArguments;
        int contactId = -1;
        int resultNum=50;
        resultNum=[[option objectForKey:@"resultNum"] intValue];
        if ([option objectForKey:@"isSearchAddress"] != nil) {
            contact.isSearchAddress = [NSString stringWithFormat:@"%d",[[option objectForKey:@"isSearchAddress"]boolValue]];
        }
        if ([option objectForKey:@"isSearchCompany"] != nil) {
            contact.isSearchCompany = [NSString stringWithFormat:@"%d",[[option objectForKey:@"isSearchCompany"]boolValue]];
        }
        if ([option objectForKey:@"isSearchEmail"] != nil) {
            contact.isSearchEmail = [NSString stringWithFormat:@"%d",[[option objectForKey:@"isSearchEmail"]boolValue]];
        }
        if ([option objectForKey:@"isSearchNote"] != nil) {
            contact.isSearchNote = [NSString stringWithFormat:@"%d",[[option objectForKey:@"isSearchNote"]boolValue]];
        }
        if ([option objectForKey:@"isSearchNum"] != nil) {
            contact.isSearchNum = [NSString stringWithFormat:@"%d",[[option objectForKey:@"isSearchNum"]boolValue]];
        }
        if ([option objectForKey:@"isSearchTitle"] != nil) {
            contact.isSearchTitle = [NSString stringWithFormat:@"%d",[[option objectForKey:@"isSearchTitle"]boolValue]];
        }
        if ([option objectForKey:@"isSearchUrl"] != nil) {
            contact.isSearchUrl = [NSString stringWithFormat:@"%d",[[option objectForKey:@"isSearchUrl"]boolValue]];
        }
        if ([option objectForKey:@"contactId"] != nil) {
            contactId = [[option objectForKey:@"contactId"]intValue];
        }
        if ([option objectForKey:@"searchName"] != nil) {
            _searchName = [NSString stringWithFormat:@"%@",[option objectForKey:@"searchName"]];
        }else{
            _searchName = @"";
        }
        if (contactId > 0) {
            NSString *jsonResult =[contact search:contactId];
            
            if ([jsonResult isKindOfClass:[NSString class]] && jsonResult.length>0) {
               // NSString *jsonStr = [NSString stringWithFormat:@"if(uexContact.cbSearch != null){uexContact.cbSearch(%@)}",jsonResult];
                //[EUtility brwView:meBrwView evaluateScript:jsonStr];
                [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbSearch" arguments:ACArgsPack(jsonResult)];
                NSDictionary *resultDic = [jsonResult ac_JSONValue];
                if ([resultDic[@"result"] isEqualToString:@"0"]) {
                  [func executeWithArguments:ACArgsPack(@(0),resultDic[@"contactList"])];
                }else{
                  [func executeWithArguments:ACArgsPack(@(1),nil)]; 
                }
                
                func = nil;
            } else {
                //NSString *jsonStr = [NSString stringWithFormat:@"if(uexContact.cbSearch != null){uexContact.cbSearch(%@)}",@""];
               // [EUtility brwView:meBrwView evaluateScript:jsonStr];
                [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbSearch" arguments:ACArgsPack(@"")];
                [func executeWithArguments:ACArgsPack(@(1),nil)];
                func = nil;
            }
        }
        else
        {
            NSString *inName =[NSString stringWithFormat:@"%@",_searchName];
            if (0 == [inName length]) {//传入名字为空时，就查找所有联系人
                NSMutableArray * array = [contact searchItem_all];
                if ([array isKindOfClass:[NSMutableArray class]] && [array count] > 0) {
                    int count = (int)[array count];
                    NSRange range;
                    if (resultNum >0) {
                        range = NSMakeRange(0, resultNum);
                    }
                    else if (resultNum == -1) {
                        range = NSMakeRange(0, count);
                    }
                    else{
                        range = NSMakeRange(0, 50);
                    }
                    NSArray * subArray = [array subarrayWithRange:range];
                    if ([subArray isKindOfClass:[NSArray class]] && [subArray count] > 0) {
                        NSString * jsonResult = [subArray ac_JSONFragment];
                        if ([jsonResult isKindOfClass:[NSString class]] && jsonResult.length>0) {
                            //NSString *jsonStr = [NSString stringWithFormat:@"if(uexContact.cbSearch != null){uexContact.cbSearch(%@)}",jsonResult];
                            //[EUtility brwView:meBrwView evaluateScript:jsonStr];
                            [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbSearch" arguments:ACArgsPack(jsonResult)];
                            [func executeWithArguments:ACArgsPack(@(0),[jsonResult ac_JSONValue])];
                            func = nil;
                            
                        } else {
                            //NSString *jsonStr = [NSString stringWithFormat:@"if(uexContact.cbSearch != null){uexContact.cbSearch(%@)}",@""];
                            //[EUtility brwView:meBrwView evaluateScript:jsonStr];
                            [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbSearch" arguments:ACArgsPack(@"")];
                            [func executeWithArguments:ACArgsPack(@(1),nil)];
                            func = nil;
                        }
                    }
                }
            } else {
                NSString * jsonResult = [contact searchItem:inName resultNum:resultNum];
                if ([jsonResult isKindOfClass:[NSString class]] && jsonResult.length>0) {
                   // NSString *jsonStr = [NSString stringWithFormat:@"if(uexContact.cbSearch != null){uexContact.cbSearch(%@)}",jsonResult];
                    //[EUtility brwView:meBrwView evaluateScript:jsonStr];
                    [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbSearch" arguments:ACArgsPack(jsonResult)];
                    [func executeWithArguments:ACArgsPack(@(0),[jsonResult ac_JSONValue])];
                    func = nil;
                    
                } else {
                    //NSString *jsonStr = [NSString stringWithFormat:@"if(uexContact.cbSearch != null){uexContact.cbSearch(%@)}",@""];
                    //[EUtility brwView:meBrwView evaluateScript:jsonStr];
                    [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbSearch" arguments:ACArgsPack(jsonResult)];
                    [func executeWithArguments:ACArgsPack(@(1),nil)];
                    func = nil;
                }
            }
            
        }
        
    }
    else
    {
        [self showAlertViewMessage];
    }
}
-(void)modifyWithId:(NSMutableArray *)inArguments{
    ACJSFunctionRef *fuc = JSFunctionArg(inArguments.lastObject);
    self.fun = fuc;
    if ([self check_Authorization]) {
        actionArray = [[NSArray alloc]initWithArray:inArguments];
        [self showAlertView:@"应用程序需要修改联系人信息，是否确认修改？" alertID:666];
    } else {
        [self showAlertViewMessage];
    }
}
-(void)modifyItemWithId:(NSArray *)array{
    NSDictionary *diction = [[array objectAtIndex:0] ac_JSONValue];
    int recordId = [[NSString stringWithFormat:@"%@",[diction objectForKey:@"contactId"]] intValue];
    NSString *name = [NSString stringWithFormat:@"%@",[diction objectForKey:@"name"]];
    NSString *num  = [NSString stringWithFormat:@"%@",[diction objectForKey:@"num"]];
    NSString *email = [NSString stringWithFormat:@"%@",[diction objectForKey:@"email"]];
    BOOL result =[contact modifyItemWithId:recordId Name:name phoneNum:num phoneEmail:email];
    if (result == NO){
        //失败
        //[self jsSuccessWithName:@"uexContact.cbModifyWithId" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CFAILED];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbModifyWithId" arguments:ACArgsPack(@0,@2,@1)];
        [self.fun executeWithArguments:ACArgsPack(@(1))];
        self.fun = nil;
    } else {
        //[self jsSuccessWithName:@"uexContact.cbModifyWithId" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CSUCCESS];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbModifyWithId" arguments:ACArgsPack(@0,@2,@0)];
        [self.fun executeWithArguments:ACArgsPack(@(0))];
        self.fun = nil;
    }
}
-(void)modifyItem:(NSMutableArray *)inArguments {
     ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
    self.fun = func;
    if ([self check_Authorization]) {
        actionArray = [[NSArray alloc] initWithArray:inArguments];
        [self showAlertView:@"应用程序需要修改联系人信息，是否确认修改？" alertID:333];
    } else {
        [self showAlertViewMessage];
    }
}


//修改多个号码的联系人
-(void)modifyMultiItem:(NSMutableArray *)inArguments{
    if ([self check_Authorization]) {
        actionArray = [[NSArray alloc] initWithArray:inArguments];
        [self showAlertView:@"应用程序需要修改联系人信息，是否确认修改？" alertID:444];
    } else {
        [self showAlertViewMessage];
    }
}
-(void)modifyMultiItemWithArray:(NSArray *)inArguments{
    BOOL result = [contact  modifyMulti:(NSMutableArray *)inArguments];
    if (result == NO){
        //失败
        //[self jsSuccessWithName:@"uexContact.cbModifyItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CFAILED];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbModifyItem" arguments:ACArgsPack(@0,@2,@1)];
        [self.fun executeWithArguments:ACArgsPack(@(1))];
        
    } else {
        //[self jsSuccessWithName:@"uexContact.cbModifyItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CSUCCESS];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbModifyItem" arguments:ACArgsPack(@0,@2,@0)];
        [self.fun executeWithArguments:ACArgsPack(@(0))];
    }
    
}

-(void)modifyItemWithName:(NSString *)inName phoneNum:(NSString *)inNum phoneEmail:(NSString *)inEmail{
    
    BOOL result = [contact modifyItem:inName phoneNum:inNum phoneEmail:inEmail];
    
    if (result == NO){
        //失败
        //[self jsSuccessWithName:@"uexContact.cbModifyItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CFAILED];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbModifyItem" arguments:ACArgsPack(@0,@2,@1)];
        [self.fun executeWithArguments:ACArgsPack(@(1))];
        self.fun = nil;
    } else {
        //[self jsSuccessWithName:@"uexContact.cbModifyItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CSUCCESS];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbModifyItem" arguments:ACArgsPack(@0,@2,@0)];
        [self.fun executeWithArguments:ACArgsPack(@(0))];
        self.fun = nil;
    }
}

-(void)multiOpen:(NSMutableArray*)inArguments{
    ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
    if ([self check_Authorization]) {
        PeopleContactViewController* contactView = [[PeopleContactViewController alloc] init];
        contactView.callBack = self;
        contactView.func = func;
        UINavigationController * nav = [[UINavigationController alloc] initWithRootViewController:contactView];
        //[EUtility brwView:[super meBrwView] presentModalViewController:nav animated:(BOOL)YES];
        [[[super webViewEngine] viewController] presentViewController:nav animated:YES completion:nil];
        //[nav release];
        //[contactView release];
    } else {
        [self showAlertViewMessage];
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        switch (alertView.tag) {
            case 111:
                [self addItemWithName:[actionArray objectAtIndex:0] phoneNum:[actionArray objectAtIndex:1] phoneEmail:[actionArray objectAtIndex:2]];
                break;
            case 112:
                [self addItemWithVCard_String:[actionArray objectAtIndex:0]];
                break;
            case 222:
                [self deleteItemWithName:[actionArray objectAtIndex:0]];
                break;
            case 333:
                [self modifyItemWithName:[actionArray objectAtIndex:0] phoneNum:[actionArray objectAtIndex:1] phoneEmail:[actionArray objectAtIndex:2]];
                break;
            case 444:
                [self modifyMultiItemWithArray:actionArray];
                break;
            case 555:
                [self deleteItemWithID:recordID];
                break;
            case 666:
                [self modifyItemWithId:actionArray];
                break;
            default:
                break;
        }
    }
    if (actionArray) {
        //[actionArray release];
        actionArray = nil;
    }
}

-(void)uexOpenSuccessWithOpId:(int)inOpId dataType:(int)inDataType data:(NSString *)inData{
    if (inData) {
        //[self jsSuccessWithName:@"uexContact.cbOpen" opId:inOpId dataType:inDataType strData:inData];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexContact.cbOpen" arguments:ACArgsPack(@(inOpId),@(inDataType),inData)];
        [self.fun executeWithArguments:ACArgsPack(@(0),[inData ac_JSONValue])];
    }else{
        [self.fun executeWithArguments:ACArgsPack(@(1),nil)];
    }
         self.fun = nil;
}

@end
