class_name FxRecipeSet
extends Resource

@export var recipes: Array[FxRecipe] = []

func get_recipe(id: StringName) -> FxRecipe:
	for r: FxRecipe in recipes:
		if r.id == id:
			return r
	return null
