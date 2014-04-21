package com.paris24.cam
{
	import com.nitobi.webapis.youtube.UserUpload;
	import com.nitobi.webapis.youtube.YouTubeService;
	import com.nitobi.webapis.youtube.event.YouTubeEvent;
	
	import flash.events.Event;
	import flash.events.FileListEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.media.Camera;
	import flash.utils.Timer;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	[Event(name="ytUploadComplete",type="com.nitobi.webapis.youtube.event.YouTubeEvent")]
	[Event(name="ytUploadProgress",type="com.nitobi.webapis.youtube.event.YouTubeEvent")]
	public class YoutubeMotionCapture extends FLVMotionCapture
	{
		static private const CHECKUPLOADTIMER:int = 5000;
		
		public var service:YouTubeService = new YouTubeService();
		private var uploadCheckTimer:Timer = new Timer(CHECKUPLOADTIMER);
		private var dirInProgress:Boolean = false;
		private var uploadTimeout:int;
		private var lastProgress:Number;
		private var lastProgressTime:Date;
		
		public var filesInQueue:int;
		public var filesInBacklog:int;
		
		public function YoutubeMotionCapture(cam:Camera=null)
		{
			super(cam);
			service.addEventListener(YouTubeEvent.YT_UPLOAD_ERROR,uploadComplete);
			service.addEventListener(YouTubeEvent.YT_UPLOAD_SUCCESS,uploadComplete);
			service.addEventListener(YouTubeEvent.YT_UPLOAD_COMPLETE,dispatchEvent);
			service.addEventListener(YouTubeEvent.YT_UPLOAD_PROGRESS,onProgress);
			uploadCheckTimer.addEventListener(TimerEvent.TIMER,checkUploads);
			uploadCheckTimer.start();
			addEventListener(Event.COMPLETE,checkUploads);
			addEventListener("kick",kick);
			
			var pendingFiles:Array = pendingDirectory.getDirectoryListing();
			for each(var file:File in pendingFiles) {
				file.moveTo(captureDirectory.resolvePath(file.name),true);
			}
			trace("Pending files:",pendingFiles.length);
		}
		
		private function kick(e:Event):void {
			uploadCheckTimer.reset();
			uploadCheckTimer.start();
			checkUploads(null);
		}
		
		public function setDevCredentials(appName:String,devKey:String):void {
			service.setCredentials(appName,devKey);
		}
		
		public function login(username:String,password:String):void {
			service.login(username,password);
		}
		
		private function onProgress(e:YouTubeEvent):void {
			dispatchEvent(e);
		}
		
		public function get pendingDirectory():File {
			var dir:File = File.applicationStorageDirectory.resolvePath("pending");
			if(!dir.exists) {
				dir.createDirectory();
			}
			return dir;
		}
		
		public function get backlogDirectory():File {
			var dir:File = File.applicationStorageDirectory.resolvePath("backlog");
			if(!dir.exists) {
				dir.createDirectory();
			}
			return dir;
		}
		
		private function compareFilesByDate(fileA:File,fileB:File):Number {
			return fileA.creationDate.date - fileB.creationDate.date;
		}
				
		private function checkUploads(e:Event):void {
			if(service.currentlyUploadingFile && service.currentlyUploadingFile.status ==UserUpload.STATUS_PENDING  || service.pendingUploadCount && (!service.currentlyUploadingFile || service.currentlyUploadingFile.status==UserUpload.STATUS_PENDING)) {
				if(!uploadTimeout)
					uploadTimeout = setTimeout(startUploading,1000);
				return;
			}
			
			if(service.currentlyUploadingFile) {
				var now:Date = new Date();
				if(lastProgress != service.currentFileUploadProgress) {
					lastProgress = service.currentFileUploadProgress;
					lastProgressTime = now;
				}
				if(now.time-lastProgressTime.time > 60*1000) {	//	1 min without progress!
					service.stopUploading();	//	reset upload
					if(!uploadTimeout)
						uploadTimeout = setTimeout(startUploading,1000);
				}
			}
			
			var dir:File = captureDirectory;
			if(dir.exists && !dirInProgress) {
				dirInProgress = true;
				dir.getDirectoryListingAsync();
				dir.addEventListener(FileListEvent.DIRECTORY_LISTING,
					function(e:FileListEvent):void {
						e.currentTarget.removeEventListener(e.type,arguments.callee);
						e.files.sort(compareFilesByDate,Array.DESCENDING);
						var addedFile:int = 0;
						var numFiles:int = 0;
						for each(var file:File in e.files) {
							if(!file.isDirectory && service.isSupportedType(file.extension) ) {
								numFiles++;
							}
						}
						filesInQueue = numFiles;
						var backlogFiles:Array = backlogDirectory.getDirectoryListing();
						trace("Files left:",numFiles);
						trace("Files pending:",pendingDirectory.getDirectoryListing().length);
						trace("Checking backlog:",backlogFiles.length);
						for each(file in e.files) {
							if(!file.isDirectory 
								&& service.isSupportedType(file.extension) 
								&& (!processedFile||file.nativePath!=processedFile.nativePath)
								&& !service.fileIsInQueue(file.nativePath)) {
								var newFile:File = pendingDirectory.resolvePath(file.name);
								file.moveTo(newFile,true);
								service.addFile(newFile);
								if(!uploadTimeout) {
									uploadTimeout = setTimeout(startUploading,1000);
								}
								break;
							}
						}
						dirInProgress = false;
						trace("CurrentUploadingFile",service.currentlyUploadingFile?service.currentlyUploadingFile.status:"none");
/*						if(!addedFile && (!service.currentlyUploadingFile || service.currentlyUploadingFile.status==UserUpload.STATUS_COMPLETED)) {
							filesInBacklog = backlogFiles.length;
							if(backlogFiles.length) {
								backlogFiles.sort(compareFilesByDate,Array.DESCENDING);
								for each(file in backlogFiles) {
									var newname:String = file.name;
									var split:Array = newname.split(".");
									var ext:String = split.pop();
									split.push("(backlog)");
									split.push(ext);
									newname = split.join(".");
									file.moveTo(captureDirectory.resolvePath(newname),true);
									uploadTimeout = setTimeout(startUploading,1000);
									uploadCheckTimer.reset();
									uploadCheckTimer.start();
									break;
								}
							}
						}*/
					});
			}
		}
		
		private function startUploading():void {
			clearTimeout(uploadTimeout);
			if(!service.currentlyUploadingFile || service.currentlyUploadingFile.status==UserUpload.STATUS_COMPLETED || service.currentlyUploadingFile.status==UserUpload.STATUS_PENDING) {
				if(service.currentlyUploadingFile && service.currentlyUploadingFile.status==UserUpload.STATUS_PENDING)
					trace(service.currentlyUploadingFile.fileName);
				service.startUploading();
			}
			uploadTimeout = 0;
		}
		
		private function uploadComplete(e:YouTubeEvent):void {
			lastProgress = 0;
			if(e.type==YouTubeEvent.YT_UPLOAD_SUCCESS)
				service.currentlyUploadingFile.file.deleteFileAsync();
			//uploadCheckTimer.reset();
			//uploadCheckTimer.start();
			dispatchEvent(e);
		}
	}
}