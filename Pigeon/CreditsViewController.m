//
//  CreditsViewController.m
//  Pigeon
//
//  Created by James Bucanek on 2/14/14.
//  Copyright (c) 2014 James Bucanek. See LICENSE.txt.
//

#import "CreditsViewController.h"


static void OpenAnURL( NSString *url );

//@interface CreditsViewController ()
//@end

@implementation CreditsViewController

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

//- (void)viewDidLoad
//{
//    [super viewDidLoad];
//	// Do any additional setup after loading the view.
//}

//- (void)didReceiveMemoryWarning
//{
//    [super didReceiveMemoryWarning];
//    // Dispose of any resources that can be recreated.
//}

- (IBAction)linkToBook:(id)sender
{
	OpenAnURL(@"http://x.co/iosappdev");
}

- (IBAction)linkToGitHub:(id)sender
{
	OpenAnURL(@"http://x.co/gitpigeon");
}

@end

static void OpenAnURL( NSString *url )
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}
