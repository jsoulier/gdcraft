class_name GDCraftSky
extends Node

@export var sunrise_length = 30.0
@export var day_length = 60.0
@export var sunset_length = 30.0
@export var night_length = 60.0
@export var speed = 1.0
@export var night_sky_top: Color = Color(0.02, 0.02, 0.1)
@export var night_sky_horizon: Color = Color(0.05, 0.05, 0.2)
@export var sunrise_sky_top: Color = Color(0.5, 0.2, 0.1)
@export var sunrise_sky_horizon: Color = Color(1.0, 0.5, 0.2)
@export var day_sky_top: Color = Color(0.5, 0.7, 1.0)
@export var day_sky_horizon: Color = Color(0.8, 0.9, 1.0)
@export var sunset_sky_top: Color = Color(0.5, 0.2, 0.1)
@export var sunset_sky_horizon: Color = Color(1.0, 0.5, 0.2)
@export var night_ambient: Color = Color(0.05, 0.05, 0.1)
@export var day_ambient: Color = Color(1, 1, 1)
@onready var _sun = $Sun
@onready var _world_environment = $WorldEnvironment
@onready var _environment = _world_environment.environment
@onready var _sky = _environment.sky
@onready var _sky_material = _sky.sky_material
var _sunrise_end: float
var _day_end: float
var _sunset_end: float
var _night_end: float
var _total_length: float
var time_of_day: float

func _init() -> void:
	_total_length = sunrise_length + day_length + sunset_length + night_length
	_sunrise_end = sunrise_length / _total_length
	_day_end = _sunrise_end + day_length / _total_length
	_sunset_end = _day_end + sunset_length / _total_length
	_night_end = 1.0
	time_of_day = _sunrise_end + (_day_end - _sunrise_end) / 2.0

func _process(delta: float) -> void:
	time_of_day += delta * speed / _total_length
	time_of_day = fmod(time_of_day, 1.0)
	var sun_angle = time_of_day * TAU + PI / 2
	var sin_angle = sin(sun_angle - PI)
	_sun.rotation.x = sun_angle
	_sun.light_energy = clamp(sin_angle, 0.0, 1.0)
	_sun.shadow_enabled = sin_angle > 0.0
	var top_color: Color
	var horizon_color: Color
	var ambient_color: Color
	var t: float
	if time_of_day < _sunrise_end:
		t = time_of_day / _sunrise_end
		top_color = night_sky_top.lerp(sunrise_sky_top, t)
		horizon_color = night_sky_horizon.lerp(sunrise_sky_horizon, t)
		ambient_color = night_ambient.lerp(day_ambient, t)
	elif time_of_day < _day_end:
		t = (time_of_day - _sunrise_end) / (_day_end - _sunrise_end)
		top_color = sunrise_sky_top.lerp(day_sky_top, t)
		horizon_color = sunrise_sky_horizon.lerp(day_sky_horizon, t)
		ambient_color = day_ambient
	elif time_of_day < _sunset_end:
		t = (time_of_day - _day_end) / (_sunset_end - _day_end)
		top_color = day_sky_top.lerp(sunset_sky_top, t)
		horizon_color = day_sky_horizon.lerp(sunset_sky_horizon, t)
		ambient_color = day_ambient.lerp(night_ambient, t)
	else:
		t = (time_of_day - _sunset_end) / (_night_end - _sunset_end)
		top_color = sunset_sky_top.lerp(night_sky_top, t)
		horizon_color = sunset_sky_horizon.lerp(night_sky_horizon, t)
		ambient_color = night_ambient
	_environment.ambient_light_color = ambient_color
	_environment.ambient_light_energy = clamp(_sun.light_energy, 0.1, 1.0)
	_sky_material.sky_top_color = top_color
	_sky_material.sky_horizon_color = horizon_color
	_sky_material.ground_bottom_color = horizon_color
	_sky_material.ground_horizon_color = horizon_color
