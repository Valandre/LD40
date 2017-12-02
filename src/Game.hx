import hxd.Res;
import hxd.Key in K;

class Game extends hxd.App {

	public static var inst : Game;
	public var event : hxd.WaitEvent;
	public var modelCache : h3d.prim.ModelCache;
	public var renderer : CustomRenderer;

	public var entities : Array<ent.Entity>;
	public var world : map.World;
	public var hero : ent.Player;

	override function init() {
		modelCache   = new CustomCache();
		renderer     = new CustomRenderer();
		s3d.renderer = renderer;

		renderer.depthColorMap = hxd.Res.Gradients.test.toTexture();
		loadRenderConfig(renderer);

		s3d.lightSystem.ambientLight.set(0.5, 0.5, 0.5);
		var dir = new h3d.scene.DirLight(new h3d.Vector( -0.3, -0.2, -1), s3d);
		dir.color.set(0.5, 0.5, 0.5);

		event = new hxd.WaitEvent();

		entities = [];
		world = new map.World();
		hero = new ent.Player();

		event.wait(0, initCamera);
	}

	function initCamera() {
		if(hero == null) return;
		var cam = s3d.camera;
		cam.target.x = hero.x;
		cam.target.y = hero.y;
		cam.target.z = hero.z;

		var p = world.getCameraFramePos(hero.x, hero.y);
		cam.pos.x = p.x;
		cam.pos.y = p.y;
		cam.pos.z = p.z;
	}

	function cameraUpdate(dt : Float) {
		if(hero == null) return;

		var cam = s3d.camera;
		cam.target.x += (hero.x - cam.target.x) * 0.15 * dt;
		cam.target.y += (hero.y - cam.target.y) * 0.15 * dt;
		cam.target.z += (hero.z - cam.target.z) * 0.15 * dt;

		var p = world.getCameraFramePos(hero.x, hero.y);
		cam.pos.x += (p.x - cam.pos.x) * 0.01 * dt;
		cam.pos.y += (p.y - cam.pos.y) * 0.01 * dt;
		cam.pos.z += (p.z - cam.pos.z) * 0.01 * dt;
	}

	function updateKeys(dt : Float) {
		if(K.isDown(K.CTRL) && K.isPressed("F".code))
			engine.fullScreen = !engine.fullScreen;
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

	override function update(dt:Float) {
		updateKeys(dt);

		cameraUpdate(dt);
		event.update(dt);
		for(e in entities)
			e.update(dt);

		if(hero != null && Math.random() < 0.01) {
			var d = 10 + Math.random() * 6;
			var a = hxd.Math.srand(Math.PI);
			new ent.Foe(hero.x + d * Math.cos(a), hero.y + d * Math.sin(a));
		}
	}

	function loadRenderConfig(renderer : CustomRenderer) {
		inline function getValue(k : Data.RenderConfigKind) {
			return Data.renderConfig.get(k).value;
		}

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