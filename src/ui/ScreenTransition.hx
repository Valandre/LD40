package ui;

class ScreenTransition
{
	var game : Game;
	var root : h2d.Sprite;
	var bg : h2d.Bitmap;

	public function new(?fadeIn = 0.25, ?fadeOut = 0.25, ?wait = 0.05, ?onReady : Void -> Void, ?onEnd : Void -> Void) {
		game = Game.inst;
		root = new h2d.Sprite(game.s2d);

		bg = new h2d.Bitmap(h2d.Tile.fromColor(0, game.s2d.width, game.s2d.height), root);
		bg.alpha = fadeIn;

		game.event.waitUntil(function(dt) {
			bg.alpha += fadeIn * dt;
			if(bg.alpha >= 1) {
				bg.alpha = 1;
				game.event.wait(wait, function() {
					if(onReady != null)
						onReady();
					game.event.waitUntil(function(dt) {
						bg.alpha -= fadeOut * dt;
						if(bg.alpha <= 0) {
							bg.alpha = 0;
							if(onEnd != null) onEnd();
							remove();
							return true;
						}
						return false;
					});
				});

				return true;
			}
			return false;
		});
	}

	public function onResize() {
		bg = new h2d.Bitmap(h2d.Tile.fromColor(0, game.s2d.width, game.s2d.height), root);
	}

	public function remove(){
		bg.remove();
		root.remove();
	}
}