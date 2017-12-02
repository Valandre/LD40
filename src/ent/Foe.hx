package ent;
import hxd.Key in K;


class Foe extends Character
{
	var moveSpeed = 0.15;
	var acc = 0.;
	var targetPos : h2d.col.Point;
	var canMove = true;

	public function new(x = 0., y = 0., z = 0.) {
		super(EFoe, x, y, z);
		speedRot = 0.02;
		spawn();
	}

	override function init() {
		obj = new h3d.scene.Object();
		obj.x = x;
		obj.y = y;
		obj.z = z;
		game.world.addChild(obj);

		rotation = targetRotation = game.hero != null ? hxd.Math.atan2(game.hero.y - y, game.hero.x - x) : hxd.Math.srand(Math.PI);

		var c = new h3d.prim.Cube(1, 1, 2.5);
		c.addNormals();
		c.addUVs();
		c.translate( -0.5, -0.5, 0);

		var m = new h3d.scene.Mesh(c, obj);
		m.material.mainPass.enableLights = true;
		m.material.shadows = true;
		m.material.color.setColor(0);
	}

	function spawn() {
		if(job == Spawn) return;
		canMove = true;
		acc = 0;
		targetPos = null;

		z = -4;
		//play("stance_loop", {smooth : 0.2});
		setJob(Spawn, function(dt) {
			z -= z * 0.1 * dt;
			obj.scaleX = obj.scaleY = 1 - z * 0.5;
			if(z > -0.01) stand();
		});
	}

	function stand() {
		if(job == Stand) return;
		canMove = true;
		acc = 0;
		targetPos = null;
		//play("stance_loop", {smooth : 0.2});
		setJob(Stand, function(dt) {
			targetRotation = hxd.Math.atan2(game.hero.y - y, game.hero.x - x);
		});
	}

	function move() {
		if(job == Move) return;
		canMove = true;

		//play("run_loop", {smooth : 0.2});

		setJob(Move, function(dt) {
			var a = new h3d.Vector(targetPos.x - x, targetPos.y - y);
			a.normalize();
			acc = hxd.Math.min(1, acc + 0.05 * dt);
			var sp = moveSpeed * acc * dt;
			moveTo(a.x * sp, a.y * sp);
			//if(obj != null) obj.currentAnimation.speed = (body.velocity.length / moveSpeed) * 1.5;
		});

		if(hxd.Math.distance(targetPos.x - x, targetPos.y - y) < 0.2) {
			stand();
			return;
		}
	}

}