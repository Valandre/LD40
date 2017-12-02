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
		root = new h3d.scene.Object(game.s3d);

		var res = hxd.Res.Map.Map01;
		var m = game.modelCache.loadModel(res);
		//m.playAnimation(game.modelCache.loadAnimation(res));
		root.addChild(m);
		game.s3d.camera.follow = { target : m.getObjectByName("Camera001.Target"), pos : m.getObjectByName("Camera001") };
	}

	public function addChild(o : h3d.scene.Object) {
		root.addChild(o);
	}

	public function getZ(x : Float, y:Float) {
		return 0.;
	}
}