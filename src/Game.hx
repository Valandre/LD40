import hxd.Res;
import hxd.Key in K;

class Game extends hxd.App {

	static public var PREFS = initPrefs();
	static function initPrefs() {
		var prefs = { fullScreen : false, mobSpawn : true };
		prefs = hxd.Save.load(prefs, "prefs");
		return prefs;
	}

	public static var inst : Game;
	public var event : hxd.WaitEvent;
	public var modelCache : h3d.prim.ModelCache;
	public var renderer : CustomRenderer;

	public var entities : Array<ent.Entity>;
	public var foes : Array<ent.Foe>;
	public var world : map.World;
	public var hero : ent.Player;
	public var ui : ui.UI;

	var screenTransition : ui.ScreenTransition;
	var pause = false;
	var infos : h2d.Text;

	override function init() {
		modelCache   = new CustomCache();
		renderer     = new CustomRenderer();
		s3d.renderer = renderer;
		engine.fullScreen = PREFS.fullScreen;

		renderer.depthColorMap = hxd.Res.Gradients.test.toTexture();
		loadRenderConfig(renderer);

		s3d.camera.fovY = 36;

		s3d.lightSystem.ambientLight.set(0.9,0.9,0.9);
		var dir = new h3d.scene.DirLight(new h3d.Vector( -0.3, -0.2, -1), s3d);
		dir.color.set(0, 0, 0);
		dir.color.set(0.1,0.1,0.1);

		event = new hxd.WaitEvent();

		entities = [];
		foes = [];
		world = new map.World();
		hero = new ent.Player();

		ui = new ui.UI();
		ui.triggerSpeech(Title);
	}

	public function transition(?fadeIn = 0.25, ?fadeOut = 0.25, ?wait = 0.05, ?onReady : Void -> Void, ?onEnd : Void -> Void) {
		screenTransition = new ui.ScreenTransition(fadeIn, fadeOut, wait, onReady, function() {
			if(onEnd != null) onEnd();
			screenTransition = null;
		});
	}

	public function initCamera(x, y, z) {
		var cam = s3d.camera;
		cam.target.x = x;
		cam.target.y = y;
		cam.target.z = z + 1.5;

		var p = getClampedFramePos();
		cam.pos.x = p.x;
		cam.pos.y = p.y;
		cam.pos.z = p.z;
	}

	var tmp = new h2d.col.Point();
	inline function getClampedFramePos() {
		var p = world.getCameraFramePos(hero.x, hero.y);
		tmp.x = p.x - hero.x;
		tmp.y = p.y - hero.y;
		var d = hxd.Math.distanceSq(tmp.x, tmp.y);
		var r = 10;
		if(d < r * r) {
			tmp.normalize();
			tmp.scale(r);
			p.x = hero.x + tmp.x;
			p.y = hero.y + tmp.y;
		}
		else {
			var r = 25;
			if(d > r * r) {
				tmp.normalize();
				tmp.scale(r);
				p.x = hero.x + tmp.x;
				p.y = hero.y + tmp.y;
			}
		}

		return p;
	}

	public var camSpeed = 0.05;
	function cameraUpdate(dt : Float) {
		if(world.step == Title) return;
		if(world.cam.locked || hero == null) return;
		var cam = s3d.camera;
		cam.target.x += (hero.x - cam.target.x) * camSpeed * dt;
		cam.target.y += (hero.y - cam.target.y) * camSpeed * dt;
		cam.target.z += (hero.z + 1.5 - cam.target.z) * camSpeed * dt;

		var p = getClampedFramePos();
		cam.pos.x += (p.x - cam.pos.x) * camSpeed * dt;
		cam.pos.y += (p.y - cam.pos.y) * camSpeed * dt;
		cam.pos.z += (p.z - cam.pos.z) * camSpeed * dt;
	}


	function updateKeys(dt : Float) {
		if(K.isDown(K.CTRL) && K.isPressed("F".code)) {
			engine.fullScreen = !engine.fullScreen;
			PREFS.fullScreen = engine.fullScreen;
			hxd.Save.save(PREFS, "prefs");
		}

		if(K.isPressed("P".code))
			pause = !pause;

		 //DEBUG
		if(K.isPressed(K.F1)) {
			PREFS.mobSpawn = !PREFS.mobSpawn;
			hxd.Save.save(PREFS, "prefs");
			if(!PREFS.mobSpawn) {
				var i = foes.length - 1;
				while(i >= 0) {
					var f = foes[i--];
					if(f.isStatic) continue;
					f.remove();
				}
			}
		}

		if (K.isDown(K.RIGHT)) {
			renderer.post.shader.bugPower += 0.01;
			if (renderer.post.shader.bugPower > 1.0)
				renderer.post.shader.bugPower = 1.0;
		}

		if (K.isDown(K.LEFT)) {
			renderer.post.shader.bugPower -= 0.01;
			if (renderer.post.shader.bugPower < 0.0)
				renderer.post.shader.bugPower = 0.0;
		}

		inline function setStep(v : Int) {
			@:privateAccess if(world.stepId != v) {
				world.stepId = -1;
				world.respawn();
				world.gotoStep(v);
			}
		}
		if(K.isPressed(K.NUMBER_1)) setStep(0);
		if(K.isPressed(K.NUMBER_2)) setStep(1);
		if(K.isPressed(K.NUMBER_3)) setStep(2);
		if(K.isPressed(K.NUMBER_4)) setStep(3);
		if(K.isPressed(K.NUMBER_5)) setStep(4);
		if(K.isPressed(K.NUMBER_6)) setStep(5);
		if(K.isPressed(K.NUMBER_7)) setStep(6);
		if(K.isPressed(K.NUMBER_8)) setStep(7);
		if(K.isPressed(K.NUMBER_9)) setStep(8);
		if(K.isPressed(K.NUMBER_0)) setStep(9);
		/*
		if(hero != null) {
			@:privateAccess {
				//trace(hero.pad.isPressed(hxd.Pad.DEFAULT_CONFIG.A));
				if(hero.pad.isPressed(hxd.Pad.DEFAULT_CONFIG.LB))
					setStep(hxd.Math.imax(0 , world.stepId - 1));
				else if(hero.pad.isPressed(hxd.Pad.DEFAULT_CONFIG.RB))
					setStep(hxd.Math.imin(world.allSteps.length - 1, world.stepId + 1));
			}
		}*/


		if(K.isPressed(K.BACKSPACE)) {
			setStep(0);
			world.respawn();
		}

		if(infos == null) {
			infos = new h2d.Text(hxd.res.DefaultFont.get(), s2d);
			infos.x = 10;
		}
		infos.text =
		"[1-8] Change Place (" + world.step + ")\n" +
		"[BackSpace] Restart Game\n" +
		"[F1] Toggle mob spawn (" + PREFS.mobSpawn + ")\n";
		infos.y = s2d.height - infos.textHeight - 10;
	}

	public function getMousePicker( ?x, ?y ) {
		if( s3d == null ) return null;
		if( x == null )
			x = s2d.mouseX;
		if( y == null )
			y = s2d.mouseY;
		var camera = s3d.camera;
		var p = new h2d.col.Point( -1 + 2 * x / s2d.width, 1 - 2 * y / s2d.height);
		var pn = camera.unproject(p.x, p.y, 0);
		var pf = camera.unproject(p.x, p.y, 1);
		var pMin = pn;
		var pMax = pf;
		var dir = pMax.sub(pMin);
		dir.normalize();
		dir.scale3(0.01); // 10cm precious
		while( pMin.sub(pMax).dot3(dir) < 0 ) {
			var z = world.getZ(pMin.x, pMin.y);
			var dz = pMin.z - z;
			if( dz < 0)	return pMin;
			pMin.x += dir.x;
			pMin.y += dir.y;
			pMin.z += dir.z;
		}
		return null;
	}

	override function onResize() {
		super.onResize();
		if(screenTransition != null)
			screenTransition.onResize();
		if(ui != null)
			ui.onResize();
	}

	override function update(dt:Float) {
		/////
		//DEBUG ONLY

		var speed = pause ? 0 : 1.;
		if( K.isDown(K.SHIFT) || (hero != null && @:privateAccess hero.pad.isDown(hxd.Pad.DEFAULT_CONFIG.RB)))
			speed *= K.isDown(K.CTRL) ? 0.1 : 5;
		hxd.Timer.deltaT *= speed;
		hxd.Timer.tmod *= speed;
		dt *= speed;
		/////////

		ui.update(dt);
		updateKeys(dt);
		if(pause) return;

		cameraUpdate(dt);
		world.update(dt);
		event.update(dt);
		for(e in entities)
			e.update(dt);
	}

	function loadRenderConfig(renderer : CustomRenderer) {
		inline function getValue(k : Data.RenderConfigKind) {
			return Data.renderConfig.get(k).value;
		}

		//renderer.enableBloom             = getValue(EnableBloom);
		renderer.enableFXAA              = getValue(EnableFxaa);
		renderer.enableSao               = getValue(EnableSao);
		renderer.sao.shader.bias         = getValue(SaoBias);
		renderer.sao.shader.intensity    = getValue(SaoIntensity);
		renderer.sao.shader.sampleRadius = getValue(SaoRadius);
		renderer.saoBlur.sigma           = getValue(SaoBlur);

		s3d.camera.zNear = getValue(CameraNear);
		s3d.camera.zFar  = getValue(CameraFar);
	}

	public function onCdbReload() {
		loadRenderConfig(Std.instance(s3d.renderer, CustomRenderer));
	}

	static function main() {
		hxd.res.Resource.LIVE_UPDATE = true;
		hxd.Res.initLocal();
		Data.load(hxd.Res.data.entry.getBytes().toString());
		inst = new Game();
		hxd.Res.data.watch(function() {
			Data.load(hxd.Res.data.entry.getBytes().toString());
			inst.onCdbReload();
		});
	}
}