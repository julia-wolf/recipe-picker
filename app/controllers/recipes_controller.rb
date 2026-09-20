class RecipesController < ApplicationController
  def index
    @ingredients = params[:ingredients]
    matcher = RecipeMatcher.new(@ingredients)
    @staples_only = matcher.staples_only?
    @results = matcher.search
    @too_far = matcher.too_far?
    @cook_now = @results.select(&:cook_now?)
    @almost = @results.select(&:almost?)
  end

  def show
    @ingredients = params[:ingredients]
    @recipe = Recipe.includes(recipe_ingredients: :ingredient).find(params[:id])
    @explanation = RecipeMatcher.explain(@recipe, @ingredients)
  end
end
