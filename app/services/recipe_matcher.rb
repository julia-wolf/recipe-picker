class RecipeMatcher
  STAPLES = [ "salt", "pepper", "water", "black pepper" ].map { |name|
    IngredientNormalizer.call(name)
  }.uniq.freeze
  STAPLE_FILLERS = %w[
    and or to taste more as needed
    ground freshly
    pinch pinches
    kosher sea coarse coarsely fine cracked
    divided
  ].freeze

  Result = Struct.new(:recipe, :missing_count, :have, :missing, keyword_init: true) do
    def match_signal
      missing_count.zero? ? "Cook now" : "Missing #{missing_count}"
    end

    def cook_now?
      missing_count.zero?
    end

    def almost?
      missing_count.between?(1, 2)
    end
  end

  DECISION_SET_SIZE = 8
  MAX_ALMOST = 3

  def self.search(query)
    new(query).search
  end

  def self.explain(recipe, query)
    new(query).explain(recipe)
  end

  def self.staples_only?(query)
    new(query).staples_only?
  end

  def initialize(query)
    @query = query
  end

  def staples_only?
    terms = pantry_terms
    terms.any? && terms.all? { |term| staple_name?(term) }
  end

  def search
    terms = pantry_terms
    matchable = terms.reject { |term| staple_name?(term) }
    return [] if matchable.empty?

    pairs = ranked_decision_pairs(matchable, terms)
    recipes = recipes_for(pairs.map(&:first))
    results = pairs.filter_map { |id, missing|
      recipe = recipes[id]
      next unless recipe

      have, missing_lines = coverage_for(recipe, terms)
      Result.new(
        recipe: recipe,
        missing_count: missing.to_i,
        have: have,
        missing: missing_lines
      )
    }
    decision_set(results)
  end

  def explain(recipe)
    terms = pantry_terms
    return if terms.empty? || terms.all? { |term| staple_name?(term) }

    have, missing = coverage_for(recipe, terms)
    Result.new(recipe: recipe, missing_count: missing.size, have: have, missing: missing)
  end

  private

  def decision_set(results)
    cook_now = results.select(&:cook_now?).first(DECISION_SET_SIZE)
    remaining = DECISION_SET_SIZE - cook_now.size
    almost = results.select(&:almost?).first([ MAX_ALMOST, remaining ].min)
    cook_now + almost
  end

  def pantry_terms
    @query.to_s.split(/[,\n]/).map { |term|
      IngredientNormalizer.pantry(term)
    }.reject(&:blank?).uniq
  end

  def matching_recipe_id_scope(matchable)
    ingredient_ids = Ingredient.where(normalized_name: matchable).select(:id)
    RecipeIngredient.where(ingredient_id: ingredient_ids).select(:recipe_id)
  end

  def ranked_decision_pairs(matchable, terms)
    excluded = (catalog_staples + terms).uniq
    missing_sql = Recipe.sanitize_sql_array([
      "COUNT(ingredients.id) FILTER (WHERE ingredients.normalized_name NOT IN (?))",
      excluded
    ])
    unknown_sql = "CASE WHEN COALESCE(recipes.prep_time, 0) = 0 AND COALESCE(recipes.cook_time, 0) = 0 THEN 1 ELSE 0 END"
    time_sql = "(COALESCE(recipes.prep_time, 0) + COALESCE(recipes.cook_time, 0))"

    Recipe.where(id: matching_recipe_id_scope(matchable))
      .joins(recipe_ingredients: :ingredient)
      .group("recipes.id")
      .having("#{missing_sql} <= 2")
      .order(Arel.sql("#{missing_sql} ASC, #{unknown_sql} ASC, #{time_sql} ASC, recipes.id ASC"))
      .limit(DECISION_SET_SIZE)
      .pluck(Arel.sql("recipes.id"), Arel.sql(missing_sql))
  end

  def recipes_for(ids)
    return {} if ids.empty?

    Recipe.where(id: ids).includes(recipe_ingredients: :ingredient).index_by(&:id)
  end

  def coverage_for(recipe, terms)
    have = []
    missing = []

    recipe.recipe_ingredients.each do |line|
      name = line.ingredient.normalized_name
      if staple_name?(name) || terms.include?(name)
        have << line.display_text
      else
        missing << line.display_text
      end
    end

    [ have, missing ]
  end

  def catalog_staples
    table = Ingredient.arel_table
    pattern = STAPLES.map { |staple|
      table[:normalized_name].matches("%#{ActiveRecord::Base.sanitize_sql_like(staple)}%")
    }.reduce(:or)
    Ingredient.where(pattern).distinct.pluck(:normalized_name).select { |name| staple_name?(name) }
  end

  def staple_name?(name)
    return false if name.blank?

    remaining = " #{name} "
    STAPLES.sort_by { |staple| -staple.length }.each do |staple|
      remaining.gsub!(/\s#{Regexp.escape(staple)}\s/, " ")
    end
    leftover = remaining.split - STAPLE_FILLERS
    leftover.empty?
  end
end
