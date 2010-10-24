// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import "GPS.h"

#import "macro.h"

#define _KEY_PATH			@"last_pos"

@interface GPS ()
@end

@implementation GPS

static GPS *g_;

@synthesize last_pos = last_pos_;

/** Returns the pointer to the singleton GPS class.
 * The class will be constructed if necessary.
 */
+ (GPS*)get
{
	if (!g_)
		g_ = [GPS new];

	return g_;
}

/** Converts a coordinate from degrees to decimal minute second format.
 * Specify with the latitude bool if you are converting the latitude
 * part of the coordinates, which has a different letter.
 *
 * \return Returns the string with the formated value as Dº M' S"
 * X, where X is a letter and D M S are numbers.
 */
+ (NSString*)degrees_to_dms:(CLLocationDegrees)value latitude:(BOOL)latitude
{
	const int degrees = fabsl(value);
	const double min_rest = (fabs(value) - degrees) * 60.0;
	const int minutes = min_rest;
	const double seconds = (min_rest - minutes) * 60.0;
	char letter = 0;
	if (latitude) {
		if (value > 0)
			letter = 'N';
		else if (value < 0)
			letter = 'S';
	} else {
		if (value > 0)
			letter = 'E';
		else if (value < 0)
			letter = 'W';
	}
	if (letter)
		return [NSString stringWithFormat:@"%dº %d' %0.2f\" %c",
			degrees, minutes, seconds, letter];
	else
		return [NSString stringWithFormat:@"%dº %d' %0.2f\"",
			degrees, minutes, seconds];
}

/** Initialises the GPS class.
 */
- (id)init
{
	if (!(self = [super init]))
		return nil;

	manager_ = [[CLLocationManager alloc] init];
	if (!manager_) {
		LOG(@"Couldn't instantiate CLLocationManager!");
		return nil;
	}

	// Set a filter for 5m.
	manager_.distanceFilter = 5;

	// Try to get the best accuracy possible.
	manager_.desiredAccuracy = kCLLocationAccuracyBest;
	manager_.delegate = self;

	return self;
}

/** Starts the GPS tracking.
 * Returns false if the location services are not available.
 */
- (bool)start
{
	if (manager_.locationServicesEnabled) {
		[manager_ startUpdatingLocation];
		return true;
	} else {
		return false;
	}
}

/** Stops the GPS tracking.
 * You can call this function anytime, doesn't really fail.
 */
- (void)stop
{
	[manager_ stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager*)manager
		didUpdateToLocation:(CLLocation*)new_location
		fromLocation:(CLLocation*)old_location
{
	DLOG(@"Updating to %@", [new_location description]);

	if (new_location.horizontalAccuracy < 0) {
		DLOG(@"Bad returned accuracy, ignoring update.");
		return;
	}

	// Keep the new location for map showing.
	[self willChangeValueForKey:_KEY_PATH];
	[new_location retain];
	[last_pos_ release];
	last_pos_ = new_location;
	[self didChangeValueForKey:_KEY_PATH];
}

/** Returns the string used by add_watcher: and removeObserver:.
 */
+ (NSString*)key_path
{
	return _KEY_PATH;
}

/** Registers an observer for changes to last_pos.
 * Observers will monitor the key_path value.
 */
- (void)add_watcher:(id)watcher
{
	[self addObserver:watcher forKeyPath:_KEY_PATH
		options:NSKeyValueObservingOptionNew context:nil];
}

/** Removes an observer for changes to last_pos.
 */
- (void)remove_watcher:(id)watcher
{
	[self removeObserver:watcher forKeyPath:_KEY_PATH];
}

@end
