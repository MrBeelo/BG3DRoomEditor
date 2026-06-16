package main

import "core:math"
import rl "vendor:raylib"

room: Room

BlockType :: enum { WALL, TRIGGER }
Block :: struct { pos: rl.Vector3, rot: rl.Vector3, size: rl.Vector3, type: BlockType, selected: bool }
Room :: struct { blocks: [dynamic]Block, end_point: rl.Vector3 }

NewBlock :: proc(pos: rl.Vector3, rot: rl.Vector3 = {}, size: rl.Vector3, type := BlockType.WALL) -> Block { return Block{pos, rot, size, type, false} }
AppendBlock :: proc(pos: rl.Vector3 = {}, rot: rl.Vector3 = {}, size: rl.Vector3 = {1, 1, 1}, type := BlockType.WALL) { 
	append(&room.blocks, NewBlock(pos, rot, size, type)) }
DrawBlocks :: proc() { for block in room.blocks do DrawBlock(block) }
GetBlockOpacity :: proc(block: Block) -> u8 { return 255 if(block.type == .WALL) else 150 }

//DrawBlock :: proc(block: Block) { rl.DrawModelEx(block_model, block.pos, {}, 0, block.scale, {190, 253, 255, GetBlockOpacity(block)} if(block.selected) else {255, 255, 255, GetBlockOpacity(block)}) }
DrawBlock :: proc(block: Block) {
	DrawModelPro(&block_model, block.pos, rot_rad(block.rot), block.size, {190, 253, 255, GetBlockOpacity(block)} if(block.selected) else {255, 255, 255, GetBlockOpacity(block)})
}

GetSelectedBlocks :: proc() -> [dynamic]^Block {
	selected_blocks: [dynamic]^Block
	for &block in room.blocks do if block.selected do append(&selected_blocks, &block)
	return selected_blocks
}

UpdateSelectedBlocks :: proc() {
	ray := rl.GetScreenToWorldRay({SCREEN_SIZE.x / 2, SCREEN_SIZE.y / 2}, camera)
	closest_dist := f32(21)
	closest_block_index := int(-1) 
	
	#reverse for &block, index in room.blocks {
		if(block.selected && rl.IsKeyPressed(.DELETE)) do unordered_remove(&room.blocks, index)
		box := GetCubeOBB(block.pos, block.rot, block.size)
		coll := GetRayCollisionOBB(ray, box)
		if(coll.hit && coll.distance < closest_dist) { 
			closest_dist = coll.distance
			closest_block_index = index
		}
	}
	
	if(rl.IsMouseButtonPressed(.LEFT) && closest_block_index >= 0) do room.blocks[closest_block_index].selected = !room.blocks[closest_block_index].selected
}

DrawSelectedBlocks :: proc() { for block in GetSelectedBlocks() do DrawOOBLines(GetCubeOBB(block.pos, block.rot, block.size), 0.04) }
DrawSelectedBlockInfo :: proc() {
	if(len(GetSelectedBlocks()) != 1) do return
	FONT_SIZE :: 48
	BUFFER :: 10
	block: Block
	for sel_block in GetSelectedBlocks() do block = sel_block^
	y_offset: f32 = 60 if cmd_menu_on else 0
	DrawText(string(format("SELECTED BLOCK DATA:")), {10, SCREEN_SIZE.y - (BUFFER + FONT_SIZE) * 5 - y_offset}, FONT_SIZE, 2, rl.LIGHTGRAY)
	DrawText(string(format("TYPE: %v", block.type)), {10, SCREEN_SIZE.y - (BUFFER + FONT_SIZE) * 4 - y_offset}, FONT_SIZE, 2, rl.LIGHTGRAY)
	DrawText(string(format("POS: [%.2f, %.2f, %.2f]", block.pos.x, block.pos.y, block.pos.z)), {10, SCREEN_SIZE.y - (BUFFER + FONT_SIZE) * 3 - y_offset}, FONT_SIZE, 2, rl.LIGHTGRAY)
	DrawText(string(format("ROT: [%.2f, %.2f, %.2f]", block.rot.x, block.rot.y, block.rot.z)), {10, SCREEN_SIZE.y - (BUFFER + FONT_SIZE) * 2 - y_offset}, FONT_SIZE, 2, rl.LIGHTGRAY)
	DrawText(string(format("SIZE: [%.2f, %.2f, %.2f]", block.size.x, block.size.y, block.size.z)), {10, SCREEN_SIZE.y - (BUFFER + FONT_SIZE) - y_offset}, FONT_SIZE, 2, rl.LIGHTGRAY)
}

DrawEndPoint :: proc() {
	rl.DrawSphere(room.end_point, 0.03, rl.PURPLE)
}

DrawModelPro :: proc(model: ^rl.Model, position: rl.Vector3, rotation: rl.Vector3, scale: rl.Vector3, tint: rl.Color) {
    matScale := rl.MatrixScale(scale.x, scale.y, scale.z)
    matRotation := MatrixRotateXYZ(rotation)
    matTranslation := rl.MatrixTranslate(position.x, position.y, position.z)
    matTransform := matTranslation * matRotation * matScale

    for i := 0; i < int(model.meshCount); i += 1 {
        mat := model.materials[model.meshMaterial[i]]
        colDiffuse := mat.maps[rl.MaterialMapIndex.ALBEDO].color

        colTinted: rl.Color = {}
        colTinted.r = u8((int(colDiffuse.r) * int(tint.r)) / 255)
        colTinted.g = u8((int(colDiffuse.g) * int(tint.g)) / 255)
        colTinted.b = u8((int(colDiffuse.b) * int(tint.b)) / 255)
        colTinted.a = u8((int(colDiffuse.a) * int(tint.a)) / 255)

        mat.maps[rl.MaterialMapIndex.ALBEDO].color = colTinted
        rl.DrawMesh(model.meshes[i], mat, matTransform)
        mat.maps[rl.MaterialMapIndex.ALBEDO].color = colDiffuse
    }
}

rot_rad :: proc(v: [3]f32) -> [3]f32 {
	return {math.to_radians(v.x), math.to_radians(v.y), math.to_radians(v.z)}
}