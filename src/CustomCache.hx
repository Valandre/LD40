package;

class CustomCache extends h3d.prim.ModelCache {
	public function new() {
		super();
	}

	override function loadModel(res : hxd.res.Model) {
		var obj = super.loadModel(res);
		for (m in obj.getMaterials()) {
			m.texture = null;
			//m.color = new h3d.Vector(1.0, 0.0, 0.0, 1.0);
			m.mainPass.enableLights = true;
			m.shadows = true;
			m.receiveShadows = false;
			m.mainPass.addShader(new shader.DepthColor());
		}
		return obj;
	}
}