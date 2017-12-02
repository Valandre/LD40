package shader;

class DepthColor extends hxsl.Shader {

	static var SRC = {
		@global var depthColor : {
			var currentMap      : Sampler2D;
			var near            : Float;
			var far             : Float;
			var transitionMap   : Sampler2D;
			var transitionRatio : Float;
		};

		var pixelColor        : Vec4;
		var projectedPosition : Vec4;

		function fragment() {
			var q = (projectedPosition.z - depthColor.near) 
			      / (depthColor.far - depthColor.near);
			q = saturate(q);
			pixelColor.rgb = depthColor.currentMap.get(vec2(q, 0)).rgb;
		}
	};

	public function new() {
		super();
	}

}