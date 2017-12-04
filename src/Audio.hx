import hxd.snd.*;

@:allow(Audio)
private class Event {
	@:noCompletion public var next   : Event;
	@:noCompletion public var nextOnHold : Event;

	public var snd        : hxd.res.Sound;
	public var group      : String;
	public var pos        : h3d.Vector;
	public var volume     : Float;
	public var pitch      : Float;
	public var target     : ent.Entity;
	public var loop       : Bool;
	public var fadeInTime : Float;

	var holdCond    : Void->Bool;
	var fadeOutTime : Float;
	var channel     : hxd.snd.Channel;
	var update      : hxd.snd.Channel->Void;

	public var holded (get, never) : Bool; inline function get_holded() return holdCond != null || target != null;

	static var cleanName : EReg;

	public function new(snd : hxd.res.Sound, volume : Float, ?pitch: Float, ?group : String, ?pos : h3d.Vector, ?target : ent.Entity) {
		this.snd = snd;
		this.pos = pos;
		this.volume = volume;
		this.target = target;
		this.fadeOutTime = 0.0;
		this.fadeInTime = 0.0;
		this.pitch = pitch!=null ? pitch : 1.0;

		if (group == null) {
			group = haxe.io.Path.withoutExtension(snd.name);
			if (cleanName == null) cleanName = ~/_?\d+$/g;
			group = cleanName.replace(group, "");
		}

		this.group = group;
	}

	public function holdWhile(cond : Void->Bool, loop = false, fadeOutTime = 0.0, ?update : hxd.snd.Channel->Void) {
		this.holdCond    = cond;
		this.fadeOutTime = fadeOutTime;
		this.loop        = loop;
		this.update      = update;
	}
}

class Audio {
	public var musicChanGroup   : ChannelGroup;
	public var ambientChanGroup : ChannelGroup;
	public var uiChanGroup      : ChannelGroup;
	public var sfxChanGroup     : ChannelGroup;

	public var bugPower : Float;

	var localEventSoundGroup   : SoundGroup;
	var localAmbientSoundGroup : SoundGroup;

	var music         : Channel;
	var mainAmbient   : Channel;
	var localAmbients : Array<Channel>;
	var bugAmbient    : Channel;

	var newEvents     : Event;
	var onHoldEvents  : Event;

	var time : Float;

	static var BASE_AMBIENT_VOLUME = 0.1;
	static var BUG_AMBIENT_VOLUME = 1.0;

	public function new() {
		musicChanGroup   = new ChannelGroup("music");
		ambientChanGroup = new ChannelGroup("ambient");
		uiChanGroup      = new ChannelGroup("ui");
		sfxChanGroup     = new ChannelGroup("sfx");

		musicChanGroup.priority   = 100;
		uiChanGroup.priority      = 90;
		ambientChanGroup.priority = 80;
		sfxChanGroup.priority     = 40;

		localEventSoundGroup = new SoundGroup("spatializedEvent");
		localEventSoundGroup.mono = true;

		localAmbientSoundGroup = new SoundGroup("spatializedAmbient");
		localAmbientSoundGroup.mono = true;
		localAmbientSoundGroup.maxAudible = 2 + 2; // main, bug, and 2 subs

		mainAmbient = hxd.Res.Ambient.wind_loop.play(true, BASE_AMBIENT_VOLUME, ambientChanGroup);
		bugAmbient  = hxd.Res.Ambient.shadow_loop.play(true, BUG_AMBIENT_VOLUME, ambientChanGroup);

		ambientChanGroup.volume = 1.0;
		musicChanGroup.volume   = 0.25;

		time = 0.0;
		bugPower = 0.0;
		localAmbients = [];
	}

	public function playUIEvent(snd : hxd.res.Sound, ?soundGroup : SoundGroup) {
		var c = snd.play(uiChanGroup, soundGroup);
		c.priority = time;
	}

	public function playMusic(snd : hxd.res.Sound, ?fadeIn = 0.0, ?fadeOut = 0.0) {
		if (music != null) {
			if (fadeOut > 0.0) music.fadeTo(0, fadeOut, music.stop);
			else music.stop();
		}
		music = snd.play(true, musicChanGroup);
		if (fadeIn > 0) {
			music.volume = 0.0;
			music.fadeTo(1.0, fadeIn);
		}
	}

	public function addAmbientAt(snd : hxd.res.Sound, x : Float, y : Float, z : Float, ?volume = 1.0) {
		var c = snd.play(true, volume, ambientChanGroup, localAmbientSoundGroup);
		var space = createAmbientSpace();
		space.position.set(x, y, z);
		c.addEffect(space);
		localAmbients.push(c);
		return c;
	}

	public function playEventAt(snd : hxd.res.Sound, x : Float, y : Float, z : Float, ?volume = 1.0, ?pitch : Float, ?group : String) : Event {
		var e = new Event(snd, volume, pitch, group, new h3d.Vector(x, y, z));
		regEvent(e);
		return e;
	}

	public function playEventOn(snd : hxd.res.Sound, target : ent.Entity, ?volume = 1.0, ?pitch : Float, ?group : String) : Event {
		var e = new Event(snd, volume, pitch, group, target);
		regEvent(e);
		return e;
	}

	public function update(dt : Float) {
		time += dt;
		updateEvents();
		updateAmbients();
	}

	public function updateAmbients() {
		bugAmbient.volume = BUG_AMBIENT_VOLUME * bugPower;

		var base = BASE_AMBIENT_VOLUME * (1 - bugPower);
		mainAmbient.volume = base;
		for (c in localAmbients) c.volume = base;
	}

	public function updateEvents() {
		var listenerPos = hxd.snd.Driver.get().listener.position;

		if (newEvents != null) {
			var lastGroup     : String = null;
			var closestEvent  : Event = null;
			var biggestVolume = 0.0;
			var closestDist   = Math.POSITIVE_INFINITY;
			var groupPos      = new h3d.Vector();
			var groupCount    = 0;

			inline function playLastGroup() {
				var c = closestEvent.snd.play(sfxChanGroup, closestDist >= 0 ? localEventSoundGroup : null);
				if( closestEvent.pitch != 1.0 ) c.addEffect(new hxd.snd.effect.Pitch(closestEvent.pitch));
				c.priority = time;
				if( closestEvent.fadeInTime > 0 ){
					c.volume = 0;
					c.fadeTo(biggestVolume, closestEvent.fadeInTime);
				} else c.volume   = biggestVolume;
				if (closestDist >= 0) {
					groupPos.scale3(1/groupCount);
					var s = createEventSpace();
					s.position.load(groupPos);
					c.addEffect(s);
				}
			}

			inline function playAndHold(e : Event) {
				var spatialized = e.pos != null || e.target != null; 
				var c = e.snd.play(e.loop, e.volume, sfxChanGroup, spatialized ? localEventSoundGroup : null);
				if( e.pitch != 1.0 ) c.addEffect(new hxd.snd.effect.Pitch(e.pitch));
				if (spatialized) {
					var s = createEventSpace();
					if (e.target != null) {
						s.position.set(e.target.x, e.target.y, e.target.z);
					} else {
						s.position.load(e.pos);
					}
					c.addEffect(s);
				}
				if( e.fadeInTime > 0 ){
					c.volume = 0;
					c.fadeTo(e.volume, e.fadeInTime);
				} else c.volume   = e.volume;
				e.channel = c;
				e.nextOnHold = onHoldEvents;
				onHoldEvents = e;
			}

			var e = haxe.ds.ListSort.sortSingleLinked(newEvents, compareEvent);
			while (e != null) {
				// special case for holded events
				if (e.holded) {
					if (lastGroup != null) playLastGroup();
					playAndHold(e);
					lastGroup = null;
					e = e.next;
					continue;
				}

				if (e.group != lastGroup) {
					if (lastGroup != null) playLastGroup();
					closestEvent  = null;
					closestDist   = Math.POSITIVE_INFINITY;
					lastGroup     = e.group;
					groupCount    = 0;
					biggestVolume = 0;
					groupPos.set(0, 0);
				}

				// common case : group events of the same group
				if (e.pos == null || closestDist < 0) {
					closestDist  = -1;
					closestEvent = e;
				} else {
					var dist = listenerPos.distanceSq(e.pos);
					if (dist < closestDist) {
						closestDist  = dist;
						closestEvent = e;
					}
					groupPos.set(groupPos.x + e.pos.x, groupPos.y + e.pos.y);
					++groupCount;
				}

				if (e.volume > biggestVolume) biggestVolume = e.volume;
				if (e.next == null) playLastGroup();
				e = e.next;
			}
			newEvents = null;
		}

		// should we stop some events on hold?
		var e = onHoldEvents;
		onHoldEvents = null;
		while (e != null) {
			var next = e.nextOnHold;
			// do not hold stopped channels
			if (@:privateAccess e.channel.driver == null) {
				e = next;
				continue;
			}

			if (e.holdCond != null && !e.holdCond() /*|| e.target != null && !e.target.isAlive()*/) {
				// fade out event
				if (e.fadeOutTime <= 0.0) e.channel.stop();
				else e.channel.fadeTo(0.0, e.fadeOutTime, e.channel.stop);
			} else {
				// keep holding the event
				e.channel.priority = time;
				e.nextOnHold = onHoldEvents;
				onHoldEvents = e;

				// update position
				if (e.target != null) {
					var s = e.channel.getEffect(hxd.snd.effect.Spatialization);
					s.position.set(e.target.x, e.target.y, e.target.z);
				}

				// call update callback
				if (e.update != null) e.update(e.channel);
			}
			e = next;
		}
	}

	public function dispose() {
		mainAmbient.stop();
		bugAmbient.stop();
		if (music != null) music.stop();
		for (c in localAmbients) c.stop();

		var e = onHoldEvents;
		while (e != null) {
			e.channel.stop();
			e = e.nextOnHold;
		} onHoldEvents = null;
	}

	inline function regEvent(e : Event) {
		e.next = newEvents;
		newEvents = e;
	}

	function createEventSpace() {
		var space = new hxd.snd.effect.Spatialization();
		space.maxDistance   = 48;
		space.fadeDistance  = 16;
		space.rollOffFactor = 0.5;
		return space;
	}

	function createAmbientSpace() {
		var space = new hxd.snd.effect.Spatialization();
		space.referenceDistance = 16;
		space.maxDistance   = 24;
		space.fadeDistance  = 16;
		return space;
	}

	function compareEvent(a : Event, b : Event) {
		if (a.group != b.group) return a.group > b.group ? 1 : -1;
		if (a.holded && !b.holded) return  1;
		if (!a.holded && b.holded) return -1;
		return 0;
	} 
}