package justpinegames.logi 
{
	/**
	 * Used for styling console appearance and behaviour.
	 */
	final public class ConsoleSettings
	{
		public function ConsoleSettings() { }
		public var animationTime:Number = 0.2;
		public var consoleSize:Number = 0.33;
		public var textColor:int = 0xdddddd;
		public var textBackgroundColor:int = 0x555555;
		public var highlightColor:int = 0x999999;
		public var consoleBackground:int = 0x000000;
		public var consoleTransparency:Number = 0.7;
		public var traceEnabled:Boolean = false;
		public var hudEnabled:Boolean = true;
		public var hudMessageFadeOutTime:Number = 0.2;
		public var hudMessageDisplayTime:Number = 2;
		
		public var buttonTextSize:int=16;
		public var logTextSize:int=16;
		public var letterSpacing:int=2;
		public var lineHeight:int = 20;
	}
}