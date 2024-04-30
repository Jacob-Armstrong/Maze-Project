extends Node2D

# Maze scene and button references
const maze = preload("res://Maze.tscn")
@onready var mazeButton = $CanvasLayer/UI/GenerateMazeButton

# Solve button references
@onready var solveButton = $CanvasLayer/UI/ColorRect/HBoxContainer/SolveButton
@onready var optionsButton = $CanvasLayer/UI/ColorRect/HBoxContainer/OptionButton
@onready var heuristicsLabel = $CanvasLayer/UI/HeuristicLabel
@onready var heuristicsOptionsButton = $CanvasLayer/UI/HeuristicOptionButton

# Stepthrough behavior references
@onready var stepToggle = $CanvasLayer/UI/StepToggle
@onready var stepButton = $CanvasLayer/UI/StepButton
@onready var stepLabel = $CanvasLayer/UI/StepLabel

# "Nodes searched" label references
@onready var nodeDisplay = $CanvasLayer/UI/NodeDisplay1
@onready var nodeDisplay2 = $CanvasLayer/UI/NodeDisplay2

# Maze references
var currentMaze
var secondMaze

# Default values
var solveMethod = 0
var solveType = "Astar"
var heuristic = "euclidian"

# +------------------------+
# | Godot Script Functions |
# +------------------------+

# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.enableSolveButtons.connect(enable_solve_buttons)
	Globals.disableSolveButtons.connect(disable_solve_buttons)
	Globals.currentMazeSolved.connect(current_nodes_searched)
	Globals.secondMazeSolved.connect(second_nodes_searched)
	Globals.showStepButton.connect(show_step_button)
	Globals.appendStepLabel.connect(append_step_label)

# +-----------------------+
# | UI Signal Connections |
# +-----------------------+

func _on_generate_maze_button_pressed():
	
	# Reset button/camera states
	optionsButton.selected = 0
	solveMethod = 0
	Globals.comparing = false
	disable_solve_buttons()
	hide_displays()
	show_heuristics()
	stepButton.visible = false 
	
	# Create a new maze and remove all others
	var newMaze = maze.instantiate()
	var children = get_children()
	for child in children:
		if child is Node2D and not child is Camera2D:
			child.queue_free()
	
	# Point reference to maze, add maze to tree
	currentMaze = newMaze
	add_child(newMaze)
	mazeButton.disabled = false

func _on_h_slider_value_changed(value):
	Globals.grid_size_x = value
	Globals.grid_size_y = value
	$CanvasLayer/UI/ColorRect2/SliderLabel.text = str(value)

func _on_solve_button_pressed():
	disable_solve_buttons()
	hide_displays()
	
	# Algorithm dropdown selection
	match solveMethod:
		0: # Astar
			currentMaze.get_node("TileMap").solve_astar(heuristic)
			solveType = "A*"
		1: # Breadth First Search
			currentMaze.get_node("TileMap").solve_bfs()
			solveType = "BFS"
		2: # Compare both algorithms
			Globals.comparing = true
			solveType = "A*"
			currentMaze.get_node("TileMap").solve_astar(heuristic)
			secondMaze.get_node("TileMap").solve_bfs()

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
	stepToggle.visible = true

func hide_heuristics():
	heuristicsLabel.visible = false
	heuristicsOptionsButton.visible = false
	stepToggle.visible = false

func _on_check_button_toggled(toggled_on):
	Globals.isDelay = toggled_on

func _on_step_toggle_toggled(toggled_on):
	Globals.stepToggle = toggled_on

func show_step_button():
	stepButton.visible = true

func _on_step_button_pressed():
	Engine.time_scale = 1
	stepButton.visible = false
	stepLabel.text = ""

func append_step_label(text):
	stepLabel.text += text + "\n\n"

func _on_option_button_item_selected(index):
	solveMethod = index
	hide_displays()
	
	currentMaze.get_node("TileMap").resetMaze()
	
	# Algorithm dropdown selection
	match solveMethod:
		0, 1: # Astar or Breadth First Search
			
			# Hide labels, only using one algorithm
			currentMaze.get_node("TileMap").get_node("Label").visible = false
			if solveMethod == 0:
				show_heuristics()
			else:
				hide_heuristics()
			Globals.comparing = false
			if is_instance_valid(secondMaze):
				secondMaze.queue_free()
		
		2: # Compare both algorithms
			show_heuristics()
			Globals.comparing = true
			
			# Duplicate current maze, tell it not to generate, and add to tree
			secondMaze = currentMaze.duplicate()
			secondMaze.get_node("TileMap").isSecondMaze = true
			secondMaze.get_node("TileMap").path = currentMaze.get_node("TileMap").path # Duplicate() is broken >:(
			add_child(secondMaze)
			
			# Reposition second maze to the right
			secondMaze.position += Vector2((currentMaze.get_node("TileMap").x_size+5)*64, 0)
			
			# Label mazes
			var firstLabel = currentMaze.get_node("TileMap").get_node("Label")
			firstLabel.text = "A*"
			firstLabel.label_settings.font_size = Globals.grid_size_x * 20
			firstLabel.visible = true
			
			var secondLabel = secondMaze.get_node("TileMap").get_node("Label")
			secondLabel.text = "BFS"
			secondLabel.label_settings.font_size = Globals.grid_size_x * 20
			secondLabel.visible = true

func _on_heuristic_option_button_item_selected(index):
	match index:
		0:
			heuristic = "euclidian"
		1:
			heuristic = "manhattan"
		2:
			heuristic = "octile"
		3:
			heuristic = "chebyshev"

# +-------------------------------------+
# | "Nodes Searched" Signal Connections |
# +-------------------------------------+

func hide_displays():
	nodeDisplay.visible = false
	nodeDisplay2.visible = false

func current_nodes_searched(nodes):
	if solveType == "A*":
		nodeDisplay.text = heuristic.capitalize() + " A* Nodes Searched: " + str(nodes)
	else:
		nodeDisplay.text = "BFS Nodes Searched: " + str(nodes)
	nodeDisplay.visible = true

func second_nodes_searched(nodes):
	nodeDisplay2.text = "BFS Nodes Searched: " + str(nodes)
	nodeDisplay2.visible = true
