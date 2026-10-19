extends Node

const POOL_SIZE: int = 5

@onready var music_player: AudioStreamPlayer = $MusicStreamPlayer
@onready var effects_pool: Node = $EffectsPool

var sfx_players: Array[AudioStreamPlayer] = []

#TODO: AQUI SE AGREGAN LAS REFERENCIAS A LOS AUDIOS (KEYNAME)
enum SFX {
	UI_HOVER,
	UI_CONFIRM,
	UI_BACK,
	Cortando_Cebolla,
	Cortar_Yuca,
	Deshilachar,
	Exprimir_Limon,
	Encebollado_Basura
}

enum MUSIC {
	MAIN_THEME
}

@export var SFX_DIC: Dictionary[SFX, AudioSetting]
@export var MUSIC_DIC: Dictionary[MUSIC, AudioSetting]

func _ready() -> void:
	for i in range(0, POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		effects_pool.add_child(player)
		sfx_players.append(player)
	
func play_sound(sfx: SFX) -> void:
	var player: AudioStreamPlayer = get_next_sfx_player()
	var setting: AudioSetting = SFX_DIC.get(sfx)
	if not setting:
		return

	player.stream = setting.source
	player.volume_db = setting.volume_db
	player.pitch_scale = get_random_pitch(setting.pitch_randomness)
	player.bus = "SFX"
	player.play()


func get_next_sfx_player() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in sfx_players:
		if not player.playing:
			return player
	
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.set_meta("temp", true)
	player.finished.connect(on_player_finished.bind(player))
	
	effects_pool.add_child(player)
	return player
	
func on_player_finished(player: AudioStreamPlayer) -> void:
	if player.has_meta("temp"):
		player.queue_free()
	
func get_random_pitch(randomness: float) -> float:
	if randomness == 0:
		return 1.0
	
	return randf_range(1.0 - randomness, 1.0 + randomness)

func play_music(music: MUSIC) -> void:
	var setting: AudioSetting = MUSIC_DIC.get(music)
	if not setting:
		return

	music_player.stream = setting.source
	music_player.volume_db = setting.volume_db
	music_player.bus = "MUSIC"
	music_player.play()
