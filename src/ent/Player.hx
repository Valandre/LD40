package ent;


class Player extends Character
{
	var pad : hxd.Pad;
	var usingPad = false;

	var moveSpeed = 0.15;
	var axisSpeed = 1.;
	var targetPos : h2d.col.Point;
	var canMove = false;

	public function new(x = 0., y = 0., z = 0.) {
		super(EPlayer, x, y, z);
		stand();
		hxd.Pad.wait(function(pad) {
			this.pad = pad;
		});
	}

	override function init() {
		obj = new h3d.scene.Object();
		obj.x = x;
		obj.y = y;
		obj.z = z;
		game.world.addChild(obj);

		var c = new h3d.prim.Cube(1, 1, 2);
		c.addNormals();
		c.addUVs();
		c.translate( -0.5, -0.5, 0);

		var m = new h3d.scene.Mesh(c, obj);
		m.material.mainPass.enableLights = true;
		m.material.shadows = true;
	}

	function stand() {
		if(job == Stand) return;
		canMove = true;
		targetPos = null;
		//play("stance_loop", {smooth : 0.2});
		setJob(Stand, null);
	}

	function move() {
		if(job == Move) return;
		canMove = true;

		if(usingPad) {
			//play("run_loop", {smooth : 0.2});
			setJob(Move, function(dt) {
				var a = new h3d.Vector(targetPos.x - x, targetPos.y - y);
				a.normalize();
				moveTo(a.x * moveSpeed * axisSpeed, a.y * moveSpeed * axisSpeed);
				//if(obj != null) obj.currentAnimation.speed = (body.velocity.length / moveSpeed) * 1.5;
			});
			return;
		}
	}

	function moveTo(dx : Float, dy : Float) {
		targetRotation = hxd.Math.atan2(dy, dx);
		x += dx;
		y += dy;
	}

	function getCameraAng() {
		var c = game.s3d.camera;
		return hxd.Math.atan2(y - c.pos.y, x - c.pos.x);
	}

	function updateKeys(dt : Float) {
		if(pad != null) {
			var deadZone = 0.3;
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

		if(targetPos != null )
			move();
		else stand();
	}

	override public function update(dt:Float) {
		updateKeys(dt);
		super.update(dt);
	}

}