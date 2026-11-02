extends Node
## Prozedurale Audio-Platzhalter: keine externen Samples oder Lizenzen.
## Spaeter durch CC0-Aufnahmen ersetzen, Klangzuordnung beibehalten.

const RATE := 22050
var _wind: AudioStreamPlayer
var _mower: AudioStreamPlayer
var _engine: AudioStreamPlayer

func _ready() -> void:
    _wind = _player(_make_clip("wind", 3.0, true), -32.0)
    _wind.play()
    _mower = _player(_make_clip("mower", 2.0, true), -31.0)
    _mower.play()
    _engine = _player(_make_clip("engine", 4.0, false), -17.0)

func set_mower_active(active: bool) -> void:
    if _mower != null:
        _mower.volume_db = -31.0 if active else -80.0

func engine_cue() -> void:
    if _engine != null:
        _engine.play()

func _player(stream: AudioStream, db: float) -> AudioStreamPlayer:
    var p := AudioStreamPlayer.new()
    p.stream = stream
    p.volume_db = db
    add_child(p)
    return p

func _make_clip(kind: String, seconds: float, looping: bool) -> AudioStreamWAV:
    var count := int(RATE * seconds)
    var samples := PackedByteArray()
    samples.resize(count * 2)
    var rng := RandomNumberGenerator.new()
    rng.seed = 180927
    var smooth_noise := 0.0
    for i in count:
        var t := float(i) / RATE
        var noise := rng.randf_range(-1.0, 1.0)
        smooth_noise = lerpf(smooth_noise, noise, 0.028)
        var value := 0.0
        match kind:
            "wind":
                value = smooth_noise * 0.5
            "mower":
                value = (sin(TAU * 73.0 * t) * 0.28 + sin(TAU * 146.0 * t) * 0.11 + smooth_noise * 0.1)
            "engine":
                var speed := 44.0 + minf(t, 2.0) * 22.0
                value = (sin(TAU * speed * t) * 0.27 + sin(TAU * speed * 2.0 * t) * 0.12 + smooth_noise * 0.12) * minf(1.0, t * 2.0)
        samples.encode_s16(i * 2, int(clampf(value, -0.95, 0.95) * 32767.0))
    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = RATE
    wav.stereo = false
    wav.data = samples
    if looping:
        wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
        wav.loop_end = count
    return wav
