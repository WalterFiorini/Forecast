extends Node3D

var weather_data = {}
var rain_effect_instance: GPUParticles3D = null  # Declare the variable to hold the rain effect instance

func _ready():
	# Remove any existing rain effect at the start
	remove_rain_effect()

func fetch_weather_data(city: String):
	var api_key = "0ce76044de89376be9bb79692006fa37"  # Replace with your actual API key
	var url = "https://api.openweathermap.org/data/2.5/weather?q=" + city + "&appid=" + api_key + "&units=metric"
	var http_request = $WeatherRequest  # Reference the HTTPRequest node

	# Ensure signal is connected only once
	http_request.disconnect("request_completed", Callable(self, "_on_request_completed"))
	http_request.connect("request_completed", Callable(self, "_on_request_completed"))

	var error = http_request.request(url)
	if error != OK:
		print("Error requesting weather data")
		return

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.new()
		var body_as_string = body.get_string_from_utf8()
		var parse_result = json.parse(body_as_string)
		
		if parse_result == OK:
			weather_data = json.get_data()
			update_weather_display()

			# Check for rain data
			var is_raining = false  # Flag to check if it's raining
			if weather_data.has("weather"):
				for weather in weather_data["weather"]:
					if weather.has("main") and weather["main"] == "Rain":
						print("It's raining!")
						is_raining = true
						break
			else:
				print("No rain data available.")

			# Add or remove rain effect based on weather condition
			if is_raining:
				add_rain_effect()
			else:
				remove_rain_effect()  # Ensure to remove if it's not raining
		else:
			print("Error parsing weather data")
	else:
		print("Error fetching weather data: ", response_code)

func add_rain_effect():
	# Remove existing rain effect if present
	remove_rain_effect()

	# Instantiate and add the rain effect
	rain_effect_instance = preload("res://Assets/rain_effect.tscn").instantiate()  # Ensure the path is correct
	add_child(rain_effect_instance)  # Add the rain effect to the scene
	rain_effect_instance.get_node("GPUParticles3D").emitting = true  # Start emitting particles

func remove_rain_effect():
	if rain_effect_instance != null:
		rain_effect_instance.queue_free()  # Remove the existing rain effect
		rain_effect_instance = null  # Reset the reference

func update_weather_display():
	if weather_data.has("main"):
		var temp = weather_data["main"]["temp"]
		$CanvasLayer/Panel/WeatherLabel.text = "Temperature: " + str(temp) + "°C"
	else:
		$CanvasLayer/Panel/WeatherLabel.text = "No data available."

func on_button_pressed():
	var city = $CanvasLayer/Panel/CityInput.text  # Update this path to your LineEdit
	fetch_weather_data(city)
