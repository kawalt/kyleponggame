package ;
import flash.display.Loader;
import flash.display.Sprite;
import flash.display.Stage;
import flash.net.URLRequest;
import flash.events.Event;

/**
 * ...
 * @author Kyle Awalt
 */

class Ball extends Sprite 
{
	private var myStage:Stage;
	private var _radius:Int;
	private var _xPos:Float;
	private var _yPos:Float;
	private var _xVel:Float; 
	private var _yVel:Float;
	private var _dir:Float;
	private var _acc:Float; // acceleration
	private var _rot:Float; // rotation
	private var _mass:Float;
	private var _xStart:Float;
	private var _yStart:Float;
	
	public function new(stage:Stage)
	{
		super();
		_radius = 8;
		_mass = 1;
		_xVel = 0;
		_yVel = 0;
		_rot = 0;
		_xStart = (stage.stageWidth / 2);
		_yStart = (stage.stageHeight / 2);
	}
	
	public function drawBallInMiddle()
	{
		graphics.beginFill(0x538755);
		graphics.drawCircle(_xStart, _yStart, _radius);
		graphics.endFill();
	}
	
	public function get_radius():Int
	{
		return _radius;
	}
	
	public function set_radius(r:Int)
	{
		_radius = r;
	}
	
	public function get_xPos():Float
	{
		return Math.round(_xPos * 10) / 10;
	}
	
	public function get_yPos():Float
	{
		return Math.round(_yPos * 10) / 10;
	}
	
	public function set_pos(xVal:Float, yVal:Float)
	{
		var xDiff = xVal - _xPos;
		var yDiff = yVal - _yPos;
		_xPos = xVal;
		_yPos = yVal;
		x += xDiff;
		y += yDiff;
	}
	
	public function moveX(amount:Float)
	{
		_xPos += amount;
		x += amount;
	}
	
	public function moveY(amount:Float)
	{
		_yPos += amount;
		y += amount;
	}
	
	public function get_xVel():Float 
	{
		return Math.round(_xVel * 100) / 100;
		
	}
	
	public function set_xVel(value:Float):Float 
	{
		return _xVel = value;
	}
	
	public function get_yVel():Float 
	{
		return Math.round(_yVel * 100) / 100;
	}
	
	public function set_yVel(value:Float):Float 
	{
		return _yVel = value;
	}
		
	public function get_acc():Float 
	{
		return _acc;
	}
	
	public function set_acc(value:Float):Float 
	{
		return _acc = value;
	}
		
	public function get_dir():Float 
	{
		return _dir;
	}
	
	public function set_dir(value:Float):Float 
	{
		return _dir = value;
	}
		
	public function get_rot():Float 
	{
		return _rot;
	}
	
	public function set_rot(value:Float):Float 
	{
		return _rot = value;
	}

	public function stop()
	{
		_xVel = 0;
		_yVel = 0;
		_acc = 0;
		_rot = 0;
	}	
	
	public function get_mass():Float
	{
		return _mass;
	}
	
	public function get_xStart():Float
	{
		return _xStart;
	}
	
	public function get_yStart():Float
	{
		return _yStart;
	}
}