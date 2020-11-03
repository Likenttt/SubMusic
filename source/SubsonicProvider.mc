class SubsonicProvider {
	
	private var d_api;

	private var d_callback;
	private var d_fallback;
	
	function initialize(settings) {
		d_api = new SubsonicAPI(settings, self.method(:onFailed));
	}
	
	function onSettingsChanged(settings) {
		System.println("SubsonicProvider:: onSettingsChanged");
		
		d_api.update(settings);
	}
	
	// functions:
	// - getAllPlaylists - returns array of all playlists available for Subsonic user
	// - getPlaylistSongs - returns an array of songs on the playlist with id
	// - getRefId - returns a refId for a song by id (this downloads the song)
	//
	// to be added in the future (not possible for SubsonicAPI, so return allplaylists):
	// - getUpdatedPlaylists - returns array of all playlists updated since Moment
	
	/**
	 * getAllPlaylists
	 *
	 * returns array of all playlists available for Ampache user
	 */
	function getAllPlaylists(callback) {
		d_callback = callback;
		d_api.getPlaylists(self.method(:onGetAllPlaylists));
	}

	/**
	 * getPlaylist
	 *
	 * returns an array of one playlist object for id
	 */
	function getPlaylist(id, callback) {
		d_callback = callback;

		var params = {
			"id" => id,
		};
		d_api.getPlaylist(self.method(:onGetPlaylist), params);
	}
	
	/**
	 * getPlaylistSongs
	 * 
	 * returns an array of songs on the playlist with id
	 */
	function getPlaylistSongs(id, callback) {
		d_callback = callback;

		var params = {
			"id" => id,
		};

		d_api.getPlaylist(self.method(:onGetPlaylistSongs), params);
	}

	/**
	 * getRefId
	 *
	 *  returns a refId for a song by id (this downloads the song)
	 */	
	function getRefId(id, mime, callback) {
		d_callback = callback;

		var encoding = mimeToEncoding(mime);
		var format = "mp3";
		if (encoding == Media.ENCODING_INVALID) {
			// default to mp3 transcoding
			encoding = Media.ENCODING_MP3;
		} else {
			// if mime is supported, request raw
			format = "raw";
		}
		var params = {
			"id" => id,
			"format" => format,
		};
		d_api.stream(self.method(:onStream), params, encoding);
	}

	function getPodcasts(callback) {
		d_callback = callback;
		var params = {
			"includeEpisodes" => false,
		};
		d_api.getPodcasts(self.method(:onGetPodcasts), params);
	}

	function getPodcast(id, callback) {
		d_callback = callback;
		var params = {
			"id" => id,
			"includeEpisodes" => false,
		};
		d_api.getPodcasts(self.method(:onGetPodcast), params);
	}

	function getPodcastEpisodes(id, callback) {
		d_callback = callback;
		var params = {
			"id" => id,
			"includeEpisodes" => true,
		};
		d_api.getPodcasts(self.method(:onGetPodcastEpisodes), params);
	}

	// handlers

	function onGetAllPlaylists(response) {
		System.println("SubsonicProvider::onGetAllPlaylists( response = " + response + ")");
		
		// construct the standard array of playlist objects
		var playlists = [];
		// for (var idx = 0; idx < response.size(); ++idx) {
		// 	var playlist = response[idx];
		// 	playlists.add({
		// 		"id" => playlist["id"],
		// 		"name" => playlist["name"],
		// 		"songCount" => playlist["songCount"].toNumber(),
		// 	});
		// }
		
		// construct the playlist instance
		for (var idx = 0; idx < response.size(); ++idx) {
			var playlist = response[idx];

			var songCount = playlist["songCount"];
			if (songCount == null) {
				songCount = 0;		// assume 0 if not defined
			}
			
			playlists.add(new Playlist({
				"id" => playlist["id"],
				"name" => playlist["name"],
				"songCount" => songCount.toNumber(),
				"remote" => true,
			}));
		}
		d_callback.invoke(playlists);
	}

	function onGetPlaylist(response) {
		System.println("SubsonicProvider::onGetPlaylist( response = " + response + ")");
		
		var songCount = response["songCount"];
		if (songCount == null) {
			songCount = 0;		// assume 0 if not defined
		}

		d_callback.invoke([new Playlist({
				"id" => response["id"],
				"name" => response["name"],
				"songCount" => songCount.toNumber(),
				"remote" => true,
		})]);
	}

	function onGetPlaylistSongs(response) {
		System.println("SubsonicProvider::onGetPlaylistSongs( response = " + response + ")");
		
		// construct the standard array of song objects
		var songs = [];
		// for (var idx = 0; idx < response["entry"].size(); ++idx) {
		// 	var song = response["entry"][idx];
		// 	songs.add({
		// 		"id" => song["id"],
		// 		"time" => song["duration"].toNumber(),
		// 	});
		// }
		
		// construct the song instances array
		for (var idx = 0; idx < response["entry"].size(); ++idx) {
			var song = response["entry"][idx];

			var time = song["duration"];
			if (time == null) {
				time = 0;
			}
			songs.add(new Song({
				"id" => song["id"],
				"time" => time.toNumber(),
				"mime" => song["contentType"],
			}));
		}
		
		d_callback.invoke(songs);
	}

	function onStream(refId) {
		d_callback.invoke(refId);
	}
	
	function onFailed(responseCode, data) {
		d_fallback.invoke(responseCode, data);
	}
    
    function setFallback(fallback) {
    	d_fallback = fallback;
    }

	function mimeToEncoding(mime) {
		// mime should be a string
		if (!(mime instanceof Lang.String)) {
			return Media.ENCODING_INVALID;
		}
		// check docs: https://developer.mozilla.org/en-US/docs/Web/Media/Formats/Containers
		if (mime.equals("audio/mpeg")) {
			return Media.ENCODING_MP3;
		}
		if (mime.equals("audio/mp4")) {
			return Media.ENCODING_M4A;
		}
		if (mime.equals("audio/aac")) {
			return Media.ENCODING_ADTS;
		}
		if (mime.equals("audio/wave")
			|| mime.equals("audio/wav")
			|| mime.equals("audio/x-wav")
			|| mime.equals("audio/x-pn-wav")) {
			return Media.ENCODING_WAV;
		}
		return Media.ENCODING_INVALID;
	}
}