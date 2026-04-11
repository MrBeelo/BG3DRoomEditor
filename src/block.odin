package main

import rl "vendor:raylib"

room: Room

Block :: struct { pos: rl.Vector3, scale: rl.Vector3, selected: bool }
Room :: struct { blocks: [dynamic]Block, end_point: rl.Vector3 }

NewBlock :: proc(pos: rl.Vector3, scale: rl.Vector3) -> Block { return Block{pos, scale, false} }
AppendBlock :: proc(pos: rl.Vector3 = {}, scale: rl.Vector3 = {1, 1, 1}) { append(&room.blocks, NewBlock(pos, scale)) }
DrawBlocks :: proc() { for block in room.blocks do DrawBlock(block) }
DrawBlock :: proc(block: Block) { rl.DrawModelEx(block_model, block.pos, {}, 0, block.scale, {190, 253, 255, 255} if(block.selected) else rl.WHITE) }

GetSelectedBlocks :: proc() -> [dynamic]^Block {
	selected_blocks: [dynamic]^Block
	for &block in room.blocks do if block.selected do append(&selected_blocks, &block)
	return selected_blocks
}

GetBlockBoundingBox :: proc(block: Block) -> rl.BoundingBox {
	pos, hs := block.pos, (block.scale / 2)
	return {{pos.x - hs.x, pos.y - hs.y, pos.z - hs.z}, {pos.x + hs.x, pos.y + hs.y, pos.z + hs.z}}
}

UpdateSelectedBlocks :: proc() {
	ray := rl.GetScreenToWorldRay({SCREEN_SIZE.x / 2, SCREEN_SIZE.y / 2}, camera)
	#reverse for &block, index in room.blocks {
		box := GetBlockBoundingBox(block)
		coll := rl.GetRayCollisionBox(ray, box)
		if(coll.hit && coll.distance < 20 && rl.IsMouseButtonPressed(.LEFT)) do block.selected = !block.selected
		if(block.selected && rl.IsKeyPressed(.DELETE)) do unordered_remove(&room.blocks, index)
	}
}

DrawSelectedBlocks :: proc() { for block in GetSelectedBlocks() do rl.DrawCubeWiresV(block.pos, block.scale + 0.04, rl.RED) }
DrawSelectedBlockInfo :: proc() {
	if(len(GetSelectedBlocks()) != 1) do return
	FONT_SIZE :: 48
	BUFFER :: 10
	block := room.blocks[0]
	y_offset: f32 = 60 if cmd_menu_on else 0
	DrawText(string(format("SELECTED BLOCK DATA:")), {10, SCREEN_SIZE.y - (BUFFER + FONT_SIZE) * 3 - y_offset}, FONT_SIZE, 2, rl.LIGHTGRAY)
	DrawText(string(format("POS: [%.2f, %.2f, %.2f]", block.pos.x, block.pos.y, block.pos.z)), {10, SCREEN_SIZE.y - (BUFFER + FONT_SIZE) * 2 - y_offset}, FONT_SIZE, 2, rl.LIGHTGRAY)
	DrawText(string(format("SCALE: [%.2f, %.2f, %.2f]", block.scale.x, block.scale.y, block.scale.z)), {10, SCREEN_SIZE.y - (BUFFER + FONT_SIZE) - y_offset}, FONT_SIZE, 2, rl.LIGHTGRAY)
}

DrawEndPoint :: proc() {
	rl.DrawSphere(room.end_point, 0.03, rl.PURPLE)
}