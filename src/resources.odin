package main

import "core:fmt"
import rl "vendor:raylib"
import "core:strings"

block_texture: rl.Texture2D
block_mesh: rl.Mesh
block_model: rl.Model

LoadEmbeddedTexture :: proc($name: string, $extension: string) -> rl.Texture2D {
	data := #load("../res/" + name + extension)
	image := rl.LoadImageFromMemory(strings.clone_to_cstring(extension), &data[0], i32(len(data)))
	texture := rl.LoadTextureFromImage(image)
	rl.UnloadImage(image)
	return texture
}

LoadEmbeddedFont :: proc($name: string, $extension: string) -> rl.Font {
	data := #load("../res/" + name + extension)
	font := rl.LoadFontFromMemory(strings.clone_to_cstring(extension), &data[0], i32(len(data)), 100, nil, 0)
	return font
}

LoadResources :: proc() {
	block_texture = LoadEmbeddedTexture("blockdef", ".png")
	block_mesh = rl.GenMeshCube(1, 1, 1)
	block_model = rl.LoadModelFromMesh(block_mesh)
	block_model.materials[0].maps[0].texture = block_texture
}

UnloadResources :: proc() {
	rl.UnloadModel(block_model)
}