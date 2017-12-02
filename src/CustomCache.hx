package;

class CustomCache extends h3d.prim.ModelCache {
	public function new() {
		super();
	}

	override function loadModel(res : hxd.res.Model) {
		var obj = super.loadModel(res);
		for (m in obj.getMaterials()) {
			//m.texture = null;
			//m.color = new h3d.Vector(1.0, 0.0, 0.0, 1.0);
			m.mainPass.addShader(new shader.DepthColor());
			m.mainPass.enableLights = true;
			m.shadows = true;
			
			if (m.texture != null) {
				m.textureShader.priority = 12;
				var name = haxe.io.Path.withoutExtension(m.texture.name);
				name += "_emi.png";
				if (hxd.Res.loader.exists(name)) {
					m.mainPass.addShader(
						new shader.EmissiveMap(hxd.Res.load(name).toTexture())
					);
				}
			}
		}
		return obj;
	}
}