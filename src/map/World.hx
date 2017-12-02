package map;

class World
{
	var game : Game;
	var root : h3d.scene.Object;

	var curStep = 0;

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

		gotoStep(0);
	}

	public function addChild(o : h3d.scene.Object) {
		root.addChild(o);
	}


	public function gotoStep(v : Int) {
		var anim = cam.obj.currentAnimation;
		var frame = switch(v) {
			case 1 : 100;	//phone box
			case 2 : 200;	//park
			case 3 : 300;	//river
			case 4 : 400;	//car shop
			case 5 : 500; 	//accident
			case 6 : 600;	//graveyard
			case 7 : anim.frameCount - 1;	//tombstone
			default : 0; 	//start
		}

		anim.setFrame(frame);
		anim.sync();

		if(game.hero != null) {
			var p = cam.target.localToGlobal();
			game.hero.x = p.x;
			game.hero.y = p.y;
			game.hero.z = 0;
			game.initCamera(game.hero.x, game.hero.y, game.hero.z);
		}
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