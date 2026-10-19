extends Control

func _ready() -> void:
	AudioManager.play_music(AudioManager.MUSIC.MAIN_THEME)

func _on_play_button_pressed() -> void:
	GameManager.go_to_game()
	AudioManager.play_music(AudioManager.MUSIC.GAME_TRACK)
	AudioManager.play_sound(AudioManager.SFX.UI_CONFIRM)


func _on_gallery_button_pressed() -> void:
	pass # Replace with function body.


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_option_button_pressed() -> void:
	pass # Replace with function body.
