class CustomRenderer extends h3d.scene.Renderer {

	public var sao         : h3d.pass.ScalableAO;
	public var saoBlur     : h3d.pass.Blur;
	public var enableSao   : Bool;
	public var enableEdges : Bool;
	public var enableFXAA  : Bool;
	public var fxaa        : h3d.pass.FXAA;

	public var depthColorMap(default, set) : h3d.mat.Texture;
	public var depthColorNear : Float;
	public var depthColorFar  : Float;

	var depthColorMapId  : Int;
	var depthColorNearId : Int;
	var depthColorFarId  : Int;
	var depthColorMax    : Int;

	var out : h3d.mat.Texture;

	public function new() {
		super();

		var engine = h3d.Engine.getCurrent();
		if (!engine.driver.hasFeature(MultipleRenderTargets))
			throw "engine must have MRT";

		def = new h3d.pass.MRT(
			[Value("output.color"), PackFloat(Value("output.depth")), PackNormal(Value("output.normal"))], null, true,
			[engine.backgroundColor, 0xFF0000, 0x808080]);

		depthColorMap    = h3d.mat.Texture.fromColor(0xFFFFFF);
		depthColorNear   = 0.0;
		depthColorFar    = 1000.0; 
		depthColorMapId  = hxsl.Globals.allocID("depthColor.currentMap");
		depthColorNearId = hxsl.Globals.allocID("depthColor.near");
		depthColorFarId  = hxsl.Globals.allocID("depthColor.far");

		sao = new h3d.pass.ScalableAO();
		saoBlur = new h3d.pass.Blur(3, 3, 2);
		sao.shader.sampleRadius	= 0.2;

		fxaa = new h3d.pass.FXAA();
	}

	function set_depthColorMap(v : h3d.mat.Texture) {
		var pixels = v.capturePixels();
		depthColorMax = pixels.getPixel(pixels.width - 1, 0);

		var def = Std.instance(def, h3d.pass.MRT);
		if (def != null) def.clearColors[0] = depthColorMax;
		else h3d.Engine.getCurrent().backgroundColor = depthColorMax;

		return depthColorMap = v;
	}

	override function render() {
		ctx.setGlobalID(depthColorMapId,  depthColorMap);
		ctx.setGlobalID(depthColorNearId, depthColorNear);
		ctx.setGlobalID(depthColorFarId,  depthColorFar);

		super.render();

		var outputTexture : h3d.mat.Texture;
		var depthTexture  : h3d.mat.Texture;
		var normalTexture : h3d.mat.Texture;

		outputTexture = def.getTexture(0);
		depthTexture  = def.getTexture(1);
		normalTexture = def.getTexture(2);

		if (enableSao) {
			var saoTarget = allocTarget("sao",0,false);
			setTarget(saoTarget);
			sao.apply(depthTexture, normalTexture, ctx.camera);
			resetTarget();
			saoBlur.apply(saoTarget, allocTarget("saoBlurTmp", 0, false));
			h3d.pass.Copy.run(saoTarget, outputTexture, Multiply);
		}

		if (enableFXAA) fxaa.apply(outputTexture);
		else h3d.pass.Copy.run(outputTexture, null, None);
	}

}