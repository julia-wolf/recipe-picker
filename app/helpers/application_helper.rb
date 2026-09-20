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
  def recipe_time(recipe, detail: false)
    total = recipe.total_time
    return "Time not listed" unless total
    return "#{total} min" unless detail

    parts = [ "#{total} min total" ]
    parts << "prep #{recipe.prep_time.to_i} min" if recipe.prep_time.to_i.positive?
    parts << "cook #{recipe.cook_time.to_i} min" if recipe.cook_time.to_i.positive?
    parts.join(" · ")
  end

  def pantry_entry_count(raw)
    raw.to_s.split(/[,\n]/).map { |term|
      IngredientNormalizer.pantry(term)
    }.reject(&:blank?).uniq.size
  end
end
