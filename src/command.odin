package main

import rl "vendor:raylib"
import "core:strings"
import "core:strconv"
import "core:fmt"
import "core:os"
import "core:encoding/json"

DEF_PATH :: "res/rooms/"

cmd_text := ""
cmd_menu_on := false
past_texts: [dynamic]string
past_text_index: int

OperationType :: enum{ MOVE, RESIZE }

UpdateCommandMenu :: proc() {
	if(cmd_menu_on) {
		char_pressed := rl.GetCharPressed()
		cmd_text = strings.concatenate({cmd_text, to_string(char_pressed)})
		if(rl.IsKeyPressed(.BACKSPACE)) do cmd_text = string_pop(cmd_text)
		if(rl.IsKeyPressed(.RIGHT_SHIFT)) do cmd_text = ""
		if(rl.IsKeyPressed(.ENTER)) {
			append(&past_texts, cmd_text)
			past_text_index = -1
			args := strings.split(cmd_text, " ")
			if(len(args) == 0) do return
			fmt.printf("GAME: Recieved command with arguments: %v\n", args)
			
			switch(args[0]) {
				case "cube": AddCube(args)
				case "export": ExportRoom(strings.concatenate({DEF_PATH, args[1], ".json"}))
				case "import": ImportRoom(strings.concatenate({DEF_PATH, args[1], ".json"}))
				case "move": HandleBlockData(args, .MOVE)
				case "resize": HandleBlockData(args, .RESIZE)
				case "delete": #reverse for block, index in room.blocks do if(block.selected) do unordered_remove(&room.blocks, index)
				case "duplicate": #reverse for block in room.blocks do AppendBlock(block.pos, block.scale)
				case "endpoint": HandleEndPoint(args)
				case "select": if(len(args) == 1 || (len(args) == 2 && args[1] == "all")) do #reverse for &block in room.blocks do block.selected = true
				case "deselect": if(len(args) == 1 || (len(args) == 2 && args[1] == "all")) do #reverse for &block in room.blocks do block.selected = false
			}
			
			cmd_text = ""
			cmd_menu_on = false
		}
		
		if(rl.IsKeyPressed(.UP)) {
			if(past_text_index == -1) {
				cmd_text = past_texts[len(past_texts) - 1]
				past_text_index = len(past_texts) - 1
			} else if(past_text_index > 0) {
				cmd_text = past_texts[past_text_index - 1]
				past_text_index -= 1
			}
		} else if(rl.IsKeyPressed(.DOWN)) {
			if(past_text_index >= 0 && past_text_index < len(past_texts) - 1) {
				cmd_text = past_texts[past_text_index + 1]
				past_text_index += 1
			} else {
				cmd_text = ""
				past_text_index = -1
			}
		}
	}
	
	if(rl.IsKeyPressed(.ESCAPE) && cmd_menu_on) do cmd_menu_on = false
	if(rl.IsKeyPressed(.SLASH)) do cmd_menu_on = !cmd_menu_on
}

AddCube :: proc(args: []string) {
	switch(len(args)) {
		case 1: AppendBlock()
		case 4: {
			vec, ok := ParseVector(args[1:], 3)
			if(ok) do AppendBlock(vec)
		}
		case 7: {
			args1 := args[1:4]
			args2 := args[4:]
			vec1, ok1 := ParseVector(args1, 3)
			vec2, ok2 := ParseVector(args2, 3)
			if(ok1 && ok2) do AppendBlock(vec1, vec2)
		}
	}
}

ExportRoom :: proc(path: string) {
	options := json.Marshal_Options{.JSON, true, false, 0, false, false, false, false, false, 0, false, false}
	BareBlock :: struct{pos: rl.Vector3, scale: rl.Vector3}
	BareRoom :: struct{bare_blocks: [dynamic]BareBlock, end_point: rl.Vector3}
	bare_room: BareRoom
	for block in room.blocks do append(&bare_room.bare_blocks, BareBlock{block.pos, block.scale})
	bare_room.end_point = room.end_point
	data, err := json.marshal(bare_room, options)
	if(err != nil) {
		fmt.printf("GAME: Json marshal error! (path: %s)\n", path)
		return
	}
	os.make_directory(DEF_PATH)
	write_err := os.write_entire_file(path, data)
	if(write_err != nil) do fmt.printf("GAME: OS write file error! (path: %s)\n", path); else do fmt.printf("GAME: Exported to %s\n", path)
}

ImportRoom :: proc(path: string) {
	BareBlock :: struct{pos: rl.Vector3, scale: rl.Vector3}
	BareRoom :: struct{bare_blocks: [dynamic]BareBlock, end_point: rl.Vector3}
	data, err := os.read_entire_file(path, context.allocator)
	if(err != nil) {
		fmt.printf("GAME: OS read file error! (path: %s)\n", path)
		return
	}
	new_room: BareRoom
	unm_err := json.unmarshal(data, &new_room)
	if(unm_err != nil) {
		fmt.printf("GAME: Json unmarshal error! (path: %s)\n", path)
		return
	}
	clear(&room.blocks)
	for block in new_room.bare_blocks do AppendBlock(block.pos, block.scale)
	room.end_point = new_room.end_point
	fmt.printf("GAME: Imported from %s\n", path)
}

MoveBlock :: proc(block: ^Block, amount: rl.Vector3, add: bool) { if(add) do block.pos += amount; else do block.pos = amount }
ResizeBlock :: proc(block: ^Block, amount: rl.Vector3, add: bool) { 
	if(add && block.scale.x + amount.x >= 0 && block.scale.y + amount.y >= 0 && block.scale.z + amount.z >= 0) do block.scale += amount
	if(!add && amount.x >= 0 && amount.y >= 0 && amount.z >= 0) do block.scale = amount
}

HandleBlockData :: proc(args: []string, op: OperationType) {
	if !(len(args) == 4 || (len(args) == 6 && args[2] == "all")) do return
	func :: proc(block: ^Block, amount: rl.Vector3, add: bool, op: OperationType) {
		switch(op) {
			case .MOVE: MoveBlock(block, amount, add)
			case .RESIZE: ResizeBlock(block, amount, add)
		}
	}
	
	for block in GetSelectedBlocks() {
		if(args[2] == "all") {
			vec, ok := ParseVector(args[3:], 3)
			if(ok) do switch(args[1]) {
				case "add": func(block, vec, true, op)
				case "set": func(block, vec, false, op)
			}
			return
		}
		
		value, ok := Parse(args[3], f32)
		def_val: rl.Vector3
		switch(op) {
			case .MOVE: def_val = block.pos
			case .RESIZE: def_val = block.scale
		}
	 	if(ok) do switch(args[1]) {
			case "add": switch(args[2]) {
				case "x": func(block, {value, 0, 0}, true, op)
				case "y": func(block, {0, value, 0}, true, op)
				case "z": func(block, {0, 0, value}, true, op)
			}
			case "set": switch(args[2]) {
				case "x": func(block, {value, def_val.y, def_val.z}, false, op)
				case "y": func(block, {def_val.x, value, def_val.z}, false, op)
				case "z": func(block, {def_val.x, def_val.y, value}, false, op)
			}
		}
	}
}

HandleEndPoint :: proc(args: []string) {
	if !(len(args) == 4 || (len(args) == 6 && args[2] == "all")) do return
	if(args[2] == "all") {
		vec, ok := ParseVector(args[3:], 3)
		if(ok) do switch(args[1]) {
			case "add": room.end_point += vec
			case "set": room.end_point = vec
		}
		return
	}
	
	value, ok := Parse(args[3], f32)
 	if(ok) do switch(args[1]) {
		case "add": switch(args[2]) {
			case "x": room.end_point.x += value
			case "y": room.end_point.y += value
			case "z": room.end_point.z += value
		}
		case "set": switch(args[2]) {
			case "x": room.end_point.x = value
			case "y": room.end_point.y = value
			case "z": room.end_point.z = value
		}
	}
}

DrawCommandMenu :: proc() {
	if(cmd_menu_on) {
		BUFFER :: 10
		HEIGHT :: 60
		BOX_OPACITY :: 100
		FONT_SIZE :: 56
		FONT_SPACING :: 1
		POS: rl.Vector2 : {BUFFER + 10, SCREEN_SIZE.y - BUFFER - HEIGHT}
		rl.DrawRectangle(BUFFER, i32(SCREEN_SIZE.y) - BUFFER - HEIGHT, i32(SCREEN_SIZE.x) - BUFFER * 2, HEIGHT, {0, 0, 0, BOX_OPACITY})
		DrawText(cmd_text, POS, FONT_SIZE, FONT_SPACING, rl.WHITE)
		size := MeasureText(cmd_text, FONT_SIZE, FONT_SPACING)
		rl.DrawLineEx({POS.x + size.x + BUFFER, POS.y + BUFFER}, {POS.x + size.x + BUFFER, POS.y + HEIGHT - BUFFER}, 3, rl.WHITE)
	}
}

Parse :: proc(str: string, $T: typeid) -> (result: T, ok: bool) {
	when(T == int) { return strconv.parse_int(str) } 
	else when(T == f32) { return strconv.parse_f32(str) }
	else when(T == f64) { return strconv.parse_f64(str) } 
	else when(T == bool) { return strconv.parse_bool(str) } 
	else when(T == string || T == cstring) { return str, true }
}

ParseVector :: proc(args: []string, $vlen: int) -> (vec: [vlen]f32, ok: bool) {
	if(len(args) < vlen) do return {}, false
	vector: [vlen]f32
	vgok := true
	for i in 0..=vlen - 1 {
		vok: bool
		vector[i], vok = Parse(args[i], f32)
		if(!vok) do vgok = false
	}
	return vector, vgok
}