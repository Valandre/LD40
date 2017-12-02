package ent;
import hxd.Key in K;


class Player extends Character
{
	var pad : hxd.Pad;
	var usingPad = false;

	var deadZone = 0.3;
	var moveSpeed(get, never) : Float;
	var axisSpeed = 1.;
	var acc = 0.;
	var targetPos : h2d.col.Point;
	var canMove = true;

	public function new(x = 0., y = 0., z = 0.) {
		super(EPlayer, x, y, z);
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

		//var lamp = obj.getObjectByName("Lampe");
		//lamp.follow = obj.getObjectByName("B_lamp");
	}

	function get_moveSpeed() {
		//return 0.2;
		return switch(game.world.curStep) {
			case 0,1 : 0.05;
			case 2,3 : 0.12;
			case 4,5 : 0.15;
			case 6,7 : 0.18;
			default : 0.15;
		}
	}

	function stand() {
		if(job == Stand) return;
		canMove = true;
		acc = 0;
		targetPos = null;
		//play("idle01", {smooth : 0.2});
		setJob(Stand, null);
	}

	function move() {
		if(job == Move) return;
		canMove = true;

		play("walk", {smooth : 0.2});

		setJob(Move, function(dt) {
			var a = new h3d.Vector(targetPos.x - x, targetPos.y - y);
			a.normalize();
			acc = hxd.Math.min(1, acc + 0.05 * dt);
			var sp = moveSpeed * axisSpeed * acc * dt;
			moveTo(a.x * sp, a.y * sp);
			//trace(x, y);
			if(obj != null) obj.currentAnimation.speed = (sp / moveSpeed / dt);
		});

		if(hxd.Math.distance(targetPos.x - x, targetPos.y - y) < 0.2) {
			stand();
			return;
		}
	}

	function getCameraAng() {
		var c = game.s3d.camera;
		return hxd.Math.atan2(y - c.pos.y, x - c.pos.x);
	}


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
		}

		if(!usingPad) {
			axisSpeed = 1;
			if(K.isDown(K.MOUSE_LEFT) ) {
				var pos = game.getMousePicker();
				if(pos != null)
					targetPos = new h2d.col.Point(pos.x, pos.y);
			}
		}

		if(targetPos != null )
			move();
		else stand();
	}

	override public function update(dt:Float) {
		updateKeys(dt);
		super.update(dt);
	}

}