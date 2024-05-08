extends Node

var grid_size_x = 5
var grid_size_y = 5

var isDelay = false
var stepToggle = false
var delay = 0.001

var comparing = false

signal enableSolveButtons
signal disableSolveButtons

signal currentMazeSolved(nodes)
signal secondMazeSolved(nodes)
signal thirdMazeSolved(nodes)

signal showStepButton
signal appendStepLabel
