class RecipeMatcher
  STAPLES = [ "salt", "pepper", "water", "black pepper" ].map { |name|
    IngredientNormalizer.call(name)
  }.uniq.freeze

  Result = Struct.new(:recipe, :missing_count, keyword_init: true)
  PAGE_SIZE = 20

  def self.search(query, page: 1)
    matcher = new(query, page: page)
    decorate(matcher.search, matcher)
  end

  def self.staples_only?(query)
    new(query).staples_only?
  end

  def self.decorate(results, matcher)
    results.define_singleton_method(:page) { matcher.page }
    results.define_singleton_method(:has_next?) { matcher.has_next? }
    results
  end
  private_class_method :decorate

  def initialize(query, page: 1)
    @query = query
    @page = [ page.to_i, 1 ].max
    @has_next = false
  end

  def has_next?
    @has_next
  end

  attr_reader :page

  def staples_only?
    terms = pantry_terms
    terms.any? && (terms - STAPLES).empty?
  end

  def search
    terms = pantry_terms
    matchable = terms - STAPLES
    return [] if matchable.empty?

    pairs = ranked_page_pairs(matchable, terms)
    @has_next = pairs.size > PAGE_SIZE
    pairs = pairs.first(PAGE_SIZE)
    recipes = recipes_for(pairs.map(&:first))
    pairs.filter_map { |id, missing|
      recipe = recipes[id]
      next unless recipe

      Result.new(recipe: recipe, missing_count: missing.to_i)
    }
  end

  private

  def pantry_terms
    @query.to_s.split(/[,\n]/).map { |term|
      IngredientNormalizer.pantry(term)
    }.reject(&:blank?).uniq
  end

  def matching_recipe_id_scope(matchable)
    ingredient_ids = Ingredient.where(normalized_name: matchable).select(:id)
    RecipeIngredient.where(ingredient_id: ingredient_ids).select(:recipe_id)
  end

  def ranked_page_pairs(matchable, terms)
    excluded = (STAPLES + terms).uniq
    missing_sql = Recipe.sanitize_sql_array([
      "COUNT(ingredients.id) FILTER (WHERE ingredients.normalized_name NOT IN (?))",
      excluded
    ])
    unknown_sql = "CASE WHEN COALESCE(recipes.prep_time, 0) = 0 AND COALESCE(recipes.cook_time, 0) = 0 THEN 1 ELSE 0 END"
    time_sql = "(COALESCE(recipes.prep_time, 0) + COALESCE(recipes.cook_time, 0))"
    offset = (@page - 1) * PAGE_SIZE

    Recipe.where(id: matching_recipe_id_scope(matchable))
      .joins(recipe_ingredients: :ingredient)
      .group("recipes.id")
      .order(Arel.sql("#{missing_sql} ASC, #{unknown_sql} ASC, #{time_sql} ASC, recipes.id ASC"))
      .offset(offset)
      .limit(PAGE_SIZE + 1)
      .pluck(Arel.sql("recipes.id"), Arel.sql(missing_sql))
  end

  def recipes_for(ids)
    return {} if ids.empty?

    Recipe.where(id: ids).includes(recipe_ingredients: :ingredient).index_by(&:id)
  end
end
