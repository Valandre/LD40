import hxd.Res;
import hxd.Key in K;


class Game extends hxd.App {

	public static var inst : Game;
	public var event : hxd.WaitEvent;
	public var modelCache : CustomCache;
	public var renderer : CustomRenderer;

	public var entities : Array<ent.Entity>;
	public var world : map.World;

	override function init() {
		modelCache = new CustomCache();
		renderer = new CustomRenderer();
		s3d.renderer = renderer;

		event = new hxd.WaitEvent();

		entities = [];
		world = new map.World();
		new ent.Player();
	}

	function updateKeys(dt : Float) {
		if(K.isDown(K.CTRL) && K.isPressed("F".code))
			engine.fullScreen = !engine.fullScreen;
	}

	override function update(dt:Float) {
		updateKeys(dt);
		event.update(dt);
		for(e in entities)
			e.update(dt);
	}

	static function main() {
		inst = new Game();
		hxd.res.Resource.LIVE_UPDATE = true;
		hxd.Res.initLocal();
	}
}