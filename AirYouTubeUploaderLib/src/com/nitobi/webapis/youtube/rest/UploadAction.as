package com.nitobi.webapis.youtube.rest
{
	
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLVariables;

	public class UploadAction extends RestAction
	{
		
		public static var REST_EVENT_PROGRESS:String = "restEventProgress";
		
		public static var REST_EVENT_CANCEL:String = "restEventCancel";
		
		public var url:String;
		
		public var file:File;
		
		private static const redirectUrl:String = "http://doesnotexist.com/";

		public var uploadToken:String;
		
		public var uploadStatus:int;
		
		public var videoId:String;
		
		public var bytesLoaded:int = 0;
		
		public var bytesTotal:int = 0;
		
		public function UploadAction(target:IEventDispatcher=null)
		{
			super(target);			
		}
		
		public function cancelUpload():void
		{
			file.cancel();
			this.removeFileListeners();
			dispatchEvent(new Event(REST_EVENT_CANCEL));
		}
		
		public function onUploadComplete(evt:DataEvent):void
		{

		}
		
		public function onUploadProgress(evt:ProgressEvent):void
		{
			trace("progress :: " + evt.bytesLoaded + " : " + evt.bytesTotal);
			this.bytesLoaded = evt.bytesLoaded;
			this.bytesTotal = evt.bytesTotal;
			
			dispatchEvent(new Event(REST_EVENT_PROGRESS));
		}
		
		public function onHttpResponse(evt:HTTPStatusEvent):void
		{
			trace("onHttpResponse");
			if(evt.responseHeaders != null)
			{
				for(var n:int = 0; n < evt.responseHeaders.length; n++)
				{
					if(evt.responseHeaders[n].name == "Location")
					{
						var value:String = evt.responseHeaders[n].value;
						// have we been redirected?
						if(value.indexOf(redirectUrl) == 0)
						{
							// decode the query string params
							var splitStr:String = value.split("?")[1];
							var urlVars:URLVariables = new URLVariables();
								urlVars.decode(splitStr);
								
							videoId = urlVars.id;
							uploadStatus = urlVars.status;
							
							//removeFileListeners();
							
							if(uploadStatus == 200)
							{
								trace("Successfully uploaded the file! id=" + videoId);
								dispatchEvent(new Event(REST_EVENT_SUCCESS));
							}
							else
							{
								trace("Error : status=" + uploadStatus);
								dispatchEvent(new Event(REST_EVENT_ERROR));
							}
							break;
						}
					}
				}
			}
			else
			{
				trace("ResponseHeaders is null");
			}
		}
		
		public function onFileIOError(evt:IOErrorEvent):void
		{
			trace("onFileIOError");
			// we always get an error on the redirect stating that the url does not exist
			this.removeFileListeners();
		}
		
		public function onHttpStatus(evt:HTTPStatusEvent):void
		{
			trace("onHttpStatus");
		}
		
		
		public function execute(): void
		{
			var req:URLRequest = new URLRequest();
				
			req.url = url + 
					"?token=" + encodeURIComponent(this.uploadToken) + 
					 "&nexturl=" + encodeURIComponent(redirectUrl);
					 
			req.followRedirects = true;
			req.requestHeaders.push(new URLRequestHeader("Content-Type","multipart/form-data"));
			addFileListeners();
			file.upload(req,"file");
		}
		
		private function addFileListeners():void
		{
			file.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA,onUploadComplete);
			file.addEventListener(ProgressEvent.PROGRESS,onUploadProgress);
			file.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS,onHttpResponse);
			file.addEventListener(HTTPStatusEvent.HTTP_STATUS,onHttpStatus);
			file.addEventListener(IOErrorEvent.IO_ERROR,onFileIOError);
		}
		
		private function removeFileListeners():void
		{
			file.removeEventListener(DataEvent.UPLOAD_COMPLETE_DATA,onUploadComplete);
			file.removeEventListener(ProgressEvent.PROGRESS,onUploadProgress);
			file.removeEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS,onHttpResponse);
			file.removeEventListener(HTTPStatusEvent.HTTP_STATUS,onHttpStatus);
			file.removeEventListener(IOErrorEvent.IO_ERROR,onFileIOError);
		}
		
		
		
	}
}