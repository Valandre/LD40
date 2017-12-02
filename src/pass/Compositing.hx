package pass;

class CompositingShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var colorTexture  : Sampler2D;
		@param var depthTexture	 : Sampler2D;
		@param var normalTexture : Sampler2D;

		@param var cameraInverseViewProj : Mat4;
		@param var cameraPosition : Vec3;
		@param var zNear : Float;
		@param var zFar : Float;

		@global var depthColor : {
			var currentMap      : Sampler2D;
			var transitionMap   : Sampler2D;
			var transitionRatio : Float;
		};

		function getPosition(uv : Vec2) : Vec3 {
			var depth = unpack(depthTexture.get(uv));
			var uv2   = (uv - 0.5) * vec2(2, -2);
			var temp  = vec4(uv2, depth, 1) * cameraInverseViewProj;
			return vec3(temp.xyz / temp.w);
		}

		function getDist(uv : Vec2) : Float {
			var p = getPosition(uv);
			return (p - cameraPosition).length();
		}

		function fragment() {
			var dist   = getDist(input.uv);
			var normal = unpackNormal(normalTexture.get(input.uv));

			var fogIntensity = clamp((dist - zNear) / (zFar - zNear), 0.0, 1.0);
			output.color = mix(
				colorTexture.get(input.uv), 
				depthColor.currentMap.get(vec2(fogIntensity, 0.5)),
				fogIntensity);
		}
	};
}

class Compositing extends h3d.pass.ScreenFx<CompositingShader> {
	public function new() {
		super(new CompositingShader());
	}

	public function apply(
		color   : h3d.mat.Texture,
		depth	: h3d.mat.Texture, 
		normal  : h3d.mat.Texture,
		camera	: h3d.Camera)
	{
		camera.update();
		shader.colorTexture  = color;
		shader.normalTexture = normal;
		shader.depthTexture	 = depth;
		shader.zNear = camera.zNear;
		shader.zFar  = camera.zFar;
		shader.cameraInverseViewProj = camera.getInverseViewProj();
		shader.cameraPosition = camera.pos;
		
		render();
	}
}