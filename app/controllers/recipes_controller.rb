class RecipesController < ApplicationController
  def index
    @ingredients = params[:ingredients]
    @staples_only = RecipeMatcher.staples_only?(@ingredients)
    @results = RecipeMatcher.search(@ingredients)
    @cook_now = @results.select(&:cook_now?)
    @almost = @results.select(&:almost?)
  end

  def show
    @ingredients = params[:ingredients]
    @recipe = Recipe.includes(recipe_ingredients: :ingredient).find(params[:id])
    @explanation = RecipeMatcher.explain(@recipe, @ingredients)
  end
end
