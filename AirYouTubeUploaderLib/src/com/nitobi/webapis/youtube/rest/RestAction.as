package com.nitobi.webapis.youtube.rest
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;

	public class RestAction extends EventDispatcher
	{
		
		public static var REST_EVENT_SUCCESS:String = "restEventSuccess";
		public static var REST_EVENT_ERROR:String = "restEventError";
		
		protected var _loader:URLLoader;
		private var _url:String;
		
		public var status:int = 0;
		public var result:*;
		public var errorMessage:String;
		
		public function RestAction(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		public function getLoader():URLLoader
		{
			if(_loader == null)
			{
				_loader = new URLLoader();
	        	_loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleSecurityError);
	        	_loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, handleHttpStatus);
	        	_loader.addEventListener(IOErrorEvent.IO_ERROR, handleIOError);
	        	_loader.addEventListener(Event.COMPLETE, handleComplete);
			}
			return _loader;
		}
		
		
		private function removeListeners():void
		{
	        _loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, handleSecurityError);
	        _loader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, handleHttpStatus);
	        _loader.removeEventListener(IOErrorEvent.IO_ERROR, handleIOError);
	        _loader.removeEventListener(Event.COMPLETE, handleComplete);
		}
		
		protected function handleSecurityError(evt:SecurityErrorEvent):void
		{
			trace("handleSecurityError::" + evt.text);
			dispatchEvent(new Event(REST_EVENT_ERROR));
			removeListeners();
		}
		
		protected function handleHttpStatus(evt:HTTPStatusEvent):void
		{
			trace("handleHttpStatus::" + evt.status);
			trace(_loader.data);
		}
		
		protected function handleIOError(evt:IOErrorEvent):void
		{
			trace("handleIOError::" + evt.text);
			trace(_loader.data);
			dispatchEvent(new Event(REST_EVENT_ERROR));
			removeListeners();
		}
		
		
		protected function handleComplete(evt:Event):void
		{
			result = _loader.data;
			dispatchEvent(new Event(REST_EVENT_SUCCESS));
			removeListeners();
		}
		
	}
}