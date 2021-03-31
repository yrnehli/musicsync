# musicsync
A CLI tool that lets you import/remove from your music library using a JSON file. Useful for mass imports/removals.

Usage: `musicsync <json path>`

If for whatever reason you need to reset your iOS music library, you can do so with the following steps:
- Before deleting the files below, make sure to do a **backup** of them.
- Delete the folder `/var/mobile/Media/iTunes_Control/Music`
- Delete `/var/mobile/Media/iTunes_Control/iTunes/MediaLibrary.sqlitedb`
- Delete `/var/mobile/Media/iTunes_Control/iTunes/MediaLibrary.sqlitedb-shm`
- Delete `/var/mobile/Media/iTunes_Control/iTunes/MediaLibrary.sqlitedb-wal`
- Delete the files inside `/var/mobile/Media/iTunes_Control/Sync/Media`
- Respring
- Open Music App

Tested on iPhone X, 13.5.1 - compatibility for other devices/iOS unknown.

---
### JSON Format
| Key | Type | Value |
| ----------- | ----------- | ----------- |
| import | Array  | `ImportItem` objects |
| remove | Array | `RemoveFilterItem` objects |

If you don't want to import/remove you can just use an empty array for either key.

**Example JSON:**
```json
{
	"remove": [
		{
			"artist": "Isaiah Rashad",
			"title": "Shot You Down"
		}
	],
	"import": [
		{
			"url": "http:\/\/192.168.4.50:11111\/sync\/mp3\/Runaway.mp3",
			"artworkUrl": "http:\/\/192.168.4.50:11111\/sync\/artwork\/Runaway.jpg",
			"artist": "Kanye West, Pusha T",
			"duration": 548002,
			"discNumber": 1,
			"trackNumber": 9,
			"year": 2010,
			"genre": "Hip-Hop\/Rap",
			"title": "Runaway",
			"album": "My Beautiful Dark Twisted Fantasy",
			"albumArtist": "Kanye West"
		}
	]
}
```

---
### ImportItem
| Key | Type| Value |
| ----------- | ----------- | ----------- |
| url | String | URL of the song file |
| artworkUrl | String | URL of the artwork for the song |
| artist | String | Song artist |
| duration | Integer | Song duration in ms |
| discNumber | Integer | Disc number of the song |
| trackNumber | Integer | Track number of the song |
| year | Integer | Year of the song |
| genre | String | Genre of the song |
| title | String | Title of the song |
| album | String | Album of the song |
| albumArtist | String | Album artist of the song |
---
### RemoveFilterItem
| Key | Type| Value |
| ----------- | ----------- | ----------- |
| artist | String | Artist to filter by |
| album | String | Album to filter by |
| title | String | Title to filter by |

Any of these keys can be omitted, for example if you only want to filter by `title` your `RemoveFilterItem` object JSON could look like this:
```json
{
	"title": "Bandana"
}
```
If you want to remove all songs you can simply use an empty `RemoveFilterItem` object:
```json
{}
```

---
Made with help from open source projects:
- TimerCL (dado3212)
- MImport (julioverne)
- Notifica (NepetaDev)
