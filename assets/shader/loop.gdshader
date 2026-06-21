shader_type canvas_item;

uniform vec2 direction;
uniform float speed;
varying vec4 modulate;

void vertex() {
	modulate = COLOR;
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 move = direction * TIME * speed;
	COLOR = texture(TEXTURE, UV + move) * modulate;
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
