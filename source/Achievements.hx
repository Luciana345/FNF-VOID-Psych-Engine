import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import GameJolt.GameJoltAPI;

using StringTools;

class Achievements {
	public static var achievementsStuff:Array<Dynamic> = [ //Name, Description, Achievement save tag, Hidden achievement
		["Isn't Over!",					"Beat First Void Week on Hard with no Misses.",					'void1_nomiss',			false],
		["You Won!",						"Beat Second Void Week on Hard with no Misses.",					'void2_nomiss',			false],
		["You Beat Us!",					"Beat \"Security\" Song on Hard with no Misses.",					'security_fc',			false],
		["Chilling",					"Play the secret song \"Stardust\".",					'star_unlock',			true],
	];
	public static var achievementsMap:Map<String, Bool> = new Map<String, Bool>();

	public static var henchmenDeath:Int = 0;
	public static function unlockAchievement(name:String):Void {
		FlxG.log.add('Completed achievement "' + name +'"');
		achievementsMap.set(name, true);
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
	}

	public static function isAchievementUnlocked(name:String) {
		if(achievementsMap.exists(name) && achievementsMap.get(name)) {
			return true;
		}
		return false;
	}

	public static function getAchievementIndex(name:String) {
		for (i in 0...achievementsStuff.length) {
			if(achievementsStuff[i][2] == name) {
				return i;
			}
		}
		return -1;
	}

	public static function loadAchievements():Void {
		if(FlxG.save.data != null) {
			if(FlxG.save.data.achievementsMap != null) {
				achievementsMap = FlxG.save.data.achievementsMap;
			}
			if(henchmenDeath == 0 && FlxG.save.data.henchmenDeath != null) {
				henchmenDeath = FlxG.save.data.henchmenDeath;
			}
		}
	}

	public static function giveAchievement(achieve:String, achievementEnd:Void->Void = null):Void {
		var achieveID:Int = Achievements.getAchievementIndex(achieve);
		Main.toastManager.createToast(Paths.achievementImage('achievements/' + achieve), Achievements.achievementsStuff[achieveID][0], Achievements.achievementsStuff[achieveID][1], true);
		if (achievementEnd != null)
			Main.toastManager.onFinish = achievementEnd;

		switch(achieve)
		{
			case 'void1_nomiss':
				if (!GameJoltAPI.checkTrophy(164508))
					GameJoltAPI.getTrophy(164508);
			case 'void2_nomiss':
				if (!GameJoltAPI.checkTrophy(164509))
					GameJoltAPI.getTrophy(164509);
			case 'security_fc':
				if (!GameJoltAPI.checkTrophy(164507))
					GameJoltAPI.getTrophy(164507);
			case 'star_unlock':
				if (!GameJoltAPI.checkTrophy(164506))
					GameJoltAPI.getTrophy(164506);
		}

		trace('Giving achievement ' + achieve);

		ClientPrefs.saveSettings();
	}
}

class AttachedAchievement extends FlxSprite {
	public var sprTracker:FlxSprite;
	private var tag:String;
	public function new(x:Float = 0, y:Float = 0, name:String) {
		super(x, y);

		changeAchievement(name);
		antialiasing = ClientPrefs.globalAntialiasing;
	}

	public function changeAchievement(tag:String) {
		this.tag = tag;
		reloadAchievementImage();
	}

	public function reloadAchievementImage() {
		if(Achievements.isAchievementUnlocked(tag)) {
			loadGraphic(Paths.image('achievements/' + tag));
		} else {
			loadGraphic(Paths.image('achievements/lockedachievement'));
		}
		scale.set(0.7, 0.7);
		updateHitbox();
	}

	override function update(elapsed:Float) {
		if (sprTracker != null)
			setPosition(sprTracker.x - 130, sprTracker.y + 25);

		super.update(elapsed);
	}
}