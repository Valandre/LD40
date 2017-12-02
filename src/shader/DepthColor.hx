package shader;

class DepthColor extends hxsl.Shader {

	static var SRC = {
		@global var camera : {
			var zNear : Float;
			var zFar : Float;
		};

		@global var depthColor : {
			var currentMap      : Sampler2D;
			var transitionMap   : Sampler2D;
			var transitionRatio : Float;
		};

		var pixelColor        : Vec4;
		var projectedPosition : Vec4;

		function fragment() {
			var q = (projectedPosition.z - camera.zNear) / (camera.zFar - camera.zNear);

			var offset = abs((pixelColor.r - 0.5) * 2.0);
			q += offset;
			q = clamp(q, 0.0, 1.0);
			pixelColor.rgb = depthColor.currentMap.get(vec2(q, 0.5)).rgb;
			//pixelColor.rgb = vec3(offset);
		}
	};

	public function new() {
		super();
		priority = 11;
	}

}