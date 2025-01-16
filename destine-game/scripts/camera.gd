extends CharacterBody3D

@onready var camera: Camera3D = $Camera  # Assuming the camera is a child of this node

const SPEED = 30  # Movement speed
const MOUSE_SENSITIVITY = 0.10  # Mouse sensitivity for rotation
const VERTICAL_SPEED = 10.0  # Vertical movement speed (up/down)
const ZOOM_SPEED = 2.0  # Speed of zooming
const MIN_FOV = 20.0  # Minimum FOV for zooming in
const MAX_FOV = 90.0  # Maximum FOV for zooming out

var pitch = 0.0  # Vertical rotation (X-axis)
var yaw = 0.0  # Horizontal rotation (Y-axis)
var is_paused = false  # Flag to track if the motion is paused

func _ready():
	# Hide the mouse and capture it for camera control
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Set the camera to the top corner at a 45-degree angle
	var offset = Vector3(0, 10, 0)  # Adjust this vector to place the camera at the desired position
	camera.position = offset
	
	# Set the camera's rotation to look at the origin (or wherever you want the focus)
	camera.look_at(Vector3.ZERO, Vector3.UP)  # Look at the center of the scene (0, 0, 0)

func _process(_delta):
	if is_paused:
		# If the game is paused, don't move the camera
		velocity = Vector3.ZERO
		return
	
	# Handle movement based on input (WASD keys)
	var input_dir = Vector3(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		0,
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)
	var direction = (transform.basis * input_dir).normalized()

	# Move the character (camera) based on input
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED

	# Handle vertical movement (up/down) with Spacebar and Ctrl
	if Input.is_action_pressed("cam_up"):  # Spacebar for moving up
		velocity.y = VERTICAL_SPEED
	elif Input.is_action_pressed("cam_down"):  # Ctrl for moving down
		velocity.y = -VERTICAL_SPEED
	else:
		velocity.y = 0  # No vertical movement if neither is pressed

	move_and_slide()


func _input(event):
	# Rotate camera based on mouse motion
	if event is InputEventMouseMotion and not is_paused:
		yaw -= event.relative.x * MOUSE_SENSITIVITY
		pitch -= event.relative.y * MOUSE_SENSITIVITY
		pitch = clamp(pitch, -90, 90)  # Prevent flipping over (clamping vertical rotation)

		# Apply rotation to the camera and the player (CharacterBody3D)
		rotation_degrees.y = yaw
		camera.rotation_degrees.x = pitch

	# Zoom in/out with mouse wheel
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:  # Zoom in
			camera.fov = max(camera.fov - ZOOM_SPEED, MIN_FOV)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:  # Zoom out
			camera.fov = min(camera.fov + ZOOM_SPEED, MAX_FOV)

	# Toggle mouse capture and pause when pressing ESC
	if event.is_action_pressed("ui_cancel"):
		if not is_paused:
			# Pause the game and make the mouse visible
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			is_paused = true
		else:
			# Resume the game and capture the mouse again
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			is_paused = false
