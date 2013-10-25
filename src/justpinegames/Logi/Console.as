package justpinegames.logi
{
    import feathers.controls.Button;
    import feathers.controls.List;
    import feathers.controls.ScrollContainer;
    import feathers.controls.Scroller;
    import feathers.controls.renderers.IListItemRenderer;
    import feathers.controls.text.BitmapFontTextRenderer;
    import feathers.core.FeathersControl;
    import feathers.core.ITextRenderer;
    import feathers.data.ListCollection;
    import feathers.layout.VerticalLayout;
    import feathers.text.BitmapFontTextFormat;

    import flash.desktop.Clipboard;
    import flash.desktop.ClipboardFormats;
    import flash.utils.getQualifiedClassName;

    import starling.animation.Juggler;
    import starling.core.Starling;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.EnterFrameEvent;
    import starling.events.Event;
    import starling.events.ResizeEvent;
    import starling.text.BitmapFont;
    import starling.textures.TextureSmoothing;

    /**
     * Main class, used to display console and handle its events.
     */
    final public class Console extends Sprite
    {
        private static var _console:Console;
        private static var _archiveOfUndisplayedLogs:Vector.<String> = new <String>[];
        
        private var _consoleSettings:ConsoleSettings;
        private var _defaultFont:BitmapFont;
        private var _format:BitmapFontTextFormat;
        private var _formatBackground:BitmapFontTextFormat;
        private var _consoleContainer:Sprite;
        private var _hudContainer:ScrollContainer;
        private var _consoleHeight:Number;
        private var _isShown:Boolean;
        private var _hideButton:Button;
        private var _clearButton:Button;
        private var _data:Vector.<Object>;
        private var _quad:Quad;
        private var _list:List;

        private var _juggler:Juggler;

        private const VERTICAL_PADDING: Number = 5;
        private const HORIZONTAL_PADDING: Number = 5;
        
        /**
         * You need to create the instance of this class and add it to the stage in order to use this library.
         * 
         * @param   consoleSettings   Optional parameter which can specify the look and behaviour of the console.
         */
        public function Console(consoleSettings:ConsoleSettings = null) 
        {
            _consoleSettings = consoleSettings ? consoleSettings : new ConsoleSettings();
            
            _console = _console ? _console : this;

            _juggler = new Juggler();
			Starling
            _data = new Vector.<Object>();
            
            _defaultFont = new BitmapFont();
            _format = new BitmapFontTextFormat(_defaultFont, 16, _consoleSettings.textColor);
            _format.letterSpacing = 2;
            _formatBackground = new BitmapFontTextFormat(_defaultFont, 16, _consoleSettings.textBackgroundColor);
            _formatBackground.letterSpacing = 2;
            
            this.addEventListener(Event.ADDED_TO_STAGE, onAddedToStageHandler);
        }
        
        public function get isShown():Boolean { return _isShown; }
        public function set isShown(value:Boolean):void 
        {
            if (_isShown == value) return;
            _isShown = value;
            
            if (_isShown) show();
            else          hide();
        }
        
        private function onAddedToStageHandler(e:Event):void
        {
            this.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStageHandler);

            _consoleHeight = this.stage.stageHeight * _consoleSettings.consoleSize;
            
            _isShown = false;
            
            _consoleContainer = new FeathersControl();
            _consoleContainer.alpha = 0;
            _consoleContainer.y = -_consoleHeight;
            this.addChild(_consoleContainer);
            
            _quad = new Quad(this.stage.stageWidth, _consoleHeight, _consoleSettings.consoleBackground);
            _quad.alpha = _consoleSettings.consoleTransparency;
            _consoleContainer.addChild(_quad);
            
            // TODO Make the list selection work correctly.
            _list = new List();
            _list.x = HORIZONTAL_PADDING;
            _list.y = VERTICAL_PADDING;
            _list.itemRendererProperties.labelField = "data";
            _list.dataProvider = new ListCollection(_data);
            _list.itemRendererFactory = function():IListItemRenderer
            {
                var consoleItemRenderer:ConsoleItemRenderer = new ConsoleItemRenderer(_consoleSettings.textColor, _consoleSettings.highlightColor);
                consoleItemRenderer.width = _list.width;
                consoleItemRenderer.height = 20;
                return consoleItemRenderer;
            };
            _list.scrollBarDisplayMode = Scroller.SCROLL_BAR_DISPLAY_MODE_NONE;

            _consoleContainer.addChild(_list);

            _list.backgroundSkin = null;
            
            _hideButton = new Button();
            _hideButton.label = "Hide";
            _hideButton.addEventListener(Event.ADDED, function(e:Event):void
            {
                _hideButton.labelFactory = function():ITextRenderer
                {
                    return new BitmapFontTextRenderer();
                };
                _hideButton.defaultLabelProperties.smoothing = TextureSmoothing.NONE;
                _hideButton.defaultLabelProperties.textFormat = new BitmapFontTextFormat(_defaultFont, 16, _consoleSettings.textColor);
                _hideButton.downLabelProperties.smoothing = TextureSmoothing.NONE;
                _hideButton.downLabelProperties.textFormat = new BitmapFontTextFormat(_defaultFont, 16, _consoleSettings.highlightColor);

                _hideButton.stateToSkinFunction = function(target:Object, state:Object, oldValue:Object = null):Object
                {
                    return null;
                };

                _hideButton.width = 150;
                _hideButton.height = 40;
            });
            _hideButton.addEventListener(Event.TRIGGERED, hide);
            _consoleContainer.addChild(_hideButton);
			
			_clearButton = new Button();
			_clearButton.label = "Clear";
            _clearButton.addEventListener(Event.ADDED, function(e:Event):void
            {
                _clearButton.labelFactory = function():ITextRenderer
                {
                    return new BitmapFontTextRenderer();
                };
                _clearButton.defaultLabelProperties.smoothing = TextureSmoothing.NONE;
                _clearButton.defaultLabelProperties.textFormat = new BitmapFontTextFormat(_defaultFont, 16, _consoleSettings.textColor);
                _clearButton.downLabelProperties.smoothing = TextureSmoothing.NONE;
                _clearButton.downLabelProperties.textFormat = new BitmapFontTextFormat(_defaultFont, 16, _consoleSettings.highlightColor);
				_clearButton.stateToSkinFunction = function(target:Object, state:Object, oldValue:Object = null):Object
                {
                    return null;
                };
                _clearButton.width  = 150;
                _clearButton.height = 40;
            });
            _clearButton.addEventListener(Event.TRIGGERED, clear);
            _consoleContainer.addChild(_clearButton);
            
            _hudContainer = new ScrollContainer();
            // TODO This should be changed to prevent the hud from even creating, not just making it invisible.
            if (!_consoleSettings.hudEnabled) _hudContainer.visible = false;

            _hudContainer.x = HORIZONTAL_PADDING;
            _hudContainer.y = VERTICAL_PADDING;
            _hudContainer.touchable = false;
            _hudContainer.layout = new VerticalLayout();
            _hudContainer.scrollerProperties.verticalScrollPolicy = Scroller.SCROLL_POLICY_OFF;
            this.addChild(_hudContainer);
            
            this.setScreenSize(Starling.current.nativeStage.stageWidth, Starling.current.nativeStage.stageHeight);
            
            for each (var undisplayed:* in _archiveOfUndisplayedLogs)
                this.logMessage(undisplayed);

            _archiveOfUndisplayedLogs = new Vector.<String>();
            
            stage.addEventListener(ResizeEvent.RESIZE, function(e:ResizeEvent):void 
            {
                setScreenSize(stage.stageWidth, stage.stageHeight);
            });

            this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }
		

        private function onEnterFrame(event:EnterFrameEvent):void
        {
            _juggler.advanceTime(event.passedTime);
        }

        private function setScreenSize(width:Number, height:Number):void 
        {
            _consoleContainer.width = width;
            _consoleContainer.height = height;
            
            _consoleHeight = height * _consoleSettings.consoleSize;
            
            _quad.width = width;
            _quad.height = _consoleHeight;
            
            _hideButton.x = width - 110 - HORIZONTAL_PADDING;
            _hideButton.y = _consoleHeight - 33 - VERTICAL_PADDING;
            
			_clearButton.x = _hideButton.x - 110 - HORIZONTAL_PADDING;
            _clearButton.y = _consoleHeight - 33 - VERTICAL_PADDING;
            
            _list.width = this.stage.stageWidth - HORIZONTAL_PADDING * 2;
            _list.height = _consoleHeight - VERTICAL_PADDING * 2;
            
            if (!_isShown) _consoleContainer.y = -_consoleHeight;
        }
        
        private function show():void 
        {
            _consoleContainer.visible = true;

            _juggler.tween(_consoleContainer, _consoleSettings.animationTime, { y: 0, alpha: 1 });
            _juggler.tween(_hudContainer, _consoleSettings.animationTime, { alpha: 0 });

            _isShown = true;
        }
        
        private function hide():void 
        {
            _juggler.tween(_consoleContainer, _consoleSettings.animationTime, { y: -_consoleHeight, alpha: 0, onComplete:function():void {
                _consoleContainer.visible = false;
            }});
            _juggler.tween(_hudContainer, _consoleSettings.animationTime, { alpha: 1 });

            _isShown = false;
        }

        /**
         * You can use this data to save a log to the file.
         * 
         * @return  Log messages joined into a String with new lines.
         */
        public function getLogData():String 
        {
            var text:String = "";
            for each (var object:Object in _data) text += object.data + "\n";

            return text;
        }
        
        
		/**
		 * clear the console
		 */
		public function clear():void {
			_list.dataProvider.removeAll();
			_data.length = 0;
			logMessage("Cleared");
		}
		
        /**
         * Displays the message string in the console, or on the HUD if the console is hidden.
         * 
         * @param   message   String to display
         */
        public function logMessage(message:String):void 
        {
            if (_consoleSettings.traceEnabled) trace(message);

            var prefix:String = (new Date()).toLocaleTimeString() + ": ";

            var messageParts:Array = message.split("\n");

            for each (var messagePart:String in messageParts)
            {
                showInHud(messagePart);

                var labelDisplay:String = prefix + messagePart;
                _list.dataProvider.push({label: labelDisplay, data: messagePart});

                // after the first iteration set prefix to empty string:
                prefix = "";
            }
			if (_list.dataProvider.length > 0) {
				_list.scrollToDisplayIndex(_list.dataProvider.length - 1);
			}
        }

        private function showInHud(message:String):void
        {
            var createLabel:Function = function(text:String, format:BitmapFontTextFormat):BitmapFontTextRenderer
            {
                var label:BitmapFontTextRenderer = new BitmapFontTextRenderer();
                label.addEventListener(Event.ADDED, function(e:Event):void
                {
                    label.textFormat = format;
                });
                label.smoothing = TextureSmoothing.NONE;
                label.text = text;
                label.validate();
                return label;
            };

            var hudLabelContainer:FeathersControl = new FeathersControl();
            hudLabelContainer.width = 640;
            hudLabelContainer.height = 20;

            var addBackground:Function = function(offsetX:int, offsetY: int):void
            {
                var hudLabelBackground:BitmapFontTextRenderer = createLabel(message, _formatBackground);
                hudLabelBackground.x = offsetX;
                hudLabelBackground.y = offsetY;
                hudLabelContainer.addChild(hudLabelBackground);
            };

            addBackground(0, 0);
            addBackground(2, 0);
            addBackground(0, 2);
            addBackground(2, 2);

            var hudLabel:BitmapFontTextRenderer = createLabel(message, _format);
            hudLabel.x += 1;
            hudLabel.y += 1;
            hudLabelContainer.addChild(hudLabel);

            _hudContainer.addChildAt(hudLabelContainer, 0);

            _juggler.tween(hudLabelContainer, _consoleSettings.hudMessageFadeOutTime, {
                delay: _consoleSettings.hudMessageDisplayTime, alpha: 0,
                onComplete:function():void { hudLabelContainer.removeFromParent(true); }
            });
        }
        
        /**
         * Returns the first created Console instance.
         * 
         * @return Console instance
         */
        public static function getMainConsoleInstance():Console 
        {
            return _console;
        }
        
        /**
        * Main log function. Usage is the same as for the trace statement.
        * 
        * For data sent to the log function to be displayed, you need to first create a LogConsole instance, and add it to the Starling stage.
        * 
        * @param    ... arguments   Variable number of arguments, which will be displayed in the log
        */
        public static function staticLogMessage(... arguments):void 
        {
            var message:String = "";
            var firstTime:Boolean = true;
            
            for each (var argument:* in arguments)
            {
                var description:String;
                
                if (argument == null)
                {
                    description = "[null]"
                }
                else if (!("toString" in argument)) 
                {
                    description = "[object " + getQualifiedClassName(argument) + "]";
                }
                else 
                {
                    description = argument;
                }
                
                if (firstTime)
                {
                    message = description;
                    firstTime = false;
                }
                else
                {
                    message += ", " + description;
                }
            }

            var console:Console = Console.getMainConsoleInstance();
            if (console) console.logMessage(message);
            else         _archiveOfUndisplayedLogs.push(message);
        }
    }
}