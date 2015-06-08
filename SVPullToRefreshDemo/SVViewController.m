//
//  SVViewController.m
//  SVPullToRefreshDemo
//
//  Created by Sam Vermette on 23.04.12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "SVViewController.h"
#import "SVPullToRefresh.h"
#import "AFNetworking.h"
#import "AFNetworkReachabilityManager.h"
#import "AFHTTPRequestOperationManager.h"

static int initialPage = 1;

@interface SVViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, assign) int currentPage;

@end

@implementation SVViewController
@synthesize tableView = tableView;
@synthesize currentPage = _currentPage;


- (void)viewDidLoad {
    [super viewDidLoad];
//    [self setupDataSource];
   self.dataSource = [NSMutableArray array];
    self.currentPage = initialPage;
    
    __weak SVViewController *weakSelf = self;
    
//    // setup pull-to-refresh
//    [self.tableView addPullToRefreshWithActionHandler:^{
//        [weakSelf insertRowAtTop];
//    }];
//        
//    // setup infinite scrolling
//    [self.tableView addInfiniteScrollingWithActionHandler:^{
//        [weakSelf insertRowAtBottom];
//    }];
    
    
    
    // refresh new data when pull the table list
//    [self.tableView addPullToRefreshWithActionHandler:^{
//       
//    }];
    
    weakSelf.currentPage = initialPage; // reset the page
    [weakSelf.dataSource removeAllObjects]; // remove all data
    [weakSelf.tableView reloadData]; // before load new content, clear the existing table list
    [weakSelf loadFromServer]; // load new data
    [weakSelf.tableView.pullToRefreshView stopAnimating]; // clear the animation
    
    // once refresh, allow the infinite scroll again
    weakSelf.tableView.showsInfiniteScrolling = YES;
    
    // load more content when scroll to the bottom most
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        [weakSelf loadFromServer];
    }];
}

- (void)loadFromServer
{
    NSInteger start = _currentPage*5-5;
    NSInteger end = start+5;
    NSLog(@"start...%d,,,End...%d",start,end);
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:@"AiK58j67" forKey:@"api_key"];
    [dict setValue:@"a#9rJkmbOea90-" forKey:@"api_secret"];
    [dict setValue:@"naveendungarwal2009@gmail.com" forKey:@"email"];
    [dict setValue:@"12.23" forKey:@"lat"];
    [dict setValue:@"72.54" forKey:@"lon"];
    [dict setValue:@"99999" forKey:@"radius"];
    [dict setValue:[NSString stringWithFormat:@"%ld",(long)start] forKey:@"start"];
    [dict setValue:[NSString stringWithFormat:@"%ld",(long)end] forKey:@"end"];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"application/json"];
    
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/json"];
    
     manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];

    
    [manager POST:[NSString stringWithFormat:@"http://buddysin.aumkiiyo.com/api/nearby/share"] parameters:dict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *responseDict  = (NSDictionary*)responseObject;
        NSDictionary *buddysDict = [responseDict valueForKey:@"share"];
        // if no more result
        if ([[buddysDict objectForKey:@"data"] count] == 0) {
            self.tableView.showsInfiniteScrolling = NO; // stop the infinite scroll
            return;
        }
        
        _currentPage++; // increase the page number
        NSInteger currentRow = [self.dataSource count]; // keep the the index of last row before add new items into the list
        
        // store the items into the existing list
        for (id obj in [buddysDict valueForKey:@"data"]) {
            [self.dataSource addObject:obj];
        }
        [self reloadTableView:currentRow];
        
        // clear the pull to refresh & infinite scroll, this 2 lines very important
    
        [self.tableView.pullToRefreshView stopAnimating];
        [self.tableView.infiniteScrollingView stopAnimating];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.tableView.showsInfiniteScrolling = NO;
        NSLog(@"error %@", error);
    }];
}

- (void)reloadTableView:(NSInteger)startingRow;
{
    NSLog(@"curren row..%ld",(long)startingRow);
    // the last row after added new items
    NSInteger endingRow = [self.dataSource count];
    
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (; startingRow < endingRow; startingRow++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:startingRow inSection:0]];
    }
    
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [tableView triggerPullToRefresh];
}

#pragma mark - Actions

- (void)setupDataSource {
    self.dataSource = [NSMutableArray array];
    for(int i=0; i<15; i++)
        [self.dataSource addObject:[NSDate dateWithTimeIntervalSinceNow:-(i*90)]];
}

- (void)insertRowAtTop {
    __weak SVViewController *weakSelf = self;

    int64_t delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [weakSelf.tableView beginUpdates];
        [weakSelf.dataSource insertObject:[NSDate date] atIndex:0];
        [weakSelf.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
        [weakSelf.tableView endUpdates];
        
        [weakSelf.tableView.pullToRefreshView stopAnimating];
    });
}


- (void)insertRowAtBottom {
    __weak SVViewController *weakSelf = self;

    int64_t delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [weakSelf.tableView beginUpdates];
        [weakSelf.dataSource addObject:[weakSelf.dataSource.lastObject dateByAddingTimeInterval:-90]];
        [weakSelf.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:weakSelf.dataSource.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
        [weakSelf.tableView endUpdates];
        
        [weakSelf.tableView.infiniteScrollingView stopAnimating];
    });
}
#pragma mark -
#pragma mark UITableViewDataSource

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 200;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    static NSString *identifier = @"Cell";
//    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
//    
//    if (cell == nil)
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
//    
//    NSDate *date = [self.dataSource objectAtIndex:indexPath.row];
//    cell.textLabel.text = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle];
//    return cell;
//}


#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = [self.dataSource objectAtIndex:indexPath.row];
    NSLog(@"Selected item %@", item);
}


- (UITableViewCell *)tableView:(UITableView *)tableViewObj cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"MyListCell";
    UITableViewCell *cell = [tableViewObj dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    // minus 1 because the first row is the search bar
    id item = [self.dataSource objectAtIndex:indexPath.row];
    
    NSDictionary*share  = [item valueForKey:@"shares"];
    cell.textLabel.text = [share valueForKey:@"content"];
    
    return cell;
}




@end
