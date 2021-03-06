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
		walkRef = 0.04;
		runRef = 0.14;
		ray = 0.4;

		game.foes.push(this);

		if(toSpawn)	spawn();
		else {
			stand();
			obj.currentAnimation.setFrame(Math.random() * obj.currentAnimation.frameCount);
		}

		var e = game.audio.playEventOn(hxd.Res.Sfx.shadow_fry, this, 0.0);
		e.holdWhile(isAlive, true, 0.1, updateHitVolume);
	}

	function updateHitVolume(c : hxd.snd.Channel) {
		c.volume = obj.culled ? 0.0 : Math.min(hitTime, 1.0);
	}

	function isAlive() {
		return job != Dead && @:privateAccess obj.allocated;
	}

	override public function remove() {
		super.remove();
		game.foes.remove(this);
	}

	override function get_moveSpeed() {
		var v = game.world.getFrameCoef();
		return 0.02 + 0.14 * v * v;
		/*
		return switch(game.world.step) {
			case Phone, Park : 0.02;
			case River: 0.04;
			case Shop : 0.06;
			case Accident, Forest, Tombstone : 0.1;
			default : 0.;
		}*/
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

	public function canBeHit() {
		return job != Dead && (job != Spawn || obj.currentAnimation.frame > obj.currentAnimation.frameCount * 0.5);
	}

	function spawn() {
		if(job == Spawn) return;
		speedRot = 0.;
		acc = 0;
		targetPos = null;
		play("shadows_spawn", {smooth : 0.2, speed : 1.2 + Math.random() * 0.25, loop : false, onEnd : stand});
		setJob(Spawn, null);
	}

	function stand() {
		if(job == Stand) return;
		speedRot = 0.04;
		acc = 0;
		targetPos = null;
		play("shadows_idle", {smooth : 0.2});
		setJob(Stand, function(dt) {
			targetRotation = hxd.Math.atan2(pl.y - y, pl.x - x);
			if(canMove && Math.random() < 0.01 * Data.speech.get(game.world.step).index /*&& hxd.Math.distanceSq(pl.x - x, pl.y - y) < 16 * 16*/)
				move();
		});
	}

	function move() {
		if(!canMove || job == Move) return;
		speedRot = 0.15;
		acc = 0;
		var accPower = 0.005 + hxd.Math.random(0.005);
		var spCoeff = 1 - hxd.Math.random() * 0.5;
		targetPos = new h2d.col.Point(pl.x, pl.y);
		play(moveSpeed * spCoeff > runAt ? "shadows_run" : "shadows_walk", {smooth : 0.2, speed : 0});

		setJob(Move, function(dt) {
			targetPos.x = pl.x;
			targetPos.y = pl.y;
			var a = new h3d.Vector(targetPos.x - x, targetPos.y - y);
			a.normalize();
			acc = hxd.Math.min(1, acc + accPower * dt);
			var sp = moveSpeed * spCoeff * acc * dt;
			moveTo(a.x * sp, a.y * sp);
			obj.currentAnimation.speed = (acc * moveSpeed * spCoeff) / ((moveSpeed * spCoeff) > runAt ? runRef : walkRef);
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
			rotation = targetRotation = hxd.Math.atan2(pl.y - y, pl.x - x);

			for(m in obj.getMeshes()) {
				m.material.blendMode = Alpha;
				m.material.color.w -= 0.015 * dt;
			}
		});
	}

	function dead() {
		if(job == Dead) return;
		if (!obj.culled)
			game.audio.playEventAt(hxd.Res.Sfx.shadow_die, x, y, z, 0.9 + Math.random() * 0.2);
		setJob(Dead, function(dt) {
			remove();
		});
	}

	public function hit(v:Float) {
		if(!canBeHit()) return;
		hitTime += v;
		if(hitTime > 10) {
			dead();
			return;
		}
	}

	function hitShake() {
		for(m in obj.getMeshes()) {
			m.x = x + hxd.Math.srand(hitTime * 0.02);
			m.y = y + hxd.Math.srand(hitTime * 0.02);
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

		if(game.world.isSafe(x, y))
			hit(1);

		if(hitTime != 0)
			hitTime = Math.max(0, hitTime - dt * 0.5);
		if(canBeHit()) hitShake();
	}
}