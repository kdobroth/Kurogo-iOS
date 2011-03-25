#import "KGOPortletHomeViewController.h"
#import "KGOHomeScreenWidget.h"
#import "SpringboardIcon.h"
#import "KGOModule.h"
#import "IconGrid.h"

@implementation KGOPortletHomeViewController

- (void)loadView {
    [super loadView];
    
    CGFloat topFreePixel;
    CGFloat bottomFreePixel;
    
    // TODO: if we support rotation, we'll need to selectively hide widgets
    _visibleWidgets = [[self allWidgets:&topFreePixel :&bottomFreePixel] retain];
    
    _iconGrid = [[[IconGrid alloc] initWithFrame:CGRectMake(0, topFreePixel,
                                                            self.view.frame.size.width,
                                                            bottomFreePixel - topFreePixel)] autorelease];
    _iconGrid.padding = [self moduleListMargins];
    _iconGrid.spacing = [self moduleListSpacing];
    _iconGrid.icons = [self iconsForPrimaryModules:YES];
    [self.view addSubview:_iconGrid];

    for (KGOHomeScreenWidget *aWidget in _visibleWidgets) {
       [self.view addSubview:aWidget];
    }
}

- (void)refreshModules {
    _iconGrid.icons = [self iconsForPrimaryModules:YES];
    [_iconGrid setNeedsLayout];
}

- (void)refreshWidgets {
    for (KGOHomeScreenWidget *aWidget in _visibleWidgets) {
        [aWidget removeFromSuperview];
    }

    [_visibleWidgets release];
    CGFloat topFreePixel;
    CGFloat bottomFreePixel;
    _visibleWidgets = [[self allWidgets:&topFreePixel :&bottomFreePixel] retain];

    for (KGOHomeScreenWidget *aWidget in _visibleWidgets) {
        [self.view addSubview:aWidget];
    }
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

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
    [_visibleWidgets release];
    [_iconGrid release];
    [super dealloc];
}


@end
