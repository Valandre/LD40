package;

class CustomCache extends h3d.prim.ModelCache {
	public function new() {
		super();
	}

	override function loadModel(res : hxd.res.Model) {
		var obj = super.loadModel(res);
		for (m in obj.getMaterials()) {
			if (m.blendMode == Add) {
				m.mainPass.setPassName("additive");
				m.mainPass.enableLights = false;
				m.shadows = false;
			} else {
				m.mainPass.addShader(new shader.DepthColor());
				m.mainPass.enableLights = true;
				m.shadows = true;
				
				if (m.texture != null) {
					m.textureShader.priority = 12;
					var name = haxe.io.Path.withoutExtension(m.texture.name);
					name += "_emi.png";
					if (hxd.Res.loader.exists(name)) {
						var p = new h3d.mat.Pass("emissive", m.mainPass);
						p.depth(false, LessEqual);
						p.addShader(new shader.EmissiveMap(hxd.Res.load(name).toTexture()));
						m.addPass(p);
					}
					
				}
			}
		}
		return obj;
	}
}