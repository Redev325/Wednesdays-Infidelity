package data;

#if cpp
import cpp.ConstCharStar;
import cpp.UInt64;
#end
import flixel.FlxG;
import openfl.system.Capabilities;
import states.MusicBeatState;

class SpecsDetector extends MusicBeatState
{
	override public function create()
	{
		super.create();

		#if html5
		// Browser builds should not block startup with a desktop RAM/CPU check.
		FlxG.save.data.cachestart = true;
		#elseif cpp
		FlxG.save.data.cachestart = checkSpecs();
		#else
		FlxG.save.data.cachestart = true;
		#end

		FlxG.switchState(Type.createInstance(Main.initialState, []));
	}

	#if cpp
	function checkSpecs():Bool
	{
		var cpu:Bool = Capabilities.supports64BitProcesses;
		var ram:UInt64 = CppAPI.obtainRAM();

		trace('\n--- SYSTEM INFO ---\nMEMORY AMOUNT: $ram\nCPU 64 BITS: $cpu');

		if (cpu && ram >= 4096)
			return true;

		return messageBox("Wednesday's Infidelity",
			"Your PC does not meet the requirements Wednesday's Infidelity has.\nWhile you can still play the mod, you may experience framedrops and/or lag spikes.\n\nDo you want to play anyway?");
	}

	function messageBox(title:ConstCharStar = null, msg:ConstCharStar = null)
	{
		#if windows
		var msgID:Int = untyped MessageBox(null, msg, title, untyped __cpp__("MB_ICONQUESTION | MB_YESNO"));

		if (msgID == 7)
			Sys.exit(0);

		return true;
		#else
		lime.app.Application.current.window.alert(cast msg, cast title);
		return true;
		#end
	}
	#end
}
