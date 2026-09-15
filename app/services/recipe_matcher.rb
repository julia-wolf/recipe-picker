class RecipeMatcher
  STAPLES = [ "salt", "pepper", "water", "black pepper" ].map { |name|
    IngredientNormalizer.call(name)
  }.uniq.freeze

  Result = Struct.new(:recipe, :missing_count, keyword_init: true)

  def self.search(query)
    new(query).search
  end

  def self.staples_only?(query)
    new(query).staples_only?
  end

  def initialize(query)
    @query = query
  end

  def staples_only?
    terms = pantry_terms
    terms.any? && (terms - STAPLES).empty?
  end

  def search
    terms = pantry_terms
    matchable = terms - STAPLES
    return [] if matchable.empty?

    recipes_matching(matchable).map { |recipe|
      Result.new(recipe: recipe, missing_count: missing_count_for(recipe, terms))
    }.sort_by { |result| [ result.missing_count, time_sort_key(result.recipe) ] }
  end

  private

  def pantry_terms
    @query.to_s.split(/[,\n]/).map { |term|
      IngredientNormalizer.pantry(term)
    }.reject(&:blank?).uniq
  end

  def recipes_matching(matchable)
    ingredient_ids = Ingredient.where(normalized_name: matchable).pluck(:id)
    return Recipe.none if ingredient_ids.empty?

    recipe_ids = RecipeIngredient.where(ingredient_id: ingredient_ids).distinct.pluck(:recipe_id)
    Recipe.where(id: recipe_ids).includes(recipe_ingredients: :ingredient)
  end

  def missing_count_for(recipe, terms)
    recipe.recipe_ingredients.count do |recipe_ingredient|
      name = recipe_ingredient.ingredient.normalized_name
      next false if STAPLES.include?(name)

      terms.exclude?(name)
    end
  end

  def time_sort_key(recipe)
    recipe.total_time || Float::INFINITY
  end
end
