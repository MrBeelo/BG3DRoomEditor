package main

import "core:fmt"
import rl "vendor:raylib"
import "core:strings"

SCREEN_SIZE :: rl.Vector2{1920, 1080}
format :: proc(str: string, args: ..any) -> string { return string(fmt.ctprintf(str, ..args)) }
to_string :: proc(value: any) -> string { return format("%v", value) }
string_pop :: proc(str: string) -> string { text, err := strings.substring(cmd_text, 0, strings.rune_count(cmd_text) - 1); return text }

main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT, .WINDOW_HIGHDPI, .MSAA_4X_HINT})
    rl.InitWindow(i32(SCREEN_SIZE.x), i32(SCREEN_SIZE.y), "BG3D Room Editor")
    defer rl.CloseWindow();
    rl.DisableCursor()
    rl.SetExitKey(.KEY_NULL)
    LoadResources()
    defer UnloadResources()
    LoadFont()
    defer UnloadFont()
        
    for !rl.WindowShouldClose() {
   		UpdateCamera()
     	UpdateCommandMenu()
      	UpdateSelectedBlocks()
      
        rl.BeginDrawing();
        defer rl.EndDrawing();
        rl.ClearBackground(rl.WHITE)
        
        rl.BeginMode3D(camera)
        rl.DrawGrid(500, 0.2)
        rl.DrawSphere({}, 0.03, rl.YELLOW)
        DrawBlocks()
        DrawSelectedBlocks()
        DrawEndPoint()
        rl.EndMode3D()
        
        DrawCross()
        DrawCommandMenu()
        
        DrawText("Press / to open command line!", {10, 10}, 48, 2, rl.LIGHTGRAY)
        DrawText("BB3D Room Editor v1.4", {10, 70}, 48, 2, rl.LIGHTGRAY)
        DrawText(string(format("CAMERA POS: [%.2f, %.2f, %.2f]", pos.x, pos.y, pos.z)), {10, 130}, 48, 2, rl.LIGHTGRAY)
        DrawText(string(format("ENDPOINT POS: [%.2f, %.2f, %.2f]", room.end_point.x, room.end_point.y, room.end_point.z)), {10, 190}, 48, 2, rl.LIGHTGRAY)
        DrawText(string(format("BLOCK COUNT: %d (SELECTED: %d)", len(room.blocks), len(GetSelectedBlocks()))), {10, 250}, 48, 2, rl.LIGHTGRAY)
        DrawSelectedBlockInfo()
    }
}
