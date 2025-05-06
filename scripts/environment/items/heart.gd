extends StaticBody2D

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		area.get_parent().heal(50)
	elif area.is_in_group("Tongue"):
		area.get_parent().get_parent().get_parent().heal(50)
	queue_free()
