import hxd.Res;

class Game extends hxd.App {

	public static var inst : Game;

	override function init() {
	}

	override function update(dt:Float) {
	}

	static function main() {
		inst = new Game();
		hxd.res.Resource.LIVE_UPDATE = true;
		hxd.Res.initLocal();
	}
}