@tool
extends EditorScenePostImport

var range1 = 300
var range2 = 500
var fadeRange = 30 # Shadow bug

func _post_import(scene):
	for child in scene.get_children():
		if child.name.ends_with("LOD1"):
			child.visibility_range_begin = range1-1#-fadeRange
			#child.visibility_range_begin_margin = fadeRange    
			child.visibility_range_end = range2
			#child.visibility_range_end_margin = fadeRange
			#child.visibility_range_fade_mode = 1
		elif  child.name.ends_with("LOD2"):
			child.visibility_range_begin = range2-1#-fadeRange
			#child.visibility_range_begin_margin = fadeRange
			#child.visibility_range_fade_mode = 1
		else:
			child.visibility_range_end = range1
			#child.visibility_range_end_margin = fadeRange
			#child.visibility_range_fade_mode = 1
	
	return scene
