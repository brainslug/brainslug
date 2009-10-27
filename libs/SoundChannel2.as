﻿package com.birnamdesigns {
	import flash.events.IEventDispatcher;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.events.Event;
	
	/**
	* ...
	* @author David Woods
	* @link http://www.birnamdesigns.com
	* @license distributed under the MIT license -- do what you want with it! 
	* This code is distributed as-is, so tell me about problems but don't blame me for them!
	* @usage once constructed, use is identical to the SoundChannel class. The constructor
	* receives an existing SoundChannel (such as what is passed from the Sound.play() function),
	* as well as (optionally) the positionOffset this class uses to correct for the bug.
	*/
	
	/**
	 * SoundChannel2 class
	 * This is a wrapper for SoundChannel, to get around bug FP-33 http://bugs.adobe.com/jira/browse/FP-33
	 * Use with Sound2 class.
	 * 
	 * GENERAL INFO:
	 * 
	 * There are two sides to this problem. The first occurs when seeking to a point in an audio file that does not have a 44100khz sample rate.
	 * The actual playback point is advanced from the desired one by a factor determined by the actual sample rate / 44100khz.  So trying to go three
	 * seconds into a sound in a 22050 rate sound will actually start at the six second point.
	 * 
	 * The other side of the problem is that the start point is adjusted (from zero!) by a value determined by the same ratio. It looks at first like
	 * the position is effected by the ratio, but it's in fact the start point. Once started, the position progresses as expected, advancing 1000
	 * for every second.
	 * 
	 * This class creates a positionOffset property that can be used manually, or it can be used in conjuction with SoundChannel2 which handles
	 * the positionOffset automatically
	 * 
	 * You can put as many sample rates into the trialRates array as you like, but the more you have the longer the load delay is because of the time
	 * it takes to evaluate each one.
	 * 
	 * The time (in milliseconds) devoted to testing each rate is stored in the sensitivity property, and can be modified to suit your tastes. I don't
	 * know enough about the sound loading process behind-the-scenes to know why it takes a little time between playing a sound at a position after the
	 * end, and for the SOUND_COMPLETE event to fire, which is what this uses to evaluate the sample rates. Through experimentation I found that the 
	 * event was regularly fired within 300 milliseconds for me. This may be dependent on the viewer's computer's speed, so keep this in mind when
	 * testing your project.
	 * 
	 * The sensitivity time causes a delay in the file loading that is proportional to the number of rates stored in the trialRates array. The more
	 * rates you are checking the more times the test timer has to fire. This can add up, but in my tests mean about a second difference in load time.
	 * (it is not dependent on the size of the file) 
	 * 
	 * Any COMPLETE event listening for the sound file to finish loading will be notified after the sound has loaded AND after the sample rate has
	 * been evaluated. This basically expands the COMPLETE event to act more like a READY event.
	 */
	
	/**
	 * Since Adobe/Macromedia create SoundChannel as a 'final' class, this is a wrapper instead of a subclass
	 */
	public class SoundChannel2 implements IEventDispatcher {
		/**
		 * When a non-44100 rate audio is played, the measured length and the playback speed are normal,
		 * i.e. the SoundChannel.position value will increase by 1000 every second. But when the audio is played
		 * from a non-zero position, the end points are adjusted my a value determined by the sampleratio and the starting point
		 */
		private var _positionOffset:Number = 0;
		public function get positionOffset():Number { return _positionOffset; }
		
		/**
		 * The object being wrapped
		 */
		public var soundChannel:SoundChannel;
		
		//{ region wrapper properties
		public function get leftPeak():Number { return soundChannel.leftPeak; }
		public function get rightPeak():Number { return soundChannel.rightPeak; }		
		public function get soundTransform():SoundTransform { return soundChannel.soundTransform; }
		public function set soundTransform(snd:SoundTransform):void { soundChannel.soundTransform = snd; }
		
		/**
		 * returns a corrected position based on the positionOffset passed in the constructor
		 * (positionOffset is generated by the Sound2 class)
		 */
		public function get position():Number { return soundChannel.position + positionOffset; }
		//} end region
		
		//{ region constructor and wrapper functions
		public function SoundChannel2(soundchannel:SoundChannel, offset:Number = 0) {
			soundChannel = soundchannel;
			_positionOffset = offset;
		}
		
		public function stop():void {
			soundChannel.stop();
		}
		//} end region
		
		//{ INTERFACE flash.events.IEventDispatcher
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			soundChannel.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public function dispatchEvent(event:Event):Boolean {
			return soundChannel.dispatchEvent(event);
		}
		
		public function hasEventListener(type:String):Boolean {
			return soundChannel.hasEventListener(type);
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			soundChannel.removeEventListener(type, listener, useCapture);
		}
		
		public function willTrigger(type:String):Boolean {
			return soundChannel.willTrigger(type);
		}
		//} end INTERFACE
		
	}
}