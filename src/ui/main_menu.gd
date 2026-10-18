extends Control

func _on_play_button_pressed() -> void:
	GameManager.go_to_game()
	AudioManager.play_sound(AudioManager.SFX.UI_CONFIRM)


func _on_gallery_button_pressed() -> void:
	pass # Replace with function body.


func _on_exit_button_pressed() -> void:
	get_tree().quit()
