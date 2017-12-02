package map;

class World
{
	var game : Game;
	var root : h3d.scene.Object;

	var cam : {
		obj :  h3d.scene.Object,
		target : h3d.scene.Object,
		pos : h3d.scene.Object,
	};

	public function new() {
		this.game = Game.inst;
		init();
	}

	function init() {
		root = new h3d.scene.Object(game.s3d);

		var res = hxd.Res.Map.Map01;
		var m = game.modelCache.loadModel(res);
		m.playAnimation(game.modelCache.loadAnimation(res));
		m.currentAnimation.speed = 0;
		root.addChild(m);

		cam = {
			obj : m,
			target : m.getObjectByName("Camera001.Target"),
			pos : m.getObjectByName("Camera001"),
		}

		//game.s3d.camera.follow = { target : m.getObjectByName("Camera001.Target"), pos : m.getObjectByName("Camera001") };
		var p = cam.pos.localToGlobal();
		game.s3d.camera.pos.x = p.x;
		game.s3d.camera.pos.y = p.y;
		game.s3d.camera.pos.z = p.z;
	}

	public function addChild(o : h3d.scene.Object) {
		root.addChild(o);
	}


	public function getCameraFramePos(x : Float, y : Float) {
		var anim = cam.obj.currentAnimation;
		var frame = anim.frame;
		var fmin = Std.int(hxd.Math.max(0, anim.frame - 10));
		var fmax = Std.int(hxd.Math.min(anim.frameCount - 1, anim.frame + 10));
		var dist = 1e9;

		for(i in fmin...fmax) {
			anim.setFrame(i);
			anim.sync();
			var p = cam.target.localToGlobal();
			var d = hxd.Math.distanceSq(p.x - x, p.y - y);
			if(d < dist) {
				dist = d;
				frame = i;
			}
		}

		anim.setFrame(frame);
		anim.sync();
		return cam.pos.localToGlobal();
	}

	public function getZ(x : Float, y:Float) {
		return 0.;
	}
}