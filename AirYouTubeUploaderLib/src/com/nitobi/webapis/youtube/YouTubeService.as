package com.nitobi.webapis.youtube
{
	import com.nitobi.webapis.youtube.event.YouTubeEvent;
	import com.nitobi.webapis.youtube.rest.GetUploadTokenAction;
	import com.nitobi.webapis.youtube.rest.GetUserVideosAction;
	import com.nitobi.webapis.youtube.rest.LoginAction;
	import com.nitobi.webapis.youtube.rest.LogoutAction;
	import com.nitobi.webapis.youtube.rest.RestAction;
	import com.nitobi.webapis.youtube.rest.UploadAction;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.net.SharedObject;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;
	import mx.events.CollectionEvent;

	// Login has begun, waiting for response from YouTube
	[Event(name="ytLoginStart",type="YouTubeEvent")]
	// 
	[Event(name="ytLoginError",type="com.nitobi.webapis.youtube.event.YouTubeEvent")]

	[Event(name="ytLoginSuccess",type="com.nitobi.webapis.youtube.event.YouTubeEvent")]
	
	[Event(name="ytGotUserVideos",type="com.nitobi.webapis.youtube.event.YouTubeEvent")]
	
	[Event(name="ytNoCredentials",type="com.nitobi.webapis.youtube.event.YouTubeEvent")]
	
	[Event(name="ytUploadTokenSuccess",type="com.nitobi.webapis.youtube.event.YouTubeEvent")]
	
	[Event(name="ytUploadTokenError",type="com.nitobi.webapis.youtube.event.YouTubeEvent")]
	
	[Event(name="ytUploadSuccess",type="com.nitobi.webapis.youtube.event.YouTubeEvent")]
	
	[Event(name="ytUploadError",type="com.nitobi.webapis.youtube.event.YouTubeEvent")]
	
	[Event(name="ytUploadComplete",type="com.nitobi.webapis.youtube.event.YouTubeEvent")]
	
	[Event(name="ytUploadProgress",type="com.nitobi.webapis.youtube.event.YouTubeEvent")]
	
	[Event(name="ytProcessingCountChange",type="com.nitobi.webapis.youtube.event.YouTubeEvent")]

	[Event(name="ytFilesizeExceeded",type="com.nitobi.webapis.youtube.event.YouTubeEvent")]
	
	public class YouTubeService extends EventDispatcher
	{

		public static var URL_FORGOT_PASSWORD:String = "http://www.youtube.com/forgot?next=/";
		public static var URL_FORGOT_USERNAME:String = "http://www.youtube.com/forgot_username?next=/";
		public static var URL_SIGNUP:String = "http://www.youtube.com/signup?next_url=/&";
		public static var URL_HELP:String = "http://www.youtube.com/t/help_gaia";
		
		public static const MAX_QUEUE_SIZE:int = 100;
		public static const MAX_FILE_SIZE:int = (1024 * 1024 * 1024); // 1 GB
		public static const ALLOWED_EXTENSIONS:String = "wmv|avi|mov|mpg|flv"; // note this must be lowercase
		
		public static const localSharedObjKey:String = "YTService";
		
		private var tempCredentials:Object; // store username and password if they choose
		
		private var _loginAction:LoginAction;
		private var _logoutAction:LogoutAction;
		private var _uploadAction:UploadAction;
		private var _getUserVideosAction:GetUserVideosAction;
		private var _getUploadTokenAction:GetUploadTokenAction;
		
		private var _authToken:String;
		private var _currentUserName:String;
		
		private var _clientID:String;
		private var _devKey:String;
		
		private var _uploadQueue:ArrayCollection;
		
		private var _userVideos:ArrayCollection;
		private var _userVideoMap:Dictionary;
		
		// this will also serve as a keep-alive
		public static var TIMER_INTERVAL:int = ( 30 * 1000 ); // thirty seconds
		
		// timer to refesh the list of user vids
		private var _refreshTimer:Timer;
		
		[Bindable]
		public var isAuthenticated:Boolean = false;
		
		[Bindable]
		public var isUploading:Boolean = false;
		
		[Bindable]
		public var uploadFileIndex:int = 0;
		
		[Bindable]
		public var totalUploads:int;
		
		[Bindable]
		public var currentFileUploadProgress:Number;
		
		[Bindable]
		public var currentlyUploadingFile:UserUpload;
		
		[Bindable]
		public var processingCount:int; // the number of videos currently being processed by YouTube

		
		public function YouTubeService(target:IEventDispatcher=null)
		{
			super(target);
			_userVideoMap = new Dictionary();
			_userVideos = new ArrayCollection();
			uploadQueue.addEventListener(CollectionEvent.COLLECTION_CHANGE,updateBindings);
		}
		
		// Public getter/setters
		
		/**************************************************** authToken
		 */
		[Bindable]
		public function get authToken():String
		{
			return this._authToken;
		}
		
		public function set authToken(value:String):void
		{
			this._authToken = value;
		}
		
		/**************************************************** currentUserName
		 */
		[Bindable]
		public function get currentUserName():String
		{
			return this._currentUserName;
		}
		
		public function set currentUserName(value:String):void
		{
			this._currentUserName = value;
		}
		
		/**************************************************** uploadQueue
		 */
		[Bindable]
		public function set uploadQueue(value:ArrayCollection):void
		{
			_uploadQueue = value;
		}
		
		
		public function get uploadQueue():ArrayCollection
		{
			if(_uploadQueue == null)
			{
				_uploadQueue = new ArrayCollection();
			}
			return this._uploadQueue;
		}
		
		
		/**************************************************** userVideos
		 */
		[Bindable]
		public function set userVideos(value:ArrayCollection):void
		{
			this._userVideos = value;
		}
		
		public function get userVideos():ArrayCollection
		{
			return this._userVideos;
		}
		
		public function removeUpload(upload:UserUpload):void
		{
			if(upload.status != UserUpload.STATUS_UPLOADING)
			{
				_uploadQueue.removeItemAt(_uploadQueue.getItemIndex(upload));
			}
			else
			{
				_uploadAction.cancelUpload();
				_uploadQueue.removeItemAt(_uploadQueue.getItemIndex(upload));
				uploadNextVideo();
			}
		}
		
		[Bindable]
		///////////////////////////////////////////////////// 	completedUploadCount
		public function get completedUploadCount():int
		{
			var count:int = 0; 
			for(var n:int = 0; n < this._uploadQueue.length; n++)
			{
				if((_uploadQueue[n] as UserUpload).status == UserUpload.STATUS_COMPLETED)
				{
					count++;
				}
			}
			return count;
		}
		
		private function set completedUploadCount(value:int):void
		{
			// to support binding only
		}
		
		[Bindable]
		///////////////////////////////////////////////////// 	failedUploadCount
		public function get failedUploadCount():int
		{
			var count:int = 0; 
			for(var n:int = 0; n < this._uploadQueue.length; n++)
			{
				if((_uploadQueue[n] as UserUpload).status == UserUpload.STATUS_ERROR)
				{
					count++;
				}
			}
			return count;
		}
		
		private function set failedUploadCount(value:int):void
		{
			// to support binding only
		}
		
		[Bindable]
		///////////////////////////////////////////////////// 	pendingUploadCount
		public function get pendingUploadCount():int
		{
			var count:int = 0; 
			for(var n:int = 0; n < this._uploadQueue.length; n++)
			{
				var status:String = (_uploadQueue[n] as UserUpload).status;
				if(status == UserUpload.STATUS_QUEUED)
				{
					count++;
				}
			}
			return count;
		}
		
		private function set pendingUploadCount(value:int):void
		{
			// to support binding only
		}

		
		public function clearCompletedUploads():void
		{
			for(var n:int = _uploadQueue.length - 1; n >= 0; n--)
			{
				if(_uploadQueue[n].status == UserUpload.STATUS_COMPLETED)
				{
					_uploadQueue.removeItemAt(n);
				}
			}
			updateBindings();
		}
		
		public function retryFailedUploads():void
		{
			for(var n:int = 0; n < _uploadQueue.length; n++)
			{
				if(_uploadQueue[n].status == UserUpload.STATUS_ERROR)
				{
					_uploadQueue[n].status = UserUpload.STATUS_QUEUED;
				}
			}
			if(!isUploading)
			{
				isUploading = true;
				uploadNextVideo();
			}
		}
		
		public function removeFailedUploads():void
		{
			for(var n:int = _uploadQueue.length - 1; n >= 0; n--)
			{
				if(_uploadQueue[n].status == UserUpload.STATUS_ERROR)
				{
					_uploadQueue.removeItemAt(n);
				}
			}
		}
		
		public function addFiles(fileList:Array):Boolean
		{
			for(var n:int = 0; n < fileList.length; n++)
			{
				if(addFile(fileList[n]))
					return true;
			}
			return false;
		}
		
		public function addFile(file:File):Boolean
		{
			return recursiveAddFile(file);
		}
		
		
		// returns true if queue is full
		private function recursiveAddFile(file:File):Boolean
		{
			if(uploadQueue.length < MAX_QUEUE_SIZE)
			{
				if(file.isHidden)
				{
					return false;
				}
				else if(file.isDirectory)
				{
					
					var dirFiles:Array = file.getDirectoryListing();
					for(var n:int = 0; n < dirFiles.length;n++)
					{
						var childFile:File = dirFiles[n] as File;
						if(recursiveAddFile(childFile))
						{
							return true;
						}
					}
				}
				else
				{
					if(file != null && file.extension != null && isSupportedType(file.extension))
					{
						if(file.size > MAX_FILE_SIZE)
						{
							var errEvt:YouTubeEvent = new YouTubeEvent(YouTubeEvent.YT_FILESIZE_EXCEEDED);
							errEvt.data = file;
							dispatchEvent(errEvt);
						}
						else if(fileIsInQueue(file.url))
						{

						}
						else
						{
							addFileToQueue(file.url);
						}
					}
				}
				return false;
			}
			return true;	
		}
		
		public function fileIsInQueue(fileUrl:String):Boolean
		{
			for(var n:int = 0; n < _uploadQueue.length; n++)
			{
				if((_uploadQueue.getItemAt(n) as UserUpload).file.url == fileUrl)
				{
					return true;
				}
			}
			return false;
		}
		
		public function isSupportedType(ext:String):Boolean
		{
			return ( ext != null && (ALLOWED_EXTENSIONS.indexOf(ext.toLowerCase()) > -1) );
		}
			
		public function setCredentials(clientID:String,devKey:String):void
		{
			this._clientID = clientID;
			this._devKey = devKey;
			if(checkCredentials())
			{
				// dispatch credentials set event? -jm
			}
		}
		
		/**
		 * logout
		 */
		public function logout():void
		{
			if(isAuthenticated) // can't log out if you're not logged in
			{
				if(_logoutAction == null)
				{
					_logoutAction = new LogoutAction();
					_logoutAction.addEventListener(RestAction.REST_EVENT_ERROR,onLogoutError);
					_logoutAction.addEventListener(RestAction.REST_EVENT_SUCCESS,onLogoutSuccess);
					_logoutAction.execute();
				}
				else
				{
					throw new Error("YouTube.LogoutAction pending");
				}
			}
			processingCount = 0;
			uploadQueue = new ArrayCollection();
			userVideos = new ArrayCollection();
			_userVideoMap = new Dictionary();
			
		}
		
		private function onLogoutSuccess(evt:Event):void
		{
			cleanup();
			clearSession();
			// TODO: dispatch event
			stopRefreshTimer();
		}
		
		private function onLogoutError(evt:Event):void
		{
			cleanup();
			clearSession();
			// TODO: dispatch event
			stopRefreshTimer();
		}
		
		private function clearSession():void
		{
			authToken = "";
			currentUserName = "";
			currentlyUploadingFile = null;
			this.isAuthenticated = false;
			uploadQueue = null;
		}
		
		/**
		 * 	login
		 */
		public function login(userName:String,password:String,rememberMe:Boolean = true):void
		{
			tempCredentials = rememberMe ? {username:userName,password:password} : null;
			
			if(checkCredentials())
			{
				if(_loginAction == null)
				{
					currentUserName = userName;
					_loginAction = new LoginAction();
					_loginAction.addEventListener(RestAction.REST_EVENT_ERROR,onLoginError);
					_loginAction.addEventListener(RestAction.REST_EVENT_SUCCESS,onLoginSuccess);
					_loginAction.userName = userName;
					_loginAction.password = password;
					_loginAction.execute();
					this.isAuthenticated = false;
					dispatchEvent(new YouTubeEvent(YouTubeEvent.YT_LOGIN_START));
				}
				else
				{
//					throw new Error("YouTube.LoginAction pending");
				}
			}
		}
		
		public function onLoginSuccess(evt:Event):void
		{
			// pull out our token
			this._authToken = _loginAction.authToken;
			this.isAuthenticated = true;
			
			if(isAuthenticated && tempCredentials)
			{
				storeUserCredentials();
			}
			else
			{
				clearUserCredentials();
			}
				
			dispatchEvent(new YouTubeEvent(YouTubeEvent.YT_LOGIN_SUCCESS));
			cleanup();
			
			refreshUserVideos();
			startRefreshTimer();
		}
		
		public function onLoginError(evt:Event):void
		{
			dispatchEvent(new YouTubeEvent(YouTubeEvent.YT_LOGIN_ERROR));
			cleanup();
		}
		
		/**
		 * 	get user videos 
		 */
		public function refreshUserVideos():void
		{
			if(checkCredentials() && !isUploading)
			{
				if(_getUserVideosAction == null)
				{
					_getUserVideosAction = new GetUserVideosAction();
					_getUserVideosAction.addEventListener(RestAction.REST_EVENT_ERROR,onGetUserVideosError);
					_getUserVideosAction.addEventListener(RestAction.REST_EVENT_SUCCESS,onGetUserVideosSuccess);
					_getUserVideosAction.execute(authToken,_clientID,_devKey);
				}
				else
				{
//					throw new Error("YouTube.GetUserVideosAction pending");
				}
			}
		}
		
		public function onGetUserVideosError(evt:Event):void
		{
			//trace("onGetUserVideosError");
			// TODO: Dispatch event
			cleanup();
		}
		

		
		public function onGetUserVideosSuccess(evt:Event):void
		{
			var preEventVidCount:int = userVideos.length;
			// update the list of user videos ...
			var totalResults:int = _getUserVideosAction.totalResults;
			var itemsPerPage:int = _getUserVideosAction.itemsPerPage;
			var startIndex:int = _getUserVideosAction.startIndex;
			
			var arr:Array = _getUserVideosAction.items;
			var procCount:int = 0;
			
			for(var n:int = 0; n < arr.length; n++)
			{
				var userVid:UserVideo = arr[n] as UserVideo;
				if(_userVideoMap[userVid.id] == null)
				{
					userVideos.addItem(userVid);
					_userVideoMap[userVid.id] = userVid;
					
				}
				else
				{	// call update so we only change properties and allow bindings to update
					_userVideoMap[userVid.id].update(userVid);
				}
				if(userVid.status == UserVideo.STATUS_PROCESSING)
				{
					procCount++;
				}
			}
			
			// need to know if we should fire an event ( after cleanup )
			var hasProcCountChanged:Boolean = (procCount != processingCount);
			processingCount = procCount;
			
			var sort:Sort = new Sort();
			sort.fields = [new SortField("published",true,true)];
			userVideos.sort = sort;
			userVideos.refresh();
			cleanup();
			
			if(hasProcCountChanged)
			{
				// dispatch event
				var procChangeEvent:YouTubeEvent = new YouTubeEvent(YouTubeEvent.YT_PROCESSING_COUNT_CHANGE);
					procChangeEvent.data = processingCount;
				dispatchEvent(procChangeEvent);
			}
			if(userVideos.length != preEventVidCount)
			{
				var gotVidsEvent:YouTubeEvent = new YouTubeEvent(YouTubeEvent.YT_GOT_USER_VIDEOS);
				dispatchEvent(gotVidsEvent);
			}
		}
		
		private function addFileToQueue(filePath:String):int
		{
				
			_uploadQueue.addItem(UserUpload.create(filePath));
			updateBindings();
			return _uploadQueue.length;
		}
		
		public function removeFileFromQueue(upld:UserUpload):void
		{
			var length:int = uploadQueue.length;
			for(var n:int = 0; n < length; n++)
			{
				var file:File = _uploadQueue.getItemAt(n).file as File;
				if(file != null && file == upld.file)
				{
					_uploadQueue.removeItemAt(n);
					break;
				}
			}
		}
		
		public function startUploading():void
		{
			if(checkCredentials() && uploadQueue.length > 0)
			{
				this.isUploading = true;
				this.totalUploads = this.uploadQueue.length;
				uploadNextVideo();
				
			}
		}
		
		private function uploadNextVideo():void
		{
			if(_getUploadTokenAction == null)
			{
				currentlyUploadingFile = null;
				for(var n:int = 0; n < _uploadQueue.length ; n++)
				{
					var userUpload:UserUpload = _uploadQueue[n] as UserUpload;
					if(userUpload.status == UserUpload.STATUS_QUEUED)
					{
						userUpload.status = UserUpload.STATUS_PENDING;
						currentlyUploadingFile = userUpload;
						
						_getUploadTokenAction = new GetUploadTokenAction();
						
						var formatedName:String = currentlyUploadingFile.name;
						//	remove extension
						var formatedNameSplit:Array = formatedName.split(".");
						if(formatedNameSplit[formatedNameSplit.length-1].toUpperCase()=="FLV")
							formatedNameSplit.pop();
						//	change "|" to ":"
						formatedName = formatedNameSplit.join(".");
						formatedName = formatedName.split("|").join(":");
						
						_getUploadTokenAction.mediaTitle = formatedName;
						_getUploadTokenAction.mediaDescription = currentlyUploadingFile.description;
						_getUploadTokenAction.mediaKeywords = currentlyUploadingFile.keywords;
						
						_getUploadTokenAction.isPublic = currentlyUploadingFile.isPublic;
						
						
						_getUploadTokenAction.addEventListener(RestAction.REST_EVENT_ERROR,onGetUploadTokenError);
						_getUploadTokenAction.addEventListener(RestAction.REST_EVENT_SUCCESS,onGetUploadTokenSuccess);
						_getUploadTokenAction.execute(authToken,_clientID,_devKey);
						dispatchEvent(new Event("upload_start"));
						break;
					}
				}
				if(currentlyUploadingFile == null) // still null?
				{
					this.stopUploading();
				}
				updateBindings();
			}
			else
			{
//				throw new Error("YouTube.GetUploadTokenAction pending");
			}
			
		}
		
		private function onGetUploadTokenError(err:Event):void
		{
			// TODO: Dispatch Event
			//trace("YouTubeService::onGetUploadTokenError");
			cleanup();
			currentlyUploadingFile.status = UserUpload.STATUS_ERROR;
		}
		
		private function onGetUploadTokenSuccess(evt:Event):void
		{
			var token:String = _getUploadTokenAction.token;
			var url:String = _getUploadTokenAction.uploadUrl;
			
			cleanup();
			
			_uploadAction = new UploadAction();
			_uploadAction.file = currentlyUploadingFile.file;
			_uploadAction.uploadToken = token;
			_uploadAction.url = url;
			_uploadAction.addEventListener(RestAction.REST_EVENT_ERROR,onUploadError);
			_uploadAction.addEventListener(RestAction.REST_EVENT_SUCCESS,onUploadSuccess);
			_uploadAction.addEventListener(UploadAction.REST_EVENT_PROGRESS,onUploadProgress);
			_uploadAction.execute();
			
			currentlyUploadingFile.status = UserUpload.STATUS_UPLOADING;
		}
		
		private function onUploadError(evt:Event):void
		{
			// add to failed list
			cleanup();
			currentlyUploadingFile.status = UserUpload.STATUS_ERROR;
			dispatchEvent(new YouTubeEvent(YouTubeEvent.YT_UPLOAD_ERROR));
			dispatchEvent(new YouTubeEvent(YouTubeEvent.YT_UPLOAD_COMPLETE));
			updateBindings();
		}
		
		private function onUploadSuccess(evt:Event):void
		{
			var id:String = _uploadAction.videoId;
			currentlyUploadingFile.status = UserUpload.STATUS_COMPLETED;
			
			cleanup();
			
			dispatchEvent(new YouTubeEvent(YouTubeEvent.YT_UPLOAD_SUCCESS));
			dispatchEvent(new YouTubeEvent(YouTubeEvent.YT_UPLOAD_COMPLETE));
			
			if(isUploading)
			{
				uploadNextVideo();
			}

			updateBindings();
		}
		
		public function stopUploading():void
		{
			this.isUploading = false;
			if(_uploadAction != null)
			{
				_uploadAction.cancelUpload();
				if(currentlyUploadingFile)
					currentlyUploadingFile.status = UserUpload.STATUS_QUEUED;
			}
			updateBindings();
		}
		
		private function onUploadProgress(evt:Event):void
		{
			var bytesLoaded:int = _uploadAction.bytesLoaded;
			var bytesTotal:int = _uploadAction.bytesTotal;
			this.currentlyUploadingFile.bytesTotal = _uploadAction.bytesTotal;
			this.currentlyUploadingFile.bytesLoaded = _uploadAction.bytesLoaded;
			var progEvt:YouTubeEvent = new YouTubeEvent(YouTubeEvent.YT_UPLOAD_PROGRESS);
				progEvt.data = {bytesLoaded:bytesLoaded,bytesTotal:bytesTotal};
				
			dispatchEvent(progEvt);
		}
		
		public function storeUserCredentials():void
		{
			var so:SharedObject = SharedObject.getLocal(localSharedObjKey);
				so.data.username = tempCredentials.username;
				so.data.password = tempCredentials.password;
				so.flush();
		}
		
		public function clearUserCredentials():void
		{
			var so:SharedObject = SharedObject.getLocal(localSharedObjKey);
				so.data.username = null;
				so.data.password = null;
				so.flush();
		}
		
		public function get storedUsername():String
		{
			var so:SharedObject = SharedObject.getLocal(localSharedObjKey);
			if(so.data.username != null)
			{
				return so.data.username;
			}
			return "";
		}
		
		public function get storedPassword():String
		{
			var so:SharedObject = SharedObject.getLocal(localSharedObjKey);
			if(so.data.password != null)
			{
				return so.data.password;
			}
			return "";
		}


		private function checkCredentials():Boolean
		{
			if(this._clientID == null 	|| this._clientID.length <= 0 	||
			   this._devKey == null 	|| this._devKey.length <= 0)
		   {
		   		// dispatch error no credentials event
		   		dispatchEvent(new YouTubeEvent(YouTubeEvent.YT_NO_CREDENTIALS));
		   		return false;
		   }
		   return true;
		}
		
		private function cleanup():void
		{
			if(_loginAction != null)
			{
				_loginAction.removeEventListener(RestAction.REST_EVENT_ERROR,onLoginError);
				_loginAction.removeEventListener(RestAction.REST_EVENT_SUCCESS,onLoginSuccess);
				_loginAction = null;
			}
			if(_logoutAction != null)
			{
				_logoutAction.removeEventListener(RestAction.REST_EVENT_ERROR,onLogoutError);
				_logoutAction.removeEventListener(RestAction.REST_EVENT_SUCCESS,onLogoutSuccess);
			}
			if(_uploadAction != null)
			{
				_uploadAction.removeEventListener(RestAction.REST_EVENT_ERROR,onUploadError);
				_uploadAction.removeEventListener(RestAction.REST_EVENT_SUCCESS,onUploadSuccess);
				_uploadAction.removeEventListener(UploadAction.REST_EVENT_PROGRESS,onUploadProgress);
				_uploadAction = null;
			}
			if(_getUserVideosAction != null)
			{
				_getUserVideosAction.removeEventListener(RestAction.REST_EVENT_ERROR,onGetUserVideosError);
				_getUserVideosAction.removeEventListener(RestAction.REST_EVENT_SUCCESS,onGetUserVideosSuccess);
				_getUserVideosAction = null;
			}
			if(_getUploadTokenAction != null)
			{
				_getUploadTokenAction.removeEventListener(RestAction.REST_EVENT_ERROR,onRestError);
				_getUploadTokenAction.removeEventListener(RestAction.REST_EVENT_SUCCESS,onGetUploadTokenSuccess);
				_getUploadTokenAction = null;
			}
		}
		
		// Refresh Timer
		
		private function startRefreshTimer():void
		{
			if(_refreshTimer == null)
			{
				_refreshTimer = new Timer(TIMER_INTERVAL);
				_refreshTimer.addEventListener(TimerEvent.TIMER,onRefreshTimer);
			}
			_refreshTimer.start();
		}
		
		private function stopRefreshTimer():void
		{
			if(_refreshTimer != null)
			{
				_refreshTimer.stop();
			}
		}
		
		private function onRefreshTimer(evt:TimerEvent):void
		{
			refreshUserVideos();
		}
		
		
		// Event Handlers
		private function onRestError(evt:Event):void
		{
			trace("YouTubeService::onRestError::");
			// TODO: Dispatch Event
			cleanup();
			currentlyUploadingFile = null;
		}
		
		private function updateBindings(evt:CollectionEvent = null):void
		{
			// these calls simply update bindings, the real values are retieved from the getters
			completedUploadCount = -1;
			failedUploadCount = -1;
			pendingUploadCount = -1;
		}
		
		
		
	}
	
	
}