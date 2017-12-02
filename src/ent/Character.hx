package ent;

enum EntityKind {
	EPlayer;
	EFoe;
}


class Character extends ent.Entity {
	var kind : EntityKind;

	public function new(kind, x, y, z) {
		this.kind = kind;
		super(x, y, z);
	}
}