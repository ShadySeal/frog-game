extends ProgressBar

func set_health_bar(health):
	max_value = health
	value = health
	
func change_health(new_value):
	value = new_value
