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
			m.mainPass.enableLights = true;
			m.shadows = true;

			if (!hasMRT) {
				m.addPass(new h3d.mat.Pass("depth",  m.mainPass));
				m.addPass(new h3d.mat.Pass("normal", m.mainPass));
			}
		}
		return obj;
	}
}