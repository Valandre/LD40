package pass;

class PostProcessingShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var colorTexture : Sampler2D;
		@param var time : Float;

		function screenDistort(coords : Vec2) : Vec2 {
			var uv = coords;
			uv -= vec2(.5,.5);
			uv = uv*1.2*(1./1.2+2.*uv.x*uv.x*uv.y*uv.y);
			uv += vec2(.5,.5);
			return uv;
		}

		/*function vignette(coords : Vec2) : Float {
			var uv = coords;
			var vigAmt = 3.+.3*sin(time + 5.*cos(time*5.));
			return (1.-vigAmt*(uv.y-.5)*(uv.y-.5))*(1.-vigAmt*(uv.x-.5)*(uv.x-.5));
		}*/

		function vignette(coords : Vec2) : Float {
			var uv = coords;
			uv *=  1.0 - uv.yx;
			var vig = uv.x*uv.y * 15.0; // multiply with sth for intensity
			vig = pow(vig, 0.10); // change pow for modifying the extend of the  vignette
			return vig;
		}
		
		function fragment() {
			var color = colorTexture.get(input.uv);
			var vig = vignette(input.uv);
			output.color = color * vig;
		}
	};
}

class PostProcessing extends h3d.pass.ScreenFx<PostProcessingShader> {
	public function new() {
		super(new PostProcessingShader());
	}

	public function apply(from : h3d.mat.Texture, time : Float, ?to : h3d.mat.Texture) {
		engine.pushTarget(to);
		pass.setBlendMode(None);
		shader.colorTexture  = from;
		shader.time = time;
		render();
		engine.popTarget();
	}
}