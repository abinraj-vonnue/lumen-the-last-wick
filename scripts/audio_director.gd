extends Node
## Procedural atmospheric soundscape and sound-effect synthesizer for Lumen: The Last Wick.
## Operates with zero external binary dependencies while supporting optional external audio overrides.

const MIX_RATE := 22050.0
const OPTIONAL_AUDIO_PATHS := {
	"step": "res://assets/audio/sfx_step.ogg",
	"jump": "res://assets/audio/sfx_jump.ogg",
	"land": "res://assets/audio/sfx_land.ogg",
	"dash": "res://assets/audio/sfx_dash.ogg",
	"flare": "res://assets/audio/sfx_flare.ogg",
	"platform_on": "res://assets/audio/sfx_platform_on.ogg",
	"platform_off": "res://assets/audio/sfx_platform_off.ogg",
	"switch": "res://assets/audio/sfx_switch.ogg",
	"gate": "res://assets/audio/sfx_gate.ogg",
	"checkpoint": "res://assets/audio/sfx_checkpoint.ogg",
	"death": "res://assets/audio/sfx_death.ogg",
	"respawn": "res://assets/audio/sfx_respawn.ogg",
	"complete": "res://assets/audio/sfx_complete.ogg",
}

var _ambience_player: AudioStreamPlayer
var _ambience_playback: AudioStreamGeneratorPlayback
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_playbacks: Array[AudioStreamGeneratorPlayback] = []
var _active_voices: Array[Dictionary] = []
var _ambience_phase_a: float = 0.0
var _ambience_phase_b: float = 0.0
var _ambience_phase_c: float = 0.0
var _crackle_seed: int = 13579
var _stage_mood: int = 0
var _is_finale_screen: bool = false
var _headless_mode: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_headless_mode = DisplayServer.get_name() == "headless" or AudioServer.get_driver_name() == "Dummy"
	if _headless_mode:
		set_process(false)
		return

	var amb_stream := AudioStreamGenerator.new()
	amb_stream.mix_rate = MIX_RATE
	amb_stream.buffer_length = 0.25
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "AmbiencePlayer"
	_ambience_player.stream = amb_stream
	_ambience_player.volume_db = -14.5
	add_child(_ambience_player)
	_ambience_player.play()
	_ambience_playback = _ambience_player.get_stream_playback() as AudioStreamGeneratorPlayback

	for idx in 4:
		var gen := AudioStreamGenerator.new()
		gen.mix_rate = MIX_RATE
		gen.buffer_length = 0.35
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer_%d" % idx
		player.stream = gen
		player.volume_db = -8.0
		add_child(player)
		player.play()
		_sfx_players.append(player)
		_sfx_playbacks.append(player.get_stream_playback() as AudioStreamGeneratorPlayback)


func set_stage_mood(stage_index: int, is_finale: bool = false) -> void:
	_stage_mood = clampi(stage_index, 0, 5)
	_is_finale_screen = is_finale


func play_sfx(event_name: String, volume_scale: float = 1.0) -> void:
	if _headless_mode:
		return
	if OPTIONAL_AUDIO_PATHS.has(event_name):
		var ext_path: String = OPTIONAL_AUDIO_PATHS[event_name]
		if ResourceLoader.exists(ext_path):
			var stream := load(ext_path) as AudioStream
			if stream != null:
				var ext_player := AudioStreamPlayer.new()
				ext_player.stream = stream
				ext_player.volume_db = linear_to_db(clampf(volume_scale, 0.05, 1.5)) - 6.0
				add_child(ext_player)
				ext_player.finished.connect(ext_player.queue_free)
				ext_player.play()
				return
	_enqueue_procedural_voice(event_name, volume_scale)


func _enqueue_procedural_voice(event_name: String, volume_scale: float) -> void:
	var voice := {
		"type": event_name,
		"time": 0.0,
		"duration": 0.18,
		"freq_start": 220.0,
		"freq_end": 220.0,
		"freq_alt": 0.0,
		"noise": 0.0,
		"amp": 0.22 * volume_scale,
		"phase": 0.0,
		"phase_alt": 0.0,
	}
	match event_name:
		"step":
			voice["duration"] = 0.055
			voice["freq_start"] = 145.0 + float(_crackle_seed % 25)
			voice["freq_end"] = 88.0
			voice["noise"] = 0.35
			voice["amp"] = 0.11 * volume_scale
		"jump":
			voice["duration"] = 0.16
			voice["freq_start"] = 210.0
			voice["freq_end"] = 420.0
			voice["freq_alt"] = 315.0
			voice["noise"] = 0.08
			voice["amp"] = 0.18 * volume_scale
		"land":
			voice["duration"] = 0.09
			voice["freq_start"] = 130.0
			voice["freq_end"] = 68.0
			voice["noise"] = 0.42
			voice["amp"] = 0.16 * volume_scale
		"dash":
			voice["duration"] = 0.22
			voice["freq_start"] = 520.0
			voice["freq_end"] = 180.0
			voice["freq_alt"] = 390.0
			voice["noise"] = 0.55
			voice["amp"] = 0.24 * volume_scale
		"flare":
			voice["duration"] = 0.52
			voice["freq_start"] = 440.0
			voice["freq_end"] = 880.0
			voice["freq_alt"] = 659.25
			voice["noise"] = 0.12
			voice["amp"] = 0.28 * volume_scale
		"platform_on":
			voice["duration"] = 0.24
			voice["freq_start"] = 330.0
			voice["freq_end"] = 493.88
			voice["freq_alt"] = 659.25
			voice["amp"] = 0.14 * volume_scale
		"platform_off":
			voice["duration"] = 0.20
			voice["freq_start"] = 392.0
			voice["freq_end"] = 261.63
			voice["amp"] = 0.10 * volume_scale
		"switch":
			voice["duration"] = 0.45
			voice["freq_start"] = 587.33
			voice["freq_end"] = 880.0
			voice["freq_alt"] = 1174.66
			voice["amp"] = 0.26 * volume_scale
		"gate":
			voice["duration"] = 0.48
			voice["freq_start"] = 110.0
			voice["freq_end"] = 164.81
			voice["freq_alt"] = 220.0
			voice["noise"] = 0.32
			voice["amp"] = 0.25 * volume_scale
		"checkpoint":
			voice["duration"] = 0.42
			voice["freq_start"] = 523.25
			voice["freq_end"] = 783.99
			voice["freq_alt"] = 659.25
			voice["amp"] = 0.25 * volume_scale
		"death":
			voice["duration"] = 0.34
			voice["freq_start"] = 293.66
			voice["freq_end"] = 110.0
			voice["noise"] = 0.38
			voice["amp"] = 0.24 * volume_scale
		"respawn":
			voice["duration"] = 0.36
			voice["freq_start"] = 261.63
			voice["freq_end"] = 523.25
			voice["freq_alt"] = 392.0
			voice["amp"] = 0.22 * volume_scale
		"complete":
			voice["duration"] = 0.65
			voice["freq_start"] = 440.0
			voice["freq_end"] = 880.0
			voice["freq_alt"] = 659.25
			voice["amp"] = 0.28 * volume_scale
	if _active_voices.size() >= 8:
		_active_voices.pop_front()
	_active_voices.append(voice)


func _process(_delta: float) -> void:
	if _headless_mode:
		return
	_fill_ambience_buffer()
	_fill_sfx_buffer()


func _fill_ambience_buffer() -> void:
	if _ambience_playback == null:
		return
	var frames := _ambience_playback.get_frames_available()
	if frames <= 0:
		return
	var roots := [110.0, 123.47, 130.81, 146.83, 164.81, 196.0]
	var root_freq: float = roots[clampi(_stage_mood, 0, roots.size() - 1)]
	var fifth_freq := root_freq * 1.498
	var octave_freq := root_freq * (2.5 if _is_finale_screen else 2.0)
	var inv_rate := 1.0 / MIX_RATE

	for _i in frames:
		_ambience_phase_a = fmod(_ambience_phase_a + root_freq * inv_rate, 1.0)
		_ambience_phase_b = fmod(_ambience_phase_b + fifth_freq * inv_rate, 1.0)
		_ambience_phase_c = fmod(_ambience_phase_c + octave_freq * inv_rate, 1.0)

		var pad := sin(_ambience_phase_a * TAU) * 0.45
		pad += sin(_ambience_phase_b * TAU) * 0.30
		pad += sin(_ambience_phase_c * TAU) * 0.18

		# Subtle warm lantern crackle
		_crackle_seed = (_crackle_seed * 1103515245 + 12345) & 0x7fffffff
		var rand_norm := (float(_crackle_seed % 10000) / 5000.0) - 1.0
		var crackle := rand_norm * 0.015 if (_crackle_seed % 97 == 0) else 0.0
		var sample := (pad * 0.16) + crackle
		_ambience_playback.push_frame(Vector2(sample, sample))


func _fill_sfx_buffer() -> void:
	if _sfx_playbacks.is_empty():
		return
	var playback := _sfx_playbacks[0]
	if playback == null:
		return
	var frames := playback.get_frames_available()
	if frames <= 0:
		return
	var inv_rate := 1.0 / MIX_RATE

	for _i in frames:
		var mixed := 0.0
		var idx := _active_voices.size() - 1
		while idx >= 0:
			var v: Dictionary = _active_voices[idx]
			var t: float = v["time"]
			var dur: float = v["duration"]
			if t >= dur:
				_active_voices.remove_at(idx)
				idx -= 1
				continue
			var progress := clampf(t / dur, 0.0, 1.0)
			var env := sin(progress * PI) * (1.0 - progress * 0.45)
			var freq := lerpf(float(v["freq_start"]), float(v["freq_end"]), progress)
			var phase := fmod(float(v["phase"]) + freq * inv_rate, 1.0)
			v["phase"] = phase
			var sig := sin(phase * TAU)
			var alt_freq := float(v["freq_alt"])
			if alt_freq > 0.0:
				var phase_alt := fmod(float(v["phase_alt"]) + alt_freq * inv_rate, 1.0)
				v["phase_alt"] = phase_alt
				sig = (sig * 0.65) + (sin(phase_alt * TAU) * 0.35)
			var noise_amt := float(v["noise"])
			if noise_amt > 0.0:
				_crackle_seed = (_crackle_seed * 1103515245 + 12345) & 0x7fffffff
				var n := (float(_crackle_seed % 10000) / 5000.0) - 1.0
				sig = lerpf(sig, n, noise_amt)
			mixed += sig * env * float(v["amp"])
			v["time"] = t + inv_rate
			idx -= 1
		mixed = clampf(mixed, -0.85, 0.85)
		playback.push_frame(Vector2(mixed, mixed))
