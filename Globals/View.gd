extends Node

# Shared camera state for all 2D-projected 3D shapes (cubes, monsters, items).
#
# Mental model: there's a screen plane at world z = 0. Each cube/shape sits on
# this plane at its Node2D global_position. Its rotated corners stick out in
# 3D from there. The shared camera lives at (camera_position.x, camera_position.y,
# +camera_distance), looking toward -Z.
#
# Projection math used by each cube:
#   world_xy = cube.global_position + Vector2(corner.x, -corner.y)   # flip Y: world-up → screen-down
#   depth    = camera_distance - corner.z                            # distance in front of camera
#   lateral  = world_xy - camera_position                            # offset from camera screen-XY
#   screen   = camera_position + lateral * focal_length / depth
#
# When camera_position equals a cube's global_position, that cube projects exactly
# like the old per-cube camera. As cubes drift away from camera_position, they
# foreshorten toward the shared vanishing point — left cubes lean right, right
# cubes lean left, top cubes tilt down, etc.

# Screen-pixel anchor of the camera (the vanishing point on screen).
# Tune this to wherever you want all cubes to "look toward."
var camera_position : Vector2 = Vector2(360, 800)

# Depth distance from camera to the z=0 screen plane. Bigger = flatter / less
# perspective. Should be larger than any corner's z so depth stays positive.
var camera_distance : float = 4.0

# Pixels per world unit at depth = camera_distance. Bigger = telephoto / cubes
# look closer. Roughly: doubling this doubles the on-screen size of every cube.
var focal_length : float = 250.0
