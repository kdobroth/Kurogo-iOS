#import "KGOCategoryListViewController.h"
#import "KGOSearchModel.h"
#import "KGOMapCategory.h"
#import "KGOEventCategory.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "KGOTheme.h"
#import "CoreDataManager.h"
#import "Foundation+KGOAdditions.h"
#import "KGOPlacemark.h"
#import "KGOEvent.h"

@implementation KGOCategoryListViewController

@synthesize parentCategory, categoriesRequest, categoryEntityName, leafItemsRequest, leafItemEntityName;

- (void)loadView {
	[super loadView];
    
    self.title = NSLocalizedString(@"Browse", nil);

    UITableViewStyle style;
    if (self.categories || self.categoriesRequest) {
        style = UITableViewStyleGrouped;
    } else {
        style = UITableViewStylePlain;
    }
	
	if (!self.tableView) {
		CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
		self.tableView = [self addTableViewWithFrame:frame style:style];
	}
    
    if (!self.categories && self.categoriesRequest) {
        [self.categoriesRequest connect];
        
    } else if (!self.leafItems && self.leafItemsRequest) {
        [self.leafItemsRequest connect];
    }
}

- (NSArray *)categories {
	return _categories;
}

- (void)setCategories:(NSArray *)categories {
	[_categories release];
	_categories = [categories retain];
	
	if ([self isViewLoaded]) {
		[self reloadDataForTableView:self.tableView];
	}
}

- (NSArray *)leafItems {
	return _leafItems;
}

- (void)setLeafItems:(NSArray *)leafItems {
	[_leafItems release];
	_leafItems = [leafItems retain];
	
	if ([self isViewLoaded]) {
		[self reloadDataForTableView:self.tableView];
	}
}

- (UIView *)headerView {
	return _headerView;
}

- (void)setHeaderView:(UIView *)headerView {
	[_headerView release];
	_headerView = [headerView retain];
	self.tableView.tableHeaderView = _headerView;
}

#pragma KGORequestDelegate

- (void)request:(KGORequest *)request didHandleResult:(NSInteger)returnValue {
    if (request == self.categoriesRequest) {    
        self.categoriesRequest = nil;
        
        NSArray *categories = nil;
        if (self.parentCategory == nil) {
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"parentCategory = NULL"];
            categories = [[CoreDataManager sharedManager] objectsForEntity:self.categoryEntityName matchingPredicate:pred];
        } else {
            categories = [self.parentCategory children];
        }
        
        self.categories = categories;

    } else if (request == self.leafItemsRequest) {
        self.leafItems = self.parentCategory.items;
    }

    [self reloadDataForTableView:self.tableView];
}

- (void)requestWillTerminate:(KGORequest *)request {
    if (request == self.categoriesRequest) {
        self.categoriesRequest = nil;
    } else if (request == self.leafItemsRequest) {
        self.leafItemsRequest = nil;
    }
}

#pragma mark Table view methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = 0;
    if (self.categories) {
        count = self.categories.count;
    } else if (self.leafItems) {
        count = self.leafItems.count;
    }
    return count;
}

- (KGOTableCellStyle)tableView:(UITableView *)tableView styleForCellAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellStyleDefault;
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath {
    NSString *title = nil;
    NSString *accessory = nil;
    
    if (self.categories) {        
        id<KGOCategory> category = [self.categories objectAtIndex:indexPath.row];
        title = category.title;
        accessory = KGOAccessoryTypeChevron;

    } else if (self.leafItems) {
        id<KGOSearchResult> leafItem = [self.leafItems objectAtIndex:indexPath.row];
        title = leafItem.title;
        //accessory = KGOAccessoryTypeChevron;
    }
    
    return [[^(UITableViewCell *cell) {
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.textLabel.text = title;
        cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:accessory];
    } copy] autorelease];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *moduleTag = nil;
    if (self.categories) {
        id<KGOCategory> category = [self.categories objectAtIndex:indexPath.row];
        // TODO: need better way to get module tag
        if ([category isKindOfClass:[KGOMapCategory class]]) {
            moduleTag = MapTag;
        } else if ([category isKindOfClass:[KGOEventCategory class]]) {
            moduleTag = CalendarTag;
        }
        
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:category, @"parentCategory", nil];
        if (category.children) {
            [params setObject:category.children forKey:@"categories"];
            
        } else if (category.items) {
            [params setObject:category.items forKey:@"items"];
        }
        [(KGOAppDelegate *)[[UIApplication sharedApplication] delegate] showPage:LocalPathPageNameCategoryList forModuleTag:moduleTag params:params];
        
    } else if (self.leafItems) {
        id<KGOSearchResult> leafItem = [self.leafItems objectAtIndex:indexPath.row];
        // TODO: need better way to get module tag
        if ([leafItem isKindOfClass:[KGOPlacemark class]]) {
            moduleTag = MapTag;
        } else if ([leafItem isKindOfClass:[KGOEvent class]]) {
            moduleTag = CalendarTag;
        }
        
        NSString *identifier = leafItem.identifier;
        NSString *query = [NSString stringWithFormat:@"identifier = %@", identifier];
        NSURL *url = [NSURL internalURLWithModuleTag:moduleTag path:LocalPathPageNameSearch query:query];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

#pragma mark -

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    self.categoriesRequest.delegate = nil;
    self.categoriesRequest = nil;
    
    self.leafItemsRequest.delegate = nil;
    self.leafItemsRequest = nil;
    
	self.headerView = nil;
	self.categories = nil;
    self.leafItems = nil;
    
    self.categoryEntityName = nil;
    self.leafItemEntityName = nil;
    
    [super dealloc];
}

@end