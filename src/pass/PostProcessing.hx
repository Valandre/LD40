package pass;

// inspired by https://www.shadertoy.com/view/Ms23DR
// and https://www.shadertoy.com/view/ldjGzV

class PostProcessingShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var colorTexture : Sampler2D;
		@param var time : Float;
		@param var bugPower : Float;
		@param var tsize : Vec2;

		function curve(uv : Vec2) : Vec2 {
			uv = (uv - 0.5) * 2.0;
			uv   *= 1.1;	
			uv.x *= 1.0 + pow((abs(uv.y) / 5.0), 2.0);
			uv.y *= 1.0 + pow((abs(uv.x) / 4.0), 2.0);
			uv    = (uv / 2.0) + 0.5;
			uv    =  uv *0.92 + 0.04;
			return uv;
		}

		function vignette(uv : Vec2) : Float {
			var vig = 16.0 * uv.x * uv.y * (1.0-uv.x) * (1.0-uv.y);
			return pow(vig,0.3);
		}

		function onOff(a : Float, b : Float, c : Float) : Float {
			return step(c, sin(time + a * cos(time * b)));
		}

		function readColor(uv : Vec2) : Vec3 {
			var window = 1. / (1.+20.*(uv.y-mod(time/4.,1.))*(uv.y-mod(time/4.,1.)));
			uv.x += sin(uv.y * 10. + time) / 50.0 * (1.0 + cos(time*80.))
				* onOff(4.0, 4.0, 0.3)
				* (1.0 + cos(time * 80.)) * window * bugPower;
			
			var vShift = 0.15 * onOff(4.0, 5.0, 0.9) * (sin(time)*sin(time*15.) + (0.5 + 0.1*sin(time*150.)*cos(time)));
			vShift *= cos(time * 50) * sin(time * 20);
			uv.y = mod(uv.y + vShift * bugPower, 1.);

			return colorTexture.get(uv).rgb;
		}
		
		function fragment() {
			var uv = input.uv;
			uv = curve(uv);
			var color = readColor(uv);

			if (uv.x < 0.0 || uv.x > 1.0) color *= 0.0;
			if (uv.y < 0.0 || uv.y > 1.0) color *= 0.0;

			// scanlines
			var s = sin(time * 10 + uv.y * tsize.y);
			color *= vec3(0.96 + 0.04 * s);

			// vignette
			var vig = vignette(input.uv);
			color *= vig;

			output.color = vec4(color, 1.0);
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
		shader.bugPower = 0.0;
		shader.tsize.set(from.width, from.height);
		render();
		engine.popTarget();
	}
}