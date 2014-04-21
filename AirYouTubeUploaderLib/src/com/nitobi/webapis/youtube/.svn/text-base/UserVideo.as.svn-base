package com.nitobi.webapis.youtube
{
	import com.adobe.utils.DateUtil;
	
	import mx.collections.ArrayCollection;
	
	[Bindable]
	public class UserVideo
	{
		
		public static const STATUS_PROCESSING:String = "processing";
		
		public static const STATUS_ACTIVE:String = "active";
		
		public static const STATUS_REJECTED:String = "rejected";
		
		public static const WATCH_BASE_URL:String = "http://www.youtube.com/watch?v=";
		
		public static const SWF_BASE_URL:String = "http://www.youtube.com/v/";
		
		public var id:String;
		public var thumbnail1:String;
		public var thumbnail2:String;
		public var thumbnail3:String;
		
		public var durationSeconds:int;
		
		public var viewCount:int;
		public var commentsCount:int = -1;
		public var commentsUrl:String;
		public var comments:ArrayCollection;
		
		public var title:String;
		public var published:Date;
		public var updated:Date;
		public var status:String; // processing | active | rejected
		public var reason:String; // ie. Duplicate video
		public var description:String;
		public var keywords:String;
		
		public var rating:Number = 0;
		
/* // Sample XML
<entry xmlns="http://www.w3.org/2005/Atom" 
	xmlns:openSearch="http://a9.com/-/spec/opensearchrss/1.0/" 
	xmlns:gml="http://www.opengis.net/gml" 
	xmlns:georss="http://www.georss.org/georss" 
	xmlns:media="http://search.yahoo.com/mrss/" 
	xmlns:batch="http://schemas.google.com/gdata/batch" 
	xmlns:yt="http://gdata.youtube.com/schemas/2007" 
	xmlns:gd="http://schemas.google.com/g/2005">
	
  <id>
    http://gdata.youtube.com/feeds/api/videos/LRomhDzJ6V0
  </id>
  <published>
    2009-01-07T22:01:15.000Z
  </published>
  <updated>
    2009-01-07T23:23:08.000Z
  </updated>
  <category scheme="http://gdata.youtube.com/schemas/2007/categories.cat" term="People" label="People &amp; Blogs"/>
  <category scheme="http://schemas.google.com/g/2005#kind" term="http://gdata.youtube.com/schemas/2007#video"/>
  <category scheme="http://gdata.youtube.com/schemas/2007/keywords.cat" term="OverlayTV"/>
  <title type="text">
    VID00001.AVI
  </title>
  <content type="text">
    yutuplr uploader
  </content>
  <link rel="alternate" type="text/html" href="http://www.youtube.com/watch?v=LRomhDzJ6V0"/>
  <link rel="http://gdata.youtube.com/schemas/2007#video.responses" type="application/atom+xml" href="http://gdata.youtube.com/feeds/api/videos/LRomhDzJ6V0/responses?client=ytapi-Nitobi-SampleAirUploade-bn5tqgqd-1"/>
  <link rel="http://gdata.youtube.com/schemas/2007#video.ratings" type="application/atom+xml" href="http://gdata.youtube.com/feeds/api/videos/LRomhDzJ6V0/ratings?client=ytapi-Nitobi-SampleAirUploade-bn5tqgqd-1"/>
  <link rel="http://gdata.youtube.com/schemas/2007#video.complaints" type="application/atom+xml" href="http://gdata.youtube.com/feeds/api/videos/LRomhDzJ6V0/complaints?client=ytapi-Nitobi-SampleAirUploade-bn5tqgqd-1"/>
  <link rel="http://gdata.youtube.com/schemas/2007#video.related" type="application/atom+xml" href="http://gdata.youtube.com/feeds/api/videos/LRomhDzJ6V0/related?client=ytapi-Nitobi-SampleAirUploade-bn5tqgqd-1"/>
  <link rel="http://gdata.youtube.com/schemas/2007#mobile" type="text/html" href="http://m.youtube.com/details?v=LRomhDzJ6V0"/>
  <link rel="self" type="application/atom+xml" href="http://gdata.youtube.com/feeds/api/users/livemidnite/uploads/LRomhDzJ6V0?client=ytapi-Nitobi-SampleAirUploade-bn5tqgqd-1"/>
  <link rel="edit" type="application/atom+xml" href="http://gdata.youtube.com/feeds/api/users/livemidnite/uploads/LRomhDzJ6V0?client=ytapi-Nitobi-SampleAirUploade-bn5tqgqd-1"/>
  <author>
    <name>
      livemidnite
    </name>
    <uri>
      http://gdata.youtube.com/feeds/api/users/livemidnite
    </uri>
  </author>
  <media:group>
    <media:title type="plain">
      VID00001.AVI
    </media:title>
    <media:description type="plain">
       uploader
    </media:description>
    <media:keywords>
      cool
    </media:keywords>
    <yt:duration seconds="21"/>
    <media:category label="People &amp; Blogs" scheme="http://gdata.youtube.com/schemas/2007/categories.cat">
      People
    </media:category>
    <media:content url="http://www.youtube.com/v/LRomhDzJ6V0&amp;f=gdata_user_uploads&amp;c=ytapi-Nitobi-SampleAirUploade-bn5tqgqd-1&amp;d=FQtM66QThbTdbl-5wt4uqmD9LlbsOl3qUImVMV6ramM" type="application/x-shockwave-flash" medium="video" isDefault="true" expression="full" duration="21" yt:format="5"/>
    <media:content url="rtsp://rtsp2.youtube.com/CnoLENy73wIacQld6ck8hCYaLRMYDSANFEIoeXRhcGktTml0b2JpLVNhbXBsZUFpclVwbG9hZGUtYm41dHFncWQtMUgGUhJnZGF0YV91c2VyX3VwbG9hZHNyIBULTOukE4W03W5fucLeLqpg_S5W7Dpd6lCJlTFeq2pjDA==/0/0/0/video.3gp" type="video/3gpp" medium="video" expression="full" duration="21" yt:format="1"/>
    <media:content url="rtsp://rtsp2.youtube.com/CnoLENy73wIacQld6ck8hCYaLRMYESARFEIoeXRhcGktTml0b2JpLVNhbXBsZUFpclVwbG9hZGUtYm41dHFncWQtMUgGUhJnZGF0YV91c2VyX3VwbG9hZHNyIBULTOukE4W03W5fucLeLqpg_S5W7Dpd6lCJlTFeq2pjDA==/0/0/0/video.3gp" type="video/3gpp" medium="video" expression="full" duration="21" yt:format="6"/>
    <media:thumbnail url="http://i.ytimg.com/vi/LRomhDzJ6V0/2.jpg" height="97" width="130" time="00:00:10.500"/>
    <media:thumbnail url="http://i.ytimg.com/vi/LRomhDzJ6V0/1.jpg" height="97" width="130" time="00:00:05.250"/>
    <media:thumbnail url="http://i.ytimg.com/vi/LRomhDzJ6V0/3.jpg" height="97" width="130" time="00:00:15.750"/>
    <media:thumbnail url="http://i.ytimg.com/vi/LRomhDzJ6V0/0.jpg" height="240" width="320" time="00:00:10.500"/>
    <media:player url="http://www.youtube.com/watch?v=LRomhDzJ6V0"/>
  </media:group>
  <gd:rating average="3.0" max="5" min="1" numRaters="1" rel="http://schemas.google.com/g/2005#overall"/>
  <yt:statistics favoriteCount="0" viewCount="2"/>
  <gd:comments>
    <gd:feedLink href="http://gdata.youtube.com/feeds/api/videos/LRomhDzJ6V0/comments?client=ytapi-Nitobi-SampleAirUploade-bn5tqgqd-1" countHint="0"/>
  </gd:comments>
</entry>
*/

  
  

/* Rating Strings
	1:Poor
	2:Nothing Special
	3:Worth Watching
	4:Pretty Cool
	5:Awesome
*/
			
		public function UserVideo(xml:XML = null)
		{
			if(xml != null)
			{
				this.id = xml.*::id.toString();
				
				this.thumbnail1 = xml.*::group.*::thumbnail[0].@url.toString();
				this.thumbnail2 = xml.*::group.*::thumbnail[1].@url.toString();
				this.thumbnail3 = xml.*::group.*::thumbnail[2].@url.toString();
				
				this.title = xml.*::title.toString();
				this.published = DateUtil.parseW3CDTF(xml.*::published.toString());
				this.updated = DateUtil.parseW3CDTF(xml.*::updated.toString());
				this.status = xml.*.*::state.@name.toString();
				
				this.durationSeconds = parseInt(xml.*::group.*::duration.@seconds.toString());
				
				this.viewCount = parseInt(xml.*::statistics.@viewCount.toString());
				this.commentsCount = parseInt(xml.*::comments.*::feedLink.@countHint.toString());
				this.commentsUrl = xml.*::comments.*::feedLink.@href.toString();
				
				this.keywords = xml.*::group.*::keywords.toString();
				
				this.reason = xml.*.*::state.toString();
				this.description = xml.*.*::description.toString();

				var num:Number = parseFloat(xml.*::rating.@average.toString());
				this.rating = isNaN(num) ? 0 : num;
	

				if(this.status == "")
				{
					this.status = "active";
				}
			}
		}
		
		public function get formattedDuration():String
		{
			var seconds:int = this.durationSeconds % 60;
			var minutes:int = (this.durationSeconds - seconds) / 60;
			var joinStr:String = seconds < 10 ? ":0" : ":";

			return minutes + joinStr + seconds;
		}
		
		public function set formattedDuration(str:String):void
		{
			// to support binding only
		}
		

		public function get watchUrl():String
		{
			return WATCH_BASE_URL + id.substr(id.lastIndexOf("/") + 1);
		}
		
		public function set watchUrl(value:String):void
		{
			// to support binding only
		}
		
		public function get swfUrl():String
		{
			return SWF_BASE_URL + id.substr(id.lastIndexOf("/") + 1);
		}
		
		public function set swfUrl(value:String):void
		{
			// to support binding only
		}

        
        // update sets all values except ID, which is unique
        public function update(value:UserVideo):void
        {
			this.title = value.title;
			this.published = value.published;
			this.updated = value.updated;
			this.status = value.status;
			this.reason = value.reason;
			this.rating = value.rating;
			if(this.status == "")
			{
				this.status = "active";
			}
        }
	}
}