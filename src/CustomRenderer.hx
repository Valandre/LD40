class CustomRenderer extends h3d.scene.Renderer {

	public var sao          : h3d.pass.ScalableAO;
	public var saoBlur      : h3d.pass.Blur;
	public var enableSao    : Bool;
	public var enableFXAA   : Bool;
	public var fxaa         : h3d.pass.FXAA;
	public var fog          : pass.Fog;

	public var enableBloom  : Bool;
	public var bloomExtract : pass.BloomExtract;
	public var bloomBlur    : h3d.pass.Blur;

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

		def = new h3d.pass.MRT([
			Value("output.color"), 
			PackFloat(Value("output.depth")), 
			PackNormal(Value("output.normal")), 
			Value("output.emissive")
		], null, true, [
			engine.backgroundColor, 
			0xFF0000, 
			0x808080, 
			0
		]);

		depthColorMap    = h3d.mat.Texture.fromColor(0xFFFFFF);
		depthColorNear   = 0.0;
		depthColorFar    = 1000.0; 
		depthColorMapId  = hxsl.Globals.allocID("depthColor.currentMap");
		depthColorNearId = hxsl.Globals.allocID("depthColor.near");
		depthColorFarId  = hxsl.Globals.allocID("depthColor.far");

		sao = new h3d.pass.ScalableAO();
		saoBlur = new h3d.pass.Blur(3, 3, 2);
		sao.shader.sampleRadius	= 0.2;

		fog  = new pass.Fog();
		fxaa = new h3d.pass.FXAA();
		
		bloomExtract = new pass.BloomExtract();
		bloomBlur = new h3d.pass.Blur(3, 3, 2);
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

		var outputTexture   = def.getTexture(0);
		var depthTexture    = def.getTexture(1);
		var normalTexture   = def.getTexture(2);
		var emissiveTexture = def.getTexture(3);

		if (enableSao) {
			// apply soa
			var saoTarget = allocTarget("sao", 0, false);
			setTarget(saoTarget);
			sao.apply(depthTexture, normalTexture, ctx.camera);
			resetTarget();
			saoBlur.apply(saoTarget, allocTarget("saoBlurTmp", 0, false));
			h3d.pass.Copy.run(saoTarget, outputTexture, Multiply);
		}

		{	// apply fog
			var fogTarget = allocTarget("fog", 0, false);
			fog.setGlobals(ctx);
			setTarget(fogTarget);
			fog.apply(
				outputTexture, 
				depthTexture, 
				normalTexture, 
				ctx.camera
			);
			resetTarget();
			outputTexture = fogTarget;
		}

		var bloomTexture = allocTarget("bloom", 1, false);
		if (enableBloom) {
			var bloomTexture = allocTarget("bloom", 1, false);
			h3d.pass.Copy.run(emissiveTexture, bloomTexture, None);
			bloomExtract.apply(outputTexture, bloomTexture);
			bloomBlur.apply(bloomTexture, allocTarget("blurBloom", 1, false));
			h3d.pass.Copy.run(bloomTexture, outputTexture, Add);
		}

		h3d.pass.Copy.run(emissiveTexture, outputTexture, Add);
		
		if (enableFXAA) {
			fxaa.apply(outputTexture);
		} else {
			h3d.pass.Copy.run(outputTexture, null, None);
		}
	}

}

/*{
	var uv = input.uv; 
	uv *=  1.0 - uv.yx;
	var vig = uv.x*uv.y * 15.0; // multiply with sth for intensity
	vig = pow(vig, 0.10); // change pow for modifying the extend of the  vignette
	color *= vig;
}*/