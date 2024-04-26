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
	Globals.currentMazeSolved.emit(0)

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
		
		if move == end_coords:
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
	if isSecondMaze:
		Globals.secondMazeSolved.emit(nodesSearched)
	else:
		Globals.currentMazeSolved.emit(nodesSearched)

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

class Anode:
	var position = Vector2i(0, 0)
	
	var f = 0
	var g = 0
	var h = 0
	
	func _to_string():
		return "Position: " + str(position) + "\nf: " + str(f) + "\ng: " + str(g) + "\nh: " + str(h)

func better_astar(heuristic):
	
	var openList = [start_coords]
	var closedList = []
	var g = 0
	var f = INF
	
	var currentNode
	
	while not closedList.has(end_coords):
		
		
		for node in openList:
			if heuristic_calculation(node, end_coords, heuristic) > f:
				currentNode = node
		
		if end_coords in closedList.keys():
			print("we win yay")
			place_solved_path(currentNode)
			break
		
		
		
		pass


func find_lowest_f(list):
	var lowestF = INF
	var lowestNode
	for node in list:
		if node.f < lowestF:
			lowestF = node.f
			lowestNode = node
	return lowestNode

# A* pathfinding function
func find_path(heuristic):
	
	if pathFound:
		resetMaze()
	
	var openList = []
	var closedList = []
	
	var begin = Anode.new()
	begin.position = start_coords
	begin.g = 0
	begin.h = heuristic_calculation(start_coords, end_coords, heuristic)
	begin.f = begin.g + begin.h
	
	var end = Anode.new()
	end.position = end_coords
	
	openList.append(begin)
	
	while openList.size() > 0:
		
		#if openList.size() > 1:
			#print("=====\nmore than one option. openList: " + str(openList))
			#print("\nclosedList: " + str(closedList))
			#print("=====")
		
		var current_node = find_lowest_f(openList)
		
		var objectsToRemove = []
		for i in range(openList.size()):
			#print("current node's pos is " + str(current_node.position))
			if current_node.position == openList[i].position:
				#print("removing " + str(openList[i].position) + " from openList")
				openList.remove_at(i)
				break
		
		#print("\n current_node is: ")
		#print(current_node)
		#print("\n")
		
		nodesSearched += 1
		
		if current_node.position == end_coords:
			place_solved_path(current_node.position)
			print("we won :D")
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
			#print("appending " + str(possible_node.position) + " to openList")
			#print("fcost: " + str(possible_node.f))
			#print("current fcost: " + str(current_node.f))
		
		closedList.append(current_node)
		place_solved_path(current_node.position)
		path.append(current_node.position)
		await get_tree().create_timer(Globals.delay).timeout
	
	Globals.enableSolveButtons.emit()
	pathFound = true
	print("A* Nodes Searched: " + str(nodesSearched))
	

# =================================
