package ui;

class UI
{
	var game : Game;
	var root : h2d.Sprite;
	var text : h2d.Text;

	var sentenceQueue  : Array<String>;
	var curSentence    : String;
	var textAccu       : Float;
	var sndKeyGroup    : hxd.snd.SoundGroup;

	static var CHAR_COOLDOWN = 3.0;

	public function new() {
		game = Game.inst;
		root = new h2d.Sprite(game.s2d);

		sentenceQueue = [];
		curSentence   = null;

		sndKeyGroup = new hxd.snd.SoundGroup("keyGroup");
		sndKeyGroup.maxAudible = 1;
		sndKeyGroup.volume = 0.5;

		onResize();
	}

	public function triggerSpeech(id : Data.SpeechKind) {
		var sentences = Data.speech.get(id).value;
		sentenceQueue = sentences.split("#");
		nextSentence();
		onResize();
	}

	function nextSentence() : Bool {
		if (sentenceQueue.length == 0)
			return true;

		if (text != null) text.remove();

		curSentence = sentenceQueue.shift();

		text = new h2d.Text(hxd.Res.Font.anitypewriter_medium_24.toFont(), root);
		text.smooth   = true;
		text.maxWidth = text.calcTextWidth(curSentence);
		textAccu = 0.0;
		onResize();

		return false;
	}

	function nextCharacter() : Bool {
		if (curSentence.length == 0)
			return true;

		text.text += curSentence.charAt(0);
		curSentence = curSentence.substr(1);
		textAccu -= CHAR_COOLDOWN;

		var done = curSentence.length == 0;
		if (done) {
			var c = hxd.Res.Sfx.typewriterRoll.play(sndKeyGroup);
			c.priority = text.text.length;
		} else {
			var sfx = (Std.random(2) > 0)
				? hxd.Res.Sfx.typewriterKey1
				: hxd.Res.Sfx.typewriterKey2;
			var c = sfx.play(sndKeyGroup);
			c.priority = text.text.length;
		}

		return done;
	}

	public function isSpeaking() {
		return curSentence != null;
	}

	public function isWaitingValidation() : Bool {
		return curSentence != null && curSentence.length == 0;
	}

	public function triggerValidate() : Bool {
		if (curSentence == null)
			return true;

		if (curSentence.length > 0) {
			text.text += curSentence;
			curSentence = "";
			var c = hxd.Res.Sfx.typewriterRoll.play(sndKeyGroup);
			c.priority = text.text.length;
			return false;
		}

		var done = nextSentence();
		if (!done) return false;

		// speech is done
		curSentence  = null;
		text.remove();
		return true;
	}

	public function update(dt:Float) {
		if (hxd.Key.isPressed(hxd.Key.MOUSE_LEFT)) {
			triggerValidate();
		}

		if (curSentence != null && curSentence.length > 0) {
			textAccu += dt;
			while (textAccu > CHAR_COOLDOWN) {
				var done = nextCharacter();
				if (done) break;
			}
		}
	}

	public function onResize() {
		var textScale = game.s2d.height / 1080;
		if (text != null) {
			text.setScale(textScale);
			text.setPos(
				Std.int((game.s2d.width - text.maxWidth * textScale) * 0.5),
				Std.int(game.s2d.height * 0.9 - text.textHeight * textScale)
			);
		}
	}

}