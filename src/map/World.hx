package map;

enum StepKind {
	Start;
	Phone;
	Park;
	River;
	Shop;
	Accident;
	Forest;
	Tombstone;
}

class World
{
	var game : Game;
	var root : h3d.scene.Object;

	var stepId = -1;
	var stepFrames = [];
	var allSteps = StepKind.createAll();

	public var step(default, set) : StepKind;

	var cam : {
		obj :  h3d.scene.Object,
		target : h3d.scene.Object,
		pos : h3d.scene.Object,
		locked : Bool,
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
		m.lightCameraCenter = true;
		root.addChild(m);

		for (m in m.getMeshes())
		for (o in m) if (o.name.indexOf("Conelight") == 0) {
			// spawn cone light
			var l = new scene.SpotLight();
			l.direction.set(-1, 0, 0);
			l.color.scale3(100);
			l.follow = o;
			addChild(l);
		}

		cam = {
			obj : m,
			target : m.getObjectByName("Camera001.Target"),
			pos : m.getObjectByName("Camera001"),
			locked : false,
		}

		/*
		//show cam target path
		var g = new h3d.scene.Graphics(game.s3d);
		g.lineStyle(3, 0x00FFFF);

		var anim = cam.obj.currentAnimation;
		anim.setFrame(0);
		anim.sync();
		var p = cam.target.localToGlobal();
		g.moveTo(p.x, p.y, 0.1);

		for(i in 0...anim.frameCount) {
			if(i % 10 != 0) continue;
			anim.setFrame(i);
			anim.sync();
			var p = cam.target.localToGlobal();
			g.lineTo(p.x, p.y, 0.1);
		}*/


		//start, phone, park, river, shop, accident, graveyard, tombstone
		stepFrames = [0, 1100, 1800, 2850, 3800, 4990, 5100, m.currentAnimation.frameCount - 1];

		game.event.wait(0, function() {
			step = Start;
			gotoStep(0);
		});
	}

	public function addChild(o : h3d.scene.Object) {
		root.addChild(o);
	}

	function set_step(k : StepKind) {
		if(step == k) return step;

		var curId = StepKind.createAll().indexOf(k);
		if(stepId >= curId) return step;
		stepId = curId;

		switch(k) {
			case Start:
				new ent.Foe(-75, 90, 6, false, false, true);
				new ent.Foe(-78, 90, 6, false, false, true);
				new ent.Foe(-77, 70, 5, false, false, true);
			case Phone:
			case Park:
			case River:
			case Shop:
			case Accident:
			case Forest:
			case Tombstone:
			default:
		}
		return step = k;
	}

	function stepUpdate(dt : Float) {
		if(step == null) return;
		switch (step) {
			case Phone:
				if(Game.PREFS.mobSpawn && Math.random() < 0.01) {
					var p = cam.target.localToGlobal();
					var d = 12 + hxd.Math.random(8);
					var a = hxd.Math.srand(Math.PI);
					new ent.Foe(p.x + d * Math.cos(a), p.y + d * Math.sin(a), 0, true, false, false);
				}

			case Park:
				if(Game.PREFS.mobSpawn && Math.random() < 0.015) {
					var p = cam.target.localToGlobal();
					var d = 10 + hxd.Math.random(8);
					var a = hxd.Math.srand(Math.PI);
					new ent.Foe(p.x + d * Math.cos(a), p.y + d * Math.sin(a), 0);
				}

			case River, Shop:
				if(Game.PREFS.mobSpawn && Math.random() < 0.025) {
					var p = cam.target.localToGlobal();
					var d = 8 + hxd.Math.random(8);
					var a = hxd.Math.srand(Math.PI);
					new ent.Foe(p.x + d * Math.cos(a), p.y + d * Math.sin(a), 0);
				}

			case Accident:
				if(Game.PREFS.mobSpawn && Math.random() < 0.1) {
					var p = cam.target.localToGlobal();
					var d = 6 + hxd.Math.random(8);
					var a = hxd.Math.srand(Math.PI);
					new ent.Foe(p.x + d * Math.cos(a), p.y + d * Math.sin(a), 0);
				}

			case Forest:
				if(Game.PREFS.mobSpawn && Math.random() < 0.2) {
					var p = cam.target.localToGlobal();
					var d = 6 + hxd.Math.random(8);
					var a = hxd.Math.srand(Math.PI);
					new ent.Foe(p.x + d * Math.cos(a), p.y + d * Math.sin(a), 0);
				}
			default:
		}
	}

	public function gotoStep(v : Int) {
		step = allSteps[v];
		var frame = stepFrames[v];
		var anim = cam.obj.currentAnimation;
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

	function getStepFromFrame(f : Float) {
		var index = stepFrames.length - 1;
		while(index >= 0) {
			if(stepFrames[index] <= f) return allSteps[index];
			index--;
		}
		;
		return allSteps[0];
	}


	public function getCameraFramePos(x : Float, y : Float) {
		var anim = cam.obj.currentAnimation;
		var frame = anim.frame;
		var fmin = Std.int(hxd.Math.max(0, anim.frame - 1000));
		var fmax = Std.int(hxd.Math.min(anim.frameCount - 1, anim.frame + 1000));
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
		step = getStepFromFrame(frame);
		//trace(frame, step);

		return cam.pos.localToGlobal();
	}

	public function getZ(x : Float, y:Float) {
		return 0.;
	}

	public function respawn() {
		var i = game.foes.length - 1;
		while(i >= 0) {
			var f = game.foes[i--];
			if(f.isStatic) continue;
			f.remove();
		}

		@:privateAccess game.hero.stand();
		gotoStep(stepId);
	}

	public function update(dt: Float) {
		stepUpdate(dt);
	}
}