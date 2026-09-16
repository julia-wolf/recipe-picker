module ApplicationHelper
  def recipe_time(recipe, detail: false)
    total = recipe.total_time
    return "Time not listed" unless total
    return "#{total} min" unless detail

    parts = [ "#{total} min total" ]
    parts << "prep #{recipe.prep_time.to_i} min" if recipe.prep_time.to_i.positive?
    parts << "cook #{recipe.cook_time.to_i} min" if recipe.cook_time.to_i.positive?
    parts.join(" · ")
  end
end
