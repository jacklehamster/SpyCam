package com.nitobi.webapis.youtube.rest
{
	import flash.events.IEventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;

	public class LoginAction extends RestAction
	{
		private var url:String = "https://www.google.com/youtube/accounts/ClientLogin";

		public var userName:String;
		public var password:String;
		
		public function LoginAction(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		public function execute(): void
		{
			var loader:URLLoader = this.getLoader();
			var req:URLRequest = new URLRequest();
				req.url = url;
				req.method = URLRequestMethod.POST;
				req.requestHeaders.push(new URLRequestHeader("pragma", "no-cache"));
			
			var urlVar:URLVariables = new URLVariables();
				urlVar.Email = userName;
				urlVar.Passwd = password;
				urlVar.service = "youtube";
				urlVar.source = "YuTuplr";
			
			req.data = urlVar;
			loader.load(req);
		}
		
		public function get authToken():String
		{
			var vars:URLVariables = new URLVariables();
				vars.decode(this.result);
			var str:String = String(vars.Auth);
			return str.split("\n")[0];
		}
		
		public function get ytUserName():String
		{
			var str:String = String(this.result);
			return str.split("\n")[1];
		}
		
	
	}
}