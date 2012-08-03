package ;
import flash.display.Shape;
import flash.display.Sprite;
import flash.display.Stage;
import flash.Lib;

/**
 * ...
 * @author Kyle Awalt
 */

class Paddle extends Sprite
{	
	private var myStage:Stage;
	private var _paddleWidth:Int;
	private var _paddleHeight:Int;
	private var _isLeft:Bool;
	private var _xStart:Float;
	private var _yStart:Float;
	private var _xVel:Float;
	private var _yVel:Float;
	private var _prevX:Float;
	private var _prevY:Float;
	private var _mass:Float;
	private static var velFactor:Float = 1;
	private var _deadenFactor:Float;
	private var _hitBox:Sprite;
	private static var hitBoxDepth = 30;
	
	public function new(theStage:Stage, myIsLeft:Bool, paddleColor:UInt)
	{
		super();
		myStage = theStage;
		_paddleWidth = 15;
		_paddleHeight = 75;
		_isLeft = myIsLeft;
		_isLeft ? _xStart = 50 : _xStart = myStage.stageWidth - 50 - _paddleWidth;
		_yStart = (myStage.stageHeight / 2) - (_paddleHeight / 2);
		_prevX = x;
		_prevY = y;
		_xVel = 0;
		_yVel = 0;
		_mass = 10;
		_deadenFactor = 0.5;
		graphics.beginFill(paddleColor);
		graphics.drawRect(_xStart, _yStart, _paddleWidth, _paddleHeight);
		graphics.endFill();
		_hitBox = new Sprite();
		_hitBox.graphics.beginFill(0xFFFFFF);
		if (myIsLeft)
		{
			_hitBox.graphics.drawRect(_xStart - hitBoxDepth, _yStart, hitBoxDepth + _paddleWidth, _paddleHeight);
		}
		if (!myIsLeft)
		{
			_hitBox.graphics.drawRect(_xStart, _yStart, hitBoxDepth + _paddleWidth, _paddleHeight);
		}
		_hitBox.graphics.endFill();
		_hitBox.alpha = 0.3;
		this.hitArea = _hitBox;
	}
	
	public function get_isLeft():Bool
	{
		return _isLeft;
	}
	
	public function get_xStart():Float
	{
		return _xStart;
	}
	
	public function get_yStart():Float
	{
		return _yStart;
	}
	
	public function get_paddleWidth():Int
	{
		return _paddleWidth;
	}
	
	public function get_paddleHeight():Int
	{
		return _paddleHeight;
	}
	
	public function getXPos():Float 
	{
		return _xStart + x;
	}
	
	public function getYPos():Float 
	{
		return _yStart + y;
	}
	
	public function setXPos(val:Float)
	{
		x = val - _xStart;
		_hitBox.x = val - _xStart;
	}
	
	public function setYPos(val:Float)
	{
		y = val - _yStart;
		_hitBox.y = val - _yStart;
	}
	
	public function moveX(val:Float)
	{
		_prevX = x;
		x += val;
		_hitBox.x += val;
	}
	
	public function moveY(val:Float)
	{
		if (val < 0 && !(_yStart + y <= 0))
		{
			_prevY = y;
			y += val;
			_hitBox.y += val;
		}
		if (val > 0 && !(_yStart + y  + _paddleHeight >= myStage.stageHeight))
		{
			_prevY = y;
			y += val;
			_hitBox.y += val;
		}
	}
	
	public function get_xVel():Float
	{
		return _xVel * velFactor;
	}
	
	public function get_yVel():Float
	{
		return _yVel * velFactor;
	}
	
	public function set_xVel(val:Float)
	{
		_xVel = val;
	}
	
	public function set_yVel(val:Float)
	{
		_yVel = val;
	}
	
	public function get_prevX():Float 
	{
		return _prevX;
	}
	
		public function get_prevY():Float 
	{
		return _prevY;
	}
	
	public function get_mass():Float
	{
		return _mass;
	}
	
	public function get_deadenFactor():Float 
	{
		return _deadenFactor;
	}
	
	public function reset()
	{
		x = 0;
		y = 0;
		_xVel = 0;
		_yVel = 0;
		_hitBox.x = 0;
		_hitBox.y = 0;
	}
	
	public function get_hitBox():Sprite
	{
		return _hitBox;
	}
}