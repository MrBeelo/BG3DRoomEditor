package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

SENSITIVITY: f32 : 0.003
SPEED: f32 : 3

camera: rl.Camera = {{0, 0.5, 0}, {1, 0.5, 1}, {0, 1, 0}, 60, .PERSPECTIVE}
pos: rl.Vector3 = {0, 0.5, 0}
dir: rl.Vector3 = {1, 0, 1}
yaw: f32 = 0
pitch: f32 = 0

UpdateCamera :: proc() {
	speed := rl.GetFrameTime() * SPEED * (2 if rl.IsKeyDown(.LEFT_SHIFT) else 1)
	yaw -= rl.GetMouseDelta().x * SENSITIVITY
	pitch = max(-1.57, min(1.57, pitch - rl.GetMouseDelta().y * SENSITIVITY))
	dir = {math.cos(pitch) * math.sin(yaw), math.sin(pitch), math.cos(pitch) * math.cos(yaw)}
	
	forward := f32(int(rl.IsKeyDown(.W)) - int(rl.IsKeyDown(.S)))
	sideward := f32(int(rl.IsKeyDown(.D)) - int(rl.IsKeyDown(.A)))
	upward := f32(int(rl.IsKeyDown(.SPACE)) - int(rl.IsKeyDown(.LEFT_CONTROL)))
	
	npos := pos
	npos += {(math.cos(pitch) * math.sin(yaw) * forward), (math.sin(pitch) * forward), (math.cos(pitch) * math.cos(yaw) * forward)} * speed // W / S
	npos += {(-math.cos(yaw) * sideward), upward, (math.sin(yaw) * sideward)} * speed // Other Buttons
	if(!cmd_menu_on) do pos = npos
	
	camera.position = pos
	camera.target = pos + dir
}

DrawCross :: proc() {
	LINE_SIZE :: 30
	DSCR_X :: SCREEN_SIZE.x / 2
	DSCR_Y :: SCREEN_SIZE.y / 2
	OFFSET_X :: DSCR_X - LINE_SIZE / 2
	OFFSET_Y :: DSCR_Y - LINE_SIZE / 2
	LINE_THICKNESS :: 2
	rl.DrawLineEx({OFFSET_X, DSCR_Y}, {SCREEN_SIZE.x - OFFSET_X, DSCR_Y}, LINE_THICKNESS, rl.BLACK)
	rl.DrawLineEx({DSCR_X, OFFSET_Y}, {DSCR_X, SCREEN_SIZE.y - OFFSET_Y}, LINE_THICKNESS, rl.BLACK)
}