package main

import "core:strings"
import rl "vendor:raylib"

changa_one: rl.Font

LoadFont :: proc() {
	changa_one = LoadEmbeddedFont("fontdef", ".ttf")
}

UnloadFont :: proc() {
	rl.UnloadFont(changa_one)
}

DrawText :: proc(text: string, pos: rl.Vector2, font_size: f32, font_spacing: f32 = 5, color := rl.WHITE) {
	rl.DrawTextEx(changa_one, strings.clone_to_cstring(text), pos, font_size, font_spacing, color)
}

MeasureText :: proc(text: string, font_size: f32, font_spacing: f32 = 5) -> rl.Vector2 {
	return rl.MeasureTextEx(changa_one, strings.clone_to_cstring(text), font_size, font_spacing)
}