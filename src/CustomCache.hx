package;

class CustomCache extends h3d.prim.ModelCache {
	var hasMRT : Bool;

	public function new(hasMRT : Bool) {
		super();
		this.hasMRT = hasMRT;
	}

	override function loadModel(res : hxd.res.Model) {
		var obj = super.loadModel(res);
		for (m in obj.getMaterials()) {
			m.texture = null;
			//m.color = new h3d.Vector(1.0, 0.0, 0.0, 1.0);
			m.mainPass.enableLights = true;
			m.shadows = true;
			m.receiveShadows = false;

			if (!hasMRT) {
				m.addPass(new h3d.mat.Pass("depth",  m.mainPass));
				m.addPass(new h3d.mat.Pass("normal", m.mainPass));
			}
			m.mainPass.addShader(new shader.DepthColor());
		}
		return obj;
	}
}