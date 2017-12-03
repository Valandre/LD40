package ent;
import hxd.Key in K;


class Foe extends Character
{
	var acc = 0.;
	var targetPos : h2d.col.Point;
	var isStatic = false;
	var pl : ent.Player;

	var hitTime = 0.;

	public function new(x = 0., y = 0., z = 0., toSpawn = false, isStatic = false) {
		super(EFoe, x, y, z);
		this.isStatic = isStatic;
		this.pl = game.hero;

		game.foes.push(this);

		if(toSpawn)	spawn();
		else stand();
	}

	override public function remove() {
		super.remove();
		game.foes.remove(this);
	}

	override function get_moveSpeed() {
		return switch(game.world.step) {
			case River : 0.02;
			case Park: 0.04;
			case Shop : 0.06;
			case Accident, Forest, Tombstone : 0.1;
			default : 0.;
		}
	}

	override function init() {
		obj = new h3d.scene.Object();
		obj.x = x;
		obj.y = y;
		obj.z = z;
		obj.scaleZ = 0.9 + hxd.Math.random(0.3);
		game.world.addChild(obj);

		rotation = targetRotation = pl != null ? hxd.Math.atan2(pl.y - y, pl.x - x) : hxd.Math.srand(Math.PI);

		var c = new h3d.prim.Cube(0.9, 0.9, 2.5);
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
		speedRot = 0.;
		acc = 0;
		targetPos = null;

		var oz = z;
		z -= 4;
		//play("stance_loop", {smooth : 0.2});
		setJob(Spawn, function(dt) {
			z += (oz - z) * 0.1 * dt;
			obj.scaleX = obj.scaleY = 1 - (oz - z) * 0.5;
			if(z > oz-0.01) stand();
		});
	}

	function stand() {
		if(job == Stand) return;
		speedRot = 0.04;
		acc = 0;
		targetPos = null;
		//play("stance_loop", {smooth : 0.2});
		setJob(Stand, function(dt) {
			targetRotation = hxd.Math.atan2(pl.y - y, pl.x - x);
			if(!isStatic && Math.random() < 0.01 && hxd.Math.distanceSq(pl.x - x, pl.y - y) < 16 * 16) {
				move();
			}
		});
	}

	function move() {
		if(isStatic || job == Move) return;
		speedRot = 0.15;
		var accPower = 0.005 + hxd.Math.random(0.005);
		var spCoeff = 1 - hxd.Math.random() * 0.8;
		targetPos = new h2d.col.Point(pl.x, pl.y);
		//play("run_loop", {smooth : 0.2});

		setJob(Move, function(dt) {
			targetPos.x = pl.x;
			targetPos.y = pl.y;
			var a = new h3d.Vector(targetPos.x - x, targetPos.y - y);
			a.normalize();
			acc = hxd.Math.min(1, acc + accPower * dt);
			var sp = moveSpeed * spCoeff * acc * dt;
			moveTo(a.x * sp, a.y * sp);
			//if(obj != null) obj.currentAnimation.speed = (body.velocity.length / moveSpeed) * 1.5;
		});

		if(hxd.Math.distance(targetPos.x - x, targetPos.y - y) < 0.2) {
			stand();
			return;
		}
	}

	function dead() {
		if(job == Dead) return;
		setJob(Dead, function(dt) {
			remove();
		});
	}

	public function hit(v:Float) {
		hitTime += v;
		if(hitTime > 10) {
			dead();
			return;
		}
	}

	function hitShake() {
		z = hitTime * 0.01;
		for(m in obj.getMeshes()) {
			m.x = hxd.Math.srand(hitTime * 0.03);
			m.y = hxd.Math.srand(hitTime * 0.03);
			m.scaleX = m.scaleY = 1 + hitTime * 0.04;
			//m.material.blendMode = Alpha;
			//m.material.color.w = 1 - hitTime * 0.05;
		}
	}

	override public function update(dt:Float) {
		super.update(dt);
		if(!isStatic && hxd.Math.distanceSq(pl.x - x, pl.y - y) > 50 * 50)
			remove();

		if(hitTime != 0)
			hitTime = Math.max(0, hitTime - dt * 0.5);
		hitShake();

	}
}