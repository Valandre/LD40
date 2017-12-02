package map;

class World
{
	var game : Game;
	var root : h3d.scene.Object;

	public function new() {
		this.game = Game.inst;
		init();
	}

	function init() {

	}

	public function addChild(o : h3d.scene.Object) {
		root.addChild(o);
	}

	public function getZ(x : Float, y:Float) {
		return 0.;
	}
}