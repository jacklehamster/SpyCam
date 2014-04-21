package com.nitobi.webapis.youtube.rest
{

	import com.nitobi.webapis.youtube.UserVideo;
	
	import flash.events.IEventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;

	public class GetAllDevTagVideosAction extends RestAction
	{
		private static const devTagReplaceKey:RegExp = /DEVTAG/;
		private static const devKeyReplace:RegExp = /DEVKEY/;
		private static const clientIDReplace:RegExp = /CLIENTID/;
		private static const url:String =  "http://gdata.youtube.com/feeds/api/videos/-/%7Bhttp%3A%2F%2Fgdata.youtube.com%2Fschemas%2F2007%2Fdevelopertags.cat%7DDEVTAG?client=CLIENTID&key=DEVKEY";
		
		public function GetAllDevTagVideosAction(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		public function execute(devTag:String,clientId:String,devKey:String): void
		{
			var loader:URLLoader = this.getLoader();
			var req:URLRequest = new URLRequest();
			var fixedUrl:String = url.replace(devTagReplaceKey,devTag);
				fixedUrl = fixedUrl.replace(devKeyReplace,devKey);
				fixedUrl = fixedUrl.replace(clientIDReplace,clientId);
			req.url = fixedUrl;
			trace(fixedUrl);
			req.method = URLRequestMethod.POST;
			req.requestHeaders.push(new URLRequestHeader("pragma", "no-cache"));

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
			var xml:XML = new XML(this.result);
			var ns:Namespace = xml.namespace("openSearch");
			var count:String = xml.ns::totalResults.toString();
			return parseInt(count);
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