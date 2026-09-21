module RecipesHelper
  RECIPE_PHOTO_FALLBACK = "/recipe-placeholder.svg?v=2".freeze

  def recipe_photo_tag(recipe)
    url = recipe.image_url.presence
    if url
      image_tag(
        url,
        alt: recipe.title,
        class: "recipe-photo",
        data: {
          controller: "recipe-photo",
          recipe_photo_fallback_value: RECIPE_PHOTO_FALLBACK,
          action: "error->recipe-photo#fallback"
        }
      )
    else
      image_tag(RECIPE_PHOTO_FALLBACK, alt: recipe.title, class: "recipe-photo")
    end
  end

  def recipe_time(recipe)
    recipe_time_lines(recipe).first
  end

  def recipe_time_lines(recipe)
    total = recipe.total_time
    return [ t("recipes.time.unknown") ] unless total

    lines = [ t("recipes.time.ready_in", count: total) ]
    lines << t("recipes.time.preparation", count: recipe.prep_time.to_i) if recipe.prep_time.to_i.positive?
    lines << t("recipes.time.cook", count: recipe.cook_time.to_i) if recipe.cook_time.to_i.positive?
    lines
  end
end
