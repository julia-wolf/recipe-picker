class RecipeMatcher
  STAPLES = [ "black pepper", "salt", "pepper", "water" ].map { |name|
    IngredientNormalizer.normalize(name)
  }.uniq.freeze
  STAPLE_FILLERS = %w[
    and or to taste more as needed
    ground freshly
    pinch pinches
    kosher sea coarse coarsely fine cracked
    divided
  ].freeze
  DECISION_SET_SIZE = 9
  MIN_MISSING = 1
  MAX_MISSING = 3
  EXCLUDED_CATEGORIES = [ "Pet Treats", "Pet Food" ].freeze

  Result = Struct.new(:recipe, :missing_count, :have, :missing, :staples, keyword_init: true) do
    def cook_now?
      missing_count.zero?
    end

    def almost?
      missing_count.between?(MIN_MISSING, MAX_MISSING)
    end
  end

  Search = Struct.new(:results, :needs_more, :staples_only, :pantry_terms, keyword_init: true) do
    include Enumerable

    def each(...)
      results.each(...)
    end

    def empty?
      results.empty?
    end

    def size
      results.size
    end

    def needs_more?
      needs_more
    end

    def staples_only?
      staples_only
    end

    def cook_now
      results.select(&:cook_now?)
    end

    def almost
      results.select(&:almost?)
    end
  end

  class << self
    def search(ingredients)
      new(ingredients).search
    end

    def coverage(recipe, ingredients)
      new(ingredients).coverage(recipe)
    end
  end

  def initialize(ingredients)
    @ingredients = ingredients
  end

  def search
    if matchable_terms.empty?
      return Search.new(
        results: [],
        needs_more: false,
        staples_only: pantry_terms.any?,
        pantry_terms: pantry_terms
      )
    end

    ids, needs_more = ranked_decision_ids
    recipes = recipes_for(ids)
    results = ids.filter_map { |id|
      recipe = recipes[id]
      next unless recipe

      have, missing, staples = coverage_for(recipe, pantry_terms)
      Result.new(
        recipe: recipe,
        missing_count: missing.size,
        have: have,
        missing: missing,
        staples: staples
      )
    }
    Search.new(results: results, needs_more: needs_more, staples_only: false, pantry_terms: pantry_terms)
  end

  def coverage(recipe)
    return if matchable_terms.empty?

    have, missing, staples = coverage_for(recipe, pantry_terms)
    Result.new(recipe: recipe, missing_count: missing.size, have: have, missing: missing, staples: staples)
  end

  private

  def pantry_terms
    @pantry_terms ||= @ingredients.to_s.split(/[,\n]/).map { |term|
      IngredientNormalizer.without_amount(term)
    }.reject(&:blank?).uniq
  end

  def matchable_terms
    @matchable_terms ||= pantry_terms.reject { |term| staple_name?(term) }
  end

  def candidate_recipe_ids(matchable_terms)
    ingredient_ids = Ingredient.where(normalized_name: matchable_terms).select(:id)
    recipe_ids = RecipeIngredient.where(ingredient_id: ingredient_ids).select(:recipe_id)
    Recipe.where(id: recipe_ids)
      .where("category IS NULL OR category NOT IN (?)", EXCLUDED_CATEGORIES)
      .select(:id)
  end

  def ranked_decision_ids
    covered_names = (catalog_staples + pantry_terms).uniq
    missing_sql = Recipe.sanitize_sql_array([
      "COUNT(ingredients.id) FILTER (WHERE ingredients.normalized_name NOT IN (?))",
      covered_names
    ])
    unknown_sql = "CASE WHEN COALESCE(recipes.prep_time, 0) = 0 AND COALESCE(recipes.cook_time, 0) = 0 THEN 1 ELSE 0 END"
    time_sql = "(COALESCE(recipes.prep_time, 0) + COALESCE(recipes.cook_time, 0))"
    candidate_ids = candidate_recipe_ids(matchable_terms)

    ranked = Recipe.where(id: candidate_ids)
      .joins(recipe_ingredients: :ingredient)
      .group("recipes.id")
      .having("#{missing_sql} <= #{MAX_MISSING}")
      .order(Arel.sql("#{missing_sql} ASC, #{unknown_sql} ASC, #{time_sql} ASC, recipes.id ASC"))
      .limit(DECISION_SET_SIZE)
      .pluck(Arel.sql("recipes.id"))

    needs_more = ranked.empty? && Recipe.where(id: candidate_ids).exists?
    [ ranked, needs_more ]
  end

  def recipes_for(ids)
    return {} if ids.empty?

    Recipe.where(id: ids).includes(recipe_ingredients: :ingredient).index_by(&:id)
  end

  def coverage_for(recipe, pantry_terms)
    have = []
    missing = []
    staples = []

    recipe.recipe_ingredients.each do |line|
      name = line.ingredient.normalized_name
      treated_staple = staple_name?(name)
      in_pantry = pantry_terms.include?(name)
      if treated_staple
        have << line.display_text
        staples << line.display_text
      elsif in_pantry
        have << line.display_text
      else
        missing << line.display_text
      end
    end

    [ have, missing, staples ]
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
    STAPLES.each do |staple|
      remaining.gsub!(/\s#{Regexp.escape(staple)}\s/, " ")
    end
    leftover = remaining.split - STAPLE_FILLERS
    leftover.empty?
  end
end
