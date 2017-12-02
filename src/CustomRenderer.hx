class CustomRenderer extends h3d.scene.Renderer {

	public var sao         : h3d.pass.ScalableAO;
	public var saoBlur     : h3d.pass.Blur;
	public var hasMRT      : Bool;
	public var enableSao   : Bool;
	public var enableEdges : Bool;
	public var enableFXAA  : Bool;
	public var fxaa        : h3d.pass.FXAA;

	public var depthColorMap(default, set) : h3d.mat.Texture;

	var depthColorMapId : Int;
	var depthColorMax   : Int;
	var out : h3d.mat.Texture;

	public var bench = new h3d.impl.Benchmark();

	public function new() {
		super();

		var engine = h3d.Engine.getCurrent();
		hasMRT = engine.driver.hasFeature(MultipleRenderTargets);
		if (hasMRT) def = new h3d.pass.MRT(
			[Value("output.color"), PackFloat(Value("output.depth")), PackNormal(Value("output.normal"))], null, true,
			[engine.backgroundColor, 0xFF0000, 0x808080]);

		depthColorMap   = h3d.mat.Texture.fromColor(0xFFFFFF);
		depthColorMapId = hxsl.Globals.allocID("depthColor.currentMap");

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

	override function renderPass(name, p:h3d.pass.Base, passes) {
		bench.measure(name);
		return super.renderPass(name, p, passes);
	}

	override function render() {
		ctx.setGlobalID(depthColorMapId, depthColorMap);

		super.render();

		var outputTexture = allocTarget("output", 0, true);
		if (hasMRT) h3d.pass.Copy.run(def.getTexture(0), outputTexture);

		var depthTexture  : h3d.mat.Texture;
		var normalTexture : h3d.mat.Texture;
		if (hasMRT) {
			depthTexture  = def.getTexture(1);
			normalTexture = def.getTexture(2);
		} else {
			depthTexture  = depth.getTexture();
			normalTexture = normal.getTexture();
		}

		if (enableSao) {
			bench.measure("sao");
			var saoTarget = allocTarget("sao",0,false);
			setTarget(saoTarget);
			sao.apply(depthTexture, normalTexture, ctx.camera);
			resetTarget();
			bench.measure("saoBlur");
			saoBlur.apply(saoTarget, allocTarget("saoBlurTmp", 0, false));
			bench.measure("saoBlend");
			h3d.pass.Copy.run(saoTarget, outputTexture, Multiply);
		}

		if (enableFXAA) fxaa.apply(outputTexture);
		else h3d.pass.Copy.run(outputTexture, null, None);
	}

}