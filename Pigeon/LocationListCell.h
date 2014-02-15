//
//  LocationListCell.h
//  Pigeon
//
//  Created by James Bucanek on 12/21/13.
//  Copyright (c) 2013 James Bucanek. See LICENSE.txt.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class SavedLocation;

//
// A table row cell in the locations list.
//

@interface LocationListCell : UITableViewCell

@property (strong,nonatomic) SavedLocation*		location;

@property (weak,nonatomic) IBOutlet MKMapView*	mapView;
@property (weak,nonatomic) IBOutlet UILabel*	dateLabel;
@property (weak,nonatomic) IBOutlet UILabel*	titleLabel;
@property (weak,nonatomic) IBOutlet UILabel*	distanceLabel;

@end
