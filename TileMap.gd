extends TileMap

# +--------------------+
# | Constant Variables |
# +--------------------+
const LAYER = 0
const SOURCE = 0
const PATH_ATLAS_COORDS = Vector2i(0, 0)
const WALL_ATLAS_COORDS = Vector2i(1, 0)
const SOLVED_ATLAS_COORDS = Vector2i(2, 0)

@export var x_size = 30
@export var y_size = 30
var start_coords = Vector2i(0, 0)

var path = []
var pathFound = false

var nodesSearched = 0

var isSecondMaze
var solving
var timer = 0

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
	if solving:
		timer += delta

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

# +----------------+
# | Maze Generator |
# +----------------+

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

# +------------------------------+
# | Astar Maze Solving Algorithm |
# +------------------------------+

func solve_astar(heuristic):
	
	if pathFound:
		resetMaze()
	
	solving = true
	
	# Initialize 2D Grid for Astar
	var astargrid = AStarGrid2D.new()
	astargrid.region = get_used_rect()
	astargrid.cell_size = Vector2i(64, 64)
	astargrid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astargrid.default_compute_heuristic = heuristic
	astargrid.update()
	
	# Overlay maze walls onto Astar grid
	var tiles = get_used_cells(LAYER)
	for tile in tiles:
		if is_wall(tile):
			astargrid.set_point_solid(tile)
	
	# Solve maze using Astar, return list of coordinates
	path = astargrid.get_id_path(Vector2i(start_coords.x, start_coords.y), Vector2i(x_size-1, y_size-1))
	
	for coord in path:
		place_solved_path(coord)
		await get_tree().create_timer(Globals.delay).timeout
	
	pathFound = true
	Globals.enableSolveButtons.emit()
	solving = false
	Globals.currentMazeSolved.emit(timer)
	timer = 0

# +--------------------------------------+
# | Breadth First Maze Solving Algorithm |
# +--------------------------------------+

func solve_bfs():
	
	# Reset maze if already solved
	if pathFound:
		resetMaze()
	
	solving = true
	
	# Create frontier and explored
	var frontier: Array[Vector2i] = [start_coords]
	var explored = []
	var solved = false
	
	while frontier.size() > 0 or not solved:
		var move = frontier.pop_front()
		
		if move == Vector2i(x_size-1, y_size-1):
			solved = true
			break
		
		for side in adjacent:
			var possible_move = move + side
			
			if possible_move not in explored and isValidMove(possible_move):
				frontier.append(possible_move)
				explored.append(possible_move)
				path.append(possible_move)
				place_solved_path(possible_move)
				await get_tree().create_timer(Globals.delay).timeout
				nodesSearched += 1
	
	pathFound = true
	
	# Solving complete, reenable buttons
	Globals.enableSolveButtons.emit()
	print("BFS Nodes Searched: " + str(nodesSearched))
	
	# Pause timer, send time info, reset timer
	solving = false
	if isSecondMaze:
		Globals.secondMazeSolved.emit(nodesSearched)
	else:
		Globals.currentMazeSolved.emit(nodesSearched)
	timer = 0

# Function to calculate Manhattan distance between two points
func manhattan_distance(start, end):
	return abs(start.x - end.x) + abs(start.y - end.y)

# Euclidean Distance
func euclidean_distance(start, end):
	var dx = end.x - start.x
	var dy = end.y - start.y
	return sqrt(dx * dx + dy * dy)

# Chebyshev Distance
func chebyshev_distance(start, end):
	return max(abs(start.x - end.x), abs(start.y - end.y))

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

# Octile Distance
func octile_distance(start, end):
	var dx = abs(start.x - end.x)
	var dy = abs(start.y - end.y)
	return sqrt(2) * min(dx, dy) + max(dx, dy) - min(dx, dy)

class anode:
	var parent
	var position = Vector2i(0, 0)
	
	var f = 0
	var g = 0
	var h = 0

# A* pathfinding function
func find_path(start_pos, end_pos, heuristic):
	
	if pathFound:
		print("resetting maze")
		resetMaze()
		
	var start_node = anode.new()
	var end_node = anode.new()
	
	var openList = []
	var closedList = []
	
	openList.append(start_node)
	
	while openList.size() > 0:
		var current_node = openList[0]
		var current_index = 0
		var index = 0
		
		for node in openList:
			if node.f < current_node.f:
				current_node = node
				current_index = index
			index += 1
		
		openList.pop_at(current_index)
		closedList.append(current_node)
		
		# if goal found
		if current_node == end_node:
			path = []
			var current = current_node
			while current != null:
				path.append(current.position)
				place_solved_path(current.position)
				current = current.parent
			path.reverse()
			return path
		
		var children = []
		for new_position in adjacent:
			print("current_node.position[0]: " + str(current_node.position[0]))
			print("new_position[0]: " + str(new_position[0]))
			print("current_node.position[1]: " + str(current_node.position[1]))
			print("new_position[1]: " + str(new_position[1]))
			var node_position = Vector2i(current_node.position[0] + new_position[0], current_node.position[1] + new_position[1])
			
			if not isValidMove(node_position):
				continue
			
			var new_node = anode.new()
			new_node.parent = current_node
			new_node.position = node_position
			
			children.append(new_node)
		
		for child in children:
			
			for closed_child in closedList:
				if child == closed_child:
					continue
			
			child.g = current_node.g + 1
			child.h = heuristic_calculation(child.position, end_node.position, "euclidian")
			child.f = child.g + child.h
			
			for open_node in openList:
				if child == open_node and child.g > open_node.g:
					continue
			
			openList.append(child)
