package ent;
import hxd.Key in K;


class Player extends Character
{
	static var PAD = hxd.Pad.DEFAULT_CONFIG;

	var pad : hxd.Pad;
	var usingPad = false;

	var deadZone = 0.3;
	var axisSpeed = 1.;
	var acc = 0.;
	var targetPos : h2d.col.Point;

	var lampActive = true;
	var lampPower = 1.;
	var lampDist = 10.;
	var lampArc = Math.PI * 0.25;

	var tmp = new h2d.col.Point();
	var lampLight : h3d.scene.PointLight;
	var spotLight : scene.SpotLight;

	public function new(x = 0., y = 0., z = 0.) {
		super(EPlayer, x, y, z);
		walkRef = 0.05;
		runRef = 0.14;
		ray = 0.4;
		stand();
		hxd.Pad.wait(function(pad) {
			this.pad = pad;
		});
	}

	override function getModel():hxd.res.Model {
		return hxd.Res.chars.main_character.model;
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
		spotLight.color.set(1.0, 1.0, 0.6);

		spotLight.direction.set(-1, 0, 0);
		spotLight.follow = obj.getObjectByName("B_lamp");
		spotLight.params.set(1.0, 0.014, 0.0007);
		spotLight.setAngle(Math.PI / 8, Math.PI / 8);
		game.world.addChild(spotLight);
	}

	override function get_moveSpeed() {
		//return 0.2;
		return switch(game.world.step) {
			case Start, Phone : 0.05;
			case Park, River : 0.08;
			case Shop: 0.12;
			case Accident, Forest, Tombstone : 0.15;
			default : 0.15;
		}
	}

	function stand() {
		if(job == Stand) return;
		acc = 0;
		targetPos = null;
		play("idle01", {smooth : 0.2});
		setJob(Stand, null);
	}

	function move() {
		if(job == Move) return;

		setJob(Move, function(dt) {
			var a = new h3d.Vector(targetPos.x - x, targetPos.y - y);
			a.normalize();
			acc = hxd.Math.min(1, acc + 0.05 * dt);
			var sp = moveSpeed * axisSpeed * acc * dt;
			if(canMove) {
				play(moveSpeed > 0.1 ? "run" : "walk", {smooth : 0.2});
				moveTo(a.x * sp, a.y * sp);
				if(obj != null) obj.currentAnimation.speed = acc * moveSpeed / (moveSpeed > 0.1 ? runRef : walkRef);
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
		if(!lampActive) return;
		var da = lampArc * 0.5;

		for(e in game.foes) {
			if(e.job == Dead) continue;

			//for(m in e.obj.getMeshes())
				//m.material.color.r = 0;

			tmp.x = e.x - x;
			tmp.y = e.y - y;
			if(hxd.Math.distanceSq(tmp.x, tmp.y) > lampDist * lampDist) continue;
			if(Math.abs(hxd.Math.angle(rotation - hxd.Math.atan2(tmp.y, tmp.x))) > da) continue;
			e.hit(lampPower * dt);
			//for(m in e.obj.getMeshes())
				//m.material.color.r = 1;

		}

		//////DEBUG
		/*
		if(g == null) g = new h3d.scene.Graphics(game.s3d);
		g.clear();
		g.lineStyle(3, 0xA03010);

		g.moveTo(x, y, 0.1);
		g.lineTo(x + lampDist * Math.cos(rotation - da), y + lampDist * Math.sin(rotation - da), 0.1);
		g.moveTo(x, y, 0.1);
		g.lineTo(x + lampDist * Math.cos(rotation + da), y + lampDist * Math.sin(rotation + da), 0.1);

		g.moveTo(x + lampDist * Math.cos(rotation - da), y + lampDist * Math.sin(rotation - da), 0.1);
		for(i in 0...8)
			g.lineTo(x + lampDist * Math.cos(rotation - da + lampArc * (i + 1) / 8), y + lampDist * Math.sin(rotation - da + lampArc * (i + 1) / 8), 0.1);
		*/
	}

	function checkHurt() {
		for(e in game.foes) {
			if(e.job == Dead) continue;
			tmp.x = e.x - x;
			tmp.y = e.y - y;
			var r = 1 + ray + e.ray;
			if(hxd.Math.distanceSq(tmp.x, tmp.y) > r * r) continue;
			e.attack();
		}
	}


	var oldMousePos = new h2d.col.Point();
	function updateKeys(dt : Float) {
		usingPad = false;
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

			canMove = !pad.isDown(PAD.A);
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

		if(targetPos != null )
			move();
		else stand();
	}

	override public function update(dt:Float) {
		checkHurt();
		if(!game.world.cam.locked && job != Dead) {
			updateKeys(dt);
			checkLamp(dt);
		}
		super.update(dt);
	}

}