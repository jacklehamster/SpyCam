package com.paris24.cam
{
	import com.paris24.events.MotionEvent;
	
	import flash.desktop.NativeApplication;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.net.SharedObject;
	import flash.system.Capabilities;
	
	import leelib.util.flvEncoder.FileStreamFlvEncoder;
	
	[Event(name="videoFrame",type="flash.events.Event")]
	[Event(name="motion",type="flash.events.MotionEvent")]
	[Event(name="idle",type="flash.events.MotionEvent")]
	public class FLVMotionCapture extends EventDispatcher
	{
		static protected const SEC:int = 1000;
		static protected const MB:Number = 1024*1024;
		static protected const MOTION_TIMEOUT:int = 10*SEC;
		static protected const MAXFILESIZE:Number = 20*MB;
		
		protected var motion:MotionCapture = new MotionCapture();
		
		protected var processedFile:File;
		protected var flv:FileStreamFlvEncoder;
		private var frameCount:int;
		private var fps:Number = 0;
		private var startCapture:Date;
		private var lastCapture:Date;
		private var shape:Shape = new Shape();
		
		private var needQuick:Boolean = false;
		
		
		public function FLVMotionCapture(cam:Camera=null)
		{
			motion.attachCamera(cam);
			motion.addEventListener(MotionEvent.MOTION,onMotionFrame);
			motion.addEventListener(Event.VIDEO_FRAME,onVideoFrame);
			NativeApplication.nativeApplication.addEventListener(Event.EXITING,finalizeFile);
		}
		
		public function close():void {
			motion.removeEventListener(Event.VIDEO_FRAME,onMotionFrame);
			motion.close();
		}
		
		public function attachCamera(value:Camera):void {
			motion.attachCamera(value);
		}
		
		public function get video():Video {
			return motion.video;
		}
		
		public function get camera():Camera {
			return motion.camera;
		}
		
		public function set frameRate(value:Number):void {
			fps = value;	
		}
		
		public function get frameRate():Number {
			return fps || (flv?flv.frameRate : 0);
		}
		
		private function onMotionFrame(e:MotionEvent):void {
			var now:Date = new Date();
			if(!processedFile) {
				var so:SharedObject = SharedObject.getLocal("FLVMotionCapture");
				so.setProperty("count",so.data.count ? so.data.count+1 : 1);
				
				startCapture = now;
				processedFile = captureDirectory.resolvePath(so.data.count+" - "+Capabilities.os+" @"+startCapture.toLocaleString().split(":").join("|")+".flv");
				trace("Processing:",processedFile.name);
				flv = new FileStreamFlvEncoder(processedFile,motion.camera.fps);
				flv.setVideoProperties(motion.camera.width, motion.camera.height);
				//	flv.setAudioProperties(FlvEncoder.SAMPLERATE_44KHZ, , false);
				flv.fileStream.open(processedFile,FileMode.WRITE);
				flv.start();
				frameCount = 0;
			}
			
			if(!lastCapture || now.time-lastCapture.time> 10*60*1000) {
				needQuick = true;
			}
			if(needQuick && now.time-startCapture.time>500) {
				// take quick snap and send it
				if(motion.bitmapData) {
					for(;frameCount<=flv.frameRate;frameCount++) {
						flv.addFrame(motion.bitmapData,null);
					}
				}
				so = SharedObject.getLocal("FLVMotionCapture");
				var newFile:File = captureDirectory.resolvePath("QUICKSNAP ["+so.data.count+"] @"+new Date().toLocaleString().split(":").join("|")+".flv");
				flv.file.copyTo(newFile);
				needQuick = false;
				dispatchEvent(new Event("kick"));
			}
			
			var duration:Number = now.time - startCapture.time;
			shape.graphics.clear();
			shape.graphics.beginFill(0x00FFFF,.4);
			shape.graphics.drawRect(0,motion.bitmapData.height-35,motion.bitmapData.width*Math.min(1,duration/(60*1000)),3);
			shape.graphics.endFill();
			
			if(needQuick) {
				shape.graphics.lineStyle(4,0xFFFFFF,.4);
				shape.graphics.drawRect(40,40,motion.bitmapData.width-80,motion.bitmapData.height-80);
			}
			
			motion.bitmapData.draw(shape);
			shape.graphics.clear();
			
			flv.addFrame(motion.bitmapData,null);
			frameCount++;
			dispatchEvent(e);
			lastCapture = now;
		}
		
		private function onVideoFrame(e:Event):void {
			if(motion.running) {
				var now:Date = new Date();
				
				if(processedFile) {
					if(now.time-motion.lastCapture.time>MOTION_TIMEOUT 
						|| flv.fileStream.position>MAXFILESIZE	//	20 mb
						|| now.time-startCapture.time > 30*60*1000	//	30 mins
					) {
						finalizeFile();
					}
				}
			}
			dispatchEvent(e);
		}
		
		private function finalizeFile(e:Event=null):void {
			if(flv) {
				if(motion.bitmapData) {
					for(;frameCount<=flv.frameRate;frameCount++) {
						flv.addFrame(motion.bitmapData,null);
					}
				}
				
				trace("File complete:",flv.file.name);
				flv.fileStream.close();
				
				var duration:Number = lastCapture?(lastCapture.time-startCapture.time):0;

				var fileName:String = flv.file.name;
				var fileNameSplit:Array = fileName.split(".");
				fileNameSplit.pop();
				fileName = fileNameSplit.join(".") + ". Dur| "+Math.round(duration/1000)+" sec " + ".flv";
				
				var newFile:File = captureDirectory.resolvePath(fileName);
				flv.file.moveTo(newFile);
					
				dispatchEvent(new Event(Event.COMPLETE));
			}
			
			processedFile = null;
			flv = null;
			frameCount = 0;
		}
		
		public function get captureDirectory():File {
			var dir:File = File.applicationStorageDirectory.resolvePath("capture");
			if(!dir.exists) {
				dir.createDirectory();
			}
			return dir;
		}
	}
}