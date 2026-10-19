extends Control
@onready var main_container: Panel = $MainContainer
@onready var video: VideoStreamPlayer = $VideoStreamPlayer
@onready var skip_btn: Button = $SkipBtn

func _ready() -> void:
	AudioManager.play_music(AudioManager.MUSIC.MAIN_THEME)

func _on_play_button_pressed() -> void:
	main_container.visible = false
	skip_btn.visible = true
	video.play()
	
	await video.finished

	GameManager.go_to_game()
	AudioManager.play_music(AudioManager.MUSIC.GAME_TRACK)
	AudioManager.play_sound(AudioManager.SFX.UI_CONFIRM)

	main_container.visible = true
	skip_btn.visible = false


func _on_gallery_button_pressed() -> void:
	pass # Replace with function body.


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_option_button_pressed() -> void:
	pass # Replace with function body.


func _on_skip_btn_pressed() -> void:
	video.stop()

	GameManager.go_to_game()
	AudioManager.play_music(AudioManager.MUSIC.GAME_TRACK)
	AudioManager.play_sound(AudioManager.SFX.UI_CONFIRM)

	main_container.visible = true
	skip_btn.visible = false

