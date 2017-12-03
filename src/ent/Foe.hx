package ent;
import hxd.Key in K;


class Foe extends Character
{
	public var isStatic = false;

	var acc = 0.;
	var targetPos : h2d.col.Point;
	var pl : ent.Player;

	var hitTime = 0.;
	var scaleRef = 0.01;

	public function new(x = 0., y = 0., z = 0., toSpawn = true, canMove = true, isStatic = false) {
		super(EFoe, x, y, z);
		this.isStatic = isStatic;
		this.canMove = canMove;
		this.pl = game.hero;
		walkRef = 0.05;
		runRef = 0.14;
		ray = 0.4;

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
			case Phone, River : 0.02;
			case Park: 0.04;
			case Shop : 0.06;
			case Accident, Forest, Tombstone : 0.1;
			default : 0.;
		}
	}


	override function getModel():hxd.res.Model {
		var id = Std.random(3);
		return hxd.Res.load("chars/shadows/model0" + id + ".FBX").toModel();
	}

	override function init() {
		model = getModel();
		if(model == null) return;

		obj = game.modelCache.loadModel(model);
		obj.setScale(scaleRef);
		obj.x = x;
		obj.y = y;
		obj.z = z;
		obj.scaleZ *= 0.9 + hxd.Math.random(0.25);
		game.world.addChild(obj);

		rotation = targetRotation = pl != null ? hxd.Math.atan2(pl.y - y, pl.x - x) : hxd.Math.srand(Math.PI);
	}

	function spawn() {
		if(job == Spawn) return;
		speedRot = 0.;
		acc = 0;
		targetPos = null;
		play("shadows_spawn", {smooth : 0.2, loop : false, onEnd : stand});
	}

	function stand() {
		if(job == Stand) return;
		speedRot = 0.04;
		acc = 0;
		targetPos = null;
		play("shadows_idle", {smooth : 0.2});
		setJob(Stand, function(dt) {
			targetRotation = hxd.Math.atan2(pl.y - y, pl.x - x);
			if(canMove && Math.random() < 0.01 /*&& hxd.Math.distanceSq(pl.x - x, pl.y - y) < 16 * 16*/)
				move();
		});
	}

	function move() {
		if(!canMove || job == Move) return;
		speedRot = 0.15;
		acc = 0;
		var accPower = 0.005 + hxd.Math.random(0.005);
		var spCoeff = 1 - hxd.Math.random() * 0.8;
		targetPos = new h2d.col.Point(pl.x, pl.y);
		play(moveSpeed > 0.1 ? "shadows_run" : "shadows_walk", {smooth : 0.2, speed : 0});

		setJob(Move, function(dt) {
			targetPos.x = pl.x;
			targetPos.y = pl.y;
			var a = new h3d.Vector(targetPos.x - x, targetPos.y - y);
			a.normalize();
			acc = hxd.Math.min(1, acc + accPower * dt);
			var sp = moveSpeed * spCoeff * acc * dt;
			moveTo(a.x * sp, a.y * sp);
			obj.currentAnimation.speed = acc * moveSpeed / (moveSpeed > 0.1 ? runRef : walkRef);
		});
	}

	public function attack() {
		if(job == Attack) return;
		targetPos = new h2d.col.Point(pl.x, pl.y);
		play("shadows_grab", {loop : false});
		setJob(Attack, function(dt) {
			if(obj.currentAnimation.frame < obj.currentAnimation.frameCount * 0.15) return;
			@:privateAccess pl.dead();
			targetPos.x = pl.x;
			targetPos.y = pl.y;
			targetRotation = hxd.Math.atan2(pl.y - y, pl.x - x);
			/*
			var a = new h3d.Vector(targetPos.x - x, targetPos.y - y);
			if(hxd.Math.distanceSq(a.x, a.y) > 0.1) {
				a.normalize();
				var sp = 0.25 * dt;
				moveTo(a.x * sp, a.y * sp);
			}*/
		});
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
		for(m in obj.getMeshes()) {
			m.x = x + hxd.Math.srand(hitTime * 0.03);
			m.y = y + hxd.Math.srand(hitTime * 0.03);
			m.scaleX = m.scaleY = scaleRef * (1 + hitTime * 0.04);
			/*
			m.material.mainPass.setPassName("alpha");
			m.material.blendMode = Alpha;
			m.material.color.w = 1 - hitTime * 0.05;*/
		}
	}

	override public function update(dt:Float) {
		super.update(dt);
		if(!isStatic && hxd.Math.distanceSq(pl.x - x, pl.y - y) > 50 * 50)
			remove();

		if(hitTime != 0)
			hitTime = Math.max(0, hitTime - dt * 0.5);
		if(job != Spawn) hitShake();
	}
}