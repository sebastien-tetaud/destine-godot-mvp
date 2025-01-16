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


#func createPointCloud():
	#for label in labeledPoints.keys():
		#if labeledPoints[label].size() == 0:
			#continue
		#var arrayMesh = ArrayMesh.new()
		#var meshData = []
		#meshData.resize(Mesh.ARRAY_MAX)
		#meshData[Mesh.ARRAY_VERTEX] = labeledPoints[label]
		#arrayMesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, meshData)
		#var meshInstance = MeshInstance3D.new()
		#meshInstance.mesh = arrayMesh
		#meshInstance.material_override = baseMaterial.duplicate()
		#meshInstance.material_override.albedo_color = Color.PURPLE
		#print(label)
		#add_child(meshInstance)

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
		
		print("Label: ", label, " Color: ", random_color)
		add_child(meshInstance)



#func placeCamera():
	#centerObject.transform.origin = Vector3(extent[0] / 2, (extent[3] + extent[2]) / 2, extent[4] / 2)
	#cameraBody.transform.origin = Vector3(extent[0],  (extent[3] + extent[2]) / 2, extent[4])
	#cameraBody.look_at(centerObject.position)
