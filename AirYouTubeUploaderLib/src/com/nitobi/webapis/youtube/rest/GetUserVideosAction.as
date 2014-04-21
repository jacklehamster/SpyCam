package com.nitobi.webapis.youtube.rest
{

	import com.nitobi.webapis.youtube.UserVideo;
	
	import flash.events.IEventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;

	public class GetUserVideosAction extends RestAction
	{
		private static const url:String = "http://gdata.youtube.com/feeds/api/users/default/uploads?max-results=50";
		
		public function GetUserVideosAction(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		public function execute(authToken:String,clientId:String,devKey:String): void
		{
			var loader:URLLoader = this.getLoader();
			var req:URLRequest = new URLRequest();
				req.url = url;
				req.method = URLRequestMethod.POST;
				req.requestHeaders.push(new URLRequestHeader("pragma", "no-cache"));
				req.requestHeaders.push(new URLRequestHeader("X-HTTP-Method-Override","PUT"));
/*				req.requestHeaders.push(new URLRequestHeader("Content-Type","application/atom+xml"));
				req.requestHeaders.push(new URLRequestHeader("X-GData-Key","key=" + devKey));
				req.requestHeaders.push(new URLRequestHeader("GData-Version","2"));

				req.requestHeaders.push(new URLRequestHeader("Authorization","Bearer " + authToken));*/
				req.requestHeaders.push(new URLRequestHeader("Authorization","GoogleLogin auth=\"" + authToken + "\""));
				req.requestHeaders.push(new URLRequestHeader("X-GData-Client",clientId));
				req.requestHeaders.push(new URLRequestHeader("X-GData-Key","key=" + devKey));
	/*			
				POST /feeds/api/videos HTTP/1.1
				X-HTTP-Method-Override: GET
				Host: gdata.youtube.com
				Content-Type: application/atom+xml
				Content-Length: CONTENT_LENGTH
				Authorization: Bearer ACCESS_TOKEN
				GData-Version: 2
				X-GData-Key: key=DEVELOPER_KEY
		*/		
			try
			{
				loader.load(req);
			}
			catch(err:Error)
			{
				trace("err::" + err.message);
			}
		}
		
		public function get totalResults():int
		{
			try {
				var xml:XML = new XML(this.result);
				var ns:Namespace = xml.namespace("openSearch");
				var count:String = xml.ns::totalResults.toString();
				return parseInt(count);
			}
			catch(error:Error) {
			}
			return 0;
		}
		
		public function get startIndex():int
		{
			var xml:XML = new XML(this.result);
			var ns:Namespace = xml.namespace("openSearch");
			var count:String = xml.ns::startIndex.toString();
			return parseInt(count);
		}
		
		public function get itemsPerPage():int
		{
			var xml:XML = new XML(this.result);
			var ns:Namespace = xml.namespace("openSearch");
			var count:String = xml.ns::itemsPerPage.toString();
			return parseInt(count);
		}
		
		public function get items():Array
		{
			var arr:Array = new Array();
			var xml:XML = new XML(this.result);
			var ns:Namespace = xml.namespace();
			
			var itemList:XMLList = xml.ns::entry;
			
			var len:int = itemList.length();
			
			for(var n:int =0; n < len; n++)
			{
				arr.push(new UserVideo(itemList[n]));
			}
			return arr;
		}
		
		
	}
}