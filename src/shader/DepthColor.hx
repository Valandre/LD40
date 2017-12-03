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
			var q  = (projectedPosition.z - camera.zNear) / (camera.zFar - camera.zNear);
			q += (pixelColor.r - 0.5) * 2.0;
			q  = saturate(q);
			pixelColor.rgb = depthColor.currentMap.get(vec2(q, 0.5)).rgb;
		}
	};

	public function new() {
		super();
		priority = 11;
	}

}