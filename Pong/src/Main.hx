package ;

import flash.display.Shape;
import flash.display.Sprite;
import flash.display.Stage;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.DataEvent;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.SecurityErrorEvent;
import flash.geom.ColorTransform;
import flash.geom.Rectangle;
import flash.net.XMLSocket;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.ui.Mouse;
import flash.Lib;
import flash.display.MovieClip;
import flash.utils.Timer;
import Paddle;
import flash.events.TimerEvent;
import flash.text.TextFormatAlign;

/**
 * ...
 * @author Kyle Awalt
 */

class Main 
{
	private static var serverIP = "24.89.234.48";
	private static var serverPort = 1011;
	private static var dragRoom = 225; 
	private static var goalRoom = 50;
	private static var lineWidth = 2;
	private static var startGameButtonWidth = 100;
	private static var startGameButtonHeight = 75;
	private static var socketConnectDelay = 5000; // 5s
	private static var socketConnectionRetries = 3;
	private var curRetry:Int;
	private static var ballMinVel = 5;
	private static var rotFactor = 4;
	private static var aiPaddleMoveRate = 50;
	
	private var xmlSocket:XMLSocket;

	private var root:MovieClip;

	private var leftPaddle:Paddle;
	private var rightPaddle:Paddle;
	private var ball:Ball;
	private var player:Player;

	private var leftLine:Sprite;
	private var rightLine:Sprite;
	private var startGameButton:Sprite;
	private var stageBorder:Shape;
	private var gameModeButton1P:Sprite;
	private var gameModeButton2P:Sprite;
	
	private var startText:TextField;
	private var leftScoreText:TextField;
	private var rightScoreText:TextField;
	private var instructionText:TextField;
	private var infoText:TextField;
	private var readyText:TextField;
	private var gameMode1PText:TextField;
	private var gameMode2PText:TextField;
	private var selectGameModeText:TextField;
	private var newColor:ColorTransform;

	private var leftWall:Int;
	private var rightWall:Int;
	private var topWall:Int;
	private var bottomWall:Int;

	private var prevMouseX:Float;
	private var prevMouseY:Float;
	private var changeMouseX:Float;
	private var changeMouseY:Float;
	private var leftScore:String;
	private var rightScore:String;
	private var leftGames:Int;
	private var rightGames:Int;

	private var isLeftAttached:Bool;
	private var isRightAttached:Bool;
	private var isLeftServe:Bool;
	private var is1P:Bool; // true for 1P mode, false for 2P mode

	private var collisionFormulaTop1:Float; // placeholders in processCollision method
	private var collisionFormulaTop2:Float;
	private var collisionFormulaBottom:Float;
	private var collisionFormulaTotal:Float;
	private static var ballVelFactor:Float = 0.7; // used to mess with the physics in the processCollision method
	private var gameState:Int; // state 0 = init, state 1 = ready, state 2 = game started
	private var incomingX:Float;
	private var incomingY:Float;
	private var incomingRot:Float;
	private var curBallVelX:Float; // these are place-holders in the for-loops to move the ball and paddles
	private var curBallVelY:Float;
	private var curPaddleVelX:Float;
	private var curPaddleVelY:Float;
	private var curBallRot:Float;

	private var socketConnectTimer:Timer;
	
	private var aiPaddleMoveX:Float;
	private var aiPaddleMoveY:Float;
	private var curAIPaddleMoveX:Float;
	private var curAIPaddleMoveY:Float;
	
	/**
	 * Main's constructor
	 */
	public function new() 
	{
		root = Lib.current;
		root.stage.frameRate = 45;
		stageBorder = new Shape();
		drawStageBorder();
		root.addChild(stageBorder);				
		isLeftAttached = false;
		isRightAttached = false;
		newColor = new ColorTransform();
		socketConnectTimer = new Timer(socketConnectDelay, 3);
		socketConnectTimer.addEventListener(TimerEvent.TIMER_COMPLETE, processSocketTimeout);
		socketConnectTimer.addEventListener(TimerEvent.TIMER, processSocketRetry);
		
		changeMouseX = 0;
		changeMouseY = 0;
		leftScore = "0";
		rightScore = "0";
		gameState = 0;
		isLeftServe = true;
		curRetry = 0;
		
		instructionText = new TextField();
		instructionText.x = root.stage.stageWidth / 2 - 200;
		instructionText.y = 3;
		instructionText.width = 500;
		instructionText.height = 20;		
		
		leftLine = new Sprite();
		leftLine.graphics.beginFill(0x456567);
		leftLine.graphics.drawRect(dragRoom, 0, lineWidth, root.stage.stageHeight);
		leftLine.graphics.endFill();
		rightLine = new Sprite();
		rightLine.graphics.beginFill(0x456567);
		rightLine.graphics.drawRect(root.stage.stageWidth - dragRoom, 0, lineWidth, root.stage.stageHeight);
		rightLine.graphics.endFill();
		
		ball = new Ball(root.stage);
		ball.set_pos(ball.get_xStart(), ball.get_yStart());
		root.addChild(ball);
		root.addChild(leftLine);
		root.addChild(rightLine);
		
		leftWall = 0;
		rightWall = root.stage.stageWidth;
		topWall = 0;
		bottomWall = root.stage.stageHeight;
		
		var selectGameModeTextFormat = new TextFormat();
		selectGameModeTextFormat.size = 40;
		selectGameModeTextFormat.color = 0x000000;
		selectGameModeTextFormat.font = "Arial";
		selectGameModeTextFormat.italic = true;
		selectGameModeTextFormat.align = TextFormatAlign.CENTER;
		selectGameModeText = new TextField();
		selectGameModeText.defaultTextFormat = selectGameModeTextFormat;
		selectGameModeText.text = "Select Game Mode...";
		selectGameModeText.x = root.stage.stageWidth / 4;
		selectGameModeText.y = 150;
		selectGameModeText.width = root.stage.stageWidth / 2;
		selectGameModeText.height = 75;
		root.addChild(selectGameModeText);
		
		gameModeButton1P = new Sprite();
		gameModeButton1P.graphics.beginFill(0x60AFFE);
		gameModeButton1P.graphics.drawRect(0, 0, root.stage.stageWidth / 2 - 1, root.stage.stageHeight);
		gameModeButton1P.graphics.endFill();
		gameModeButton1P.alpha = 0.7;
		gameModeButton1P.useHandCursor = true;
		gameModeButton1P.buttonMode = true;
		gameModeButton1P.mouseChildren = false;
		
		gameModeButton2P = new Sprite();
		gameModeButton2P.graphics.beginFill(0x70DB93);
		gameModeButton2P.graphics.drawRect(root.stage.stageWidth / 2 + 1, 0, root.stage.stageWidth / 2 - 1, root.stage.stageHeight);
		gameModeButton2P.graphics.endFill();
		gameModeButton2P.alpha = 0.7;
		gameModeButton2P.useHandCursor = true;
		gameModeButton2P.buttonMode = true;
		gameModeButton2P.mouseChildren = false;
			
		root.addChild(gameModeButton1P);
		root.addChild(gameModeButton2P);
		
		infoText = new TextField();
		var infoTextFormat = new TextFormat();
		infoTextFormat.size = 14;
		infoTextFormat.color = 0x000000;
		infoTextFormat.font = "Arial";
		infoTextFormat.italic = true;
		infoTextFormat.align = TextFormatAlign.CENTER;
		infoText.defaultTextFormat = infoTextFormat;
		infoText.text = "";
		infoText.x = root.stage.stageWidth / 4;
		infoText.y = 10;
		infoText.width = root.stage.stageWidth / 2;
		infoText.height = 30;
		infoText.visible = false;
		root.addChild(infoText);
		
		var gameMode1PTextFormat = new TextFormat();
		gameMode1PTextFormat.size = 60;
		gameMode1PTextFormat.color = 0x000000;
		gameMode1PTextFormat.font = "Verdana";
		gameMode1PTextFormat.italic = true;
		gameMode1PTextFormat.align = TextFormatAlign.CENTER;
		
		var gameMode2PTextFormat = new TextFormat();
		gameMode2PTextFormat.size = 60;
		gameMode2PTextFormat.color = 0x000000;
		gameMode2PTextFormat.font = "Verdana";
		gameMode2PTextFormat.italic = true;
		gameMode2PTextFormat.align = TextFormatAlign.CENTER;
		
		gameMode1PText = new TextField();
		gameMode1PText.defaultTextFormat = gameMode1PTextFormat;
		gameMode1PText.width = 90;
		gameMode1PText.height = 75;
		gameMode1PText.x = root.stage.stageWidth / 2 - 125;
		gameMode1PText.y = 20;
		gameMode1PText.text = "1P";
		
		gameMode2PText = new TextField();
		gameMode2PText.defaultTextFormat = gameMode2PTextFormat;
		gameMode2PText.width = 90;
		gameMode2PText.height = 75;
		gameMode2PText.x = root.stage.stageWidth / 2 + 35;
		gameMode2PText.y = 20;
		gameMode2PText.text = "2P";
		
		root.addChild(gameMode1PText);
		root.addChild(gameMode2PText);
		
		readyText = new TextField();
		var readyTextFormat = new TextFormat();
		readyTextFormat.size = 20;
		readyTextFormat.color = 0x000000;
		readyTextFormat.font = "Verdana";
		readyTextFormat.italic = true;
		readyTextFormat.align = TextFormatAlign.CENTER;
		readyText.defaultTextFormat = readyTextFormat;
		readyText.text = "Ready!";
		readyText.width = root.stage.stageWidth / 2;
		readyText.height = 40;
		readyText.x = root.stage.stageWidth / 4;
		readyText.y = 40;
		
		startGameButton = new Sprite();
		startGameButton.useHandCursor = true;
		startGameButton.buttonMode = true;
		startGameButton.mouseChildren = false;
		
		startText = new TextField();
		var startTextFormat:TextFormat = new TextFormat();
		startTextFormat.size = 30;
		startTextFormat.align = TextFormatAlign.CENTER;
		startText.defaultTextFormat = startTextFormat;
		startText.text = leftScore + " - " + rightScore;
		startText.textColor = 0x333333;
		startText.x = (root.stage.stageWidth / 2) - (startGameButtonWidth / 2);
		startText.y = (root.stage.stageHeight / 2) - (startGameButtonHeight / 2) + 16; // trying to center it
		startText.width = startGameButtonWidth;
		startText.height = startGameButtonHeight;
		startText.selectable = false;
		startText.visible = false;
		root.addChild(startText);
		
		leftScoreText = new TextField();
		var leftScoreTextFormat:TextFormat = new TextFormat();
		leftScoreTextFormat.size = 30;
		leftScoreTextFormat.align = TextFormatAlign.RIGHT;
		leftScoreText.defaultTextFormat = leftScoreTextFormat;	
		leftScoreText.textColor = 0x333333;	
		leftScoreText.text = "0";	
		leftScoreText.x = 0;
		leftScoreText.y = 5;
		leftScoreText.width = dragRoom - 5;
		
		var rightScoreTextFormat:TextFormat = new TextFormat();
		rightScoreTextFormat.size = 30;
		rightScoreTextFormat.align = TextFormatAlign.LEFT;
		rightScoreText = new TextField();
		rightScoreText.defaultTextFormat = rightScoreTextFormat;
		rightScoreText.textColor = 0x333333;
		rightScoreText.text = "0";
		rightScoreText.x = root.stage.stageWidth - dragRoom + 5;
		rightScoreText.y = 5;
		
		root.addChild(leftScoreText);
		root.addChild(rightScoreText);
		
		gameModeButton1P.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		gameModeButton2P.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		gameModeButton1P.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		gameModeButton2P.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		gameModeButton1P.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		gameModeButton2P.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		gameMode1PText.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		gameMode2PText.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		gameMode1PText.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		gameMode2PText.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		gameMode1PText.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		gameMode2PText.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		readyText.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		readyText.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		readyText.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		root.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownListener);
		
		// control passed to onLoop function
		root.addEventListener(Event.ENTER_FRAME, onLoop, false, 0, true);
		
		aiPaddleMoveX = 0;
		aiPaddleMoveY = 0;
		curAIPaddleMoveX = 0;
		curAIPaddleMoveY = 0;
	}
	
	static function main() 
	{
		var stage = Lib.current.stage;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		// entry point
		var myMain = new Main();
	}
	
		/**
	 * This function executes with each new frame. The basic process for each frame is:
		 * 1. Get the ball and paddle velocities
		 * 2. If they're smaller than 1 but greater than 0 then move them that amount
		 * 3. If they're 1 or larger then enter into a loop that moves them 1px at a time
		 * 4. Check for collisions between the ball and the paddles, walls and goals each iteration of the loop
	 * @param	evt
	 */
	function onLoop(evt:Event)
	{		
		if (gameState == 2)
		{
			trace(aiPaddleMoveY);
			curBallVelX = ball.get_xVel();
			curBallVelY = ball.get_yVel();
			curBallRot = ball.get_rot();
			if (isLeftAttached && player.get_isLeft())
			{
				changeMouseX = root.stage.mouseX - prevMouseX;
				changeMouseY = root.stage.mouseY - prevMouseY;
			}
			else if (isRightAttached && !player.get_isLeft())
			{
				changeMouseX = root.stage.mouseX - prevMouseX;
				changeMouseY = root.stage.mouseY - prevMouseY;
			}
			else 
			{
				changeMouseX = 0;
				changeMouseY = 0;
			}
			curPaddleVelX = changeMouseX;
			curPaddleVelY = changeMouseY;
			
			if (aiPaddleMoveX > aiPaddleMoveRate)
			{
				curAIPaddleMoveX = aiPaddleMoveRate;
				aiPaddleMoveX -= aiPaddleMoveRate;
			}
			else 
			{
				curAIPaddleMoveX = aiPaddleMoveX;
				aiPaddleMoveX = 0;
			}
			if (Math.abs(aiPaddleMoveY) > aiPaddleMoveRate)
			{
				curAIPaddleMoveY = aiPaddleMoveRate;
				aiPaddleMoveY > 0 ? aiPaddleMoveY -= aiPaddleMoveRate : aiPaddleMoveY += aiPaddleMoveRate;
			}
			else 
			{
				curAIPaddleMoveY = aiPaddleMoveY;
				aiPaddleMoveY = 0;
			}
			
			if (is1P)
			{
				//rightPaddle.set_xVel(1PPaddleMoveX);
				rightPaddle.set_yVel(aiPaddleMoveY);
			}
			
			// if ball has only moved a fraction of a px during this frame, move it here
			if ((curBallVelX > 0 && curBallVelX < 1) || (curBallVelX < 0 && curBallVelX > -1 )) 
			{
				ball.moveX(curBallVelX);
				curBallVelX = 0;
							
				// only check for collisions and goals when ball is inside the paddle areas
				if ((player.get_isLeft() && ball.get_xPos() <= dragRoom && ball.get_xVel() < 0) || (!player.get_isLeft() && ball.get_xPos() >= root.stage.stageWidth - dragRoom && ball.get_xVel() > 0))
				{

					if (checkForCollisions())
					{
						curBallVelX = 0;
						curBallVelY = 0;
						curPaddleVelX = 0;
						curPaddleVelY = 0;
						curBallRot = 0;
					}
					if (testGoals())
					{
						curBallVelX = 0;
						curBallVelY = 0;
						curPaddleVelX = 0;
						curPaddleVelY = 0;
						curBallRot = 0;
						aiPaddleMoveX = 0;
						aiPaddleMoveY = 0;
					}
				}
			}
			
			// if paddle has only moved a fraction of a px this frame, move it here
			if ((curPaddleVelX > 0 && curPaddleVelX < 1) || (curPaddleVelX < 0 && curPaddleVelX > -1 ) || (aiPaddleMoveX > 0 && aiPaddleMoveX < 1) || (aiPaddleMoveX < 0 && aiPaddleMoveX > -1))
			{
				if (isLeftAttached)
				{
					leftPaddle.moveX(curPaddleVelX);
					curPaddleVelX = 0;
				}
				else if (isRightAttached)
				{
					rightPaddle.moveX(curPaddleVelX);
					curPaddleVelX = 0;
				}
				else if (is1P)
				{
					rightPaddle.moveX(aiPaddleMoveX);
					aiPaddleMoveX = 0;
				}
				
				// only check for collisions and goals when ball is inside the paddle areas
				if ((player.get_isLeft() && ball.get_xPos() <= dragRoom && ball.get_xVel() < 0) || (!player.get_isLeft() && ball.get_xPos() >= root.stage.stageWidth - dragRoom && ball.get_xVel() > 0))
				{
					if (checkForCollisions())
					{
						curBallVelX = 0;
						curBallVelY = 0;
						curPaddleVelX = 0;
						curPaddleVelY = 0;
						curBallRot = 0;
					}
					if (testGoals())
					{
						curBallVelX = 0;
						curBallVelY = 0;
						curPaddleVelX = 0;
						curPaddleVelY = 0;
						curBallRot = 0;
						aiPaddleMoveX = 0;
						aiPaddleMoveY = 0;
					}
				}
			}
			
			// if ball or paddle has moved at least 1 px, move here
			if (curBallVelX >= 1 || curBallVelX <= -1 || curPaddleVelX >= 1 || curPaddleVelX <= -1 || aiPaddleMoveX >= 1 || aiPaddleMoveX <= -1)
			{
				var maxChange:Float = 0;
				if (Math.abs(curPaddleVelX) > Math.abs(curBallVelX))
				{
					maxChange = Math.abs(curPaddleVelX);
				}
				else 
				{
					maxChange = Math.abs(curBallVelX);
				}
				if (aiPaddleMoveX > maxChange)
				{
					maxChange = Math.abs(aiPaddleMoveX);
				}
				for (n in 0...Math.floor(maxChange))
				{
					if ((curBallVelX > 0 && curBallVelX < 1) || (curBallVelX < 0 && curBallVelX > -1 )) 
					{
						ball.moveX(curBallVelX);
						curBallVelX = 0;
					}		
					else if (curBallVelX > 0)
					{
						ball.moveX(1);
						curBallVelX -= 1;
					}
					else if (curBallVelX < 0)
					{
						ball.moveX(-1);
						curBallVelX += 1;
					}
					if ((curPaddleVelX > 0 && curPaddleVelX < 1) || (curPaddleVelX < 0 && curPaddleVelX > -1 )) 
					{
						if (isLeftAttached)
						{
							leftPaddle.moveX(curPaddleVelX);
							curPaddleVelX = 0;
						}
						else if (isRightAttached)
						{
							rightPaddle.moveX(curPaddleVelX);
							curPaddleVelX = 0;
						}
					}
					else if (curPaddleVelX > 0)
					{
						if (isLeftAttached)
						{
							leftPaddle.moveX(1);
							curPaddleVelX -= 1;
						}
						else if (isRightAttached)
						{
							rightPaddle.moveX(1);
							curPaddleVelX -= 1;
						}
					}
					else if (curPaddleVelX < 0)
					{
						if (isLeftAttached)
						{
							leftPaddle.moveX(-1);
							curPaddleVelX += 1;
						}
						else if (isRightAttached)
						{
							rightPaddle.moveX(-1);
							curPaddleVelX += 1;
						}
					}
					if ((aiPaddleMoveX > 0 && aiPaddleMoveX < 1) || (aiPaddleMoveX < 0 && aiPaddleMoveX > -1 ))
					{
						if (is1P)
						{
							rightPaddle.moveX(aiPaddleMoveX);
							aiPaddleMoveX = 0;
						}
					}
					else if (aiPaddleMoveX > 0)
					{
						if (is1P)
						{
							rightPaddle.moveX(aiPaddleMoveX);
							aiPaddleMoveX -= 1;
						}
					}
					else if (aiPaddleMoveX < 0)
					{
						if (is1P)
						{
							rightPaddle.moveX(aiPaddleMoveX);
							aiPaddleMoveX += 1;
						}
					}
					
					// only check for collisions when ball is inside the paddle areas
					if ((player.get_isLeft() && ball.get_xPos() <= dragRoom && ball.get_xVel() < 0) || (!player.get_isLeft() && ball.get_xPos() >= root.stage.stageWidth - dragRoom && ball.get_xVel() > 0))
					{
						if (checkForCollisions())
						{
							curBallVelX = 0;
							curBallVelY = 0;
							curPaddleVelX = 0;
							curPaddleVelY = 0;
							curBallRot = 0;
							break;
						}
						if (testGoals())
						{
							curBallVelX = 0;
							curBallVelY = 0;
							curPaddleVelX = 0;
							curPaddleVelY = 0;
							curBallRot = 0;
							aiPaddleMoveX = 0;
							aiPaddleMoveY = 0;
							break;
						}
					}
				}
			}
			
			// do all of the above again, this time for y and this time including rotational movement (which only affects the y)
			// if ball has only moved a fraction of a px during this frame, move it here
			if ((curBallVelY > 0 && curBallVelY < 1) || (curBallVelY < 0 && curBallVelY > -1))
			{
				ball.moveY(curBallVelY);
				curBallVelY = 0;
				if (testBoundaries())
				{
					curBallVelX = 0;
					curBallVelY = 0;
					curPaddleVelX = 0;
					curPaddleVelY = 0;
					curBallRot = 0;
				}
				
				// only check for collisions and goals when ball is inside the paddle areas
				if ((player.get_isLeft() && ball.get_xPos() <= dragRoom && ball.get_xVel() < 0) || (!player.get_isLeft() && ball.get_xPos() >= root.stage.stageWidth - dragRoom && ball.get_xVel() > 0))
				{
					if (checkForCollisions())
					{
						curBallVelX = 0;
						curBallVelY = 0;
						curPaddleVelX = 0;
						curPaddleVelY = 0;
						curBallRot = 0;
					}
					if (testGoals())
					{
						curBallVelX = 0;
						curBallVelY = 0;
						curPaddleVelX = 0;
						curPaddleVelY = 0;
						curBallRot = 0;
						aiPaddleMoveX = 0;
						aiPaddleMoveY = 0;
					}
				}
			}
			
			// if paddle has only moved a fraction of a px during this frame, move it here
			if ((curPaddleVelY > 0 && curPaddleVelY < 1) || (curPaddleVelY < 0 && curPaddleVelY > -1 )) 
			{
				if (isLeftAttached)
				{
					leftPaddle.moveY(curPaddleVelY);
					curPaddleVelY = 0;
				}
				if (isRightAttached)
				{
					rightPaddle.moveY(curPaddleVelY);
					curPaddleVelY = 0;
				}
				else if (is1P)
				{
					rightPaddle.moveY(curAIPaddleMoveY);
					curAIPaddleMoveY = 0;
				}
				if (testBoundaries())
				{
					curBallVelX = 0;
					curBallVelY = 0;
					curPaddleVelX = 0;
					curPaddleVelY = 0;
					curBallRot = 0;
				}				
				
				// only check for collisions and goals when ball is inside the paddle areas
				if ((player.get_isLeft() && ball.get_xPos() <= dragRoom && ball.get_xVel() < 0) || (!player.get_isLeft() && ball.get_xPos() >= root.stage.stageWidth - dragRoom && ball.get_xVel() > 0))
				{
					if (checkForCollisions())
					{
						curBallVelX = 0;
						curBallVelY = 0;
						curPaddleVelX = 0;
						curPaddleVelY = 0;
						curBallRot = 0;
					}
					if (testGoals())
					{
						curBallVelX = 0;
						curBallVelY = 0;
						curPaddleVelX = 0;
						curPaddleVelY = 0;
						curBallRot = 0;
						aiPaddleMoveX = 0;
						aiPaddleMoveY = 0;
					}
				}
			}
			
			// if rotation is under 1, move ball here
			if ((curBallRot > 0 && curBallRot < 1) || (curBallRot < 0 && curBallRot > -1))
			{
				ball.moveY(curBallRot / rotFactor);
				curBallRot = 0;
				if (testBoundaries())
				{
					curBallVelX = 0;
					curBallVelY = 0;
					curPaddleVelX = 0;
					curPaddleVelY = 0;
					curBallRot = 0;
				}
				
				// only check for collisions and goals when ball is inside the paddle areas
				if ((player.get_isLeft() && ball.get_xPos() <= dragRoom && ball.get_xVel() < 0) || (!player.get_isLeft() && ball.get_xPos() >= root.stage.stageWidth - dragRoom && ball.get_xVel() > 0))
				{
					if (checkForCollisions())
					{
						curBallVelX = 0;
						curBallVelY = 0;
						curPaddleVelX = 0;
						curPaddleVelY = 0;
						curBallRot = 0;
					}
					if (testGoals())
					{
						curBallVelX = 0;
						curBallVelY = 0;
						curPaddleVelX = 0;
						curPaddleVelY = 0;
						curBallRot = 0;
						aiPaddleMoveX = 0;
						aiPaddleMoveY = 0;
					}
				}
			}
			
			// if ball, paddle or ball rotation has moved at least 1 px, move here
			if (curBallVelY >= 1 || curBallVelY <= -1 || curPaddleVelY >= 1 || curPaddleVelY <= -1)
			{
				var maxChange:Float = 0;
				if (Math.abs(curPaddleVelY) > Math.abs(curBallVelY))
				{
					maxChange = Math.abs(curPaddleVelY);
				}
				else 
				{
					maxChange = Math.abs(curBallVelY);
				}
				if (curBallRot > maxChange)
				{
					maxChange = Math.abs(curBallRot);
				}
				if (curAIPaddleMoveY > maxChange)
				{
					maxChange = Math.abs(curAIPaddleMoveY);
				}
				for (n in 0...Math.floor(maxChange))
				{
					if ((curBallVelY > 0 && curBallVelY < 1) || (curBallVelY < 0 && curBallVelY > -1))
					{
						ball.moveY(curBallVelY);
						curBallVelY = 0;
					}
					else if (curBallVelY > 0)
					{
						ball.moveY(1);
						curBallVelY -= 1;
					}
					else if (curBallVelY < 0)
					{
						ball.moveY(-1);
						curBallVelY += 1;
					}
					if ((curPaddleVelY > 0 && curPaddleVelY < 1) || (curPaddleVelY < 0 && curPaddleVelY > -1 )) 
					{
						if (isLeftAttached)
						{
							leftPaddle.moveY(curPaddleVelY);
							curPaddleVelY = 0;
						}
						else if (isRightAttached)
						{
							rightPaddle.moveY(curPaddleVelY);
							curPaddleVelY = 0;
						}
					}	
					else if (curPaddleVelY > 0)
					{
						if (isLeftAttached)
						{
							leftPaddle.moveY(1);
							curPaddleVelY -= 1;
						}
						else if (isRightAttached)
						{
							rightPaddle.moveY(1);
							curPaddleVelY -= 1;
						}
					}
					else if (curPaddleVelY < 0)
					{
						if (isLeftAttached)
						{
							leftPaddle.moveY(-1);
							curPaddleVelY += 1;
						}
						else if (isRightAttached)
						{
							rightPaddle.moveY(-1);
							curPaddleVelY += 1;
						}
					}
					if ((curBallRot > 0 && curBallRot < 1) || (curBallRot < 0 && curBallRot > -1))
					{
						ball.moveY(curBallRot / rotFactor);
						curBallRot = 0;
					}
					else if (curBallRot > 0)
					{
						curBallVelX > 0 ? ball.moveY( -1 / rotFactor) : ball.moveY(1 / rotFactor);
						curBallRot -= 1;
					}
					else if (curBallRot < 0)
					{
						curBallVelX > 0 ? ball.moveY(1 / rotFactor) : ball.moveY(-1 / rotFactor);
						curBallRot += 1;
					}
					if ((curAIPaddleMoveY > 0 && curAIPaddleMoveY < 1) || (curAIPaddleMoveY < 0 && curAIPaddleMoveY > -1))
					{
						if (is1P)
						{
							rightPaddle.moveY(curAIPaddleMoveY);
							curAIPaddleMoveY = 0;
						}
					}
					else if (curAIPaddleMoveY > 0)
					{
						if (is1P)
						{
							rightPaddle.moveY(1);
							curAIPaddleMoveY -= 1;
						}
					}
					else if (curAIPaddleMoveY < 0)
					{
						if (is1P)
						{
							rightPaddle.moveY(-1);
							curAIPaddleMoveY += 1;
						}
					}
					if (testBoundaries())
					{
						curBallVelX = 0;
						curBallVelY = 0;
						curPaddleVelX = 0;
						curPaddleVelY = 0;
						curBallRot = 0;
						break;
					}
					if ((player.get_isLeft() && ball.get_xPos() <= dragRoom && ball.get_xVel() < 0) || (!player.get_isLeft() && ball.get_xPos() >= root.stage.stageWidth - dragRoom && ball.get_xVel() > 0))
					{
						if (checkForCollisions())
						{
							curBallVelX = 0;
							curBallVelY = 0;
							curPaddleVelX = 0;
							curPaddleVelY = 0;
							curBallRot = 0;
							break;
						}
						if (testGoals())
						{
							curBallVelX = 0;
							curBallVelY = 0;
							curPaddleVelX = 0;
							curPaddleVelY = 0;
							curBallRot = 0;
							aiPaddleMoveX = 0;
							aiPaddleMoveY = 0;
							break;
						}
					}
				}
			}
			
			// once per frame send an update to the server regarding the paddle location and update the paddle velocities
			if (isLeftAttached)
			{
				if (!is1P)
				{
					xmlSocket.send("px" + leftPaddle.getXPos() + "y" + leftPaddle.getYPos() + "\n");
				}
				leftPaddle.set_xVel(changeMouseX);
				leftPaddle.set_yVel(changeMouseY);
			}
			else if (isRightAttached)
			{
				if (!is1P)
				{
					xmlSocket.send("px" + rightPaddle.getXPos() + "y" + rightPaddle.getYPos() + "\n");
				}
				rightPaddle.set_xVel(changeMouseX);
				rightPaddle.set_yVel(changeMouseY);
			}
			testPaddles();
		}
		
		// each frame grab the mouse position so that on the next frame we can calculate how much to move the paddle
		prevMouseX = root.stage.mouseX;
		prevMouseY = root.stage.mouseY;
	}
	
	function handleXMLConnect(event):Void 
	{
		
	}
	
	function handleXMLClose(event):Void 
	{
	}
	
	function handleXMLIOError(event):Void 
	{
	}
	
	function handleXMLSecError(event:SecurityErrorEvent):Void 
	{
	}
	
	/**
	 * This is the handler function that gets called when the XMLSocket receives an incomming data event.
	 * The chain of events is as follows:
		 1. The player loads the game and a socket is created to connect to the server.
		 2. The server accepts the connection and responds to say if the client is the first person to have connected or the second. "conn1" or "conn2".
		 3. Each client sends a "ready" message to the server when user clicks button.
		 3. When the server has received both ready messages it sends a message to each client, "ready".
		 4. When the client receives this "ready" message from the server, it knows the other client has as well and the game is ready to start.
	 * @param event 
	 */
	function handleXMLData(event:DataEvent):Void 
	{
		if (gameState == 0) 
		{
			if (event.data.toString() == "conn1")
			{
				socketConnectTimer.stop();
				player = new Player(true);
				infoText.text = "Connected... You are left paddle. Click when ready.";
				root.addChild(readyText);
				leftPaddle = new Paddle(root.stage, true, 0x800000);
				rightPaddle = new Paddle(root.stage, false, 0x191970);
				root.addChild(leftPaddle.get_hitBox());
				root.addChild(rightPaddle.get_hitBox());
				root.addChild(leftPaddle);
				root.addChild(rightPaddle);
				leftPaddle.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
				leftPaddle.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
				leftPaddle.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			}
			else if (event.data.toString() == "conn2")
			{
				socketConnectTimer.stop();
				player = new Player(false);
				infoText.text = "Connected... You are right paddle. Click when ready.";
				root.addChild(readyText);
				leftPaddle = new Paddle(root.stage, true, 0x191970);
				rightPaddle = new Paddle(root.stage, false, 0x800000);
				root.addChild(leftPaddle.get_hitBox());
				root.addChild(rightPaddle.get_hitBox());
				root.addChild(leftPaddle);
				root.addChild(rightPaddle);
				rightPaddle.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
				rightPaddle.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
				rightPaddle.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			}
		}
		if (event.data.toString() == "ready")
		{
			trace("ready");
			gameState = 1;
			if (isLeftServe)
			{
				if (!player.get_isLeft())
				{
					drawStartGameButton();
				}
				infoText.text = "Game ready. Left serve. Right player click blue button to begin.";
			}
			else
			{
				if (player.get_isLeft())
				{
					drawStartGameButton();
				}
				infoText.text = "Game ready. Right serve. Left player click blue button to begin.";
			}
			startText.visible = true;
			leftScoreText.visible = true;
			rightScoreText.visible = true;
		}
		if (gameState == 1 && event.data.toString() == "start")
		{
				gameState = 2;
				infoText.visible = false;
				startText.visible = false;
				startGame();
		}
		
		// this is the server sending a paddle position update
		if (gameState == 2 && event.data.toString().charAt(0) == "p")
		{
			var dataString = event.data.toString();
			var xString = dataString.substr(2, dataString.indexOf("y") - 1);
			var yString = dataString.substr(dataString.indexOf("y") + 1);
			incomingX = Std.parseFloat(xString);
			incomingY = Std.parseFloat(yString);
			if (player.get_isLeft())
			{
				rightPaddle.setXPos(incomingX);
				rightPaddle.setYPos(incomingY);
			}
			else
			{
				leftPaddle.setXPos(incomingX);
				leftPaddle.setYPos(incomingY);
			}
		}
		
		// this is server sending a ball position/velocity update
		else if (gameState == 2 && event.data.toString().charAt(0) == "b" && event.data.toString().charAt(1) == "x")
		{
			var dataString = event.data.toString();
			var xString = dataString.substr(dataString.indexOf("x") + 1, dataString.indexOf("y") - (dataString.indexOf("x") + 1));
			var yString = dataString.substr(dataString.indexOf("y") + 1, dataString.lastIndexOf("x") - (dataString.indexOf("y") + 1));
			var xvString = dataString.substr(dataString.lastIndexOf("x") + 2, dataString.lastIndexOf("y") - (dataString.lastIndexOf("x") + 2));
			var yvString = dataString.substr(dataString.lastIndexOf("y") + 2, dataString.indexOf("r") - dataString.lastIndexOf("y") + 2);
			var rotString = dataString.substr(dataString.indexOf("r") + 1);
			incomingX = Std.parseFloat(xString);
			incomingY = Std.parseFloat(yString);
			ball.set_pos(incomingX, incomingY);
			incomingX = Std.parseFloat(xvString);
			incomingY = Std.parseFloat(yvString);
			incomingRot = Std.parseFloat(rotString);
			ball.set_xVel(incomingX);
			ball.set_yVel(incomingY);
		}
		
		// this is server sending a goal update
		else if (gameState == 2 && event.data.toString() == "g")
		{
			if (player.get_isLeft())
			{
				xmlSocket.send("lt" + "\n");
				processGoal(false);
			}
			else
			{
				xmlSocket.send("lt" + "\n");
				processGoal(true);
			}
		}
		
		// these are part of the lagtest process. when the server sends 'flagtest' (final lagtest) the lagtest is complete
		if (event.data.toString() == "lagtest")
		{
			xmlSocket.send(event.data.toString() + "\n");
		}
		else if (event.data.toString() == "flagtest")
		{
			xmlSocket.send(event.data.toString() + "\n");
		}
	}	
			
	private function processSocketRetry(event:TimerEvent)
	{
		curRetry++;
		infoText.text = "Retry " + curRetry + " of " + socketConnectionRetries;
		xmlSocket.close();
		xmlSocket.connect(serverIP, serverPort);
	}
	private function processSocketTimeout(event:TimerEvent)
	{
		infoText.text = "Connection timeout. The game server is not responding.";
		xmlSocket.close();
	}
	
	function onMouseDown(event:MouseEvent)
	{
		if (event.target == leftPaddle && gameState == 2)
		{
			if (!isLeftAttached && player.get_isLeft())
			{
				attachLeft();
			}
		}
		else if (event.target == rightPaddle && gameState == 2)
		{
			if (!isRightAttached && !player.get_isLeft())
			{
				attachRight();
			}
		}
		else if (event.target == startGameButton && gameState == 1)
		{
			if (!is1P)
			{
				xmlSocket.send("start" + "\n");
			}
			gameState = 2;
			infoText.visible = false;
			startGameButton.graphics.clear();
			root.removeChild(startGameButton);
			startGame();
		}
		else if (event.target == gameModeButton1P || event.target == gameMode1PText)
		{
			is1P = true;
			player = new Player(true);
			leftPaddle = new Paddle(root.stage, true, 0x800000);
			rightPaddle = new Paddle(root.stage, false, 0x191970);
			root.addChild(leftPaddle.get_hitBox());
			root.addChild(rightPaddle.get_hitBox());
			root.addChild(leftPaddle);
			root.addChild(rightPaddle);
			leftPaddle.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			leftPaddle.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			leftPaddle.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			root.removeChild(gameModeButton1P);
			root.removeChild(gameModeButton2P);
			root.removeChild(gameMode1PText);
			root.removeChild(gameMode2PText);
			root.removeChild(selectGameModeText);
			infoText.text = "You are left paddle. Click Ready to begin.";
			root.addChild(readyText);
		}
		else if (event.target == gameModeButton2P || event.target == gameMode2PText)
		{
			is1P = false;
			infoText.text = "Connecting to server... Timeout set to " + (socketConnectDelay * socketConnectionRetries) / 1000 + " seconds.";
			infoText.visible = true;
			root.removeChild(gameModeButton1P);
			root.removeChild(gameModeButton2P);
			root.removeChild(gameMode1PText);
			root.removeChild(gameMode2PText);
			root.removeChild(selectGameModeText);
			xmlSocket = new XMLSocket();
			xmlSocket.timeout = 10000;
			xmlSocket.addEventListener(Event.CONNECT, handleXMLConnect);//OnConnect//
			xmlSocket.addEventListener(Event.CLOSE, handleXMLClose);//OnDisconnect//
			xmlSocket.addEventListener(IOErrorEvent.IO_ERROR, handleXMLIOError);//OnDisconnect//
			xmlSocket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleXMLSecError);
			xmlSocket.addEventListener(DataEvent.DATA, handleXMLData);
			socketConnectTimer.start();
			xmlSocket.connect(serverIP, serverPort);
		}
		else if (event.target == readyText)
		{	
			if (!is1P)
			{
				xmlSocket.send("ready" + "\n");
				infoText.text = "Waiting for second player... ";
			}
			else 
			{
				drawStartGameButton();
				infoText.text = "Right player serve. Click blue button to begin.";
				gameState = 1;
			}
			root.removeChild(readyText);
		}
	}
	
	function onMouseOver(event:MouseEvent)
	{
		if (event.target == rightPaddle || event.target == leftPaddle) 
		{
			flash.ui.Mouse.cursor = "hand";
		}
		else if (event.target == gameModeButton1P || event.target == gameMode1PText)
		{
			newColor.color = 0xFF4500;
			newColor.alphaMultiplier = 0.7;
			gameModeButton1P.transform.colorTransform = newColor;
			newColor.color = 0xFFE600;
			gameMode1PText.transform.colorTransform = newColor;
			flash.ui.Mouse.cursor = "button";
		}
		else if (event.target == gameModeButton2P || event.target == gameMode2PText)
		{
			newColor.color = 0xFF4500;
			newColor.alphaMultiplier = 0.7;
			gameModeButton2P.transform.colorTransform = newColor;
			newColor.color = 0xFFE600;
			gameMode2PText.transform.colorTransform = newColor;
			flash.ui.Mouse.cursor = "button";
		}
		else if (event.target == readyText)
		{
			newColor.color = 0xFFE600;
			readyText.transform.colorTransform = newColor;
			flash.ui.Mouse.cursor = "button";
		}
	}
	
	function onMouseOut(event:MouseEvent)
	{
		if (event.target == rightPaddle || event.target == leftPaddle) 
		{
			flash.ui.Mouse.cursor = "auto";
		}
		else if (event.target == gameModeButton1P || event.target == gameMode1PText)
		{
			newColor.color = 0x60AFFE;
			gameModeButton1P.transform.colorTransform = newColor;
			newColor.color = 0x000000;
			gameMode1PText.transform.colorTransform = newColor;
			flash.ui.Mouse.cursor = "auto";
		}
		else if (event.target == gameModeButton2P || event.target == gameMode2PText)
		{
			newColor.color = 0x70DB93;
			gameModeButton2P.transform.colorTransform = newColor;
			newColor.color = 0x000000;
			gameMode2PText.transform.colorTransform = newColor;
			flash.ui.Mouse.cursor = "auto";
		}
		else if (event.target == readyText)
		{
			newColor.color = 0x000000;
			readyText.transform.colorTransform = newColor;
			flash.ui.Mouse.cursor = "auto";
		}
	}
	
	function keyDownListener(event:KeyboardEvent)
	{
		if (event.keyCode == 27) 
		{
			if (isLeftAttached)
			{
				detachLeft();
			}
			if (isRightAttached)
			{
				detachRight();
			}
		}
	}
	
	function startGame()
	{
		ball.drawBallInMiddle();
		leftPaddle.reset();
		rightPaddle.reset();
		if (isLeftServe) 
		{
			ball.set_xVel( -6);
		}
		else
		{
			ball.set_xVel(6);
			//computeAIPaddleMoveX();
			computeAIPaddleMoveY();
		}
		ball.set_yVel(0);
	}
	
	private function attachLeft()
	{
		Mouse.hide();
		isLeftAttached = true;
	}
	
	private function attachRight()
	{
		Mouse.hide();
		isRightAttached = true;
	}
	private function detachLeft()
	{
		Mouse.show();
		isLeftAttached = false;
	}
	private function detachRight()
	{
		Mouse.show();
		isRightAttached = false;
	}
	
	private function testBoundaries():Bool
	{
		if (ball.get_yPos() <= topWall + (ball.get_radius()))
		{
			ball.set_yVel(ball.get_yVel() * -1);
			return true;
		}
		
		if (ball.get_yPos() >= bottomWall - (ball.get_radius() * 2))
		{
			ball.set_yVel(ball.get_yVel() * -1);
			return true;
		}		
		return false;
	}
	
	private function testGoals():Bool
	{
		if (player.get_isLeft() && ball.get_xPos() <= leftWall - (ball.get_radius() * 2))
		{
			if (!is1P)
			{
				xmlSocket.send("g" + "\n");
			}
			processGoal(true);
			return true;
		}
		else if ((!player.get_isLeft() || is1P) && ball.get_xPos() >= rightWall + (ball.get_radius() * 2))
		{
			if (!is1P)
			{
				xmlSocket.send("g" + "\n");
			}
			processGoal(false);
			return true;
		}
		return false;
	}
	
	private function putBallInMiddle()
	{
		ball.set_pos(ball.get_xStart(), ball.get_yStart());
	}
	
	/**
	 * If the paddle goes outside its area it gets bounced back to its default location and detatched
	 * @return true if the paddle has gone outside its area
	 */
	private function testPaddles():Bool
	{
		if (player.get_isLeft() && (leftPaddle.x + leftPaddle.get_paddleWidth() > dragRoom - goalRoom))
		{
			leftPaddle.reset();
			if (!is1P)
			{
				xmlSocket.send("px" + leftPaddle.getXPos() + "y" + leftPaddle.getYPos() + "\n");
			}
			detachLeft();
			return true;
		}
		
		if (!player.get_isLeft() && (rightPaddle.x - rightPaddle.get_paddleWidth() < -(dragRoom - goalRoom)))
		{
			rightPaddle.reset();
			if (!is1P)
			{
				xmlSocket.send("px" + rightPaddle.getXPos() + "y" + rightPaddle.getYPos() + "\n");
			}
			detachRight();
			return true;
		}
		return false;
	}
	
	private function drawStageBorder()
	{
			var borderWidth = 1;
			var borderAlpha = 1;
			var borderColour = 0x000000;
			stageBorder.graphics.beginFill(borderColour, borderAlpha);
			stageBorder.graphics.drawRect(borderWidth, 0, root.stage.stageWidth - borderWidth, borderWidth);
			stageBorder.graphics.endFill();
 
			stageBorder.graphics.beginFill(borderColour, borderAlpha);
			stageBorder.graphics.drawRect(root.stage.stageWidth - borderWidth, borderWidth, borderWidth, root.stage.stageHeight - borderWidth);
			stageBorder.graphics.endFill();
 
			stageBorder.graphics.beginFill(borderColour, borderAlpha);
			stageBorder.graphics.drawRect(0, root.stage.stageHeight - borderWidth, root.stage.stageWidth - borderWidth, borderWidth);
			stageBorder.graphics.endFill();
 
			stageBorder.graphics.beginFill(borderColour, borderAlpha);
			stageBorder.graphics.drawRect(0, 0, borderWidth, root.stage.stageHeight - borderWidth);
			stageBorder.graphics.endFill();
	}
	
	private function processCollision(paddle:Paddle)
	{
		collisionFormulaTop1 = (ball.get_xVel() * ballVelFactor)  * (ball.get_mass() - paddle.get_mass());
		collisionFormulaTop2 = 2 * paddle.get_mass() * paddle.get_xVel();
		collisionFormulaBottom = paddle.get_mass() + ball.get_mass();
		collisionFormulaTotal = ((collisionFormulaTop1 / collisionFormulaBottom) + (collisionFormulaTop2 / collisionFormulaBottom)) * paddle.get_deadenFactor();
		if (collisionFormulaTotal < ballMinVel && collisionFormulaTotal >= 0)
		{
			collisionFormulaTotal = ballMinVel;
		}
		else if (collisionFormulaTotal > -ballMinVel && collisionFormulaTotal <= 0)
		{
			collisionFormulaTotal = -ballMinVel;
		}
		ball.set_xVel(collisionFormulaTotal);
		
		collisionFormulaTop1 = -1 * (ball.get_yVel() * ballVelFactor) * (ball.get_mass() - paddle.get_mass());
		collisionFormulaTop2 = 2 * paddle.get_mass() * paddle.get_yVel();
		collisionFormulaBottom = paddle.get_mass() + ball.get_mass();
		collisionFormulaTotal = ((collisionFormulaTop1 / collisionFormulaBottom) + (collisionFormulaTop2 / collisionFormulaBottom)) * paddle.get_deadenFactor();
		ball.set_yVel(collisionFormulaTotal);
	}
	
	private function processGoal(left:Bool)
	{
		ball.stop();
		putBallInMiddle();
		leftPaddle.x = 0;
		leftPaddle.y = 0;
		detachLeft();
		rightPaddle.x = 0;
		rightPaddle.y = 0;
		detachRight();
		if (left) 
		{
			incrementScore(false);
			startText.text = leftScore + " - " + rightScore;
		}
		else 
		{
			incrementScore(true);
			startText.text = leftScore + " - " + rightScore;
		}		
		gameState = 1;
		infoText.visible = true;
	}
	
	function checkForCollisions():Bool
	{
		if (player.get_isLeft())
		{
			if (ball.hitTestObject(leftPaddle) && (ball.get_xVel() <= 0))
			{
				processCollision(leftPaddle);
				if (!is1P)
				{
					xmlSocket.send("bx" + ball.get_xPos() + "y" + ball.get_yPos() + "xv" + ball.get_xVel() + "yv" + ball.get_yVel() + "r" + ball.get_rot() + "\n");
				}
				else
				{
					//computeAIPaddleMoveX();
					computeAIPaddleMoveY();
				}
				return true;
			}
		}
		else if (!player.get_isLeft() || is1P)
		{
			if (ball.hitTestObject(rightPaddle) && (ball.get_xVel() >= 0))
			{
				processCollision(rightPaddle);
				if (!is1P)
				{
					xmlSocket.send("bx" + ball.get_xPos() + "y" + ball.get_yPos() + "xv" + ball.get_xVel() + "yv" + ball.get_yVel() + "r" + ball.get_rot() + "\n");
				}
				return true;
			}
		}
		return false;
	}
	
	private function drawStartGameButton()
	{				
		startGameButton.addChild(startText);
		startGameButton.graphics.beginFill(0xAEEEEE);
		startGameButton.graphics.drawRect((root.stage.stageWidth / 2) - (startGameButtonWidth / 2), (root.stage.stageHeight / 2) - (startGameButtonHeight / 2), startGameButtonWidth, startGameButtonHeight);
		startGameButton.graphics.endFill();
		root.addChild(startGameButton);
		startGameButton.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
	}
	
	private function incrementScore(incLeft:Bool)
	{
		if (incLeft)
		{
			if (leftScore == "0")
			{
				leftScore = "15";
			}
			else if (leftScore == "15")
			{
				leftScore = "30";
			}
			else if (leftScore == "30")
			{
				if (rightScore == "40")
				{
					leftScore = "D";
					rightScore = "D";
				}
				else 
				{
					leftScore = "40";
				}
			}
			else if (leftScore == "40")
			{
				rightScore = "0";
				leftScore = "0";
				incrementGames(true);
				leftScoreText.text = "" + leftGames;
			}
			else if (leftScore == "D")
			{
				if (rightScore == "D")
				{
					leftScore = "D+";
				}
				else if (rightScore == "D+")
				{
					leftScore = "D";
					rightScore = "D";
				}
			}
			else if (leftScore == "D+")
			{
				rightScore = "0";
				leftScore = "0";
				incrementGames(true);
				leftScoreText.text = "" + leftGames;
			}
		}
		else 
		{
			if (rightScore == "0")
			{
				rightScore = "15";
			}
			else if (rightScore == "15")
			{
				rightScore = "30";
			}
			else if (rightScore == "30")
			{
				if (leftScore == "40")
				{
					rightScore = "D";
					leftScore = "D";
				}
				else 
				{
					rightScore = "40";
				}
			}
			else if (rightScore == "40")
			{
				rightScore = "0";
				leftScore = "0";
				incrementGames(false);
				rightScoreText.text = "" + rightGames;
			}
			else if (rightScore == "D")
			{
				if (leftScore == "D")
				{
					rightScore = "D+";
				}
				else if (leftScore == "D+")
				{
					rightScore = "D";
					leftScore = "D";
				}
			}
			else if (rightScore == "D+")
			{
				rightScore = "0";
				leftScore = "0";
				incrementGames(false);
				rightScoreText.text = "" + rightGames;
			}
		}
	}
	
	private function incrementGames(incLeft:Bool)
	{
		if (incLeft)
		{
			leftGames++;
			if ((leftGames + rightGames) % 2 == 0)
			{
				isLeftServe = true;
			}
			else 
			{
				isLeftServe = false;
			}
		}
		else 
		{
			rightGames++;	
			if ((leftGames + rightGames) % 2 == 0)
			{
				isLeftServe = true;
			}
			else 
			{
				isLeftServe = false;
			}
		}
	}
	
	// TODO: Complete this method. It is a work in progress
	private function computeAIPaddleMoveX()
	{
		var dx:Float = (root.stage.stageWidth - dragRoom) - ball.get_xPos(); // x distance from ball to right hitting area
		var t:Float = dx / ball.get_xVel(); // time it will take, in frames, for the ball to reach right hitting area
		var dy:Float = ball.get_yVel() * t; // y distance ball will travel as it makes its way across
		if (ball.get_yVel() > 0 && dy + ball.get_yPos() > bottomWall)
		{
			if (ball.get_xVel() / ball.get_yVel() > 1)
			{
				aiPaddleMoveY = ((bottomWall * 0.8) - rightPaddle.get_paddleHeight() - rightPaddle.getYPos()); // move paddle almost all the way to the wall
			}
			// otherwise don't move the paddle since we're not sure what kind of subsequent wall bounces might go on			
		}
		else if (ball.get_yVel() < 0 && dy + ball.get_yPos() < topWall)
		{
			if (Math.abs(ball.get_xVel() / ball.get_yVel()) > 1)
			{
				aiPaddleMoveY = (topWall - (rightPaddle.getYPos() * 0.80)); // move paddle almost all the way to the wall
			}
			// otherwise don't move the paddle since we're not sure what kind of subsequent wall bounces might go on
		}
	}
	
	// TODO: Complete this method. It is a work in progress
	private function computeAIPaddleMoveY()
	{
		var yVel = ball.get_yVel();
		var xVel = ball.get_xVel();
		var px:Float = ball.get_xPos();
		var py:Float = ball.get_yPos();
		var dx:Float = rightPaddle.get_xStart() - px; // x distance from ball to right hitting area
		trace("dx = " + dx + " xVel = " + xVel);
		var t:Float = dx / xVel; // time it will take, in frames, for the ball to reach right hitting area
		var dy:Float = yVel * t; // y distance ball will travel as it makes its way across
		trace("yVel = " + yVel + " dy = " + dy + " py = " + py);
		while ((yVel > 0 && dy + py > bottomWall - ball.get_radius() * 2) || (yVel < 0 && dy + py < topWall))
		{
			trace("hit wall?");
			if (yVel > 0)
			{
				t = yVel / ((bottomWall - ball.get_radius() * 2) - py);
				dx = xVel * t;
				px += dx;
				py = bottomWall - ball.get_radius() * 2;
				yVel *= -1;
				dx = rightPaddle.get_xStart() - px;
				t = dx / xVel;
				dy = yVel * t;
			}
			else if (yVel < 0)
			{
				t = yVel / py;
				dx = xVel * t;
				px += dx;
				py = topWall;
				yVel *= -1;
				dx = rightPaddle.get_xStart() - px;
				t = dx / xVel;
				dy = yVel * t;
			}
		}
		py += dy;
				trace("paddlePos = " + rightPaddle.getYPos() + "py = " + py);

		if (py > rightPaddle.getYPos() && py < rightPaddle.getYPos() + rightPaddle.get_paddleHeight())
		{
			aiPaddleMoveY = 0;
		}
		else if (rightPaddle.getYPos() > py)
		{
			aiPaddleMoveY = -1 * (rightPaddle.getYPos() - py + 5);
			trace("aiPaddleMoveY = " + aiPaddleMoveY);
		}
		else if (rightPaddle.getYPos() < py)
		{
			aiPaddleMoveY = py - rightPaddle.getYPos() - rightPaddle.get_paddleHeight() + 5;
		}
		
	}
}