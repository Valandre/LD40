package pass;

class Emissive extends h3d.pass.Default {

	var emissiveMapId : Int;
	public var reduceSize : Int = 0;
	public var blur : h3d.pass.Blur;

	public function new() {
		super();
		emissiveMapId = hxsl.Globals.allocID("emissiveMap");
		blur = new h3d.pass.Blur(2, 3);
	}

	override function getOutputs() : Array<hxsl.Output> {
		return [Value("emissiveColor")];
	}

	override function draw( passes : h3d.pass.Object ) {
		var outputTex  = tcache.allocTarget("emissiveMap", ctx, ctx.engine.width >> reduceSize, ctx.engine.height >> reduceSize, false);
		var captureTex = tcache.allocTarget("captureTex",  ctx, ctx.engine.width, ctx.engine.height, true);

		ctx.engine.pushTarget(captureTex);
		ctx.engine.clear(0);
		passes = super.draw(passes);
		ctx.engine.popTarget();

		h3d.pass.Copy.run(captureTex, outputTex, None);
		blur.apply(outputTex, tcache.allocTarget("tmpBlur", ctx, outputTex.width, outputTex.height, false));

		ctx.setGlobalID(emissiveMapId, { texture : outputTex });
		return passes;
	}
}