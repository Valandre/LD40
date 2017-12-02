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

		//game.s3d.camera.follow = { target : m.getObjectByName("Camera001.Target"), pos : m.getObjectByName("Camera001") };

		var p = m.getObjectByName("Camera001").localToGlobal();
		game.s3d.camera.pos.x = p.x;
		game.s3d.camera.pos.y = p.y;
		game.s3d.camera.pos.z = p.z;
		var t = m.getObjectByName("Camera001.Target").localToGlobal();
		game.s3d.camera.target.x = t.x;
		game.s3d.camera.target.y = t.y;
		game.s3d.camera.target.z = t.z;
	}

	public function addChild(o : h3d.scene.Object) {
		root.addChild(o);
	}

	public function getZ(x : Float, y:Float) {
		return 0.;
	}
}