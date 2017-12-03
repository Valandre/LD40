package pass;

class PostProcessingShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var colorTexture    : Sampler2D;
		
		function fragment() {
			var color = colorTexture.get(input.uv);

			{
				var uv = input.uv; 
				uv *=  1.0 - uv.yx;
				var vig = uv.x*uv.y * 15.0; // multiply with sth for intensity
				vig = pow(vig, 0.10); // change pow for modifying the extend of the  vignette
				color *= vig;
			}
			

			output.color = color;
		}
	};
}

class PostProcessing extends h3d.pass.ScreenFx<PostProcessingShader> {
	public function new() {
		super(new PostProcessingShader());
	}

	public function apply(from : h3d.mat.Texture, to : h3d.mat.Texture) {
		engine.pushTarget(to);
		pass.setBlendMode(None);
		shader.colorTexture  = from;
		render();
		engine.popTarget();
	}
}