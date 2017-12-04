package map;

enum StepKind {
	Title;
	Start;
	Phone;
	Park;
	River;
	Shop;
	Avenue;
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

	var colliders : h2d.col.Polygons;
	var traps : Array<h3d.col.Collider> = [];
	var safeZones : Array<h3d.col.Sphere> = [];

	var sceneZones : Array<h3d.col.Sphere> = [];

	public var step(default, set) : StepKind;

	public var cam : {
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
		var obj = game.modelCache.loadModel(res);
		obj.playAnimation(game.modelCache.loadAnimation(res));
		obj.currentAnimation.speed = 0;
		obj.getObjectByName("Landscape").lightCameraCenter = true;
		root.addChild(obj);

		for (m in obj.getMeshes()) {
			if(m.name == "Road") {
				initCollideShape(m);
				m.visible = false;
			}
			if(m.name.substr(0, 4) == "Trap") {
				m.visible = false;
				traps.push(m.getCollider());
			}
			if(m.name.substr(0, 4) == "Safe") {
				m.visible = false;
				safeZones.push(m.getBounds().toSphere());
			}
			if(m.name.substr(0, 6) == "Flower") {
				sceneZones.push(m.getBounds().toSphere());
				var l = new h3d.scene.PointLight();
				l.color.setColor(0xf7cf78);
				l.follow = m;
				l.params.set(1.0, 0.14, 0.07);
				addChild(l);
			}
			for (o in m) if (o.name.indexOf("Conelight") == 0) {
				// spawn cone light
				var l = new scene.SpotLight();
				l.direction.set(-1, 0, 0);
				l.color.setColor(0xf7cf78);
				l.color.scale3(1.5);
				l.params.set(1.0, 0.014, 0.0007);
				l.setAngle(Math.PI / 16, Math.PI / 24);
				l.follow = o;
				addChild(l);
			}
		}

		cam = {
			obj : obj,
			target : obj.getObjectByName("Camera001.Target"),
			pos : obj.getObjectByName("Camera001"),
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


		//Title, start, phone, park, river, shop, Avenue, accident, graveyard, tombstone
		stepFrames = [0, 1, 1100, 1950, 2850, 3800, 4500, 4990, 5100, obj.currentAnimation.frameCount - 1];

		step = Title;
		game.event.wait(0, function() {
			gotoStep(0);
		});
	}

	public function addChild(o : h3d.scene.Object) {
		root.addChild(o);
	}

	public function isScene(x, y) {
		for(s in sceneZones)
			if(s.contains(new h3d.col.Point(x, y, 0))) return true;
		return false;
	}

	public function isSafe(x, y) {
		for(s in safeZones)
			if(s.contains(new h3d.col.Point(x, y, 0))) return true;
		return false;
	}

	public function triggerTrap(x, y) {
		if(!game.world.trapped(x, y)) return;
		if(Math.random() < 0.7 && game.foes.length < 80) {
			var da = hxd.Math.min(hxd.Math.random(Math.PI * 0.9), hxd.Math.random(Math.PI * 0.9)) * (hxd.Math.random() < 0.5 ? -1 : 1);
			var a = game.hero.targetRotation + da;
			var d = (0.2 + 0.8 * (1 - Math.abs(da) / Math.PI)) * 20;
			var x = game.hero.x + d * Math.cos(a);
			var y = game.hero.y + d * Math.sin(a);
			if(!collides(x, y) && !isSafe(x, y)) new ent.Foe(x, y, 0);
		}
	}

	function trapped(x, y) {
		for( t in traps)
			if(t.contains(new h3d.col.Point(x, y, 0))) return true;
		return false;
	}

	public function collides(x, y) {
		return !colliders.contains(new h2d.col.Point(x, y));
	}

	function initCollideShape(col : h3d.scene.Object) {
		colliders = [];
		var buffs = cast(col.toMesh().primitive, h3d.prim.HMDModel).getDataBuffers([new hxd.fmt.hmd.Data.GeometryFormat("position", DVec3)]);
		var dx = 0;// 8.5;
		var dy = 0;// -12;
		for(i in 0...Std.int(buffs.indexes.length / 3)) {
			var t = new h2d.col.Polygon();
			inline function addPoint(x:Float, y:Float) {
				t.push(new h2d.col.Point(x + dx, y + dy));
			}
			addPoint(buffs.vertexes[buffs.indexes[i * 3] * 3], buffs.vertexes[buffs.indexes[i * 3] * 3 + 1]);
			addPoint(buffs.vertexes[buffs.indexes[i * 3 + 1] * 3], buffs.vertexes[buffs.indexes[i * 3 + 1] * 3 + 1]);
			addPoint(buffs.vertexes[buffs.indexes[i * 3 + 2] * 3], buffs.vertexes[buffs.indexes[i * 3 + 2] * 3 + 1]);

			colliders.push(t);
		}
		colliders = colliders.toIPolygons(100).union(false).toPolygons(1 / 100);

/*
		var g = new h3d.scene.Graphics(game.s3d);
		g.lineStyle(3, 0xFF00FF);
		for(c in colliders) {
			for(i in 0...5) {
				var p0 = c.points[c.points.length - 1];
				g.moveTo(p0.x, p0.y, i*0.4);
				for(p in c.points) {
					g.lineTo(p.x, p.y, i*0.4);
					p0 = p;
				}
			}
		}*/
	}

	public function getFrameCoef() {
		return cam.obj.currentAnimation.frame / cam.obj.currentAnimation.frameCount;
	}

	function set_step(k : StepKind) {
		if(step == k) return step;

		var curId = allSteps.indexOf(k);
		if(stepId >= curId) return step;
		stepId = curId;
/*
		switch(k) {
			case Title:
				new ent.Foe(-75, 90, 6, false, false, true);
				new ent.Foe(-78, 90, 6, false, false, true);
				new ent.Foe(-77, 70, 5, false, false, true);
			default:
		}*/
		return step = k;
	}

	function stepUpdate(dt : Float) {
		if(step == null) return;
		if(!Game.PREFS.mobSpawn) return;

		inline function setFrontSpawn(dmax) {
			var da = hxd.Math.min(hxd.Math.random(Math.PI * 0.9), hxd.Math.random(Math.PI * 0.9)) * (hxd.Math.random() < 0.5 ? -1 : 1);
			var a = game.hero.targetRotation + da;
			var d = (0.2 + 0.8 * (1 - Math.abs(da) / Math.PI)) * dmax;
			var x = game.hero.x + d * Math.cos(a);
			var y = game.hero.y + d * Math.sin(a);
			if(!collides(x, y) && !isSafe(x, y)) new ent.Foe(x, y, 0);
		}

		switch (step) {
			case Phone:
				if(Math.random() < 0.015) {
					var d = 12 + hxd.Math.random(8);
					var a = hxd.Math.srand(Math.PI);
					var x = game.hero.x + d * Math.cos(a);
					var y = game.hero.y + d * Math.sin(a);
					if(!collides(x, y) && !isSafe(x, y)) new ent.Foe(x + d * Math.cos(a), y + d * Math.sin(a), 0, true, false, false);
				}

			case Park:
				if(Math.random() < 0.025) {
					var d = 10 + hxd.Math.random(8);
					var a = hxd.Math.srand(Math.PI);
					var x = game.hero.x + d * Math.cos(a);
					var y = game.hero.y + d * Math.sin(a);
					if(!collides(x, y) && !isSafe(x, y)) new ent.Foe(x + d * Math.cos(a), y + d * Math.sin(a), 0);
				}

			case River:
				if(Math.random() < 0.05) setFrontSpawn(20);
			case Shop:
				if(Math.random() < 0.1) setFrontSpawn(35);
			case Avenue :
				if(Math.random() < 0.2) setFrontSpawn(35);
			case Accident:
				if(Math.random() < 0.15) setFrontSpawn(30);
			case Forest:
				if(Math.random() < 0.25) setFrontSpawn(30);
			default:
		}
	}


	public function gotoStep(v : Int) {
		step = allSteps[v];
		if(v > 0) {
			cam.locked = false;

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
		else {
			game.hero.reset();
			cam.locked = true;

			game.s3d.camera.target = cam.obj.getObjectByName("Cameratitle.Target").localToGlobal();
			game.s3d.camera.pos = cam.obj.getObjectByName("Cameratitle").localToGlobal();
			game.ui.setTitle();

			game.event.clear();
			var pad = game.hero != null ? @:privateAccess game.hero.pad : null;
			if(pad != null) {
				var PAD = hxd.Pad.DEFAULT_CONFIG;
				game.event.waitUntil(function(dt) {
					if(hxd.Key.isPressed(hxd.Key.MOUSE_LEFT) || hxd.Key.isPressed(hxd.Key.MOUSE_RIGHT) || hxd.Key.isPressed(hxd.Key.ENTER) || hxd.Key.isPressed(hxd.Key.SPACE)
					|| pad.isPressed(PAD.A) || pad.isPressed(PAD.B) || pad.isPressed(PAD.X) || pad.isPressed(PAD.Y) || pad.isPressed(PAD.start)  || pad.isPressed(PAD.back) || pad.isPressed(PAD.LB) || pad.isPressed(PAD.RB)) {
						startGame();
						return true;
					}
					return false;
				});
			}
		}
	}

	function startGame() {
		game.ui.resetTitle();

		var cam = game.s3d.camera;
		var hero = game.hero;
		var camSpeed = 0.0005;
		game.event.waitUntil(function(dt) {
			cam.target.x += (hero.x - cam.target.x) * camSpeed * dt;
			cam.target.y += (hero.y - cam.target.y) * camSpeed * dt;
			cam.target.z += (hero.z + 1.5 - cam.target.z) * camSpeed * dt;

			var p = @:privateAccess game.getClampedFramePos();
			cam.pos.x += (p.x - cam.pos.x) * camSpeed * dt;
			cam.pos.y += (p.y - cam.pos.y) * camSpeed * dt;
			cam.pos.z += (p.z - cam.pos.z) * camSpeed * dt;
			camSpeed *= Math.pow(1.02, dt);

			if(Math.abs(cam.pos.z - p.z) < 0.1) {
				this.cam.locked = false;
				return true;
			}
			return false;
		});
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

		game.renderer.post.shader.bugPower = 0;
		@:privateAccess game.hero.stand();
		if(stepId != -1) gotoStep(stepId);
	}

	function bugPowerUpdate(dt : Float) {
		var r = 10;
		var v = 0.;
		for(f in game.foes) {
			var d = hxd.Math.distanceSq(f.x - game.hero.x, f.y - game.hero.y);
			if(d < r * r) {
				var n = (1 - Math.sqrt(d) / r) * 0.85;
				v += n * n * n * n * n;
			}
		}
		v = Math.min(1, v);
		game.renderer.post.shader.bugPower += (v - game.renderer.post.shader.bugPower) * 0.1 * dt;
	}

	public function update(dt: Float) {
		stepUpdate(dt);
		bugPowerUpdate(dt);
	}
}