extends Node3D

@onready var variables = get_node("/root/Variables")

var labeledPoints = {}
var baseMaterial
var extent = []

func _ready():
	get_node("/root/Variables").extent = []
	labeledPoints = variables.labeledPoints
	if labeledPoints.size() > 0:
		initializeMaterial()
		createPointCloud()
		#placeCamera()
	else:
		print("No labeled points available to visualize.")
	

func initializeMaterial():
	baseMaterial = StandardMaterial3D.new()
	baseMaterial.use_point_size = true
	baseMaterial.point_size = 4
	baseMaterial.albedo_color = Color(1, 0, 0)  # Default color (red)


func createPointCloud():
	for label in labeledPoints.keys():
		if labeledPoints[label].size() == 0:
			continue
		var arrayMesh = ArrayMesh.new()
		var meshData = []
		meshData.resize(Mesh.ARRAY_MAX)
		meshData[Mesh.ARRAY_VERTEX] = labeledPoints[label]
		arrayMesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, meshData)
		
		var meshInstance = MeshInstance3D.new()
		meshInstance.mesh = arrayMesh
		
		# Create a random color for the label (R, G, B values between 0 and 1)
		var random_color = Color(randf(), randf(), randf())
		# Set the material and apply the random color
		meshInstance.material_override = baseMaterial.duplicate()
		meshInstance.material_override.albedo_color = random_color
		add_child(meshInstance)


func create_terrain_from_heightmap(image_path: String) -> MeshInstance3D:
	# Load the heightmap image
	var image = Image.new()
	if image.load(image_path) != OK:
		print("Failed to load heightmap image.")
		return null

	# Create an ImageTexture from the image
	var texture = ImageTexture.new()
	texture.create_from_image(image)

	# Get the heightmap dimensions
	var width = image.get_width()
	var height = image.get_height()
	
	# Generate a mesh based on the heightmap
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Create vertices for the heightmap
	for y in range(height - 1):
		for x in range(width - 1):
			# Get the height values (normalize to a scale)
			var h1 = image.get_pixel(x, y).r * 100.0  # Scale height by 100
			var h2 = image.get_pixel(x + 1, y).r * 100.0
			var h3 = image.get_pixel(x, y + 1).r * 100.0
			var h4 = image.get_pixel(x + 1, y + 1).r * 100.0

			# Create triangles for the quad
			surface_tool.add_vertex(Vector3(x, h1, y))
			surface_tool.add_vertex(Vector3(x + 1, h2, y))
			surface_tool.add_vertex(Vector3(x, h3, y + 1))

			surface_tool.add_vertex(Vector3(x + 1, h2, y))
			surface_tool.add_vertex(Vector3(x + 1, h4, y + 1))
			surface_tool.add_vertex(Vector3(x, h3, y + 1))
	
	#surface_tool.set_color(Color(1, 0, 0))
	# Commit the mesh
	var mesh = surface_tool.commit()
	# Create a MeshInstance3D to display the terrain
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh

	# Add a material for better visualization
	var material = StandardMaterial3D.new()
	material.albedo_texture = texture
	material.roughness = 1.0
	material.metallic = 0.0
	mesh_instance.material_override = material
	
	
	return mesh_instance
