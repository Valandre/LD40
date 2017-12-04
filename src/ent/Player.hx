package ent;
import hxd.Key in K;


class Player extends Character
{
	var usingPad = false;

	var deadZone = 0.3;
	var axisSpeed = 1.;
	var acc = 0.;
	var targetPos : h2d.col.Point;

	var lampActive = true;
	var lampPower = 1.;
	var lampDist = 12.;
	var lampArc = Math.PI * 0.25;
	var lampBattery = 5.;

	var tmp = new h2d.col.Point();
	var lampLight : h3d.scene.PointLight;
	var spotLight : scene.SpotLight;
	var matLight : h3d.mat.Material;

	var spotColor = new h3d.Vector(1, 1, 0.6);

	public function new(x = 0., y = 0., z = 0.) {
		super(EPlayer, x, y, z);
		walkRef = 0.04;
		runRef = 0.14;
		ray = 0.4;
		runAt = 0.085;
		reset();
	}

	override function getModel():hxd.res.Model {
		return hxd.Res.chars.main_character.model;
	}

	public function reset() {
		x = y = z = 0;
		rotation = targetRotation = Math.PI+1;
		lampBattery = 5;
		stand();
	}

	override function init() {
		model = getModel();
		if(model == null) return;

		obj = game.modelCache.loadModel(model);
		obj.setScale(0.01);
		for(m in obj.getMeshes()) {
			m.material.mainPass.enableLights = true;
			m.material.shadows = true;
		}
		game.world.addChild(obj);

		matLight = obj.getMaterialByName("Mat_light");

		var lamp = obj.getObjectByName("Lampe");
		lamp.follow = obj.getObjectByName("B_lamp");

		lampLight = new h3d.scene.PointLight(obj);
		lampLight.setPos(-20, 0, 0);
		lampLight.color.set(1.0, 1.0, 0.6);
		lampLight.follow = obj.getObjectByName("B_lamp");
		lampLight.params.set(1.0, 0.7, 1.8);
		game.world.addChild(lampLight);

		spotLight = new scene.SpotLight(obj);
		spotLight.setPos(-20, 0, 0);
		spotLight.color.setColor(spotColor.toColor());

		spotLight.direction.set(-1, 0, 0);
		spotLight.follow = obj.getObjectByName("B_lamp");
		spotLight.params.set(1.0, 0.22, 0.20, 0);
		spotLight.setAngle(Math.PI / 8, Math.PI / 8);
		game.world.addChild(spotLight);
	}

	override function get_moveSpeed() {
		var v = game.world.getFrameCoef();
		return 0.05 + 0.15 * v * v;
	}

	public function stand() {
		if(job == Stand) return;
		acc = 0;
		targetPos = null;
		play("idle01", {smooth : 0.2});
		setJob(Stand, null);
	}

	function move() {
		if(job == Move) return;

		var stepWalkFrames = [10, 25];
		var stepRunFrames = [0, 10];
		var stepSprintFrames = [7, 15];
		var nextStepId = 0;
		var sprintRef = 0.2;

		setJob(Move, function(dt) {
			if(targetPos == null) {
				stand();
				return;
			}
			var a = new h3d.Vector(targetPos.x - x, targetPos.y - y);
			a.normalize();
			acc = hxd.Math.min(1, acc + 0.05 * dt);
			var sp = moveSpeed * axisSpeed * acc * dt;

			if(canMove) {
				var sprinting = moveSpeed > 0.125;
				var running = moveSpeed > runAt;
				play(sprinting ? "sprint" : running ? "run" : "walk", {smooth : 0.2});
				moveTo(a.x * sp, a.y * sp);
				if(obj != null) {
					obj.currentAnimation.speed = acc * moveSpeed / (sprinting ? sprintRef : running ? runRef : walkRef);

					var tab = sprinting ? stepSprintFrames : running ? stepRunFrames : stepWalkFrames;
					if(obj.currentAnimation.frame > tab[nextStepId] && (nextStepId != 0 || obj.currentAnimation.frame < tab[1]) ) {
						nextStepId = 1 - nextStepId;
						game.audio.playEventAt(hxd.Res.Sfx.step, x, y, z, 25 * sp * (0.5 + 0.5 * Math.random()), 1 + hxd.Math.srand(0.2));
					}
				}
			}
			else {
				targetRotation = hxd.Math.atan2(a.y, a.x);
				play("idle01");
			}
		});

		if(hxd.Math.distance(targetPos.x - x, targetPos.y - y) < 0.2) {
			stand();
			return;
		}
	}

	function dead() {
		if(job == Dead) return;

		game.audio.playUIEvent(hxd.Res.Sfx.hero_die);
		play("death", {loop : false});
		var time = 100.;
		setJob(Dead, function(dt) {
			time -= dt;
			if(time < 0) {
				game.transition(0.01, 0.025, game.world.respawn);
				currentJobFunc = null;
			}
		});
	}

	function getCameraAng() {
		var c = game.s3d.camera;
		return hxd.Math.atan2(y - c.pos.y, x - c.pos.x);
	}

	var g : h3d.scene.Graphics;
	function checkLamp(dt : Float) {
		if(!lampActive || job == LampReload) return;
		var da = lampArc * 0.5;

		for(e in game.foes) {
			if(!e.canBeHit()) continue;

			//for(m in e.obj.getMeshes())
				//m.material.color.r = 0;

			tmp.x = e.x - x;
			tmp.y = e.y - y;
			var d2 = hxd.Math.distanceSq(tmp.x, tmp.y);
			if(d2 > lampDist * lampDist) continue;
			if(Math.abs(hxd.Math.angle(rotation - hxd.Math.atan2(tmp.y, tmp.x))) > da) continue;

			var d = 1 - hxd.Math.min(1, Math.sqrt(d2) / lampDist * 0.5);
			e.hit(lampPower * d * dt);
			//for(m in e.obj.getMeshes())
				//m.material.color.r = 1;
		}
	}

	function checkHurt() {
		if(game.world.isSafe(x, y)) return;
		for(e in game.foes) {
			if(e.job == Dead || e.job == Spawn) continue;
			tmp.x = e.x - x;
			tmp.y = e.y - y;
			var r = ray + e.ray;
			if(hxd.Math.distanceSq(tmp.x, tmp.y) > r * r) continue;
			e.attack();
		}
	}

	var oldMousePos = new h2d.col.Point();
	function updateKeys(dt : Float) {
		usingPad = false;
		var pad = Game.pad;
		if(pad != null) {
			var xAxis = pad.xAxis;
			var yAxis = pad.yAxis;
			var n = new h2d.col.Point(xAxis, yAxis);
			axisSpeed = hxd.Math.clamp(n.length() * 1.5);
			if(axisSpeed < deadZone) {
				xAxis = yAxis = 0;
				axisSpeed = 0;
			}
			if(xAxis != 0 || yAxis != 0) {
				usingPad = true;
				var a = hxd.Math.atan2(yAxis, xAxis) + getCameraAng() + Math.PI * 0.5;
				targetPos = new h2d.col.Point(x + Math.cos(a), y + Math.sin(a));
			}
			else targetPos = null;

			canMove = !pad.isDown(Game.PAD.X);
		}

		if(!usingPad) {
			axisSpeed = 1;
			//if(K.isDown(K.MOUSE_LEFT) || K.isDown(K.MOUSE_RIGHT)) {
			if(K.isDown(K.MOUSE_LEFT) || oldMousePos.x != game.s2d.mouseX || oldMousePos.y != game.s2d.mouseY) {
				oldMousePos.x = game.s2d.mouseX;
				oldMousePos.y = game.s2d.mouseY;
				var pos = game.getMousePicker();
				if(pos != null)
					targetPos = new h2d.col.Point(pos.x, pos.y);
			}
			//}

			canMove = K.isDown(K.MOUSE_LEFT);// !K.isDown(K.SPACE);
		}

		if(pad.isDown(Game.PAD.A) || K.isDown(K.MOUSE_RIGHT))
			lampReload();
		else if(targetPos != null )
			move();
		else
			stand();
	}

	var lightCoef = 1.;
	function updateBattery(dt : Float) {
		if(game.world.cam.locked) return;
		lampBattery = Math.max(0, lampBattery - dt / 60);
		lampActive = lampBattery > 0;

		var min = 10;
		if(lampBattery < min) {
			var v = lampBattery <= 0 ? 0 : hxd.Math.max(0, lightCoef);
			matLight.color.w = v;
			lampLight.color.set(v * spotColor.x, v * spotColor.y, v * spotColor.z);
			spotLight.color.set(v * spotColor.x, v * spotColor.y, v * spotColor.z);

			if(Math.random() < 0.1)
				lightCoef = Math.max(lampBattery / min, lightCoef - 0.25);
			else lightCoef = Math.min(1, lightCoef + 0.015 * dt);
		}
	}

	function isReloading() {
		return job == LampReload;
	}

	function lampReload() {
		if(job == LampReload) return;
		if(lampBattery > 10) return;
		lampBattery = 0;

		var e = game.audio.playEventOn(hxd.Res.Sfx.lamp_reload, this);
		e.holdWhile(isReloading, true, 0.2);
		e.fadeInTime = 0.2;

		play("reload", {loop : true, speed : 1.8});
		setJob(LampReload, function(dt) {
			lampBattery += dt * 5 / 60;
			if(lampBattery > 10) {
				lampBattery = 45;
				matLight.color.w = 1;
				lampLight.color.set(spotColor.x, spotColor.y, spotColor.z);
				spotLight.color.set(spotColor.x, spotColor.y, spotColor.z);
				lightCoef = 1;
				stand();
			}
		});
	}

	override public function update(dt:Float) {
		updateBattery(dt);
		if(!game.world.sceneLock) {
			checkHurt();
			if(!game.world.cam.locked && job != Dead) {
				updateKeys(dt);
				checkLamp(dt);
			}
		}

		super.update(dt);
	}

}