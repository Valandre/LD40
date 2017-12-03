package scene;

class SpotLight extends h3d.scene.Light {

	var pshader : shader.SpotLight;
	var tmpVec  : h3d.Vector;

	public var params(get, set) : h3d.Vector;
	public var direction : h3d.Vector;

	public function new(?parent) {
		pshader = new shader.SpotLight();
		super(pshader, parent);
		direction = new h3d.Vector(1, 0, 0);
		tmpVec    = new h3d.Vector();
		setAngle(Math.PI / 8, Math.PI / 10);
	}

	override function get_color() {
		return pshader.color;
	}

	override function get_enableSpecular() {
		return pshader.enableSpecular;
	}

	override function set_enableSpecular(b) {
		return pshader.enableSpecular = b;
	}

	inline function get_params() {
		return pshader.params;
	}

	inline function set_params(p) {
		return pshader.params = p;
	}

	public function setAngle(outerAngle : Float, innerAngle : Float) {
		pshader.outerCutOff = Math.cos(outerAngle);
		pshader.innerCutOff = Math.cos(innerAngle);
	}

	override function emit(ctx) {
		var lum = hxd.Math.max(hxd.Math.max(color.r, color.g), color.b);
		var p = params;
		if( p.z == 0 ) {
			cullingDistance = (lum * 128 - p.x) / p.y;
		} else {
			var delta = p.y * p.y - 4 * p.z * (p.x - lum * 128);
			cullingDistance = (p.y + Math.sqrt(delta)) / (2 * p.z);
		}

		pshader.lightPosition.set(absPos._41, absPos._42, absPos._43);

		tmpVec.load(direction);
		var target = localToGlobal(tmpVec);
		target.x -= absPos._41;
		target.y -= absPos._42;
		target.z -= absPos._43;
		target.normalize();
		pshader.lightDirection.set(target.x, target.y, target.z);

		super.emit(ctx);
	}

}