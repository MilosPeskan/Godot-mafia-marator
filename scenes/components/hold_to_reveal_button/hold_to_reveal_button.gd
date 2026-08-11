extends Control

signal hold_started
signal hold_stopped

@export var hold_duration: float = 1.0   # sekunde potrebne da se otkrije

@onready var progress_ring: TextureProgressBar = $ProgressRing
@onready var press_area: Button = $ProgressRing/PressArea

var _holding := false
var _progress := 0.0

func _ready() -> void:
	press_area.button_down.connect(_on_press_start)
	press_area.button_up.connect(_on_press_release)
	progress_ring.value = 0

func _process(delta: float) -> void:
	if _holding:
		_progress += delta / hold_duration
		_progress = clamp(_progress, 0.0, 1.0)
		progress_ring.value = _progress * 100.0
	else:
		if _progress > 0.0:
			_progress -= delta / hold_duration
			_progress = clamp(_progress, 0.0, 1.0)
			progress_ring.value = _progress * 100.0

func _on_press_start() -> void:
	_holding = true
	hold_started.emit()

func _on_press_release() -> void:
	_holding = false
	hold_stopped.emit()
