package com.birnamdesigns {
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import com.birnamdesigns.SoundChannel2;
	import flash.media.SoundTransform;
	import flash.events.*;
	import flash.media.SoundLoaderContext;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	/**
	* ...
	* @author David Woods
	* @link http://www.birnamdesigns.com
	* @license distributed under the MIT license -- do what you want with it! 
	* This code is distributed as-is, so tell me about problems but don't blame me for them!
	* @usage use it exactly like the existing Sound class, except you will need to use play2() instead of play() if you want
	* to use it with the SoundChannel2 class (this accommodates positionOffset automatically). This class delays the COMPLETE
	* event during sound load, so any event listeners looking for the sound file to load will be notified when both the sound
	* has loaded and when the sample rate has been evaluated.
	*/
	
	/**
	 * Sound2 class
	 * This is a replacement for Sound, to get around bug FP-33 http://bugs.adobe.com/jira/browse/FP-33
	 * Use with SoundChannel2 class.
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
	public class Sound2 extends Sound {
		
		/**
		 * Array of rates to test for. The more rates you include the longer the load delay. 
		 * NOTE: These need to be in order!
		 */
		public var trialRates:Array = [11025, 22050, 44100];
		
		/**
		 * Ratio of derived sample rate to 44100 default. e.g. 22050 rate audio has a sampleRatio of 0.5
		 */
		public var sampleRatio:Number = 1;
		
		/**
		 * When a non-44100 rate audio is played, the measured length and the playback speed are normal,
		 * i.e. the SoundChannel.position value will increase by 1000 every second. But when the audio is played
		 * from a non-zero position, the end points are adjusted my a value determined by the sampleratio and the starting point
		 */
		public var positionOffset:Number = 0;
		
		/**
		 * if the actual rate was not included in the trialRates, the derived sample ratio may be a false positive, this will tell. 
		 * NOTE: the actual rate might also be less than the smallest trial rate, which is also a false positive scenario, but is not detected with this code.
		 */
		public var rateWasFound:Boolean = false;
		
		/**
		 * Milliseconds to wait for results from each rate test. Recommended (and default) value is 300, although higher values might be needed to account for slower computers..
		 */
		public var sensitivity:Number = 300;
		
		private var curRate:Number = 0;
		private var testTimer:Timer;
		private var soundtest:SoundChannel;
		private var triggered:Boolean = false;
		private var loadEvent:Event;
		
		/**
		 * returns a value calculated to trigger immediate SoundComplete for the current trial rate
		 */
		private function get teststart():Number { return length * ((trialRates[curRate] / 44100) + 0.1); }	// the 0.1 is arbitrary, the position just needs to be _after_ the trial/44100 position
		
		public function Sound2(stream:URLRequest = null, context:SoundLoaderContext = null) {
			addEventListener(Event.COMPLETE, _onSoundLoadComplete);
			super(stream, context);
		}
		
		public override function load(stream:URLRequest, context:SoundLoaderContext = null):void {
			super.load(stream, context);
		}
		
		/**
		 * use with normal SoundChannel, you must handle positionOffset yourself
		 * recommended: use play2 and SoundChannel2 to have that handled automatically
		 */
		public override function play(startTime:Number = 0, loops:int = 0, sndTransform:SoundTransform = null):SoundChannel {
			positionOffset = startTime - (startTime * sampleRatio);
			return super.play(startTime * sampleRatio, loops, sndTransform);
		}
		
		/**
		 * use with SoundChannel2 to handle positionOffset automatically
		 */
		public function play2(startTime:Number = 0, loops:int = 0, sndTransform:SoundTransform = null):SoundChannel2 {
			positionOffset = startTime - (startTime * sampleRatio);
			
			// uses SoundChannel2 to handle positionOffset automatically
			return new SoundChannel2(super.play(startTime * sampleRatio, loops, sndTransform), positionOffset);
		}
		
		private function testRate():void {
			// test sound at 0 volume, so it is not obvious
			soundtest = play(teststart, 0, new SoundTransform(0, 0));
			soundtest.addEventListener(Event.SOUND_COMPLETE, _onSoundComplete);
			testTimer = new Timer(sensitivity, 1);
			testTimer.addEventListener(TimerEvent.TIMER_COMPLETE, _onTimerEvent);
			testTimer.start();
		}
		
		//{region events
		private function _onSoundLoadComplete(e:Event):void {
			// store load event for delayed dispatch
			loadEvent = e;
			e.stopImmediatePropagation();
			removeEventListener(Event.COMPLETE, _onSoundLoadComplete);
			testRate();
		}
		
		private function _onSoundComplete(e:Event):void {
			triggered = true;
		}
		
		private function _onTimerEvent(e:TimerEvent):void {
			soundtest.stop();
			if (triggered || curRate == trialRates.length - 1) {				
				// sound completed too soon, we either found the sample rate or ran out of rates to try
				sampleRatio = trialRates[curRate] / 44100;
				rateWasFound = triggered;
				
				// clean up
				testTimer.stop();
				soundtest.removeEventListener(Event.SOUND_COMPLETE, _onSoundComplete);
				testTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, _onTimerEvent);
				
				// now send out that load event
				dispatchEvent(loadEvent);
			} else {
				// try next one
				curRate++;
				testRate();
			}
		}
		//} end region
	}
}