extends TileMap

@onready var labelPreset = preload("res://LabelPreset.tscn")

# +--------------------+
# | Constant Variables |
# +--------------------+
const LAYER = 0
const SOURCE = 0
const PATH_ATLAS_COORDS = Vector2i(0, 0)
const WALL_ATLAS_COORDS = Vector2i(1, 0)
const SOLVED_ATLAS_COORDS = Vector2i(2, 0)
const FINAL_PATH_ATLAS_COORDS = Vector2i(3, 0)
const STEP_ATLAS_COORDS = Vector2i(4, 0)

@export var x_size = 30
@export var y_size = 30
var start_coords = Vector2i(0, 0)
var end_coords = Vector2i(Globals.grid_size_x-1, Globals.grid_size_y-1)

var path = []
var pathFound = false

var nodesSearched = 0

var isSecondMaze

# Array of cardinal directions
var adjacent = [
	Vector2i(-1, 0), # Left
	Vector2i(1, 0), # Right
	Vector2i(0, 1), # Down
	Vector2i(0, -1) # Up
]

func _ready():
	y_size = Globals.grid_size_x
	x_size = Globals.grid_size_y
	
	if not isSecondMaze:
		create_global_border()
		generate_maze()
	else:
		resetMaze()

func _process(delta):
	pass

# +---------------------------+
# | Maze Generation Functions |
# +---------------------------+

# Add wall tile to specified coordinates
func create_wall(coords: Vector2):
	set_cell(LAYER, coords, SOURCE, WALL_ATLAS_COORDS)

# Add path tile to specified coordinates
func create_path(coords: Vector2):
	set_cell(LAYER, coords, SOURCE, PATH_ATLAS_COORDS)

# Add red "solved" tile to specified coordinates
func place_solved_path(coords):
	set_cell(LAYER, coords, SOURCE, SOLVED_ATLAS_COORDS)

func place_final_path(coords):
	set_cell(LAYER, coords, SOURCE, FINAL_PATH_ATLAS_COORDS)
	
func place_step_options(coords):
	set_cell(LAYER, coords, SOURCE, STEP_ATLAS_COORDS)

# Return true if tile is wall
func is_wall(coords: Vector2): 
	return get_cell_atlas_coords(LAYER, coords) == WALL_ATLAS_COORDS

# Return true if tile is even
func isWallCoord(coords: Vector2i):
	return (coords.x % 2 == 1 and coords.y % 2 == 1)

# Move is in bounds and not a wall
func isValidMove(coords: Vector2): 
	return (coords.x >= 0 and coords.y >= 0 and coords.x < x_size and coords.y < y_size and not is_wall(coords))

# Reset maze if already solved
func resetMaze():
	for coord in path:
		create_path(coord)
	path = []
	nodesSearched = 0

# Create border around maze
func create_global_border():
	for y in range(-1, y_size): # Left border
		create_wall(Vector2(-1, y))
	for y in range(-1, y_size + 1): # Right Border
		create_wall(Vector2i(x_size, y))
	for x in range(-1, x_size): # Top border
		create_wall(Vector2i(x, -1))
	for x in range(-1, x_size + 1): # Bottom Border
		create_wall(Vector2i(x, y_size))

# +---------------------------------------+
# | Recursive Backtracking Maze Generator |
# +---------------------------------------+

func generate_maze():
	var frontier: Array[Vector2i] = [start_coords]
	var explored = {}
	
	while frontier.size() > 0:
		var move = frontier.pop_back()
		explored[move] = true
		
		if move in explored or not isValidMove(move):
			if Globals.isDelay:
				await get_tree().create_timer(Globals.delay).timeout
		
		# Create walls in grid pattern while exploring
		if isWallCoord(move):
			create_wall(move)
		
		var valid_path = false
		adjacent.shuffle()
		for side in adjacent:
			var possible_move = move + side
			
			if possible_move not in explored and isValidMove(possible_move):
				if isWallCoord(possible_move):
					create_wall(possible_move)
				else:
					valid_path = true
					frontier.append(possible_move)
		
		if not valid_path:
			create_wall(move)
		else:
			create_path(move)
	
	# Generation done. Reenable buttons.
	Globals.enableSolveButtons.emit()

# +---------------------------------------+
# | Astar Calculation Functions & Classes |
# +---------------------------------------+

# Euclidean Distance
func euclidean_distance(start, end):
	var dx = end.x - start.x
	var dy = end.y - start.y
	return sqrt(dx * dx + dy * dy)

# Manhattan Distance
func manhattan_distance(start, end):
	return abs(start.x - end.x) + abs(start.y - end.y)

# Chebyshev Distance
func chebyshev_distance(start, end):
	return max(abs(start.x - end.x), abs(start.y - end.y))

# Octile Distance
func octile_distance(start, end):
	var dx = abs(start.x - end.x)
	var dy = abs(start.y - end.y)
	return sqrt(2) * min(dx, dy) + max(dx, dy) - min(dx, dy)

# Switch based on chosen heuristic
func heuristic_calculation(start, end, heuristic):
	match heuristic:
		"euclidian":
			return euclidean_distance(start, end)
		"manhattan":
			return manhattan_distance(start, end)
		"octile":
			return octile_distance(start, end)
		"chebyshev":
			return chebyshev_distance(start, end)

# Node class for Astar calculations
class Anode:
	var position = Vector2i(0, 0)
	
	# Number of moves it took to get to this node
	var g = 0
	
	# Heuristic calculation
	var h = 0
	
	# Total score (g + h)
	var f = 0
	
	# Debug to_string() override
	func _to_string():
		return "Position: " + str(position) + "\nf: " + str(f) + "\ng: " + str(g) + "\nh: " + str(h)

# +-------------------------------------+
# | Custom Astar Maze Solving Algorithm |
# +-------------------------------------+

# Return node with lowest F value from given list
func find_lowest_f(list):
	var lowestF = INF
	var lowestNode
	for node in list:
		if node.f < lowestF:
			lowestF = node.f
			lowestNode = node
	return lowestNode

# A* pathfinding function
func solve_astar(heuristic):
	
	if pathFound:
		resetMaze()
	
	var openList = []
	var closedList = []
	
	# Create node for starting coords
	var begin = Anode.new()
	begin.position = start_coords
	begin.g = 0
	begin.h = heuristic_calculation(start_coords, end_coords, heuristic)
	begin.f = begin.g + begin.h
	
	var end = Anode.new()
	end.position = end_coords
	
	# Add starting coords to open list
	openList.append(begin)
	
	while openList.size() > 0:
		
		var current_node = find_lowest_f(openList)
		
		# Remove node from open list
		for i in range(openList.size()):
			if current_node.position == openList[i].position:
				openList.remove_at(i)
				break
		
		# End of maze found
		if current_node.position == end_coords:
			place_solved_path(current_node.position)
			path.append(current_node.position)
			nodesSearched += 1
			break
		
		for side in adjacent:
			var possible_node = Anode.new()
			possible_node.position = current_node.position + side
			
			# Node is already in the open list
			var inOpen = false
			for node in openList:
				if node.position == possible_node.position:
					inOpen = true
			if inOpen: continue
			
			# Node is in closed list
			var inClosed = false
			for node in closedList:
				if node.position == possible_node.position:
					inClosed = true
			if inClosed: continue
			
			# Don't explore, just a wall
			if not isValidMove(possible_node.position):
				continue
			
			possible_node.g = current_node.g + 1
			possible_node.h = heuristic_calculation(possible_node.position, end_coords, heuristic)
			possible_node.f = possible_node.g + possible_node.h
			
			openList.append(possible_node)
		
		var children = get_children()
		for child in children:
			if child is Node2D:
				child.queue_free()
		
		# Stepthrough information
		if openList.size() > 1 and Globals.stepToggle:
			
			var optionNum = 1
			var folder = Node2D.new()
			add_child(folder)
				
			for node in openList:
				place_step_options(node.position)
				var label = labelPreset.instantiate()
				folder.add_child(label)
				label.position = map_to_local(node.position) - Vector2(15, 30)
				label.text = str(optionNum)
				Globals.appendStepLabel.emit("Option " + str(optionNum) + ": \n" + str(node))
				optionNum += 1
				
			Engine.time_scale = 0
			Globals.showStepButton.emit()
		
		# Searching node...
		closedList.append(current_node)
		nodesSearched += 1
		place_solved_path(current_node.position)
		path.append(current_node.position)
		await get_tree().create_timer(Globals.delay).timeout
	
	Globals.enableSolveButtons.emit()
	Globals.currentMazeSolved.emit(nodesSearched)
	pathFound = true
	retrace_path()

# +--------------------------------------+
# | Breadth First Maze Solving Algorithm |
# +--------------------------------------+

func solve_bfs():
	
	# Reset maze if already solved
	if pathFound:
		resetMaze()
	
	# Create frontier and explored
	var frontier: Array[Vector2i] = [start_coords]
	var explored = []
	var solved = false
	
	while frontier.size() > 0 or not solved:
		
		var move = frontier.pop_front()
		
		# End of maze found
		if move == end_coords:
			solved = true
			break
		
		# Check each direction (NSEW)
		for side in adjacent:
			var possible_move = move + side
			
			if possible_move not in explored and isValidMove(possible_move):
				
				# Add to frontier AND explored
				frontier.append(possible_move)
				explored.append(possible_move)
				
				# Visualizer implementations
				path.append(possible_move)
				place_solved_path(possible_move)
				await get_tree().create_timer(Globals.delay).timeout
				nodesSearched += 1
	
	pathFound = true
	retrace_path()
	
	# Solving complete, reenable buttons
	Globals.enableSolveButtons.emit()
	
	# Display # of nodes solved
	if isSecondMaze:
		Globals.secondMazeSolved.emit(nodesSearched)
	else:
		Globals.currentMazeSolved.emit(nodesSearched)

# +----------------------------+
# | Godot Astar Implementation |
# +----------------------------+

func retrace_path():
	# Initialize 2D Grid for Astar
	var astargrid = AStarGrid2D.new()
	astargrid.region = get_used_rect()
	astargrid.cell_size = Vector2i(64, 64)
	astargrid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astargrid.update()
	
	# Overlay maze walls onto Astar grid
	var tiles = get_used_cells(LAYER)
	for tile in tiles:
		if is_wall(tile):
			astargrid.set_point_solid(tile)
	
	var retracepath = astargrid.get_id_path(Vector2i(start_coords.x, start_coords.y), Vector2i(x_size-1, y_size-1))
	
	for coord in retracepath:
		place_final_path(coord)
		await get_tree().create_timer(Globals.delay).timeout
	
	Globals.enableSolveButtons.emit()
