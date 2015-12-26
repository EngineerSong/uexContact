//
//  PeopleContactViewController.h
//  ABMutilChoose
//
//  Created by AppCan on 12-5-22.
//  Copyright 2012 AppCan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EUExBase.h"

@interface PeopleContactViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>{
	UITableView * table;
	NSArray *sourceArray;
	NSMutableArray *keyArray;
	NSMutableDictionary *allPeoples;
	NSMutableArray *keys;
	NSMutableDictionary *names;
	NSMutableDictionary *selectNames;
	UISearchBar *mySearchBar;
	UIToolbar* toolBar;
	NSInteger isEditableOrNot;
	EUExBase* callBack;
    ABAddressBookRef addressBook;
}

@property(nonatomic,retain) UITableView * table;
@property(nonatomic,retain)	NSArray *sourceArray;
@property(nonatomic,retain)	NSMutableArray *keyArray;
@property(nonatomic,retain)	NSMutableDictionary *allPeoples;
@property(nonatomic,retain)	NSMutableArray *keys;
@property(nonatomic,retain)	NSMutableDictionary *names;
@property(nonatomic,retain)	NSMutableDictionary *selectNames;
@property(nonatomic,retain) UISearchBar *mySearchBar;
@property(nonatomic,retain) UIToolbar* toolBar;
@property(nonatomic,retain) EUExBase* callBack;

@end
