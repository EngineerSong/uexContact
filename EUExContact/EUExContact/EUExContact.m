
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
#import "JSON.h"

@implementation EUExContact

-(id)initWithBrwView:(EBrowserView *) eInBrwView {	
	if (self = [super initWithBrwView:eInBrwView]) {
		contact = [[Contact alloc] init];
	}
	return self;
}

-(void)dealloc {
    if (contact) {
        [contact release];
        contact = nil;
    }
	contact = nil;
	if (actionArray) {
		[actionArray release];
		actionArray = nil;
	}
	[super dealloc];
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
	[alert release];
}

-(void)open:(NSMutableArray *)inArguments {
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
	[alert release];
}

-(void)addItem:(NSMutableArray *)inArguments {
    if ([self check_Authorization]) {
        actionArray = [[NSArray alloc] initWithArray:inArguments];
        BOOL isNeedAlertDialog=YES;
        
        if(inArguments.count>3){
            NSDictionary *isNeedAlert=[inArguments[3] JSONValue];
            if(isNeedAlert){
                isNeedAlertDialog=[[isNeedAlert objectForKey:@"isNeedAlertDialog"] boolValue];
            }
        }
        if(isNeedAlertDialog){
            [self showAlertView:@"应用程序需要添加联系人信息，是否确认添加？" alertID:111];
        }
        else{
            [self addItemWithName:[actionArray objectAtIndex:0] phoneNum:[actionArray objectAtIndex:1] phoneEmail:[actionArray objectAtIndex:2]];
        }
    }else{
        [self showAlertViewMessage];
    }
}

-(void)addItemWithName:(NSString *)inName phoneNum:(NSString *)inNum  phoneEmail:(NSString *)inEmail {
    BOOL result = [contact addItem:inName phoneNum:inNum phoneEmail:inEmail];	
	if (result == NO){
		//失败
		[self jsSuccessWithName:@"uexContact.cbAddItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CFAILED];
	} else {
		[self jsSuccessWithName:@"uexContact.cbAddItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CSUCCESS];
	}
}

-(void)addItemWithVCard:(NSMutableArray *)inArguments {
    if ([self check_Authorization]) {
        if (inArguments && [inArguments count] > 0) {
            if (1 == [inArguments count]) {
                actionArray = [[NSArray alloc] initWithArray:inArguments];
            } else if(2 == [inArguments count]){
                NSArray * array = [inArguments subarrayWithRange:NSMakeRange(0, 1)];
                actionArray = [[NSArray alloc] initWithArray:array];
                NSString * isShowAV = [inArguments objectAtIndex:1];
                if (1 == [isShowAV intValue]) {
                    [self addItemWithVCard_String:[inArguments objectAtIndex:0]];
                    if (actionArray) {
                        [actionArray release];
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
		[self jsSuccessWithName:@"uexContact.cbAddItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CFAILED];
	} else {
		[self jsSuccessWithName:@"uexContact.cbAddItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CSUCCESS];
	}
}

-(void)deleteItem:(NSMutableArray *)inArguments {
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
		[self jsSuccessWithName:@"uexContact.cbDeleteItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CFAILED];
	} else {
		[self jsSuccessWithName:@"uexContact.cbDeleteItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CSUCCESS];
	}
}

-(void)searchItem:(NSMutableArray *)inArguments {
    if ([self check_Authorization]) {
        NSString * inName = [inArguments objectAtIndex:0];
        int resultNum=50;
        if(inArguments.count>1){
            NSDictionary *option=[[inArguments objectAtIndex:1] JSONValue];
            if(option){
                resultNum=[[option objectForKey:@"resultNum"] intValue];
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
                    NSString * jsonResult = [subArray JSONFragment];
                    if ([jsonResult isKindOfClass:[NSString class]] && jsonResult.length>0) {
                        //处理换行符；
                        //jsonResult=[jsonResult stringByReplacingOccurrencesOfString:@"\\n" withString:@" "];
                        [self jsSuccessWithName:@"uexContact.cbSearchItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:jsonResult];
                    } else {
                        [self jsSuccessWithName:@"uexContact.cbSearchItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:@""];
                    }
                }
            }
        } else {
            NSString * jsonResult = [contact searchItem:inName resultNum:resultNum];
            if ([jsonResult isKindOfClass:[NSString class]] && jsonResult.length>0) {
                [self jsSuccessWithName:@"uexContact.cbSearchItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:jsonResult];
            } else {
                [self jsSuccessWithName:@"uexContact.cbSearchItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:@""];
            }
        }
    } else {
        [self showAlertViewMessage];
    }
}

-(void)modifyItem:(NSMutableArray *)inArguments {
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
        [self jsSuccessWithName:@"uexContact.cbModifyItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CFAILED];
    } else {
        [self jsSuccessWithName:@"uexContact.cbModifyItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CSUCCESS];
    }

}

-(void)modifyItemWithName:(NSString *)inName phoneNum:(NSString *)inNum phoneEmail:(NSString *)inEmail{

	BOOL result = [contact modifyItem:inName phoneNum:inNum phoneEmail:inEmail];

	if (result == NO){
		//失败
		[self jsSuccessWithName:@"uexContact.cbModifyItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CFAILED];
	} else {
		[self jsSuccessWithName:@"uexContact.cbModifyItem" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CSUCCESS];
	}
}

-(void)multiOpen:(NSMutableArray*)inArguments{
    if ([self check_Authorization]) {
        PeopleContactViewController* contactView = [[PeopleContactViewController alloc] init];
        contactView.callBack = self;
        UINavigationController * nav = [[UINavigationController alloc] initWithRootViewController:contactView];
        [EUtility brwView:[super meBrwView] presentModalViewController:nav animated:(BOOL)YES];
        [nav release];
        [contactView release];
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
			default:
				break;
		}
	}
    if (actionArray) {
		[actionArray release];
		actionArray = nil;
	}
}

-(void)uexOpenSuccessWithOpId:(int)inOpId dataType:(int)inDataType data:(NSString *)inData{
	if (inData) {
		[self jsSuccessWithName:@"uexContact.cbOpen" opId:inOpId dataType:inDataType strData:inData];
	}
}

@end
