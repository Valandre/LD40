import hxd.snd.*;

class Audio {
	public var musicChanGroup   : ChannelGroup;
	public var ambientChanGroup : ChannelGroup;
	public var uiChanGroup      : ChannelGroup;
	public var sfxChanGroup     : ChannelGroup;

	var music : Channel;
	var mainAmbient : Channel;

	public function new() {
		musicChanGroup   = new ChannelGroup("music");
		ambientChanGroup = new ChannelGroup("ambient");
		uiChanGroup      = new ChannelGroup("ui");
		sfxChanGroup     = new ChannelGroup("sfx");

		musicChanGroup.priority   = 100;
		ambientChanGroup.priority = 90;
		uiChanGroup.priority      = 80;
		sfxChanGroup.priority     = 40;

		mainAmbient = hxd.Res.Ambient.wind_loop.play(true, ambientChanGroup);

		ambientChanGroup.volume = 0.10;
		musicChanGroup.volume   = 0.25;
	}

	public function playMusic(snd : hxd.res.Sound, ?fadeIn = 0.0) {
		if (music != null) music.stop();
		music = snd.play(true, musicChanGroup);
		if (fadeIn > 0) {
			music.volume = 0.0;
			music.fadeTo(1.0, fadeIn);
		}
	}
}