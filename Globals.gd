extends Node

var grid_size_x = 5
var grid_size_y = 5

var isDelay = false
var delay = 0.001

var comparing = false

signal enableSolveButtons
signal disableSolveButtons

signal currentMazeSolved(time)
signal secondMazeSolved(time)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
