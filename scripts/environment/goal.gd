extends StaticBody2D

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		MainMusic.stop()
		call_deferred("reload_scene")
		
func reload_scene():
	get_tree().change_scene_to_file("res://scenes/victory.tscn")
