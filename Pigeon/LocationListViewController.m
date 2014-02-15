//
//  LocationListViewController.m
//  Pigeon
//
//  Created by James Bucanek on 12/20/13.
//  Copyright (c) 2013 Dawn to Dusk Software. All rights reserved.
//

#import "LocationListViewController.h"

#import "AppDelegate.h"
#import "LocationListCell.h"
#import "MKMapView+MapPanning.h"


@interface LocationListViewController ()

@end

@implementation LocationListViewController

//- (id)initWithStyle:(UITableViewStyle)style
//{
//    self = [super initWithStyle:style];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

- (void)dealloc
{
    [_data removeObserver:self forKeyPath:@"locations"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Grab a copy of the global data model object
	_data = [LocationData sharedData];
	
	// Observe changes to the set of locations
	[_data addObserver:self forKeyPath:@"locations" options:0 context:NULL];
	
	// self.clearsSelectionOnViewWillAppear = NO;
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

//- (NSUInteger)supportedInterfaceOrientations
//{
//	return UIInterfaceOrientationMaskAll;
//}

//- (void)didReceiveMemoryWarning
//{
//    [super didReceiveMemoryWarning];
//    // Dispose of any resources that can be recreated.
//}

#pragma mark <UITableViewDataSource>

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//#warning Potentially incomplete method implementation.
//    // Return the number of sections.
//    return 0;
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _data.locations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellID = @"location";
    LocationListCell* cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    
	SavedLocation* location = _data.locations[indexPath.row];
	cell.accessoryType = ( location==_data.activeLocation ? UITableViewCellAccessoryCheckmark
														  : UITableViewCellAccessoryNone );
	cell.location = location;
	
    return cell;
}

#pragma mark <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Change the active location to the one just tapped
	[_data setActiveLocationAtIndex:indexPath.row];
	// Return to the map and show the new location
	[self.navigationController popViewControllerAnimated:YES];
}

//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    // Return NO if you do not want the specified item to be editable.
//    return YES;
//}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Edit the table
    if (editingStyle == UITableViewCellEditingStyleDelete)
		{
        // Delete the row
		[tableView beginUpdates];
		[_data removeLocationAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
		[tableView endUpdates];
		}
//    else if (editingStyle == UITableViewCellEditingStyleInsert)
//		{
//        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//		}
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
	// Rearrange the table
	[_data moveLocationAtIndex:fromIndexPath.row toIndex:toIndexPath.row];
}

#pragma mark Data Model

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	// we only observe the locations; if it changes, reload the list
	[self.tableView reloadData];
}

@end
