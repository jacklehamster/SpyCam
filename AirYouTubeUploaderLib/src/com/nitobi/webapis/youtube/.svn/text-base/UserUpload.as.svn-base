package com.nitobi.webapis.youtube
{
	import flash.filesystem.File;
	
	[Bindable]
	public class UserUpload
	{
		public static const FILESIZE_BYTES:Array = ["Bytes","KB","MB","GB"];
		
		// file is currently uploading
		public static const STATUS_UPLOADING:String = "uploading";
		
		// file has been uploaded
		public static const STATUS_COMPLETED:String = "completed";
		
		// file upload failed
		public static const STATUS_ERROR:String = "error";
		
		// file is in the queue
		public static const STATUS_QUEUED:String = "ready";
		
		// file details are being edited
		public static const STATUS_PENDING:String = "pending";
		
		
		public var name:String;
		public var uid:String;
		public var file:File;
		public var fileName:String;
		public var keywords:String = "YuTuplr";
		public var description:String = "YuTuplr";
		public var category:String;
		
		public var isPublic:Boolean;
		
		public var status:String;
		
		public var bytesTotal:Number;
		public var bytesLoaded:Number;
		
		
		
		public function UserUpload()
		{
			isPublic = true;
			this.status = STATUS_QUEUED;
		}
		
		public function get formattedSize():String
		{
			var tempSize:Number = this.file.size;
			
			var index:int = 0;
			for(;index < FILESIZE_BYTES.length; index++)
			{
				if(tempSize < 1000) // we always want 3 digits even if it ends up less than 1.0 ( example 0.99 MB instead of 1010 KB )
					break;
				else
				{
					tempSize /= 1024;
				}
			}
			return tempSize.toPrecision(3) + " " + FILESIZE_BYTES[index];
		}
		
		private function set formattedSize(value:String):void	
		{
			// to support binding only
		}
		
		public static function create(filePath:String):UserUpload
		{
			var upload:UserUpload = new UserUpload();
			var file:File = new File(filePath);
			upload.name = file.name;
			upload.uid	= file.url;
			upload.fileName = file.name;
			upload.file = file;
			return upload;
		}

	}
}