package ent;

typedef PlayOptions = {
	@:optional var speed : Float;
	@:optional var loop : Bool;
	@:optional var smooth : Float;
	@:optional var onEnd : Void -> Void;
}

enum AnimationCommand {
	ASingle( a : h3d.anim.Animation );
}

class Entity {
	public var x(default, set) : Float;
	public var y(default, set) : Float;
	public var z(default, set) : Float;
	public var targetRotation : Float;
	public var rotation(default, set) : Float;

	var game : Game;
	var model : hxd.res.Model;
	var obj : h3d.scene.Object;

	var currentAnim(default,set) : { opts : PlayOptions, name : String };
	var cachedAnims = new Map<String,AnimationCommand>();

	public function new(x = 0., y = 0., z = 0.) {
		game = Game.inst;
		game.entities.push(this);
		this.x = x;
		this.y = y;
		this.z = z;
		init();
	}

	public function remove() {
		if(obj != null)	obj.remove();
		game.entities.remove(this);
	}

	function getModel() : hxd.res.Model {
		return null;
	}

	function init() {
		var res = getModel();
		if( res == null ) return;
		model = res;
		obj = game.modelCache.loadModel(res);
		obj.inheritCulled = true;
		obj.x = x;
		obj.y = y;
		obj.z = z;
		game.world.addChild(obj);
	}

	public function getBounds() {
		return obj == null ? null : obj.getBounds();
	}

	public function play( anim : String, ?opts : PlayOptions ) {
		if( currentAnim != null && currentAnim.name == anim ) return;
		if( opts == null ) opts = { };
		if( opts.speed == null ) opts.speed = 1;
		if( opts.smooth == null ) opts.smooth = 0.2;
		if( opts.loop == null ) opts.loop = true;
		currentAnim = { opts : opts, name : anim };
	}

	function set_currentAnim(c) {
		currentAnim = c;
		if( c == null || obj == null )
			return c;
		var anim = c.name;
		var a = cachedAnims.get(anim);
		if( a == null ) {
			a = getAnim(anim);
			if( a == null ) throw "Can't find anim " + anim;
			cachedAnims.set(anim, a);
		}

		playImpl(a);
		return c;
	}

	function getAnimPath() {
		return model.entry.directory;
	}

	function getAnim(name:String) : AnimationCommand {
		var loader = hxd.Res.loader;
		inline function load(path) return game.modelCache.loadAnimation(loader.load(path+".FBX").toModel());
		var path = getAnimPath() + "/Anim_" + name;

		var hasAnim = loader.exists(path + ".FBX");
		if( !hasAnim ) return null;

		return ASingle(load(path));
	}

	function playImpl( a : AnimationCommand ) {
		if( obj == null ) return;

		inline function playAnimation(a, loop) {
			obj.playAnimation(a);
			obj.currentAnimation.loop = loop;
			if( loop ) @:privateAccess obj.currentAnimation.frameCount--;
		}

		var opts = currentAnim.opts;
		var onEnd = opts.onEnd;
		var prev = obj.currentAnimation;
		switch( a ) {
		case ASingle(a):
			playAnimation(a,opts.loop);
			obj.currentAnimation.onAnimEnd = function() {
				if( onEnd != null ) onEnd();
			};
		}

		obj.currentAnimation.speed = opts.speed;

		if( prev != null && opts.smooth != 0 ) {
			var cur = obj.currentAnimation;
			var sm = new h3d.anim.SmoothTarget(cur, opts.smooth);
			obj.switchToAnimation(sm);
			sm.onAnimEnd = function() obj.switchToAnimation(cur);
		}
	}

	function set_x(v : Float) {
		if(obj != null)	obj.x = v;
		return x = v;
	}

	function set_y(v : Float) {
		if(obj != null)
			obj.y = v;
		return y = v;
	}

	function set_z(v : Float) {
		if(obj != null)
			obj.z = v;
		return z = v;
	}

	function set_rotation(v:Float) {
		if( obj != null )
			obj.setRotate(0, 0, v);
		return rotation = v;
	}

	public function update(dt : Float) {
	}
}