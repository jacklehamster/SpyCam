package com.paris24.events
{
	import flash.events.Event;
	
	public class MotionEvent extends Event
	{
		static public const MOTION:String = "motion";
		static public const IDLE:String = "idle";
		public function MotionEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event {
			return new MotionEvent(type,bubbles,cancelable);
		}
	}
}