extends Node2D

const maze = preload("res://Maze.tscn")
@onready var mazeButton = $CanvasLayer/UI/GenerateMazeButton

# Solver Buttons
@onready var solveButton = $CanvasLayer/UI/ColorRect/HBoxContainer/SolveButton
@onready var optionsButton = $CanvasLayer/UI/ColorRect/HBoxContainer/OptionButton
@onready var heuristicsLabel = $CanvasLayer/UI/HeuristicLabel
@onready var heuristicsOptionsButton = $CanvasLayer/UI/HeuristicOptionButton

var currentMaze
var secondMaze
var solveMethod = 0
var heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN

# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.enableSolveButtons.connect(enable_solve_buttons)
	Globals.disableSolveButtons.connect(disable_solve_buttons)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_generate_maze_button_pressed():
	
	optionsButton.selected = 0
	#show_heuristics()
	
	Globals.comparing = false
	
	mazeButton.disabled = true
	solveButton.disabled = true
	optionsButton.disabled = true
	
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
	$CanvasLayer/UI/ColorRect2/SliderLabel.text = str(value)

func _on_solve_button_pressed():
	disable_solve_buttons()
	
	if solveMethod == 2:
		
		Globals.comparing = true
		currentMaze.get_node("TileMap").solve_astar(heuristic)
		secondMaze.get_node("TileMap").solve_bfs()

	else:
		Globals.comparing = false
		match solveMethod:
			0:
				currentMaze.get_node("TileMap").solve_astar(heuristic)
			1:
				currentMaze.get_node("TileMap").solve_bfs()

func enable_solve_buttons():
	solveButton.disabled = false
	optionsButton.disabled = false
	heuristicsOptionsButton.disabled = false

func disable_solve_buttons():
	solveButton.disabled = true
	optionsButton.disabled = true
	heuristicsOptionsButton.disabled = true

func show_heuristics():
	heuristicsLabel.visible = true
	heuristicsOptionsButton.visible = true

func hide_heuristics():
	heuristicsLabel.visible = false
	heuristicsOptionsButton.visible = false

func _on_check_button_toggled(toggled_on):
	Globals.isDelay = toggled_on

func _on_option_button_item_selected(index):
	solveMethod = index
	
	if index == 2:
		
		#show_heuristics()
		Globals.comparing = true
		
		secondMaze = currentMaze.duplicate()
		secondMaze.get_node("TileMap").isSecondMaze = true
		add_child(secondMaze)
		
		var currentTilemap = currentMaze.get_node("TileMap")
		var secondTilemap = secondMaze.get_node("TileMap")
		var tiles = currentTilemap.get_used_cells(0)
		secondTilemap.clear()
		
		for tile in tiles:
			if currentTilemap.is_wall(tile):
				secondTilemap.create_wall(tile)
			else:
				secondTilemap.create_path(tile)
		
		secondMaze.position += Vector2((currentMaze.get_node("TileMap").x_size+5)*64, 0)
		
		var firstLabel = currentMaze.get_node("TileMap").get_node("Label")
		firstLabel.text = "A*"
		firstLabel.label_settings.font_size = Globals.grid_size_x * 20
		firstLabel.visible = true
		
		var secondLabel = secondMaze.get_node("TileMap").get_node("Label")
		secondLabel.text = "BFS"
		secondLabel.label_settings.font_size = Globals.grid_size_x * 20
		secondLabel.visible = true
	elif index == 1:
		currentMaze.get_node("TileMap").get_node("Label").visible = false
		#hide_heuristics()
		Globals.comparing = false
		if is_instance_valid(secondMaze):
			secondMaze.queue_free()
	else:
		currentMaze.get_node("TileMap").get_node("Label").visible = false
		#show_heuristics()
		Globals.comparing = false
		if is_instance_valid(secondMaze):
			secondMaze.queue_free()

func _on_heuristic_option_button_item_selected(index):
	match index:
		0:
			heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
		1:
			heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
		2:
			heuristic = AStarGrid2D.HEURISTIC_OCTILE
		3:
			heuristic = AStarGrid2D.HEURISTIC_CHEBYSHEV
