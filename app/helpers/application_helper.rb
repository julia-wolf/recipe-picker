module ApplicationHelper
  RECIPE_PHOTO_FALLBACK = "/recipe-placeholder.svg?v=2".freeze

  def recipe_photo_tag(recipe)
    url = recipe.image_url.presence || RECIPE_PHOTO_FALLBACK
    image_tag(
      url,
      alt: recipe.title,
      class: "recipe-photo",
      onerror: "this.onerror=null;this.src='#{RECIPE_PHOTO_FALLBACK}'"
    )
  end
  def recipe_time(recipe)
    recipe_time_lines(recipe).first
  end

  def recipe_time_lines(recipe)
    total = recipe.total_time
    return [ "Ready in: time unknown" ] unless total

    lines = [ "Ready in: #{total} minutes" ]
    lines << "Preparation: #{recipe.prep_time.to_i} minutes" if recipe.prep_time.to_i.positive?
    lines << "Cook time: #{recipe.cook_time.to_i} minutes" if recipe.cook_time.to_i.positive?
    lines
  end

  def pantry_entry_count(raw)
    raw.to_s.split(/[,\n]/).map { |term|
      IngredientNormalizer.pantry(term)
    }.reject(&:blank?).uniq.size
  end
end
