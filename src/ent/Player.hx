package ent;


class Player extends Character
{
	public function new(x = 0., y = 0., z = 0.) {
		super(EPlayer, x, y, z);
	}

	override function init() {
		var obj = new h3d.scene.Object();
		obj.x = x;
		obj.y = y;
		obj.z = z;
		game.world.addChild(obj);

		var c = new h3d.prim.Cube(1, 1, 2);
		c.addNormals();
		c.addUVs();
		c.translate( -0.5, -0.5, 0);

		var m = new h3d.scene.Mesh(c, obj);
		m.material.mainPass.enableLights = true;
		m.material.shadows = true;
	}

}