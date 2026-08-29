extends Node
## Autoload singleton: res://Scripts/AudioManager.gd -> "AudioManager"
##
## Same idea as the old Unity BuildAutomation auto-wiring: drop audio files
## into Assets/Audio/<keyword>/ and they get picked up automatically, no
## manual node wiring needed. Supported keyword folders:
## footstep, jump, slide, death, growl, coin, gameover, victory, jungle, home
##
## jungle/home are treated as looping background music; everything else
## is a one-shot SFX (random file if multiple are in the folder).

const AUDIO_ROOT := "res://Assets/Audio/"
const KEYWORDS: Array[String] = ["footstep", "jump", "slide", "death", "growl", "coin", "gameover", "victory", "jungle", "home"]
const MUSIC_KEYWORDS: Array[String] = ["jungle", "home"]

var _sfx_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _library: Dictionary = {}  # keyword -> Array[String] of resource paths

func _ready() -> void:
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "Master"
	add_child(_sfx_player)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	add_child(_music_player)

	_scan_library()

func _scan_library() -> void:
	for keyword in KEYWORDS:
		_library[keyword] = []
		var dir_path := AUDIO_ROOT + keyword + "/"
		var dir := DirAccess.open(dir_path)
		if dir == null:
			continue
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and (file_name.ends_with(".ogg") or file_name.ends_with(".wav") or file_name.ends_with(".mp3")):
				_library[keyword].append(dir_path + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()

func play_sfx(keyword: String) -> void:
	if not _library.has(keyword) or _library[keyword].is_empty():
		return
	var path: String = _library[keyword][randi() % _library[keyword].size()]
	var stream: AudioStream = load(path)
	if stream:
		_sfx_player.stream = stream
		_sfx_player.play()

func play_music(keyword: String) -> void:
	if not _library.has(keyword) or _library[keyword].is_empty():
		return
	var path: String = _library[keyword][randi() % _library[keyword].size()]
	var stream: AudioStream = load(path)
	if stream:
		if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
			stream.loop = true
		_music_player.stream = stream
		_music_player.play()

func stop_music() -> void:
	_music_player.stop()
