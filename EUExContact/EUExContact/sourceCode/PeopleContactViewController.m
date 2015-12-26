//
//  PeopleContactViewController.m
//  AppCan
//
//  Created by AppCan on 12-5-22.
//  Copyright 2012 AppCan. All rights reserved.
//
#import <AddressBook/AddressBook.h>
#import "PeopleContactViewController.h"
#import "NSDictionary-MutableDeepCopy.h"
#import "ChineseToPinyin.h"
#import "JSON.h"
#import "EUEXContact.h"

@implementation PeopleContactViewController
@synthesize table;
@synthesize sourceArray;
@synthesize keyArray;
@synthesize allPeoples;
@synthesize keys;
@synthesize names;
@synthesize selectNames;
@synthesize mySearchBar;
@synthesize toolBar;
@synthesize callBack;
#pragma mark -
#pragma mark init data
-(void)doCallBack:(NSString*)jsonString{
	if (callBack) {
		[callBack jsSuccessWithName:@"uexContact.cbMultiOpen" opId:0 dataType:1 strData:jsonString];
	}
}

-(void)initSelectNames:(NSString*)value{
	if (keys && names) {
        if (!self.selectNames) {
            self.selectNames = [[[NSMutableDictionary alloc] initWithCapacity:1] autorelease];
        }
		NSInteger count = [keys count];
		for (NSInteger i = 0; i < count; i++) {
			NSString* key = [keys objectAtIndex:i];
			NSArray* array = [names objectForKey:key];
			NSInteger len = [array count];
			for (NSInteger j = 0;j < len; j++) {
				[selectNames setObject:value forKey:[NSString stringWithFormat:@"%dX%d",i,j]];
			}
		}
	}
}

-(void)initPeoples{
	//ABAddressBookRef addressBook = ABAddressBookCreate();
//    ABAddressBookRef addressBook = nil;
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
    }else{
        addressBook = ABAddressBookCreate();
    }
    
	self.sourceArray = [(NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook) autorelease];
	NSUInteger count = [sourceArray count];
    if (!self.keyArray) {
        self.keyArray = [[[NSMutableArray alloc] initWithCapacity:count] autorelease];
    }
	for(NSUInteger i = 0;i < count;i++)
	{
		ABRecordRef record = [sourceArray objectAtIndex:i];
		if (record) {
			NSString *name = (NSString *)ABRecordCopyCompositeName(record);
			char letter = [name ChinesePinyinHeadLetter];
            [name release];
			[keyArray insertObject:[[[NSString alloc] initWithFormat:@"%c",letter] autorelease] atIndex:i];
		}
	}
	self.allPeoples = [[[NSMutableDictionary alloc] initWithCapacity:2] autorelease];
	for (NSString* key in keyArray){
		[allPeoples setObject:[[[NSMutableArray alloc] initWithCapacity:5] autorelease] forKey:key];
	}
	for (NSUInteger i = 0;i < count;i++){
		NSMutableArray* array = [allPeoples objectForKey:[keyArray objectAtIndex:i]];
		[array addObject:[sourceArray objectAtIndex:i]];
	}
	NSArray* kk = [[allPeoples allKeys] sortedArrayUsingSelector:@selector(compare:)];
    if (!self.keys) {
       NSMutableArray *array = [[NSMutableArray alloc]initWithCapacity:1];
        self.keys = array;
        [array release];
    }
    [self.keys setArray:kk];
	self.names = [allPeoples mutableDeepCopy];
	[self initSelectNames:@"0"];
//    CFRelease(addressBook);
}

#pragma mark -
#pragma mark init UIToolBar

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
	NSString *personPhone =nil;
    NSArray *phoneArray = nil;
	if (ABMultiValueGetCount(phone)>0) {
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
 	NSString *emailStr = nil;
	if (ABMultiValueGetCount(emails)>0) {
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
    NSString *companyStr=(NSString*)ABRecordCopyValue(person, kABPersonOrganizationProperty);
    if (companyStr != nil) {
		[dict setObject:companyStr forKey:UEX_JKORG];
	}else {
		[dict setObject:@"" forKey:UEX_JKORG];
	}
    [companyStr release];
    
    //title
    NSString *titleStr=(NSString*)ABRecordCopyValue(person, kABPersonJobTitleProperty);
    if (titleStr != nil) {
		[dict setObject:titleStr forKey:UEX_JKTITLE];
	}else {
		[dict setObject:@"" forKey:UEX_JKTITLE];
	}
    [titleStr release];
    
    //url
    ABMultiValueRef urls = (ABMultiValueRef)ABRecordCopyValue(person, kABPersonURLProperty);
 	NSString *urlStr = nil;
	if (ABMultiValueGetCount(urls)>0) {
		urlStr = (NSString*)ABMultiValueCopyValueAtIndex(urls, 0);
	}
    CFRelease(urls);
    if (urlStr != nil) {
		[dict setObject:urlStr forKey:UEX_JKURL];
	}else {
		[dict setObject:@"" forKey:UEX_JKURL];
	}
    [urlStr release];
    
    //note
    NSString *noteStr=(NSString*)ABRecordCopyValue(person, kABPersonNoteProperty);
    if (noteStr != nil) {
		[dict setObject:noteStr forKey:UEX_JKNOTE];
	}else {
		[dict setObject:@"" forKey:UEX_JKNOTE];
	}
    [noteStr release];
}

-(void)confirmButtonClick{
	NSArray* selectKeys = [selectNames allKeys];
	NSMutableArray* selectPeoples = [[NSMutableArray alloc] init];
	for (NSString * key in selectKeys){
		NSString* value = [selectNames objectForKey:key];
		if ([value intValue] == 1) {
			NSArray * array = [key componentsSeparatedByString:@"X"];
			if([array count] == 2)
			{
				NSInteger section = [[array objectAtIndex:0] intValue];
				NSInteger row = [[array objectAtIndex:1] intValue];
				NSInteger ck = [keys count];
				if (section < ck) {
					NSString * k = [keys objectAtIndex:section];
					NSArray * ar = [names objectForKey:k];
					NSInteger cv = [ar count];
					if (ar && row < cv) {
						NSMutableDictionary* selectPeople = [[NSMutableDictionary alloc] initWithCapacity:3];
						ABRecordRef person = [ar objectAtIndex:row];
                        //返回数据
                        [self setDataDict:person withInDict:selectPeople];
						[selectPeoples addObject:selectPeople];
						[selectPeople release];
					}					
				}
			}
		}
	}
    NSString *resultJson = nil;
    if ([selectPeoples count]>0) {
        resultJson = [selectPeoples JSONFragment];
    }
    NSLog(@"jsstr = %@",resultJson);
    [selectPeoples release];
    [self doCallBack:resultJson];
    
	[self dismissModalViewControllerAnimated:YES];
}
-(void)allSelectButtonClick{
	[self initSelectNames:@"1"];
	[table reloadData];
}
-(void)CancelAllSelectButtonClick{
	[self initSelectNames:@"0"];
	[table reloadData];
}
-(void)nullButtonClick{	
}

-(void)initToolbar{
	//CGFloat width =  self.view.frame.size.width;
	CGSize size = [[UIScreen mainScreen] bounds].size;
    int autoSize = 0;
    float systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    int style = UIBarStyleDefault;
    if (systemVersion < 7.0) {
        autoSize = 108;
        style =UIBarButtonItemStyleBordered;
    }else{
        autoSize = 40;
        style = UIBarStyleDefault;
    }
	toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, size.height-autoSize, size.width, 40)];
	toolBar.barStyle = style;
	toolBar.backgroundColor = [UIColor clearColor];
//	toolBar.barStyle = UIBarButtonItemStylePlain;
	[toolBar sizeToFit];
	toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;//这句作用是切换时宽度自适应.
    
    UIBarButtonItem *allSelectBarItem = [[[UIBarButtonItem alloc] init] autorelease];
    [allSelectBarItem setTitle:@"全选"];
    [allSelectBarItem setStyle:UIBarButtonItemStyleBordered];
    [allSelectBarItem setTarget:self];
    [allSelectBarItem setAction:@selector(allSelectButtonClick)];
    
    UIBarButtonItem *cancelSelectBarItem = [[[UIBarButtonItem alloc] init] autorelease];
    [cancelSelectBarItem setTitle:@"取消全选"];
    [cancelSelectBarItem setStyle:UIBarButtonItemStyleBordered];
    [cancelSelectBarItem setTarget:self];
    [cancelSelectBarItem setAction:@selector(CancelAllSelectButtonClick)];
    
    UIBarButtonItem *confirmBarItem = [[[UIBarButtonItem alloc] init] autorelease];
    [confirmBarItem setTitle:@"确定"];
    [confirmBarItem setStyle:UIBarButtonItemStyleBordered];
    [confirmBarItem setTarget:self];
    [confirmBarItem setAction:@selector(confirmButtonClick)];
    
	UIBarButtonItem* barItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:@selector(nullButtonClick)] autorelease];
    
    NSArray *array = [[[NSArray alloc] initWithObjects:allSelectBarItem, barItem, cancelSelectBarItem, barItem, confirmBarItem,nil] autorelease];
	[toolBar setItems:array];
	[self.view addSubview:toolBar];
}

#pragma mark -
#pragma mark UISearchBarDelegate
- (void)resetSearch {
	self.names = [allPeoples mutableDeepCopy];
	NSLog(@"%@",names);
	NSArray* kk = [[allPeoples allKeys] sortedArrayUsingSelector:@selector(compare:)];
	keys = [[NSMutableArray alloc]initWithArray:kk];
	if (isEditableOrNot) {
		[self initSelectNames:@"0"];
	}
}

- (void)handleSearchForTerm:(NSString *)searchTerm {
    NSMutableArray *sectionsToRemove = [[NSMutableArray alloc] init];
    [self resetSearch];
	
    for (NSString *key in keys) {
		NSLog(@"%@",key);
        NSMutableArray *array = [names valueForKey:key];
        NSMutableArray *toRemove = [[NSMutableArray alloc] init];
		NSInteger count = [array count];
		for (NSUInteger i = 0;i < count;i++){
//			NSMutableArray* array = [allPeoples objectForKey:[keyArray objectAtIndex:i]];
			ABRecordRef record = [array objectAtIndex:i];
			NSString* name = (NSString *)ABRecordCopyCompositeName(record);
			NSLog(@"%@",name);
            if ([name rangeOfString:searchTerm options:NSCaseInsensitiveSearch].location == NSNotFound)
			{
				if ([[name ChinesePinyin] rangeOfString:searchTerm options:NSCaseInsensitiveSearch].location == NSNotFound) {
					[toRemove addObject:(void*)record];	
				}				
			}
            [name release];
		}
        if ([array count] == [toRemove count])
            [sectionsToRemove addObject:key];
		
        [array removeObjectsInArray:toRemove];
        [toRemove release];
    }
    [keys removeObjectsInArray:sectionsToRemove];
    [sectionsToRemove release];
    [table reloadData];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	searchBar.text = @"";
	[self resetSearch];
	[table reloadData];
	[searchBar setShowsCancelButton:NO animated:YES];
	[searchBar resignFirstResponder];
}
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
	[searchBar resignFirstResponder];
	//开始搜索
	NSString *keyWord = searchBar.text;
	[self handleSearchForTerm:keyWord];
}

-(BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar{
	[searchBar setShowsCancelButton:YES animated:YES];
	return YES;
} 

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
	if ([searchText length] == 0) {
		[self resetSearch];
		[table reloadData];
		return;
	}
	[self handleSearchForTerm:searchText];
}

- (void)initSearchBar{
	self.mySearchBar = [[[UISearchBar alloc]initWithFrame:CGRectMake(0,0,[UIScreen mainScreen].applicationFrame.size.width,45)] autorelease];
	mySearchBar.delegate = self;
	mySearchBar.placeholder =  @"搜索";
	[mySearchBar setTintColor:[UIColor lightGrayColor]];
	//	[mySearchBar setTintColor:[UIColor orangeColor]];
	//[self.view addSubview:mySearchBar];
	table.tableHeaderView = mySearchBar;
}
#pragma mark -
#pragma mark Init TitleBar
-(void)rightButtonClick:(id)sender{
	UIBarButtonItem* rightItemButton = (UIBarButtonItem*)sender;
    NSString *title = rightItemButton.title;
	if ([title isEqualToString:@"编辑"]) {
		rightItemButton.title = @"取消";
		isEditableOrNot = 1;
		[table setTableFooterView:[[[UIView alloc] initWithFrame:CGRectMake(0,0,[UIScreen mainScreen].applicationFrame.size.width,40)] autorelease]];
		[self initToolbar];
	}else {
		rightItemButton.title = @"编辑";
		isEditableOrNot = 0;
		[toolBar removeFromSuperview]; 
		[table setTableFooterView:[[[UIView alloc] initWithFrame:CGRectZero] autorelease]];
		[table reloadData];
	}	
	//	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)backBtnClicked{
	[self dismissModalViewControllerAnimated:YES];
}

- (void)initTitleBar{
	UILabel * titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	titleLabel.backgroundColor = [UIColor clearColor];
	titleLabel.opaque = NO;
    float systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (systemVersion < 7.0) {
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.highlightedTextColor = [UIColor whiteColor];
    }else{
        titleLabel.textColor = [UIColor blackColor];
        titleLabel.highlightedTextColor = [UIColor blackColor];
    }
	titleLabel.font = [UIFont boldSystemFontOfSize:18];
	titleLabel.frame = CGRectMake(0.0, 0.0,160, 22.0);
	titleLabel.text = @"所有联系人";
	titleLabel.textAlignment = UITextAlignmentCenter;
	self.navigationItem.titleView = titleLabel;
    [titleLabel release];
//	self.navigationItem.title = @"所有联系人";
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStyleBordered target:self action:@selector(backBtnClicked)] autorelease];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"编辑" style:UIBarButtonItemStyleBordered target:self action:@selector(rightButtonClick:)] autorelease];
	self.navigationController.navigationBar.tintColor = [UIColor blackColor];  
}

#pragma mark -
#pragma mark Initialization
/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/


#pragma mark -
#pragma mark View lifecycle
 
- (void)viewDidLoad {
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor clearColor];
    CGRect rect;
    float systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (systemVersion < 7.0) {
        rect = CGRectMake(0.0, 0.0, [UIScreen mainScreen].applicationFrame.size.width, [UIScreen mainScreen].bounds.size.height-65);
    }else{
        rect = CGRectMake(0.0, 0.0, [UIScreen mainScreen].applicationFrame.size.width, [UIScreen mainScreen].bounds.size.height);
    }
	table = [[UITableView alloc]initWithFrame:rect style:UITableViewStylePlain];
	table.delegate = self;
	table.dataSource = self;
//	table.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:table];
	[self initPeoples];
	[self initTitleBar];
	[self initSearchBar];
    
    //一开始就处于编辑状态
    [self performSelector:@selector(rightButtonClick:) withObject:self.navigationItem.rightBarButtonItem afterDelay:0.5];
}


/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return [keys count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (keys && names) {
        NSString* key = [keys objectAtIndex:section];
        NSArray* value = [names objectForKey:key];
        NSLog(@"%@",value);
        return [value count];
    }else{
        return 0;
    }
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		//cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

	NSInteger row = [indexPath row];
	NSInteger section = [indexPath section];
	NSString* key = [keys objectAtIndex:section];
	NSArray* value = [names objectForKey:key];
	ABRecordRef record = [value objectAtIndex:row];
	if (record) {
		NSString *nameStr = (NSString *)ABRecordCopyCompositeName(record);
		cell.textLabel.text = nameStr;
        [nameStr release];
	}
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	if(isEditableOrNot) {  
		NSString* bk = [NSString stringWithFormat:@"%dX%d",section,row];
		NSString* bString = [selectNames objectForKey:bk];
		NSInteger b = bString ? [bString intValue]:0;
		if (b) {
			UIImage *image = [UIImage imageWithContentsOfFile:[[UEX_BUNDLE resourcePath] stringByAppendingPathComponent: @"plugin_contact_selected.png"]];
			UIImageView* imageView = [[UIImageView alloc] initWithImage:image];
			cell.accessoryView = imageView;
            [imageView release];
		}
		else {
			cell.accessoryView = nil;
		}
	}else {
		cell.accessoryView = nil;
	}
    return cell;
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
//{
//	return [keys objectAtIndex:section];	
//}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section 
{ 
	UIView* customView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, tableView.bounds.size.width, 22.0)] autorelease];
	
	UILabel * headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	headerLabel.backgroundColor = [UIColor grayColor];
	headerLabel.opaque = NO;
	headerLabel.textColor = [UIColor whiteColor];
	headerLabel.highlightedTextColor = [UIColor whiteColor];
	headerLabel.font = [UIFont boldSystemFontOfSize:20];
	headerLabel.frame = CGRectMake(0.0, 0.0,tableView.bounds.size.width, 22.0);
	headerLabel.text = [keys objectAtIndex:section];
	[customView addSubview:headerLabel];
    [headerLabel release];
	return customView;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if(isEditableOrNot && selectNames) {  
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		NSString* key = [NSString stringWithFormat:@"%dX%d",indexPath.section,indexPath.row];
		NSString* bString = [selectNames objectForKey:key];
		NSInteger b = bString ? [bString intValue]:0;
		if (b) {
			cell.accessoryView = nil;
			[selectNames setObject:@"0" forKey:key];
			NSArray* array = [NSArray arrayWithObject:indexPath];
			[tableView reloadRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationNone];
		}
		else {
			UIImage *image = [UIImage imageWithContentsOfFile:[[UEX_BUNDLE resourcePath] stringByAppendingPathComponent: @"plugin_contact_selected.png"]];
			UIImageView* imageView = [[UIImageView alloc] initWithImage:image];
			cell.accessoryView = imageView;
            [imageView release];
			[selectNames setObject:@"1" forKey:key];
		} 

	}
}


// // Override to support conditional editing of the table view.
// - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
// // Return NO if you do not want the specified item to be editable.
// return YES;
// }


//- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return UITableViewCellEditingStyleDelete | UITableViewCellEditingStyleInsert;
//}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
	[table release];
	[sourceArray release];
	[keyArray release];
	[allPeoples release];
	[keys release];
	[names release];
	[selectNames release];
	[mySearchBar release];
	[toolBar release];
	[callBack release];
    CFRelease(addressBook);
    [super dealloc];
}


@end

