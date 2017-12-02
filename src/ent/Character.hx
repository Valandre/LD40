package ent;

enum EntityKind {
	EPlayer;
	EFoe;
}

enum JobKind {
	Stop;
	Wait;

	Stand;
	Move;
	Dead;
	Spawn;
}

class Character extends ent.Entity {
	var kind : EntityKind;
	var job : JobKind;
	var currentJobFunc : Float -> Void;
	var currentJobOnStop : Void -> Void;
	var speedRot = 0.15;

	public function new(kind, x, y, z) {
		this.kind = kind;
		super(x, y, z);
	}

	function setJob(j : JobKind, f : Float->Void, onStop = null ) {
		job = j;
		if( currentJobOnStop != null ) {
			currentJobFunc = null;
			currentJobOnStop();
			if( currentJobFunc != null ) throw "Can't change job in onStop";
		}
		currentJobOnStop = onStop;
		currentJobFunc = f;
		return j;
	}

	public function stop() {
		setJob(Stop, null);
	}

	function wait( time : Float, ?onEnd ) {
		waitJob(Wait, time, onEnd);
	}

	function waitJob( j : JobKind, time : Float, ?onEnd, ?checkStop, autoStop = true ) {
		var wait = false;
		setJob(j, function(t) {
			if(checkStop != null && checkStop()) {
				stop();
				return;
			}
			if( wait ) return;
			time -= t;
			if( time < 0 ) {
				wait = true;
				if( autoStop ) stop();
				if( onEnd != null ) onEnd();
			}
		});
	}

	function moveTo(dx : Float, dy : Float) {
		targetRotation = hxd.Math.atan2(dy, dx);
		x += dx;
		y += dy;
	}

	function updateAngle(dt : Float) {
		if( rotation == targetRotation ) return false;
		rotation = hxd.Math.angleMove(rotation, targetRotation, (0.05 + Math.abs(hxd.Math.angle(rotation - targetRotation))) * speedRot * dt);
		return true;
	}

	override public function update(dt:Float) {
		super.update(dt);
		if( currentJobFunc != null )
			currentJobFunc(dt);
		updateAngle(dt);
	}
}