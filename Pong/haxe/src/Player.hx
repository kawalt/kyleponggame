package ;

/**
 * ...
 * @author Kyle Awalt
 */

class Player 
{
	
	private var _isLeft:Bool;
	private var _score:Int;
	private var _name:String;

	public function new(isLeft:Bool) 
	{
		_isLeft = isLeft;
	}
	
	public function get_isLeft():Bool
	{
		return _isLeft;
	}
	
	public function set_isLeft(isLeft:Bool)
	{
		_isLeft = isLeft;
	}
	
	public function get_score():Int 
	{
		return _score;
	}
	
	public function set_score(score:Int)
	{
		_score = score;
	}
	
	public function get_name():String 
	{
		return _name;
	}
	
	public function set_name(name:String)
	{
		_name = name;
	}
}