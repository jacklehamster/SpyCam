package com.nitobi.webapis.youtube.rest
{
	import flash.events.IEventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	/*
	<form name="logoutForm" method="post" target="_top" action="/index">
		<input type="hidden" name="action_logout" value="1">
	</form>	
	*/

	public class LogoutAction extends RestAction
	{
		private var url:String = "http://www.youtube.com/index";
		
		public function LogoutAction(target:IEventDispatcher=null)
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
				urlVar.action_logout = 1;
			
			req.data = urlVar;
			loader.load(req);
		}
		
	
	}
}