/*
REQUIREMENTS:

I will be editing the API for this, meaning you have to download a git:
haxelib git tentools https://github.com/TentaRJ/tentools.git

You need to download and rebuild SysTools, I think you only need it for Windows but just get it *just in case*:
haxelib git systools https://github.com/haya3218/systools
haxelib run lime rebuild systools [windows, mac, linux]

SETUP (GameJolt):
To add your game's keys, you will need to make a file in the source folder named GJKeys.hx (filepath: ../source/GJKeys.hx)

In this file, you will need to add the GJKeys class with two public static variables, id:Int and key:String

Example:

package;
class GJKeys
{
    public static var id:Int = 	0; // Put your game's ID here
    public static var key:String = ""; // Put your game's private API key here
}

You can find your game's API key and ID code within the game page's settngs under the game API tab.

Hope this helps! -tenta

SETUP(Toasts):
To use toasts, you will need to do a few things.

Inside the Main class (Main.hx), you need to make a new variable called toastManager.
`public static var toastManager.toastManager`

Inside the setupGame function in the Main class, you will need to create the toastManager.
`toastManager = new toastManager();`
`addChild(toastManager);`

Toasts can be called by using `Main.toastManager.createToast();`

TYSM Firubii for your help! :heart:

USAGE:
To start up the API, the two commands you want to use will be:
GameJoltAPI.connect();
GameJoltAPI.authDaUser(FlxG.save.data.gjUser, FlxG.save.data.gjToken);
*You can't use the API until this step is done!*

FlxG.save.data.gjUser & gjToken are the save values for the username and token, used for logging in once someone already logs in.
Save values (gjUser & gjToken) are deleted when the player signs out with GameJoltAPI.deAuthDaUser(); and are replaced with "".

To open up the login menu, switch the state to GameJoltLogin.
Exiting the login menu will throw you back to Main Menu State. You can change this in the GameJoltLogin class.

The session will automatically start on login and will be pinged every 30 seconds.
If it isn't pinged within 120 seconds, the session automatically ends from GameJolt's side.
Thanks GameJolt, makes my life much easier! Not sarcasm!

You can give a trophy by using:
GameJoltAPI.getTrophy(trophyID);
Each trophy has an ID attached to it. Use that to give a trophy. It could be used for something like a week clear...

Hope this helps! -tenta
*/
package;

// GameJolt things
import flixel.addons.ui.FlxUIState;
import haxe.iterators.StringIterator;
import flixel.addons.api.FlxGameJolt as GJApi;

// Login things
import flixel.ui.FlxButton;
import flixel.text.FlxText;
import flixel.FlxSubState;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import lime.system.System;
import flixel.FlxSprite;
import flixel.ui.FlxBar;

// Toast things
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.display.BitmapData;
import openfl.text.TextField;
import openfl.display.Bitmap;
import openfl.text.TextFormat;
import openfl.Lib;
import flixel.FlxG;
import openfl.display.Sprite;

using StringTools;

class GameJoltAPI // Connects to flixel.addons.api.FlxGameJolt
{
    /**
     * Inline variable to see if the user has logged in.
     * True for logged in, false for not logged in.
     */
    static var userLogin:Bool = false;

    /**
     * Inline variable to see if the user wants to submit scores.
     */
    public static var leaderboardToggle:Bool;
    /**
     * Grabs user data and returns as a string, true for Username, false for Token
     * @param username Bool value
     * @return String 
     */
    public static function getUserInfo(username:Bool = true):String
    {
        if(username)return GJApi.username;
        else return GJApi.usertoken;
    }

    /**
     * Returns the user login status
     * @return Bool
     */
    public static function getStatus():Bool
    {
        return userLogin;
    }

    /**
     * Sets the game API key from GJKeys.api
     * Doesn't return anything
     */
    public static function connect() 
    {
        trace("Grabbing API keys...");
        GJApi.init(Std.int(GJKeys.id), Std.string(GJKeys.key), false, "", "", function(data:Bool){
            #if debug
            Main.toastManager.createToast(GameJoltInfo.imagePath, "Game " + (data ? "authenticated!" : "not authenticated..."), (!data ? "If you are a developer, check GJKeys.hx\nMake sure the id and key are formatted correctly!" : "Yay!"), false);
            #end
        });
    }

    /**
     * Inline function to auth the user. Shouldn't be used outside of GameJoltAPI things.
     * @param in1 username
     * @param in2 token
     * @param loginArg Used in only GameJoltLogin
     */
    public static function authDaUser(in1, in2, ?loginArg:Bool = false)
    {
        if(!userLogin)
        {
            GJApi.authUser(in1, in2, function(yes:Bool)
            {
                trace("User: " + (in1 == "" ? "n/a" : in1));
                trace("Token: " + in2);
                if(yes)
                {
                    Main.toastManager.createToast(GameJoltInfo.imagePath, in1 + " signed in!", "Time: " + Date.now() + "\nGame ID: " + GJKeys.id + "\nScore Submitting: " + (GameJoltAPI.leaderboardToggle? "Enabled" : "Disabled"), false);
                    trace("User authenticated!");
                    FlxG.save.data.gjUser = in1;
                    FlxG.save.data.gjToken = in2;
                    FlxG.save.flush();
                    userLogin = true;
                    startSession();
                    if(loginArg)
                        GameJoltLogin.login = true;
                }
                else 
                {
                    if(loginArg)
                        GameJoltLogin.login = true;
                    Main.toastManager.createToast(GameJoltInfo.imagePath, "Not signed in!\nSign in to save GameJolt Trophies and Leaderboard Scores!", "", false);
                    trace("User login failure!");
                }
            });
        }
    }
    
    /**
     * Inline function to deauth the user, shouldn't be used out of GameJoltLogin state!
     * @return  Logs the user out and closes the game
     */
    public static function deAuthDaUser()
    {
        closeSession();
        userLogin = false;
        trace(FlxG.save.data.gjUser + FlxG.save.data.gjToken);
        FlxG.save.data.gjUser = "";
        FlxG.save.data.gjToken = "";
        FlxG.save.flush();
        trace(FlxG.save.data.gjUser + FlxG.save.data.gjToken);
        trace("Logged out!");
        System.exit(0);
    }

    /**
     * Give a trophy!
     * @param trophyID Trophy ID. Check your game's API settings for trophy IDs.
     */
    public static function getTrophy(trophyID:Int) /* Awards a trophy to the user! */
    {
        if(userLogin)
        {
            GJApi.addTrophy(trophyID, function(data:Map<String,String>){
                trace(data);
                var bool:Bool = false;
                if (data.exists("message"))
                    bool = true;
                Main.toastManager.createToast(GameJoltInfo.imagePath, "Unlocked a new trophy"+(bool ? "... again?" : "!"), "", true);
            });
        }
    }

    /**
     * Checks a trophy to see if it was collected
     * @param id TrophyID
     * @return Bool (True for achieved, false for unachieved)
     */
    public static function checkTrophy(id:Int):Bool
    {
        var value:Bool = false;
        GJApi.fetchTrophy(id, function(data:Map<String, String>)
            {
                trace(data);
                if (data.get("achieved").toString() != "false")
                    value = true;
                trace(id+""+value);
            });
        return value;
    }

    public static function pullTrophy(?id:Int):Map<String,String>
    {
        var returnable:Map<String,String> = null;
        GJApi.fetchTrophy(id, function(data:Map<String,String>){
            trace(data);
            returnable = data;
        });
        return returnable;
    }

    /**
     * Add a score to a table!
     * @param score Score of the song. **Can only be an int value!**
     * @param tableID ID of the table you want to add the score to!
     * @param extraData (Optional) You could put accuracy or any other details here!
     */
    public static function addScore(score:Int, tableID:Int, ?extraData:String)
    {
        if (GameJoltAPI.leaderboardToggle)
        {
            trace("Trying to add a score");
            var formData:String = extraData.split(" ").join("%20");
            GJApi.addScore(score+"%20Points", score, tableID, false, null, formData, function(data:Map<String, String>){
                trace("Score submitted with a result of: " + data.get("success"));
                Main.toastManager.createToast(GameJoltInfo.imagePath, "Score submitted!", "Score: " + score + "\nExtra Data: "+extraData, true);
            });
        }
        else
        {
            Main.toastManager.createToast(GameJoltInfo.imagePath, "Score not submitted!", "Score: " + score + "Extra Data: " +extraData+"\nScore was not submitted due to score submitting being disabled!", true);
        }
    }

    /**
     * Return the highest score from a table!
     * 
     * Usable by pulling the data from the map by [function].get();
     * 
     * Values returned in the map: score, sort, user_id, user, extra_data, stored, guest, success
     * 
     * @param tableID The table you want to pull from
     * @return Map<String,String>
     */
    public static function pullHighScore(tableID:Int):Map<String,String>
    {
        var returnable:Map<String,String>;
        GJApi.fetchScore(tableID,1, function(data:Map<String,String>){
            trace(data);
            returnable = data;
        });
        return returnable;
    }

    /**
     * Inline function to start the session. Shouldn't be used out of GameJoltAPI
     * Starts the session
     */
    public static function startSession()
    {
        GJApi.openSession(function()
            {
                trace("Session started!");
                new FlxTimer().start(20, function(tmr:FlxTimer){pingSession();}, 0);
            });
    }

    /**
     * Tells GameJolt that you are still active!
     * Called every 20 seconds by a loop in startSession().
     */
    public static function pingSession()
    {
        GJApi.pingSession(true, function(){trace("Ping!");});
    }

    /**
     * Closes the session, used for signing out
     */
    public static function closeSession()
    {
        GJApi.closeSession(function(){trace('Closed out the session');});
    }
}

class GameJoltInfo
{   
    /**
     * Variable to change which state to go to by hitting ESCAPE or the CONTINUE buttons.
     */
    public static var changeState:MusicBeatState = new options.OptionsState();
    /**
    * Inline variable to change the font for the GameJolt API elements.
    * @param font You can change the font by doing **Paths.font([Name of your font file])** or by listing your file path.
    * If *null*, will default to the normal font.
    */
    public static var font:String = null; /* Example: Paths.font("vcr.ttf"); */
    /**
    * Inline variable to change the font for the notifications made by Firubii.
    * 
    * Don't make it a NULL variable. Worst mistake of my life.
    */
    public static var fontPath:String = "assets/fonts/vcr.ttf";
    /**
    * Image to show for notifications. Leave NULL for no image, it's all good :)
    * 
    * Example: Paths.getLibraryPath("images/stepmania-icon.png")
    */
    public static var imagePath:String = "assets/images/gamejolt-haxe.png"; 

    /* Other things that shouldn't be messed with are below this line! */

    /**
    * GameJolt + FNF version.
    */
    public static var version:String = "1.1";
    /**
     * Random quotes I got from other people. Nothing more, nothing less. Just for funny.
     */
    public static var textArray:Array<String> = [
        "I should probably push my commits...",
        "Where is my apple cider?",
        "Mario be like wahoo!",
        "[Funny IP address joke]",
        "I love Camellia mod",
        "I forgot to remove the IP grabber...",
        "Play Post Mortem Mixup",
        "*Spontaniously combusts*",
        "Holofunk is awesome",
        "What you know about rollin down in the deep",
        "This isn't an NFT. Crazy right?",
        "no not the null reference :(",
        "Thank you BrightFyre for your help :)",
        "Thank you Firubii for the notification code :)"
    ];
}

class GameJoltLogin extends MusicBeatSubstate
{
    var gamejoltText1:FlxText;
    var gamejoltText2:FlxText;
    var loginTexts:FlxTypedGroup<FlxText>;
    var loginBoxes:FlxTypedGroup<FlxUIInputText>;
    var loginButtons:FlxTypedGroup<FlxButton>;
    var usernameText:FlxText;
    var tokenText:FlxText;
    var usernameBox:FlxUIInputText;
    var tokenBox:FlxUIInputText;
    var signInBox:FlxButton;
    var helpBox:FlxButton;
    var logOutBox:FlxButton;
    var cancelBox:FlxButton;
    var username1:FlxText;
    var username2:FlxText;
    var boyfriend:Character = null;
    var baseX:Int = -190;
    var versionText:FlxText;
    var funnyText:FlxText;

    public static var login:Bool = false;

    override function create()
    {
        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.scrollFactor.set();
        bg.color = FlxColor.fromHSB(FlxG.random.int(0, 359), FlxG.random.float(0, 0.8), FlxG.random.float(0.3, 1));
        add(bg);

        boyfriend = new Character(840, 170, 'bf', true);
        boyfriend.setGraphicSize(Std.int(boyfriend.width * 0.75));
        boyfriend.updateHitbox();
        boyfriend.dance();
        insert(1, boyfriend);

        gamejoltText1 = new FlxText(0, 25, 0, "GameJolt + FNF Integration", 16);
        gamejoltText1.screenCenter(X);
        gamejoltText1.x += baseX;
        gamejoltText1.color = FlxColor.fromRGB(84,155,149);
        add(gamejoltText1);

        gamejoltText2 = new FlxText(0, 45, 0, Date.now().toString(), 16);
        gamejoltText2.screenCenter(X);
        gamejoltText2.x += baseX;
        gamejoltText2.color = FlxColor.fromRGB(84,155,149);
        add(gamejoltText2);

        funnyText = new FlxText(5, FlxG.height - 40, 0, GameJoltInfo.textArray[FlxG.random.int(0, GameJoltInfo.textArray.length - 1)]+ " -Tenta", 12);
        add(funnyText);

        versionText = new FlxText(5, FlxG.height - 22, 0, "Game ID: " + GJKeys.id + " API: " + GameJoltInfo.version, 12);
        add(versionText);

        loginTexts = new FlxTypedGroup<FlxText>(2);
        add(loginTexts);

        usernameText = new FlxText(0, 125, 300, "Username:", 20);

        tokenText = new FlxText(0, 225, 300, "Token: (Not PW)", 20);

        loginTexts.add(usernameText);
        loginTexts.add(tokenText);
        loginTexts.forEach(function(item:FlxText){
            item.screenCenter(X);
            item.x += baseX;
            item.font = GameJoltInfo.font;
        });

        loginBoxes = new FlxTypedGroup<FlxUIInputText>(2);
        add(loginBoxes);

        usernameBox = new FlxUIInputText(0, 175, 300, null, 32, FlxColor.BLACK, FlxColor.GRAY);
        #if android
        usernameBox.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
        #end

        tokenBox = new FlxUIInputText(0, 275, 300, null, 32, FlxColor.BLACK, FlxColor.GRAY);
        #if android
        tokenBox.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
        #end

        loginBoxes.add(usernameBox);
        loginBoxes.add(tokenBox);
        loginBoxes.forEach(function(item:FlxUIInputText){
            item.screenCenter(X);
            item.x += baseX;
            item.font = GameJoltInfo.font;
        });

        if(GameJoltAPI.getStatus())
        {
            remove(loginTexts);
            remove(loginBoxes);
        }

        loginButtons = new FlxTypedGroup<FlxButton>(3);
        add(loginButtons);

        signInBox = new FlxButton(0, 475, "Sign In", function()
        {
            trace(usernameBox.text);
            trace(tokenBox.text);
            GameJoltAPI.authDaUser(usernameBox.text,tokenBox.text,true);
        });

        helpBox = new FlxButton(0, 550, "GameJolt Token", function()
        {
            if (!GameJoltAPI.getStatus())
                openLink('https://www.youtube.com/watch?v=T5-x7kAGGnE');
            else
            {
                GameJoltAPI.leaderboardToggle = !GameJoltAPI.leaderboardToggle;
                trace(GameJoltAPI.leaderboardToggle);
                FlxG.save.data.lbToggle = GameJoltAPI.leaderboardToggle;
                Main.toastManager.createToast(GameJoltInfo.imagePath, "Score Submitting", "Score submitting is now " + (GameJoltAPI.leaderboardToggle ? "Enabled":"Disabled"), false);
            }
        });
        helpBox.color = FlxColor.fromRGB(84,155,149);

        logOutBox = new FlxButton(0, 625, "Log Out & Close", function()
        {
            GameJoltAPI.deAuthDaUser();
        });
        logOutBox.color = FlxColor.RED /*FlxColor.fromRGB(255,134,61)*/ ;

        cancelBox = new FlxButton(0,625, "Not Right Now", function()
        {
            FlxG.save.flush();
            FlxG.sound.play(Paths.sound('confirmMenu'), 0.7, false, null, true, function(){
                #if android
                FlxTransitionableState.skipNextTransOut = true;
                FlxG.resetState();
                #else
                close();
                #end
            });
        });

        if(!GameJoltAPI.getStatus())
        {
            loginButtons.add(signInBox);
        }
        else
        {
            cancelBox.y = 475;
            cancelBox.text = "Continue";
            loginButtons.add(logOutBox);
        }
        loginButtons.add(helpBox);
        loginButtons.add(cancelBox);

        loginButtons.forEach(function(item:FlxButton){
            item.screenCenter(X);
            item.setGraphicSize(Std.int(item.width) * 3);
            item.x += baseX;
        });

        if(GameJoltAPI.getStatus())
        {
            username1 = new FlxText(0, 95, 0, "Signed in as:", 40);
            username1.alignment = CENTER;
            username1.screenCenter(X);
            username1.x += baseX;
            add(username1);

            username2 = new FlxText(0, 145, 0, "" + GameJoltAPI.getUserInfo(true) + "", 40);
            username2.alignment = CENTER;
            username2.screenCenter(X);
            username2.x += baseX;
            add(username2);
        }

        if(GameJoltInfo.font != null)
        {       
            // Stupid block of code >:(
            gamejoltText1.font = GameJoltInfo.font;
            gamejoltText2.font = GameJoltInfo.font;
            funnyText.font = GameJoltInfo.font;
            versionText.font = GameJoltInfo.font;
            username1.font = GameJoltInfo.font;
            username2.font = GameJoltInfo.font;
            loginBoxes.forEach(function(item:FlxUIInputText){
                item.font = GameJoltInfo.font;
            });
            loginTexts.forEach(function(item:FlxText){
                item.font = GameJoltInfo.font;
            });
        }

        FlxG.mouse.visible = true;
    }

    override function update(elapsed:Float)
    {
        gamejoltText2.text = Date.now().toString();

        if (GameJoltAPI.getStatus())
        {
            helpBox.text = "Leaderboards:\n" + (GameJoltAPI.leaderboardToggle ? "Enabled" : "Disabled");
            helpBox.color = (GameJoltAPI.leaderboardToggle ? FlxColor.GREEN : FlxColor.RED);
        }

        if (FlxG.sound.music != null)
            Conductor.songPosition = FlxG.sound.music.time;

        if (!FlxG.sound.music.playing)
        {
            FlxG.sound.playMusic(Paths.music('freakyMenu'));
        }

        if (FlxG.keys.justPressed.ESCAPE #if android || FlxG.android.justReleased.BACK #end)
        {
            FlxG.save.flush();
            FlxG.mouse.visible = false;
            #if android
            FlxTransitionableState.skipNextTransOut = true;
            FlxG.resetState();
            #else
            close();
            #end
        }

        if(boyfriend != null && boyfriend.animation.curAnim.finished) {
            boyfriend.dance();
            boyfriend.playAnim((GameJoltAPI.getStatus() ? "hey" : "idle"));
        }

        super.update(elapsed);
    }

    override function beatHit()
    {
        super.beatHit();
    }

    override function destroy() {
        if(boyfriend != null) {
            boyfriend.kill();
            remove(boyfriend);
            boyfriend.destroy();
        }
        
        super.destroy();
    }
    function openLink(url:String)
    {
        #if linux
        Sys.command('/usr/bin/xdg-open', [url, "&"]);
        #else
        FlxG.openURL(url);
        #end
    }
}
