package com.nitobi.webapis.youtube.rest
{
	
	import flash.events.IEventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;


	public class GetUploadTokenAction extends RestAction
	{
		private static const url:String = "http://gdata.youtube.com/action/GetUploadToken";
		
		private static const xmlTemplate:String = '<entry xmlns="http://www.w3.org/2005/Atom"'
												  + 'xmlns:media="http://search.yahoo.com/mrss/"'
												  + 'xmlns:yt="http://gdata.youtube.com/schemas/2007">'
												  + '<media:group>'
												  + '  <media:title type="plain"></media:title>'
												  + '  <media:description type="plain"></media:description>'
												  + '  <media:category '
												  + '    scheme="http://gdata.youtube.com/schemas/2007/categories.cat">People</media:category>'
												  + ' <media:keywords></media:keywords>'
												  +  ' <media:category scheme="http://gdata.youtube.com/schemas/2007/developertags.cat">SpyCam</media:category>'
												  + 'PRIVATE'
												  + '</media:group>'
												  + '</entry>';
		
		public var mediaTitle:String = "SpyCam Capture";
		public var mediaKeywords:String = "spycam";
		public var mediaDescription:String = "Spy cam capture.";
		public var isPublic:Boolean = true;
		
		
		
		public function GetUploadTokenAction(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		
		public function execute(authToken:String,clientId:String,devKey:String): void
		{
			var loader:URLLoader = this.getLoader();
			var req:URLRequest = new URLRequest();
				req.url = url;
				req.method = URLRequestMethod.POST;
			
				req.requestHeaders.push(new URLRequestHeader("Authorization","GoogleLogin auth=\"" + authToken + "\""));
				req.requestHeaders.push(new URLRequestHeader("X-GData-Client",clientId));
				req.requestHeaders.push(new URLRequestHeader("X-GData-Key","key=" + devKey));
				req.contentType = "application/atom+xml; charset=UTF-8";

			req.data = getMediaXML();

			try	
			{
				loader.load(req);
			}
			catch(err:Error)
			{
				trace("err::" + err.message);
			}

		}
		
		public function getMediaXML():XML
		{
			var xmlStr:String = new String(xmlTemplate);
			var arr:Array;
			if(this.isPublic)
			{
				arr = xmlStr.split("PRIVATE");
				xmlStr = arr.join("");
			}
			else
			{
				arr = xmlStr.split("PRIVATE");
				xmlStr = arr.join("<yt:private/>");
			}	
			
			var mediaXML:XML = new XML(xmlStr);
			var ns:Namespace = mediaXML.namespace("media");
			mediaXML.ns::group.ns::title = this.mediaTitle.length > 0 ? this.mediaTitle : "SpyCam Capture";
			mediaXML.ns::group.ns::keywords = this.mediaKeywords.length  > 0 ? this.mediaKeywords : "spycam";
			mediaXML.ns::group.ns::description = this.mediaDescription.length  > 0 ? this.mediaDescription : "Spy cam capture on "+new Date().toLocaleString();

			trace("mediaXML = " + mediaXML.toString());
			return mediaXML;
		}
		
/* // Sample response
	<?xml version='1.0' encoding='UTF-8'?>
	<response>
		<url>http://uploads.gdata.youtube.com/action/FormDataUpload/AIwbFASOsYFD298Zeulg54ClSjNpMrxeA8Crx5jVFISUc6nzluZHryDBxnwAHfhOuT6pU9Okl0_U_bnBVoF6-fsf0cLK2uuWiQ</url>
		<token>AIwbFASwMW02K-ilkZR46_ab6Ti6OTcErdzXbK4kwn91ZqLFeiUY9Z5GDlwhWaxeHQQDVKskUEo3fdWwhVIgu8WuPeYKbpDumC_X3eP9Tzt63C3PjxQMHfhsqdeE5nlxVmXaU4pwXHXNNuDP7TWmQifvtKnyX7il8ZVyhN_0d3oTGKd9-Om97hjfO_Drpl5vyCOwyb90cghV3bPWnirbxpYrExASbogNqtTrfs6ElU-3zMo28BAFViJeDs6Qrmi9WDJFJxfNOm_iF07Zi2if9gIcfPtAGZp_FVRNzeqTtaWq-w1dE0IWBjpm-fkK988AFRBcO_3xfUd3uwmqs240dFqgJnJIqfLpn64HrtePs1JjWJRK-bIg-zA</token>
	</response>
*/
		
		public function get token():String
		{
			var xml:XML = new XML(this.result);
			return xml.token;

		}
		
		public function get uploadUrl():String
		{
			var xml:XML = new XML(this.result);
			return xml.url;
		}
		
	}
}