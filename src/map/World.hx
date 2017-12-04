package map;


class World
{
	var game : Game;
	var root : h3d.scene.Object;

	var stepId = -1;
	var stepFrames = [];
	var allSteps = Data.speech.all;

	var colliders : h2d.col.Polygons;
	var traps : Array<h3d.col.Collider> = [];
	var safeZones : Array<h3d.col.Sphere> = [];

	var sceneZones : Array<h3d.col.Sphere> = [];
	var memories : Array<h3d.scene.Object> = [];
	var flowers : Array<h3d.scene.Object> = [];
	var flowerGlow : Array<h3d.scene.Object> = [];

	public var step(default, set) : Data.SpeechKind;
	public var sceneLock = false;

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

	public function remove(){
		root.remove();
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
			if(m.name.substr(0, 5) == "Phone") {
				var b = m.getBounds();
				b.scaleCenter(2);
				sceneZones.push(b.toSphere());
			}
			if(m.name.substr(0, 8) == "Memories") {
				m.visible = false;
				memories.push(m);
			}
			if(m.name.substr(0, 6) == "Flower") {
				flowers.push(m);
				var b = m.getBounds();
				b.scaleCenter(4);
				sceneZones.push(b.toSphere());
				var l = new h3d.scene.PointLight();
				l.color.setColor(0xf7cf78);
				l.follow = m;
				l.params.set(1.0, 0.14, 0.07);
				var i = Std.parseInt(m.name.substr(6));
				var p = m.localToGlobal();
				switch(i) {
					case 1 :// park;
						game.audio.addAmbientAt(hxd.Res.Ambient.playground_loop,
							p.x, p.y, p.z
						);
					case 2 : // bridge
						game.audio.addAmbientAt(hxd.Res.Ambient.water_loop,
							p.x, p.y, p.z
						);
					default :
				}
				addChild(l);

				var glowRes = hxd.Res.Map.flower_glow;
				var glow = game.modelCache.loadModel(glowRes);
				glow.x = p.x;
				glow.y = p.y;
				glow.z = p.z;
				//glow.setScale(0.5);
				addChild(glow);
				var a = game.modelCache.loadAnimation(glowRes);
				glow.playAnimation(a);
				flowerGlow.push(glow);
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

		//Title, start, phone, park, river, shop, Avenue, accident, graveyard, tombstone
		stepFrames = [0, 1, 890, 1800, 2850, 3800, 4500, 4900, 5100, obj.currentAnimation.frameCount - 1];

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

	public function isSpeech(x, y) {
		for(s in sceneZones)
			if(s.contains(new h3d.col.Point(x, y, 0))) return true;
		return false;
	}

	public function getSpeechAt(x, y) {
		for(s in sceneZones)
			if(s.contains(new h3d.col.Point(x, y, 0))) return s;
		return null;
	}

	public function getFlowerAt(x : Float, y : Float ) {
		var flower = null;
		var d = 8.;
		for(f in flowers) {
			var p = f.localToGlobal();
			var dist = hxd.Math.distanceSq(p.x - x, p.y - y);
			if(dist < d) {
				flower = f;
				d = dist;
			}
		}

		return flower;
	}

	public function getFlowerGlowAt(x : Float, y : Float ) {
		var flower = null;
		var d = 8.;
		for(f in flowerGlow) {
			var p = f.localToGlobal();
			var dist = hxd.Math.distanceSq(p.x - x, p.y - y);
			if(dist < d) {
				flower = f;
				d = dist;
			}
		}

		return flower;
	}

	public function removeSpeechAt(x, y) {
		for(s in sceneZones)
			if(s.contains(new h3d.col.Point(x, y, 0))) {
				sceneZones.remove(s);
				break;
			}
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
	}

	public function getFrameCoef() {
		return cam.obj.currentAnimation.frame / cam.obj.currentAnimation.frameCount;
	}

	function set_step(k : Data.SpeechKind) {
		if(step == k) return step;

		var curId = Data.speech.get(k).index;
		if(stepId >= curId) return step;
		stepId = curId;
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
					var d = 8 + hxd.Math.random(6);
					var a = hxd.Math.srand(Math.PI);
					var x = game.hero.x + d * Math.cos(a);
					var y = game.hero.y + d * Math.sin(a);
					if(!collides(x, y) && !isSafe(x, y)) new ent.Foe(x + d * Math.cos(a), y + d * Math.sin(a), 0, true, false, false);
				}

			case Park:
				if(Math.random() < 0.025) {
					var d = 8 + hxd.Math.random(6);
					var a = hxd.Math.srand(Math.PI);
					var x = game.hero.x + d * Math.cos(a);
					var y = game.hero.y + d * Math.sin(a);
					if(!collides(x, y) && !isSafe(x, y)) new ent.Foe(x + d * Math.cos(a), y + d * Math.sin(a), 0);
				}

			case River:
				if(Math.random() < 0.05) setFrontSpawn(12);
			case Shop:
				if(Math.random() < 0.1) setFrontSpawn(20);
			case Avenue :
				if(Math.random() < 0.2) setFrontSpawn(35);
			case Accident:
				if(Math.random() < 0.15) setFrontSpawn(25);
			case Forest:
				if(Math.random() < 0.25) setFrontSpawn(30);
			default:
		}
	}


	public function gotoStep(v : Int) {
		step = allSteps[v].id;
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

			game.event.clear();
			var PAD = hxd.Pad.DEFAULT_CONFIG;
			game.event.waitUntil(function(dt) {
				if(step != Title) return true;
				if(hxd.Key.isPressed(hxd.Key.MOUSE_LEFT) || hxd.Key.isPressed(hxd.Key.MOUSE_RIGHT) || hxd.Key.isPressed(hxd.Key.ENTER) || hxd.Key.isPressed(hxd.Key.SPACE)) {
					startGame();
					return true;
				}
				var pad = Game.pad;
				if(pad == null) return false;
				if(pad.isPressed(PAD.A) || pad.isPressed(PAD.B) || pad.isPressed(PAD.X) || pad.isPressed(PAD.Y) || pad.isPressed(PAD.start)  || pad.isPressed(PAD.back) || pad.isPressed(PAD.LB) || pad.isPressed(PAD.RB)) {
					startGame();
					return true;
				}
				return false;
			});
		}
	}

	function startGame() {
		playScene(Title, function() {
			var cam = game.s3d.camera;
			var hero = game.hero;
			var camSpeed = 0.0005;

			game.audio.playMusic(hxd.Res.Music.title, 2.0);
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
					playScene(Start, null);
					return true;
				}
				return false;
			});
		});
	}

	function getStepFromFrame(f : Float) {
		var index = stepFrames.length - 1;
		while(index >= 0) {
			if(stepFrames[index] <= f) return allSteps[index].id;
			index--;
		}
		return allSteps[0].id;
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

	public function playScene(k : Data.SpeechKind, ?onEnd : Void -> Void) {
		if(sceneLock) return;

		var pressed = false;
		inline function actionPressed() {
			if(!Game.pad.isDown(Game.PAD.A)) pressed = false;
			if(!pressed && Game.pad.isDown(Game.PAD.A)) {
				pressed = true;
				return true;
			}
			return false;
		}

		inline function clearMobs(dist = 50) {
			var i = game.foes.length - 1;
			while(i >= 0) {
				var f = game.foes[i--];
				if(hxd.Math.distanceSq(f.x - game.hero.x, f.y - game.hero.y) < dist * dist)
					f.remove();
			}
		}

		var memory : h3d.scene.Object = null;
		inline function endScene() {
			game.camMaxDist = 25;
			game.camSpeed = 0.01;
			game.camDz = 0;
			game.event.wait(4, function() {
				game.camSpeed = 0.05;
			});

			if(memory != null) {
				for(m in memory.getMeshes())
					m.material.blendMode = Alpha;
				var a = 1.;
				game.event.waitUntil(function(dt) {
					a = Math.max(0, a - 0.01 * dt);
					for(m in memory.getMeshes())
						m.material.color.w = a;
					return a == 0;
				});
			}

			var flower = getFlowerAt(game.hero.x, game.hero.y);
			if(flower != null) {
				var p = flower.localToGlobal();
				game.hero.targetRotation = hxd.Math.atan2(p.y - game.hero.y, p.x - game.hero.x);

				var glow = getFlowerGlowAt(game.hero.x, game.hero.y);

				game.event.waitUntil(function(dt) {
					for(m in glow.getMeshes()) {
						m.material.color.w -= 0.05 * dt;
					}
					@:privateAccess game.hero.updateAngle(dt);
					if(hxd.Math.abs(hxd.Math.angle(game.hero.rotation - game.hero.targetRotation)) < 0.01) {
						game.hero.play("catch", {loop : false, onEnd : function() {
							removeSpeechAt(game.hero.x, game.hero.y);
							glow.visible = false;
							if(onEnd != null) onEnd();
							sceneLock = false;
						}});

						var catched = false;
						game.event.waitUntil(function(dt) {
							for(m in glow.getMeshes()) {
								m.material.color.w -= 0.05 * dt;
							}
							@:privateAccess if(!catched && game.hero.obj.currentAnimation.frame > game.hero.obj.currentAnimation.frameCount * 0.5) {
								flower.visible = false;
								catched = true;
							}
							return !sceneLock;
						});
						return true;
					}
					return false;
				});
			}
			else {
				removeSpeechAt(game.hero.x, game.hero.y);
				if(onEnd != null) onEnd();
				sceneLock = false;
			}
		}

		sceneLock = true;
		var t = 0.;
		switch(k) {
			case Phone :
				game.audio.playEventAt(hxd.Res.Sfx.pick_phone,
					game.hero.x, game.hero.y, game.hero.z
				);
				t = 1.5;
			case Park :
				game.audio.playUIEvent(hxd.Res.Sfx.flower);
				game.audio.playMusic(hxd.Res.Music.playground, 30.0, 0.1);
				game.renderer.flash(0xFFFFFF, 4);
				memory = memories[0];
				memory.visible = true;
				clearMobs();
				t = 3;
			case River :
				game.audio.playUIEvent(hxd.Res.Sfx.flower);
				game.renderer.flash(0xFFFFFF, 4);
				memory = memories[1];
				memory.visible = true;
				clearMobs();
				t = 3;
			case Shop :
				game.audio.playUIEvent(hxd.Res.Sfx.flower);
				game.audio.playMusic(hxd.Res.Music.city, 30.0, 0.1);
				game.renderer.flash(0xFFFFFF, 4);
				memory = memories[2];
				memory.visible = true;
				clearMobs();
				t = 3;
			case Accident :
				game.audio.playUIEvent(hxd.Res.Sfx.flower);
				game.audio.playMusic(hxd.Res.Music.run, 4.0, 0.1);
				game.renderer.flash(0xFFFFFF, 10.0);
				clearMobs();
				t = 3;
			default:
		}

		game.hero.stand();
		game.event.wait(t, function() {
			var b = game.ui.triggerSpeech(k);
			sceneLock = b;
			if(!sceneLock) {
				endScene();
				return;
			}

			if(memory == null) {
				var s = getSpeechAt(game.hero.x, game.hero.y);
				if(s != null)
					game.hero.targetRotation = hxd.Math.atan2(s.y - game.hero.y, s.x - game.hero.x);
			}
			else {
				var p = memory.localToGlobal();
				game.hero.targetRotation = hxd.Math.atan2(p.y - game.hero.y, p.x - game.hero.x);
			}

			if(k != Start) {
				game.camMaxDist = 9;
				game.camSpeed = 0.02;
				game.camDz = 1.5;
			}

			game.event.waitUntil(function(dt) {
				@:privateAccess game.hero.updateAngle(dt);
				if(step != k) {
					game.ui.clear();
					sceneLock = false;
					return  true;
				}
				if(actionPressed() || hxd.Key.isPressed(hxd.Key.MOUSE_LEFT))
					if(game.ui.triggerValidate()) {
						endScene();
						return true;
					}
				return false;
			});
		});
	}

	public function triggerSpeech(x, y) {
		if(isSpeech(x, y))
			playScene(step);
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
		game.audio.bugPower = game.renderer.post.shader.bugPower;
	}

	public function update(dt: Float) {
		if(!sceneLock) stepUpdate(dt);
		bugPowerUpdate(dt);
		triggerSpeech(game.hero.x, game.hero.y);
		triggerTrap(game.hero.x, game.hero.y);
	}
}