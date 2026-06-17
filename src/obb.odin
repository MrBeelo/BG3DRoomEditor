package main

import rl "vendor:raylib"

OBB :: struct {
	center: rl.Vector3,
	axis: [3]rl.Vector3,
	half_size: rl.Vector3
}

GetOBBCorners :: proc(box: OBB, offset := f32(0)) -> [8]rl.Vector3 {
	hx := box.axis.x * (box.half_size.x + offset)
    hy := box.axis.y * (box.half_size.y + offset)
    hz := box.axis.z * (box.half_size.z + offset)
    
	return [?]rl.Vector3{
		box.center - hx - hy - hz, box.center + hx - hy - hz,
		box.center + hx + hy - hz, box.center - hx + hy - hz,
		box.center - hx - hy + hz, box.center + hx - hy + hz,
		box.center + hx + hy + hz, box.center - hx + hy + hz
	}
}

DrawOOBLines :: proc(box: OBB, offset := f32(0.01), color := rl.RED) {
	corners := GetOBBCorners(box, offset)
	rl.DrawLine3D(corners[0], corners[1], color)
	rl.DrawLine3D(corners[1], corners[2], color)
	rl.DrawLine3D(corners[2], corners[3], color)
	rl.DrawLine3D(corners[3], corners[0], color)
	rl.DrawLine3D(corners[4], corners[5], color)
	rl.DrawLine3D(corners[5], corners[6], color)
	rl.DrawLine3D(corners[6], corners[7], color)
	rl.DrawLine3D(corners[7], corners[4], color)
	rl.DrawLine3D(corners[0], corners[4], color)
	rl.DrawLine3D(corners[1], corners[5], color)
	rl.DrawLine3D(corners[2], corners[6], color)
	rl.DrawLine3D(corners[3], corners[7], color)
}

GetOBBFromBoundingBox :: proc(box: rl.BoundingBox) -> OBB {
	center := (box.max + box.min) / 2
	axes := [3]rl.Vector3{{1, 0, 0}, {0, 1, 0}, {0, 0, 1}}
	half_size := (box.max - box.min) / 2
	return {center, axes, half_size}
}

GetCubeOBB :: proc(pos: rl.Vector3, rot: rl.Vector3, scale: rl.Vector3) -> OBB {
	rm := MatrixRotateXYZ(rot_rad(rot))
	axis_x := rl.Vector3{rm[0, 0], rm[1, 0], rm[2, 0]}
	axis_y := rl.Vector3{rm[0, 1], rm[1, 1], rm[2, 1]}
	axis_z := rl.Vector3{rm[0, 2], rm[1, 2], rm[2, 2]}
	return {pos, {axis_x, axis_y, axis_z}, scale / 2}
}

GetRayCollisionOBB :: proc(ray: rl.Ray, box: OBB) -> rl.RayCollision {
	delta := ray.position - box.center
	local_pos := rl.Vector3{rl.Vector3DotProduct(delta, box.axis[0]), rl.Vector3DotProduct(delta, box.axis[1]), 
		rl.Vector3DotProduct(delta, box.axis[2])}
	local_dir := rl.Vector3{rl.Vector3DotProduct(ray.direction, box.axis[0]), rl.Vector3DotProduct(ray.direction, box.axis[1]),
        rl.Vector3DotProduct(ray.direction, box.axis[2])}
	
    local_ray := rl.Ray{local_pos, local_dir}
    local_box := rl.BoundingBox{-box.half_size, box.half_size};
    hit := rl.GetRayCollisionBox(local_ray, local_box);
    
    if (!hit.hit) do return hit;
    
    hit.point = box.center + box.axis[0] * hit.point.x + box.axis[1] * hit.point.y + box.axis[2] * hit.point.z
    hit.normal = rl.Vector3Normalize(box.axis[0] * hit.normal.x + box.axis[1] * hit.normal.y + box.axis[2] * hit.normal.z)
    return hit;
}

MatrixRotateXYZ :: proc(v: rl.Vector3) -> rl.Matrix {
	rx := rl.MatrixRotateX(v.x)
	ry := rl.MatrixRotateY(v.y)
    rz := rl.MatrixRotateZ(v.z)
    return rx * ry * rz
}