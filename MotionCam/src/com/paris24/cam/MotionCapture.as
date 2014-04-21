package com.paris24.cam
{
	import com.paris24.events.MotionEvent;
	
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.text.TextField;
	
	[Event(name="videoFrame",type="flash.events.Event")]
	[Event(name="motion",type="flash.events.MotionEvent")]
	[Event(name="idle",type="flash.events.MotionEvent")]
	public class MotionCapture extends EventDispatcher
	{
		static private const NULLPOINT:Point = new Point();
		static private const IDLETIME:int = 5000;
		
		private var cam:Camera;
		
		private var bmpd:BitmapData;
		private var oldBmpd:BitmapData;
		private var diff:BitmapData;
		private var resultBitmap:BitmapData;
		
		private var tf:TextField= new TextField();
		private var _video:Video = new Video();
		public var pixelThreshold:int = 20;
		public var diffThreshold:uint = 0xFF272727;
		public var idle:Boolean = true;
		private var date:Date;
		
		static public var active:Boolean = true;
		
		public function MotionCapture(cam:Camera = null)
		{
			attachCamera(cam);
			tf.textColor = 0xFFFFFF;
			tf.mouseEnabled = false;
		}
		
		public function onFrame(e:Event):void {
			if(MotionCapture.active) {
				ensureSize();
				cam.drawToBitmapData(bmpd);
				diff.copyPixels(oldBmpd,oldBmpd.rect,NULLPOINT);
				diff.draw(bmpd,null,null,BlendMode.DIFFERENCE);
				
				var pixelDiff:int = (diff.threshold(diff,diff.rect,NULLPOINT,">", diffThreshold, 0xFF000000));
				if(pixelDiff>=pixelThreshold) {
					date = new Date();
					resultBitmap.copyPixels(bmpd,bmpd.rect,NULLPOINT);
					tf.text = "SPYCAM. "+date.toLocaleString();
					tf.height = 20;
					resultBitmap.draw(tf,new Matrix(1,0,0,1,0,resultBitmap.height-tf.height),null,BlendMode.DIFFERENCE);
					dispatchEvent(new MotionEvent(MotionEvent.MOTION));
					idle = false;
				}
				else if(idle) {
					var now:Date = new Date(); 
					if(!date || now.time-date.time>IDLETIME) {
						dispatchEvent(new MotionEvent(MotionEvent.IDLE));
						idle = true;	
					}
				}
				
				var temp:BitmapData = bmpd;
				bmpd = oldBmpd;
				oldBmpd = temp;
			}
			dispatchEvent(e);
		}
		
		public function get running():Boolean {
			return bmpd!=null;
		}
		
		public function get bitmapData():BitmapData {
			return resultBitmap;
		}
		
		public function attachCamera(value:Camera):void {
			if(cam) {
				cam.removeEventListener(Event.VIDEO_FRAME,onFrame);
			}
			cam = value;
			_video.attachCamera(cam);
			idle = true;
			if(cam) {
				cam.addEventListener(Event.VIDEO_FRAME,onFrame);
			}
		}
		
		public function get video():Video {
			return _video;
		}
		
		public function get camera():Camera {
			return cam;
		}
		
		public function get lastCapture():Date {
			return date;
		}
				
		public function close():void {
			video.attachCamera(null);
			cam.removeEventListener(Event.VIDEO_FRAME,onFrame);
			clearBitmaps();
		}
		
		private function clearBitmaps():void {
			if(bmpd) {
				bmpd.dispose();
				oldBmpd.dispose();
				diff.dispose();
				resultBitmap.dispose();
				bmpd = null;
				oldBmpd = null;
				diff = null;
				resultBitmap = null;
			}
		}
		
		private function ensureSize():void {
			if(bmpd && (bmpd.width!=cam.width || bmpd.height!=cam.height)) {
				clearBitmaps();
			}

			if(!bmpd) {
				bmpd = new BitmapData(cam.width,cam.height,false,0);
				oldBmpd = new BitmapData(cam.width,cam.height,false,0);
				diff = new BitmapData(cam.width,cam.height,false,0);
				resultBitmap = new BitmapData(cam.width,cam.height,false,0);
				tf.width = cam.width;
			}
		}
	}
}