extends Control

const UNLABELED_LABEL = "__UNLABELED__"
const INT64_MAX = (1 << 63) - 1
var labeledPoints = {}
var separator
var pointcloudPath = " "
var extent = [INT64_MAX, -INT64_MAX, INT64_MAX, -INT64_MAX, INT64_MAX, -INT64_MAX]
var useLabels = false
var labelColors = {}

var baseMaterial
var initialPointSize = 3


func _ready():
	initializeMaterial()

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/labeled_city_view.tscn")

func _on_load_pressed() -> void:
	labeledPoints[UNLABELED_LABEL] = PackedVector3Array()
	var filePath = "res://data/labeled_city_view.txt"
	loadPointcloudFile(filePath)
	translatePointcloud()
	savePointCloudData()
	get_tree().change_scene_to_file("res://scenes/point_cloud_view.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()

func loadPointcloudFile(filePath, limit=null):
	var file = FileAccess.open(filePath, FileAccess.READ)
	limit = file.get_length() if limit == null else limit
	separator = " "
	
	useLabels = true
	for i in range(limit):
		var line = file.get_csv_line(separator)
		if len(line) < 3: continue
		
		var point = Vector3(float(line[0]), float(line[2]), float(line[1]))
		updateExtents(point)
		
		var label = UNLABELED_LABEL
		if useLabels and len(line) == 4:
			label = line[3]
			if !labeledPoints.has(label):
				labeledPoints[label] = PackedVector3Array()
			labeledPoints[label].append(point)
		else:
			labeledPoints[UNLABELED_LABEL].append(point)

#
#func loadPointcloudFile(filePath, limit=null):
	#var file = FileAccess.open(filePath, FileAccess.READ)
	#limit = file.get_length() if limit == null else limit
	#var seperator = " "
	#for i in range(limit):
		#var line = file.get_csv_line(seperator)
		#if len(line) < 3: continue
		#
		#var point = Vector3(float(line[0]), float(line[2]), float(line[1]))
		#updateExtents(point)
		#
		#var label = UNLABELED_LABEL
		#if useLabels and len(line) == 4:
			#label = line[3]
			#if !labeledPoints.has(line[3]):
				#labeledPoints[line[3]] = PackedVector3Array()
			#
		#labeledPoints[label].push_back(point)


func translatePointcloud():
	for label in labeledPoints.keys():
		for i in range(0, len(labeledPoints[label])):
			var normalized_x = labeledPoints[label][i][0] - extent[1]
			var normalized_z = labeledPoints[label][i][2]- extent[5]
			labeledPoints[label][i][0] = normalized_x
			labeledPoints[label][i][2] = normalized_z

	var translatedExtent = [extent[0] - extent[1], 0, extent[2], extent[3], extent[4] - extent[5], 0]
	extent = translatedExtent


func updateExtents(point):
	if point[0] <= extent[0]:
		extent[0] = point[0]
	if point[0] >= extent[1]:
		extent[1] = point[0]
	if point[1] <= extent[2]:
		extent[2] = point[1]
	if point[1] >= extent[3]:
		extent[3] = point[1]
	if point[2] <= extent[4]:
		extent[4] = point[2]
	if point[2] >= extent[5]:
		extent[5] = point[2]


func initializeMaterial():
	baseMaterial = StandardMaterial3D.new()
	baseMaterial.use_point_size = true
	baseMaterial.point_size = initialPointSize
	baseMaterial.albedo_color = Color(1, 0, 0)  # Red points


func savePointCloudData():
	var variables = get_node("/root/Variables")  # Accessing the singleton
	variables.labeledPoints = labeledPoints
	variables.extent = extent
