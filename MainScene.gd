extends Node2D

var num = 0

var currentMaze

@onready var optionsButton = $CanvasLayer/UI/OptionButton
var solveMethod

const maze = preload("res://Maze.tscn")
@onready var mazeButton = $CanvasLayer/UI/GenerateMazeButton

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_generate_maze_button_pressed():
	mazeButton.disabled = true
	var newMaze = maze.instantiate()
	var children = get_children()
	for child in children:
		if child is Node2D and not child is Camera2D:
			child.queue_free()
	
	currentMaze = newMaze
	add_child(newMaze)
	mazeButton.disabled = false



func _on_h_slider_value_changed(value):
	Globals.grid_size_x = value
	Globals.grid_size_y = value
	$CanvasLayer/UI/SliderLabel.text = str(value)


func _on_solve_button_pressed():
	match solveMethod:
		0:
			currentMaze.get_node("TileMap").generate_astar_grid()
		1:
			currentMaze.get_node("TileMap").solve_bfs()
	
	#currentMaze.get_node("TileMap").generate_astar_grid()
	#currentMaze.get_node("TileMap").solve_bfs()


func _on_check_button_toggled(toggled_on):
	Globals.isDelay = toggled_on


func _on_option_button_item_selected(index):
	solveMethod = index
