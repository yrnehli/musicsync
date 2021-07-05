#import "Tweak.h"

extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter();

static BBServer *bbServer = nil;

static dispatch_queue_t getBBServerQueue() {
	static dispatch_queue_t queue;
	static dispatch_once_t predicate;

	dispatch_once(&predicate, ^{
		void *handle = dlopen(NULL, RTLD_GLOBAL);
		if (handle) {
			dispatch_queue_t __weak *pointer = (__weak dispatch_queue_t *) dlsym(handle, "__BBServerQueue");
			if (pointer) {
				queue = *pointer;
			}
			dlclose(handle);        
		}
	});

	return queue;
}

static void pushNotification(NSString *title, NSString *message) {
	BBBulletin *bulletin = [[%c(BBBulletin) alloc] init];

	bulletin.title = title;
	bulletin.message = message;
	bulletin.sectionID = @"com.apple.Music";
	bulletin.bulletinID = [[NSProcessInfo processInfo] globallyUniqueString];
	bulletin.recordID = [[NSProcessInfo processInfo] globallyUniqueString];
	bulletin.publisherBulletinID = [[NSProcessInfo processInfo] globallyUniqueString];
	bulletin.date = [NSDate date];
	bulletin.defaultAction = [%c(BBAction) actionWithLaunchBundleID:bulletin.sectionID callblock:nil];

	if ([bbServer respondsToSelector:@selector(publishBulletin:destinations:alwaysToLockScreen:)]) {
		dispatch_sync(getBBServerQueue(), ^{
			[bbServer publishBulletin:bulletin destinations:14 alwaysToLockScreen:YES];
		});
	} else if ([bbServer respondsToSelector:@selector(publishBulletin:destinations:)]) {
		dispatch_sync(getBBServerQueue(), ^{
			[bbServer publishBulletin:bulletin destinations:14];
		});
	}
}

void import(NSArray *importEntries) {
	SSDownloadManager* downloadManager = [SSDownloadManager IPodDownloadManager];	
	NSMutableArray *downloads = [[NSMutableArray alloc] init];

	for (NSDictionary *importEntry in importEntries) {	
		NSString *url = [importEntry objectForKey:@"url"];
		NSString *artworkUrl = [importEntry objectForKey:@"artworkUrl"];
		NSString *artist = [importEntry objectForKey:@"artist"];
		NSNumber *duration = [importEntry objectForKey:@"duration"];
		NSNumber *discNumber = [importEntry objectForKey:@"discNumber"];
		NSNumber *trackNumber = [importEntry objectForKey:@"trackNumber"];
		NSNumber *year = [importEntry objectForKey:@"year"];
		NSString *genre = [importEntry objectForKey:@"genre"];
		NSString *title = [importEntry objectForKey:@"title"];
		NSString *album = [importEntry objectForKey:@"album"];
		NSString *albumArtist = [importEntry objectForKey:@"albumArtist"];
		int itemId = (arc4random() % 100000000) + 1;

		// See https://developer.apple.com/documentation/ituneslibrary
		NSDictionary *payloadImport = @{
			@"purchaseDate": [NSDate date],
			@"is-purchased-redownload": @YES,
			@"URL": url,
			@"artworkURL": artworkUrl,
			@"artwork-urls": @{
				@"default": @{
					@"url": artworkUrl,
				}, 
				@"image-type": @"download-queue-item"
			},
			@"songId": @(itemId),
			@"metadata": @{
				@"artistName": artist,
				@"compilation": @NO,
				@"drmVersionNumber": @0,
				@"duration": duration,
				@"explicit": @NO,
				@"gapless": @NO,
				@"genre": genre,
				@"isMasteredForItunes": @NO,
				@"itemId": @(itemId),
				@"itemName": title,
				@"kind": @"song",
				@"playlistArtistName": albumArtist,
				@"playlistName": album,
				@"releaseDate": [NSDate date], 
				@"sort-album": album,
				@"sort-artist": artist,
				@"sort-name": title,
				@"discNumber": discNumber,
				@"trackNumber": trackNumber,
				@"year": year
			}
		};
		
		SSDownloadMetadata *metadata = [[SSDownloadMetadata alloc] initWithDictionary:payloadImport];
		SSDownload *download = [[SSDownload alloc] initWithDownloadMetadata:metadata];

		[downloads addObject:download];
	}

	[downloadManager addDownloads:downloads completionBlock:nil];
}

void remove(NSArray *removalEntries) {
	MPMediaLibrary *library = [MPMediaLibrary defaultMediaLibrary];

	for (NSDictionary *removalEntry in removalEntries) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			NSString *artist = [removalEntry objectForKey:@"artist"];
			NSString *album = [removalEntry objectForKey:@"album"];
			NSString *title = [removalEntry objectForKey:@"title"];
			MPMediaQuery *query = [MPMediaQuery songsQuery];

			if (artist) {
				MPMediaPropertyPredicate *artistFilter = [MPMediaPropertyPredicate predicateWithValue:artist forProperty:@"artist"];
				[query addFilterPredicate:artistFilter];
			}

			if (album) {
				MPMediaPropertyPredicate *albumFilter = [MPMediaPropertyPredicate predicateWithValue:album forProperty:@"albumTitle"];
				[query addFilterPredicate:albumFilter];
			}

			if (title) {
				MPMediaPropertyPredicate *titleFilter = [MPMediaPropertyPredicate predicateWithValue:title forProperty:@"title"];
				[query addFilterPredicate:titleFilter];
			}

			[library performSelectorInBackground:@selector(deleteItems:) withObject:query.items];
		});
	}
}

void sync(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	@try {
		NSError *error = nil;
		NSString *jsonFilepath = [(__bridge NSDictionary*)userInfo objectForKey:@"jsonFilepath"];
		NSString *jsonString = [NSString stringWithContentsOfFile:jsonFilepath usedEncoding:nil error:&error];

		if (!jsonString) {
			[NSException raise:@"Invalid JSON" format:@"An error occurred when try to open/encode the JSON file. Error Details: %@", error];
		}

		NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
		NSDictionary *parsedData = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
		
		if (!parsedData) {
			[NSException raise:@"Invalid JSON" format:@"An error occurred when try to parse the JSON file. Error Details: %@", error];
		}

		remove([parsedData objectForKey:@"remove"]);
		import([parsedData objectForKey:@"import"]);
		pushNotification(@"Sync Queued", @"Your sync has successfully been queued.");
	} @catch (NSException *e) {
		pushNotification(@"Sync Failed", [NSString stringWithFormat:@"Your sync failed. This was most likely due to invalid JSON. Exception Details: %@ -> %@", e.name, e.reason]);
	}
}

%hook BBServer
- (id)initWithQueue:(id)arg1 {
	bbServer = %orig;
	return bbServer;
}

- (id)initWithQueue:(id)arg1 dataProviderManager:(id)arg2 syncService:(id)arg3 dismissalSyncCache:(id)arg4 observerListener:(id)arg5 utilitiesListener:(id)arg6 conduitListener:(id)arg7 systemStateListener:(id)arg8 settingsListener:(id)arg9 {
	bbServer = %orig;
	return bbServer;
}

- (void)dealloc {
	if (bbServer == self) {
		bbServer = nil;
	}

	%orig;
}
%end

%hook SpringBoard
- (id)init {
	CFNotificationCenterAddObserver(
		CFNotificationCenterGetDistributedCenter(),
		NULL,
		&sync,
		CFSTR("xyz.henryli17.musicsync"),
		NULL,
		CFNotificationSuspensionBehaviorDeliverImmediately
	);

	return %orig;
}
%end

%ctor {
	%init;
}