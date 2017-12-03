package ui;

class UI
{
	var game : Game;
	var root : h2d.Sprite;
	var txtStart : h2d.Text;

	public function new() {
		game = Game.inst;
		root = new h2d.Sprite(game.s2d);
	}

	public function setTitle() {
		return;
		if(txtStart != null) txtStart.remove();

		txtStart = new h2d.Text(hxd.res.DefaultFont.get(), root);
		txtStart.text = "<Press any Key>";
		onResize();
	}

	public function resetTitle() {
		if(txtStart == null) return;
		game.event.waitUntil(function(dt) {
			txtStart.alpha -= 0.01 * dt;
			return txtStart.alpha <= 0;
		});
	}

	public function onResize() {
		if(txtStart != null) {
			txtStart.x = Std.int((game.s2d.width - txtStart.textWidth) * 0.5);
			txtStart.y = Std.int(game.s2d.height * 0.8);
		}
	}

}