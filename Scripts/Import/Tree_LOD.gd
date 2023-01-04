@tool
extends EditorScenePostImport

var range1 = 300
var range2 = 500

func _post_import(scene):
	for child in scene.get_children():
		if child.name.ends_with("LOD1"):
			child.visibility_range_begin = range1-1
			child.visibility_range_end = range2
		elif  child.name.ends_with("LOD2"):
			child.visibility_range_begin = range2-1
		else:
			child.visibility_range_end = range1
	
	return scene
