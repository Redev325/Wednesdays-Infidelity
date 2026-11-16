package;

import data.ClientPrefs;
import data.CppAPI;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.input.keyboard.FlxKey;
import haxe.CallStack;
import input.Controls;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.events.Event;
import openfl.events.UncaughtErrorEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import states.menus.*;

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).

	public static var initialState:Class<FlxState> = WarningState; // The FlxState the game starts with.

	var zoom:Int = -1; // Integer scaling keeps Flixel's browser and desktop viewport sizing consistent.
	var framerate:Int = 60; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	public static var canToggleFullScreen:Bool = false; // Will be set true in Init to make sure everything is ready

	public static var fullscreenKeys:Array<Null<FlxKey>>;

	public static var fpsVar:FPS;

	private var diagnosticPopup:Sprite;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		// Listen on LoaderInfo so errors from the game and asynchronous asset
		// loading can be shown in the game window instead of only in the console.
		if (loaderInfo != null && loaderInfo.uncaughtErrorEvents != null)
		{
			loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
		}

		addEventListener(Event.ENTER_FRAME, update);
		setupGame();
	}

	public function update(e:Event)
	{
		if (FlxG.keys == null)
			return;

		// F8 opens/closes a live startup report. ESC hides the popup.
		if (FlxG.keys.justPressed.F8)
		{
			if (diagnosticPopup != null && diagnosticPopup.visible)
			{
				diagnosticPopup.visible = false;
			}
			else
			{
				showDiagnostic("HTML5 DIAGNOSTIC REPORT", buildDiagnosticReport());
			}
		}

		if (FlxG.keys.justPressed.ESCAPE && diagnosticPopup != null && diagnosticPopup.visible)
		{
			diagnosticPopup.visible = false;
		}

		if (canToggleFullScreen && fullscreenKeys != null)
		{
			var lastPressed:FlxKey = FlxG.keys.firstJustPressed();

			if (!fullscreenKeys.contains(lastPressed))
				return;

			for (key in fullscreenKeys)
			{
				if (key == null || key == FlxKey.NONE)
					continue;

				if (key == lastPressed)
				{
					FlxG.fullscreen = !FlxG.fullscreen;
					break;
				}
			}
		}
	}

	private function onUncaughtError(event:UncaughtErrorEvent):Void
	{
		var error:Dynamic = event.error;
		var message:String = Std.string(error);
		var stackText:String = "";

		if (error != null)
		{
			var errorMessage:Dynamic = Reflect.field(error, "message");
			var errorStack:Dynamic = Reflect.field(error, "stack");
			if (errorMessage != null)
				message = Std.string(errorMessage);
			if (errorStack != null)
				stackText = Std.string(errorStack);
		}

		if (stackText.length == 0)
		{
			for (call in CallStack.callStack())
			{
				stackText += Std.string(call) + "\n";
			}
		}

		trace("UNCAUGHT HTML5 RUNTIME ERROR: " + message);
		showDiagnostic("RUNTIME ERROR", message + "\n\nSTACK TRACE\n" + stackText + "\n\n" + buildDiagnosticReport());
	}

	private function buildDiagnosticReport():String
	{
		var stateName:String = "Not initialized";
		if (FlxG.state != null)
		{
			var stateClass = Type.getClass(FlxG.state);
			if (stateClass != null)
				stateName = Type.getClassName(stateClass);
		}

		var width:Int = stage != null ? stage.stageWidth : 0;
		var height:Int = stage != null ? stage.stageHeight : 0;
		var lines:Array<String> = [
			"Platform: HTML5",
			"Time: " + Std.string(Date.now()),
			"Viewport: " + width + " x " + height,
			"Game state: " + stateName,
			"Flixel input: " + (FlxG.keys == null ? "not ready" : "ready"),
			""
		];

		for (library in ["shared", "songs", "videos"])
		{
			var isLoaded:Bool = false;
			try
			{
				isLoaded = Assets.getLibrary(library) != null;
			}
			catch (error:Dynamic)
			{
				isLoaded = false;
			}
			lines.push("Asset library " + library + ": " + (isLoaded ? "loaded" : "not loaded"));
		}

		lines.push("");
		lines.push("F8: close/open this report");
		lines.push("ESC: close this popup");
		lines.push("Select the text to copy it into a bug report.");
		return lines.join("\n");
	}

	private function showDiagnostic(title:String, message:String):Void
	{
		if (diagnosticPopup != null && diagnosticPopup.parent == this)
		{
			removeChild(diagnosticPopup);
		}

		diagnosticPopup = new Sprite();
		var viewWidth:Int = stage != null ? stage.stageWidth : 1280;
		var viewHeight:Int = stage != null ? stage.stageHeight : 720;

		var shade:Shape = new Shape();
		shade.graphics.beginFill(0x000000, 0.84);
		shade.graphics.drawRect(0, 0, viewWidth, viewHeight);
		shade.graphics.endFill();
		diagnosticPopup.addChild(shade);

		var panelWidth:Float = Math.max(280, Math.min(viewWidth - 32, 1040));
		var panelHeight:Float = Math.max(240, Math.min(viewHeight - 32, 660));
		var panelX:Float = (viewWidth - panelWidth) / 2;
		var panelY:Float = (viewHeight - panelHeight) / 2;

		var panel:Shape = new Shape();
		panel.graphics.lineStyle(2, 0xE34B4B, 1);
		panel.graphics.beginFill(0x15171C, 0.99);
		panel.graphics.drawRoundRect(panelX, panelY, panelWidth, panelHeight, 14, 14);
		panel.graphics.endFill();
		diagnosticPopup.addChild(panel);

		var heading:TextField = new TextField();
		heading.defaultTextFormat = new TextFormat("_sans", 20, 0xFFFFFF, true);
		heading.text = title;
		heading.x = panelX + 22;
		heading.y = panelY + 16;
		heading.width = panelWidth - 44;
		heading.height = 30;
		heading.selectable = false;
		diagnosticPopup.addChild(heading);

		var subheading:TextField = new TextField();
		subheading.defaultTextFormat = new TextFormat("_sans", 12, 0xC8CDD5);
		subheading.text = "Startup diagnostics • Copy the details below when reporting a problem";
		subheading.x = panelX + 22;
		subheading.y = panelY + 48;
		subheading.width = panelWidth - 44;
		subheading.height = 22;
		subheading.selectable = false;
		diagnosticPopup.addChild(subheading);

		var details:TextField = new TextField();
		details.defaultTextFormat = new TextFormat("_typewriter", 12, 0xF0F1F4);
		details.text = message;
		details.x = panelX + 22;
		details.y = panelY + 78;
		details.width = panelWidth - 44;
		details.height = panelHeight - 126;
		details.multiline = true;
		details.wordWrap = true;
		details.background = true;
		details.backgroundColor = 0x20232A;
		details.border = true;
		details.borderColor = 0x414651;
		details.selectable = true;
		diagnosticPopup.addChild(details);

		var footer:TextField = new TextField();
		footer.defaultTextFormat = new TextFormat("_sans", 12, 0xAEB5C0);
		footer.text = "F8  Toggle diagnostics     ESC  Close popup     Select text to copy";
		footer.x = panelX + 22;
		footer.y = panelY + panelHeight - 36;
		footer.width = panelWidth - 44;
		footer.height = 22;
		footer.selectable = false;
		diagnosticPopup.addChild(footer);

		addChild(diagnosticPopup);
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Std.int(Math.floor(Math.min(ratioX, ratioY)));
			if (zoom < 1)
				zoom = 1;
			gameWidth = Std.int(Math.ceil(stageWidth / zoom));
			gameHeight = Std.int(Math.ceil(stageHeight / zoom));
		}

		#if !debug
		initialState = WarningState;
		#end

		addChild(new FlxGame(gameWidth, gameHeight, Init, framerate, framerate, skipSplash, startFullscreen));

		#if !mobile
		fpsVar = new FPS(10, 5, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if (fpsVar != null)
		{
			fpsVar.visible = false;
		}
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end
	}
}
